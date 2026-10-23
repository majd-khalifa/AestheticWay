# Read-only local contract reproduction; never connects to production.
# Disposable SQLite/media files and generated signing secret are test-only.
import os, sys, json, argparse, pathlib, hashlib, secrets, logging

parser = argparse.ArgumentParser()
parser.add_argument("--backend-root", required=True, type=pathlib.Path)
parser.add_argument("--output", required=True, type=pathlib.Path)
args = parser.parse_args()
backend = args.backend_root.resolve()
if not (backend / "apps/treatments/portal_views.py").is_file():
    raise SystemExit("Expected the supplied Django source root")


def inventory():
    return {
        str(p.relative_to(backend)): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in backend.rglob("*")
        if p.is_file()
    }


before = inventory()
logging.disable(logging.CRITICAL)
os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings.testing"
os.environ["SECRET_KEY"] = secrets.token_urlsafe(48)
sys.dont_write_bytecode = True
sys.path.insert(0, str(backend))
import django

django.setup()
from django.conf import settings

assert (
    settings.DATABASES["default"]["ENGINE"] == "django.db.backends.sqlite3"
    and settings.DATABASES["default"]["NAME"] == ":memory:"
), "Refusing a persistent or production database"
assert settings.EMAIL_BACKEND == "django.core.mail.backends.locmem.EmailBackend"
settings.ALLOWED_HOSTS = ["testserver"]
settings.DEBUG = False
from django.core.management import call_command

call_command("migrate", verbosity=0, interactive=False)
from rest_framework.test import APIClient
from apps.accounts.models import User, UserRole, ClinicUser
from apps.clinics.models import Clinic
from apps.treatments.models import Category, Treatment
from apps.practitioners.models import Practitioner
from apps.treatments.serializers import PublicCategorySerializer

client = APIClient()
clinic = Clinic.objects.create(
    name_en="Isolated QA Clinic A", slug="isolated-qa-clinic-a", status="active"
)
user = User.objects.create_user(
    phone="+971500000001", role=UserRole.CLINIC_ADMIN, is_verified=True
)
ClinicUser.objects.create(
    user=user, clinic=clinic, role_in_clinic="admin", is_active=True
)
client.force_authenticate(user=user)
out = []


def record(method, url, payload=None):
    res = (
        getattr(client, method)(url, payload, format="json")
        if payload is not None
        else getattr(client, method)(url)
    )
    try:
        body = res.json()
    except (ValueError, TypeError):
        body = {"format": res.get("Content-Type", "empty"), "route_match": False}
    out.append(
        dict(
            method=method.upper(),
            url=url,
            status=res.status_code,
            request={k: ("<redacted disposable proof>" if k in {"code", "refresh_token"} else v) for k, v in payload.items()} if isinstance(payload, dict) else payload,
            response=body,
        )
    )
    return res


payload = {"name_en": "skin care", "name_ar": "عناية بالبشرة"}
record("post", "/api/v1/clinic-portal/categories/", payload)
record("post", "/api/v1/categories/", payload)
record("patch", "/api/v1/categories/00000000-0000-4000-8000-000000000001/", payload)
# Safe disposable fixtures in in-memory SQLite + Django test media directory.
import io, pathlib
from PIL import Image
from django.core.files.uploadedfile import SimpleUploadedFile

category = Category.objects.create(
    name_en="QA Skin care", name_ar="عناية بالبشرة", slug="qa-skin-care"
)
practitioner = Practitioner.objects.create(
    clinic=clinic, name_en="QA Practitioner", type="doctor", status="active"
)
other_clinic = Clinic.objects.create(
    name_en="Isolated QA Clinic B", slug="isolated-qa-clinic-b", status="active"
)
other_practitioner = Practitioner.objects.create(
    clinic=other_clinic, name_en="Other QA Practitioner", type="doctor", status="active"
)
record("get", "/api/v1/categories/")
res = record(
    "post",
    "/api/v1/clinic-portal/treatments/",
    {
        "category": str(category.id),
        "name_en": "QA Treatment",
        "name_ar": "إجراء اختبار",
        "price": "250.75",
        "practitioners": [str(practitioner.id)],
    },
)
assert res.status_code == 201
id = res.json()["id"]
route = f"/api/v1/clinic-portal/treatments/{id}/"
assert record("get", route).json()["practitioners"] == [str(practitioner.id)]
assert (
    record("patch", route, {"description_en": "Updated QA description"}).status_code
    == 200
)
assert record("get", route).json()["practitioners"] == [str(practitioner.id)]
assert (
    record("patch", route, {"practitioners": [str(other_practitioner.id)]}).status_code
    == 400
)
assert record("get", f"/api/v1/treatments/{id}/").status_code == 200
other_treatment = Treatment.objects.create(
    clinic=other_clinic, category=category, name_en="Other QA Treatment"
)
for method in ["get", "patch", "delete"]:
    assert (
        record(
            method,
            f"/api/v1/clinic-portal/treatments/{other_treatment.id}/",
            {} if method == "patch" else None,
        ).status_code
        == 404
    )
assert record("delete", route).status_code == 204
assert record("get", f"/api/v1/treatments/{id}/").status_code == 404


def image(name):
    buf = io.BytesIO()
    Image.new("RGB", (32, 32), (120, 120, 120)).save(buf, format="PNG")
    return SimpleUploadedFile(name, buf.getvalue(), content_type="image/png")


def upload(url, data):
    res = client.post(url, data, format="multipart")
    out.append(
        {
            "method": "POST",
            "url": url,
            "status": res.status_code,
            "response": res.json(),
        }
    )
    return res


assets = []
for i in range(3):
    res = upload(
        "/api/v1/media/upload/",
        {
            "file": image(f"qa-gallery-{i}.png"),
            "media_type": "clinic_gallery",
            "clinic_id": str(clinic.id),
        },
    )
    assert res.status_code == 201
    assets.append(res.json())
profile = record("get", "/api/v1/clinic-portal/profile/").json()
assert len(profile["gallery_images"]) == 3
assert len(record("get", f"/api/v1/clinics/{clinic.id}/").json()["gallery_images"]) == 3
record("get", "/api/v1/media/?media_type=clinic_gallery&page=1&page_size=20")
# Switch identities, preserving real object permissions (no production credentials).
patient = User.objects.create_user(
    phone="+971500000002", role=UserRole.PATIENT, is_verified=True
)
client.force_authenticate(user=patient)
assert (
    record(
        "post",
        "/api/v1/clinic-portal/treatments/",
        {"category": str(category.id), "name_en": "Unauthorized"},
    ).status_code
    == 403
)
assert (
    upload(
        "/api/v1/media/upload/",
        {
            "file": image("denied.png"),
            "media_type": "clinic_gallery",
            "clinic_id": str(clinic.id),
        },
    ).status_code
    == 403
)
admin_b = User.objects.create_user(
    phone="+971500000003", role=UserRole.CLINIC_ADMIN, is_verified=True
)
ClinicUser.objects.create(
    user=admin_b, clinic=other_clinic, role_in_clinic="admin", is_active=True
)
client.force_authenticate(user=admin_b)
assert record("delete", f"/api/v1/media/{assets[0]['id']}/").status_code == 403
client.force_authenticate(user=user)
assert record("delete", f"/api/v1/media/{assets[0]['id']}/").status_code == 204
assert (
    len(record("get", "/api/v1/clinic-portal/profile/").json()["gallery_images"]) == 2
)
# Actual MP4 bytes; backend deep validator parses duration without a fake duration.
video_path = (
    pathlib.Path(__file__).resolve().parents[1]
    / "test/fixtures/clinic_media/short_showcase.mp4"
)
clinic.subscription_tier = "vip"
clinic.save()
res = client.patch(
    "/api/v1/clinic-portal/profile/",
    {
        "video_ad_file": SimpleUploadedFile(
            "qa-showcase.mp4", video_path.read_bytes(), content_type="video/mp4"
        )
    },
    format="multipart",
)
out.append(
    {
        "method": "PATCH",
        "url": "/api/v1/clinic-portal/profile/",
        "status": res.status_code,
        "response": res.json(),
    }
)
assert res.status_code == 200 and res.json()["video_ad_file"].endswith(".mp4")
assert (
    record("get", "/api/v1/clinic-portal/profile/")
    .json()["video_ad_file"]
    .endswith(".mp4")
)
assert (
    record("get", f"/api/v1/clinics/{clinic.id}/")
    .json()["video_ad_file"]
    .endswith(".mp4")
)
# Profile image fields take binary multipart directly (not MediaAsset IDs).
for field in ("logo", "cover_image"):
    res = client.patch(
        "/api/v1/clinic-portal/profile/",
        {field: image(f"qa-{field}.png")},
        format="multipart",
    )
    out.append(
        {
            "method": "PATCH",
            "url": "/api/v1/clinic-portal/profile/",
            "request": {field: "<real PNG binary>"},
            "status": res.status_code,
            "response": res.json(),
        }
    )
    assert res.status_code == 200 and res.json()[field].endswith(".png")
    portal = record("get", "/api/v1/clinic-portal/profile/").json()
    public = record("get", f"/api/v1/clinics/{clinic.id}/").json()
    assert portal[field] == public[field]
# All four supported one-image catalog associations: upload -> save -> reopen ->
# public serializer -> omitted PATCH preserves -> explicit null removes -> reopen.
from django.utils import timezone
from datetime import timedelta
from urllib.parse import urljoin

now = timezone.now()
cases = [
    (
        "practitioners",
        "avatar",
        "avatar_url",
        "practitioner_avatar",
        {"name_en": "QA Portrait", "type": "doctor", "status": "active"},
    ),
    (
        "offers",
        "image",
        "image_url",
        "offer_image",
        {
            "title_en": "QA Offer",
            "original_price": "100.00",
            "offer_price": "80.00",
            "starts_at": (now - timedelta(days=1)).isoformat(),
            "ends_at": (now + timedelta(days=1)).isoformat(),
            "status": "active",
        },
    ),
    (
        "products",
        "image",
        "image_url",
        "product_image",
        {
            "name_en": "QA Brand Showcase",
            "brand_name_en": "QA Fixture Brand",
            "status": "active",
        },
    ),
    (
        "articles",
        "cover_image",
        "cover_image_url",
        "article_cover",
        {
            "title_en": "QA Article",
            "content_en": "Synthetic contract test content.",
            "status": "active",
            "is_published": True,
        },
    ),
]
for collection, image_field, url_field, media_type, fields in cases:
    uploaded = upload(
        "/api/v1/media/upload/",
        {
            "file": image("qa-catalog.png"),
            "media_type": media_type,
            "clinic_id": str(clinic.id),
        },
    )
    assert uploaded.status_code == 201
    asset = uploaded.json()
    res = record(
        "post",
        f"/api/v1/clinic-portal/{collection}/",
        {**fields, "media_asset": asset["id"], image_field: asset["url"]},
    )
    assert res.status_code == 201, res.json()
    route = f"/api/v1/clinic-portal/{collection}/{res.json()['id']}/"
    public = f"/api/v1/{collection}/{res.json()['id']}/"
    assert record("get", route).json()["media_asset"] == asset["id"]
    public_url = record("get", public).json()[url_field]
    assert urljoin("http://testserver", public_url) == asset["url"], (
        collection,
        public_url,
        asset["url"],
    )
    assert record("patch", route, {}).json()["media_asset"] == asset["id"]
    assert (
        record("patch", route, {image_field: None, "media_asset": None}).status_code
        == 200
    )
    assert not record("get", route).json()[url_field]
    assert not record("get", public).json()[url_field]
# Entitlement gates new uploads, not removal of an already-owned video.
clinic.subscription_tier = "basic"
clinic.save()
assert (
    record(
        "patch", "/api/v1/clinic-portal/profile/", {"video_ad_file": None}
    ).status_code
    == 200
)
assert not record("get", "/api/v1/clinic-portal/profile/").json()["video_ad_file"]
# 1f1e4bf additions: real view/serializer execution, never production accounts.
from apps.treatments.models import CategoryRequest
from apps.accounts.services.sms import MockSmsProvider
from django.core.cache import cache
from apps.accounts.services.account_deletion import AccountDeletionService

client.force_authenticate(user=user)
requests_url = "/api/v1/clinic-portal/category-requests/"
proposal = record("post", requests_url, {"name_en": "QA New Category", "name_ar": "تصنيف اختبار جديد"})
assert proposal.status_code == 201 and proposal.json()["status"] == "pending"
request_id = proposal.json()["id"]
assert record("post", requests_url, {"name_en": "qa new category"}).status_code == 409
assert record("post", requests_url, {"name_en": category.name_en}).json()["error"]["code"] == "CATEGORY_ALREADY_EXISTS"
assert record("get", requests_url).status_code == 200
other_user = User.objects.create_user(phone="+971500000021", role="clinic_admin")
ClinicUser.objects.create(user=other_user, clinic=other_clinic, role_in_clinic="admin", is_active=True)
client.force_authenticate(user=other_user)
assert record("get", f"{requests_url}{request_id}/").status_code == 404
admin = User.objects.create_user(phone="+971500000022", role="super_admin")
admin_url = "/api/v1/admin-portal/treatment-categories/"
review_url = "/api/v1/admin-portal/category-requests/"
assert record("post", admin_url, {"name_en": "Forbidden"}).status_code == 403
client.force_authenticate(user=admin)
assert record("get", review_url + "?status=pending").json()["count"] == 1
approved = record("post", f"{review_url}{request_id}/approve/", {})
assert approved.status_code == 200 and approved.json()["status"] == "approved"
resolved = approved.json()["resolved_category_id"]
client.force_authenticate(user=user)
assert record("get", f"{requests_url}{request_id}/").json()["resolved_category_id"] == resolved
second = record("post", requests_url, {"name_en": "QA Rejection Candidate"}).json()["id"]
client.force_authenticate(user=admin)
assert record("post", f"{review_url}{second}/reject/", {"rejection_reason": "Use the existing taxonomy."}).json()["rejection_reason"] == "Use the existing taxonomy."
created = record("post", admin_url, {"name_en": "QA Disposable Category", "name_ar": "اختبار", "display_order": 4})
assert created.status_code == 201
created_id, slug = created.json()["id"], created.json()["slug"]
assert record("patch", f"{admin_url}{created_id}/", {"name_en": "QA Renamed", "display_order": 8, "is_active": False}).json()["slug"] == slug
assert record("delete", f"{admin_url}{created_id}/").status_code == 204
in_use = Treatment.objects.create(clinic=clinic, category=category, name_en="QA Protected")
assert record("delete", f"{admin_url}{category.id}/").json()["error"]["code"] == "CATEGORY_IN_USE"
assert record("patch", f"{admin_url}{category.id}/", {"is_active": False}).status_code == 200
client.force_authenticate(user=user)
assert record("patch", f"/api/v1/clinic-portal/treatments/{in_use.id}/", {"category": str(category.id), "name_en": "QA Preserve Archived"}).status_code == 200
assert record("post", "/api/v1/clinic-portal/treatments/", {"category": str(category.id), "name_en": "QA Reject Archived"}).status_code == 400
client.force_authenticate(user=admin)
assert record("post", "/api/v1/clinic-portal/treatments/", {"category": resolved, "name_en": "QA No Membership"}).status_code == 403

# Only purpose-bound disposable challenges. Never include OTPs or JWTs in output.
for index, role in enumerate(["patient", "clinic_admin", "super_admin"]):
    disposable = User.objects.create_user(phone=f"+97150000003{index}", role=role, full_name="Disposable QA")
    client.force_authenticate(user=disposable)
    cache.clear(); MockSmsProvider.reset()
    start = record("post", "/api/v1/auth/me/deletion/request/", {})
    assert start.status_code == 200 and start.json()["success"]
    proof = MockSmsProvider.sent_messages[-1]["code"]
    assert record("post", "/api/v1/auth/me/deletion/confirm/", {"code": "incorrect"}).status_code == 400
    assert record("post", "/api/v1/auth/me/deletion/confirm/", {"code": proof}).json()["success"]
    disposable.refresh_from_db()
    assert not disposable.is_active and disposable.deleted_at and disposable.full_name == "Deleted User"
client.force_authenticate(user=user)
assert record("post", "/api/v1/auth/me/deletion/request/", {}).json()["code"] == "SOLE_CLINIC_ADMIN"
client.force_authenticate(user=admin)
assert record("post", "/api/v1/auth/me/deletion/request/", {}).json()["code"] == "LAST_SUPER_ADMIN"
expired_user = User.objects.create_user(phone="+971500000040", role="patient")
client.force_authenticate(user=expired_user)
assert record("post", "/api/v1/auth/me/deletion/confirm/", {"code": "123456"}).status_code == 400
expired_user.refresh_from_db(); assert expired_user.is_active
client.force_authenticate(user=None)
assert record("post", "/api/v1/auth/me/deletion/request/", {}).status_code == 401

assert inventory() == before, "Backend source was changed"
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(
    json.dumps(
        {
            "files_unchanged": len(before),
            "environment": "isolated in-memory SQLite, local test storage; force-authenticated disposable role fixtures; not production/R2/JWT verification",
            "records": out,
        },
        ensure_ascii=False,
        indent=2,
    )
    + "\n"
)
print(
    f"Local Django contract cases passed: {len(out)} responses; {len(before)} backend file hashes unchanged. Evidence: {args.output}"
)
