"""Read-only API contract probes: isolated SQLite, mocked providers, no live traffic."""
import argparse
import hashlib
import json
import logging
import os
import secrets
import sys
from pathlib import Path
p = argparse.ArgumentParser()
p.add_argument('--backend-root', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
root = a.backend_root.resolve()

def inventory():
    return {str(f.relative_to(root)): hashlib.sha256(f.read_bytes()).hexdigest() for f in root.rglob('*') if f.is_file()}
before = inventory()
sys.dont_write_bytecode = True
sys.path.insert(0, str(root))
os.environ['DJANGO_SETTINGS_MODULE'] = 'config.settings.testing'
os.environ['SECRET_KEY'] = secrets.token_urlsafe(48)
logging.disable(logging.CRITICAL)
import django
django.setup()
from apps.accounts.models import ClinicUser, User
from apps.clinics.models import Clinic
from django.conf import settings
from django.core.cache import cache
from django.core.management import call_command
from rest_framework.test import APIClient
assert settings.DATABASES['default']['NAME'] == ':memory:'
settings.DEBUG = False
settings.ALLOWED_HOSTS = ['testserver']
settings.GOOGLE_PLACES_API_KEY = 'disposable-offline-fixture'
call_command('migrate', verbosity=0, interactive=False)
owner = User.objects.create_user(phone='+971500000094', role='clinic_admin')
staff = User.objects.create_user(phone='+971500000095', role='clinic_staff')
patient = User.objects.create_user(phone='+971500000096', role='patient')
c = Clinic.objects.create(name_en='Disposable integration QA', slug='integration-qa', status='active', setup_status='approved', google_place_id='QA-Old', google_maps_url='https://www.google.com/maps/search/?api=1&query=QA-Old&query_place_id=QA-Old', latitude=25.11, longitude=55.21)
ClinicUser.objects.create(user=owner, clinic=c, role_in_clinic='admin')
ClinicUser.objects.create(user=staff, clinic=c, role_in_clinic='staff')
client = APIClient()
records = []

def call(method, route, data=None):
    r = getattr(client, method)(route, data, format='json') if data is not None else client.get(route)
    records.append({'method': method.upper(), 'route': route, 'status': r.status_code})
    return r
from django.core.files.uploadedfile import SimpleUploadedFile
from apps.clinics.models import ClinicBranch
client.force_authenticate(user=owner)
route = '/api/v1/clinic-portal/practitioners/'
text = dict(name_en='Disposable nurse', name_ar='ممرض اختبار', title_en='', title_ar='', speciality_en='', speciality_ar='', type='nurse', bio_en='', bio_ar='', status='active')
for typ in ['doctor', 'nurse', 'licensed_professional']:
    r = client.post(route, {**text, 'type': typ}, format='json')
    records.append({'case': typ + '_without_photo', 'status': r.status_code, 'errors': r.data if r.status_code >= 400 else None})
for label, title in [('flutter_blank_title_fallback', 'x' * 120), ('fixed_optional_blank_title', '')]:
    r = client.post(route, {**text, 'speciality_en': 'x' * 120, 'title_en': title}, format='json')
    records.append({'case': label, 'status': r.status_code, 'errors': r.data if r.status_code >= 400 else None})
for field, value in [('type', 'Nurse'), ('title_en', 'x' * 101), ('speciality_en', 'x' * 201)]:
    r = client.post(route, {**text, field: value}, format='json')
    records.append({'case': 'invalid_' + field, 'status': r.status_code, 'errors': r.data})
from apps.practitioners.models import Practitioner
nurse = Practitioner.objects.filter(clinic=c, type='nurse').first()
r = client.patch(route + str(nurse.pk) + '/', {'title_en': '', 'bio_en': 'Edited source fixture'}, format='json')
fresh_practitioner = APIClient()
fresh_practitioner.force_authenticate(user=owner)
read = fresh_practitioner.get(route + str(nurse.pk) + '/')
records.append({'case': 'nurse_edit_new_authenticated_read', 'status': r.status_code, 'read_status': read.status_code, 'blank_title_preserved': read.data.get('title_en') == '', 'edited_bio_persisted': read.data.get('bio_en') == 'Edited source fixture'})
Practitioner.objects.bulk_create([Practitioner(clinic=c, name_en=f'ZZ pagination {i:02d}', type='nurse') for i in range(21)])
other = Clinic.objects.create(name_en='Disposable unrelated tenant', status='active')
Practitioner.objects.create(clinic=other, name_en='Excluded unrelated practitioner', type='doctor')
page1 = client.get(route + '?page=1&page_size=20')
page2 = client.get(route + '?page=2&page_size=20')
first_ids = {d['id'] for d in page1.data['results']}
second_ids = {d['id'] for d in page2.data['results']}
records.append({'case': 'practitioner_page2_tenant_scope', 'status': page2.status_code, 'count': page2.data['count'], 'page1_rows': len(first_ids), 'page2_rows': len(second_ids), 'overlap': bool(first_ids & second_ids), 'all_current_tenant': not Practitioner.objects.filter(pk__in=first_ids | second_ids).exclude(clinic=c).exists()})
png = (Path(__file__).resolve().parents[1] / 'test/fixtures/media/portrait_photo.png').read_bytes()
for state in ['active', 'pending']:
    c.status = state
    c.save(update_fields=['status'])
    for mt in ['practitioner_avatar', 'clinic_gallery']:
        r = client.post('/api/v1/media/upload/', {'file': SimpleUploadedFile('image.png', png, content_type='image/png'), 'media_type': mt, 'clinic_id': str(c.pk)}, format='multipart')
        records.append({'case': state + '_' + mt, 'status': r.status_code, 'errors': r.data if r.status_code >= 400 else None})
        if r.status_code == 201 and mt == 'practitioner_avatar':
            q = client.post(route, {**text, 'avatar': r.data['url'], 'media_asset': r.data['id']}, format='json')
            records.append({'case': 'nurse_with_asset', 'status': q.status_code, 'errors': q.data if q.status_code >= 400 else None})
        if r.status_code == 201 and mt == 'clinic_gallery':
            q = client.get('/api/v1/media/?media_type=clinic_gallery&page=1&page_size=20')
            records.append({'case': 'gallery_readback', 'status': q.status_code, 'count': q.data['count'], 'keys': list(q.data['results'][0])})
            fresh = APIClient()
            fresh.force_authenticate(user=owner)
            read = fresh.get('/api/v1/clinic-portal/profile/')
            records.append({'case': 'gallery_new_authenticated_client_profile_read', 'status': read.status_code, 'gallery_count': len(read.data['gallery_images'])})
            q = client.delete('/api/v1/media/' + r.data['id'] + '/')
            records.append({'case': 'gallery_delete', 'status': q.status_code})
c.status = 'active'
c.save(update_fields=['status'])
q = client.patch('/api/v1/clinic-portal/profile/', {'city': 'Dubai', 'emirate': 'Abu Dhabi', 'address_en': 'Sharjah', 'latitude': '25.3463', 'longitude': '55.4209'}, format='json')
records.append({'case': 'contradictory_location', 'status': q.status_code, 'stored': {k: q.data.get(k) for k in ['city', 'emirate', 'address_en', 'latitude', 'longitude']}})
for label, active, deleted in [('active_branch', True, False), ('inactive_branch', False, False), ('deleted_branch', True, True)]:
    x = Clinic.objects.create(name_en='Disposable ' + label, status='active', setup_status='approved', city='Abu Dhabi', emirate='Abu Dhabi')
    from django.utils import timezone
    ClinicBranch.objects.create(clinic=x, name_en='Test branch', city='Dubai', is_active=active, deleted_at=timezone.now() if deleted else None)
q = client.get('/api/v1/clinics/?city=Dubai')
records.append({'case': 'Dubai_filter', 'status': q.status_code, 'names': [d['name_en'] for d in q.data['results']]})
x = Clinic.objects.get(name_en='Disposable active_branch')
x.latitude = '24.4571300'
x.longitude = '54.3740700'
x.save(update_fields=['latitude', 'longitude'])
b = x.branches.first()
b.latitude = '25.2315000'
b.longitude = '55.3242000'
b.save(update_fields=['latitude', 'longitude'])
near = client.get('/api/v1/clinics/nearby/?latitude=25.23201&longitude=55.32471&radius_km=50')
matched = next((d for d in near.data.get('results', []) if d['id'] == str(x.pk)), None)
records.append({'case': 'nearby_cross_emirate_branch_metadata', 'status': near.status_code, 'nearest_branch': None if matched is None else matched['nearest_branch'], 'distance_km': None if matched is None else matched['distance_km']})
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(records, indent=2, ensure_ascii=False))
assert before == inventory()
print(json.dumps({'observations': len(records), 'source_files_unchanged': len(before), 'output': str(a.output)}, indent=2))
