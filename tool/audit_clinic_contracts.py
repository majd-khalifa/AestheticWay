# Read-only local contract reproduction; never connects to production.
# Disposable SQLite/media files and generated signing secret are test-only.
import os, sys, json, argparse, pathlib, hashlib, secrets, logging

parser = argparse.ArgumentParser()
parser.add_argument("--backend-root", required=True, type=pathlib.Path)
parser.add_argument("--output", required=True, type=pathlib.Path)
args = parser.parse_args()
backend = args.backend_root.resolve()
if not (backend / "apps/treatments/portal_views.py").is_file():
    raise SystemExit("Expected the supplied d1023b0 source root")


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
            request=payload,
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
