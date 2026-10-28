"""Read-only source QA: no production traffic, real accounts or credentials."""

import argparse
import hashlib
import io
import json
import logging
import os
import secrets
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

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
from django.conf import settings

assert settings.DATABASES["default"]["NAME"] == ":memory:"
settings.DEBUG = False
settings.ALLOWED_HOSTS = ["testserver"]
from django.core.management import call_command

call_command("migrate", verbosity=0, interactive=False)
from apps.accounts.models import ClinicUser, User
from apps.clinics.models import Clinic
from django.core.cache import cache
from django.core.files.storage import FileSystemStorage
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image
from rest_framework.test import APIClient

client = APIClient()
owner = User.objects.create_user(phone="+971500000091", role="clinic_admin")
c = Clinic.objects.create(
    name_en="Disposable video QA",
    slug="geo-video-qa",
    subscription_tier="vip",
    setup_status="submitted",
    status="pending",
)
ClinicUser.objects.create(clinic=c, user=owner, role_in_clinic="admin", is_active=True)
records = []
private = "/api/v1/clinic-portal/profile/"


def record(name, response):
    records.append({"case": name, "status": response.status_code})
    return response


with tempfile.TemporaryDirectory(prefix="aw-geo-media-") as tmp:
    storage = FileSystemStorage(location=tmp, base_url="/qa-media/")
    for name in ["video_ad_file", "cover_image"]:
        Clinic._meta.get_field(name).storage = storage
    image = io.BytesIO()
    Image.new("RGB", (20, 20)).save(image, format="PNG")
    c.cover_image.save(
        "qa.png",
        SimpleUploadedFile("qa.png", image.getvalue(), content_type="image/png"),
    )
    cover = c.cover_image.name
    client.force_authenticate(user=owner)
    video = (
        Path(__file__).resolve().parents[1]
        / "test/fixtures/clinic_media/short_showcase.mp4"
    ).read_bytes()

    def upload(data):
        return client.patch(
            private,
            {
                "video_ad_file": SimpleUploadedFile(
                    "qa.mp4", data, content_type="video/mp4"
                )
            },
            format="multipart",
        )

    valid = record("pending VIP actual multipart MP4", upload(video))
    assert valid.status_code == 200
    get = record("fresh authenticated GET", client.get(private))
    assert get.json()["video_ad_file"] == valid.json()["video_ad_file"]
    c.refresh_from_db()
    assert storage.exists(c.video_ad_file.name) and c.cover_image.name == cover
    old = c.video_ad_file.name
    invalid = record(
        "invalid MP4 duration returns a field validation error",
        upload(b"\x00\x00\x00\x18ftypisom" + b"\x00" * 80),
    )
    assert invalid.status_code == 400
    with patch.object(storage, "save", side_effect=OSError("Synthetic storage fault")):
        failed = record(
            "storage failure maps to HTTP500, not a gallery operation", upload(video)
        )
    assert failed.status_code == 500
    c.refresh_from_db()
    assert c.video_ad_file.name == old
    removed = record(
        "remove video via JSON null",
        client.patch(private, {"video_ad_file": None}, format="json"),
    )
    assert removed.status_code == 200
    c.refresh_from_db()
    assert not c.video_ad_file and c.cover_image.name == cover
    for tier in ["basic", "featured"]:
        c.subscription_tier = tier
        c.save(update_fields=["subscription_tier"])
        assert record(f"{tier} forbidden upload", upload(video)).status_code == 400
# A nearer Basic must not be claimed nearest when the backend sorts a farther VIP first.
Clinic.objects.all().update(status="suspended")
near = Clinic.objects.create(
    name_en="Near Basic QA",
    slug="near-qa",
    status="active",
    setup_status="approved",
    subscription_tier="basic",
    latitude=25.1001,
    longitude=55.2001,
)
far = Clinic.objects.create(
    name_en="Far VIP QA",
    slug="far-qa",
    status="active",
    setup_status="approved",
    subscription_tier="vip",
    latitude=25.8,
    longitude=55.9,
)
client.force_authenticate(user=None)
for endpoint in [
    "/api/v1/clinics/",
    "/api/v1/home/nearby-clinics/",
    "/api/v1/home/feed/",
]:
    r = record(
        endpoint + " remains tier-first",
        client.get(endpoint, {"latitude": 25.1, "longitude": 55.2}),
    )
    assert r.status_code == 200
    body = r.json()
    rows = body.get("results", body.get("nearby_clinics", []))
    assert rows[0]["id"] == str(far.id)
    assert rows[0]["distance"] > rows[1]["distance"]
    assert "distance_km" not in rows[0]
patient = User.objects.create_user(phone="+971500000092", role="patient")
client.force_authenticate(user=patient)
cache.clear()
with patch("apps.accounts.services.account_deletion.get_sms_provider") as provider:
    provider.return_value.send_otp.return_value = True
    otp = record(
        "deletion request no destination contract",
        client.post("/api/v1/auth/me/deletion/request/", {}, format="json"),
    )
assert otp.status_code == 200
assert set(otp.json()) == {"success", "message", "expires_in", "resend_cooldown"}
assert inventory() == before
output = {
    "backend_archive_commit": "09f49bbd22131f6dad49a65a5167de5396f03797",
    "environment": "isolated SQLite / temporary local media / mocked OTP provider; not production",
    "responses": records,
    "source_files_unchanged": len(before),
    "source_unchanged": True,
}
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(output, indent=2) + "\n")
print(f"{len(records)} source probes passed; {len(before)} source files unchanged")
