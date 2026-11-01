"""Offline source probes for 5fd66e6, never a live API/deployment test.

Uses the shared pre-initialization network/database/media isolation boundary.
All accounts and contact values below are synthetic fixtures.
"""
from pathlib import Path
import argparse
import sys, os, json, hashlib, logging
from uuid import uuid4, UUID
from unittest.mock import patch
sys.dont_write_bytecode = True
parser = argparse.ArgumentParser(description='Offline 5fd66e6 contract probes; never a live API test')
parser.add_argument('--backend-root', required=True, type=Path)
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
root = args.backend_root.resolve()
output = args.output.resolve()
if output.is_relative_to(root):
    raise RuntimeError('Output must remain outside the read-only backend')
sys.path.insert(0, str(repo / 'tool'))
from isolated_django_audit import isolated_django_audit
before = {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file()}
assert hashlib.sha256(json.dumps(before, sort_keys=True, separators=(',', ':')).encode()).hexdigest() == 'a6634ec5491d8631330ba15ec49e075384b7285c9d47c9727d5fd5eff0663ef2'
sys.path.insert(0, str(root))
os.environ['DJANGO_SETTINGS_MODULE'] = 'config.settings.testing'
os.environ['SECRET_KEY'] = 'synthetic-local-contract-probe'
logging.disable(logging.CRITICAL)
records = []
with isolated_django_audit() as check:
    import django
    django.setup()
    check()
    from django.core.management import call_command
    from django.conf import settings
    from django.core.cache import cache
    from django.db import IntegrityError, transaction
    from rest_framework.test import APIClient
    from apps.accounts.models import User
    from apps.accounts.services.sms import MockSmsProvider
    from apps.clinics.models import Clinic, ClinicBranch
    from apps.analytics.models import AnalyticsEvent, AnalyticsDailyAggregate
    import phonenumbers
    settings.ALLOWED_HOSTS = ['testserver']
    settings.DEBUG = False
    call_command('migrate', verbosity=0, interactive=False)
    c = APIClient(raise_request_exception=False)
    example = phonenumbers.format_number(phonenumbers.example_number_for_type('SY', phonenumbers.PhoneNumberType.MOBILE), phonenumbers.PhoneNumberFormat.E164)
    base = {'full_name': 'Synthetic QA', 'phone': example, 'email': 'synthetic-one@example.test', 'password': 'Synthetic!Qa917x'}
    with patch('apps.accounts.views.OtpService.send_otp', return_value={'expires_in': 300}):
        r = c.post('/api/v1/auth/register/', base, format='json')
        assert r.status_code == 201, (r.status_code, r.data)
        records.append({'case': 'valid_syrian_registration', 'http': 201, 'canonical_phone_matches': User.objects.get(email=base['email']).phone == example, 'provider_delivery': 'mocked; not verified'})
        cases = [('invalid_phone', dict(base, phone='+963123', email='invalid-phone@example.test'), ['phone']), ('invalid_email', dict(base, phone='+971501234567', email='invalid'), ['email']), ('duplicate_phone', dict(base, email='unique-email@example.test'), ['phone']), ('duplicate_email', dict(base, phone='+971501234567'), ['email']), ('missing_email', {k: v for k, v in dict(base, phone='+971501234567').items() if k != 'email'}, ['email'])]
        for name, payload, expected in cases:
            r = c.post('/api/v1/auth/register/', payload, format='json')
            assert r.status_code == 400, (name, r.status_code)
            fields = r.data['error']['fields']
            assert sorted(fields) == expected, (name, fields)
            records.append({'case': name, 'http': r.status_code, 'code': r.data['error']['code'], 'fields': sorted(fields), 'field_error_codes': {k: [getattr(e, 'code', 'string') for e in v] for k, v in fields.items()}})
    admin = User.objects.create_user(phone='+971500000010', role='super_admin')
    first = User.objects.get(email=base['email'])
    second = User.objects.create_user(phone='+971500000011', role='patient')
    public = Clinic.objects.create(name_en='Synthetic public', status='active', setup_status='approved')
    draft = Clinic.objects.create(name_en='Synthetic unpublished', status='pending', setup_status='draft')
    branch = ClinicBranch.objects.create(clinic=draft, name_en='Synthetic branch', is_active=True)
    ingest = '/api/v1/analytics/events/'
    c.force_authenticate(first)
    payload = {'event_id': str(uuid4()), 'event_type': 'call_tap', 'clinic': str(public.pk), 'metadata': {'source': 'android', 'screen': 'clinic_profile'}}
    one = c.post(ingest, payload, format='json')
    two = c.post(ingest, payload, format='json')
    conflict = c.post(ingest, dict(payload, event_type='whatsapp_tap'), format='json')
    assert [one.status_code, two.status_code, conflict.status_code] == [201, 200, 409]
    records.append({'case': 'source_idempotent_ack', 'http': [201, 200, 409], 'ack_matches': one.data['event_id'] == two.data['event_id'] == payload['event_id'], 'rows': AnalyticsEvent.objects.filter(event_id=payload['event_id']).count()})
    c.force_authenticate(second)
    r = c.post(ingest, payload, format='json')
    assert r.status_code == 200
    records.append({'case': 'cross_actor_duplicate_ack', 'http': 200, 'stored_user_unchanged': AnalyticsEvent.objects.get(event_id=payload['event_id']).user_id == first.pk})
    for kind, body, expected in [('client_lead_rejected', dict(payload, event_id=str(uuid4()), event_type='lead_submitted'), 400), ('missing_id_rejected', {k: v for k, v in payload.items() if k != 'event_id'}, 400), ('branch_can_derive_unpublished_clinic', {'event_id': str(uuid4()), 'event_type': 'call_tap', 'branch': str(branch.pk)}, 201), ('clinicless_contact_accepted', {'event_id': str(uuid4()), 'event_type': 'call_tap'}, 201), ('unbounded_metadata_token_like_value_accepted', dict(payload, event_id=str(uuid4()), metadata={'screen': 'eyJhbGciOiJub25lIn0.eyJzdWIiOiJzeW50aGV0aWMifQ.fixture'}), 201), ('forbidden_key_rejected', dict(payload, event_id=str(uuid4()), metadata={'patient_notes': 'synthetic'}), 400)]:
        r = c.post(ingest, body, format='json')
        assert r.status_code == expected, (kind, r.status_code, r.data)
        records.append({'case': kind, 'http': r.status_code})
    c.force_authenticate(first)
    first.is_verified = True
    first.save(update_fields=['is_verified'])
    r = c.post('/api/v1/leads/', {'clinic': str(public.pk), 'patient_name': 'Synthetic QA', 'patient_phone': example, 'service_name': 'Synthetic procedure context', 'consent_accepted': True}, format='json')
    assert r.status_code == 201, (r.status_code, r.data)
    event = AnalyticsEvent.objects.filter(event_type='lead_submitted', user=first).get()
    assert {'service_name', 'reference_code'} <= event.metadata.keys()
    records.append({'case': 'saved_lead_server_event_still_has_inquiry_metadata', 'http': 201, 'events_for_saved_lead': 1, 'metadata_field_names': sorted(event.metadata)})
    c.force_authenticate(admin)
    for route in ['/api/v1/admin/analytics/clinics/', f'/api/v1/admin/clinics/{public.pk}/analytics/']:
        r = c.get(route)
        assert r.status_code == 404, (route, r.status_code)
    a = c.get('/api/v1/admin/analytics/')
    b = c.get('/api/v1/admin/analytics/', {'clinic_id': str(public.pk), 'page': 2})
    assert a.data == b.data
    records.append({'case': 'per_clinic_routes_absent_and_filters_ignored', 'proposed_routes_http': [404, 404], 'same_summary': True, 'row_fields': sorted(a.data['clinic_engagement'][0])})
    AnalyticsDailyAggregate.objects.create(date='2026-10-01', clinic=None)
    try:
        with transaction.atomic():
            AnalyticsDailyAggregate.objects.create(date='2026-10-01', clinic=None)
    except IntegrityError:
        records.append({'case': 'platform_null_rollup_unique_fixed', 'duplicate_rejected': True})
    else:
        raise AssertionError('Expected uniqueness')
    for i, uid in enumerate(['abcdef00-0000-4000-8000-000000000001', 'abcdef11-0000-4000-8000-000000000002']):
        cache.clear()
        MockSmsProvider.reset()
        u = User.objects.create_user(id=UUID(uid), phone=f'+97150000100{i}', role='patient', is_verified=True)
        c.force_authenticate(u)
        start = c.post('/api/v1/auth/me/deletion/request/', {}, format='json')
        assert start.status_code == 200
        code = MockSmsProvider.sent_messages[-1]['code']
        r = c.post('/api/v1/auth/me/deletion/confirm/', {'code': code}, format='json')
        u.refresh_from_db()
        assert r.status_code == 200 and (not u.is_active)
        records.append({'case': 'deletion_same_prefix_fixed', 'fixture': i, 'http': r.status_code, 'tombstone_length': len(u.phone)})
assert before == {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file()}
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps({'backend': '5fd66e60d76350ac1feb2a044bf2e8544ecfc318', 'scope': 'disposable SQLite/local storage/network denied, synthetic fixtures; not production', 'unchanged_source_files': len(before), 'records': records}, indent=2) + '\n')
print('Probe completed:', len(records), 'observations;', len(before), 'backend files unchanged')
