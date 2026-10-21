# Patient Portal backend handoff — تسليم تعديلات الخادم لعلي

2026-10-20. **Reference review, not deployment verification / مراجعة نسخة مرجعية وليست تحققاً من الخادم المنشور.**

No Django files were edited. Evidence is the supplied `backend_latest.zip` reference, extracted outside Flutter. The deployed API version, authenticated uploads, production database, Places credentials/worker and CDN delivery were not verified. The older audit handoffs are proposals, not evidence that their changes are deployed.

لم يتم تعديل أي ملف Django. الأدلة مأخوذة من النسخة المرجعية المرفقة. لا تعني هذه المراجعة أن الخادم الحي يطابقها، ولم يتم فحص بيانات المرضى أو إجراء تعديلات إنتاجية.

## 1. Home metadata and media differ from the clinic directory — اختلاف بيانات الصفحة الرئيسية

**Evidence:** `apps/home/serializers.py:15` (`PublicClinicSerializer`) omits `google_reviews_count`, `google_place_id`, `google_maps_url`, and the clinic's `subscription_tier`. It uses raw ImageFields, unlike `apps/clinics/serializers.py:32` (`PublicClinicListSerializer.to_representation`) which calls `resolve_media_url`. `HomeFeedAPIView` instantiates serializers without request context and caches the resulting response. Nested `FeaturedAdSerializer.clinic` uses the same reduced serializer. Home offers omit their real `image_url`, although `Offer.image_url` is available to the public offer serializer.

**Endpoints:** GET `/api/v1/home/feed/`, `/home/nearby-clinics/`, `/home/featured-ads/`, `/home/offers/`.

**Effect:** Home cannot consistently show the actual review count or link the Google badge, distinguish the clinic's package, or show an offer banner. A raw ImageField can produce a mangled URL for legacy absolute URL names. Flutter preserves absent data and does not substitute legacy ratings. An ad's paid placement tier is now separate from the clinic subscription tier; the frontend never overwrites the clinic's tier with an ad tier.

**التأثير:** بيانات تقييم Google وروابط الخرائط والصور تختلف بين الرئيسية والدليل. لا ينبغي تعويضها بقيم افتراضية أو اعتبار باقة الإعلان باقةً للعيادة.

**Proposed code in existing classes (no new endpoint):**

```python
# apps/home/serializers.py
from apps.clinics.serializers import PublicClinicListSerializer
from apps.media.utils import resolve_media_url

class PublicClinicSerializer(PublicClinicListSerializer):
    class Meta(PublicClinicListSerializer.Meta):
        fields = list(dict.fromkeys([
            *PublicClinicListSerializer.Meta.fields,
            "google_place_id",
        ]))
        read_only_fields = fields

# Keep FeaturedAdSerializer.clinic = PublicClinicSerializer(read_only=True).
# Keep the AD's subscription_tier on FeaturedAdSerializer; do not derive it
# from is_featured or overwrite the nested clinic.subscription_tier.

# Add to the EXISTING OfferSerializer class:
image_url = serializers.SerializerMethodField()
def get_image_url(self, obj):
    return resolve_media_url(obj.image_url, self.context.get("request"))
# Append "image_url" to OfferSerializer.Meta.fields.
```

In `HomeFeedAPIView.get`, pass `context={"request": request}` to each serializer; do likewise for direct `FeaturedAdSerializer` calls. Public list views normally supply context automatically. Check cache keys/TTL before changing context: never cache user-dependent URLs or signed URLs beyond their expiration. Purge/version existing home cache on deploy. No database migration is needed. Only already-public fields are added; do not expose moderation, credentials or regulatory fields.

**Tests / الاختبارات:** same stored clinic has identical Google/media values in home, list and detail; no ratings gives null/zero count without invented stars; custom CDN absolute names round-trip; absent banner stays absent; paid ad tier and clinic tier can differ without either being overwritten; disabled/deleted clinics excluded; cache refresh after a profile/catalog change.

## 2. Profile string-media normalization can destroy a valid external URL — تشويه رابط صورة خارجي صحيح

**Evidence:** `apps/clinics/portal_serializers.py:25`, `ClinicProfilePortalSerializer.to_internal_value`, strips everything through `/media/` from any non-`https://pub-...` string. Thus the synthetic URL `https://cdn.example/media/logo.png?signature=fixture` becomes `logo.png?signature=fixture`. This loses the origin and can turn signed query text into a storage key. `apps/media/utils.py:resolve_media_url` already knows how to preserve an absolute `FieldFile.name`, so destructive stripping is unnecessary. Ordinary binary multipart uploads do not exercise this string branch.

**Endpoint:** PATCH `/api/v1/clinic-portal/profile/`; fields `logo`, `cover_image`, `video_ad_file`. Flutter uses multipart for normal local replacements, and pre-upload + JSON for mixed replacement/removal. Catalog pre-uploads still use real `media_asset` UUIDs plus the returned media URL.

**العلة:** التحويل النصي يحذف نطاق CDN من بعض الروابط الموقعة. نجاح حفظ النص لا يثبت حفظ الصورة أو صلاحية الرابط بعد إعادة التحميل.

**Minimal compatibility correction inside the existing loop:**

```python
from django.core.validators import URLValidator
from django.core.exceptions import ValidationError as DjangoValidationError

# After clean_media_url(raw_val), replace the broad '/media/' split:
if raw_val.startswith(("https://", "http://")):
    try:
        URLValidator(schemes=["https"])(raw_val)
    except DjangoValidationError:
        raise serializers.ValidationError({field: "A valid HTTPS media URL is required."})
    string_media[field] = raw_val  # Preserve encoded path/query verbatim.
elif raw_val.startswith("/media/"):
    string_media[field] = raw_val[len("/media/"):]
else:
    string_media[field] = raw_val
```

Ali must retain the existing binary upload validation and explicitly enforce **VIP eligibility for string video updates too**: popping a string before `super().to_internal_value` bypasses field validators. Validate asset ownership/media type for pre-uploaded assets; never accept another clinic's asset just because its URL is valid. For new writes prefer durable owned storage references and generate signed delivery URLs at serialization time; do not migrate existing absolute values by blind string replacement. A relative storage name containing signature query text needs a reviewed repair, not a global data rewrite.

**Tests:** multipart JPEG/PNG save and subsequent GET; mixed logo replace + cover null; absolute custom CDN including `/media/`; signed query remains byte-for-byte; empty removal; omitted field preserved; wrong clinic asset denied; non-VIP string/binary video denied; valid owned VIP video allowed. Confirm actual storage access after logout/restart and after signature expiry. No broad migration is required for the minimal patch; inspect affected rows before any targeted repair.

## 3. Retire referral reward-code mutations — إيقاف عمليات أكواد الخصم

**Evidence:** `apps/referrals/views/patient_views.py`, `CollectCodeAPIView`, still debits 500 points and issues a discount code. `ReferralStatusAPIView` uses only `IsAuthenticated` and can create a PatientProfile for other roles. `apps/referrals/views/clinic_views.py`, `VerifyDiscountCodeAPIView` and `RedeemDiscountCodeAPIView`, retain legacy operations. Routes exist in `apps/referrals/urls.py` and `urls_clinic.py`.

**Endpoints:** POST `/api/v1/referral/collect-code/`, `/clinic-portal/discount-codes/verify/`, `/clinic-portal/discount-codes/redeem/`; GET `/referral/my-status/`.

**Frontend:** no issuance, verification or redemption requests remain. Disabled compatibility methods cannot debit points or call these routes. Legacy response DTO parsing is retained internally only. Copy/share accepts an authentic returned `https://aestheticway.ae/invite/{token}`; no hardcoded personal link is manufactured.

**المطلوب:** إبقاء رابط الدعوة والنقاط ومراحل 20/35/50 فقط؛ إيقاف إصدار الأكواد والتحقق منها واستبدالها، دون حذف سجلات التدقيق القديمة أو إعادة حساب الأرصدة من العميل.

```python
# In the existing patient views module:
from core.permissions.roles import IsPatient
from rest_framework import status
from rest_framework.response import Response

# ReferralStatusAPIView:
permission_classes = [IsAuthenticated, IsPatient]

# Replace CollectCodeAPIView.post BEFORE any ledger operation:
def post(self, request, *args, **kwargs):
    return Response({"detail": "This reward operation has been retired."},
                    status=status.HTTP_410_GONE)

# Apply the same 410 body at the beginning of the existing VerifyDiscountCodeAPIView
# and RedeemDiscountCodeAPIView post methods. Retain their authentication and clinic
# scope checks; a patient must not gain access to clinic operations.
```

Keep the read status shape compatible initially; then deprecate `discount_codes`, `can_collect_code`, `points_to_collect` in a versioned change. Keep genuine `current_points`, successful invitation counts, and milestone flags. `apps/referrals/services.py` currently awards 10 per qualified referral plus milestone bonuses 100/175/250 at 20/35/50. Flutter displays the ledger balance rather than recomputing it from counts. `PatientProfile.invite_link` in `apps/accounts/models.py` already implements the unified URL. Verify environment link configuration without changing tokens or referral attribution.

**Tests:** all mutation routes return 410 with no ledger writes, notifications or code creation; patient status excludes other roles; qualified attribution idempotent; links resolve to the same inviter; expired/invalid token rejected; concurrent referral completion awards once. No destructive ledger migration. Deploy frontend retirement first, backend 410 next, response deprecation later.

## 4. Patient-only lead authorization — عزل صلاحيات طلبات المرضى

**Evidence:** `apps/leads/views/patient_views.py:LeadCreateAPIView.permission_classes=[AllowAny]` explicitly permits guest leads. `MyLeadsAPIView.get_queryset` allows `SUPER_ADMIN` as well as `PATIENT`. This conflicts with the no-guest, isolated patient workflow. Flutter guards consultation actions by patient role and checks role/session before submission and completion, but server authorization must be authoritative.

```python
from core.permissions.roles import IsPatient
# Existing LeadCreateAPIView, MyLeadsAPIView, MyLeadsCountAPIView and
# MyLeadDetailAPIView: apply to all four existing classes:
permission_classes = [IsAuthenticated, IsPatient]
# Keep patient=request.user and queryset patient=request.user.
# Keep Super Admin supervision on the EXISTING admin leads endpoint.
```

Do not remove `PatientLeadCreateSerializer` ownership validation. A `branch`, `practitioner`, `treatment`, `offer` or clinic-associated `product` must belong to the selected active clinic. Keep offer validity and treatment/practitioner assignment checks. General brand-product inquiries legitimately allow `clinic=null` when the actual product has no clinic. Do not assign an arbitrary clinic to those leads. Ali should define operational handling/notification of those existing unassigned product leads; source notifications currently target clinic staff only when `lead.clinic` exists.

**الاختبارات:** ضيف 401، أدوار العيادة والإدارة 403، مريض صحيح 201، ربط كيان من عيادة أخرى 400، عرض منتهٍ 400، منتج مستقل بلا عيادة يُحفظ دون عيادة وهمية، نجاح لا يُعاد قبل الحفظ. Preserve duplicate throttling and its 429 response. No schema migration needed; deploy with the already-authenticated Flutter workflow.

## 5. Stable pagination, category matching and geo validation — ثبات الصفحات والفلاتر

**Evidence:** category ordering is `display_order,name_en` without unique tie-breaker in `CategoryListAPIView`; treatments use `ordering=["name_en"]`; clinic ordering ends at `name_en`; home ads end at `-created_at`. Identical values can reorder across page boundaries. Clinic search covers names/descriptions/city/emirate, not area/address/specialty. Clinic category UUID filtering exists and is reused; product categories are not treatment categories. Geo views float-convert coordinates without finite/range validation; the SQLite approximation is squared degrees, not kilometers.

**Frontend:** 20/page and 350ms debounce are preserved; filter changes invalidate old requests immediately and clear stale records. Home search navigates to the server-wide directory, rather than filtering a ten-record feed. No proximity or distance claims are made without consented coordinates.

```python
# Existing list querysets/orderings: append a unique PK, retaining current priorities.
# ClinicListAPIView.get_queryset:
order_by_args.append("pk")
# TreatmentListAPIView:
ordering = ["name_en", "pk"]
# CategoryListAPIView.get_queryset:
return Category.objects.filter(is_active=True).order_by("display_order", "name_en", "pk")
# Existing home query helpers: append "pk" to each canonical order_by.
```

For supplied coordinates, validate the pair before annotating:

```python
import math
from rest_framework.exceptions import ValidationError

def validated_coordinates(lat, lng):
    if lat is None and lng is None:
        return None
    try:
        a, b = float(lat), float(lng)
    except (TypeError, ValueError):
        raise ValidationError({"location": "Both coordinates are required."})
    if not (math.isfinite(a) and math.isfinite(b) and -90 <= a <= 90 and -180 <= b <= 180):
        raise ValidationError({"location": "Invalid coordinates."})
    return a, b
```

Use documented distance units for any future geo response; never relabel the development approximation as km. Validate clinic/branch stored coordinate pairs independently. Do not claim nearby behavior merely from a city filter.

**Tests:** >40 matching records with identical names/orders paginate without missing IDs; Arabic and English city/category search; nonmatches remain empty; stale request cannot replace a changed filter; invalid/partial/NaN coordinates 400; lat/lng zero singly is valid, (0,0) is unavailable for this app's stored clinic destination. No migration for ordering. Add indexes only after query-plan measurement.

## 6. Catalog content, optional fields and Google operations — المحتوى وحقول Google الاختيارية

These are **source-data/deployment checks**, not invented client fixes:

- `TreatmentListAPIView` correctly filters `is_active=True`, `status=active`, not deleted, active/nondeleted clinic and active category. Empty screenshots do not prove a parser bug. Ali must inspect which predicate excludes intended records. Do not publish drafts or fabricate treatments to populate the app.
- Current `PublicTreatment*Serializer` has no treatment image/duration/downtime fields. If those become supported, add actual model/storage fields, an explicit migration, clinic-owned upload validation, matching portal serializer and public read serializer. Existing fallback is honest until then. A proposed new field is not a deployed API.
- Clinic public serializers have no working hours or verified-clinic flag backed by the current Clinic model. Flutter omits those assertions; either keep them absent or define a reviewed field/schema/migration and moderation policy before adding UI. Source addresses/map fields must be supplied by the clinic, never defaulted to Dubai.
- `PublicProductSerializer` **already includes** localized brand names and `sponsor_company`, and the public queryset **already supports** clinic-null products. Missing catalog values are content completeness problems. Independent Super Admin write gaps remain covered by `SUPER_ADMIN_BACKEND_GAPS_FOR_ALI.md`; do not repurpose clinic-scoped writes.
- `apps/clinics/services/google_places.py` and `tasks.py` **already implement** Places New caching. Do not rebuild this integration or call Google on patient page loads. Ali must verify key restrictions, configuration, scheduled worker execution, authentic Place IDs and `google_last_synced_at/google_sync_status` in the deployment. The service must reject nonfinite ratings and noninteger counts (currently float values can be truncated); preserve the last valid cache on failures.
- Existing clinic review endpoints return placeholder success/empty records. Patient UI uses Google only and does not invoke them. Retire writes or return an explicit unsupported response; never acknowledge a review that was not saved.

**فصل المسؤوليات:** أسماء/أوصاف CMS التجريبية أو الناقصة تحتاج مراجعة تحريرية. الواجهة لا تختلق اختصاصاً أو مؤهلاً أو سيرة ولا تعيد كتابة النص الطبي تلقائياً. لا تُضاف ساعات عمل أو علامة توثيق إلا من مصدر معتمد.

**Tests:** publication matrix; exact category UUID and practitioner relations; translated values absent/present; actual brand fields retained; no product price in patient response after a compatible deprecation plan; Google 401/403/404/429/5xx preserves cache; NaN/infinity/fractional/negative count rejected; no synthetic “new listing” state; no patient request triggers Places fetch.

## Deployment sequence — ترتيب النشر الآمن

1. Preserve a reviewed deployment/DB backup and run backend tests on a staging copy. No production records in diagnostics.
2. Deploy the safe Flutter behavior and then patient authorization/referral retirement. Verify supported authenticated clients first; announce the retired reward workflow.
3. Apply source-preserving media normalization and Home serializer/context fixes; clear affected Home cache. Verify real upload → GET → restart → decoded image on staging.
4. Apply stable ordering and coordinate validation; test multiple pages and both languages.
5. Verify Google worker/configuration and curate clinic/catalog data. Optional model fields require separate reviewed migrations and matched public/portal contracts.
6. Deploy backward-compatible API reads before activating new frontend capabilities. Keep historical ledgers and assets intact. Verify separate Patient, Clinic and Admin accounts with dedicated staging fixtures.

No Django implementation in this handoff was applied or tested against the production server. Ali owns implementation, migrations, credentials and deployment.

علي مسؤول عن التنفيذ والاختبارات والترحيلات والنشر. أمثلة Python أعلاه مبنية على الأصناف الموجودة، لكنها ليست ادعاءً بأنها نُفذت أو نُشرت.
