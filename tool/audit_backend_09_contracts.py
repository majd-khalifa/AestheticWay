"""Read-only supplied-source probes. No production traffic or credential output."""

import argparse, hashlib, json, os, pathlib, secrets, sys, tempfile, logging

p = argparse.ArgumentParser()
p.add_argument("--backend-root", type=pathlib.Path, required=True)
p.add_argument("--output", type=pathlib.Path, required=True)
args = p.parse_args()
backend = args.backend_root.resolve()


def inventory():
    return {
        str(f.relative_to(backend)): hashlib.sha256(f.read_bytes()).hexdigest()
        for f in backend.rglob("*")
        if f.is_file()
    }


before = inventory()
sys.dont_write_bytecode = True
sys.path.insert(0, str(backend))
os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings.testing"
os.environ["SECRET_KEY"] = secrets.token_urlsafe(48)
logging.disable(logging.CRITICAL)
import django

django.setup()
from django.conf import settings

assert settings.DATABASES["default"]["NAME"] == ":memory:"
settings.ALLOWED_HOSTS = ["testserver"]
settings.DEBUG = False
from django.core.management import call_command

call_command("migrate", verbosity=0, interactive=False)
from rest_framework.test import APIClient
from django.core.files.storage import FileSystemStorage
from django.core.files.uploadedfile import SimpleUploadedFile
from apps.accounts.models import User, ClinicUser
from apps.clinics.models import Clinic, ClinicBranch
from apps.practitioners.models import Practitioner
from apps.treatments.models import Category, Treatment
from apps.media.models import MediaAsset
from django.utils import timezone
from datetime import timedelta
from PIL import Image
import io

client = APIClient()
records = []
facts = {}
# Store test media outside the supplied source and keep URLs explicitly local.
storage = FileSystemStorage(
    location=tempfile.mkdtemp(prefix="aw09-media-"), base_url="/qa-media/"
)
for model, field in [
    (Clinic, "logo"),
    (Clinic, "cover_image"),
    (Clinic, "video_ad_file"),
    (MediaAsset, "file"),
]:
    model._meta.get_field(field).storage = storage


def req(method, path, data=None, multipart=False):
    r = (
        getattr(client, method)(path, data, format="multipart" if multipart else "json")
        if data is not None
        else getattr(client, method)(path)
    )
    try:
        b = r.json()
    except ValueError:
        b = {}
    # No complete private DTOs, OTPs, contact data, credentials or signed URLs.
    safe = {
        k: b[k]
        for k in [
            "status",
            "setup_status",
            "subscription_tier",
            "submitted_setup_count",
            "count",
            "new_status",
            "success",
            "rejection_reason",
            "setup_rejection_reason",
            "moderation_notes",
        ]
        if k in b
    }
    if isinstance(b.get("error"), dict):
        safe["error_code"] = b["error"].get("code")
    records.append(
        {
            "method": method.upper(),
            "path": path,
            "status": r.status_code,
            "summary": safe,
        }
    )
    return r, b


def png():
    b = io.BytesIO()
    Image.new("RGB", (24, 24), (170, 150, 100)).save(b, format="PNG")
    return SimpleUploadedFile("qa.png", b.getvalue(), content_type="image/png")


admin = User.objects.create_user(
    phone="+971500000001", role="super_admin", is_staff=True
)
owner = User.objects.create_user(phone="+971500000002", role="clinic_admin")
patient = User.objects.create_user(phone="+971500000003", role="patient")
c = Clinic.objects.create(
    name_en="Disposable QA clinic",
    slug="qa-09",
    status="pending",
    setup_status="submitted",
    subscription_tier="vip",
    description_en="Local fixture",
    description_ar="بيانات اختبار",
    phone="+97141110000",
)
ClinicUser.objects.create(user=owner, clinic=c, role_in_clinic="admin", is_active=True)
c.logo.save("logo.png", png())
c.cover_image.save("cover.png", png())
cover = c.cover_image.name
ClinicBranch.objects.create(
    clinic=c, name_en="QA branch", is_active=True, latitude=25.1, longitude=55.2
)
cat = Category.objects.create(name_en="QA category", slug="qa09")
staff = Practitioner.objects.create(
    clinic=c, name_en="QA practitioner", type="doctor", status="pending"
)
treatment = Treatment.objects.create(
    clinic=c, category=cat, name_en="QA treatment", status="pending"
)
other = Clinic.objects.create(
    name_en="Other QA", slug="qa09-other", setup_status="draft"
)
foreign = Practitioner.objects.create(clinic=other, name_en="Foreign QA", type="doctor")
for target, typ in [
    (c, "clinic_gallery"),
    (other, "clinic_gallery"),
    (c, "practitioner_avatar"),
]:
    MediaAsset.objects.create(
        clinic=target,
        uploader=owner,
        media_type=typ,
        file=png(),
        original_filename="qa.png",
        file_size=100,
        mime_type="image/png",
    )
private = "/api/v1/clinic-portal/profile/"
detail = f"/api/v1/admin/clinics/{c.id}/"
client.force_authenticate(user=owner)
assert req("get", private)[1]["subscription_tier"] == "vip"
assert req("get", f"/api/v1/clinics/{c.id}/")[0].status_code == 404
video_bytes = (
    pathlib.Path(__file__).resolve().parents[1]
    / "test/fixtures/clinic_media/short_showcase.mp4"
).read_bytes()
for tier in ["vip", "featured", "basic"]:
    c.subscription_tier = tier
    c.save(update_fields=["subscription_tier"])
    assert (
        req(
            "patch",
            private,
            {"subscription_tier": "vip", "name_en": "Disposable QA clinic"},
        )[1]["subscription_tier"]
        == tier
    )
    r, b = req(
        "patch",
        private,
        {
            "video_ad_file": SimpleUploadedFile(
                "qa.mp4", video_bytes, content_type="video/mp4"
            )
        },
        True,
    )
    assert r.status_code == (200 if tier == "vip" else 400)
    if tier == "vip":
        assert b["subscription_tier"] == "vip" and b["video_ad_file"].endswith(".mp4")
        c.refresh_from_db()
        assert storage.exists(c.video_ad_file.name)
        # A fresh client reconstructs the authenticated screen's source state.
        fresh = APIClient()
        fresh.force_authenticate(user=owner)
        assert fresh.get(private).json()["video_ad_file"] == b["video_ad_file"]
    r, b = req("patch", private, {"video_ad_file": None})
    assert r.status_code == 200 and not b["video_ad_file"]
    c.refresh_from_db()
    assert c.cover_image.name == cover
client.force_authenticate(user=admin)
r, b = req("get", "/api/v1/admin/clinics/?setup_status=submitted")
assert all(x["setup_status"] == "submitted" for x in b["results"]) and b["count"] == 1
assert req("get", "/api/v1/admin/dashboard/")[1]["submitted_setup_count"] == 1
r, b = req("get", detail)
assert {x["id"] for x in b["practitioners"]} == {str(staff.id)}
assert {x["id"] for x in b["treatments"]} == {str(treatment.id)}
assert len(b["gallery_assets"]) == 1
facts["detail_projections_tenant_scoped"] = True
assert (
    req("post", detail + "reject-setup/", {"rejection_reason": ""})[0].status_code
    == 400
)
r, b = req(
    "post", detail + "reject-setup/", {"rejection_reason": "Replace the QA cover."}
)
assert r.status_code == 200 and b["setup_status"] == "rejected"
c.refresh_from_db()
assert c.status == "pending"
assert req("get", "/api/v1/admin/dashboard/")[1]["submitted_setup_count"] == 0
client.force_authenticate(user=owner)
assert req("get", private)[1]["setup_rejection_reason"] == "Replace the QA cover."
assert (
    req("get", private + "setup-checklist/")[1]["setup_rejection_reason"]
    == "Replace the QA cover."
)
assert req("post", private + "submit-for-review/", {})[1]["setup_status"] == "submitted"
c.refresh_from_db()
facts["resubmission_retains_prior_moderation_notes"] = (
    c.moderation_notes == "Replace the QA cover."
)
client.force_authenticate(user=admin)
r, b = req("post", detail + "verify/", {})
assert (
    r.status_code == 200
    and b["setup_status"] == "approved"
    and b["new_status"] == "active"
)
assert req("post", detail + "verify/", {})[0].status_code == 409
client.force_authenticate(user=owner)
assert (
    req("post", private + "submit-for-review/", {})[1]["error"]["code"]
    == "ALREADY_APPROVED"
)
client.force_authenticate(user=admin)
r, b = req(
    "post", detail + "reject-setup/", {"rejection_reason": "QA transition probe"}
)
assert r.status_code == 200
facts["reject_accepts_previously_approved"] = True
incomplete = Clinic.objects.create(
    name_en="Incomplete QA", slug="incomplete-qa", setup_status="submitted"
)
r, b = req("post", f"/api/v1/admin/clinics/{incomplete.id}/verify/", {})
assert r.status_code == 409 and b["error"]["code"] == "CLINIC_SETUP_INCOMPLETE"
for role in [patient, owner, None]:
    client.force_authenticate(user=role)
    for suffix in ["verify/", "reject-setup/"]:
        assert req("post", detail + suffix, {"rejection_reason": "QA forbidden"})[
            0
        ].status_code in [401, 403]
# Exercise real filtered pagination and a global total beyond the first page.
client.force_authenticate(user=admin)
Clinic.objects.bulk_create(
    [
        Clinic(
            name_en=f"Pagination QA {i}",
            slug=f"pagination-qa-{i}",
            setup_status="submitted",
        )
        for i in range(21)
    ]
)
r, first = req(
    "get", "/api/v1/admin/clinics/?setup_status=submitted&page_size=20&page=1"
)
r, second = req(
    "get", "/api/v1/admin/clinics/?setup_status=submitted&page_size=20&page=2"
)
assert (
    first["count"] == 22
    and second["count"] == 22
    and len(first["results"]) == 20
    and len(second["results"]) == 2
    and first["next"]
)
assert {x["id"] for x in first["results"]}.isdisjoint(
    {x["id"] for x in second["results"]}
)
assert req("get", "/api/v1/admin/dashboard/")[1]["submitted_setup_count"] == 22
facts["filtered_pagination_and_global_total_beyond_first_page"] = True
# Public HTML route: anonymous local view only, not live HTTPS evidence.
client.force_authenticate(user=None)
r, _ = req("get", "/account-deletion/")
assert r.status_code == 200 and b"AESTHETIC WAY" in r.content
# Privacy: drive the real purpose-bound OTP endpoints, never export the proof.
from apps.accounts.services.sms import MockSmsProvider
from apps.referrals.models import ReferralInvite
from apps.leads.models import Lead

inv = ReferralInvite.objects.create(
    referrer=owner,
    referred_user=patient,
    invitee_phone=patient.phone,
    notes="Disposable personal note",
)
old_phone = patient.phone
personal = MediaAsset.objects.create(
    uploader=patient,
    clinic=None,
    media_type="patient_avatar",
    file=png(),
    original_filename="qa.png",
    file_size=100,
    mime_type="image/png",
)
client.force_authenticate(user=patient)
assert req("post", "/api/v1/auth/me/deletion/request/", {})[0].status_code == 200
code = MockSmsProvider.sent_messages[-1]["code"]
assert (
    req("post", "/api/v1/auth/me/deletion/confirm/", {"code": "incorrect"})[
        0
    ].status_code
    == 400
)
assert (
    req("post", "/api/v1/auth/me/deletion/confirm/", {"code": code})[1]["success"]
    is True
)
patient.refresh_from_db()
inv.refresh_from_db()
assert not patient.is_active and not MediaAsset.objects.filter(id=personal.id).exists()
facts["deleted_patient_phone_retained_in_received_invite"] = (
    inv.invitee_phone == old_phone
)
facts["received_invite_note_retained"] = bool(inv.notes)
assert inventory() == before, "Supplied Django source changed"
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(
    json.dumps(
        {
            "source_commit": "09f49bbd22131f6dad49a65a5167de5396f03797",
            "source_files_unchanged": len(before),
            "environment": "isolated in-memory SQLite / local test files / force-authenticated disposable roles; no live JWT, R2 or production verification",
            "facts": facts,
            "responses": records,
        },
        indent=2,
    )
    + "\n"
)
print(
    f"{len(records)} actual Django responses passed; {len(before)} source files unchanged"
)
