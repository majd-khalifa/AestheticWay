# Super Admin — verified backend gaps for Ali / نواقص الباك اند للمشرف العام

Date / التاريخ: 20 October 2026. Frontend branch: `codex/super-admin-production-hardening`.

**Scope / النطاق:** This is a deployment handoff, not a claim that Django has been changed. Both backend references remain read-only. Findings below are verified against `/workspace/work/backend-latest-reference` (`backend_latest.zip`, 636 files); the original 622-file reference is also preserved. The archive is evidence of source contracts, not proof of the current live deployment. No live Super Admin JWT was supplied.

هذه تعليمات تسليم لعلي، وليست تعديلات مطبقة على Django. لم نغيّر ملفات الباك اند أو الترحيلات أو إعدادات النشر. يجب مراجعة الأمثلة ودمجها واختبارها في بيئة تجريبية قبل النشر.

## 1. Admin location writes are missing / غياب حفظ إحداثيات الموقع

**Current frontend / فلاتر حالياً:** Clinic details resolve genuine clinic coordinates, then valid active/main branch data, or a recognized stored Google Maps link. Missing/invalid location disables Maps. Creation/editing saves supported city/address fields. It does **not** submit ignored coordinates or claim that a new pin was saved. Pin editing is visibly unavailable until this contract is implemented.

**Verified Django / المثبت بالمصدر:**

- `apps/admin_portal/serializers.py::AdminClinicDetailSerializer` returns `latitude`, `longitude`, `google_maps_url`.
- `AdminClinicProvisionSerializer` and `AdminClinicUpdateSerializer` omit those write fields.
- `AdminClinicBranchSummarySerializer` omits branch coordinates/maps URLs.
- `apps/admin_portal/services/clinic_provisioning.py::ClinicProvisioningService.provision_clinic` does not save coordinates on the clinic or its newly created main branch.
- Existing `Clinic`/`ClinicBranch` fields are nullable `DecimalField(max_digits=10, decimal_places=7)`; Clinic Maps URL is length 500. No new location model is needed.

**Endpoints / المسارات:** `POST /api/v1/admin/clinics/`, `PATCH /api/v1/admin/clinics/{id}/`, and their GET representations.

**Required behavior / المطلوب:** A user-confirmed map selection writes both coordinates and a canonical Google Maps URL atomically. Omitted location preserves existing values. Explicit paired nulls remove the location. Partial pairs, nonfinite/out-of-range coordinates and `(0,0)` must fail. Only existing `IsAuthenticated, IsSuperAdmin` permissions may authorize these admin writes.

### Serializer implementation / تطبيق السيريالايزر

Add this class in `apps/admin_portal/serializers.py`, using its existing `serializers` import:

```python
from decimal import Decimal

class AdminLocationInputMixin(serializers.Serializer):
    latitude = serializers.DecimalField(
        max_digits=10, decimal_places=7, required=False, allow_null=True,
        min_value=Decimal("-90"), max_value=Decimal("90"),
    )
    longitude = serializers.DecimalField(
        max_digits=10, decimal_places=7, required=False, allow_null=True,
        min_value=Decimal("-180"), max_value=Decimal("180"),
    )
    google_maps_url = serializers.URLField(
        max_length=500, required=False, allow_blank=True,
    )

    def validate(self, attrs):
        attrs = super().validate(attrs)
        has_lat = "latitude" in attrs
        has_lng = "longitude" in attrs
        if has_lat != has_lng:
            raise serializers.ValidationError(
                {"latitude": "Send latitude and longitude together."}
            )
        if not has_lat:
            if "google_maps_url" in attrs:
                raise serializers.ValidationError(
                    {"google_maps_url": "Send coordinates with a location change."}
                )
            return attrs
        lat, lng = attrs["latitude"], attrs["longitude"]
        if (lat is None) != (lng is None):
            raise serializers.ValidationError(
                {"latitude": "Both coordinates must be set or cleared together."}
            )
        if lat is None:
            attrs["google_maps_url"] = ""
        elif lat == 0 and lng == 0:
            raise serializers.ValidationError(
                {"latitude": "Choose the clinic's actual map position."}
            )
        else:
            # DecimalField already rejects NaN, infinity and range violations.
            attrs["google_maps_url"] = (
                "https://www.google.com/maps/search/?api=1&query="
                f"{lat},{lng}"
            )
        return attrs
```

Change the **existing** class bases, keeping their current fields, nested-admin normalization, media handling and validation:

```diff
-class AdminClinicProvisionSerializer(serializers.Serializer):
+class AdminClinicProvisionSerializer(AdminLocationInputMixin, serializers.Serializer):

-class AdminClinicUpdateSerializer(serializers.ModelSerializer):
+class AdminClinicUpdateSerializer(AdminLocationInputMixin, serializers.ModelSerializer):
```

These are class-header changes, not replacement serializers. In `AdminClinicUpdateSerializer.Meta.fields`, append `"latitude", "longitude", "google_maps_url"`. In `AdminClinicBranchSummarySerializer.Meta.fields`, append the same three fields. If additional serializer `validate()` methods exist in the deployment, they must call `super().validate(attrs)` so the mixin is not bypassed.

هذه تغييرات على تعريف الأصناف الحالية مع الاحتفاظ بجميع الحقول والمنطق الموجود. لا تستبدل جسم السيريالايزر بـ `pass`؛ أضف الحقول إلى `Meta.fields` واستدعِ تحقق الـ mixin.

### Provisioning service / خدمة إنشاء العيادة

Immediately before the existing `Clinic.objects.create(...)` call in `ClinicProvisioningService.provision_clinic`, define:

```python
# Define before Clinic.objects.create(...); pass **location_kwargs inside it:
location_kwargs = {
    "latitude": data.get("latitude"),
    "longitude": data.get("longitude"),
    "google_maps_url": data.get("google_maps_url", ""),
}
```

Apply `**location_kwargs` to that existing call. Inside the immediately following `ClinicBranch.objects.create(...)`, add `latitude=clinic.latitude`, `longitude=clinic.longitude`, and `google_maps_url=clinic.google_maps_url`. Keep clinic/user/membership/branch creation inside the existing atomic transaction.

PATCH already calls `serializer.save()` in `AdminClinicViewSet.partial_update`; the added ModelSerializer fields persist there without a new endpoint. Do not overwrite the locations of intentionally distinct branches automatically. Decide and test a separate explicit main-branch synchronization policy if the product requires one. Expose branch locations on GET so Flutter can distinguish clinic and branch geography.

**Compatibility / التوافق:** Existing clients omit these keys and retain their behavior. No migration is needed for these existing fields. Reject invalid writes rather than accepting and ignoring them.

**Validation / الاختبار:** Test create/PATCH with valid decimals (JSON and multipart), one missing coordinate, null pair, out-of-range values, NaN, `(0,0)`, and omission. Verify the new clinic and main branch share the confirmed position on creation. Verify patient/clinic-admin requests get 401/403 and cannot alter official clinic contact/location through admin routes.

**Ali → Flutter follow-up / خطوة فلاتر بعد النشر:** Once Ali deploys and proves this contract, wire `AdminClinicEditor` to the existing `showClinicLocationSelector` and send `latitude`, `longitude` rounded to 7 decimal places and `google_maps_url` from the confirmed selection. The current frontend intentionally leaves these writes disabled; it cannot infer deployment support from the presence of read-only fields. No unsupported location request has been shipped.

## 2. Moderation responses omit the real state / غياب حالة المراجعة في الرد

**Current frontend / فلاتر حالياً:** An all-status record without `status` is labeled “Status unavailable,” rather than falsely Active/Published. A server status-filtered response has a known status because the queryset applies that exact filter. Explicit Approve/Suspend actions remain usable through the verified POST endpoints. Pending writes disable duplicate actions; only a matching `new_status` acknowledgement updates the current view. Failure retains the prior state. An unfiltered refresh can return Unknown again until this serializer gap is deployed.

**Verified Django:** `AdminOfferModerationViewSet`, `AdminProductModerationViewSet`, and `AdminArticleModerationViewSet` reuse `PublicOfferSerializer`, `PublicProductSerializer`, and `PublicArticleDetailSerializer`. These deliberately exclude moderation status. The admin queryset includes all statuses, so the frontend cannot reconstruct status from price, `published_at`, an image, or an omitted boolean.

**Endpoints:** GET `admin/offers/`, `admin/products/`, `admin/articles/` and `{id}/`; POST `{id}/approve/`, `{id}/suspend/`, `{id}/restore/`, `{id}/reject/` already return `new_status` correctly.

### Private inspection serializers / سيريالايزرات إدارية خاصة

Add to `apps/admin_portal/serializers.py`:

```python
from apps.offers.serializers import PublicOfferSerializer
from apps.products.serializers import PublicProductSerializer
from apps.articles.serializers import PublicArticleDetailSerializer


class AdminOfferInspectionSerializer(PublicOfferSerializer):
    class Meta(PublicOfferSerializer.Meta):
        fields = list(PublicOfferSerializer.Meta.fields) + ["status", "is_active"]
        read_only_fields = fields


class AdminProductInspectionSerializer(PublicProductSerializer):
    class Meta(PublicProductSerializer.Meta):
        # Showcase moderation has no price contract.
        fields = [f for f in PublicProductSerializer.Meta.fields if f != "price"] + [
            "status", "is_active"
        ]
        read_only_fields = fields


class AdminArticleInspectionSerializer(PublicArticleDetailSerializer):
    class Meta(PublicArticleDetailSerializer.Meta):
        fields = list(PublicArticleDetailSerializer.Meta.fields) + ["status"]
        read_only_fields = fields
```

Import these classes in `apps/admin_portal/views.py`. Replace the existing `get_serializer_class()` return in each of the three real viewsets:

```python
# Inside AdminOfferModerationViewSet:
def get_serializer_class(self):
    return AdminOfferInspectionSerializer


# Inside AdminProductModerationViewSet:
def get_serializer_class(self):
    return AdminProductInspectionSerializer


# Inside AdminArticleModerationViewSet:
def get_serializer_class(self):
    return AdminArticleInspectionSerializer
```

Changing `serializer_class` alone is insufficient: the existing overrides explicitly return the public classes. Keep public endpoints unchanged; do not expose private moderation state globally. No migration is required.

**Compatibility / التوافق:** This adds fields only to protected admin responses. The Flutter parser already accepts them. Legacy product price values stay internal to compatibility parsing and are never rendered or sent in showcase updates. If public API price removal affects other clients, coordinate that as a separate API-version decision.

**Tests / الاختبارات:** For each content type, create Active/Pending/Suspended/Rejected rows. Check list/detail status, every filter, approve/suspend/restore/reject persistence and fresh-client reload. Verify no price in the private product response. Verify 401/403 for unauthorized roles, and no status mutation endpoint for admin Leads.

## 3. Search and stable pagination / البحث وترتيب الصفحات

**Verified problem:** The latest `BaseContentModerationViewSet.get_queryset()` searches `name_en/name_ar` for every model. `Offer` and `Article` have `title_en/title_ar`; a nonempty search can raise Django `FieldError`. Product search works for product/brand/sponsor names, but excludes clinic attribution. The original archive lacks moderation search entirely. Clinic/Lead/Moderation orderings do not consistently include a unique tie-breaker.

**Current Flutter:** Product search uses the working server contract. Offer/article search is explicitly labeled as search over loaded records and does not send the broken parameter. Load More remains available even when the local match set is empty. Clinic tier/search and Lead clinic/status/search use verified server filters and one 350 ms debounce. Lead search hints match the fields the server actually searches; they do not promise service-name search.

**Endpoints:** `admin/clinics/`, `admin/leads/`, `admin/offers/`, `admin/products/`, `admin/articles/`.

Replace the existing `BaseContentModerationViewSet.get_queryset()` body with this implementation (existing `Q`, model and status imports remain):

```python
def get_queryset(self):
    if getattr(self, "swagger_fake_view", False) or self.model_class is None:
        return self.model_class.objects.none() if self.model_class else Offer.objects.none()
    field_names = {f.name for f in self.model_class._meta.get_fields()}
    qs = self.model_class.objects.filter(deleted_at__isnull=True)
    related = [f for f in ("clinic", "media_asset", "treatment", "author_practitioner")
               if f in field_names]
    if related:
        qs = qs.select_related(*related)
    status_value = self.request.query_params.get("status")
    clinic_id = self.request.query_params.get("clinic")
    if status_value:
        qs = qs.filter(status__iexact=status_value)
    if clinic_id:
        qs = qs.filter(clinic_id=clinic_id)
    brand = self.request.query_params.get("brand")
    if brand and "brand_name_en" in field_names:
        qs = qs.filter(Q(brand_name_en__icontains=brand) | Q(brand_name_ar__icontains=brand))
    sponsor = self.request.query_params.get("sponsor")
    if sponsor and "sponsor_company" in field_names:
        qs = qs.filter(sponsor_company__icontains=sponsor)
    term = self.request.query_params.get("search", "").strip()
    if term:
        condition = Q()
        for field in ("name_en", "name_ar", "title_en", "title_ar",
                      "brand_name_en", "brand_name_ar", "sponsor_company"):
            if field in field_names:
                condition |= Q(**{f"{field}__icontains": term})
        if "clinic" in field_names:
            condition |= Q(clinic__name_en__icontains=term) | Q(clinic__name_ar__icontains=term)
        if "author_practitioner" in field_names:
            condition |= Q(author_practitioner__name_en__icontains=term)
            condition |= Q(author_practitioner__name_ar__icontains=term)
        qs = qs.filter(condition)
    return qs.order_by("-created_at", "-pk")
```

In `AdminClinicViewSet.get_queryset()`, keep the ordering allowlist but append a unique tie-breaker (`order_by(ordering, "pk")` for allowed orderings; fallback `order_by("-created_at", "-pk")`). In `AdminLeadAPIView.get_queryset()`, change the existing base ordering to `order_by("-created_at", "-pk")`. Maintain the current permission/query scope.

`AdminStandardPagination` already defaults to 20; set `max_page_size = 20` to make the agreed cap server-enforced rather than only client-enforced. Existing callers requesting more must accept smaller pages and follow `next`.

**Compatibility / التوافق:** Search is an optional additive query parameter. After staging acceptance, remove Flutter's offers/articles loaded-page search fallback and use the repaired server query. Do not enable it merely because the frontend sends `search`; the source currently proves that request is broken.

**Tests:** At least 45 records, identical timestamps, matches only beyond page 1, Arabic titles, brand/sponsor and clinic names, active/suspended filters, page-size 20, no duplicates for a static dataset. Pagination over concurrently changing offset datasets still has the usual movement limits; consider a cursor API separately if strict snapshot traversal is required. Verify that a nonempty offer/article search returns 200 rather than FieldError.

## 4. Lead translations / ترجمات أسماء عناصر الطلب

**Verified source:** `AdminLeadClinicSummarySerializer` includes bilingual clinic names. `AdminLeadSerializer.get_branch/get_practitioner/get_treatment/get_offer/get_product` return only English names/titles. `service_name` is free-form historical text. Flutter chooses real localized relation names when supplied, otherwise retains the available original string. Missing or invalid submission time displays `—`; it is never replaced with the current time. Admin supervision remains read-only.

**Endpoint:** GET `admin/leads/`, `admin/leads/{id}/`.

In the existing `AdminLeadEntitySummarySerializer`, add read-only `name_ar` and `title_ar` fields. Replace the five actual serializer methods with these bodies:

```python
def get_branch(self, obj):
    return {"id": obj.branch.id, "name_en": obj.branch.name_en,
            "name_ar": obj.branch.name_ar} if obj.branch else None


def get_practitioner(self, obj):
    return {"id": obj.practitioner.id, "name_en": obj.practitioner.name_en,
            "name_ar": obj.practitioner.name_ar} if obj.practitioner else None


def get_treatment(self, obj):
    return {"id": obj.treatment.id, "name_en": obj.treatment.name_en,
            "name_ar": obj.treatment.name_ar} if obj.treatment else None


def get_offer(self, obj):
    return {"id": obj.offer.id, "title_en": obj.offer.title_en,
            "title_ar": obj.offer.title_ar} if obj.offer else None


def get_product(self, obj):
    return {"id": obj.product.id, "name_en": obj.product.name_en,
            "name_ar": obj.product.name_ar} if obj.product else None
```

Retain their existing schema decorators and `select_related` on the list/detail views. Do not machine-translate stored clinical names or alter `service_name`. No model migration or lead write method is needed. Test both languages, absent relations, blank translations, and genuine historical text.

## 5. Analytics metadata is a summary, not a complete clinic report / حدود بيانات التحليلات

**Current source:** `AdminPlatformAnalyticsAPIView` returns the top 10 clinic IDs/English names/event counts in the date range. It does not return per-clinic leads, branches, offers, subscription tiers or city in that summary. The frontend now shows only those genuine event counts instead of mixing lifetime counters from a partially loaded clinic directory or inventing Basic/Dubai defaults in the UI.

`GET admin/analytics/referrals/` already supplies `total_successful_invites` and `total_points_awarded` from `ReferralInvite` and positive `ReferralPointsLedger.points`. Flutter now uses that verified endpoint. No new referral endpoint, coupon metric, or points calculation is required.

**Optional additive metadata / تحسين اختياري:** If Ali wants bilingual clinic labels and verified subscription badges in the existing event ranking, extend the current `.values(...)` / response comprehension in `AdminPlatformAnalyticsAPIView`:

```python
clinic_engagement_qs = (
    events.filter(clinic__isnull=False)
    .values("clinic__id", "clinic__name_en", "clinic__name_ar",
            "clinic__city", "clinic__subscription_tier")
    .annotate(event_count=Count("id"))
    .order_by("-event_count", "clinic__id")[:10]
)
clinic_engagement = [
    {"clinic_id": str(item["clinic__id"]),
     "clinic_name": item["clinic__name_en"],
     "clinic_name_ar": item["clinic__name_ar"],
     "city": item["clinic__city"],
     "subscription_tier": item["clinic__subscription_tier"],
     "events_count": item["event_count"]}
    for item in clinic_engagement_qs
]
```

Existing clients keep their current keys; Flutter's optional metadata parsing is compatible. Keep counts scoped to the requested event period. Do not label all `total_offers` as Active: the dashboard source counts all nondeleted offers. Likewise `featured_clinics` currently counts Featured/VIP **subscription tiers**, not the independent `is_featured` homepage flag. Flutter keeps these concepts separate and does not render that misleading caption.

**Tests:** Empty range stays zero; more than 10 clinics are honestly a top-10 summary; Arabic names/tier metadata match Clinic records; event counts are not labeled page views or engagement percentages. Positive awarded points must not include negative ledger debits. Keep access restricted to Super Admin.

## 6. Admin mixed-media URL normalization / تطبيع روابط الصور في تعديل العيادة

**Verified source:** `AdminClinicUpdateSerializer.to_internal_value()` strips everything before `/media/` from an absolute URL unless the hostname text starts with `https://pub-`. A custom R2/CDN URL can legitimately contain `/media/`; this turns a real external URL (including its signed query) into a different storage name. The existing `apps.media.utils.resolve_media_url()` already supports absolute HTTP(S) values stored in a FieldFile's `name` without reconstructing their query string. Native binary uploads use the normal ImageField path and should remain unchanged.

**Flutter behavior:** Logo/cover changes normally use multipart. A combined replace/remove operation preserves JSON nulls by pre-uploading the replacement and passing its returned URL. The client cannot safely split one edit into partially successful PATCHes to work around this server transformation. A local cache only applies after API acknowledgement; it cannot repair storage or expired URLs.

**Endpoint:** PATCH `admin/clinics/{id}/`. In the existing `AdminClinicUpdateSerializer`, replace only `to_internal_value()` with the body below. Retain all its fields, `to_representation`, permission checks and the location mixin from section 1:

```python
def to_internal_value(self, data):
    if hasattr(data, "getlist"):
        data = {key: data[key] for key in data.keys()}
    else:
        data = data.copy() if hasattr(data, "copy") else dict(data)
    strings = {}
    for field in ("logo", "cover_image", "video_ad_file"):
        value = data.get(field)
        if field not in data or not isinstance(value, str):
            continue
        data.pop(field)
        raw = value.strip()
        if not raw or raw.lower() in {"null", "none"}:
            strings[field] = None
            continue
        raw = clean_media_url(raw)
        limit = self.Meta.model._meta.get_field(field).max_length
        strings[field] = serializers.URLField(max_length=limit).run_validation(raw)
    result = super().to_internal_value(data)
    result.update(strings)
    return result
```

لا تحذف بادئة الرابط بناءً على وجود `/media/` بداخله، ولا تفك أو تعيد ترميز توقيع الرابط. تظل الملفات المرفوعة ثنائياً خاضعة لتحقق ImageField. الحذف الصريح يساوي `null`، وغياب المفتاح يحافظ على الصورة الحالية.

**Compatibility and limits:** This URL-input branch is for the absolute upload response used by Flutter. If another deployed client sends raw relative storage names, audit that caller before replacing the legacy permissive string branch. Clinic branding columns in the latest reference have length 500; reject oversized values explicitly instead of causing a database-length error. Native uploads remain compatible. Do not store an expiring signed URL as the long-term identity of a private object: Ali must use a stable server-owned object key/asset identity and generate a fresh URL on read for private storage. That storage-specific mapping cannot be inferred from the archive's deployed bucket configuration; use the broader media handoff and verify actual storage settings. No arbitrary server-side URL download is proposed.

**Validation:** Test multipart file replacement, JSON URL replacement, explicit null, omission, and mixed replace/remove. Include an HTTPS CDN URL containing `/media/` and a query such as `?sig=a%2Fb+x`; assert its bytes survive validation and representation unchanged. Test the field length limit and invalid URL rejection, then load the returned image from a fresh client after restart. This is backend persistence testing, beyond a widget preview.

## Deployment order and acceptance / النشر والقبول

1. Apply the private moderation serializers/search/order fixes first; retain public/private API separation and all existing permission checks.
2. Implement and test admin location validation/provisioning. Deploy source and any deployment-specific changes through Ali's normal release process.
3. Deploy bilingual relation fields and optional analytics metadata additively.
4. Run authenticated DRF tests for all three roles, API filtering across multiple pages and fresh-client moderation reloads. Probe actual storage URLs over HTTPS after saving a logo/cover; Flutter's session-local media cache is not evidence of durable server persistence.
5. Hand Flutter a staging deployment identifier and test results. Enable the interactive admin map-write UI and full server search only after their contracts are proven.

لا توجد مدفوعات أو حجز مواعيد أو أكواد خصم في هذه الواجهات. لا تضف حقول ترخيص أو جهات صحية إلى فلاتر. لا تمنح المشرف العام أدوات متابعة المريض أو تعديل حالة طلبه. لا تغيّر باك اند الإنتاج من هذه المحادثة؛ علي مسؤول عن الدمج والاختبار والنشر.
