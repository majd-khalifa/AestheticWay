# Media-first handoff for Ali / تسليم عرض الوسائط إلى علي

Reviewed 21 October 2026 (Asia/Damascus). Frontend baseline: `242aa8763a4f170cafa6f81c0f978b2998113092`.

**Scope:** read-only contract tracing of the latest supplied `backend.zip`. No Django file was changed. This archive is a source snapshot, **not deployment evidence**. No authenticated production response, object-store credentials, or device capture of a successful live upload was available. Production media persistence and delivery remain unverified.

**النطاق:** تمت مراجعة عقود نسخة `backend.zip` للقراءة فقط. لم نعدّل Django. الأرشيف لا يثبت نشر هذه النسخة على الخادم. لم تتوفر استجابة إنتاج موثقة أو صلاحية فحص التخزين أو تجربة رفع ناجحة على جهاز؛ لذلك لا ندّعي إصلاح صور الإنتاج.

Archive SHA-256: `d3a676d464a75805651bbdef7b91d184e6dd6d02b75953267efe7418e7a28f22`. Extracted reference: 641 files. Hashes are checked against the pre-work inventory. The archive contains the site logo but no clinic/product/practitioner photo library with which to establish actual live record media.

## 1. What is fixed in Flutter / ما تم إصلاحه في Flutter

1. A video-only advertisement previously rendered a zero-height absent poster. `ViewportActivity` consequently never observed a visible area, so no video controller could start. `FeaturedAdSlideMedia` now gives a **valid video** a responsive 16:9 stage, with an honest video status, muted playback, progress, pause/play/retry, reduced-motion opt-in, and the existing 15-second bound. A record with neither image nor video still collapses.
2. A video-backed `FeaturedAd.media_asset` can appear in both `image_url` and `video_url`. When `media_type=video` and those resolved URLs match, the parser treats it as video, **not a poster image**. A distinct real poster retains precedence. The clinic photograph can supply the poster without replacing the approved placement's video selection.
3. Discovery uses the real cover, then an actual gallery photograph. A logo never substitutes for photography. Missing/failed photos collapse, while compact identity remains. Clinic profile gallery width follows its container rather than the whole window.
4. Shared cards use responsive photographic framing. Product packaging is contained. Media URL query bytes, session isolation, request coalescing, page size and cache budgets remain intact.

**بالعربية:** أُصلح توقف فيديو الإعلان بلا صورة ملصق، ومنع تفسير رابط الفيديو كصورة، وأُعطيت الصور الحقيقية أولوية على الشعارات. الصور المفقودة لا تحجز لوحة فارغة. هذا إصلاح لمسار العرض وليس إثباتاً لحفظ ملفات الإنتاج.

## 2. Contract trace / تتبع العقد

Paths in the backend column are relative to the supplied archive. Exact symbols are included because line numbers can move between deployments.

| Entity | Flutter consumes | Supplied Django source | Result and responsibility |
|---|---|---|---|
| Clinic logo/cover | `ClinicModel.fromJson`: nonblank `logo`/`logo_url`, `cover_image`/`cover_image_url`; cover before gallery | `apps/clinics/serializers.py:32` `PublicClinicListSerializer`, `:94` `to_representation`; corresponding detail serializer | Resolves fields with request context. Existing archive behavior supports absolute URLs. Verify deployed Home, list and detail responses agree. |
| Home clinics | Same `ClinicModel` | `apps/home/serializers.py:16` `PublicClinicSerializer(PublicClinicListSerializer)` | **Already inherits the directory serializer in this snapshot.** Do not repeat an older handoff's claim that this inheritance is missing. Deployment unknown. |
| Clinic video | `video_url`, then `video_ad_file`, VIP eligibility | `apps/clinics/serializers.py:88` `get_video_url`; `Clinic.video_ad_file` | Public URL exists in this snapshot. Playback remains subject to active slide/tab/route, foreground, viewport and reduced motion. |
| Featured image/video | `FeaturedAdApiModel`: `image_url`/`image`, `video_url`, `media_type`, placement tier and clinic | `apps/media/models.py:65` `FeaturedAd.image_url`; `apps/home/serializers.py:51` `FeaturedAdSerializer` | **Confirmed ambiguity:** model property returns `media_asset.url` even for video. Flutter now handles identical image/video URLs. Backend should return a genuine poster separately. |
| Offer banner | `OfferModel`: `image_url`, `image` | `apps/offers/models.py:81` `image_url`; `apps/offers/serializers.py:23`; Home's `OfferSerializer.get_image_url` | Model prefers the asset file, then legacy image. Home additionally resolves using request context. Relative catalog strings are resolved against the configured media origin in Flutter. |
| Product photograph | `ProductModel`: `image_url`, `image`; no commerce fields displayed | `apps/products/models.py:130` `image_url`; `PublicProductSerializer` | Asset file precedes legacy URL. A nonempty URL does not prove that its bytes are accessible or decodable. |
| Practitioner portrait | `PractitionerModel`: `avatar_url`, `avatar`, supported aliases | `apps/practitioners/models.py:97` `avatar_url`; public list/detail serializers | Asset file precedes legacy avatar. Absent portrait uses a small identity fallback, not a fabricated doctor photo. |
| Article cover | `ArticleModel`: `cover_image_url`, `image_url`, `cover_image`, `image` | `apps/articles/serializers.py:50,77` map `cover_image_url` from model `image_url` | Existing alias is supported; no new backend field is required solely to display this alias. |

**ملاحظة:** بعض إصلاحات العقود موجودة فعلاً في الأرشيف الجديد، بما فيها `ScopedPortalImageMixin`. المطلوب مقارنة النسخة المنشورة بهذه النسخة وفحص الملف نفسه، لا إعادة إنشاء إصلاح موجود ولا افتراض نشره.

## 3. Upload, persistence and delivery / الرفع والحفظ والتوصيل

### Catalog images

`ClinicCatalogRepository._resolveMediaAssetPayload` uploads a selected local image to `POST /api/v1/media/upload/` using multipart `file`, the entity-specific `media_type` and optional clinic scope. A successful response must contain the asset `id` and valid public/storage `url`. Flutter then sends JSON to the create/PATCH catalog endpoint:

```json
{"image": "<uploaded-url>", "media_asset": "<asset-uuid>"}
```

Use `avatar` for practitioners and `cover_image` for articles. A supplied `MultipartFile` instead produces `FormData`. Omitted keys preserve media; explicit removal sends both the image key and `media_asset` as null. A missing ID/URL fails before reporting a successful catalog save.

The snapshot already supplies `apps/media/portal_images.py` with `PortalImageInputField` and `ScopedPortalImageMixin`, imported by practitioner/offer/product/article portal serializers. The mixin validates asset type/MIME/tenant scope, links the asset and clears the legacy URL when an asset is supplied. Confirm this module and its serializers/views are **actually deployed together**. An older ImageField-only deployment can reject the URL string or fail to link the asset.

### Clinic logo, cover and VIP video

`ClinicCatalogRepository.updateClinicProfile` uses `MediaPayloadBuilder` and PATCH. A local file becomes multipart `logo`, `cover_image` or `video_ad_file`. URL-only or removal requests use JSON. Mixing a logo/cover replacement with a removal uploads the replacement first and preserves the null in JSON; unsupported mixed video removal/replacement fails explicitly. Dio supplies multipart boundaries; do not hard-code `application/json` for `FormData`.

The snapshot's `ClinicProfileAPIView` (`apps/clinics/portal_views.py:137`) accepts `MultiPartParser`, `FormParser` and `JSONParser`. `ClinicProfilePortalSerializer` accepts ImageFields/FileField and also string references in `to_internal_value`; its representation resolves logo/cover/video fields.

**بالعربية:** نجاح رفع الملف لا يكفي. يجب نجاح ربط UUID بالسجل ثم إعادة قراءة السجل والتأكد من أن رابط الصورة يعيد ملفاً قابلاً للفك. شعار/غلاف العيادة والفيديو يستخدمون PATCH متعدد الأجزاء عند رفع ملف؛ صور الكتالوج ترفع أولاً ثم تربط `media_asset`. لا تثبت رسالة نجاح النص أن الملف متاح عبر CDN.

### Storage and caching

`config/settings/base.py:143-144,291-338` chooses local storage, R2 or S3 from deployment configuration. `config/storage_backends.py` configures R2 endpoint/custom domain/bucket, `s3v4`, automatic region and `file_overwrite=False`. The archive cannot establish live flags, mounted media persistence, bucket policy, CDN origin, TLS, cache headers or signed URL expiry.

`apps/media/utils.py.clean_media_url` **already preserves valid absolute HTTP(S) strings**, including signed queries, before legacy recovery. `resolve_media_url` resolves strings/FieldFiles, but its broad exception fallback can return a storage name after URL generation fails. That string can look usable while no accessible object exists. Do not report a usable image merely because the resulting field is nonempty.

Flutter preserves signed URLs, uses bounded aspect-preserving decodes and a 120-entry/64-MiB cache budget. Network/decode errors correctly choose fallback. There is no new query-based cache busting that could invalidate signatures. Replacing bytes at an unchanged URL can retain cached content; prefer immutable replacement object keys and correct CDN validators. Evicting a base `NetworkImage` alone does not establish eviction of every resized variant or CDN cache.

## 4. Precise backend follow-up / المطلوب من علي

### A. Disambiguate approved ad posters (confirmed source issue)

In `apps/home/serializers.py`, change `FeaturedAdSerializer.get_image_url` to avoid exposing video bytes as an image. This proposed method uses existing fields; it does not require a database migration:

```python
def get_image_url(self, obj):
    request = self.context.get("request")
    # image is the existing independent poster URL when supplied.
    if obj.image:
        return resolve_media_url(obj.image, request) or ""
    asset = obj.media_asset
    if obj.media_type == "image" and asset and asset.file:
        return resolve_media_url(asset.file, request) or ""
    return ""

def get_video_url(self, obj):
    request = self.context.get("request")
    if obj.media_type != "video":
        return None
    if obj.video_url:
        return resolve_media_url(obj.video_url, request)
    asset = obj.media_asset
    if asset and asset.file:
        return resolve_media_url(asset.file, request)
    return None
```

Validate poster input as an image reference and video input as approved video at the admin write serializer. A future generated poster should have a distinct field/object and documented availability; do not invent a frontend API for extracting it. Preserve placement ownership, moderation, tier, active status and display order. Subscription directory priority must not create a fabricated paid placement.

**بالعربية:** لا يرجع `image_url` ملف MP4. يرجع الملصق الحقيقي أو قيمة فارغة، ويُرجع الفيديو في `video_url` فقط. لا يغيّر الإصلاح صلاحيات الإعلان أو اعتماده أو ترتيب الاشتراك.

### B. Real clinic gallery (confirmed source limitation)

Both public `get_gallery_images` methods currently return only the cover as a one-item list (`apps/clinics/serializers.py:81,201`). `clinic_gallery` exists as a media type, but those serializers do not enumerate ordered gallery records. Flutter can display real gallery URLs when supplied; the archive does not establish independent gallery management. If required, add an explicitly owned, ordered clinic-gallery relation with public read serialization and clinic-scoped create/delete/reorder permissions. Do not reinterpret every uploaded asset as published gallery content.

**بالعربية:** قائمة المعرض الحالية تكرر الغلاف فقط. يلزم عقد مستقل للصور المنشورة وترتيبها وملكيتها إذا أُريد معرض متعدد الصور؛ لم نبنِ مسارات وهمية في Flutter.

### C. Verify persisted references, access and deployment (unverified live conditions)

For one authorized synthetic record per entity, compare upload response → saved database reference → create/PATCH response → fresh list/detail/Home response → actual media HTTP body. Confirm MIME and genuine decoding; test new URL, explicit clear, reload and process restart. Check local durable volume or object presence, CDN routing and signed expiry. Return controlled validation/storage failures; emit only redacted structured server diagnostics. Never log signed URLs, patient text or credentials.

The profile serializer's string branch validates absolute URL syntax but reinserts references after normal field validation. Retain the existing security handoff requirements for ownership, media type and VIP authorization on **every reference path**, including strings; syntax validation alone is not asset authorization. This task does not modify that security architecture.

**بالعربية:** يجب فحص النشر والتخزين والملكية وصلاحية الرابط فعلياً. التحقق من صيغة الرابط لا يثبت ملكية الملف ولا صلاحية رفع فيديو VIP. أخطاء التخزين ينبغي أن تظهر كفشل واضح، لا كرابط تخزين احتياطي يوحي بنجاح الصورة.

### D. Source content quality

CMS titles/descriptions such as `anything`, empty brand/sponsor names, missing portraits, absent covers and unlicensed media require content-owner review. Flutter preserves actual supplied text and does not rewrite it into invented medical marketing. No supplied production dataset established which live records contain these values. Product/practitioner preview calibration images are test fixtures only and never seed production records.

**بالعربية:** محتوى مثل `anything` والصور الناقصة مشكلة بيانات مصدر تحتاج مراجعة صاحب المحتوى. لا نستبدلها بادعاءات طبية أو تقييمات أو صور مصطنعة داخل التطبيق.

## 5. Redacted evidence / أدلة منقّحة

Run locally on an authorized API JSON export:

```bash
dart run tool/media_contract_diagnostics.dart response.json
```

The [example diagnostic output](previews/media_first/redacted_fixture_diagnostics.json) is generated from a synthetic fixture, not a live API response.

Output contains only whitelisted media field names and booleans/classifications (`supplied`, source kind, resolved HTTP, query present). No URLs, hosts, paths, IDs, names, notes or query values are emitted. It is opt-in local tooling, not production telemetry, and cannot prove HTTP reachability. `test/media_interaction_polish_test.dart` asserts secret values cannot leak through it. See [MEDIA_FIRST_VISUAL_ACCEPTANCE.md](MEDIA_FIRST_VISUAL_ACCEPTANCE.md) for rendered evidence and environment limits.
