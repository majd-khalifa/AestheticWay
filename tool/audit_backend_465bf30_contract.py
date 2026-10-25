"""Read-only API contract probes: isolated SQLite, mocked providers, no live traffic."""

import argparse
import hashlib
import json
import logging
import os
import secrets
import sys
from pathlib import Path
from unittest.mock import Mock, patch

p = argparse.ArgumentParser()
p.add_argument("--backend-root", type=Path, required=True)
p.add_argument("--output", type=Path, required=True)
a = p.parse_args()
root = a.backend_root.resolve()


def inventory():
    return {
        str(f.relative_to(root)): hashlib.sha256(f.read_bytes()).hexdigest()
        for f in root.rglob("*")
        if f.is_file()
    }


before = inventory()
sys.dont_write_bytecode = True
sys.path.insert(0, str(root))
os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings.testing"
os.environ["SECRET_KEY"] = secrets.token_urlsafe(48)
logging.disable(logging.CRITICAL)
import django

django.setup()
from apps.accounts.models import ClinicUser, User
from apps.clinics.models import Clinic
from apps.clinics.services.google_places import create_selection_proof
from django.conf import settings
from django.core.cache import cache
from django.core.management import call_command
from rest_framework.test import APIClient

assert settings.DATABASES["default"]["NAME"] == ":memory:"
settings.DEBUG = False
settings.ALLOWED_HOSTS = ["testserver"]
settings.GOOGLE_PLACES_API_KEY = "disposable-offline-fixture"
call_command("migrate", verbosity=0, interactive=False)
owner = User.objects.create_user(phone="+971500000094", role="clinic_admin")
staff = User.objects.create_user(phone="+971500000095", role="clinic_staff")
patient = User.objects.create_user(phone="+971500000096", role="patient")
c = Clinic.objects.create(
    name_en="Disposable integration QA",
    slug="integration-qa",
    status="active",
    setup_status="approved",
    google_place_id="QA-Old",
    google_maps_url="https://www.google.com/maps/search/?api=1&query=QA-Old&query_place_id=QA-Old",
    latitude=25.11,
    longitude=55.21,
)
ClinicUser.objects.create(user=owner, clinic=c, role_in_clinic="admin")
ClinicUser.objects.create(user=staff, clinic=c, role_in_clinic="staff")
client = APIClient()
records = []


def call(method, route, data=None):
    r = (
        getattr(client, method)(route, data, format="json")
        if data is not None
        else client.get(route)
    )
    records.append({"method": method.upper(), "route": route, "status": r.status_code})
    return r


profile = "/api/v1/clinic-portal/profile/"
google = profile + "google-business/"
client.force_authenticate(user=owner)
r = call("patch", profile, {"google_place_id": "QA-Unverified"})
assert r.status_code == 400
r = call("patch", profile, {"latitude": 25.12, "longitude": 55.22})
assert r.status_code == 200 and r.data["google_place_id"] == "QA-Old"
transport = Mock(status_code=200)
transport.json.return_value = {
    "suggestions": [
        {
            "placePrediction": {
                "placeId": "QA-Selected",
                "structuredFormat": {
                    "mainText": {"text": "Disposable QA"},
                    "secondaryText": {"text": "QA Dubai"},
                },
            }
        }
    ]
}
with patch("apps.clinics.services.google_places.requests.post", return_value=transport):
    r = call(
        "post",
        google + "autocomplete/",
        {
            "query": "Disposable",
            "session_token": "550e8400-e29b-41d4-a716-446655440000",
            "language_code": "en",
        },
    )
assert (
    r.status_code == 200
    and "suggestions" in r.data
    and r.data["results"] == r.data["suggestions"]
)
transport.json.return_value = {
    "id": "QA-Selected",
    "displayName": {"text": "Disposable QA"},
    "formattedAddress": "QA Dubai, UAE",
    "location": {"latitude": 25.1, "longitude": 55.2},
    "googleMapsUri": "https://www.google.com/maps/search/?api=1&query_place_id=QA-Selected&query=QA-Selected",
    "addressComponents": [
        {"types": ["country"], "shortText": "AE"},
        {"types": ["locality"], "longText": "Dubai"},
    ],
}
with patch("apps.clinics.services.google_places.requests.get", return_value=transport):
    r = call(
        "post",
        google + "details/",
        {
            "place_id": "QA-Selected",
            "session_token": "550e8400-e29b-41d4-a716-446655440000",
            "language_code": "en",
        },
    )
assert r.status_code == 200 and r.data["proof_expires_in"] == 300
proof = r.data["selection_proof"]
r = call(
    "post",
    google + "link/",
    {
        "place_id": "QA-Selected",
        "selection_proof": proof,
        "expected_current_place_id": "QA-Other",
    },
)
assert r.status_code == 409
r = call(
    "post",
    google + "link/",
    {
        "place_id": "QA-Selected",
        "selection_proof": proof,
        "expected_current_place_id": "QA-Old",
        "google_maps_url": "https://malicious.invalid/untrusted",
    },
)
assert r.status_code == 200 and r.data["google_link_status"] == "linked_verified_place"
assert r.data["google_maps_url"].startswith("https://www.google.com/")
r = call("get", profile)
assert r.data["google_place_id"] == "QA-Selected" and float(r.data["latitude"]) == 25.12
r = call(
    "post",
    google + "link/",
    {
        "place_id": "QA-Selected",
        "selection_proof": proof,
        "expected_current_place_id": "QA-Selected",
    },
)
assert r.status_code == 400
expired = create_selection_proof(owner.id, c.id, "QA-Expired")
cache.delete(f"gplace_proof:{expired}")
r = call(
    "post",
    google + "link/",
    {
        "place_id": "QA-Expired",
        "selection_proof": expired,
        "expected_current_place_id": "QA-Selected",
    },
)
assert r.status_code == 400
r = call("post", google + "unlink/", {"expected_current_place_id": "QA-Selected"})
assert r.status_code == 200 and r.data["google_link_status"] == "unlinked"
# Real two-second H.264 test clip (no clinic/person content), local file storage.
# This verifies pointer rewind/actual saved bytes, not physical playback or R2.
import tempfile

from apps.media.models import MediaAsset
from django.core.files.storage import FileSystemStorage
from django.core.files.uploadedfile import SimpleUploadedFile

with tempfile.TemporaryDirectory(prefix="aw-401-video-") as tmp:
    storage = FileSystemStorage(location=tmp, base_url="/qa-media/")
    Clinic._meta.get_field("video_ad_file").storage = storage
    Clinic._meta.get_field("cover_image").storage = storage
    MediaAsset._meta.get_field("file").storage = storage
    c.refresh_from_db()
    c.subscription_tier = "vip"
    c.cover_image = "preserved/cover.png"
    c.save()
    # Existing real-shape gallery association must survive video changes.
    gallery = MediaAsset.objects.create(
        clinic=c,
        uploader=owner,
        media_type="clinic_gallery",
        file="preserved/gallery.png",
        file_size=120,
        mime_type="image/png",
    )
    before_profile = call("get", profile).data
    clip = (
        Path(__file__).resolve().parents[1]
        / "test/fixtures/clinic_media/android_layout_showcase.mp4"
    ).read_bytes()
    # Preserve real H.264 samples/chunk offsets, extend mdat before moov.
    import struct

    offset = 0
    while offset + 8 <= len(clip):
        size, kind = struct.unpack(">I4s", clip[offset : offset + 8])
        if kind == b"mdat":
            padding = 3 * 1024 * 1024
            clip = (
                clip[:offset]
                + struct.pack(">I", size + padding)
                + clip[offset + 4 : offset + size]
                + bytes(padding)
                + clip[offset + size :]
            )
            break
        offset += size
    assert len(clip) > settings.FILE_UPLOAD_MAX_MEMORY_SIZE
    r = client.patch(
        profile,
        {
            "video_ad_file": SimpleUploadedFile(
                "showcase.mp4", clip, content_type="video/mp4"
            )
        },
        format="multipart",
    )
    records.append(
        {"method": "PATCH multipart", "route": profile, "status": r.status_code}
    )
    assert r.status_code == 200
    from django.core.files.uploadedfile import TemporaryUploadedFile

    assert isinstance(r.wsgi_request.FILES["video_ad_file"], TemporaryUploadedFile)
    c.refresh_from_db()
    with c.video_ad_file.open("rb") as saved:
        assert saved.read() == clip
    ack = r.data["video_url"]
    fresh = call("get", profile)
    assert fresh.status_code == 200 and fresh.data["video_url"] == ack
    restart_client = APIClient()
    restart_client.force_authenticate(user=owner)
    r = restart_client.get(profile)
    records.append(
        {
            "method": "GET new authenticated client",
            "route": profile,
            "status": r.status_code,
        }
    )
    assert r.status_code == 200 and r.data["video_url"] == ack
    r = call("patch", profile, {"video_ad_file": None})
    assert r.status_code == 200 and r.data["video_url"] is None
    assert (
        r.data["cover_image"] == before_profile["cover_image"]
        and r.data["gallery_images"] == before_profile["gallery_images"]
    )
r = call(
    "put",
    profile,
    {"name_en": "Disposable integration QA", "google_place_id": "QA-Unverified-PUT"},
)
assert r.status_code == 400

# Staff must be rejected by all four protected endpoints.
client.force_authenticate(user=staff)
r = call("post", google + "unlink/", {"expected_current_place_id": ""})
assert r.status_code == 403
client.force_authenticate(user=patient)
assert call("post", google + "unlink/", {}).status_code == 403
client.force_authenticate(user=None)
counts = {}
for name in ["emirates", "cities", "areas"]:
    r = call("get", f"/api/v1/locations/{name}/")
    assert r.status_code == 200 and isinstance(r.data, list)
    counts[name] = len(r.data)
unapproved = Clinic.objects.create(
    name_en="Disposable unapproved QA",
    slug="unapproved-qa",
    status="active",
    setup_status="draft",
    latitude=25.1001,
    longitude=55.2001,
)
r = call("get", "/api/v1/clinics/nearby/?latitude=25.1&longitude=55.2&page_size=20")
assert r.status_code == 200
leaks_draft = any(str(row["id"]) == str(unapproved.id) for row in r.data["results"])
assert not leaks_draft
assert call("get", "/api/v1/clinics/nearby/?city=dubai").status_code == 400
# Manual Home discovery must expose the complete server-paginated count.
for i in range(12):
    Clinic.objects.create(
        name_en=f"Disposable manual {i}",
        slug=f"manual-{i}",
        status="active",
        setup_status="approved",
        city="Dubai",
    )
r = call("get", "/api/v1/home/nearby-clinics/?city=Dubai&page_size=20")
assert r.status_code == 200 and len(r.data["results"]) == 12 and r.data["count"] == 12
# Source-backed all-tier nearest branch, public visibility and numbered pages.
from apps.clinics.models import ClinicBranch

for setup in ["submitted", "rejected"]:
    Clinic.objects.create(
        name_en=f"Hidden {setup}",
        slug=f"hidden-{setup}",
        status="active",
        setup_status=setup,
        latitude=25.1001,
        longitude=55.2001,
    )
for state in ["pending", "suspended"]:
    Clinic.objects.create(
        name_en=f"Hidden {state}",
        slug=f"hidden-{state}",
        status=state,
        setup_status="approved",
        latitude=25.1001,
        longitude=55.2001,
    )
for i, tier in enumerate(["basic", "featured", "vip"]):
    visible = Clinic.objects.create(
        name_en=f"Visible {tier}",
        slug=f"visible-{tier}",
        status="active",
        setup_status="approved",
        subscription_tier=tier,
        latitude=25.4,
        longitude=55.5,
    )
    ClinicBranch.objects.create(
        clinic=visible,
        name_en="Nearest eligible branch",
        latitude=25.101 + i * 0.001,
        longitude=55.201,
        is_active=True,
    )
r = call("get", "/api/v1/clinics/nearby/?latitude=25.1&longitude=55.2&page_size=2")
assert r.status_code == 200 and r.data["count"] == 4 and r.data["next"]
first = r.data["results"][0]
assert (
    first["subscription_tier"] == "basic"
    and first["nearest_branch"]["id"] == first["nearest_branch_id"]
)
assert first["nearest_branch"]["latitude"] == 25.101
r = call(
    "get", "/api/v1/clinics/nearby/?latitude=25.1&longitude=55.2&page_size=2&page=2"
)
assert r.status_code == 200 and r.data["next"] is None
# Production-mode deletion cannot claim a console SMS dispatch.
from django.test import override_settings

patient.email = "disposable@example.invalid"
patient.is_verified = False
patient.is_email_verified = False
patient.save()
client.force_authenticate(user=patient)
with (
    patch("mailer.services.send_email", return_value=True),
    patch(
        "apps.accounts.services.profile_change.generate_otp_code", return_value="654321"
    ),
):
    assert (
        call(
            "post",
            "/api/v1/auth/me/email/change/request/",
            {"new_email": patient.email},
        ).status_code
        == 200
    )
    assert (
        call(
            "post",
            "/api/v1/auth/me/email/change/confirm/",
            {"new_email": patient.email, "code": "654321"},
        ).status_code
        == 200
    )
patient.refresh_from_db()
assert patient.is_email_verified and patient.email_verified_at
r = call("get", "/api/v1/auth/me/")
assert r.data["is_email_verified"] is True
email_provider = Mock()
email_provider.send_otp.return_value = True
with (
    override_settings(DEBUG=False, TESTING=False, SMS_PROVIDER="console"),
    patch(
        "apps.accounts.services.account_deletion.get_email_otp_provider",
        return_value=email_provider,
    ),
):
    r = call("post", "/api/v1/auth/me/deletion/request/", {})
assert r.status_code == 200 and r.data["delivery_channel"] == "email"
assert [d["channel"] for d in r.data["deliveries"]] == ["email"]
assert r.data["masked_destination"] == "d***@example.invalid"
# New errors and permissions must be distinguishable from empty Google results.
client.force_authenticate(user=owner)
for method in ["put", "patch"]:
    for field, value in [
        ("google_place_id", "QA-Unverified"),
        ("google_maps_url", "https://malicious.invalid/map"),
    ]:
        r = call(method, profile, {"name_en": c.name_en, field: value})
        assert r.status_code == 400
for blocked in [staff, patient]:
    client.force_authenticate(user=blocked)
    for endpoint in ["autocomplete", "details", "link", "unlink"]:
        assert call("post", google + endpoint + "/", {}).status_code == 403
client.force_authenticate(user=owner)
with override_settings(GOOGLE_PLACES_API_KEY=""):
    r = call(
        "post",
        google + "autocomplete/",
        {
            "query": "Disposable",
            "session_token": "550e8400-e29b-41d4-a716-446655440000",
        },
    )
    assert r.status_code == 503 and r.data["code"] == "PLACES_PROVIDER_UNAVAILABLE"
# A clinic-scoped mutation must not select an arbitrary clinic for an
# unassigned platform administrator. Reproduce the remaining source behavior;
# Flutter's role guard already rejects this role before making any request.
from apps.clinics.portal_permissions import get_user_clinic

unassigned = User.objects.create_user(phone="+971500000097", role="super_admin")
assert not unassigned.clinic_memberships.exists()
fallback = get_user_clinic(unassigned)
fallback.google_place_id = "QA-Unassigned-Super-Fallback"
fallback.save(update_fields=["google_place_id"])
client.force_authenticate(user=unassigned)
r = call(
    "post",
    google + "unlink/",
    {"expected_current_place_id": "QA-Unassigned-Super-Fallback"},
)
assert (
    r.status_code == 200
    and r.data["id"] == str(fallback.id)
    and not r.data["google_place_id"]
)
# Export only aggregate contract evidence, never the disposable contacts/proofs.
# No OTP, proof, contact or URL is included in exported observations.
assert inventory() == before
result = {
    "backend_commit": "465bf3089dba98a2b0b4145e728daec3c533b0f1",
    "scope": "Isolated source API views; disposable records; mocked Google; no production, device, OTP or R2 verification",
    "responses": records,
    "catalog_counts": counts,
    "autocomplete_key": "suggestions",
    "direct_place_id_patch_blocked": True,
    "CAS_and_expired_reused_proof_rejected": True,
    "manual_pin_preserved": True,
    "genuine_large_MP4_temporary_file_bytes_preserved_and_new_authenticated_client_reload": True,
    "video_removal_preserved_cover_and_gallery": True,
    "source_contract_observations": {
        "clinic_staff_can_mutate_google_association": False,
        "generic_PUT_bypasses_unverified_place_id_guard": False,
        "nearby_returns_active_unapproved_draft": False,
        "nearby_requires_coordinates": True,
        "manual_home_nearby_queryset_top_ten": False,
    },
    "remaining_source_gap_unassigned_super_admin_can_unlink_fallback_clinic": True,
    "persisted_email_verification_and_production_console_SMS_suppression": True,
    "nearest_branch_coordinates_and_full_manual_pagination": True,
    "source_files_unchanged": len(before),
}
a.output.parent.mkdir(exist_ok=True, parents=True)
a.output.write_text(json.dumps(result, indent=2) + "\n")
print(f"{len(records)} source responses verified; {len(before)} source files unchanged")
