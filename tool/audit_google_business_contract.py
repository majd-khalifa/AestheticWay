"""Read-only supplied Django source probe; no live or Google traffic."""

import argparse
import hashlib
import json
import logging
import os
import secrets
import sys
import tempfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--backend-root", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
a = parser.parse_args()
root = a.backend_root.resolve()


def inventory():
    return {
        str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in root.rglob("*")
        if p.is_file()
    }


before = inventory()
sys.dont_write_bytecode = True
sys.path.insert(0, str(root))
os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings.testing"
os.environ["SECRET_KEY"] = secrets.token_urlsafe(48)
logging.disable(logging.CRITICAL)
import django

django.setup()
from django.conf import settings

assert settings.DATABASES["default"]["NAME"] == ":memory:"
settings.DEBUG = False
settings.ALLOWED_HOSTS = ["testserver"]
from django.core.management import call_command

call_command("migrate", verbosity=0, interactive=False)
from apps.accounts.models import ClinicUser, User
from apps.clinics.models import Clinic
from django.core.files.storage import FileSystemStorage
from rest_framework.test import APIClient

client = APIClient()
owner = User.objects.create_user(phone="+971500000094", role="clinic_admin")
patient = User.objects.create_user(phone="+971500000095", role="patient")
c = Clinic.objects.create(
    name_en="Disposable association QA",
    slug="association-qa",
    status="pending",
    setup_status="draft",
    google_place_id="QA-Place-Identity",
)
ClinicUser.objects.create(user=owner, clinic=c, role_in_clinic="admin", is_active=True)
foreign = Clinic.objects.create(
    name_en="Other tenant QA",
    slug="association-other",
    google_place_id="QA-Other-Identity",
)
with tempfile.TemporaryDirectory(prefix="aw-association-") as tmp:
    storage = FileSystemStorage(location=tmp, base_url="/qa-media/")
    for field in ["cover_image", "video_ad_file"]:
        Clinic._meta.get_field(field).storage = storage
    c.cover_image = "preserved/cover.png"
    c.video_ad_file = "preserved/video.mp4"
    c.latitude = 25.1
    c.longitude = 55.2
    c.google_maps_url = "https://www.google.com/maps/search/?api=1&query_place_id=QA-Place-Identity&query=QA-Place-Identity"
    c.google_rating = 4.5
    c.google_reviews_count = 12
    c.google_sync_status = "synced"
    c.save()
    records = []

    def call(method, data=None):
        route = "/api/v1/clinic-portal/profile/"
        r = (
            getattr(client, method)(route, data, format="json")
            if data is not None
            else client.get(route)
        )
        records.append(
            {"method": method.upper(), "route": route, "status": r.status_code}
        )
        return r

    client.force_authenticate(user=owner)
    first = call("get")
    assert first.status_code == 200
    body = first.json()
    assert body["google_place_id"] == "QA-Place-Identity"
    assert body["google_sync_status"] == "synced"
    # Manual pin PATCH never supplies or mutates the business identity/URL.
    moved = call("patch", {"latitude": 25.11, "longitude": 55.21})
    assert moved.status_code == 200
    c.refresh_from_db()
    assert (
        c.google_place_id == "QA-Place-Identity"
        and c.google_maps_url == body["google_maps_url"]
    )
    unlinked = call("patch", {"google_place_id": "", "google_maps_url": ""})
    assert unlinked.status_code == 200
    fresh = call("get")
    assert fresh.status_code == 200
    clean = fresh.json()
    assert clean["google_place_id"] == "" and clean["google_maps_url"] == ""
    assert (
        clean["google_rating"] is None
        and clean["google_reviews_count"] == 0
        and clean["google_sync_status"] == "not_configured"
    )
    c.refresh_from_db()
    assert (
        c.cover_image.name == "preserved/cover.png"
        and c.video_ad_file.name == "preserved/video.mp4"
    )
    assert float(c.latitude) == 25.11 and float(c.longitude) == 55.21
    # Confirm the current generic serializer accepts an unverified identity.
    # This is a backend verification gap; production Flutter linking stays off.
    accepted = call("patch", {"google_place_id": "QA-Unverified-New-Identity"})
    assert accepted.status_code == 200
    assert accepted.json()["google_sync_status"] == "pending"
    foreign.refresh_from_db()
    assert foreign.google_place_id == "QA-Other-Identity"
    client.force_authenticate(user=patient)
    assert call("patch", {"google_place_id": ""}).status_code == 403
    client.force_authenticate(user=None)
    assert call("get").status_code in [401, 403]
assert inventory() == before
result = {
    "backend_commit": "09f49bbd22131f6dad49a65a5167de5396f03797",
    "scope": "Isolated SQLite/source profile views; synthetic records; no production, Google, R2 or OTP traffic",
    "responses": records,
    "generic_patch_accepts_unverified_nonempty_place_id": True,
    "manual_pin_preserved_business": True,
    "unlink_cleared_identity_url_cached_ratings": True,
    "unlink_preserved_pin_cover_video_and_other_tenant": True,
    "source_files_unchanged": len(before),
}
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(result, indent=2) + "\n")
print(f"{len(records)} source responses passed; {len(before)} source files unchanged")
