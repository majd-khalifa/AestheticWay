# AESTHETIC WAY — Backend handoff for Ali / تسليم إصلاحات الباك إند إلى علي

Date / التاريخ: 2026-10-19. **Specification only; no backend source was changed. / هذه مواصفات تنفيذ فقط؛ لم يتم تعديل ملفات الباك إند.**

## Scope, evidence, and deployment dependency / النطاق والأدلة واعتماد النشر

The backend inspected here is the supplied `backend.zip`, extracted at `/workspace/work/audit/backend`, not the inaccessible Windows path `C:\Users\MVJD\Desktop\UAE_project\backend`. Archive SHA-256: `6cf2d3ef00e54b1c6b62b8fb184436c3f2a5acda3b576ced810f4a38cbae6c1c`. Line numbers below refer to this snapshot. Rebase snippets against Ali's current branch before applying them. The supplied source does **not** contain the newly described URL/binary media support; that support is a user-specified integration contract, not a verified deployment fact.

المراجعة مبنية على الأرشيف المرفق؛ المسار المحلي في ويندوز غير متاح في هذه البيئة. أرقام الأسطر تخص نسخة الأرشيف وقد تتغير في فرع علي. دعم روابط الصور والملفات الذي ذكره علي هو عقد التكامل المطلوب؛ لا يمكن تأكيد نشره من الأرشيف القديم.

Frontend now preserves upload errors, signed URLs, explicit JSON `null`, and partial lead responses. It submits provisioning branding as real multipart files, with flat administrator keys when multipart is needed. **Deploy the matching backend changes before treating provisioning branding and URL-based clinic image updates as verified end-to-end.** No production storage/credentials were available for a live R2 test.

الفرونت يحافظ الآن على أخطاء الرفع والروابط الموقعة وقيم الحذف الصريحة. إنشاء العيادة مع الصور يتطلب نشر إصلاح عقد الإنشاء أدناه. الاختبارات المحلية لا تثبت نجاح التخزين الفعلي في R2.

### Priority / الأولوية

| Priority | Backend location in supplied snapshot | Required outcome / النتيجة |
|---|---|---|
| P0 | `apps/accounts/services/otp.py:213,289`; `apps/accounts/views.py:189,434` | Recovery OTP checked twice but consumed once / التحقق مرتين والاستهلاك مرة واحدة |
| P0 | `apps/practitioners/models.py:96`; `apps/offers/models.py:78`; all catalog `portal_serializers.py` | Fresh asset URL wins, removals persist, tenant assignment enforced / أولوية الصورة الجديدة وعزل العيادات |
| P0 | `apps/clinics/portal_permissions.py:8,46`; `apps/leads/views/clinic_views.py:31,56` | All clinic endpoints reject suspended clinics and foreign tenants / منع العيادات الموقوفة |
| P1 | `apps/accounts/serializers.py:94–111`; `apps/accounts/views.py:141` | No patient JWT before verification / منع دخول المريض غير الموثق |
| P1 | `apps/admin_portal/serializers.py:92–111`; `services/clinic_provisioning.py:20,45` | Branding and administrator metadata survive provisioning / حفظ الهوية وبيانات المشرف |
| P1 | `apps/leads/views/clinic_views.py:115,117` | PATCH returns the full lead / إرجاع بيانات الطلب كاملة |
| P1 | URL model fields listed in section 3 | No 200-character rejection / إزالة حد ٢٠٠ حرف |

## 1. Password recovery OTP double consumption / استهلاك رمز الاستعادة مرتين

**Observed / المثبت:** `VerifyOtpView.post` calls `OtpService.verify_otp`; its success branch deletes the Redis OTP key. The mobile flow then posts the same OTP to `ResetPasswordView`, which verifies it again. The second call returns `422 OTP_EXPIRED`. The database OTP audit record is not the verification authority; the Redis key is. Calling this a database `is_used` bug would be misleading.

السبب هو حذف مفتاح Redis بعد شاشة التحقق، ثم محاولة فحص الرمز نفسه عند تغيير كلمة المرور. لا تحذف التحقق النهائي من `ResetPasswordView`، ولا تسمح بإعادة تعيين كلمة المرور اعتماداً على رقم الهاتف فقط.

### Exact compatible patch / تعديل متوافق مع التطبيق الحالي

In `apps/accounts/services/otp.py:213`, replace the method signature only; preserve every existing hash, expiry, lockout and IP-attempt check at lines 226–287:

```python
@staticmethod
def verify_otp(
    phone: str,
    purpose: str,
    code: str,
    ip_address: str = "unknown",
    *,
    consume: bool = True,
) -> bool:
    # Keep the existing body through its constant-time comparison and invalid-code branch.
    # Replace only the success tail using the next code block.
    ...
```

Replace success tail `otp.py:289–295` with the following, inside that existing method:

```python
if not consume:
    # Do not refresh TTL, reset attempt counters, or create a reusable phone grant.
    return True

# Redis/LocMem delete is atomic and returns whether the key existed. Two racing
# successful verifications may compare the same hash, but only one may consume it.
if not cache.delete(otp_key):
    raise OtpExpiredError("OTP already used. Please request a new one.")
cache.delete(attempts_key)
cache.delete(_locked_key(phone, purpose))
logger.info("OTP consumed successfully for %s purpose=%s", phone, purpose)
return True
```

Replace the call in `apps/accounts/views.py:189` with:

```python
OtpService.verify_otp(
    phone,
    purpose,
    code,
    ip_address=ip,
    consume=(purpose != "password_reset"),
)
```

Keep the final reset call at `views.py:434` consuming:

```python
OtpService.verify_otp(
    phone, "password_reset", code, ip_address=ip, consume=True,
)
```

`ResetPasswordSerializer` must continue requiring the OTP and validating password quality. Retain the active-user lookup, password hashing and refresh-token revocation at `views.py:438+`. This patch changes neither request nor response keys and supports existing mobile versions. A future opaque, short-lived, single-use reset grant is also viable, but requires a coordinated mobile/API change; do not mix the two protocols silently.

هذا الحل لا يغيّر مفاتيح الطلب أو الاستجابة. فحص شاشة التحقق لا يستهلك الرمز ولا يطيل صلاحيته؛ تغيير كلمة المرور يستهلكه مرة واحدة. يجب اختبار السباق على Redis الحقيقي لأن قاعدة البيانات لا تجعل عمليتي قراءة/حذف الكاش معاملة واحدة.

**Acceptance / القبول:** valid verify → reset succeeds once; repeated reset fails; wrong/expired OTP fails; wrong purpose fails; lockout/IP limits remain effective; password and token revocation persist; two simultaneous resets permit only one consumption. Isolate cache state between tests; the original suite contains order-dependent OTP cache failures.

## 2. Fresh image precedence and image removal / أولوية الصورة الجديدة وحذف الصور

### Models / الموديلات

Replace `Practitioner.avatar_url` at `apps/practitioners/models.py:96`:

```python
@property
def avatar_url(self) -> str:
    if self.media_asset_id and self.media_asset.file:
        return self.media_asset.file.url
    return self.avatar or ""
```

Replace `Offer.image_url` at `apps/offers/models.py:78`:

```python
@property
def image_url(self) -> str:
    if self.media_asset_id and self.media_asset.file:
        return self.media_asset.file.url
    return self.image or ""
```

Apply the equivalent property to `Product.image_url` (`apps/products/models.py:85`) and `Article.image_url` (`apps/articles/models.py:94`):

```python
# Product
@property
def image_url(self) -> str:
    if self.media_asset_id and self.media_asset.file:
        return self.media_asset.file.url
    return self.image or ""

# Article
@property
def image_url(self) -> str:
    if self.media_asset_id and self.media_asset.file:
        return self.media_asset.file.url
    return self.cover_image or ""
```

Never append query parameters to these values in Flutter, and never freeze an asset's signed URL into the legacy URL column. Generate the current URL from the storage object on each response. When assigning an asset, **update the legacy URL column to `""`**; this removes the stale override without persisting an expiring signature. Existing externally hosted legacy URLs remain valid only when no asset is attached.

احفظ علاقة `media_asset` وليس رابطاً مؤقتاً من R2. عند تبديل العلاقة امسح القيمة القديمة في عمود الرابط. الحذف الصريح يجب أن يمسح العلاقة والقيمة القديمة معاً، وإلا ستعود الصورة القديمة من مسار الاحتياط.

### Shared serializer implementation / تطبيق مشترك للسيريالايزر

The next implementation supports HTTPS/HTTP URLs, validated binary uploads, and JSON `null` for catalog URL fields. It also enforces asset scope/type. It uses the existing media upload serializer's byte/MIME/size validation. Add `is_public` from section 6 first. Save as a proposed new `apps/media/portal_images.py`; **this is code for Ali to apply, not a file changed in this session.**

```python
from django.core.files.uploadedfile import UploadedFile
from rest_framework import serializers
from rest_framework.exceptions import PermissionDenied

from apps.clinics.portal_permissions import get_user_clinic
from apps.media.serializers import MediaUploadSerializer


class PortalImageInputField(serializers.Field):
    def __init__(self, **kwargs):
        kwargs.setdefault("required", False)
        kwargs.setdefault("allow_null", True)
        super().__init__(**kwargs)

    def to_internal_value(self, value):
        if isinstance(value, UploadedFile):
            return serializers.ImageField().run_validation(value)
        if value == "":
            return ""
        return serializers.URLField(max_length=1000).run_validation(value)

    def to_representation(self, value):
        return str(value or "")


class ScopedPortalImageMixin:
    image_field_name = "image"
    image_media_type = ""

    def validate(self, attrs):
        attrs = super().validate(attrs)
        field = self.image_field_name
        request = self.context["request"]
        clinic = get_user_clinic(request.user)
        attrs = dict(attrs)
        upload = attrs.get(field)

        if isinstance(upload, UploadedFile):
            if attrs.get("media_asset") is not None:
                raise serializers.ValidationError({field: "Choose a file or an asset, not both."})
            # Validate now, defer storage writes until all serializer validation passes.
            upload_serializer = MediaUploadSerializer(
                data={"file": upload, "media_type": self.image_media_type,
                      "clinic_id": str(clinic.pk)},
                context=self.context,
            )
            upload_serializer.is_valid(raise_exception=True)
            self._pending_image_upload = upload_serializer
            attrs.pop(field)
        elif field in attrs and "media_asset" not in attrs:
            # A direct URL replaces the previous asset; null/empty clears it.
            attrs["media_asset"] = None

        asset = attrs.get("media_asset")
        if asset is not None:
            if asset.clinic_id != clinic.pk and not asset.is_public:
                raise PermissionDenied("Cannot attach another clinic's private media.")
            if asset.media_type != self.image_media_type:
                raise serializers.ValidationError({"media_asset": "Wrong image purpose."})
            if not asset.mime_type.startswith("image/"):
                raise serializers.ValidationError({"media_asset": "An image asset is required."})
            # Changing the FK updates (clears) the legacy URL atomically with the model.
            attrs[field] = ""
        elif "media_asset" in attrs:
            # Keep a deliberately supplied direct URL; otherwise clear the legacy fallback.
            attrs[field] = attrs.get(field) or ""
        return attrs

    def _materialize_image(self, validated_data):
        pending = getattr(self, "_pending_image_upload", None)
        if pending is not None:
            asset = pending.save()
            validated_data["media_asset"] = asset
            validated_data[self.image_field_name] = ""
        return validated_data

    def create(self, validated_data):
        return super().create(self._materialize_image(validated_data))

    def update(self, instance, validated_data):
        return super().update(instance, self._materialize_image(validated_data))
```

Update the four existing serializer class declarations and input fields (keep existing `Meta.fields`, type/status validators, treatment ownership and article-author ownership):

```python
# apps/practitioners/portal_serializers.py:11
from apps.media.portal_images import PortalImageInputField, ScopedPortalImageMixin

class ClinicPractitionerPortalSerializer(ScopedPortalImageMixin, serializers.ModelSerializer):
    image_field_name = "avatar"
    image_media_type = "practitioner_avatar"
    avatar = PortalImageInputField()
    # Keep existing body, except remove to_internal_value at lines 51–58.

# apps/offers/portal_serializers.py:8
from apps.media.portal_images import PortalImageInputField, ScopedPortalImageMixin

class ClinicOfferPortalSerializer(ScopedPortalImageMixin, serializers.ModelSerializer):
    image_media_type = "offer_image"
    image = PortalImageInputField()
    # Keep existing body, except remove to_internal_value at lines 48–55.

# apps/products/portal_serializers.py
from apps.media.portal_images import PortalImageInputField, ScopedPortalImageMixin

class ClinicProductPortalSerializer(ScopedPortalImageMixin, serializers.ModelSerializer):
    image_media_type = "product_image"
    image = PortalImageInputField()
    # Keep existing body and Meta.

# apps/articles/portal_serializers.py
from apps.media.portal_images import PortalImageInputField, ScopedPortalImageMixin

class ClinicArticlePortalSerializer(ScopedPortalImageMixin, serializers.ModelSerializer):
    image_field_name = "cover_image"
    image_media_type = "article_cover"
    cover_image = PortalImageInputField()
    # Keep existing body and existing author/clinic validation and create/update overrides.
```

**Integration detail:** these are class-header/field replacements, not empty replacement classes. Preserve the existing `validate()` implementations and their `super().validate(attrs)` calls so the mixin runs; the existing offer validator continues to enforce dates/prices/treatment ownership. Remove its older, redundant asset ownership check once the shared check is active. Keep `MultiPartParser`, `FormParser`, `JSONParser` enabled on catalog views. Do not treat missing keys as removals. Do not delete a shared/public underlying asset when clearing one catalog record. If entity save fails after asset creation, record/clean up the orphan with an explicit retention job; database rollback cannot roll back S3 writes.

السنايبت السابقة تستبدل رأس الكلاس والحقول فقط، وليست بديلاً فارغاً لبقية منطق السيريالايزر. حافظ على تحقق العرض والعلاج وكاتب المقال. عمليات الحذف لا تحذف الملف المشترك من التخزين. الملفات اليتيمة تحتاج سياسة تنظيف مستقلة.

### Clinic ImageFields are a separate contract / صور العيادة لها عقد مختلف

`apps/clinics/models.py:128–129` are `ImageField`, not catalog URL columns. The original `apps/clinics/portal_serializers.py:25–33` discards strings. Ali's announced URL support must resolve **only a validated, authorized asset produced by the upload service** to a storage object; do not implement arbitrary remote downloads. Preserve direct binary upload support. `{"logo": null}` must clear the field, while omitted `logo` keeps it. Mixed replace/remove saves in Flutter use pre-upload + JSON specifically because multipart has no native JSON-null value.

Signed URLs must be returned unchanged from `storage.url(name)` and resolved against the request origin when relative. Ensure development `/media/` serving or production storage/nginx delivery is configured. Never concatenate `MEDIA_URL` to an already absolute storage URL.

**Acceptance:** replace an asset on an entity with a populated old URL; fresh output wins immediately and after a fresh GET/restart. Clear via JSON `null`; fresh GET stays empty. Edit text without image key; image stays. Wrong file type, wrong purpose, foreign/private asset all fail. URLs retain their exact signatures.

## 3. URL length migration / زيادة طول حقول الروابط

At `apps/products/models.py:34`, `apps/articles/models.py` (`cover_image` declaration), `apps/practitioners/models.py:60`, `apps/offers/models.py:31`, change the declarations, retaining the existing blank/default behavior:

```python
# Product.image
image = models.URLField(max_length=1000, blank=True, default="")
# Article.cover_image
cover_image = models.URLField(max_length=1000, blank=True, default="")
# Practitioner.avatar
avatar = models.URLField(max_length=1000, blank=True, default="")
# Offer.image
image = models.URLField(max_length=1000, blank=True, default="")
```

Check `apps/media/models.py:41,54,55` (`FeaturedAd.image`, `video_url`, `link`) and any other media URL columns for the same length ceiling; apply the same max length while preserving `null=True` where already used. Also enlarge `MediaAsset.file` at `apps/media/models.py:147` independently:

```python
file = models.FileField(upload_to=media_asset_upload_path, max_length=500)
```

This prevents long structured upload keys from truncating UUID basenames or exhausting the storage filename limit. URLs and storage keys are different limits; fix both.

```bash
python manage.py makemigrations practitioners offers products articles media
python manage.py sqlmigrate practitioners <generated_migration_number>
python manage.py migrate
python manage.py makemigrations --check --dry-run
```

Replace the placeholder in `sqlmigrate` with the actual generated migration name; inspect every generated `AlterField` and apply migrations to staging before production. Do not replace an app's entire migration history. Explicit URL serializer fields must also use `max_length=1000`; model changes do not override an explicitly declared `max_length=200` field.

تم إثبات رفض رابط اختباري موقّع بطول ٣٩٢ حرفاً في حقول المنتجات والمقالات. زيادة الحد تمنع خطأ التحقق فقط؛ **لا تمنع انتهاء صلاحية الرابط**. العلاقات إلى `MediaAsset` وتوليد رابط جديد وقت القراءة هما الحل الدائم.

## 4. Lead PATCH response / استجابة تحديث حالة الطلب

The class in the supplied repository is **`ClinicLeadViewSet`** and its full serializer is **`ClinicLeadSerializer`**, not the names `ClinicLeadPortalViewSet` / `ClinicLeadPortalSerializer` used in the request. Exact file: `apps/leads/views/clinic_views.py:21,30,115,117`.

الاسم الصحيح في الأرشيف هو `ClinicLeadViewSet`. سيريالايزر تحديث الحالة يعيد الحالة فقط؛ لا تستخدمه لتمثيل الطلب الكامل.

Replace **both** `return Response(serializer.data)` statements in `partial_update` with:

```python
lead.refresh_from_db()
return Response(self.get_serializer(lead).data)
```

`self.get_serializer()` uses the existing `serializer_class = ClinicLeadSerializer` and supplies request context. If Ali has renamed those symbols, the equivalent explicit form is:

```python
return Response(
    ClinicLeadSerializer(lead, context=self.get_serializer_context()).data
)
```

Keep status-history insertion, permission checks and patient notifications intact. The response must include at least `id`, `patient_name`, `patient_phone`, `service_name`, `created_at`, status and relationship summaries. Flutter remains compatible with the old status-only response by merging into the existing model.

**Acceptance:** update `new → contacted → closed`; all patient and service fields remain byte-for-byte unchanged, history remains correct, foreign tenant PATCH is forbidden, and same-status PATCH returns the same full schema.

## 5. Clinic provisioning branding and flat multipart / إنشاء العيادة مع الهوية وحقول المشرف المسطحة

**Observed:** `AdminClinicProvisionSerializer` does not declare logo/cover; `ClinicProvisioningService.provision_clinic` never passes them to `Clinic.objects.create`. Thus a successful creation may silently discard branding. Dio's default nested multipart bracket keys are also not a DRF nested serializer contract.

الصور كانت تُرفع أو تُرسل ثم تُهمل عند الإنشاء. إصلاح حفظ الملفات وحده لا يكفي؛ يجب توحيد أسماء حقول المشرف أيضاً.

In `apps/admin_portal/serializers.py:92–111`, keep the existing scalar fields and add these members to `AdminClinicProvisionSerializer`:

```python
logo = serializers.ImageField(required=False, allow_null=True)
cover_image = serializers.ImageField(required=False, allow_null=True)

def to_internal_value(self, data):
    # JSON retains nested admin_user. HTML/multipart must use dotted keys for DRF's
    # nested HTML parser; accept flat and legacy bracket forms at the API boundary.
    if hasattr(data, "getlist"):
        normalized = data.copy()
        for name in ("full_name", "phone", "email", "temporary_password"):
            flat_key = f"admin_{name}"
            bracket_key = f"admin_user[{name}]"
            dotted_key = f"admin_user.{name}"
            if flat_key in data:
                normalized[dotted_key] = data[flat_key]
            elif bracket_key in data and dotted_key not in data:
                normalized[dotted_key] = data[bracket_key]
    else:
        normalized = dict(data)
        flat = {
            name: normalized[f"admin_{name}"]
            for name in ("full_name", "phone", "email", "temporary_password")
            if f"admin_{name}" in normalized
        }
        if flat:
            nested = normalized.get("admin_user")
            if nested is not None and not isinstance(nested, dict):
                raise serializers.ValidationError({"admin_user": "Expected an object."})
            nested = dict(nested or {})
            for name, value in flat.items():
                if name in nested and nested[name] != value:
                    raise serializers.ValidationError({"admin_user": "Conflicting administrator fields."})
                nested[name] = value
            normalized["admin_user"] = nested
    return super().to_internal_value(normalized)
```

For multipart duplicate aliases (`admin_phone` and `admin_user.phone` etc.), reject conflicting values before choosing either; add the check below inside the `for name ...` loop before assignment:

```python
provided = [data[key] for key in (flat_key, bracket_key, dotted_key) if key in data]
if len(set(provided)) > 1:
    raise serializers.ValidationError({"admin_user": "Conflicting administrator fields."})
```

In `apps/admin_portal/services/clinic_provisioning.py:20`, copy input instead of mutating the serializer's dictionary:

```python
data = dict(data)
admin_data = dict(data.pop("admin_user", {}) or {})
if not admin_data:
    raise ValidationError({"admin_user": "Administrator details are required."})
```

Add the branding arguments inside `Clinic.objects.create` at line 45:

```python
logo=data.get("logo"),
cover_image=data.get("cover_image"),
```

Keep the existing service method, database transaction, admin creation, primary branch creation, return schema and audit log. Normalize the admin phone with the existing backend `normalize_phone()` helper before uniqueness checks; normalize email with `.strip().lower()` and use case-insensitive uniqueness checks consistent with login. Add database uniqueness only after auditing existing duplicate email rows.

Confirm the provisioning view accepts all three parsers:

```python
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser

parser_classes = [MultiPartParser, FormParser, JSONParser]
```

**Wire examples / أمثلة العقد**

```json
{
  "name_en": "Example Clinic",
  "subscription_tier": "vip",
  "admin_user": {
    "full_name": "Clinic Administrator",
    "phone": "+971501234567",
    "email": "admin@example.test",
    "temporary_password": "a-strong-temporary-password"
  }
}
```

Multipart: `name_en`, `subscription_tier`, `logo` (binary image), `cover_image` (binary image), `admin_full_name`, `admin_phone`, `admin_email`, `admin_temporary_password`. Tier values are exclusively `vip`, `featured`, `basic`. For creation, frontend now sends binaries directly, rather than orphan preuploads without a clinic UUID.

If Ali also accepts uploaded URLs for provisioning, keep that validated-asset adapter alongside `ImageField`; do not fetch arbitrary external URLs from the backend. This direct-binary contract works without remote URL resolution.

**Storage consistency:** Django transactions do not roll back storage writes. On provisioning failure, delete only files newly written by that failed provisioning operation; do not delete supplied/shared assets. Implement a bounded orphan-reconciliation job with a retention window for uploads that never become attached. Keep credentials out of application logs; the existing handoff response is intended only for the authenticated super admin.

**Acceptance:** JSON without images succeeds; flat multipart with two images succeeds and fresh detail GET returns accessible branding; omitted images stay empty; invalid image/admin/tier produces no clinic/admin/branch partial creation; duplicate aliases fail; existing nested JSON clients remain supported.

## 6. Security and isolation / الأمان وعزل الأدوار والعيادات

### 6.1 Own assets or explicitly public assets / صور العيادة أو الصور العامة صراحة

Current unrestricted `MediaAsset.objects.all()` relationship fields accept foreign assets in practitioner/product/article serializers. The offer check rejects another clinic's non-null `clinic_id` but accidentally treats every unscoped asset as public. **`clinic_id is None` is not proof of public visibility:** it can be a patient's private upload.

المورد غير المنسوب لعيادة ليس عاماً تلقائياً. لا تسمح لعيادة بربط صورة مريض أو صورة عيادة أخرى عبر تخمين UUID.

Proposed new field in `apps/media/models.py`, inside `MediaAsset`:

```python
is_public = models.BooleanField(default=False, db_index=True)
```

Do not expose writable `is_public` in patient/clinic upload serializers. Only a super-admin workflow may promote an asset. Do not mark existing unscoped assets public in a blanket data migration. Generate/apply a media migration. The shared mixin in section 2 enforces `(asset.clinic_id == clinic.pk) or asset.is_public`, plus image MIME and purpose. A strict deployment may reject all public cross-clinic reuse until this explicit flag is available; do not substitute `clinic_id=None`.

Enforce the same tenant/type checks on create and PATCH, including JSON URL adapters. Validate supplied uploaded URLs against an authorized asset in your own configured storage, not against arbitrary `http` content. The generic upload endpoint must bind `media_type` to allowed MIME classes (image purposes cannot accept videos).

### 6.2 Patient verification before token issuance / التوثيق قبل إصدار توكن للمريض

`apps/accounts/serializers.py:94–111`, after active/deleted checks and **before** `self.user = user` / token generation:

```python
from apps.accounts.models import UserRole

if user.role == UserRole.PATIENT and not user.is_verified:
    raise serializers.ValidationError(
        {"detail": "Verify your account before signing in."},
        code="account_unverified",
    )
```

Keep the condition role-specific so provisioned clinic/super-admin accounts use their intended policy. `LoginView` in this snapshot uses this serializer, so the check prevents JWT issuance. Check any other login/token endpoints for an equivalent guard, and require active/non-deleted users in OTP login as well. The frontend should route this error to verification in a coordinated follow-up; this handoff does not invent a new response envelope.

### 6.3 Shared clinic permission and tenant resolver / صلاحية موحدة للعيادة

The supplied `get_user_clinic()` **already rejects suspended/rejected/deleted clinics**. The actual bypass is clinic leads: `ClinicLeadViewSet.permission_classes = [IsAuthenticated]` and a separate membership query bypass the resolver. In addition, the resolver's super-admin fallback selects the first active clinic and violates role isolation.

الدالة الحالية تمنع العيادات الموقوفة بالفعل، لكن مسار الطلبات لا يستعملها. لا تعالج ذلك بإضافة شرط مكرر في الشاشة؛ وحّد التحقق في جميع مسارات البوابة وأزل دخول السوبر أدمن إلى بوابة العيادة.

Replace `get_user_clinic()` in `apps/clinics/portal_permissions.py:8` with:

```python
def get_user_clinic(user) -> Clinic:
    if not (user and user.is_authenticated):
        raise NotAuthenticated("Authentication required.")
    if user.role not in (UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF):
        raise PermissionDenied("Clinic portal access requires a clinic role.")
    if not user.is_active or user.deleted_at is not None:
        raise PermissionDenied("Account is inactive.")
    memberships = list(
        user.clinic_memberships.filter(is_active=True)
        .select_related("clinic")[:2]
    )
    # No arbitrary .first() tenant when more than one membership exists.
    # If multi-clinic staff is a future feature, require an explicit authenticated
    # clinic selector and validate it against memberships in every endpoint.
    if len(memberships) != 1:
        raise PermissionDenied("Exactly one active clinic assignment is required.")
    clinic = memberships[0].clinic
    if clinic.deleted_at is not None or clinic.status in (
        ClinicStatus.SUSPENDED, ClinicStatus.REJECTED,
    ):
        raise PermissionDenied("CLINIC_SUSPENDED")
    return clinic
```

Replace the body of `IsClinicPortalAccess.has_permission()` with:

```python
def has_permission(self, request, view):
    try:
        request._portal_clinic = get_user_clinic(request.user)
        return True
    except (PermissionDenied, NotAuthenticated) as exc:
        self.message = str(exc)
        return False
```

In `IsClinicAdminAccess.has_permission()`, remove the super-admin allowance and consistently query membership for `request._portal_clinic`, not an arbitrary first membership. Preserve clinic-admin access and permit a staff membership with the explicit admin role only if that is the chosen policy:

```python
def has_permission(self, request, view):
    if not super().has_permission(request, view):
        return False
    if request.user.role == UserRole.CLINIC_ADMIN:
        return True
    return request.user.clinic_memberships.filter(
        clinic=request._portal_clinic,
        is_active=True,
        role_in_clinic=ClinicRoleInClinic.ADMIN,
    ).exists()
```

In `apps/leads/views/clinic_views.py`, import and apply the permission and replace `get_queryset()` with the equivalent tenant scope:

```python
from apps.clinics.portal_permissions import IsClinicPortalAccess

# Inside ClinicLeadViewSet:
permission_classes = [IsClinicPortalAccess]

def get_queryset(self):
    if getattr(self, "swagger_fake_view", False):
        return Lead.objects.none()
    clinic = getattr(self.request, "_portal_clinic", None)
    if clinic is None:
        return Lead.objects.none()
    return (
        Lead.objects.filter(clinic=clinic)
        .select_related("clinic", "branch", "practitioner", "treatment", "offer", "product", "patient")
        .prefetch_related("internal_notes__author", "status_history__changed_by")
    )
```

Super admins retain the dedicated `/admin/leads/` endpoint, not operational clinic-portal access. Verify all clinic profile/catalog/branch/checklist/lead endpoints share the resolver. Pending clinics must still be able to complete onboarding; do not require `status=active` globally unless a separate onboarding permission is deliberately introduced.

**Acceptance matrix:** patient and super-admin requests to clinic portal fail; suspended/rejected/deleted clinic requests fail including leads/notes; an active assigned clinic can finish onboarding; foreign clinic resource IDs return 404/403; multi-membership ambiguity fails closed; private unscoped patient asset attachment fails; explicitly public approved image works under the declared policy.

## 7. Remaining backend audit items / بقية نتائج مراجعة الباك إند

These remain explicit work items, not claims that the six patches alone repair the entire platform. See `docs/CODEX_FULL_SYSTEM_AUDIT_REPORT.md` for the complete evidence and endpoint matrix.

| Priority | Location | Required follow-up / المتابعة |
|---|---|---|
| P1 | `config/settings/base.py` REST_FRAMEWORK; auth views `throttle_scope`; `apps/media/views.py` | Enable `ScopedRateThrottle` for named scopes; attach upload scope; keep service OTP limits; test rate limits with isolated cache. |
| P1 | `apps/accounts/models.py:207`; referral views; `config/urls.py:13` | Align `/invite/...` path and code-vs-token lookup, implement mobile/web attribution and server-driven points/milestone policy. Preserve historical ledger; retire coupon creation by policy rather than deleting audit history blindly. |
| P1 | `apps/media/models.py:147`; asset deletion/signals and entity replacement | Longer file keys, type validation, one deletion owner, safe orphan cleanup, no deletion of referenced/shared files. |
| P1 | `apps/admin_portal/services/clinic_provisioning.py:30–33`; account email lookup | Normalize identifiers; deduplicate email data and add appropriate uniqueness constraint to prevent ambiguous case-insensitive login. |
| P2 | `apps/home/serializers.py:47`; home feed view/cache | Include offer media, return usable URLs and featured-ad DTO data, pass request context into nested serializers, invalidate or version cached feed after catalog changes (current TTL 300 s). |
| P2 | public clinic serializers; portal profile serializer | Return explicitly approved ranking/badge semantics; include clinic subscription tier in private profile where used; `is_featured` is not equivalent to VIP. |
| P2 | clinic onboarding checklist | Keep readiness rules consistent: logo AND cover, bilingual bios plus contact, active branch/practitioner/treatment as defined; return canonical server checklist after writes. |
| P2 | lead model reference-code generation | Add collision retry around short random unique reference creation. |
| P2 | clinic geography queryset | Verify PostGIS functions/extension availability and normalize distance units; do not label squared-degree or metre values as kilometres. |
| P2 | test suite fixtures and cache handling | Supply `clinic_staff_user`, `patient_user`, `clinic_admin_user` fixtures for permission tests; isolate OTP cache between tests; keep actual file persistence assertions, not only text-save assertions. |
| Product contract | product serializers/lead serializer | Remove product price presentation fields from showcase contracts where no longer needed; continue accepting `product_inquiry`, not `product`. Empty preferred time window is valid for inquiry-only leads. |

No `/clinics/<id>/reviews/` model/router exists in the supplied backend. The frontend no longer calls it; Google rating/count are the supported contract. Do not add an unused review endpoint to preserve a dead client call. Product/brand/sponsor fields and offer campaign start/end dates are real fields, not ghost inputs. Do not remove those date fields under the prohibition on appointment scheduling.

## 8. Release gates / شروط القبول والنشر

1. Apply/rebase patches on Ali's branch, add migrations, and run Django system checks plus the full backend suite. Existing audit baseline was 561 passed, 2 failed, 3 errors; do not mistake it for a clean backend baseline.
2. Add integration tests for every acceptance case above, including real uploaded bytes → fresh detail GET, image clear → fresh GET, cross-tenant assets, verified login, suspended clinic leads, and atomic recovery OTP consumption.
3. Run against the deployed R2 configuration with actual credentials: upload, PATCH, GET after a fresh login, open returned signed URL unchanged, repeat after expiry to verify a freshly generated signature. A mocked unit test cannot prove this gate.
4. Confirm provisioning with both nested JSON and flat multipart from mobile; verify persisted storage and clinic administrator/branch records. Coordinate backend deployment before declaring mobile branding creation complete.
5. Never print OTPs, JWTs, storage keys/secrets or temporary passwords in diagnostic logs.

لا يتم اعتبار الإصلاح مكتمل الإنتاج بمجرد ظهور رسالة نجاح في التطبيق. القبول هو: ملف محفوظ فعلياً، رابط قابل للعرض، قراءة جديدة تعيد الصورة الصحيحة، وحذف يبقى محذوفاً، مع منع الوصول بين العيادات وعدم تجاوز التوثيق.

## 9. Final scale and concurrency handoff — 19 October 2026

**Status:** this section is a specification for Ali, not backend changes applied by Codex. The extracted backend remains read-only. Apply sections 1–6 first; this section must not reintroduce cross-tenant access, allow unverified sessions, bypass media ownership, or change the inquiry-only product contract. All paths/line references below refer to the supplied backend snapshot. Flutter changes are delivered separately.

500 simultaneous users is a workload target, not a proven capacity result. 500 connected users, 500 simultaneous requests, and 3,000 requests/second are different workloads. No production benchmark, real SMTP/R2/FCM test, or physical-device 60/120 Hz measurement was available in this workspace. The load acceptance procedure at the end is a release gate.

### 9.1 Evidence and scope across every subsystem

| Subsystem | Evidence in supplied source | Required change / protection to retain |
|---|---|---|
| accounts | `services/otp.py:175–190`; `services/profile_change.py:69–90,210–237`; `services/email.py:58–85` | SMTP runs in the API thread; phone/email change also sends synchronously. Use the encrypted delivery outbox below for **all** generation paths. Make cooldown reservation atomic. Existing unique phone/email constraints and recovery-consumption fixes remain mandatory. |
| clinics | `serializers.py:162–187`; `views.py:99`; `portal_views.py:40–86` | Detail prefetches whole catalogs, then `.filter()` bypasses that cache and serializes everything again. Bound previews, provide branch paging, collapse four event scans and four lead scans into two aggregates. |
| treatments | `portal_views.py:31`; `portal_serializers.py:107`; `views.py:62` | Portal serializes the through relation (`practitioner_treatments`), while it prefetches `practitioners`: wrong cache. Detail practitioner lists are unbounded; select media assets and bound nested summaries. Category filter in clinic portal is currently ignored. |
| practitioners | `views.py:37,54`; detail `serializers.py:get_treatments` | Avatar property can fetch `media_asset` per row. Detail treatment filtering bypasses prefetch and is unbounded. |
| offers | public `views.py:30,51` already joins clinic + asset | Preserve those joins and campaign date predicates. Portal query must join asset, clinic and optional treatment where serialized. Stable ordering needs a UUID tie-breaker. |
| products | public `views.py:28,47` already joins clinic + asset; portal `portal_views.py:28` does not | Fix portal/moderation joins; search real brand/sponsor columns too. Preserve null-clinic brand showcases. No client category/price contract is invented. |
| articles | `portal_views.py:27`; public `views.py:33,57` | Portal joins author only; nested author may fetch clinic/media per article. Public author asset also needs loading. Keep publication and author visibility restrictions. |
| leads | `pagination.py:20`; `views/clinic_views.py:44`; `serializers.py:ClinicLeadSerializer` | No page parameter currently means **all leads**. Pagination is mandatory; list must not prefetch every historical note/status event. Existing patient joins miss `practitioner__media_asset` and `treatment__category`. |
| referrals | `views/patient_views.py:39,68–69`; `services.py:52–54,119–121,173` | Status embeds all discount/reward records twice. Bound historical previews; paginate a separate history endpoint. Preserve transactional profile locking and ledger idempotency. Do not turn points UI back into coupon strings. |
| notifications | `push.py:117–143,190–208`; `tasks.py:62–95`; `service.py:44–62` | FCM falls back synchronously if enqueue fails. `max_retries` alone does not retry. Existing Notification DB rows are useful; no periodic pending sweeper is implemented. Do not swallow provider failures and mark undelivered pushes sent. |
| media | `views.py:77–122`; `serializers.py:132`; `permissions.py:77`; `config/storage_backends.py` | List inherits global pagination, but membership `.count()` + `.first()` doubles resolution. Native compression helps; file validation and R2 upload still consume an API worker. Bound storage timeouts now; presigned direct uploads are a separate versioned protocol, not a pretend compatible fix. |
| admin_portal | `views.py:78,103` already aggregates clinics and leads correctly; `1090–1094` repeats event counts; moderation `778` | Keep existing dashboard aggregates. Aggregate legacy analytics too; add moderation search/joins. A single join across unrelated catalog tables would multiply rows and produce wrong counts. |
| home / analytics | `home/views.py:28–44,60,92,205+`; `analytics/views.py:56–65`; `analytics/tasks.py:61,141` | Home slices already bound categories to 8 and other sections to 10. Add media joins, response context and stampede protection. Cache key currently drops city when geo exists. Analytics daily task does per-clinic aggregate loops; group by clinic rather than issuing queries per clinic. |

ORM `.all()` in a serializer's PK-related-field **validation queryset** is lazy; it is not itself an unbounded HTTP list. Fix ownership/scoping there as specified earlier, rather than misreporting every `MediaAsset.objects.all()` as an eager database scan. Foreign keys/unique IDs already have indexes; do not duplicate them.

### 9.2 Mandatory 20-record pagination and deterministic order

Replace `core/pagination/standard.py:StandardResultsPagination` with the class below; keep the existing `CursorResultsPagination` export for consumers that use it, but change its max size to 20 too. The Flutter page-number client sends `page` and `page_size=20`; do not silently switch those endpoints to cursors without a client contract change.

```python
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

class StandardResultsPagination(PageNumberPagination):
    page_size = 20
    page_query_param = "page"
    page_size_query_param = "page_size"
    max_page_size = 20

    def get_page_size(self, request):
        # Exactly 20: page offsets must not change when a legacy caller sends 100.
        return 20

    def get_paginated_response(self, data):
        return Response({
            "count": self.page.paginator.count,
            "total_pages": self.page.paginator.num_pages,
            "current_page": self.page.number,
            "page_size": 20,
            "next": self.get_next_link(),
            "previous": self.get_previous_link(),
            "results": data,
        })
```

Replace the entire `apps/leads/pagination.py` with:

```python
from core.pagination import StandardResultsPagination

class ClinicLeadPagination(StandardResultsPagination):
    pass
```

Replace `AdminStandardPagination` in `apps/admin_portal/views.py` with:

```python
from core.pagination import StandardResultsPagination

class AdminStandardPagination(StandardResultsPagination):
    pass
```

`MyLeadsAPIView` already inherits global pagination. Public/portal catalog GenericAPIView/ViewSet lists and media lists inherit the global class as well. Set the same class explicitly on new APIViews that manually serialize a collection; plain APIView has no automatic pagination. `AdminModerationQueueAPIView` currently slices 100 **per type**; its legacy mixed queue must be replaced by one paginated content type per request, or retired in favor of the existing three paginated moderation viewsets. Flutter uses those viewsets. Do not present a 300-row response as a 20-row page.

Append `"pk"` (or `"-pk"` for descending created time) to each ordering: clinic ranking ends in `name_en, pk`; treatments `name_en, pk`; practitioner `display_order, name_en, pk`; offers/products/articles/admin/lead/media lists `-created_at, -pk`; branch `-is_main_branch, name_en, pk`. Numbered pagination is bounded but not snapshot-consistent under concurrent inserts. Flutter deduplicates IDs; a future cursor API is appropriate for very deep, frequently changing leads. Do not advertise numbered pages as lossless snapshots.

### 9.3 Bounded public clinic detail and branch directory

Remove `.prefetch_related("branches", "practitioners", "treatments__category")` from `ClinicDetailAPIView.get_queryset()`; retain its active, non-deleted clinic predicate and UUID/slug lookup unchanged. For this **single-clinic** endpoint, three limited queries are simpler than prefetching every related record. Replace the three methods in `PublicClinicDetailSerializer` with these methods. They preserve existing JSON keys, and each previews six items. `context=self.context` preserves URL handling.

```python
@extend_schema_field(PublicClinicBranchSerializer(many=True))
def get_branches(self, obj):
    qs = obj.branches.filter(is_active=True, deleted_at__isnull=True).order_by(
        "-is_main_branch", "name_en", "pk"
    )[:6]
    return PublicClinicBranchSerializer(qs, many=True, context=self.context).data

@extend_schema_field(PublicClinicPractitionerSummarySerializer(many=True))
def get_practitioners(self, obj):
    qs = obj.practitioners.filter(status="active", deleted_at__isnull=True).select_related(
        "media_asset"
    ).order_by("display_order", "name_en", "pk")[:6]
    return PublicClinicPractitionerSummarySerializer(qs, many=True, context=self.context).data

@extend_schema_field(PublicClinicTreatmentSummarySerializer(many=True))
def get_treatments(self, obj):
    qs = obj.treatments.filter(
        is_active=True, status="active", deleted_at__isnull=True, category__is_active=True,
    ).select_related("category").order_by("name_en", "pk")[:6]
    return PublicClinicTreatmentSummarySerializer(qs, many=True, context=self.context).data
```

The Flutter patient clinic profile loads practitioners/treatments/offers via their existing paginated directories **on the first visit to that profile tab**. Clinic-portal profiles use six-row previews and a lazy paginated View All sheet. For branches, add the following view to `apps/clinics/views.py` and route before `<str:id>/` in `apps/clinics/urls.py`; otherwise bounding the embedded branch preview would make later branches inaccessible.

```python
from apps.clinics.models import ClinicBranch
from apps.clinics.serializers import PublicClinicBranchSerializer
from core.pagination import StandardResultsPagination

class ClinicBranchListAPIView(generics.ListAPIView):
    permission_classes = [AllowAny]
    serializer_class = PublicClinicBranchSerializer
    pagination_class = StandardResultsPagination
    filter_backends = [filters.SearchFilter]
    search_fields = ["name_en", "name_ar", "city", "address_en", "address_ar"]

    def get_queryset(self):
        return ClinicBranch.objects.filter(
            clinic_id=self.kwargs["clinic_id"], clinic__status=ClinicStatus.ACTIVE,
            clinic__deleted_at__isnull=True, is_active=True, deleted_at__isnull=True,
        ).order_by("-is_main_branch", "name_en", "pk")
```

```python
# Add to apps/clinics/urls.py imports and urlpatterns, respectively.
from apps.clinics.views import ClinicBranchListAPIView
# urlpatterns entry:
branch_directory_route = path(
    "<uuid:clinic_id>/branches/", ClinicBranchListAPIView.as_view(), name="clinic-branches",
)
# Insert branch_directory_route into urlpatterns before the clinic-detail entry.
```

Add `branches_directory_url = serializers.SerializerMethodField()` to `PublicClinicDetailSerializer` and include `"branches_directory_url"` in its Meta.fields. Its method is:

```python
def get_branches_directory_url(self, obj):
    return f"/api/v1/clinics/{obj.pk}/branches/"
```

Flutter recognizes this capability field: branch selectors and the profile View All sheet then use the paginated branch route. Older responses retain bounded local choices from their existing embedded branch list. Deploy the route and capability field together before bounding the embedded branch preview.

For a practitioner detail's treatment summaries, use the existing filtered treatment predicate, `.select_related("category")`, `.order_by("name_en", "pk")[:6]` and pass serializer context. For a treatment detail's practitioner summaries use the existing active/non-deleted practitioner predicate, `.select_related("media_asset")`, ordering with `pk`, and `[:6]`. Remove the corresponding unfiltered unlimited detail prefetch. Expose full related directories with the existing `clinic` filters plus an explicitly validated practitioner/treatment filter if the product needs more; never return the whole through-table in a detail response.

### 9.4 Queryset joins, real search, and portal filter compatibility

Change **the existing** querysets in place, keeping all their visibility and ownership predicates. The following are exact relation names in this snapshot:

| Queryset | Required joins/prefetch (in addition to existing predicates) |
|---|---|
| public practitioners list/detail | `.select_related("clinic", "media_asset")`; bounded detail relations as above |
| public article list/detail | `.select_related("clinic", "media_asset", "author_practitioner", "author_practitioner__clinic", "author_practitioner__media_asset")` |
| clinic practitioners/offers/products | `.select_related("clinic", "media_asset")`; offer includes `"treatment"` where serialized |
| clinic articles | same article relation chain as public |
| clinic treatments | `.select_related("clinic", "category")`; replace `prefetch_related("practitioners")` with `prefetch_related("practitioner_treatments")` for the current PK-through representation |
| patient/admin leads | preserve existing joins; add `"practitioner__media_asset", "treatment__category"` wherever nested serializers read them |
| admin moderation | clinic + media; article also author + author clinic + author media |
| home ads/offers | current `.select_related("clinic")` becomes `.select_related("clinic", "media_asset")` |

For a treatment's **list** response, exposing every practitioner PK remains an unbounded nested relation even after fixing the prefetch. Use a light list serializer excluding `practitioners`, and fetch assignments in a separate paginated endpoint for an assignment editor. Current Flutter treatment editor does not edit assignments. Detail assignment representation can be capped at 20 plus a dedicated paging route; never silently truncate an editable assignment set and then save it as a complete replacement.

Replace `BaseContentModerationViewSet.get_queryset()` in `apps/admin_portal/views.py` with:

```python
def get_queryset(self):
    if getattr(self, "swagger_fake_view", False) or self.model_class is None:
        return Offer.objects.none()
    qs = self.model_class.objects.filter(deleted_at__isnull=True)
    relations = ["clinic", "media_asset"]
    if self.model_class is Article:
        relations += ["author_practitioner", "author_practitioner__clinic", "author_practitioner__media_asset"]
    qs = qs.select_related(*relations)
    status_value = self.request.query_params.get("status")
    clinic_value = self.request.query_params.get("clinic")
    if status_value:
        qs = qs.filter(status__iexact=status_value)
    if clinic_value:
        qs = qs.filter(clinic_id=clinic_value)
    term = self.request.query_params.get("search", "").strip()[:100]
    if term:
        names = ["name_en", "name_ar"] if self.model_class is Product else ["title_en", "title_ar"]
        if self.model_class is Product:
            names += ["brand_name_en", "brand_name_ar", "sponsor_company"]
        query = Q()
        for name in names:
            query |= Q(**{f"{name}__icontains": term})
        qs = qs.filter(query)
    return qs.order_by("-created_at", "-pk")
```

`Q` is already imported by this module. Invalid UUID filters should produce a DRF 400, not a Django 500: use a query-parameter serializer with `UUIDField(required=False)` before `.filter(clinic_id=...)`, likewise category/branch. This validation applies to existing admin lead/clinic filters too.

The Flutter clinic treatment filter now sends a category UUID. Add the following immediately before the return of `ClinicTreatmentPortalViewSet.get_queryset()` (refactor its return expression into `qs` first):

```python
from rest_framework import serializers

class ClinicTreatmentQuerySerializer(serializers.Serializer):
    category = serializers.UUIDField(required=False)

def filter_portal_treatment_category(qs, request):
    query = ClinicTreatmentQuerySerializer(data=request.query_params)
    query.is_valid(raise_exception=True)
    category_id = query.validated_data.get("category")
    return qs.filter(category_id=category_id) if category_id else qs
# get_queryset returns filter_portal_treatment_category(qs, self.request).
```

Add `SearchFilter` with `search_fields=["name_en", "name_ar"]` to `CategoryListAPIView` if not already inherited; cap categories at 20 too. Include `brand_name_en`, `brand_name_ar`, `sponsor_company` in both public and portal product `search_fields`. The client deliberately no longer fakes product/article categories from words in names. Portal lead `search` is currently ignored: add `SearchFilter` with `search_fields=["patient_name", "patient_phone", "reference_code", "service_name"]` to `ClinicLeadViewSet`. All patient/portal/admin search bars in the changed list flows debounce for 350 ms and reject stale responses; server search must operate over the full queryset before pagination.

The nurse/licensed-professional directory sends `types=nurse,licensed_professional`; current `PractitionerFilter` only accepts one `type`. Add the following declaration/method **inside** `PractitionerFilter` and add `types` to its Meta.fields. It runs before pagination, rather than filtering an arbitrary loaded page:

```python
types = django_filters.CharFilter(method="filter_types")

def filter_types(self, queryset, name, value):
    from rest_framework.exceptions import ValidationError
    values = [item.strip() for item in value.split(",") if item.strip()]
    allowed = {item for item, label in PractitionerType.choices}
    if not values or len(values) > 3 or not set(values).issubset(allowed):
        raise ValidationError({"types": "Choose valid practitioner types."})
    return queryset.filter(type__in=values)
```

Clinic default ranking must remain on the server; it depends on a tier intentionally omitted from public JSON. Do not sort the loaded 20 records client-side and call that a global rating/distance order. Support an explicit whitelisted sort parameter while retaining paid-placement policy, or remove unavailable sort choices. Distance requires validated coordinates, PostGIS availability, and metre-to-kilometre conversion, not a fabricated zero distance.

### 9.5 Lead lists and bounded history

A clinic lead list prefetches all notes and status history for each of its 20 leads. Ten thousand notes on one lead can therefore defeat list pagination. Add this serializer to `apps/leads/serializers.py`:

```python
class ClinicLeadListSerializer(ClinicLeadSerializer):
    class Meta(ClinicLeadSerializer.Meta):
        fields = [field for field in ClinicLeadSerializer.Meta.fields
                  if field not in ("internal_notes", "status_history")]
```

Use it only for `self.action == "list"`; keep the detail serializer for detail/mutations. For detail, replace the two history field declarations with `SerializerMethodField` and add the following methods to `ClinicLeadSerializer`:

```python
internal_notes = serializers.SerializerMethodField()
status_history = serializers.SerializerMethodField()

def get_internal_notes(self, obj):
    rows = obj.internal_notes.select_related("author").order_by("-created_at", "-pk")[:20]
    return LeadNoteSerializer(rows, many=True, context=self.context).data

def get_status_history(self, obj):
    rows = obj.status_history.select_related("changed_by").order_by("-created_at", "-pk")[:20]
    return LeadStatusHistorySerializer(rows, many=True, context=self.context).data
```

Remove the unlimited notes/history prefetch from the base lead queryset. Keep section 6's `IsClinicPortalAccess` and strict single-clinic resolver. Add the following two methods inside `ClinicLeadViewSet`; merge GET into the **existing** notes action rather than defining two `notes` actions. Existing POST note validation/save logic remains after the GET branch.

```python
from rest_framework.decorators import action
from apps.leads.serializers import ClinicLeadListSerializer, LeadStatusHistorySerializer

# Inside ClinicLeadViewSet:
def get_serializer_class(self):
    return ClinicLeadListSerializer if self.action == "list" else ClinicLeadSerializer

@action(detail=True, methods=["get"], url_path="history")
def history(self, request, pk=None):
    lead = self.get_object()  # tenant-scoped; never query Lead directly by supplied ID
    rows = lead.status_history.select_related("changed_by").order_by("-created_at", "-pk")
    page = self.paginate_queryset(rows)
    return self.get_paginated_response(LeadStatusHistorySerializer(page, many=True).data)

# At the start of existing notes(self, request, pk=None), with methods=["get", "post"]:
def paginated_notes_response(self, request):
    lead = self.get_object()
    rows = lead.internal_notes.select_related("author").order_by("-created_at", "-pk")
    page = self.paginate_queryset(rows)
    return self.get_paginated_response(LeadNoteSerializer(page, many=True).data)
# if request.method == "GET": return self.paginated_notes_response(request)
```

Add `notes_directory_url = serializers.SerializerMethodField()` to `ClinicLeadSerializer`, add it to Meta.fields, and implement:

```python
def get_notes_directory_url(self, obj):
    return f"/api/v1/clinic-portal/leads/{obj.pk}/notes/"
```

The Flutter detail notes component fetches fresh detail metadata, then pages this route when the capability is present; older snapshots retain bounded local paging of their embedded notes. Deploy GET notes and its capability together. The list serializer may omit this link because detail retrieves it before paging.

Frontend list models accept missing history arrays. Detail screens must label the embedded 20 records as recent; a full-history control must use these authenticated pages before claiming that all history is visible. Keep patient-safe serializers separate: patient APIs must never expose internal notes.

Referral status must similarly stop embedding an unlimited queryset twice. Set `codes` to `ReferralDiscountCode.objects.filter(patient=...).order_by("-created_at", "-pk")[:20]`; retain only points/milestones/unified-link fields in the next public contract. If historical rewards are required, create a patient-scoped `ListAPIView` with `StandardResultsPagination` instead of adding more arrays to status. Existing Flutter points screen does not need coupon records. Keep existing ledger locks/unique idempotency keys; repeated aggregate reconciliation belongs in the transaction/reconciliation job, not a sum per card render.

### 9.6 Clinic dashboard aggregation with identical response keys

In `apps/clinics/portal_views.py`, import `Count, Q` and replace the eight event/lead count statements with these two queries. Use `request._portal_clinic` populated by the permission from section 6, rather than resolving membership again.

```python
from django.db.models import Count, Q

# Inside ClinicDashboardAPIView.get:
clinic = request._portal_clinic
interactions = AnalyticsEvent.objects.filter(clinic=clinic).aggregate(
    whatsapp_taps=Count("id", filter=Q(event_type=EventType.WHATSAPP_TAP)),
    call_taps=Count("id", filter=Q(event_type=EventType.CALL_TAP)),
    maps_taps=Count("id", filter=Q(event_type=EventType.MAPS_TAP)),
    profile_views=Count("id", filter=Q(event_type=EventType.CLINIC_VIEW)),
)
lead_counts = Lead.objects.filter(clinic=clinic).aggregate(
    total=Count("id"),
    new=Count("id", filter=Q(status=LeadStatus.NEW)),
    contacted=Count("id", filter=Q(status=LeadStatus.CONTACTED)),
    closed=Count("id", filter=Q(status=LeadStatus.CLOSED)),
)
lead_counts["conversion_rate_percentage"] = (
    round((lead_counts["contacted"] + lead_counts["closed"]) / lead_counts["total"] * 100, 1)
    if lead_counts["total"] else 0.0
)
# In the existing response: "interactions": interactions, "leads": lead_counts.
# Keep clinic_id, clinic_name, referrals, catalog and appointments=None unchanged.
```

Keep one count per unrelated catalog model with exactly the existing active/deleted predicates. This reduces 14 metric queries to 8, not to one magical correct cross-table aggregate. `badges/` **already uses one Lead.aggregate** at `badge_views.py:37`: retain it. Admin dashboard **already uses one clinic aggregate and one lead aggregate** at `admin_portal/views.py:78,103`: retain them and short-cache the resulting scalar metrics. Counts over distinct tables are not N+1; do not join them together to force a misleading query count.

Legacy admin engagement at `1090–1094` can use this one aggregate (existing response keys preserved):

```python
metrics = events.aggregate(
    app_opens_30d=Count("id", filter=Q(event_type=EventType.APP_OPEN)),
    whatsapp_taps_30d=Count("id", filter=Q(event_type=EventType.WHATSAPP_TAP)),
    call_taps_30d=Count("id", filter=Q(event_type=EventType.CALL_TAP)),
    maps_taps_30d=Count("id", filter=Q(event_type=EventType.MAPS_TAP)),
    clinic_views_30d=Count("id", filter=Q(event_type=EventType.CLINIC_VIEW)),
)
metrics["total_leads_30d"] = Lead.objects.filter(created_at__gte=timeframe).count()
# return Response(metrics)
```

Likewise collapse the three lead counts in platform analytics at `1022–1024` and the two counts in analytics views/tasks into one same-table aggregate. In the daily per-clinic task, precompute `events.values("clinic_id").annotate(...)` and `leads.values("clinic_id").annotate(...)` once and map by ID; do not perform three aggregate queries for every clinic in a loop. Date filtering must use timestamp ranges rather than `timestamp__date` where an index range can be used. Paginate raw audit logs and series; aggregate daily reporting into a rollup table when its retention exceeds bounded report ranges.

### 9.7 Remove outbound delivery from API request threads

Google Places is **already designed correctly**: public endpoints read persisted rating/count; periodic tasks call `services/google_places.py`, which uses a field mask and a timeout. Retain this architecture. The remaining issue is worker efficiency: retry sleeps inside a large clinic-sync batch occupy the worker. Use one bounded task per clinic, retries via Celery countdown, and a token-owned per-clinic lock. A timeout of 5 seconds is per attempt, not a total multi-attempt budget. Supply `timeout=(2, 3)` to Requests, limit worker attempts, and never put this call in `ClinicDetailAPIView` or a serializer. Index the stale-sync scan already using `google_last_synced_at`; inspect its plan before adding another index.

For OTP and push, the following is a concrete shared durable-outbox implementation. It writes only a DB record in the request thread; a Celery beat dispatcher publishes IDs in the worker, not secrets or OTP plaintext in broker task arguments. Add `cryptography` to backend requirements and a separately generated, secret-managed `DELIVERY_FERNET_KEY` (a valid Fernet key; do not derive it from a public setting). Rotate with `MultiFernet` if retaining pending deliveries across key rotation. Encrypt database backups as well.

Append this model to `apps/notifications/models.py` and generate a migration:

```python
from django.utils import timezone

class ExternalDelivery(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    # email_otp, sms_otp, push_user, push_topic
    kind = models.CharField(max_length=20)
    encrypted_payload = models.TextField()
    idempotency_key = models.CharField(max_length=128, unique=True)
    due_at = models.DateTimeField(default=timezone.now)
    expires_at = models.DateTimeField()
    lease_until = models.DateTimeField(null=True, blank=True)
    attempts = models.PositiveSmallIntegerField(default=0)
    completed_at = models.DateTimeField(null=True, blank=True)
    failed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["due_at", "id"],
                    condition=models.Q(completed_at__isnull=True, failed_at__isnull=True),
                    name="delivery_due_pending")]
```

New `apps/notifications/outbox.py`:

```python
import json
from datetime import timedelta
from cryptography.fernet import Fernet
from django.conf import settings
from django.utils import timezone
from apps.notifications.models import ExternalDelivery

def enqueue_delivery(kind, payload, *, idempotency_key, expires_at=None):
    ciphertext = Fernet(settings.DELIVERY_FERNET_KEY).encrypt(
        json.dumps(payload, separators=(",", ":")).encode()
    ).decode()
    row, _ = ExternalDelivery.objects.get_or_create(
        idempotency_key=idempotency_key,
        defaults={"kind": kind, "encrypted_payload": ciphertext,
                  "expires_at": expires_at or timezone.now() + timedelta(minutes=10)},
    )
    return row
```

New `apps/notifications/outbox_tasks.py` (import this module from existing `tasks.py` so Celery discovers it):

```python
import json
import secrets
from datetime import timedelta
from cryptography.fernet import Fernet
from celery import shared_task
from django.conf import settings
from django.core.cache import cache
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from apps.notifications.models import ExternalDelivery

@shared_task(ignore_result=True, soft_time_limit=10, time_limit=15)
def dispatch_external_deliveries():
    now = timezone.now()
    # A UUID-only queue is replayable after broker outage; lease is not delivery success.
    with transaction.atomic():
        rows = list(ExternalDelivery.objects.select_for_update(skip_locked=True).filter(
            completed_at__isnull=True, failed_at__isnull=True,
            due_at__lte=now, expires_at__gt=now,
        ).filter(Q(lease_until__isnull=True) | Q(lease_until__lt=now))
          .order_by("due_at", "id")[:20])
        ids = [row.pk for row in rows]
        ExternalDelivery.objects.filter(pk__in=ids).update(lease_until=now + timedelta(seconds=60))
    for delivery_id in ids:
        try:
            deliver_external.apply_async(args=[str(delivery_id)], retry=False, queue="external_io")
        except Exception:
            # Do not run external delivery here. A later beat sweep requeues it.
            ExternalDelivery.objects.filter(pk=delivery_id).update(lease_until=None)

@shared_task(ignore_result=True, soft_time_limit=20, time_limit=25,
             acks_late=True, reject_on_worker_lost=True)
def deliver_external(delivery_id):
    now = timezone.now()
    with transaction.atomic():
        row = ExternalDelivery.objects.select_for_update().filter(pk=delivery_id).first()
        if row is None or row.completed_at or row.failed_at:
            return
        if row.expires_at <= now or row.attempts >= 4:
            row.failed_at = now
            row.encrypted_payload = ""
            row.save(update_fields=["failed_at", "encrypted_payload"])
            return
        # Serialize execution of duplicate queued messages, without holding a DB lock over I/O.
    execution = cache.lock(f"aw:delivery:execute:{delivery_id}", timeout=30, blocking_timeout=0)
    if not execution.acquire(blocking=False):
        return
    try:
        with transaction.atomic():
            row = ExternalDelivery.objects.select_for_update().get(pk=delivery_id)
            if row.completed_at or row.failed_at or row.due_at > timezone.now():
                return
            if row.expires_at <= timezone.now() or row.attempts >= 4:
                row.failed_at = timezone.now()
                row.encrypted_payload = ""
                row.save(update_fields=["failed_at", "encrypted_payload"])
                return
            row.attempts += 1
            row.lease_until = timezone.now() + timedelta(seconds=60)
            row.save(update_fields=["attempts", "lease_until"])
        payload = json.loads(Fernet(settings.DELIVERY_FERNET_KEY).decrypt(
            row.encrypted_payload.encode()).decode())
        # A resend invalidates an older OTP delivery before it reaches the provider.
        expected = payload.pop("expected_otp_state", None)
        otp_key = payload.pop("otp_cache_key", None)
        if otp_key and cache.get(otp_key) != expected:
            ExternalDelivery.objects.filter(pk=row.pk).update(
                completed_at=timezone.now(), encrypted_payload="", lease_until=None)
            return
        if row.kind == "email_otp":
            from apps.accounts.services.email import get_email_otp_provider
            if not get_email_otp_provider().send_otp(**payload):
                raise RuntimeError("email provider rejected delivery")
        elif row.kind == "sms_otp":
            from apps.accounts.services.sms import get_sms_provider
            if not get_sms_provider().send_otp(**payload):
                raise RuntimeError("SMS provider rejected delivery")
        elif row.kind == "push_user":
            from apps.notifications.push import send_push_to_user_devices
            send_push_to_user_devices(**payload)
        elif row.kind == "push_topic":
            from apps.notifications.push import send_push_to_topic
            send_push_to_topic(**payload)
        elif row.kind == "notification_record":
            from apps.notifications.models import Notification, NotificationStatus
            from apps.notifications.service import get_notification_provider
            notification = Notification.objects.select_related("recipient").get(pk=payload["notification_id"])
            if notification.status != NotificationStatus.SENT:
                get_notification_provider().send(notification)
                Notification.objects.filter(pk=notification.pk).update(
                    status=NotificationStatus.SENT, sent_at=timezone.now())
        else:
            raise ValueError("unsupported delivery kind")
        ExternalDelivery.objects.filter(pk=row.pk).update(
            completed_at=timezone.now(), lease_until=None, encrypted_payload="")
    except Exception:
        # No provider exception text, destination, JWT or OTP in logs/error columns.
        ExternalDelivery.objects.filter(pk=delivery_id, completed_at__isnull=True).update(
            due_at=timezone.now() + timedelta(seconds=15 + secrets.randbelow(16)),
            lease_until=None,
        )
    finally:
        try:
            execution.release()  # Redis owner-token checked release
        except Exception:
            pass
```

Add a beat entry every 1 second for `apps.notifications.outbox_tasks.dispatch_external_deliveries`; run one beat scheduler and workers for `external_io` with concurrency tuned separately from API/database workers. Run regular cleanup: expired pending rows become failed, and completed/failed encrypted payloads are erased; retain only delivery metadata for the agreed retention. Task hard termination leaves a lease for the sweeper to recover. PostgreSQL `skip_locked` is required for the dispatcher. This is **at-least-once delivery**, not an exactly-once email guarantee; providers should accept idempotency keys where supported. A duplicate OTP email is preferable to losing a committed lead or restoring an old code.

Replace the provider dispatch/rollback block in `OtpService.send_otp()` with the following after its hash is stored; retain the existing success return shape (`expires_in`, `resend_cooldown`, masked email). The earlier recovery/one-time-consumption fixes remain in force.

```python
import uuid
from datetime import datetime, timezone as datetime_timezone
from apps.notifications.outbox import enqueue_delivery

# Inside OtpService.send_otp, after storing code_hash/expires_at:
enqueue_delivery(
    "email_otp",
    {"email": recipient_email, "code": code, "purpose": purpose,
     "otp_cache_key": otp_key, "expected_otp_state": f"{code_hash}|{expires_at}"},
    idempotency_key=f"otp:{uuid.uuid4().hex}",
    expires_at=datetime.fromtimestamp(expires_at, datetime_timezone.utc),
)
```

The HTTP response now means **accepted for delivery**, not SMTP confirmed. Return an error if persisting the outbox fails and remove only the matching newly generated Redis state. Apply the same pattern to `PhoneChangeService` (`sms_otp`, phone_change, its exact pending state including new phone) and `EmailChangeService` (`email_otp`, email_change, its exact pending state). Do not leave these two synchronous escape paths behind. OTP expiry remains measured from generation, not worker execution; expired jobs must never send. Alert on delivery age well before the OTP TTL and pause new requests with 503 if the delivery worker is unhealthy.

Replace resend `cache.get()` followed by `cache.set()` with one atomic reservation using `cache.add(resend_key, generation_id, timeout=cooldown)`. Do this after validating the destination and before generating/storing the code. Roll back the reservation only if it still belongs to that generation, using a Redis Lua compare-and-delete or a token-owned lock; a plain `cache.delete()` may erase a newer request's reservation. Verification attempt counters need atomic Redis increments with expiry; ordinary get/increment/set races under concurrent attempts. Keep account + purpose + IP limits and atomic code consumption from section 3.

Replace `send_push` in `apps/notifications/push.py` with a DB enqueue call, and change the topic enqueue wrapper analogously:

```python
import uuid
from apps.notifications.outbox import enqueue_delivery

def send_push(user, title, body, data=None):
    if user is None:
        return None
    return enqueue_delivery(
        "push_user", {"user_id": str(user.id), "title": title, "body": body, "data": data or {}},
        idempotency_key=f"push:{uuid.uuid4().hex}",
    )
```

**Required provider correction:** current `send_push_to_user_devices()` catches transient Firebase/network errors and returns as if successful. Deactivate only explicit invalid/unregistered tokens, propagate transient errors to the outbox worker, and return failure when Firebase is unavailable. Remove full/partial token logging. Enforce a bounded number of active devices per user (e.g. 5; retire older tokens on registration), or fan out one delivery per device so one account cannot cause an unlimited worker loop. Configure Firebase initialization with `options={"httpTimeout": 5}`. SDK retry/credential refresh time is additionally bounded by the worker soft/hard limit; verify with a deliberately stalled provider. No synchronous fallback is permitted on broker/provider failure.

Replace the body of `NotificationService.send_async()` with this DB-only implementation. It retains the Notification audit record and uses the same outbox worker; do not additionally call the old `deliver_notification.apply_async` path for these new records. The existing provider factory currently supports console/mock, so deploying a real FCM provider still requires implementing that adapter; do not call console output a delivered device push.

```python
@staticmethod
def send_async(recipient, notification_type, payload, channel="push"):
    from django.db import transaction
    from apps.notifications.models import Notification, NotificationStatus
    from apps.notifications.outbox import enqueue_delivery
    with transaction.atomic():
        notification = Notification.objects.create(
            recipient=recipient, notification_type=notification_type, channel=channel,
            status=NotificationStatus.PENDING, payload=payload,
        )
        enqueue_delivery(
            "notification_record", {"notification_id": str(notification.pk)},
            idempotency_key=f"notification:{notification.pk}",
        )
    return notification
```

Migrate older pending Notification rows into this outbox in a bounded worker job using the same `notification:<pk>` idempotency key. Add a unique business event key (`new_lead:<lead_id>:<recipient_id>` / `lead_status:<history_id>:<recipient_id>`) to prevent two different creation paths dispatching the same event. Fan out clinic recipients in the worker, rather than two membership loops in patient lead creation. Insert the outbox in the business transaction so rollback removes it. Do not expose encrypted payloads through Django admin list pages or diagnostic logs.

Add the following cleanup task to `outbox_tasks.py` and schedule it each minute. Each run bounds writes and erases expired OTP ciphertext. Once retention is agreed, delete old completed/failed metadata in bounded batches too.

```python
@shared_task(ignore_result=True)
def expire_external_deliveries():
    now = timezone.now()
    expired = list(ExternalDelivery.objects.filter(
        completed_at__isnull=True, failed_at__isnull=True, expires_at__lte=now,
    ).order_by("expires_at", "id").values_list("pk", flat=True)[:500])
    ExternalDelivery.objects.filter(pk__in=expired, completed_at__isnull=True).update(
        failed_at=now, lease_until=None, encrypted_payload="")
```

For atomic cooldown rollback and OTP generation consumption, this helper works with the configured django-redis serialization rather than comparing Python strings against raw pickled Redis bytes:

```python
def delete_matching_cache_value(key, expected):
    client = cache.client.get_client(write=True)
    redis_key = cache.make_key(key)
    encoded = cache.client.encode(expected)
    return bool(client.eval(
        "if redis.call('get', KEYS[1]) == ARGV[1] then "
        "return redis.call('del', KEYS[1]) else return 0 end",
        1, redis_key, encoded,
    ))
```

Reserve the cooldown with `cache.add` and a random generation token, then use this helper on rollback with that token. Use a dedicated Redis-backed test configuration to verify it; LocMemCache cannot run Lua and must not silently replace this concurrency guarantee in production.


Provider and storage settings for API/worker bounds:

```python
# settings: keep secrets in environment, never in code or the mobile bundle.
EMAIL_TIMEOUT = 5
CELERY_TASK_ALWAYS_EAGER = False
CELERY_TASK_PUBLISH_RETRY = False
CELERY_BROKER_CONNECTION_TIMEOUT = 1
CELERY_BROKER_TRANSPORT_OPTIONS = {
    "socket_connect_timeout": 1, "socket_timeout": 1,
    "visibility_timeout": 120,
}
CELERY_WORKER_PREFETCH_MULTIPLIER = 1

from botocore.config import Config
AWS_S3_CLIENT_CONFIG = Config(
    connect_timeout=2, read_timeout=5,
    retries={"mode": "standard", "total_max_attempts": 2},
    max_pool_connections=20,
)
```

R2's current server-mediated upload still writes bytes in an API worker: strict timeouts and 1600px client compression reduce exposure, but do not make storage writes asynchronous. Keep raster-byte validation, maximum request/file size, tenant ownership and server-generated object keys. A direct-upload protocol requires presign → PUT → finalize, server-side HEAD/type/size/hash validation and an unattached-asset cleanup job; implement and test that as a distinct API, then update Flutter. Do not respond "saved" before storage persistence succeeds.

One additional confirmed notification authorization defect: `DeviceTokenDestroyAPIView.delete()` currently filters only by token. Change it to `DeviceToken.objects.filter(token=token, user=request.user).update(is_active=False)`; one patient must not deactivate another patient's token. Existing unique-token upsert protects concurrent registration; test simultaneous re-login/reassignment and logout ownership.

### 9.8 Redis snapshots, cache keys, and invalidation without stampedes

Do not cache permission decisions or private data under a public/global key. Resolve role + clinic permission on every request before reading a clinic metric cache. Cache **scalar data/relative object keys**, not signed media URLs near expiry. A cached signed URL TTL must be shorter than the signing TTL minus clock/skew margin; a fresh media serializer should issue the URL. Home cached absolute URLs need scheme/host/language in the key (or normalize to the configured API/media origin).

Use the configured `django_redis.cache.RedisCache`. New `core/cache_snapshots.py`:

```python
import hashlib
import json
import secrets
from django.core.cache import cache
from rest_framework.exceptions import APIException

class SnapshotWarming(APIException):
    status_code = 503
    default_detail = "Summary is warming. Please retry."
    default_code = "summary_warming"
    wait = 1

def invalidate_snapshot(scope):
    # A new random generation avoids missing-key increment races and delete scans.
    cache.set(f"aw:v3:generation:{scope}", secrets.token_hex(12), timeout=None)

def snapshot(scope, parameters, build, *, ttl=15):
    generation_key = f"aw:v3:generation:{scope}"
    generation = cache.get(generation_key)
    if generation is None:
        cache.add(generation_key, secrets.token_hex(12), timeout=None)
        generation = cache.get(generation_key)
    digest = hashlib.sha256(json.dumps(parameters, sort_keys=True, default=str).encode()).hexdigest()
    key = f"aw:v3:snapshot:{scope}:{generation}:{digest}"
    result = cache.get(key)
    if result is not None:
        return result
    lock = cache.lock(f"{key}:lock", timeout=10, blocking_timeout=0.2)
    if not lock.acquire(blocking=True):
        result = cache.get(key)
        if result is not None:
            return result
        raise SnapshotWarming()
    try:
        result = cache.get(key)
        if result is None:
            result = build()
            cache.set(key, result, timeout=ttl + secrets.randbelow(4))
        return result
    finally:
        try:
            lock.release()
        except Exception:
            pass
```

This deliberately coalesces cold rebuilds rather than making all 500 workers rebuild. The 200 ms lock wait is bounded. Prewarm common home/admin summary keys before opening traffic and after a deploy; monitor `summary_warming` separately. For high write rates use a materialized counter/snapshot updated in background rather than invalidating and recomputing a full dashboard on every event. A stale-while-refresh variant may serve an explicitly timestamped previous metrics snapshot, but must never serve stale authorization or resurrect suspended clinics.

Wrap the scalar clinic metrics builder in `snapshot(f"clinic-metrics:{clinic.pk}", {}, build_metrics, ttl=10)`. Wrap admin metrics in `snapshot("admin-metrics", {}, build_metrics, ttl=15)`. Keep live badge status counts accurate or use a short 2–5 second TTL with transactional invalidation. Use distinct scopes for public home and private metrics.

A bounded home cache identity must include **both city and geo**, rather than returning early for geo as the current helper does. Example identity helper:

```python
from django.utils.translation import get_language

def home_cache_parameters(request):
    city = str(request.query_params.get("city", "")).strip().casefold()[:50]
    lat = request.query_params.get("latitude") or request.query_params.get("lat")
    lng = request.query_params.get("longitude") or request.query_params.get("lng")
    geo = None
    try:
        a, b = float(lat), float(lng)
        if -90 <= a <= 90 and -180 <= b <= 180:
            geo = [round(a, 2), round(b, 2)]
    except (ValueError, TypeError):
        pass
    return {"city": city, "geo": geo, "language": get_language(),
            "origin": request.build_absolute_uri("/")}
```

If coordinates are bucketed in the cache, use the same rounded coordinates in the query; otherwise different exact distances are cached under one key. Do not cache exact patient coordinates. Current home bounds (8 categories, 10 ads/nearby clinics/offers) are intentional summaries: keep the View All routes and do not append entire catalogs to the feed. Add the missing offer `image_url` field and pass `context={"request": request}` to **all four** home serializers; select media asset relations. A CDN must never share private portal responses.

New `apps/clinics/scale_signals.py` for version invalidation:

```python
from django.db import transaction
from django.db.models.signals import post_save, post_delete, m2m_changed
from apps.clinics.models import Clinic, ClinicBranch
from apps.practitioners.models import Practitioner
from apps.treatments.models import Treatment, Category, PractitionerTreatment
from apps.offers.models import Offer
from apps.products.models import Product
from apps.articles.models import Article
from apps.leads.models import Lead
from apps.analytics.models import AnalyticsEvent
from apps.media.models import FeaturedAd, MediaAsset
from core.cache_snapshots import invalidate_snapshot

PUBLIC_MODELS = (Clinic, ClinicBranch, Practitioner, Treatment, Category, Offer, Product, Article, FeaturedAd, MediaAsset)
METRIC_MODELS = (Clinic, Practitioner, Treatment, Offer, Product, Article, Lead, AnalyticsEvent)

def invalidate_after_commit(sender, instance, **kwargs):
    scopes = set()
    if sender in PUBLIC_MODELS:
        scopes.add("public-home")
    if sender in METRIC_MODELS:
        scopes.add("admin-metrics")
        clinic_id = instance.pk if sender is Clinic else getattr(instance, "clinic_id", None)
        if clinic_id:
            scopes.add(f"clinic-metrics:{clinic_id}")
    transaction.on_commit(lambda scopes=tuple(scopes): [invalidate_snapshot(s) for s in scopes])

for model in set(PUBLIC_MODELS + METRIC_MODELS):
    post_save.connect(invalidate_after_commit, sender=model, weak=False,
                      dispatch_uid=f"aw:scale:save:{model._meta.label_lower}")
    post_delete.connect(invalidate_after_commit, sender=model, weak=False,
                        dispatch_uid=f"aw:scale:delete:{model._meta.label_lower}")
```

Import `scale_signals` from the existing clinics AppConfig.ready(), retaining other signal imports. `QuerySet.update()`, `bulk_update()`, raw SQL and bulk creates **do not emit post_save**. Explicitly call invalidation after commit in moderation/provisioning/Google-sync bulk writers and import jobs. Invalidate both old and new clinic scopes if reassignment is allowed. Changes to redeemed referrals must invalidate the redeemed clinic/admin metrics too; add ReferralDiscountCode with `redeemed_clinic_id` rather than pretending it has `clinic_id`. Through-model create/delete must invalidate treatment/practitioner previews; include `PractitionerTreatment` or m2m receivers where those relations are actually cached. Remove unused signal imports if adopting the direct-through hook. Cached URL metadata needs invalidation on MediaAsset replacement even when catalog models are untouched.

Avoid a process-local cache in production: 500 users distributed over multiple Gunicorn processes need shared Redis. If Redis is unavailable, metric caching should fail with a bounded error or use an explicit bounded database fallback behind concurrency admission; unrestricted fallback recreates a database stampede. Keep OTP, throttle state and general cache in separately provisioned key namespaces/instances and monitor memory/evictions. Never evict active OTP state with an image/feed cache LRU policy.

### 9.9 Composite indexes and connection budget

The supplied backend already has useful composites: clinic `(status, deleted_at, city)` and tier, treatment `(clinic, status)` / `(clinic,is_active,deleted_at)`, offer active/window/status, product three/four-field status composites, article `(clinic,status,is_published)`, and lead `(clinic,status)`. The additions below serve ordered pagination, not duplicate foreign-key lookup. Add to each model's **existing** `Meta.indexes`; retain existing indexes until EXPLAIN/write-cost evidence justifies removal.

```python
# apps/leads/models.py — Lead.Meta.indexes additions:
lead_paging_indexes = [
    models.Index(fields=["clinic", "-created_at", "-id"], name="lead_clinic_recent"),
    models.Index(fields=["clinic", "status", "-created_at", "-id"], name="lead_clinic_status_recent"),
    models.Index(fields=["patient", "-created_at", "-id"], name="lead_patient_recent"),
    models.Index(fields=["-created_at", "-id"], name="lead_admin_recent"),
]
# No deleted_at column exists on Lead: do not add a predicate for it.

# apps/clinics/models.py — Clinic.Meta.indexes addition:
clinic_paging_indexes = [
    models.Index(fields=["city", "display_order", "name_en", "id"],
                 condition=models.Q(status="active", deleted_at__isnull=True),
                 name="clinic_live_city_order"),
]
# This helps a live city-filtered scan; it does NOT satisfy the computed tier_rank/
# PostGIS distance ordering by itself. Inspect EXPLAIN on the actual expression.

# apps/treatments/models.py — Treatment.Meta.indexes additions:
treatment_paging_indexes = [
    models.Index(fields=["clinic", "name_en", "id"],
                 condition=models.Q(deleted_at__isnull=True), name="treat_clinic_name_live"),
    models.Index(fields=["category", "name_en", "id"],
                 condition=models.Q(status="active", is_active=True, deleted_at__isnull=True),
                 name="treat_category_live_name"),
]

# apps/offers/models.py — Offer.Meta.indexes addition:
offer_paging_indexes = [
    models.Index(fields=["clinic", "-created_at", "-id"],
                 condition=models.Q(deleted_at__isnull=True), name="offer_clinic_recent_live"),
]

# apps/products/models.py — Product.Meta.indexes additions:
product_paging_indexes = [
    models.Index(fields=["clinic", "-created_at", "-id"],
                 condition=models.Q(deleted_at__isnull=True), name="product_clinic_recent"),
    models.Index(fields=["-created_at", "-id"],
                 condition=models.Q(status="active", is_active=True, deleted_at__isnull=True),
                 name="product_public_recent"),
]

# apps/articles/models.py — Article.Meta.indexes additions:
article_paging_indexes = [
    models.Index(fields=["clinic", "-created_at", "-id"],
                 condition=models.Q(deleted_at__isnull=True), name="article_clinic_recent"),
    models.Index(fields=["-created_at", "-id"],
                 condition=models.Q(status="active", is_published=True, deleted_at__isnull=True),
                 name="article_public_recent"),
]
```

Model file code uses `models.Index`; these named lists are the exact additions to paste inside each corresponding Meta.indexes list, not new module-level settings that Django discovers automatically. Generate migrations against Ali's actual branch; use `AddIndexConcurrently` and `atomic=False` for an established PostgreSQL production database. For example, **after generating the Lead migration** from these model changes, its operations can use:

```python
from django.contrib.postgres.operations import AddIndexConcurrently
from django.db import migrations, models

class Migration(migrations.Migration):
    atomic = False
    dependencies = [("leads", "0002_lead_treatment")]
    operations = [
        AddIndexConcurrently(model_name="lead", index=models.Index(
            fields=["clinic", "-created_at", "-id"], name="lead_clinic_recent")),
        AddIndexConcurrently(model_name="lead", index=models.Index(
            fields=["clinic", "status", "-created_at", "-id"], name="lead_clinic_status_recent")),
        AddIndexConcurrently(model_name="lead", index=models.Index(
            fields=["patient", "-created_at", "-id"], name="lead_patient_recent")),
        AddIndexConcurrently(model_name="lead", index=models.Index(
            fields=["-created_at", "-id"], name="lead_admin_recent")),
    ]
```

The dependency above matches the supplied snapshot; rebase it if previous sections add a leads migration. Do not run both this example and a generated duplicate migration. Concurrent index creation is PostgreSQL-specific; use ordinary AddIndex in SQLite-only unit tests or a separate PostgreSQL integration suite. Large text `icontains` is not accelerated by a normal B-tree index; add `pg_trgm` and matching trigram indexes only after measuring search plans. Verify the SQL expression used by case-insensitive filters (e.g. `UPPER(city)`); an index on plain city does not automatically match it. Dynamic `now()` cannot appear in an immutable partial-index predicate, so do not index offers with `ends_at__gte=timezone.now()` in a partial condition.

`CONN_MAX_AGE` is **already 60** in `config/settings/base.py:103`; preserve it for synchronous Gunicorn. Add health checking and bounded database statements:

```python
DATABASES["default"]["CONN_HEALTH_CHECKS"] = True
DATABASES["default"]["CONN_MAX_AGE"] = config("DB_CONN_MAX_AGE", default=60, cast=int)
DATABASES["default"]["OPTIONS"].update({
    "connect_timeout": 3,
    "options": "-c statement_timeout=3000 -c lock_timeout=1000 -c idle_in_transaction_session_timeout=10000",
})
```

Some managed PostgreSQL/PgBouncer configurations reject session startup `options`; set the same limits at the database role/pooler when required and verify them with `SHOW`. Long migrations/analytics backfills need a separate worker/role timeout. With transaction-pooling PgBouncer, set `DISABLE_SERVER_SIDE_CURSORS=True`; verify session-dependent features. ASGI deployments should use the appropriate pool and connection lifespan rather than blindly copying synchronous persistence settings.

Budget connections by **replicas × Gunicorn workers × threads**, plus Celery/admin/migration connections, below PostgreSQL/PgBouncer limits with headroom. 500 simultaneous users do not require 500 persistent database connections. Start from measured worker RSS and CPU, then tune. Keep total SQL time, lock time, pool wait and connection count in the dashboard; never increase worker count until the database saturates.

### 9.10 Balanced throttling and 500-user acceptance gates

The snapshot has named rates but no `ScopedRateThrottle` in defaults; names alone do nothing for views that set `throttle_scope`. Rates are per identity, not a platform-wide 500-user quota. Starting values (tune from staging traces, not production guesswork):

```python
REST_FRAMEWORK["DEFAULT_THROTTLE_CLASSES"] = [
    "rest_framework.throttling.AnonRateThrottle",
    "rest_framework.throttling.UserRateThrottle",
    "rest_framework.throttling.ScopedRateThrottle",
]
REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"].update({
    "anon": "120/min", "user": "240/min",  # shared-NAT behavior must be measured
    "login": "5/min", "register": "5/min", "otp_request": "3/min",
    "otp_resend": "3/min", "otp_verify": "5/min",
    "forgot_password": "3/min", "password_reset": "5/min",
    "lead_create": "10/hour", "media_upload": "10/min",
    "referral_claim": "10/min", "coupon_redeem": "10/min",
})
# MediaUploadView: throttle_scope = "media_upload"
```

Audit every auth view's own `throttle_classes`; an override replaces defaults, so include all intended classes there. A class attribute is preferable to mutating shared settings in a request. Preserve the stronger account/purpose OTP service limits and phone/IP verification lockout. DRF cache-history throttles are approximate under concurrency; use atomic Redis Lua/INCR or an edge rate limiter for hard OTP/abuse limits. Configure trusted proxy/NAT identity (`NUM_PROXIES` and forwarded-header trust) correctly before depending on IP limits. Return `Retry-After`; do not automatically retry non-idempotent lead/create/upload calls after timeouts.

**Required staging acceptance, after Ali applies the handoff:**

1. Seed at least 10,000 leads and 1,000 items per catalog, with one clinic containing 200+ treatments/practitioners/products and one lead with 10,000 notes/history rows. Use synthetic identities, sandbox email/FCM, a separate storage bucket and production-like PostgreSQL + Redis. Seed outside measured windows.
2. API contract tests: no page params still returns an envelope with ≤20 results; `page_size=10000` and `per_page=10000` still return ≤20; page 2 has stable order and no duplicates for a fixed dataset; out-of-range page is 404; every list query scales with a **constant number** of SQL statements as page contents grow. Test query counts at 1 and 20 rows, not only `assertNumQueries` on an empty database.
3. Detail budgets: public clinic has ≤6 nested branches/staff/treatments; no unbounded relation prefetch; clinic detail ≤4 data queries excluding auth/permission; clinic lead list does not load notes/history; detail ≤20 recent rows and full history GET pages work within tenant scope. `CaptureQueriesContext` plus realistic fixtures must prove the asset/category joins eliminate per-row selects. Badge aggregate is one metrics query, not one total including permission/auth.
4. Cache tests: 500 parallel readers of a **warm** key run no rebuild; a cold key permits one rebuild with bounded wait/backpressure; a transaction rollback does not invalidate; committed profile/catalog/status/Google-rating changes change the correct generations; two cities with identical geo do not collide; signed URL validity exceeds cache TTL. Include bulk-update invalidation tests.
5. Delivery tests: stall SMTP/FCM/R2, kill a worker after provider send but before status update, interrupt Redis/broker, delay a resend beyond the prior OTP job, race verification 100 times and submit simultaneous OTP requests. No synchronous push/email escapes; no stale OTP delivery or reuse; pending outbox recovers; business transactions remain correct. Validate 5-device cap/fanout, owner-only device deletion and pending-notification sweeper.
6. Run a load tool with 500 authenticated virtual users, ramp over 2–5 minutes, then 15 minutes sustained plus a separate synchronized startup burst. Weighted traffic: home/discovery reads, clinic profile/tab pages, patient/clinic/admin lead pages, debounced searches, and a small authenticated mutation/upload share. Explicitly test expired-token batches and empty-cache deploy startup. Report achieved throughput, p50/p95/p99, errors/429/503, worker RSS/CPU, DB query/connection/pool waits, Redis latency/hit rate, Celery queue age and provider latency. Keep profiles/roles realistic; one shared JWT is not 500-user auth coverage.
7. Initial acceptance targets to agree for the deployment: warmed read p95 <500 ms, p99 <1 s, non-throttle 5xx <0.5%, no increasing RSS over the steady phase, no database connection exhaustion, 0 duplicate committed leads from a single idempotency key, and OTP queue age safely below TTL. These are **targets, not measured results**. Persist the exact load script, seeded counts, deployment configuration and full result logs.
8. On physical lower-memory Android and iOS devices, profile in Flutter **profile/release mode** with 1,000 loaded records: frame build+raster <16.7 ms at 60 Hz / <8.3 ms at 120 Hz, bounded image memory, no codec growth across 100 tab/background/route cycles, keyboard and Arabic/English accessibility text checks. Headless widget tests and 500 mocked Dio calls cannot certify these frame budgets.

Deployment order: backend contracts/permissions/media fixes → migrations/indexes/outbox workers and beat → warm snapshots and run acceptance → deploy Flutter → build/sign production release. Do not label an APK production-ready merely because analyze and unit/widget tests pass.

---

## 2026-10-20 — Clinic Portal categories, HTTPS media, and image persistence

**Deployment required / يتطلب النشر:** The Flutter portal now exposes category creation, bilingual renaming, and deletion. It tries `clinic-portal/categories/` first and falls back to `categories/` only on HTTP 404/405/501. Authentication/permission/validation errors and timeouts are never retried against another endpoint. The original reference only implements category GET; exposing the UI does not deploy these Django writes.

Categories are a **shared global taxonomy** in the current database, not clinic-owned records. The requested policy permits authenticated `clinic_admin` and `super_admin` users to edit this shared taxonomy. Do not imply tenant ownership without adding a corresponding model field. Deletion must reject categories referenced by **any** treatment, including soft-deleted treatments: the existing Category foreign key uses CASCADE and an unguarded delete could remove treatments in other clinics.

### Category API — paste as `apps/treatments/category_crud.py`

No category schema migration is required. Slugs are generated server-side on creation and remain stable on rename.

```python
import uuid

from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils.text import slugify
from rest_framework import filters, generics, serializers, status
from rest_framework.exceptions import APIException
from rest_framework.permissions import BasePermission, SAFE_METHODS
from rest_framework.response import Response

from apps.treatments.models import Category, Treatment


class CategoryAccess(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        user = request.user
        return bool(
            user and user.is_authenticated
            and user.role in {"clinic_admin", "super_admin"}
        )


class PortalCategoryAccess(CategoryAccess):
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated
            and super().has_permission(request, view)
        )


class CategoryWriteSerializer(serializers.ModelSerializer):
    name_en = serializers.CharField(max_length=200, allow_blank=False)
    name_ar = serializers.CharField(max_length=200, allow_blank=False)

    class Meta:
        model = Category
        fields = ["id", "name_en", "name_ar", "slug", "icon", "display_order"]
        read_only_fields = ["id", "slug", "icon", "display_order"]

    def create(self, validated_data):
        prefix = slugify(validated_data["name_en"])[:180] or "category"
        validated_data["slug"] = f"{prefix}-{uuid.uuid4().hex}"
        return super().create(validated_data)


class CategoryInUse(APIException):
    status_code = status.HTTP_409_CONFLICT
    default_detail = "This category is used by treatments and cannot be deleted."
    default_code = "category_in_use"


class CategoryListCreateAPIView(generics.ListCreateAPIView):
    permission_classes = [CategoryAccess]
    serializer_class = CategoryWriteSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ["name_en", "name_ar"]

    def get_queryset(self):
        return Category.objects.filter(is_active=True).order_by("display_order", "name_en", "pk")


class CategoryDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [CategoryAccess]
    serializer_class = CategoryWriteSerializer
    queryset = Category.objects.filter(is_active=True)
    lookup_url_kwarg = "id"
    http_method_names = ["get", "patch", "delete", "head", "options"]

    @transaction.atomic
    def destroy(self, request, *args, **kwargs):
        category = get_object_or_404(
            self.get_queryset().select_for_update(), pk=self.kwargs["id"]
        )
        self.check_object_permissions(request, category)
        if Treatment.objects.filter(category_id=category.pk).exists():
            raise CategoryInUse()
        category.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class PortalCategoryListCreateAPIView(CategoryListCreateAPIView):
    permission_classes = [PortalCategoryAccess]


class PortalCategoryDetailAPIView(CategoryDetailAPIView):
    permission_classes = [PortalCategoryAccess]
```

In **`api/v1/urls.py`**, replace the existing `categories/` GET registration (do not leave an earlier matching GET-only route), and add the following imports/routes inside the existing API-v1 `urlpatterns`:

```python
from apps.treatments.category_crud import (
    CategoryListCreateAPIView, CategoryDetailAPIView,
    PortalCategoryListCreateAPIView, PortalCategoryDetailAPIView,
)

# These paths are inside the existing /api/v1/ include:
path("categories/", CategoryListCreateAPIView.as_view(), name="category-list"),
path("categories/<uuid:id>/", CategoryDetailAPIView.as_view(), name="category-detail"),
path("clinic-portal/categories/", PortalCategoryListCreateAPIView.as_view(), name="portal-category-list"),
path("clinic-portal/categories/<uuid:id>/", PortalCategoryDetailAPIView.as_view(), name="portal-category-detail"),
```

Expected responses: POST **201** with the complete category including UUID; PATCH **200** with the renamed category; DELETE **204**; DELETE in-use category **409**; unauthenticated/unauthorized writes **401/403**. Patient and `clinic_staff` write attempts must fail. Both route families operate on the same Category rows. Keep standard pagination and AR/EN search enabled.

### Practitioner / offer persistence — do not discard URL strings

The old archive contains `to_internal_value()` overrides that pop `avatar`/`image` when they are strings. Remove those overrides completely. The newer `backend_latest.zip` already contains a portal-image mixin; reconcile the following contract with that implementation instead of adding a second conflicting mixin.

The shared image field/mixin in this document must enforce these exact rules:

- Uploaded asset UUID + URL: validate asset purpose/ownership, assign the fresh FK, and clear the legacy URL column.
- Direct URL without asset UUID: retain the URL, clear any stale FK, and never download arbitrary URLs on the server.
- Explicit image `null`/empty: normalize the non-nullable URL column to `""` and clear its FK. Omission preserves existing media.
- Binary image: validate it, store it as a MediaAsset with the correct media type, and return the new URL.
- Asset lookup must reject another clinic's private assets and incorrect media types. Do not replace the scoped queryset with an unrestricted FK assignment.

After installing the shared `PortalImageInputField` / `ScopedPortalImageMixin` from the earlier **“Shared serializer implementation / تطبيق مشترك للسيريالايزر”** section, use these exact class declarations and remove the old string-dropping methods:

```python
# apps/practitioners/portal_serializers.py
from apps.media.portal_images import PortalImageInputField, ScopedPortalImageMixin
from apps.media.models import MediaType

class ClinicPractitionerPortalSerializer(ScopedPortalImageMixin, serializers.ModelSerializer):
    avatar = PortalImageInputField(required=False, allow_null=True)
    image_field_name = "avatar"
    image_media_type = MediaType.PRACTITIONER_AVATAR
    # Retain the existing fields, Meta, and type/status validation below.
    # Delete the entire old to_internal_value override that pops avatar strings.
```

```python
# apps/offers/portal_serializers.py
from apps.media.portal_images import PortalImageInputField, ScopedPortalImageMixin
from apps.media.models import MediaType

class ClinicOfferPortalSerializer(ScopedPortalImageMixin, serializers.ModelSerializer):
    image = PortalImageInputField(required=False, allow_null=True)
    image_field_name = "image"
    image_media_type = MediaType.OFFER_IMAGE
    # Retain existing fields, Meta, pricing/date/clinic validation below.
    # Delete the entire old to_internal_value override that pops image strings.
```

If the chosen shared mixin implements `validate()`, the serializers' own `validate()` methods must end with `return super().validate(attrs)` so their MRO does not bypass it. Keep tenant/type checks after ownership resolution. The current newer reference handles input normalization in the mixin's `to_internal_value`; do not silently replace it with a version whose validation is never invoked.

**Model output must prefer the new asset.** Replace the existing properties with these bodies (inside their respective model classes):

```python
# Replace Practitioner.avatar_url:
@property
def avatar_url(self):
    from apps.media.utils import resolve_media_url
    if self.media_asset_id and self.media_asset and self.media_asset.file:
        return resolve_media_url(self.media_asset.file) or ""
    return resolve_media_url(self.avatar) or ""
```

```python
# Replace Offer.image_url:
@property
def image_url(self):
    from apps.media.utils import resolve_media_url
    if self.media_asset_id and self.media_asset and self.media_asset.file:
        return resolve_media_url(self.media_asset.file) or ""
    return resolve_media_url(self.image) or ""
```

Keep `avatar_url` and `image_url` in the response serializers. Set the legacy `Practitioner.avatar` and `Offer.image` URLFields to `max_length=1000, blank=True, default=""`, then run `python manage.py makemigrations practitioners offers` and deploy those migrations before accepting long signed URLs. Retain multipart + JSON parsers on the views. The earlier sections cover equivalent product/article behavior and clinic ImageField URL handling.

### Production HTTPS and real storage availability

Flutter now upgrades only first-party `http://aestheticway.ae` / subdomain media URLs to HTTPS and normalizes duplicated slashes in first-party/relative media paths. R2/external URLs, encoded object names, and query signatures stay unchanged. Do not enable unrestricted Android cleartext traffic to work around the server configuration.

Configure Django to trust forwarded protocol **only behind a trusted reverse proxy that overwrites those headers**:

```python
# config/settings/production.py, after the proxy is configured correctly:
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
USE_X_FORWARDED_HOST = True
```

```nginx
# In the trusted TLS Nginx location that proxies Django:
proxy_set_header Host $host;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Proto $scheme;
```

For filesystem media, ensure `/media/` is served from the actual MEDIA_ROOT over HTTPS. For R2, verify the returned object URL resolves to image bytes, content type is an image type, signatures have not expired, and the public/custom storage hostname is configured correctly. Test from a device without a local cache and after application restart. A 200 profile PATCH alone does not prove that the returned URL is accessible or that a serializer persisted the photo.

The Flutter `LocalMediaCache` is bounded and scoped to the current authenticated session. Successful saves map original picked files by entity key and returned URL; the renderer can show them immediately without a CDN fetch. It clears on session reset/logout and skips missing files. It **does not repair nginx/R2, synchronize another device, survive application restart, or prove durable backend persistence**. Only backend deployment and a fresh-client read can establish those properties.

### Deployment acceptance

1. Create/rename/delete an unused category through both URL families; verify public GET and treatment category selection reflect it. In-use deletion must return 409 without deleting any treatment.
2. Verify patient/staff writes fail and clinic_admin/super_admin writes succeed. Names validate at 200 characters; the generated slug remains stable on rename.
3. For practitioner and offer: test binary upload, uploaded UUID+URL, direct URL, omitted image, explicit null, and wrong-clinic/wrong-type assets.
4. Re-fetch saved profiles/catalog items from a separate fresh client. Check returned URLs load over HTTPS without Flutter's local cache.
