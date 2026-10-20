# Security hardening handoff for Ali / تسليم المعالجة الأمنية لعلي

Date / التاريخ: 2026-10-20.

**Backend ownership:** Ali exclusively owns Django implementation, migration and deployment. The backend supplied for this review was read-only. The Python below is a source-grounded integration proposal, not code executed or deployed by this Flutter PR. Verify imports, serializer compatibility, Redis behavior and tests in the backend repository before applying it. References use the supplied `backend-latest-reference` layout; line numbers are snapshot anchors, with class/method names as the durable reference.

**ملكية الباك إند:** علي وحده مسؤول عن تعديل Django وترحيل قاعدة البيانات والنشر. لم نعدّل ملفات الباك إند أو إعدادات الإنتاج أو بيانات المستخدمين. أمثلة Python أدناه مقترحات دمج مبنية على المصدر المقروء، ولم تُنفّذ أو تُنشر. يجب مراجعة التوافق والاختبارات في مستودع الباك إند أولاً.

No production probing was performed. No authorized staging accounts were available. Source-confirmed weaknesses are distinguished from live exploitation. See [SECURITY_AUDIT_REPORT.md](SECURITY_AUDIT_REPORT.md) and [SECURITY_REGRESSION_TEST_MATRIX.md](SECURITY_REGRESSION_TEST_MATRIX.md).

لم تُجر اختبارات هجومية على الإنتاج، ولا تتوفر حسابات اختبار مرحلية مصرح بها. وجود مسار ضعيف في المصدر لا يثبت استغلاله في الخادم المنشور.

## Priority and deployment order / الأولويات وترتيب النشر

| ID | Priority | Owner action / المطلوب |
|---|---|---|
| B01 | High | Enforce patient-only lead/referral scope / قصر مسارات المريض على دور المريض |
| B02 | High | Deny inactive/suspended/deleted clinic media operations / منع الوسائط للعيادات والحسابات غير الفعالة |
| B03 | High | Remove profile string-media validation bypass / إغلاق تجاوز التحقق من وسائط الملف |
| B04 | High | Atomic OTP counters and one-time reset / ذرية محاولات OTP واستهلاك إعادة التعيين مرة واحدة |
| B05 | High | Check live account at token issue/refresh; revocation policy / التحقق من الحساب عند إصدار وتجديد الرمز |
| B08 | High | Patch advisory-affected dependency pins with compatibility tests / تحديث الاعتماديات المتأثرة مع اختبار التوافق |
| B06 | Medium | Remove PII from logs/analytics/push / تقليل البيانات الشخصية في السجلات والتحليلات والإشعارات |
| B07 | Medium | Fail-closed media processing and metadata policy / رفض الوسائط غير القابلة للتحقق وضبط البيانات الوصفية |

Patch/test dependencies and permissions in staging first, then the authentication/media/privacy changes. Keep a known signed mobile build and tested backend deployment artifact. Do not reopen guest writes or unsafe media paths as an emergency rollback; disable the affected feature at the server until a fixed artifact is ready.

ابدأ في بيئة مرحلية بالاعتماديات والصلاحيات، ثم المصادقة والوسائط والخصوصية. احتفظ بحزمة نشر سابقة موثوقة. عند التراجع، عطّل العملية المتأثرة بدلاً من إعادة السماح للضيف أو إعادة مسار تجاوز التحقق.

## B01 — Patient-only lead and referral routes / مسارات المريض

**Classification/evidence:** Confirmed source weakness, High. `apps/leads/views/patient_views.py`: `LeadCreateAPIView:31` uses `AllowAny`; `MyLeadsAPIView:191`, `MyLeadDetailAPIView:218` and `MyLeadsCountAPIView:239` allow patient **or Super Admin** in the personal-history role check. Their patient query filters already prevent reading another patient's lead. `apps/referrals/views/patient_views.py`: `ReferralStatusAPIView:27` permits any authenticated role and creates a PatientProfile; `CollectCodeAPIView:72` still issues legacy vouchers. This is a role/policy gap, not demonstrated cross-patient BOLA.

**الدليل والأثر:** إنشاء الطلب يسمح للضيف، وبعض المسارات الشخصية تسمح بدور المشرف، وحالة الإحالة تنشئ ملف مريض لأي دور مسجل. فلاتر ملكية الطلب موجودة ويجب الحفاظ عليها. إصدار القسائم القديم يخالف نظام الدعوة والنقاط الحالي، ولم نثبت قراءة طلبات مريض آخر.

**Permission/code proposal:** add a reusable permission in `apps/accounts/permissions.py` (or the backend's canonical shared permission module), then use it with IsAuthenticated on lead creation/history/count and referral status. Replace the patient-or-admin checks with patient only. Keep `Lead.objects.filter(patient=request.user)` and derive `patient` on the server; never accept an arbitrary patient ID.

```python
from rest_framework.permissions import BasePermission, IsAuthenticated
from apps.accounts.models import UserRole

class IsActivePatient(BasePermission):
    message = "This action is available to patient accounts only."

    def has_permission(self, request, view):
        user = request.user
        return bool(
            user and user.is_authenticated and user.is_active
            and user.deleted_at is None
            and user.role == UserRole.PATIENT
        )

# Set on LeadCreateAPIView, MyLeadsAPIView, MyLeadDetailAPIView,
# MyLeadsCountAPIView and ReferralStatusAPIView:
# permission_classes = [IsAuthenticated, IsActivePatient]

# Keep historical voucher records, but replace CollectCodeAPIView.post:
def post(self, request):
    return Response(
        {"detail": "This reward action has been retired."},
        status=status.HTTP_410_GONE,
    )
# CollectCodeAPIView must also require IsAuthenticated + IsActivePatient.
```

**Schema/compatibility:** no schema migration. Historical guest leads must not be assigned to an arbitrary new patient. Guest lead writes now return 401; authenticated other roles return 403. Existing Flutter already requires a verified patient session for lead/referral actions. Preserve public, minimal invite resolution and the unified HTTPS link, points and milestones; do not add registration code inputs or coupon strings.

**Tests/deploy/rollback:** five-role matrix; A→B lead detail is 404; clinic/Super Admin calls to patient-only routes are denied; patient creation still works with consent and cross-clinic related IDs fail; old voucher issue route makes no ledger mutation. Deploy permissions before relying on the mobile guard. Roll back application changes without removing the patient permission; feature-disable lead/referral mutations if needed.

**الترحيل والتوافق والاختبار:** لا ترحيل بنيوي. طلب الضيف يُرفض، والدور غير المناسب يُرفض، وتبقى بيانات الطلبات القديمة دون ربط عشوائي. اختبر المريضين والعيادتين والمشرف، بما في ذلك تغيير المعرّفات. عند التراجع أبقِ حاجز الصلاحية أو عطّل العملية. لا تعِد القسائم أو الإدخال اليدوي للأكواد.

## B02 — Active clinic media ownership / ملكية الوسائط وحالة العيادة

**Classification/evidence:** Confirmed source weakness, High. `apps/media/permissions.py`: `CanUploadMedia:23` and `CanManageMediaAsset:100`; `apps/media/serializers.py`: `MediaUploadSerializer.validate:83`; `apps/media/views.py`: `MediaAssetListView.get_queryset:79` check active ClinicUser membership but omit clinic status/deletion. `apps/clinics/portal_permissions.py:get_user_clinic:8` already blocks suspended/rejected/deleted clinics. Thus suspension does not consistently revoke the media surface. Own-clinic membership checks exist; do not remove them.

**الدليل والأثر:** التحقق من عضوية المستخدم موجود، لكن حالة العيادة المحذوفة أو الموقوفة غير مطبقة بصورة موحدة على رفع الوسائط وقائمتها وإدارتها. قد تستمر هذه العمليات بعد الإيقاف رغم منعها في بوابة العيادة.

**Permission/code proposal:** use one explicit member queryset in upload permission, serializer resolution and validation, list queryset and object permission. Reject inactive/deleted accounts before Super Admin override. Decide whether pending clinics may upload setup media; the conservative default below allows ACTIVE only. If pending onboarding is required, authorize only that explicit setup operation; never include suspended/rejected/deleted states.

```python
from apps.accounts.models import ClinicUser
from apps.clinics.models import ClinicStatus

def active_media_memberships(user):
    if not (user and user.is_authenticated and user.is_active
            and user.deleted_at is None):
        return ClinicUser.objects.none()
    return ClinicUser.objects.filter(
        user=user,
        is_active=True,
        clinic__status=ClinicStatus.ACTIVE,
        clinic__deleted_at__isnull=True,
    )

# Upload permission/serializer after obtaining explicit target clinic_id:
# active_media_memberships(user).filter(clinic_id=target_clinic_id).exists()
# Clinic detail/delete object permission:
# active_media_memberships(user).filter(clinic_id=obj.clinic_id).exists()
# Clinic list:
# MediaAsset.objects.filter(clinic_id__in=
#     active_media_memberships(user).values_list("clinic_id", flat=True))
```

Preserve patient uploader/type restrictions, clinic_staff denial for ad media, VIP-only ad_video and explicit Super Admin permissions. Resolve missing clinic_id only from one permitted membership; reject ambiguity rather than silently choosing a clinic. Do not trust `_jwt_clinic_id` without the live membership check.

**Schema/compatibility:** no migration. Clarify pending-onboarding behavior before deployment so legitimate setup uploads are not unintentionally denied. Do not loosen status checks to fix a UI error.

**Tests/deploy/rollback:** A's assets cannot be listed/read/deleted/attached by B; suspension/deletion after token issuance immediately denies upload/list/detail/delete; role downgrade and staff video denial hold; patient avatar remains own-user only. Deploy all three layers together; rollback may disable media mutations while retaining account/clinic-state checks.

**التوافق والنشر والتراجع:** لا ترحيل. يجب حسم صلاحية رفع صور الإعداد للعيادة قيد المراجعة بشكل صريح. اختبر الإيقاف بعد إصدار JWT وتغيير الدور والعضوية، وليس تسجيل الدخول فقط. انشر المنطق الموحد في الصلاحيات والسيريالايزر والاستعلام، وعند التراجع لا تتجاوز فحص الحالة.

## B03 — Profile string-media bypass / تجاوز تحقق وسائط الملف

**Classification/evidence:** Confirmed source weakness, High. `apps/clinics/portal_serializers.py:ClinicProfilePortalSerializer.to_internal_value:26` pops string `logo`, `cover_image`, `video_ad_file`, calls `super()` without them, then reinserts strings. `validate_video_ad_file:57` is skipped for those strings. Splitting arbitrary strings on `/media/` also corrupts some CDN paths. This permits unvalidated references and VIP-video rule bypass. Merely storing a URL is **not** confirmed SSRF; no arbitrary fetch is established here.

**الدليل والأثر:** تُحذف القيم النصية للوسائط قبل التحقق ثم تعاد بعده؛ لذلك قد يُتجاوز التحقق من نوع الملف وملكيته وشرط VIP. تقطيع الرابط يضر بروابط CDN. تخزين رابط وحده لا يثبت SSRF.

**Code proposal:** remove that raw-string reinsertion. Keep the existing ImageField/FileField handling for direct multipart files and explicit null clears. Validate direct images with the shared media validator as well as DRF. An additive owned-UUID path can use the existing MediaAsset model; this does not require inventing a new storage schema. Example additions inside ClinicProfilePortalSerializer:

```python
from apps.media.models import MediaAsset, MediaType
from apps.media.validators import validate_media_file
from apps.clinics.models import SubscriptionTier

# Define these as write_only, required=False, allow_null=True fields,
# and include them in Meta.fields:
# logo_asset = serializers.PrimaryKeyRelatedField(queryset=MediaAsset.objects.all(), ...)
# cover_image_asset = serializers.PrimaryKeyRelatedField(queryset=MediaAsset.objects.all(), ...)
# video_ad_asset = serializers.PrimaryKeyRelatedField(queryset=MediaAsset.objects.all(), ...)

def validate_logo(self, value):
    if value is not None:
        _, mime, _, _ = validate_media_file(value)
        if not mime.startswith("image/"):
            raise serializers.ValidationError("An image is required.")
    return value

validate_cover_image = validate_logo

def validate(self, attrs):
    attrs = super().validate(attrs)
    clinic = self.instance  # ClinicProfileAPIView obtains this from live scope.
    bindings = (
        ("logo_asset", "logo", MediaType.CLINIC_LOGO, "image/"),
        ("cover_image_asset", "cover_image", MediaType.CLINIC_COVER, "image/"),
        ("video_ad_asset", "video_ad_file", MediaType.AD_VIDEO, "video/"),
    )
    for input_name, model_field, media_type, mime_prefix in bindings:
        if input_name not in attrs:
            continue
        asset = attrs.pop(input_name)
        if model_field in attrs:
            raise serializers.ValidationError({input_name: "Use one media input."})
        if asset is None:
            attrs[model_field] = None
            continue
        if (clinic is None or asset.clinic_id != clinic.pk
                or asset.media_type != media_type
                or not asset.mime_type.startswith(mime_prefix)
                or not asset.file.name):
            raise serializers.ValidationError({input_name: "Invalid media asset."})
        if model_field == "video_ad_file" and clinic.subscription_tier != SubscriptionTier.VIP:
            raise serializers.ValidationError({input_name: "VIP tier is required."})
        # Use the verified storage key, never a URL supplied by a caller.
        attrs[model_field] = asset.file.name
    return attrs
```

This example complements, rather than removes, the existing direct-file VIP/type validator. Asset validation must also guarantee that old/unprocessed assets satisfy the current deep-validation policy. Reuse the proven ScopedPortalImageMixin ownership semantics where suitable. Do not assign a storage name from an arbitrary client URL, strip signed query strings, or fetch client URLs to verify them.

**Schema/compatibility:** no schema migration for additional write-only UUID fields; storage key reference uses the existing MediaAsset file. Current Flutter profile upload uses direct multipart for selected files; catalog uploads use existing typed media_asset UUID plus URL. Coordinate legacy string clients: allow an unchanged existing field only if its exact serialized value is matched without assigning a new path, or use a narrowly scoped, owned-asset URL resolver during a dated transition. Do not accept arbitrary URL strings indefinitely. Keep response URLs stable and absolute; do not falsely acknowledge an unpersisted upload. Reference counting/orphan cleanup must not delete files still used by profiles.

**Tests/deploy/rollback:** basic clinic cannot attach video by file, UUID or string; VIP can attach its own valid video; cross-clinic or wrong-type assets fail; logo/cover file upload, unchanged existing media, omission and explicit removal all work; signed CDN paths remain intact; forged paths and external URL strings fail. Stage mobile/backward compatibility first. Roll back by disabling the new UUID input if necessary while retaining validation; never restore the raw-string bypass.

**الترحيل والتوافق والنشر:** لا ترحيل بنيوي للمقترح. احتفظ برفع الملفات المباشر، وأضف UUID موثوقاً عند الحاجة. نسّق التعامل مع العملاء القدامى؛ القيم القديمة غير المتغيرة يمكن دعمها بمطابقة دقيقة ومحدودة زمنياً دون إسناد مسار جديد. اختبر VIP وBasic وملكية الوسيط والحذف الصريح. لا تعِد تجاوز السيريالايزر عند التراجع.

## B04 — OTP/reset atomicity / ذرية OTP وإعادة التعيين

**Classification/evidence:** Confirmed source weakness, High. `apps/accounts/services/otp.py:OtpService.send_otp:116`, `verify_otp:212`, `get_reset_grant_key:323`, `consume_reset_grant:328`, `_increment_ip_attempts:340`. Read/set counters lose increments under concurrency; resend check/set is not one atomic acquisition. The password-reset fallback returns success even if another worker deleted the grant first. Grant keys expose phone and raw code. Existing HMAC OTP hashing, expiry, rate limits and normal OTP consume's checked delete are valuable controls and must stay.

**الدليل والأثر:** عدادات القراءة ثم الكتابة قد تفقد محاولات متزامنة، ومسار منحة إعادة التعيين لا يتحقق من نجاح الحذف الحصري. مفتاح المنحة يحتوي رقم الهاتف والكود. توجد ضوابط أساسية بالفعل؛ المطلوب جعلها ذرية وإزالة إعادة الاستخدام، لا استبدالها بمؤقت في Flutter.

**Preferred reset simplification:** Flutter's ResetPasswordScreen sends the original `otp_code`. Remove the grant fallback and grant creation entirely. The optional verify screen can validate the still-live OTP with `consume=False`; actual ResetPasswordView verifies that same OTP with `consume=True` and must win its single delete. Do not extend the original OTP lifetime on verification. Remove the now-unused grant helpers. In `verify_otp`, replace the `if not stored` block and success block with the following logic, retaining constant-time hash comparison and expiry checks between them:

```python
# Missing state: no legacy grant may turn this into success.
if not stored:
    OtpService._increment_ip_attempts(ip_key)  # replace with atomic counter below
    raise OtpExpiredError("No active OTP found. Please request a new one.")

# ... keep stored hash parsing, expiry and constant-time code comparison ...

if consume:
    if not cache.delete(otp_key):
        raise OtpExpiredError("No active OTP found. Please request a new one.")
    cache.delete(attempts_key)
    cache.delete(_locked_key(phone, purpose))
# consume=False does not create or refresh any grant.
return True
```

If future clients require a separate reset token, design a random, purpose/account-bound, short-lived, atomic one-time grant; do not use the six-digit OTP as a Redis key. Ensure OTP→grant transition and final consume cannot leave two independently reusable credentials.

**Atomic counter/resend proposal:** the configured cache is django-redis. A raw integer namespace avoids mixing pickled cache values with Redis arithmetic. The following counter is a building block for a fail-closed service; call it before verification and enforce the limit for every worker. Counting all verification attempts (including the two legitimate reset steps) requires documenting the policy and removing the old non-atomic increments. Keep phone and IP limits independently enforced. Redis Cluster would need an explicitly tested key-slot design.

```python
from django.core.cache import cache
from django.utils.crypto import salted_hmac

def private_key(scope, value):
    digest = salted_hmac("aw-security-v2", str(value), algorithm="sha256").hexdigest()
    return f"security:v2:{scope}:{digest}"

def atomic_attempt_count(key, ttl_seconds):
    client = cache.client.get_client(write=True)
    # This v2 namespace is owned by this Lua code, not cache.set serialization.
    script = """
    local n = redis.call('INCR', KEYS[1])
    if n == 1 then redis.call('EXPIRE', KEYS[1], ARGV[1]) end
    return n
    """
    return int(client.eval(script, 1, cache.make_key(key), ttl_seconds))

# In send_otp, acquire BEFORE generating/sending, remove the later lock overwrite:
# if not cache.add(private_key("resend", f"{phone}:{purpose}"), 1,
#                  timeout=OTP_RESEND_COOLDOWN):
#     raise OtpRateLimitError("Please wait before requesting another code.")
# On Redis failure fail closed; allow cooldown TTL to expire, never delete
# another worker's newly acquired lock on a late delivery failure.
```

`apps/accounts/views.py:_get_client_ip:50` trusts the first X-Forwarded-For entry. This is **potential deployment risk**, not a proven spoofable live limiter: verify trusted proxy overwrite and direct-origin access. Safer application default is `request.META.get("REMOTE_ADDR", "unknown")`; accept forwarded identities only from a configured trusted proxy that removes client-supplied headers. Align DRF proxy count and edge rules.

**Schema/compatibility:** no database migration for Redis-only changes. Version cache namespaces, let legacy grants expire, and refuse them; existing in-progress resets can request a new OTP. Do not flush unrelated Redis sessions/jobs. The supplied Flutter already sends otp_code; verify other clients before removing the grant path.

**Tests/deploy/rollback:** two workers consuming one OTP yield exactly one success; valid-then-consume reset cannot replay; failed phone/IP attempts do not lose increments; concurrent resend has one acquisition; Redis down fails closed; cooldown and expiry have bounded TTL; logs/keys contain no raw code or phone. Test trusted/untrusted proxy headers in staging. Deploy all OTP workers together or drain old workers; rollback must not reenable legacy grants, and can temporarily disable reset instead.

**الترحيل والاختبار والتراجع:** لا ترحيل لقاعدة البيانات. استخدم مساحة مفاتيح جديدة، ودع المنح القديمة تنتهي دون قبولها، واطلب كوداً جديداً عند الحاجة. اختبر تزامن عاملين وتوقف Redis وترويسات الوكيل. لا تمسح Redis كاملاً، ولا تعِد المنح القابلة لإعادة الاستخدام عند التراجع.

## B05 — Account state and JWT lifecycle / حالة الحساب ودورة JWT

**Classification/evidence:** Confirmed source weakness, High. `apps/accounts/views.py:VerifyOtpView:172` looks up a non-deleted user but omits is_active before `RefreshToken.for_user`. `RefreshView:471` uses the default refresh serializer from pinned SimpleJWT 5.3.1. Its advisory is CVE-2024-22513 / GHSA-5vcc-86wm-547q (fixed 5.5.1). Do not assume for_user authenticates the account. Protected JWT authentication normally rejects inactive users; this review did not demonstrate access to another account's data. Existing refresh rotation, blacklist and password-reset outstanding-refresh blacklisting must be retained.

**الدليل والأثر:** إصدار JWT عبر OTP لا يفحص نشاط الحساب صراحة، واعتمادية SimpleJWT مثبتة بإصدار ذي تنبيه متعلق بحالة المستخدم. هذا ضعف إصدار وتجديد، وليس دليلاً على تجاوز جميع فحوص الموارد المحمية. احتفظ بتدوير وتجريم رموز التجديد الموجودين.

**Code proposal:** check active/deleted state immediately before all issuance paths. Use a custom refresh serializer wired explicitly to the existing RefreshView, preserving its access_token/refresh_token response contract and custom claims. Example compatible structure to verify against the patched SimpleJWT version:

```python
from django.contrib.auth import get_user_model
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.settings import api_settings
from rest_framework_simplejwt.tokens import RefreshToken

class ActiveAccountRefreshSerializer(TokenRefreshSerializer):
    def validate(self, attrs):
        token = RefreshToken(attrs["refresh"])
        identity = token.get(api_settings.USER_ID_CLAIM)
        User = get_user_model()
        user = User.objects.filter(
            **{api_settings.USER_ID_FIELD: identity},
            is_active=True, deleted_at__isnull=True,
        ).first()
        if user is None:
            raise AuthenticationFailed("Unable to refresh this session.")
        return super().validate(attrs)  # keep rotation and blacklist behavior

# RefreshView.serializer_class = ActiveAccountRefreshSerializer
# VerifyOtpView must fetch is_active=True, deleted_at__isnull=True before issuing.
# Preserve _add_custom_claims, and do not mint a role based on request data.
```

Map nonexistent/inactive/deleted outcomes to the same safe auth failure; do not expose account state in public OTP/reset errors. In `LogoutView:499`, compare the parsed refresh token's user claim with request.user before blacklisting it; possessing another refresh token is already a serious prerequisite, so this is defense in depth, not proven arbitrary-user logout by ID.

The source has a 60-minute access lifetime and 30-day refresh lifetime. Agree a shorter access lifetime and a revocation model for suspension, password reset, role/membership change and suspicious sessions. The mobile client cannot revoke an offline token on the server. A per-user auth_version/auth_epoch claim checked on every protected request is one design; **it requires a new database field, default/backfill migration, issuance changes, cached-auth invalidation and a staged policy for old tokens**. Do not claim it exists today or set CHECK_REVOKE_TOKEN blindly on an older library. A supported password-revocation feature may cover password changes but not every role/clinic event.

**Schema/compatibility:** active checks and patched refresh serializer need no schema change. Optional auth-version design does. Preserve response keys and 401 handling used by Flutter; test rotated refresh tokens and custom clinic/role claims. Changing signing keys is not part of this proposal.

**Tests/deploy/rollback:** inactive/deleted users get no access/refresh token via password or OTP; existing refresh fails after deactivation; rotated refresh reuse fails; password reset revokes outstanding refresh tokens; test policy for already-issued access tokens explicitly. Verify mobile shared-refresh flow and offline logout. Deploy dependency fix first, then serializer and any migration via expand/contract. Rollback retains active checks/blacklist; optional version enforcement rollout must not unintentionally accept invalidated tokens.

**التوافق والنشر:** لا ترحيل لفحص النشاط، بينما حقل إصدار الجلسة الاختياري يحتاج ترحيلاً ونشراً تدريجياً. اختبر تعطيل الحساب وتغيير الدور وكلمة المرور وإعادة استخدام refresh، واختبر عمر access الحالي بوضوح. لا تغيّر مفاتيح التوقيع دون خطة منفصلة، ولا تجعل الرجوع يقبل رمزاً سبق إبطاله.

## B06 — Backend PII producers / مصادر البيانات الشخصية

**Classification/evidence:** Confirmed source weakness, Medium. `OtpService` logs phone/email/delivery exceptions at lines 184–204 and verification at 319. `_process_referral_invite` in `apps/accounts/views.py:248` logs invite token/code. `LeadCreateAPIView` notification/push and analytics at lines 120–181 include patient identity/reference/service context. `core/throttles.py:atomic_acquire_rate_lock:65` logs the complete lock key, and the caller builds it using patient/name/service values. The analytics model also has user/object linkage. No claim is made that these logs are publicly accessible.

**الدليل والأثر:** توجد بيانات شخصية أو معرّفات قابلة للربط في السجلات والتحليلات ونصوص الإشعارات. حتى السجل الداخلي يجب تقليل محتواه والتحكم في الوصول والاحتفاظ. لم نثبت إتاحة السجلات للعامة.

**Code proposal:** replace producer logs with static event codes and an independent random correlation ID; do not log raw exceptions or request bodies. Generate duplicate-lock keys with a keyed HMAC over the canonical identity, not raw phone/name. Keep a stable secret-backed HMAC context across workers; do not print its input. For analytics counts, the nullable existing schema permits removing patient and lead linkage:

```python
from django.utils.crypto import salted_hmac

def opaque_lead_lock(clinic_id, patient_id, lead_type, service_id):
    canonical = f"{clinic_id}|{patient_id}|{lead_type}|{service_id}"
    digest = salted_hmac("aw-lead-lock-v2", canonical, algorithm="sha256").hexdigest()
    return f"lead-lock:v2:{digest}"

logger.info("OTP_VERIFIED")
# Failure examples: logger.warning("OTP_DELIVERY_FAILED")
# Never append phone/email/code/token, str(exc), headers or request.data.

AnalyticsEvent.objects.create(
    event_type=EventType.LEAD_SUBMITTED,
    clinic=clinic,
    user=None,
    object_type="lead",
    object_id=None,
    metadata={"lead_type": lead.lead_type},  # fixed enum, no service/name/reference
)
```

Use generic clinic lockscreen push text. Even opaque lead IDs in external push payloads need a documented purpose; retrieve details only after authenticated authorization. Update both NotificationService templates and direct FCM calls, not just one string. Preserve the required patient confirmation `تم إرسال طلبك وستتواصل العيادة معك`.

Super Admin full contact detail is an existing readonly permission. The list can use a reduced serializer; keep detail access behind explicit Super Admin authorization/audit and an agreed necessity/retention policy. Do not silently change business authorization through mobile masking. Temporary credentials should expire quickly, require change on first use and never enter audit payloads/logs. Step-up/MFA rules for reset/suspension need a defined server workflow; Flutter concealment is not step-up.

**Schema/compatibility:** no schema change for minimized new events or static logs; user/object fields are nullable. Retention cleanup of historical logs/events is a separate owner-approved data operation with retention/legal requirements and backup policy. Verify analytics aggregations do not depend on removed service/reference/user metadata before deploy. HMAC key version changes may briefly reset duplicate locks; avoid overlap or use a short transition check.

**Tests/deploy/rollback:** captured logs and analytics payloads contain none of the synthetic patient's name/phone/email/notes/reference/invite/JWT/temporary password; notifications show generic text; dashboard totals still match. Deploy producer/template changes and check sink redaction/retention without extracting real records. Roll back analytics changes only with minimized metadata retained; never restore PII logs to debug an outage.

**الترحيل والاختبار والتراجع:** لا ترحيل بنيوي للحقول الحالية القابلة للقيمة الفارغة. تنظيف البيانات التاريخية عملية منفصلة بموافقة المالك وسياسة الاحتفاظ. اختبر عدم تسرب بيانات المريض الاصطناعي إلى السجلات والتحليلات والإشعارات. لا تعِد السجلات الحساسة عند التراجع أو التشخيص.

## B07 — Fail-closed media processing / معالجة الوسائط الآمنة

**Classification/evidence:** Confirmed source weakness, Medium. `apps/media/validators.py:get_video_duration:101` can return None; `validate_media_file:150`, video branch around 230, rejects only when duration is not None and over the limit. Thus missing ffprobe/unparseable duration can pass. Images use magic/type/size and Pillow verify, but no explicit maximum-pixel policy or canonical EXIF stripping is implemented. Random UUID storage paths and sanitization in MediaAsset are already present and should stay.

**الدليل والأثر:** الفيديو قد يمر عند تعذر معرفة مدته. تحقق الصور الحالي مفيد، لكنه لا يضمن إزالة بيانات EXIF ولا يحدد سياسة واضحة لعدد البكسلات أو معالجة المحتوى. اختيار requestFullMetadata=false في الهاتف لا يضمن إزالة EXIF من الملف.

**Code proposal:** reject unknown/nonfinite/nonpositive video duration; retain the existing upper bound and time-limited ffprobe. Constrain Pillow's decoder formats and pixels before decoding. Canonical re-encoding must happen before saving the actual output bytes and before computing final metadata, not merely during verification. Example validator fragments:

```python
import math
import warnings
from PIL import Image
from django.core.exceptions import ValidationError

# In the existing video branch:
duration = get_video_duration(file)
if duration is None or not math.isfinite(duration) or duration <= 0:
    raise ValidationError("Video duration could not be verified.")
if duration > MAX_VIDEO_DURATION_BUFFER_SECONDS:
    raise ValidationError("Video exceeds the allowed duration.")

# In the existing image branch, before verify()/decode; product-approved limit:
MAX_IMAGE_PIXELS = 20_000_000
with warnings.catch_warnings():
    warnings.simplefilter("error", Image.DecompressionBombWarning)
    file.seek(0)
    with Image.open(file, formats=("JPEG", "PNG", "WEBP")) as image:
        if image.width * image.height > MAX_IMAGE_PIXELS:
            raise ValidationError("Image dimensions exceed the allowed limit.")
        image.verify()
# Catch DecompressionBombWarning/Error and convert to safe validation failure;
# always seek(0) in finally. Keep the existing MIME/extension/magic cross-check.
```

Ali should implement a bounded canonicalization service: verified input → orientation-correct pixels → new ContentFile in an allowed format, omitting EXIF/GPS/comments and unneeded profiles → final size/dimensions/hash → random storage path. Do not copy original info/exif fields to the output. Restrict animation/frame count or flatten with an explicit product policy; bound decoding/processing time and memory. Patch Pillow first (B08). File verification is not malware certification.

**Permissions/storage/SSRF:** use B02/B03 for authorization. `MediaAsset.is_public` defaults false, but actual R2/S3 bucket ACL and URL signing/expiry were not verified; define public advertising media versus private patient media, use authorized short-lived private URLs and purge/retention policy. Confirm object response Content-Type, nosniff and separate CDN origin. `apps/clinics/services/google_places.py` targets a fixed Google host with timeout; no arbitrary URL fetch was found. Validate place IDs, disable unwanted cross-host redirects, keep egress restrictions and never proxy arbitrary caller URLs.

**Schema/compatibility:** no migration for duration/pixel validation. Canonicalization can use existing MediaAsset fields but needs an explicit treatment of old assets and URLs/cache invalidation; any processing-status field/new job schema requires its own migration. Do not rewrite all stored media or delete originals without a reviewed retention plan.

**Tests/deploy/rollback:** real valid JPEG/PNG/WebP and short MP4/WebM/MOV; disguised type, oversized file, truncated/huge-pixel image, ffprobe missing, nonfinite/unknown duration, too-long video, animation limits, metadata-containing sample after re-encode and expired private URL. Deploy ffprobe and resource limits before fail-closed validation. If processing fails, disable new uploads while keeping safe existing media; rollback must not accept unverified duration or arbitrary types.

**التوافق والنشر والتراجع:** لا ترحيل للتحقق وحده. أي حالة معالجة جديدة تحتاج ترحيلاً منفصلاً. جهّز ffprobe وحدود الموارد، واختبر ملفات حقيقية وملفات مشوهة وEXIF وانتهاء الرابط الخاص. لا تحذف أو تعِد كتابة الأصول القديمة عشوائياً، وعند الفشل عطّل الرفع الجديد بدلاً من قبول ملف غير متحقق.

## B08 — Advisory-affected backend pins / الاعتماديات المتأثرة

**Classification/evidence:** Confirmed pinned dependency advisory exposure, High priority; installed deployment and exploitability unverified. Public PyPI version metadata was queried for 26 exact pins in `requirements.txt`; affected entries and all returned GHSA aliases/fix lists are in [backend_dependency_advisories.json](security/backend_dependency_advisories.json). GHSA and PYSEC aliases of one CVE are not separate vulnerabilities. The separate OSV API was unavailable; do not imply it was independently queried successfully.

| Pin and source line | Representative advisory / relevance | Review candidate, not an approved pin |
|---|---|---|
| Django 5.2.4, line 8 | CVE-2025-57833 / GHSA-6w2r-r2m5-xq5w: FilteredRelation dictionary-alias SQL injection; no reachable attacker-controlled annotate kwargs demonstrated here. Other advisories are in snapshot. | Django 5.2.18 on existing LTS line; check all current advisories. Do not blindly move to latest major. |
| DRF 3.15.2, line 9 | CVE-2026-73228 / GHSA-2m8g-3cmr-wg3w: high-level request parsing body-limit bypass. CVE-2026-73229 also returned. Edge body limits remain needed. | 3.17.2; parser/serializer compatibility tests required. |
| SimpleJWT 5.3.1, line 13 | CVE-2024-22513 / GHSA-5vcc-86wm-547q: disabled-account validation. Directly relevant to token issuance/refresh B05. | 5.5.1; verify active-user and rotation behavior. |
| Pillow 11.0.0, line 38 | CVE-2026-25990 / GHSA-cfh3-3jmp-rvhc: crafted PSD decoding out-of-bounds write. Existing media magic allowlist reduces that path; other advisories and decoder paths still require review. | 12.3.0; major upgrade needs real media tests and Python/platform compatibility checks. |
| pytest 8.3.4, line 51 | CVE-2025-71176 / GHSA-6w46-j5rx-g56g: local UNIX temp directory issue. Build/test risk; not automatically a production runtime dependency exploit. | 9.0.3 or another currently fixed supported release with plugin checks. |

**الدليل والأثر:** إصدارات مثبّتة لها تنبيهات منشورة في فهرس الحزم. هذا يؤكد مشكلة التثبيت في المصدر، ولا يؤكد أن نفس الإصدارات منشورة أو أن كل مسار استغلال متاح. الإصدارات المقترحة مرشحة للمراجعة وليست أمراً بترقية كبرى دون اختبار.

**Code/config proposal:** update requirements only in Ali's backend branch after verifying supported Python and patch status; resolve a reproducible lock and scan the deployed image. The following test is a server-code guard alongside dependency updates, not a substitute for them:

```python
from rest_framework.test import APIClient

def test_inactive_user_cannot_refresh(active_user, refresh_for_user):
    token = refresh_for_user(active_user)
    active_user.is_active = False
    active_user.save(update_fields=["is_active"])
    response = APIClient().post(
        "/api/v1/auth/refresh/", {"refresh": str(token)}, format="json"
    )
    assert response.status_code == 401
# active_user / refresh_for_user are proposed isolated backend fixtures.
# Add parser body-limit tests locally against a bounded test server and real
# decoder regressions; never send oversized attack payloads to production.
```

**Schema/compatibility:** dependency changes alone normally need no application model migration, but run `makemigrations --check --dry-run`, migration plan/checks, dependency health checks and full tests; auth blacklist package migrations may differ between versions. DRF parsing and Pillow format changes require explicit backward-compatibility checks for mobile JSON/multipart and valid old media. Test plugins with pytest major upgrades.

**Deployment/rollback:** build an immutable dependency-locked image, scan it, run Django deploy checks with secrets kept out of output, smoke-test staging five-role auth/media flows, then deploy with monitoring and a known fixed rollback artifact. Do not roll back to advisory-affected libraries to restore an unsafe path; disable the affected feature or use an earlier independently patched artifact. Verify actual installed versions after deployment. No production dependency was changed in this review.

**الاختبار والنشر والتراجع:** أنشئ حزمة ثابتة الاعتماديات، واختبر الترحيلات وصلاحيات الأدوار ورفع الملفات وصيغ الصور والتوافق مع الهاتف، ثم تحقق من الإصدارات المثبتة فعلياً. لا ترجع لإصدار معروف التأثر؛ استخدم حزمة مصححة أو عطّل المسار المتأثر. لم نعدّل اعتماديات الباك إند.

## Additional verification and product decisions / تحقق إضافي وقرارات المنتج

- **BOLA staging sign-off:** create synthetic Patient A/B, Clinic A/B and Super Admin. Execute every positive and negative row in the matrix by direct authenticated API requests. Record only status, route template and synthetic object label, not credentials/contact data. Do not enumerate production IDs.
- **Idempotency:** consultation uses a short distributed lock plus duplicate query, while offer/product inquiries are excluded. Define durable patient/action-scoped idempotency for all lead types and high-risk writes; the database unique key and response replay design need an explicit migration and transaction test. Do not pretend an unimplemented client header enforces it.
- **Privileged writes:** retain IsSuperAdmin on provisioning, suspension, reset and moderation. Define expiry/forced change/audited authorization, optional step-up/MFA and idempotency server-side. Ordinary clinic routes should not silently select the first clinic for global Admin writes; require explicit authorized target on a dedicated Admin contract. This is an ownership ambiguity to confirm, not proven privilege escalation.
- **Production edge:** verify trusted proxy handling, direct-origin access, TLS redirects, CORS, body limits, secure cookies, private storage and request-log redaction. Source production settings already contain DEBUG false/HSTS/TLS/secure cookies; this review did not inspect live values.
- **Dependency/native boundary:** Flutter metadata check reported no current advisories for 117 resolved Dart packages, but native Gradle/CocoaPods/transitive image/video libraries were not independently scanned. Release build/device verification remains necessary.
- **Rollout contract:** preserve mobile error shapes, media URL signatures, existing lead ownership, readonly supervision, exact Arabic lead confirmation, native uploads and product showcase rules. No prices/cart/checkout/calendar/manual coupons/regulatory UI.

**التحقق النهائي:** نفّذ مصفوفة الصلاحيات بحسابات اصطناعية مصرح بها، ودوّن النتائج دون بيانات شخصية أو أسرار. حسم idempotency وMFA وتقليل بيانات المشرف وACL الوسائط قرارات خادم/منتج؛ لا تُحاكى بإخفاء زر في Flutter. يحتفظ التطبيق بتصميمه وقواعده، ولا يُعد هذا التقرير شهادة أمان أو بديلاً لاختبار اختراق مستقل بعد نشر إصلاحات علي.
