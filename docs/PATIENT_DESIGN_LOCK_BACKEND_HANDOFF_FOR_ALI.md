> **Superseded contract findings:** see [ca15dc6 review](PATIENT_CA15DC6_CONTRACT_REVIEW_FOR_ALI.md). The cover-only gallery and video-poster ambiguity described below are historical and resolved in the newly supplied source. Live deployment remains unverified. / نتائج العقد أدناه تاريخية؛ راجع التقرير المحدّث.

# Patient design reference lock — backend handoff / تسليم اعتماد التصميم إلى علي

Reviewed 21 October 2026, Asia/Damascus. Django is read-only. Source archive SHA-256: `d3a676d464a75805651bbdef7b91d184e6dd6d02b75953267efe7418e7a28f22` (641 files). This is source-contract evidence, not proof of deployment.

تمت مراجعة عقود الأرشيف للقراءة فقط دون تعديل Django. وجود الإصلاح في الأرشيف لا يثبت نشره على الخادم.

## Verification boundary / حدود التحقق

Six anonymous public API GET attempts (`home/feed/`, `clinics/`, `products/`, `offers/`, `articles/`, `practitioners/`) were rejected by this execution environment's proxy: `Tunnel connection failed: 403 Forbidden`. This is **not an HTTP 403 observed from Django**. No live JSON, successful live upload, object-store access, device network trace or production image decode was available. The user confirmed that a sanitized live response cannot currently be supplied. Therefore the actual cause of absent media/ratings on the device remains unverified. Fixture screenshots validate Flutter layout/decoding only; they do not establish a production-data fix.

حُجبت الطلبات بواسطة سياسة شبكة بيئة التنفيذ، وليس لدينا دليل أن Django أعاد 403. لا تتوفر استجابة إنتاج أو تجربة رفع موثقة على الجهاز. لذلك لا ندّعي إصلاح سبب غياب صور وتقييمات الإنتاج اعتماداً على صور الاختبار.

## Verified contracts / العقود المؤكدة في المصدر

| Public data | Django source / Flutter mapping | Verified behavior |
|---|---|---|
| Clinic logo and cover | `apps/clinics/serializers.py:PublicClinicListSerializer.to_representation`; `ClinicModel.fromJson` | `logo`/`logo_url` and `cover_image`/`cover_image_url`: first nonblank valid string wins. Cover precedes actual gallery photographs; logo never substitutes as photography. Relative storage paths resolve against the configured API media origin. |
| Home clinics | `apps/home/serializers.py:PublicClinicSerializer(PublicClinicListSerializer)`; `HomeRepository` | Snapshot already inherits public directory fields. Flutter starts one bounded public directory read alongside Home and enriches records by the same clinic UUID; directory representation takes precedence. Compare Home/list/detail if deployment serializes these differently. |
| Gallery | `PublicClinicListSerializer.get_gallery_images` | Snapshot returns a one-element cover list, **not a genuine multi-image gallery**. Flutter deduplicates cover/gallery and reports the actual count; it does not invent a 12-image gallery. Multiple photographs require a real gallery data model/serializer or another supported public source in Django. |
| Clinic video | Public `video_url` and `video_ad_file` from clinic file field | Existing eligible placements remain internal. Active slide/tab/route, foreground, visibility, reduced motion, disposal and the 15-second limit are preserved. |
| Featured ads | `apps/home/serializers.py:FeaturedAdSerializer`; `apps/media/models.py:FeaturedAd.image_url`; `FeaturedAdApiModel` | A video asset can populate both image and video URL fields. Existing Flutter logic rejects the same video URL as a still poster when `media_type=video`; backend should return a distinct real poster if available. Do not put a video file in a supposed image field. |
| Catalog photos | Practitioner `avatar_url`/`avatar`, offer/product `image_url`/`image`, article `cover_image_url`/`image_url`/`cover_image`/`image`, treatment `image_url`/`image` | Public model/serializer aliases match Flutter. Valid nonblank strings retain precedence. Native paths, file URIs, bundled assets and bounded network decoding remain supported. Signed absolute URL query bytes are preserved. |
| Google Places | Clinic model `google_rating`, `google_reviews_count`; public list/detail and inherited Home serializer | Flutter accepts a finite Google rating 1–5; a supplied review count must be a valid positive integer for the rating badge. Missing count is not fabricated. Legacy/internal `rating`/`review_count` are not substitutes. No practitioner/product ratings are rendered. |
| Google sync | `apps/clinics/services/google_places.py:fetch_place_rating`, `sync_clinic`; `apps/clinics/tasks.py:sync_google_places`; `config/celery.py` | Requires a real `google_place_id`, configured `GOOGLE_PLACES_API_KEY`, enabled sync, Places API access/billing, and working worker/beat. Missing Place ID marks `NOT_CONFIGURED`. Only a successful fetch saves rating/count/sync state. |
| Maps and hours | Public Maps/place/coordinate fields; `ClinicModel.mapsUri`; localized working-hours aliases | Google Maps opens only from verified location data. No invented coordinates, operating hours, map tiles, review avatars or review narratives. This snapshot does not define the localized working-hours fields consumed by Flutter; they remain hidden unless genuinely supplied. Current archive has no public review-body/author endpoint; the reference's review-avatar strip is not implemented. |

## Ali: exact remaining deployment checks / التبعيات غير المتحقق منها

1. **Deployment parity:** compare the deployed Home/list/detail serializers, `apps/media/portal_images.py` scoped asset mixin and clinic profile parser with the supplied archive. Those fixes already exist in this snapshot; do not blindly duplicate old handoff patches.
2. **Persistence:** a clinic profile multipart PATCH uses `logo`, `cover_image`, `video_ad_file`; catalog media first uploads to `POST /api/v1/media/upload/`, then sends the returned asset UUID as `media_asset` plus the image/avatar/cover URL to the matching clinic-scoped create/PATCH endpoint. Confirm the saved DB reference, re-read the public record, and then verify the returned file. Text-save success alone does not prove image persistence.
3. **Delivery:** confirm configured MEDIA_URL/storage backend, proxy forwarded HTTPS host, bucket/custom domain/public read or valid signed expiry, Content-Type, non-HTML bytes, certificate and CDN reachability. Inspect image GETs and video range responses from the affected device. Never share signed query strings or storage credentials. Flutter does not bypass TLS, substitute fabricated URLs or retry unsafe writes.
4. **Google sync:** verify API key/billing restrictions and worker/beat health privately, correct Place ID, last successful sync/status/error. Public field presence is not evidence of genuine Google provenance: the archive's `seed_data.py` contains demo Google ratings. Ensure demo records/ratings were not seeded into production. Do not replace missing values with manual/fake reviews.
5. **Gallery/reviews:** full multi-image galleries and actual Google review narratives/avatars require supported real backend data. The Flutter redesign can ship with a single cover and authentic aggregate rating/count; no new Django endpoint was fabricated.
6. **Device evidence still required:** affected build commit, API hostname, anonymous public record field shape/presence, sanitized decode/HTTP status, and re-fetch after one authorized upload. Backend/storage credentials and patient/auth payloads must not be shared.

بالعربية: يلزم التأكد من النسخة المنشورة، ربط الملف بالسجل، صلاحية وصول الجهاز إلى الملف، وإعداد Places والمهام الدورية. لا نستطيع تأكيد هذه الحالات من الأرشيف وحده. المعرض الكامل ونصوص المراجعات تحتاج بيانات حقيقية يدعمها الخادم. لا تتطلب أعمال التصميم اختلاق واجهات أو تعديل Django.

## Safe Windows capture / التقاط آمن في PowerShell

Use the **public clinic UUID**, never a patient/lead/user ID. Run from the Flutter repository:

```powershell
.\tool\capture_public_clinic_contract.ps1 -ClinicId '<PUBLIC-CLINIC-UUID>'
```

Exact anonymous endpoints: `https://aestheticway.ae/api/v1/clinics/<UUID>/`, `https://aestheticway.ae/api/v1/clinics/?page_size=20`, `https://aestheticway.ae/api/v1/home/feed/`.

The script sends no JWT/cookies/passwords. It holds raw responses only in memory and writes an allowlist: clinic UUID, media field types/presence/hostname/path hashes, genuine numeric Google fields and configuration booleans. Names, phone/WhatsApp/email/address, patient data, raw object paths, signed queries and tokens are omitted. It reports only a status on errors, never an error response body. The bounded directory page may not contain this clinic; that is not evidence the record is missing. The resulting file is a **diagnostic summary**, not a fake API fixture or a replacement URL payload. Do not paste browser Network exports, authorization headers or raw API bodies.

استخدم UUID العيادة العام فقط. السكربت لا يرسل رمز دخول ولا يحفظ الأسماء أو أرقام الهواتف أو بيانات المرضى أو روابط التخزين الكاملة. يحتفظ بملخص آمن يُمكن مشاركته. لا تشارك ملفات HAR أو ترويسات Authorization. نجح اختبار التنقيح دون شبكة باستخدام PowerShell 7.5.4 محلياً على Linux، ويوجد اختبار مستقل في CI على Windows. هذا فحص للسكربت ببيانات اصطناعية، وليس تحققاً من استجابة الإنتاج.
