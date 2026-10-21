# Patient visual recovery — backend handoff / تسليم إصلاحات الواجهة لعلي

2026-10-20. Frontend PR #6 remains unmerged. Django was inspected read-only. All Python below is **proposed work for Ali**, not deployed code. This supplements [the original Patient handoff](PATIENT_PORTAL_BACKEND_GAPS_FOR_ALI.md); its earlier advertisement-only Home recommendation is superseded by the distinctions here.

تم فحص Django للقراءة فقط، ولم يتم تعديل أو نشر أي ملف خلفي. مقاطع Python أدناه اقتراحات تنفيذ لعلي وليست ميزات منشورة. هذا الملف يكمل التسليم السابق، ويصحح توصية قصر الصفحة الرئيسية على سجلات الإعلانات وحدها.

## 1. Verified current contract / العقد الحالي المؤكد

| Concept / المفهوم | Actual source / المصدر | Frontend behavior / سلوك Flutter |
| --- | --- | --- |
| Clinic subscription / اشتراك العيادة | `apps/clinics/models.py:173`; `SubscriptionTier` = `basic`, `featured`, `vip` | Premium subscription clinics from the existing public directory can appear as partners, without creating an ad record. / عرض الشركاء أصحاب الاشتراك المميز دون اختلاق إعلان. |
| Advertisement placement / موضع الإعلان | `apps/media/models.py:21`; `FeaturedAd.subscription_tier` is an independent free-text field | Actual Home ad tiers `VIP`, `Featured`, `Basic` are serialized by `apps/home/serializers.py:97`. Flutter trims/case-normalizes **vip/featured only**, ranks VIP first, preserves each server tier's order. No guessed `vip_platinum` ad alias. / فصل تصنيف الإعلان عن اشتراك العيادة. |
| Publication / النشر | `apps/clinics/views.py:39`: active and not deleted; Home ads at `apps/home/views.py:54` also require active linked clinics | Publication authority is the existing public endpoint. No fabricated verification badge. / الاعتماد على واجهة النشر العامة دون شارة موافقة مختلقة. |
| Approval / الموافقة | `Clinic.setup_status`, `apps/clinics/models.py:154` | The public Home/directory does not expose independent approval evidence and does not filter `setup_status=approved`. Flutter cannot certify it. / لا تستطيع الواجهة تأكيد الموافقة الداخلية غير المعروضة. |
| Home visibility entitlement / استحقاق الظهور | No separate entitlement, term or expiry field exists in the inspected clinic/ad models | Current supported fallback uses published premium subscription tiers; it cannot validate 3/6/12-month contracts or expiration. `is_featured` alone never implies payment or VIP. / لا يمكن تأكيد مدة العقد أو انتهائه، ولا يكفي حقل is_featured لإثبات الدفع. |

Flutter now calls `GET home/feed/`, then **one bounded `GET clinics/?page=1&page_size=20`**, with the same supported city/geo filters. It enriches matching clinic IDs with canonical public media/Google fields, adds genuine premium subscription partners, and keeps actual ad IDs/media/tier separate. Basic clinics stay ordinary directory entries. Duplicate subscription entries are removed when that clinic already has a real premium ad; distinct real ad placements are retained. Public-directory failure retains successful ads and exposes a localized refresh action.

يطلب Flutter الصفحة الرئيسية ثم صفحة عامة واحدة من العيادات بحجم 20. يتم دمج بيانات العيادة عبر معرّفها الحقيقي، مع إبقاء الإعلان واشتراك العيادة منفصلين، وعدم ترقية العيادات الأساسية. عند فشل جلب الشركاء تبقى الإعلانات الصحيحة ظاهرة ويظهر إجراء لإعادة المحاولة.

**Limit:** the top-20 public page and Home's top-10 ads cannot guarantee exposure for every paying clinic. The client deliberately does not crawl every page on Home, infer payment, randomly rotate unknown contracts, or manufacture advertisements.

**الحد الحالي:** لا تكفي أول 20 عيادة وأول 10 إعلانات لضمان ظهور كل شريك دافع. يلزم تنظيم الاستحقاقات والتوزيع في الخادم، وليس اختلاق سجلات في التطبيق.

## 2. P0 Home serializers and request context / توحيد تسلسل الصفحة الرئيسية

`apps/home/serializers.py:15` omits clinic subscription tier, Google review count/maps, gallery and video, and uses raw ImageFields. `apps/clinics/serializers.py:31` already has a richer public serializer with `resolve_media_url` and excludes regulatory/moderation fields. The Home offer serializer at line 49 omits the image entirely; the existing public offer serializer already resolves it.

المسلسلات العامة الحالية تحتوي بيانات وصوراً لا يعيدها مسلسل Home. المطلوب إعادة استخدام المسلسلات العامة، وعدم تسريب بيانات التراخيص أو المراجعة الداخلية.

Proposed minimal reuse, retaining existing class names/imports and Home keys:

```python
# apps/home/serializers.py — proposed replacement for these two classes
from apps.clinics.serializers import PublicClinicListSerializer
from apps.offers.serializers import PublicOfferSerializer

class PublicClinicSerializer(PublicClinicListSerializer):
    pass

class OfferSerializer(PublicOfferSerializer):
    clinic = PublicClinicSerializer(read_only=True)
```

In `HomeFeedAPIView.get`, pass context to **every** serializer:

```python
context = {"request": request}
response_data = {
    "featured_ads": FeaturedAdSerializer(featured_ads, many=True, context=context).data,
    "categories": CategorySerializer(categories, many=True, context=context).data,
    "active_offers": OfferSerializer(offers_qs, many=True, context=context).data,
    "nearby_clinics": PublicClinicSerializer(clinics_qs, many=True, context=context).data,
}
```

This preserves the current API paths and avoids a new fabricated frontend endpoint. Add serializer tests for all fields, HTTPS/storage/CDN URLs, and absence of private fields. Do not replace real clinic subscription tier with an advertisement's tier.

يجب اختبار المفاتيح والروابط واستبعاد البيانات الخاصة، وعدم استبدال اشتراك العيادة بتصنيف الإعلان.

## 3. P0 Advertisement media / وسائط الإعلان

`FeaturedAd.image_url` at `apps/media/models.py:66` returns `media_asset.url` even if the asset is a video. `apps/home/serializers.py:87` forwards it without request context or media-kind validation. Supply an actual image/poster only, never an MP4 as an image URL:

```python
# Inside FeaturedAdSerializer — proposed
from apps.media.utils import resolve_media_url

def get_image_url(self, obj):
    request = self.context.get("request")
    if obj.image:
        return resolve_media_url(obj.image, request) or ""
    if obj.media_type == "image" and obj.media_asset:
        return resolve_media_url(obj.media_asset.file, request) or ""
    return ""

def get_video_url(self, obj):
    if obj.media_type != "video":
        return None
    request = self.context.get("request")
    if obj.video_url:
        return resolve_media_url(obj.video_url, request)
    if obj.media_asset:
        return resolve_media_url(obj.media_asset.file, request)
    return None
```

Validate ad media type, MIME, asset ownership and clinic association on write; reject unsupported tier strings. If poster support is required, add a separate validated poster asset field rather than reusing a video file as an image. Preserve muted 15-second playback and actual media attribution.

يجب التحقق من نوع الملف وملكيته والعيادة المرتبطة به عند الحفظ. صورة الملصق حقل مستقل عند الحاجة، ولا يجوز عرض ملف فيديو كرابط صورة.

## 4. P0 Storage persistence, signed URLs and cache / التخزين والروابط الموقعة والتخزين المؤقت

The frontend can recover the recognized first-party wrapper `/media/https%3A/cdn-host/path` or `/media/https:/cdn-host/path`. It does not decode/modify valid signed absolute URLs. Genuine primary media remains first; failed/missing photographic banners collapse instead of showing a large logo panel. Local upload cache remains session-only; a preview is **not** evidence of backend persistence.

يمكن للتطبيق معالجة غلاف المسار الخاطئ المحدد، لكنه لا يصلح توقيعاً منتهياً أو ملفاً غير محفوظ أو صلاحيات تخزين خاطئة. معاينة الملف المحلي ليست إثباتاً لنجاح الحفظ في الخادم.

Ali must:

1. Keep `ImageField`/`FileField` values as storage keys. Keep externally hosted absolute URLs in suitable URL fields or validated `MediaAsset` relations. Never feed a remote URL into filesystem storage as a filename.
2. Reuse `resolve_media_url` for Home, clinic/detail, product, offer, practitioner and article media. Repair existing mangled database values in a separately reviewed data migration. Do not blanket-decode an entire signed URL or strip `/media/` out of external URLs.
3. Preserve the signed URL's path/query byte-for-byte, generate HTTPS URLs, verify public asset permissions, and return a non-success response for failed uploads or unsaved associations. The earlier profile serializer URL-stripping and VIP-video validation handoff still applies.
4. Check CDN/object identity after a real authenticated upload, reload from a second session and a fresh device, and GET the returned binary without printing signed queries or patient details. Record status, MIME, byte count and a digest; verify a genuine image decode, not just HTTP 200.
5. Avoid caching serialized presigned URLs at `apps/home/views.py:218` beyond their usable life. Prefer cached record IDs/query results plus fresh serialization per request. Invalidate Home cache on clinic/ad/media/offer publication or changes. Cache keys must include a public schema version and the supported city/geo filters.

على علي تصحيح أنواع الحقول والبيانات القديمة، والتحقق من بقاء الصورة بعد إعادة تسجيل الدخول ومن جهاز آخر، وتحديث الروابط الموقعة دون العبث بمسارها، وإبطال ذاكرة Home عند تحديث الصور أو النشر. لا تُسجل الروابط الموقعة أو بيانات المرضى في التشخيص.

**Live verification was blocked:** the environment proxy denied the production API tunnel with HTTP 403. No production response body, object bytes, authenticated write or device upload was inspected. Local deterministic HTTP tests still validate decoding, corrupt/empty/HTML responses, expired signatures, aliases and provider types. No claim that a live failed upload is fixed.

**التحقق المباشر محجوب:** منع وكيل الشبكة الاتصال بالخادم الإنتاجي برمز 403، لذلك لم يتم فحص ملفات إنتاجية أو إجراء رفع مصادق عليه، ولا ندعي إصلاح ملف لم يتم حفظه فعلياً.

## 5. Explicit eligibility and fair delivery / الاستحقاق الصريح والتوزيع العادل

Recommended server design for Ali, **not an endpoint the client currently calls**:

- Keep clinic subscription tier, advertisement placement tier, publication/approval and Home entitlement independent.
- Resolve Home entitlement from the actual commercial contract, including enabled state and expiry; the inspected backend has no such contract entity. If represented by new fields, migrate them only from reviewed commercial records, not every `is_featured=True` clinic. Do not mark an inactive/unapproved clinic eligible.
- Publish a documented public `home_eligible` result and its source (`subscription` or `advertisement`); expose only patient-safe evidence. Include eligible subscription clinics in the Home response or add a separately documented paginated partner resource. Current Flutter requires no invented endpoint and will need a small parser update only after that contract is deployed.
- Apply `status=active`, `deleted_at IS NULL`, and the required approved setup/valid-entitlement policy server-side. Review legacy active/draft records before tightening the approval filter so legitimate partners are not silently lost.
- Rank VIP before Featured, preserve `display_order`, add unique ID tie-breaking, and implement measurable rotation/frequency rules server-side within the same paid tier. Test >20 premium clinics, empty ad tables, expired contracts, Basic clinics with `is_featured=True`, city filters, null-clinic ads and duplicate placements.
- Google Places sync already exists in this backend. Expose its real `google_rating`, `google_reviews_count` and map link consistently; do not calculate substitutes or seed ratings.

التصميم المطلوب يفصل الاشتراك عن الإعلان والموافقة واستحقاق الظهور، ويأخذ الاستحقاق من العقد التجاري الحقيقي مع صلاحيته. يجب مراجعة السجلات القديمة قبل فرض الموافقة، وتطبيق الترتيب والتناوب على الخادم واختبار أكثر من 20 شريكاً. تكامل Google موجود بالفعل؛ المطلوب نشر حقوله الصحيحة دون تقييمات مختلقة.

## 6. Content and acceptance / المحتوى والقبول

Short source descriptions such as “anything” are CMS quality defects. Flutter preserves supplied medical content rather than inventing replacement biographies, qualifications or clinic claims. Review both localized descriptions, real photos and publication status in Ali's content workflow.

الأوصاف مثل “anything” مشكلة محتوى في المصدر. يحافظ التطبيق على النص الطبي الوارد ولا يختلق وصفاً أو مؤهلات. يجب مراجعة النصين العربي والإنجليزي والصور والنشر من لوحة المحتوى.

Deployment acceptance: published eligible VIP/Featured clinics appear without requiring an ad row; genuine paid ad records remain separately labeled; Basic/unknown tiers are never promoted; failed images collapse; valid photos/portraits/logos/products use their proper fit; inquiry IDs and frozen Arabic confirmation remain unchanged. Verify on Android with staging and real sanitized media. Native Windows verification remains outstanding.

قبول النشر: ظهور الشركاء المستحقين دون اشتراط إعلان، وتمييز الإعلانات المدفوعة، وعدم ترقية Basic، وعرض الصور الحقيقية، والمحافظة على معرّفات الطلب ونص التأكيد العربي الثابت. يلزم اختبار Android على بيانات آمنة، وما زال التحقق الأصلي على Windows مطلوباً.
