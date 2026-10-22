# Updated backend contract review / مراجعة عقد الخادم المحدّث

Source: supplied `AESTHETIC_WAY_BACKEND_SOURCE_ca15dc6.zip` (SHA-256 `8c649026a3acdc0835ab8533312e210636153fb2632c41ed1a6b574400124826`). Compared by path and SHA-256 against `/workspace/work/media-first/backend-reference`, before Flutter integration edits. Archive source inspection is not deployment or live API verification. Django remains read-only.

## Changes since the previous snapshot / التغييرات منذ النسخة السابقة

| Contract | Previous snapshot | ca15dc6 source | Flutter consequence |
|---|---|---|---|
| Clinic gallery | Cover-only array | `get_clinic_gallery_images`: first ten `clinic_gallery` image assets ordered by creation/PK, distinct resolved URLs; cover fallback only when no gallery | Existing `gallery_images` mapping supported. Display genuine distinct photos only; hide single-photo controls. Previous “no real gallery contract” blocker is resolved in source. |
| Featured video poster | Video asset could be returned as `image_url` | Explicit image is poster; asset fallback only for image advertisements. Video-only advertisement has empty `image_url` and separate `video_url` | Keep separate poster and video fields and compatibility guard for old deployments. Previous poster ambiguity is resolved in source. |
| Profile gallery | No gallery response field | Portal profile now exposes read-only `gallery_images` | Gallery is managed through media assets, not a writable profile array. |
| Clinic video permissions | Some string references bypassed file-only validation | Non-VIP clinic video references and files rejected | Preserve internal eligibility; do not surface plan names to patients. |
| Upload permissions | Active membership required | Clinic user target must additionally be active and nondeleted; rejection is 403 | Existing authentication and clinic ownership must remain. Super-admin override is distinct. |
| Standard pagination | Default20, maximum100 | Default20, maximum20, supports both `page_size` and `per_page` | Flutter page20 remains compatible. Cursor paginator still maximum100; do not generalize the standard limit to every endpoint. |
| Media validation | 5MiB image,25MiB video, duration upper bound | Adds25MP image bound; rejects unknown/nonfinite/nonpositive duration; 15.5s grace upper bound | Native image selection and upload errors remain explicit. Server video validation requires working duration extraction. |

## Current public mappings / حقول العرض العامة الحالية

All routes below are under `/api/v1/`. Existing authenticated-only Flutter navigation is preserved even where Django declares `AllowAny`.

| Route | Source response | Flutter consumption |
|---|---|---|
| `clinics/`, `clinics/{id-or-slug}/` | `logo`, `cover_image`, `gallery_images`, `video_url`, `video_ad_file`; `google_rating`, `google_reviews_count`, `google_place_id`, `google_maps_url`; city/address/coordinates | `ClinicModel` separates logo from photography; accepts actual gallery and valid Google values. No legacy internal rating substituted. |
| `home/feed/` | Home clinic serializer inherits public clinic fields; advertisement has nested `clinic`, `image_url`, `video_url`, `subscription_tier` | Preserve actual advertisement and internal entitlement ranking. Public section title is permitted; commercial tiers remain hidden. |
| `products/` | `image_url` property resolves media asset before legacy `image`; localized brand and sponsor fields | Showcase only; no prices, shopping or direct product contact. |
| `offers/` | `image_url` from media asset before legacy image; actual `original_price`, `offer_price` | Genuine offer promotion and consultation lead only. |
| `articles/` | `cover_image_url` sourced from model `image_url`; actual nested clinic/author metadata | No invented author or reading time. |
| `practitioners/` | `avatar_url` from media asset before legacy avatar; actual type/speciality/clinic | No fabricated ratings, credentials or license display. |
| `treatments/` | Name/description/category/price and practitioners; no treatment image model field | Do not invent treatment photographs or reuse unrelated stock content as real treatment data. |
| `media/upload/` POST multipart | `file`, `media_type`, optional `clinic_id`; response asset `id`, `url` | Native upload returns asset UUID for catalog persistence; profile multipart fields remain separate. |

`apps/clinics/views.py` does contain review routes, but GET returns an unconditional empty paginated collection, and POST returns an acknowledgement without persistence. They are not Google review-body delivery or a functioning patient review system. Do not show fabricated review cards or enable a false submission flow. Working-hour fields and map raster images are not provided by the clinic model. Use real addresses/coordinates and the verified external Maps link; do not simulate map imagery.

## Remaining dependencies and evidence / الاعتماديات والأدلة المتبقية

- **Deployment not verified / النشر غير متحقق:** confirm the running build includes ca15dc6. No source inspection or fixture screenshot proves this.
- **Storage/configuration / التخزين والإعداد:** `USE_R2_STORAGE` and `USE_S3` default false; otherwise storage is local `FileSystemStorage`. Confirm the actual deployed mode. Filesystem mode requires persistent `MEDIA_ROOT` and HTTPS `/media/` serving in the deployment; do not assume R2 is enabled. عند استخدام التخزين المحلي يجب التحقق من استمرارية مجلد الملفات ومسار تقديمها عبر HTTPS في النشر الفعلي. persisted `MediaAsset.file` and profile ImageFields need existing objects, reachable HTTPS URLs, valid R2 bucket/custom-domain settings, correct MIME and actual decoding on a device. R2 backend is non-overwriting. Check upload response → linked UUID/field → public serializer → sanitized HTTP/decode outcome. Never include signed URLs in a shared diagnostic.
- **Google data/configuration / بيانات Google وإعداداتها:** supported fields require a genuine Place ID, valid Google API configuration and successful sync worker/beat. Null/zero values indicate missing or unsynced data, not grounds to invent a rating. Source support is verified; actual production values/provenance are not.
- **Content / المحتوى:** real gallery photos require uploaded `clinic_gallery` image assets linked to the correct clinic. A cover alone legitimately yields one photo. Staff/product/offer/article media needs its own persisted source; a logo is not a replacement photograph.
- **Source limitation / حدود المصدر:** no genuine review bodies or opening hours contract; acknowledge-only review POST must not be presented as persistence. These are separate from aggregate Google ratings.

## Exact Flutter corrections / تصحيحات Flutter المحددة

- Consultation clinic context previously resolved only `cover_image`; a valid gallery with no cover therefore showed an icon. It now uses `ClinicModel.primaryPhotoUrl` (real cover, otherwise first real gallery photo). A real-decoding widget regression covers `cover_image: null` plus a genuine gallery URL.
- Anonymous articles no longer acquire an invented Aesthetic Way author/publisher when neither author nor clinic identity exists. Supplied clinic identity remains publisher context, without pretending it is a practitioner.
- Logo, gallery, video/poster, product `image_url`, practitioner `avatar_url`, offer `image_url`, article `cover_image_url`, and Google aggregate parser mappings already match ca15dc6. They were retained, not rewritten to imply an unobserved parser defect. Response-shaped regression fixtures lock these contracts.
- Earlier preview-only article category and treatment image fields were removed from the fixture response because the actual public serializers do not provide them. No production photograph, category or reading time is fabricated to fill these gaps.

تصحيح عرض الاستشارة يستخدم صورة المعرض الحقيقية عند غياب الغلاف. كما أزيل اختلاق اسم مؤلف للمقال المجهول. بقية حقول الصور وGoogle متوافقة بالفعل مع المصدر الجديد؛ لا ندّعي إصلاح تكامل كان يعمل أصلاً، ولا نعتبر بيانات الاختبار دليلاً على الإنتاج.

## Contract details that are not new blockers / تفاصيل وليست عوائق جديدة

- Home feed is bounded separately: eight categories and ten each of ads, nearby clinics and offers; a five-minute server cache can delay visible changes. Standalone Home categories are unpaginated. These are distinct from standard page-number maximum20 and cursor maximum100.
- Google Places (New) sync writes rating, count, last-sync and sync-status fields. It does not populate clinic photographs or automatically create a Maps URL. Place ID and clinic map/location configuration remain real inputs. Inspect `GOOGLE_PLACES_API_KEY`, `GOOGLE_PLACES_SYNC_ENABLED`, `clinics.sync_google_places`, configured beat schedule and sanitized sync status; never share the key or raw diagnostic errors.
- Current public product source still serializes a legacy price. Flutter intentionally does not render it; cosmetic products remain independent advertising showcases. Public article serializers have no category or reading-time field. Clinic detail provides at most six staff/treatment summaries; full tabs use paginated scoped directories.
- Upload POST requires authentication and ownership; media detail uses object permissions. Public catalog views allow anonymous HTTP reads, but Flutter continues to require authenticated Patient navigation. No role isolation is relaxed. Clinic-user uploads to inactive/draft/suspended targets now fail403; a Super Admin has a separate override, not patient/clinic permissions.
- The new gallery implementation prefetches assets for public directory/detail and portal profile. Home now inherits gallery serialization but does not add equivalent gallery prefetches in its own querysets; this is a bounded source query-efficiency observation, not evidence of missing media or a new Flutter blocker.

الخلاصة التشغيلية: راعِ ذاكرة الصفحة الرئيسية لمدة خمس دقائق، والفصل بين صلاحيات رفع الملفات والصلاحيات العامة للقراءة. حقول الأسعار القديمة في استجابة المنتج لا تُعرض للمريض. الملخصات محدودة، والتفاصيل الكاملة تبقى ضمن قوائم مرقمة ومقيدة بالعيادة.

## Safe production evidence / جمع الأدلة بأمان

Safe public capture: `pwsh -File tool/capture_public_clinic_contract.ps1 -ClinicId <public-clinic-UUID> -OutputPath clinic-contract-sanitized.json` (check `Get-Help`/script parameters before running). It anonymously reads public clinic detail, first directory page and Home feed, emits an allowlist and hashed media paths, and excludes tokens, passwords, phone numbers and patient data. Do not add Authorization headers or paste raw responses. This environment cannot establish live delivery evidence for aestheticway.ae; obtain the sanitized output and test actual media on the affected device separately.

الخلاصة: دعم المعرض الحقيقي وفصل صورة الفيديو عن رابطه أصبحا موجودين في المصدر الجديد؛ لا يُطلب من علي إعادة تنفيذهما. يجب التحقق من النشر والملفات وإعدادات Google والبيانات الحقيقية على الخادم الفعلي. لا تغيير لملفات Django، ولا ادعاء بتحقق الإنتاج اعتماداً على الاختبارات الوهمية.
