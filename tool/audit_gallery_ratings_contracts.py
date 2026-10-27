"""Read-only c25e901 contract probes; SQLite/local files and stubbed Google only."""
import argparse
import hashlib
import io
import json
import logging
import os
from pathlib import Path
import secrets
import sys
from unittest.mock import Mock, patch

parser = argparse.ArgumentParser()
parser.add_argument("--backend-root", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
root = args.backend_root.resolve()


def inventory():
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in root.rglob("*") if p.is_file()}


before = inventory()
sys.dont_write_bytecode = True
sys.path.insert(0, str(root))
os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings.testing"
os.environ["SECRET_KEY"] = secrets.token_urlsafe(48)
logging.disable(logging.CRITICAL)
import django
from django.conf import settings

# Do not inherit R2/production storage even when an operator's environment has it.
assert settings.DATABASES["default"]["NAME"] == ":memory:"
assert not Path(settings.MEDIA_ROOT).resolve().is_relative_to(root)
settings.STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
}
django.setup()
from django.core.files.storage import FileSystemStorage, default_storage
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.management import call_command
from PIL import Image
from rest_framework.test import APIClient
from apps.accounts.models import ClinicUser, User
from apps.clinics.models import Clinic
from apps.clinics.services.google_places import sync_all_active_clinics, sync_clinic
from apps.media.models import MediaAsset

assert settings.DATABASES["default"]["NAME"] == ":memory:"
assert isinstance(default_storage, FileSystemStorage)
settings.DEBUG = False
settings.ALLOWED_HOSTS = ["testserver"]
settings.GOOGLE_PLACES_API_KEY = "disposable-offline-fixture"
call_command("migrate", verbosity=0, interactive=False)
records = []
owner = User.objects.create_user(phone="+971500000091", role="clinic_admin")
patient = User.objects.create_user(phone="+971500000092", role="patient")
clinic = Clinic.objects.create(name_en="Disposable Medical Clinic", status="active",
                               setup_status="approved", city="Dubai", emirate="Dubai")
ClinicUser.objects.create(user=owner, clinic=clinic, role_in_clinic="admin")
client = APIClient()
client.force_authenticate(user=owner)
gallery_route = "/api/v1/media/?media_type=clinic_gallery&page=1&page_size=20"
profile_route = "/api/v1/clinic-portal/profile/"
business_route = profile_route + "google-business/"


def image(fmt):
    output = io.BytesIO()
    Image.new("RGB", (32, 24), (40, 70, 90)).save(output, format=fmt)
    return SimpleUploadedFile("image." + {"JPEG": "jpg"}.get(fmt, fmt.lower()),
                              output.getvalue(), content_type="image/" + fmt.lower())


for state in ("active", "pending"):
    clinic.status = state
    clinic.save(update_fields=["status"])
    for fmt in ("PNG", "JPEG", "WEBP"):
        response = client.post("/api/v1/media/upload/", {
            "file": image(fmt), "media_type": "clinic_gallery", "clinic_id": str(clinic.pk)
        }, format="multipart")
        assert response.status_code == 201, response.data
        data = response.data
        fresh = APIClient()
        fresh.force_authenticate(user=owner)
        listed = fresh.get(gallery_route)
        profile = fresh.get(profile_route)
        asset = MediaAsset.objects.get(pk=data["id"])
        ids = [item["id"] for item in listed.data["results"]]
        check = dict(case=f"{state}_{fmt}_upload_read_association", status=response.status_code,
                     keys=sorted(data), mime=data["mime_type"],
                     saved_bytes=asset.file.size, width=data["width"], height=data["height"],
                     db_clinic_matches=asset.clinic_id == clinic.pk,
                     fresh_list_status=listed.status_code, fresh_list_contains_ack=data["id"] in ids,
                     fresh_profile_status=profile.status_code,
                     profile_contains_url=data["url"] in profile.data["gallery_images"])
        public_gallery = APIClient().get("/api/v1/clinics/" + str(clinic.pk) + "/")
        check["public_status"] = public_gallery.status_code
        if state == "active":
            assert public_gallery.status_code == 200
            check["public_contains_url"] = data["url"] in public_gallery.data["gallery_images"]
            assert check["public_contains_url"]
        else:
            assert public_gallery.status_code == 404
        assert check["fresh_list_contains_ack"] and check["profile_contains_url"]
        records.append(check)
        outsider = APIClient()
        outsider.force_authenticate(user=patient)
        denied = outsider.get("/api/v1/media/" + data["id"] + "/")
        assert denied.status_code == 403
        deleted = client.delete("/api/v1/media/" + data["id"] + "/")
        assert deleted.status_code == 204
        deleted_list = fresh.get(gallery_route)
        deleted_profile = fresh.get(profile_route)
        removed_from_list = not any(row["id"] == data["id"] for row in deleted_list.data["results"])
        removed_from_profile = data["url"] not in deleted_profile.data["gallery_images"]
        binary_removed = not asset.file.storage.exists(asset.file.name)
        assert removed_from_list and removed_from_profile and binary_removed
        records.append(dict(case=f"{state}_{fmt}_delete", status=deleted.status_code,
                            foreign_patient_status=denied.status_code,
                            db_removed=not MediaAsset.objects.filter(pk=data["id"]).exists(),
                            fresh_list_removed=removed_from_list,
                            fresh_profile_removed=removed_from_profile, binary_removed=binary_removed))

for label, payload in (
    ("corrupt_image", {"file": SimpleUploadedFile("image.png", b"not-png", content_type="image/png")}),
    ("missing_file", {}),
):
    response = client.post("/api/v1/media/upload/", {
        **payload, "media_type": "clinic_gallery", "clinic_id": str(clinic.pk)
    }, format="multipart")
    assert response.status_code == 400
    error = response.data.get("error", {})
    records.append(dict(case=label, status=response.status_code, api_code=error.get("code"),
                        validation_fields=sorted(error.get("fields", {}))))

clinic.status = "suspended"
clinic.save(update_fields=["status"])
denied = client.post("/api/v1/media/upload/", {
    "file": image("PNG"), "media_type": "clinic_gallery", "clinic_id": str(clinic.pk)
}, format="multipart")
assert denied.status_code == 403
records.append(dict(case="suspended_upload", status=denied.status_code))
clinic.status = "active"
clinic.save(update_fields=["status"])


def link_business(name, place_id):
    # Explicit provider stub: not a Google request, genuine business or rating.
    provider = Mock(status_code=200)
    provider.json.return_value = {
        "id": place_id, "displayName": {"text": name},
        "formattedAddress": "Disposable Dubai address",
        "location": {"latitude": 25.1, "longitude": 55.2},
        "addressComponents": [
            {"types": ["country"], "shortText": "AE", "longText": "United Arab Emirates"},
            {"types": ["locality"], "longText": "Dubai", "shortText": "Dubai"},
            {"types": ["administrative_area_level_1"], "longText": "Dubai", "shortText": "Dubai"},
        ],
    }
    with patch("apps.clinics.services.google_places.requests.get", return_value=provider) as calls:
        detail = client.post(business_route + "details/", {"place_id": place_id}, format="json")
        assert detail.status_code == 200, detail.data
        previous = clinic.google_place_id or ""
        linked = client.post(business_route + "link/", {
            "place_id": place_id, "selection_proof": detail.data["selection_proof"],
            "expected_current_place_id": previous,
        }, format="json")
        assert linked.status_code == 200, linked.data
        assert calls.call_count == 1  # Details only; link does not fetch ratings.
    clinic.refresh_from_db()
    records.append(dict(case="link_" + ("mismatched_business" if name != clinic.name_en else "matching_fixture"),
                        status=linked.status_code, returned_place_verification=linked.data["google_link_status"],
                        sync_status=linked.data["google_sync_status"],
                        rating=linked.data["google_rating"], count=linked.data["google_reviews_count"],
                        provider_calls_including_details=1, immediate_rating_fetches=0))


public = APIClient()
detail_route = "/api/v1/clinics/" + str(clinic.pk) + "/"
link_business("Unrelated QA Salon", "offline-mismatched-place")
before_sync = public.get(detail_route)
assert before_sync.status_code == 200 and before_sync.data["google_rating"] is None
provider = Mock(status_code=200)
provider.json.return_value = {"rating": 4.6, "userRatingCount": 42}
with patch("apps.clinics.services.google_places.requests.get", return_value=provider):
    assert sync_clinic(clinic)
after_sync = public.get(detail_route)
assert after_sync.status_code == 200 and float(after_sync.data["google_rating"]) == 4.6
records.append(dict(case="unrelated_business_rating_exposure", before_sync_rating=None,
                    after_sync_public_rating=float(after_sync.data["google_rating"]),
                    after_sync_public_count=after_sync.data["google_reviews_count"],
                    public_place_matches_link=True,
                    backend_identity_match_enforced=False,
                    public_has_identity_review_field="google_link_status" in after_sync.data))

link_business(clinic.name_en, "offline-matching-place")
with patch("apps.clinics.services.google_places.requests.get", return_value=provider):
    assert sync_clinic(clinic)
fresh_public = APIClient().get(detail_route)
fresh_private = client.get(profile_route)
records.append(dict(case="successful_controlled_rating_sync", public_status=fresh_public.status_code,
                    public_rating=float(fresh_public.data["google_rating"]),
                    public_count=fresh_public.data["google_reviews_count"],
                    private_sync_status=fresh_private.data["google_sync_status"],
                    persisted_synced_at=bool(fresh_private.data["google_last_synced_at"])))

link_business(clinic.name_en, "offline-pending-place")
clinic.status = "pending"
clinic.save(update_fields=["status"])
with patch("apps.clinics.services.google_places.requests.get", return_value=provider) as calls:
    summary = sync_all_active_clinics()
    assert calls.call_count == 0
clinic.refresh_from_db()
records.append(dict(case="pending_clinic_daily_sync_exclusion", task_total=summary["total"],
                    provider_calls=0, clinic_sync_status=clinic.google_sync_status,
                    rating=clinic.google_rating))
assert clinic.google_sync_status == "pending" and clinic.google_rating is None

clinic.status = "active"
clinic.save(update_fields=["status"])
provider = Mock(status_code=403, text="disposable provider denial")
with patch("apps.clinics.services.google_places.requests.get", return_value=provider):
    assert not sync_clinic(clinic)
clinic.refresh_from_db()
records.append(dict(case="provider_403_before_first_rating", sync_status=clinic.google_sync_status,
                    rating=clinic.google_rating, count=clinic.google_reviews_count))
assert clinic.google_sync_status == "failed" and clinic.google_rating is None


def association_changes_during_fetch(*unused_args, **unused_kwargs):
    Clinic.objects.filter(pk=clinic.pk).update(google_place_id="offline-new-selection",
                                              google_sync_status="pending", google_rating=None,
                                              google_reviews_count=0)
    return {"rating": 4.6, "reviews_count": 42}


with patch("apps.clinics.services.google_places.fetch_place_rating",
           side_effect=association_changes_during_fetch):
    sync_clinic(clinic)
clinic.refresh_from_db()
records.append(dict(case="association_changed_during_rating_fetch",
                    newer_place_preserved=clinic.google_place_id == "offline-new-selection",
                    old_place_restored=clinic.google_place_id == "offline-pending-place",
                    sync_status=clinic.google_sync_status, rating=clinic.google_rating))
assert clinic.google_place_id == "offline-pending-place"

# An assigned second tenant is authorized, but it is not the editor's tenant.
second = Clinic.objects.create(name_en="Disposable second tenant", status="active", setup_status="approved")
ClinicUser.objects.create(user=owner, clinic=second, role_in_clinic="admin")
created_ids = []
for target in (clinic, second):
    response = client.post("/api/v1/media/upload/", {
        "file": image("PNG"), "media_type": "clinic_gallery", "clinic_id": str(target.pk)
    }, format="multipart")
    assert response.status_code == 201
    created_ids.append(response.data["id"])
listed = client.get(gallery_route + "&clinic_id=" + str(clinic.pk))
tenants = {row["clinic_id"] for row in listed.data["results"]}
assert len(tenants) == 2
records.append(dict(case="multi_membership_gallery_filter_ignored", status=listed.status_code,
                    queried_one_clinic=True, returned_distinct_clinics=len(tenants),
                    returned_other_assigned_clinic=True))
for asset_id in created_ids:
    assert client.delete("/api/v1/media/" + asset_id + "/").status_code == 204
cache.clear()
assert before == inventory(), "Backend source changed"
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(dict(
    supplied_backend_commit="c25e901ec10c7c3f751462b414d90d5ab88d3c85",
    evidence_scope="isolated SQLite/local storage; explicit Google provider stubs; no production/R2/device evidence",
    source_files_unchanged=len(before), observations=records,
), indent=2, default=str) + "\n")
print(json.dumps({"observations": len(records), "source_files_unchanged": len(before)}))
