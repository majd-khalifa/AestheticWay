# Super Admin — verified backend gaps for Ali / نواقص الباك اند للمشرف العام

Date / التاريخ: 20 October 2026. Integration branch: `codex/frontend-audit-scale-ui-20261019` (mirrored to PR #4 on `codex/super-admin-production-hardening`).

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

## 7. Independent brand-product authoring is not implemented by Django / إدارة منتجات العلامات المستقلة غير مدعومة بعد

**Verified source / المصدر المثبت:** `apps/products/models.py::Product.clinic` is already nullable, and `clean()` permits an independent row only when `brand_name_en` or `sponsor_company` is nonempty. The class's older “strictly owned by a clinic” docstring does not reflect this actual field/validation behavior. There is no product category relation. `AdminProductModerationViewSet` inherits `ReadOnlyModelViewSet`; `apps/admin_portal/urls.py` maps list/detail to **GET only**, plus POST moderation actions. No POST create, PATCH update or DELETE/archive is registered. Public `/products/` is also GET-only.

`ClinicProductPortalViewSet.perform_create()` always resolves and assigns a clinic. `get_user_clinic()` may choose the first available clinic for a Super Admin without membership. Although that role passes `IsClinicPortalAccess`, these ownership semantics are **not independent platform authoring**. Flutter must not use this path for global brand products.

**Current Flutter / فلاتر:** Global listing, brand/sponsor identity, read-only inspection and confirmed publication moderation remain usable. Add Brand Product, Edit Brand Product and Archive Brand Product are explicitly unavailable. No unsupported write API, fake success, raw URL input or incomplete authoring form is shipped. The category directory remains separate from products. The future editor must use `LuxuryImagePickerField` at 1200/78 with immediate preview and localized name/description, `brand_name_en`, `brand_name_ar`, `sponsor_company`; no price, clinic assignment, shopping or contact controls.

الإنشاء والتعديل والأرشفة تحتاج مسارات مستقلة للمشرف العام. لا تستخدم مسارات لوحة العيادة لأنها قد تربط المنتج بأول عيادة تلقائياً. دعم النشر والمراجعة موجود ويظل متاحاً. لا تدّعِ اكتمال CRUD قبل دمج الكود ونشره واختباره.

**Proposed contract, not currently deployed / عقد مقترح غير منشور:**

| Route | Proposed method | Behavior |
| --- | --- | --- |
| `/api/v1/admin/products/` | POST | Create an independent product (`clinic=None`) in Pending/unpublished state; return 201 with private read representation. |
| `/api/v1/admin/products/{uuid}/` | PATCH | Update independent brand content only; return 200. Reject writes to clinic-owned records with 403. |
| same | DELETE | Soft archive independent content (`deleted_at`, inactive, suspended), return 204; keep references/history and do not delete media in this transaction. |
| existing `/approve/`, `/suspend/`, etc. | POST | Keep the verified publication/moderation actions and audit trail. |

Use existing `IsAuthenticated, IsSuperAdmin`, and also require an active, nondeleted account on these new writes. Do not widen Clinic Portal permissions. Keep current public GET routes and existing Admin moderation of clinic-associated content.

### Proposed private write serializer / سيريالايزر الكتابة المقترح

Add to `apps/admin_portal/serializers.py`. This uses actual inspected `Product`, `MediaAsset`, `MediaUploadSerializer` and `MediaType` classes. The read serializer is `AdminProductInspectionSerializer` from section 2 (no price). Both native multipart and a pre-uploaded **platform-scoped** media UUID are supported. JSON raw image URLs are deliberately not the write contract.

```python
from apps.media.models import MediaAsset, MediaType
from apps.media.serializers import MediaUploadSerializer
from apps.products.models import Product

class AdminBrandProductWriteSerializer(serializers.ModelSerializer):
    name_en = serializers.CharField(max_length=200, allow_blank=False)
    image = serializers.ImageField(write_only=True, required=False, allow_null=True)
    media_asset = serializers.PrimaryKeyRelatedField(
        queryset=MediaAsset.objects.filter(
            clinic__isnull=True, media_type=MediaType.PRODUCT_IMAGE,
        ), required=False, allow_null=True,
    )

    class Meta:
        model = Product
        fields = ["name_en", "name_ar", "description_en", "description_ar",
                  "brand_name_en", "brand_name_ar", "sponsor_company",
                  "image", "media_asset"]

    def to_internal_value(self, data):
        unknown = set(data.keys()) - set(self.fields)
        if unknown:
            raise serializers.ValidationError({
                key: "This field is not supported for independent brand authoring."
                for key in unknown
            })
        return super().to_internal_value(data)

    def validate_media_asset(self, value):
        if value and (not value.file or not value.mime_type.startswith("image/")):
            raise serializers.ValidationError("Choose a validated product image.")
        return value

    def validate(self, attrs):
        attrs = super().validate(attrs)
        if "image" in attrs and "media_asset" in attrs:
            raise serializers.ValidationError("Send an image or a media asset, not both.")
        brand = attrs.get("brand_name_en", getattr(self.instance, "brand_name_en", ""))
        sponsor = attrs.get("sponsor_company", getattr(self.instance, "sponsor_company", ""))
        if not (brand.strip() or sponsor.strip()):
            raise serializers.ValidationError({
                "brand_name_en": "An English brand name or sponsor is required for an independent product."
            })
        return attrs

    def _resolve_image(self, values):
        image = values.pop("image", serializers.empty)
        if image is not serializers.empty:
            if image is None:
                values["media_asset"] = None
            else:
                upload = MediaUploadSerializer(
                    data={"file": image, "media_type": MediaType.PRODUCT_IMAGE,
                          "clinic_id": None}, context=self.context,
                )
                upload.is_valid(raise_exception=True)
                values["media_asset"] = upload.save()
            values["image"] = ""
        elif "media_asset" in values:
            values["image"] = ""
        return values

    def create(self, validated_data):
        return super().create(self._resolve_image(validated_data))

    def update(self, instance, validated_data):
        return super().update(instance, self._resolve_image(validated_data))
```

Image omission preserves the current asset; explicit JSON `{"media_asset": null}` clears both asset and legacy URL. Replacement uses native multipart `image` or a single JSON `media_asset` UUID returned by `/media/upload/` with `media_type=product_image` and **no clinic_id**. Do not send both `image` URL and UUID. An Arabic-only brand without sponsor is rejected because the inspected model's `clean()` explicitly requires English brand or sponsor for independent records; change that model rule separately only if the product policy changes. Existing legacy prices remain in storage but are neither accepted nor exposed by the Admin serializer.

### Extend the actual AdminProductModerationViewSet / تعديل الـ ViewSet الحالي

Keep its existing decorators, `model_class`, `queryset`, `entity_type_name` and inherited moderation methods. Replace `get_serializer_class()` with the private read serializer and add these methods to the existing class. Import `AdminBrandProductWriteSerializer` and `AdminProductInspectionSerializer` from the actual Admin serializer module. `transaction`, `timezone`, `AdminAuditLog`, `AdminActionType`, parsers and `Response` already exist in `views.py`; add `PermissionDenied` from `rest_framework.exceptions`.

```python
parser_classes = [MultiPartParser, FormParser, JSONParser]

def get_serializer_class(self):
    return AdminProductInspectionSerializer

def _check_authoring_account(self, request):
    # Existing IsAuthenticated + IsSuperAdmin apply first to every action.
    if not request.user.is_active or request.user.deleted_at is not None:
        raise PermissionDenied("An active Super Admin account is required.")

def _lock_independent(self, request, pk):
    self._check_authoring_account(request)
    instance = get_object_or_404(self.get_queryset().select_for_update(), pk=pk)
    self.check_object_permissions(request, instance)
    if instance.clinic_id is not None:
        raise PermissionDenied("This authoring action is for independent brand products only.")
    return instance

def _audit_authoring(self, request, product, operation):
    AdminAuditLog.objects.create(
        admin=request.user, action_type=AdminActionType.MODERATE_CONTENT,
        entity_type="Product", entity_id=product.pk,
        details={"operation": operation, "scope": "independent_brand"},
    )

@transaction.atomic
def create(self, request):
    self._check_authoring_account(request)
    write = AdminBrandProductWriteSerializer(data=request.data, context=self.get_serializer_context())
    write.is_valid(raise_exception=True)
    product = write.save(clinic=None, status="pending", is_active=False)
    self._audit_authoring(request, product, "create")
    return Response(self.get_serializer(product).data, status=201)

@transaction.atomic
def partial_update(self, request, pk=None):
    product = self._lock_independent(request, pk)
    write = AdminBrandProductWriteSerializer(
        product, data=request.data, partial=True, context=self.get_serializer_context(),
    )
    write.is_valid(raise_exception=True)
    product = write.save()
    self._audit_authoring(request, product, "update")
    return Response(self.get_serializer(product).data)

@transaction.atomic
def destroy(self, request, pk=None):
    product = self._lock_independent(request, pk)
    product.deleted_at = timezone.now()
    product.is_active = False
    product.status = "suspended"
    product.save(update_fields=["deleted_at", "is_active", "status", "updated_at"])
    self._audit_authoring(request, product, "archive")
    return Response(status=204)
```

In `apps/admin_portal/urls.py`, replace the two existing product list/detail mappings; do not add duplicate shadowed routes:

```python
path("products/", AdminProductModerationViewSet.as_view({"get": "list", "post": "create"}), name="product-list"),
path("products/<uuid:pk>/", AdminProductModerationViewSet.as_view(
    {"get": "retrieve", "patch": "partial_update", "delete": "destroy"}), name="product-detail"),
```

No Product migration is needed for independent authoring itself: nullable clinic, media, brand/sponsor and soft-delete fields already exist. Storage writes are not rolled back by a database transaction; retain the project's orphan-upload cleanup policy and do not delete an old shared asset during an edit/archive.

**Acceptance / القبول:** Unauthenticated, patient and clinic-admin writes must fail. Create without a clinic membership or any Clinic row must succeed. Sending `clinic`, `price`, status booleans or treatment category IDs must fail. Clinic-associated rows remain inspectable/moderatable but cannot be edited/archived through these authoring methods. Test multipart and media UUID, wrong media type/MIME, cross-clinic asset rejection, omission/null, failed save rollback/audit, fresh-client image loading, 201/200/204 responses, public visibility after approval, suspension/archive exclusion and stable pagination. After Ali's staging deployment, wire the native Flutter editor and enable authoring controls; current controls do not infer capability from a public field or role label.

## 8. Treatment category CRUD and separate brand taxonomy / تصنيفات العلاجات منفصلة عن تصنيفات العلامات

**Verified source:** `apps/treatments/models.py::Category` is a global **treatment** taxonomy, with Treatment.category using CASCADE. `/categories/` maps only GET to `CategoryListAPIView`; it lists active categories and searches bilingual names. There is no category detail/write route, no `clinic-portal/categories/` registration and no Admin category API in either inspected reference. `Product` has no Category foreign key and there is no brand-product category model.

The earlier [Clinic Portal handoff](BACKEND_FIXES_FROM_CODEX_AUDIT_FOR_ALI.md#2026-10-20--clinic-portal-categories-https-media-and-image-persistence) proposes future category writes. That document is **not deployed source**. Existing Clinic Portal controls/history are preserved; this Admin extension does not call its clinic-first write fallback, reuse ClinicPortalService or assume that proposal has been deployed. It reuses `CategoryRepository` for the verified public GET, `CategoryModel` and shared pagination/UI. The Admin directory explicitly shows **active treatment categories only**, with 20-row paging, 350 ms search, retry and session invalidation. Add/Edit/Delete remain unavailable until Ali implements a verified write contract.

تصنيفات العلاجات ليست تصنيفات منتجات العلامات. لا ترسل معرّف تصنيف علاج داخل منتج، ولا تفترض وجود ملكية عيادة لهذا الجدول المشترك. لا تحذف تصنيفاً مرتبطاً بعلاج لأن CASCADE قد يحذف علاجات عيادات أخرى، حتى لو كانت محذوفة منطقياً.

### Proposed private treatment-category management / إدارة التصنيفات العلاجية المقترحة

Use a separate Admin route so authorization does not depend on clinic membership/fallback. Keep public GET unchanged and reconcile any earlier Clinic Portal category deployment additively. Add this serializer in `apps/admin_portal/serializers.py`, importing the actual `Category` and `uuid`, `slugify`:

```python
import uuid
from django.utils.text import slugify
from apps.treatments.models import Category

class AdminTreatmentCategorySerializer(serializers.ModelSerializer):
    name_en = serializers.CharField(max_length=200, allow_blank=False)
    name_ar = serializers.CharField(max_length=200, allow_blank=False)

    class Meta:
        model = Category
        fields = ["id", "name_en", "name_ar", "slug", "display_order", "is_active"]
        read_only_fields = ["id", "slug"]

    def create(self, validated_data):
        stem = slugify(validated_data["name_en"])[:180] or "category"
        validated_data["slug"] = f"{stem}-{uuid.uuid4().hex}"
        return super().create(validated_data)
```

Add to `apps/admin_portal/views.py` with imports `Category`, `Treatment`, serializer above, `APIException` and `PermissionDenied`. `filters` is imported from DRF. No new model or migration is needed for treatment categories.

```python
class CategoryInUse(APIException):
    status_code = 409
    default_detail = "This category is used by treatments and cannot be deleted."
    default_code = "category_in_use"

class AdminTreatmentCategoryViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated, IsSuperAdmin]
    serializer_class = AdminTreatmentCategorySerializer
    pagination_class = AdminStandardPagination
    http_method_names = ["get", "post", "patch", "delete", "head", "options"]
    filter_backends = [filters.SearchFilter]
    search_fields = ["name_en", "name_ar"]

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        if not request.user.is_active or request.user.deleted_at is not None:
            raise PermissionDenied("An active Super Admin account is required.")

    def get_queryset(self):
        return Category.objects.all().order_by("display_order", "name_en", "pk")

    @transaction.atomic
    def destroy(self, request, pk=None):
        category = get_object_or_404(self.get_queryset().select_for_update(), pk=pk)
        self.check_object_permissions(request, category)
        # Includes all clinics and soft-deleted treatments.
        if Treatment.objects.filter(category_id=category.pk).exists():
            raise CategoryInUse()
        category.delete()
        return Response(status=204)
```

Add explicit new Admin mappings and import this class in `apps/admin_portal/urls.py`:

```python
path("treatment-categories/", AdminTreatmentCategoryViewSet.as_view(
    {"get": "list", "post": "create"}), name="treatment-category-list"),
path("treatment-categories/<uuid:pk>/", AdminTreatmentCategoryViewSet.as_view(
    {"get": "retrieve", "patch": "partial_update", "delete": "destroy"}), name="treatment-category-detail"),
```

Admin GET includes inactive categories, unlike the current public list. Slug remains stable during rename. Do not silently convert deletion into deactivation: return 409 for any referenced row. Before release, validate lock/deletion behavior with concurrent treatment inserts against PostgreSQL; consider migrating the foreign key to PROTECT for database/application-wide deletion safety. Keep audit additions within the application's existing audit policy (the code above does not invent new enum values).

**Acceptance:** role matrix, inactive visibility only in Admin, bilingual validation, unique/stable slugs, safe unused-category delete 204, referenced-category delete 409 including another clinic and soft-deleted treatments, 20-row paging and server search across page boundaries. Wire Admin writes only after staging verification, using the Admin scope explicitly; do not switch the existing Clinic Portal repository to an Admin path.

### Brand-product categories require a new schema / تصنيفات منتجات العلامات تحتاج مخططاً جديداً

There is **no existing brand-product category contract to reuse**. If this taxonomy is required, Ali must add a distinct model and migration. These names are a proposed extension, not claims about existing source:

```python
# Proposed additions in apps/products/models.py (uuid and models already imported).
class BrandProductCategory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name_en = models.CharField(max_length=200)
    name_ar = models.CharField(max_length=200, blank=True, default="")
    slug = models.SlugField(max_length=220, unique=True)
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "brand_product_categories"
        ordering = ["display_order", "name_en", "pk"]

# Add this field INSIDE the existing Product class; existing rows keep null.
# category = models.ForeignKey(BrandProductCategory, on_delete=models.PROTECT,
#     null=True, blank=True, related_name="products")
```

Generate/review/apply the products migration through Ali's release process; do not migrate treatment category IDs into this relation. After the migration, the private write serializer may add `category = PrimaryKeyRelatedField(queryset=BrandProductCategory.objects.filter(is_active=True), required=False, allow_null=True)` and append it to Meta.fields. Public/private read serializers must expose a separate brand-category summary; add a real product filter, never a treatment-category join.

After the new model/relation migration, add these concrete classes and import the proposed `BrandProductCategory` model into the Admin serializer/view modules:

```python
# In apps/admin_portal/serializers.py, after AdminTreatmentCategorySerializer:
class AdminBrandProductCategorySerializer(AdminTreatmentCategorySerializer):
    class Meta(AdminTreatmentCategorySerializer.Meta):
        model = BrandProductCategory

# In apps/admin_portal/views.py, after AdminTreatmentCategoryViewSet:
class BrandCategoryInUse(CategoryInUse):
    default_detail = "This category is used by brand products and cannot be deleted."

class AdminBrandProductCategoryViewSet(AdminTreatmentCategoryViewSet):
    serializer_class = AdminBrandProductCategorySerializer

    def get_queryset(self):
        return BrandProductCategory.objects.all().order_by("display_order", "name_en", "pk")

    @transaction.atomic
    def destroy(self, request, pk=None):
        category = get_object_or_404(self.get_queryset().select_for_update(), pk=pk)
        self.check_object_permissions(request, category)
        if Product.objects.filter(category_id=category.pk).exists():
            raise BrandCategoryInUse()
        category.delete()
        return Response(status=204)
```

Register these new routes in `apps/admin_portal/urls.py`, importing the new ViewSet:

```python
path("brand-product-categories/", AdminBrandProductCategoryViewSet.as_view(
    {"get": "list", "post": "create"}), name="brand-product-category-list"),
path("brand-product-categories/<uuid:pk>/", AdminBrandProductCategoryViewSet.as_view(
    {"get": "retrieve", "patch": "partial_update", "delete": "destroy"}), name="brand-product-category-detail"),
```

IsAuthenticated + IsSuperAdmin, active-account validation, bilingual search and 20-item pagination are inherited from the treatment-category Admin ViewSet; data models and deletion checks are separate. The new PROTECT relation also prevents cascading data loss. Validate distinct IDs, absent/invalid/inactive brand category assignment, backward-compatible nulls, role isolation, paging and renaming. No brand-category UI selection or write request should be enabled before this schema/API is deployed. Current Flutter shows the separation and unavailable state honestly.


## Deployment order and acceptance / النشر والقبول

1. Apply the private moderation serializers/search/order fixes first; retain public/private API separation and all existing permission checks.
2. Implement and test admin location validation/provisioning. Deploy source and any deployment-specific changes through Ali's normal release process.
3. Deploy bilingual relation fields and optional analytics metadata additively.
4. Run authenticated DRF tests for all three roles, API filtering across multiple pages and fresh-client moderation reloads. Probe actual storage URLs over HTTPS after saving a logo/cover; Flutter's session-local media cache is not evidence of durable server persistence.
5. Implement/test the independent product authoring and private treatment-category APIs in sections 7–8. Brand-category support additionally requires the explicitly proposed model/relation migration. Do not bind Product to Treatment Category.
6. Hand Flutter a staging deployment identifier and test results. Enable the interactive admin map-write UI and full server search only after their contracts are proven.

لا توجد مدفوعات أو حجز مواعيد أو أكواد خصم في هذه الواجهات. لا تضف حقول ترخيص أو جهات صحية إلى فلاتر. لا تمنح المشرف العام أدوات متابعة المريض أو تعديل حالة طلبه. لا تغيّر باك اند الإنتاج من هذه المحادثة؛ علي مسؤول عن الدمج والاختبار والنشر.
