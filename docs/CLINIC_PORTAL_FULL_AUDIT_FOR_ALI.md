# Clinic Portal contract remediation — handoff for Ali / تسليم تدقيق بوابة العيادة لعلي

Date: 2026-10-23 (Asia/Damascus). Flutter base: `origin/main` at `b402d3bf7cc46c73cc1f142c7e93c4066e92d594`. Dedicated branch: `codex/clinic-portal-contract-remediation`. Release Readiness PR #11 remains separate. No Django/native signing files were changed.

## Decision / القرار

**P0 category CRUD is BLOCKED BY BACKEND, not fixed end to end.** Django d1023b0 provides active global category reads, but neither clinic nor Super Admin category write APIs. The broken Add/Edit/Delete workflow is removed; clinics can browse/search/select existing categories. This does not prevent treatment creation when a valid active category exists. Creating a missing category still requires an authorized server-side workflow.

**إنشاء وتعديل وحذف التصنيفات محجوب بسبب عقد الخادم.** التصنيفات مشتركة بين العيادات وليست مملوكة لعيادة واحدة. لا توجد واجهة كتابة للعيادة أو للسوبر أدمن في النسخة المرفقة. أزلنا الأزرار المضللة وحافظنا على اختيار التصنيفات الموجودة. لا ندّعي إصلاح CRUD قبل إضافة عقد مصرح به ونشره. يمكن إدارة التصنيفات حالياً عبر Django Admin بصلاحياته المناسبة، وليس عبر واجهة كتابة Flutter غير موجودة.

**Confirmed Flutter corrections:** category route probing removed; treatment selection/decimal prices/practitioner assignments/moderation preservation fixed; acknowledged catalog writes cannot be overwritten by an older catalog GET; clinic multi-image gallery and supported profile video editor added; stale-session form submission and changed-session delete success guarded; fabricated specialty/description defaults removed. Approved Patient/Super Admin UI, authentication infrastructure, preferences and signing remain unchanged.

**الإصلاحات المؤكدة في Flutter:** منع محاولات الكتابة على مسارات غير مدعومة، اختيار تصنيف صريح، حفظ كسور السعر وتعيينات الممارسين وحالة المراجعة، حماية نتائج الحفظ من تحميل قديم، معرض متعدد الصور وفيديو الملف المدعوم، حماية الجلسات ومنع نجاح وهمي بعد تغييرها، وإزالة أوصاف تخصص/عروض مختلقة.

## Evidence boundary / حدود الإثبات

- Source authority: user-supplied `AESTHETIC_WAY_BACKEND_SOURCE_d1023b0.zip`, SHA-256 `bf2a2855e672ee68e52cd16933c1c1e6a0e7b4ed95f5cf47ae5d4fe695b6c750`. Commit label is supplied by the owner; the archive is not a Git checkout. Older ca15dc6 limitations were rechecked against this source.
- All **393 backend file hashes unchanged**, including after execution. Django imports disabled bytecode writes; tests use testing settings, disposable in-memory SQLite/local test media, synthetic users and clinics. Nothing was deployed or written to production.
- [Controlled request evidence](clinic-portal-audit/controlled-django-contracts.json): **69 real Django APIClient responses**, using actual URL routing, permissions, serializers, database and file validators. `force_authenticate` bypasses JWT issuance only; it does not bypass object permissions. This is not a live mobile-to-server integration test.
- Supplied backend regression suites: **96 passing** portal/media/lead tests, plus **9 passing** additional media-hardening tests. Python 3.12.14, Django 5.2.4, DRF 3.15.2, pytest 9.1.1 (not an exact production dependency lock). Flutter results and CI provenance are recorded in [verification](clinic-portal-audit/VERIFICATION.md).
- [Actual Flutter-rendered comparisons](clinic-portal-audit/RENDERS.md) use explicitly synthetic QA fixtures and existing licensed test photos. They are not production photographs, Android device screenshots, storage evidence, or store-listing assets. Video native platform events are mocked in widget tests; Django separately parses a real 2-second neutral MP4.
- No live authenticated clinic response, approved test credentials, physical device or production Cloudflare R2 access is available here. The environment does not allow requests to `aestheticway.ae`. **Live HTTPS/CDN delivery, actual native picker/codec behavior, process-restart persistence on a device, and the deployed backend version remain UNVERIFIED.** Reopening a widget and new local Django GETs are verified separately; do not call them a full device restart.
- User-reported physical Android QA from the release task: patient submitted a consultation; it appeared in My Requests and Clinic Portal; clinic changed it to Contacted and Closed. This is owner-reported evidence, not a test performed in this audit. The category failure was also owner-reported; no production HTTP trace accompanied it. No new physical media QA is claimed.

**العقد المحلي مثبت، أما التسليم الحي فغير مثبت:** اختباراتنا محلية ببيانات اصطناعية وصلاحيات حقيقية داخل Django. لا تثبت نشر d1023b0 أو وصول الملفات من R2 أو عمل المعرض بعد إعادة تشغيل جهاز حقيقي. اختبار دورة الاستشارة على أندرويد منقول عن صاحب المشروع فقط. لم نستخدم بيانات مرضى أو رموز دخول في الأدلة.

## P0 category root cause / السبب الجذري للتصنيفات

Original Flutter chain (`category_repository.dart` on base):

1. Trim both names and POST `clinic-portal/categories/`.
2. On 404/405/501, POST the same JSON to `categories/`.
3. On edit/delete, probe corresponding detail routes. Some old unit tests supplied fictitious successful write adapters; those did not describe d1023b0.

Exact original POST body for the reported inputs (the same shape was used for PATCH):

```json
{"name_en":"skin care","name_ar":"عناية بالبشرة"}
```

Controlled context: authenticated active `clinic_admin`, one active membership in Clinic A; no unusual slug/name validation prerequisite.

| Request | Actual local status/body | Interpretation |
|---|---|---|
| `POST /api/v1/clinic-portal/categories/` | 404, `text/html`, no matching route | No clinic category API exists. Routing stops before serializer validation. |
| `POST /api/v1/categories/` | 405, `{"error":{"code":"API_ERROR","message":"Method \"POST\" not allowed."}}` | Public list view has no create operation. No field errors are returned. |
| `PATCH /api/v1/categories/<uuid>/` | 404, HTML route miss | No public detail writer exists. |
| `GET /api/v1/categories/` | 200, paginated active global records | Existing active UUIDs can be assigned to treatments. |

Authoritative source anchors in d1023b0:

- `api/v1/urls.py`: public categories include; no clinic category routing and no admin taxonomy writer.
- `apps/treatments/urls_categories.py`: only empty-path `CategoryListAPIView`.
- `apps/treatments/views.py::CategoryListAPIView`: `ListAPIView`, `AllowAny`, active list/search.
- `apps/treatments/serializers.py::PublicCategorySerializer`: every public field read-only (`id,name_en,name_ar,slug,icon,display_order`).
- `apps/treatments/models.py:7` Category has no clinic FK; English name max 200, Arabic optional max 200, globally unique slug max 220. Names are not themselves unique in this schema.
- `apps/treatments/models.py:49` Treatment.category currently uses **CASCADE**, so deleting shared categories through a future writer/Django Admin can delete treatments from multiple clinics. **Do not expose clinic delete permissions.**
- `apps/treatments/portal_serializers.py:20` accepts an active category UUID; `category_id` is only a compatibility alias, not a separate database field.

This is a **missing-route/method/ownership contract**, not a demonstrated duplicate-name, missing slug, malformed Arabic, or multipart problem. The generic device message obscures this. Creating a slug in Flutter cannot create a missing route. Current `CATEGORY_WRITES_UNSUPPORTED`/405 is an explicitly **local guard**, not a fabricated server reply.

**السبب ليس الاسم أو اللغة أو حقل slug مفقوداً:** رفض المسار والطريقة يحدث قبل التحقق من الحقول. إضافة slug في Flutter أو إرسال POST إلى المسار العام لن يحل المشكلة. لا يوجد أيضاً مسار لطلب تصنيف جديد من العيادة. تعديل تصنيف عالمي يغيّر عرضه لجميع العيادات؛ وحذفه حالياً قد يحذف علاجات بسبب CASCADE.

Category create-success/400-field-error/403/duplicate-slug/edit/in-use-delete API cases cannot truthfully pass against the supplied API because the writers do not exist. They are Ali acceptance cases below. Flutter instead tests no unauthorized probing, no fake IDs, selection persistence, paginated search/errors, closing sheets, keyboard/RTL/theme behavior, and explicit local rejection. No category success test was skipped or replaced with fake production success.

## Full Clinic Portal contract matrix / مصفوفة العقود

Prefix below: `/api/v1/`. Catalog collections use `count,next,previous,results` with page/page_size (Flutter fixed 20; backend ceiling 20). Detail/mutation responses are flat objects; DELETE returns 204. `CP` = `IsClinicPortalAccess` plus session-derived clinic and object-scoped queryset. This backend permission also admits `clinic_staff` and Super Admin; see role-policy finding B4. Flutter routes retain role isolation.

Common handled failures: 400 `VALIDATION_ERROR` + `error.fields`; 401 authentication; 403 `PERMISSION_DENIED`/clinic access rejection; 404 `NOT_FOUND` for foreign/missing scoped objects; 405 `API_ERROR`; 429 `RATE_LIMIT_EXCEEDED` with retry info. Router misses outside DRF may be HTML. Some explicit view responses use top-level `error/message`; do not assume every response is the standard exception envelope. `ApiException` already sanitizes/normalizes these; no auth header or raw server trace is displayed.

| Screen/component → Flutter function | Method/path → Django implementation | Role/ownership | Request → response; paging | Audit result / owner |
|---|---|---|---|---|
| Dashboard → `ClinicLeadsRepository.getDashboard` | GET `clinic-portal/dashboard/` → `ClinicDashboardAPIView` | CP, one clinic | none → clinic/setup, `leads`, `catalog` and operational aggregates; flat | Nested models match. Dashboard refetches on return after acknowledged catalog writes. No fabricated stats. |
| Shell badges → `getBadgeCounts` | GET `clinic-portal/badges/` → `ClinicBadgesAPIView` | CP | none → new/unread/contacted/closed/total counters; flat | Existing badge model preserved; backend unread currently corresponds to new. Failures preserve prior data. |
| Profile → `getClinicProfile/updateClinicProfile` | GET/PATCH `clinic-portal/profile/` → `ClinicProfileAPIView`, `ClinicProfilePortalSerializer` | CP; clinic selected server-side | name_en/ar, description_en/ar, phone, whatsapp, email, website, address_en/ar, city, emirate, latitude/longitude, google_place_id/maps_url, logo/cover/video → profile + read-only setup/gallery/Google metadata | JSON for text/null, multipart for actual files. Flutter exposes a subset; omitted fields preserved. Read-only subscription/moderation/Google ratings are not edited. `emirate` **is writable** in d1023b0. |
| Map → profile editor / `_updateClinicLocation` | Same profile PATCH | Same clinic | confirmed coordinates (7 decimal places), addresses/city/emirate and generated maps URL → updated profile | Real saved coordinates only; chooser defaults are not auto-saved. Duplicate guard/loading and opening-session validation added. Public maps client sends no JWT. Google Place ID enrichment is a separate backend dependency. |
| Setup → `getSetupChecklist/submitProfileForReview` | GET `clinic-portal/profile/setup-checklist/`; POST `.../submit-for-review/` → `ClinicSetupChecklistAPIView`, `ClinicSubmitForReviewAPIView` | CP | POST `{}` → setup status/submitted time/message; incomplete 400 `INCOMPLETE_ONBOARDING`, missing_items | Server remains authority. Existing offline/local checklist is approximate; submit is never fake success. See F1 about optimistic completeness and branch UI. |
| Branch adapter → `getBranches/createBranch/updateBranch/deleteBranch` | GET/POST `clinic-portal/branches/`, PATCH/DELETE `<uuid>/` → `ClinicBranchPortalViewSet`, `ClinicBranchPortalSerializer` | CP; clinic FK injected, foreign IDs out of queryset | name_en/ar, address_en/ar, city, phone, lat/lng, place ID/maps URL, is_main_branch/is_active → branch object; paginated list | Backend CRUD tested. Current Patient/Clinic map editor edits **clinic** location, not branch rows. No dedicated branch CRUD UI is exposed; service only loads page 1. **Remaining Flutter capability F1**, not a missing Django writer. |
| Staff → `get/create/update/deletePractitioner` | GET/POST `clinic-portal/practitioners/`, PATCH/DELETE `<uuid>/` → `ClinicPractitionerPortalViewSet`, `ClinicPractitionerPortalSerializer` | CP; clinic injected; soft delete | name_en/ar, title_en/ar, bio_en/ar, speciality_en/ar, type doctor/nurse/licensed_professional, status, display_order, avatar/media_asset → id + same + avatar_url/timestamps | Existing native single portrait editor supported. No gallery/video/ratings/years/languages fields. No license UI or license payload. Empty specialty stays empty; quick editor no longer overwrites title with invented certification. |
| Categories → `CategoryRepository.getCategories`, read-only directory | GET `categories/` → `CategoryListAPIView`, `PublicCategorySerializer` | Public active global taxonomy | search/page → six read-only fields; pagination | Read/select works; Add/Edit/Delete **P0 BLOCKED, Ali B1**. No clinic-specific ownership or category-request API. Super Admin categories screen stays read-only. |
| Treatments → `get/create/update/deleteTreatment` | GET/POST `clinic-portal/treatments/`, PATCH/DELETE `<uuid>/` → `ClinicTreatmentPortalViewSet`, `ClinicTreatmentPortalSerializer` | CP; clinic injected; practitioners must match clinic | category UUID + name_en; optional name_ar, descriptions, nullable decimal price, is_active/status, practitioners UUID[] → id/category/category_name + fields/timestamps | Corrected explicit UUID, no fallback-first category; preserve cents and existing M2M; no silent reactivation; omit status on edit. Search, category filter, page metadata match. No branch/duration/image/video contract. Foreign practitioner 400; foreign treatment operations 404. |
| Offers → `get/create/update/updateOfferStatus/deleteOffer` | GET/POST `clinic-portal/offers/`, PATCH/DELETE `<uuid>/` → `ClinicOfferPortalViewSet`, `ClinicOfferPortalSerializer` | CP; own treatment/media | title_en, original_price, offer_price, starts_at, ends_at; optional localized fields, image/media_asset, own treatment, status/is_active → same + image_url/id/timestamps | Valid promotional prices/dates, not lead scheduling. End before start/negative price rejected. Native single image only; descriptions no longer fabricated. No video or package-gallery field. |
| Products → `get/create/update/deleteProduct`, `toggleProductAvailability` | GET/POST `clinic-portal/products/`, PATCH/DELETE `<uuid>/` → `ClinicProductPortalViewSet`, `ClinicProductPortalSerializer` | CP; clinic-owned legacy content only | localized name/descriptions, brand_name_en/ar, sponsor_company, image/media_asset, status/is_active → image_url and content | Backend really supports clinic-owned CRUD; **not a global independent-brand endpoint**. No commerce added. Repository now drops price even if a caller supplies it; no product prices/actions shown. Backend legacy public price field is B7. |
| Articles → `get/create/update/deleteArticle`, publish toggle | GET/POST `clinic-portal/articles/`, PATCH/DELETE `<uuid>/` → `ClinicArticlePortalViewSet`, `ClinicArticlePortalSerializer` | CP; optional author must belong to own clinic | title_en/ar, content_en/ar, author_practitioner UUID/null, cover_image/media_asset, is_published, published_at/status → same + slug/cover_image_url/id | Native single cover; paged author selector. Backend sets published_at on first publication. No video/gallery. Public detail available only if publication/moderation/clinic eligibility permits it. |
| Leads list/detail → `ClinicLeadsRepository.getLeads/getLeadDetail` | GET `clinic-portal/leads/`, `<uuid>/` → `ClinicLeadViewSet`, `ClinicLeadListSerializer/ClinicLeadSerializer` | CP, own clinic; Super Admin read-only global exception | status/search/page/page_size; backend also branch/lead_type → lead summaries/detail; detail embedded collections bounded, separate pages supported | Existing real totals/search/pagination preserved, no fake patient leads. Clinic operational reference display retained. Patient display changes in PR11 are separate. |
| Lead Contacted/Closed → `updateLeadStatus` | PATCH `clinic-portal/leads/<uuid>/` → `partial_update`, `LeadStatusUpdateSerializer` | clinic operational roles; Super Admin denied mutations | `{"status":"contacted"}` or closed/new → full updated lead | Source d1023b0 full response compatible; Flutter retains old partial-response compatibility. UI duplicate guard, rollback on rejection. History written server-side. No booking dates. |
| Internal notes → `addLeadNote/getLeadNotes` | POST/GET `clinic-portal/leads/<uuid>/notes/` → `notes`, `LeadNoteSerializer` | scoped lead; Super Admin read-only | `{"note":"trimmed text"}` → new note object; GET paginated notes | Inputs retained on failure; no patient note exposure. History GET exists server-side but no dedicated history UI. Phone/WhatsApp use sanitized existing contact launcher. |
| Gallery → `ClinicMediaRepository.getGallery/uploadGallery/deleteGallery` | GET `media/`; POST `media/upload/`; DELETE `media/<uuid>/` → `MediaAssetListView`, `MediaUploadView`, `MediaAssetDetailView` / serializers | authenticated, `CanUploadMedia`, `CanManageMediaAsset`; active clinic scope | see media matrix below → asset UUID + media_type/clinic_id/MIME/url/metadata; paginated GET | **Flutter missing multi-image workflow fixed.** Additive uploads; individual delete; no gallery replacement PATCH or invented reorder. |
| Profile video/cover → `updateShowcaseVideo/updateClinicCover` | PATCH `clinic-portal/profile/` → profile serializer video validator | CP + VIP entitlement for nonempty video | multipart `video_ad_file` or JSON null; independently cover_image → authoritative profile | **Flutter supported native video workflow added.** No fake ad-campaign publishing or independent profile-poster field. |
| Shared uploads → `MediaUploadService.uploadImage`, `_resolveMediaAssetPayload` | POST `media/upload/`, then catalog POST/PATCH | session checked before writes, backend owner/type checks | multipart actual file/media_type/[clinic_id], then media_asset UUID + canonical URL → image fields | Existing correct native upload path retained. Omission preserves, null clears both FK and legacy URL. Signed URLs unchanged; no manual URL fields added. |

## Dedicated media-capability matrix / مصفوفة الوسائط

All selected photos use `LuxuryImagePickerField`; gallery adds `onImagesSelected` without changing existing single-image callers. Camera is offered for still images where the platform supports it. Video uses native device gallery selection; camera video recording is not required or exposed.

| Content | Backend d1023b0 actual support | Flutter editor and persistence | Patient delivery and exact limits | Remaining dependency |
|---|---|---|---|---|
| Clinic logo | `Clinic.logo` ImageField, profile multipart `logo` | Existing picker retained; explicit unchanged/replace/clear distinction | Portal/public clinic serializers resolve logo; native decode tested | Live R2/native/restart unverified; B3 validator parity |
| Clinic cover | `Clinic.cover_image` ImageField, multipart `cover_image` | Existing profile picker + isolated cover update in media screen | Cover is an image; may serve as video fallback poster, never the video itself | No independent profile poster field (B2); live verification |
| Clinic **multi-image gallery** | MediaAsset with `clinic_id`, `media_type=clinic_gallery`, image MIME; profile/public `gallery_images` computed read-only | **New** multi-select/camera, queue previews/removal, append real uploads, load existing pages, individual delete/confirmation, partial retry/progress | Public first **10** images in oldest-first server order; cover fallback if none. UI limits new selection to remaining public slots | No atomic draft save/reorder/association PATCH; immediately public. More-than-10 legacy assets are still browseable/deletable through pagination. B2 |
| Practitioner | Single avatar URL + typed MediaAsset FK; avatar_url output | Existing single picker; upload → UUID+URL → save; editor initialized from returned model | Public avatar_url, no practitioner rating or gallery | Multiple portraits/video unsupported; do not invent fields |
| Treatment/service | **No image/video/media FK at all** in portal serializer/model | Do not show unsupported media pickers | Patient’s existing category illustration is a placeholder, not treatment-upload proof | New approved model/serializer/public mapping/migration required only if product later authorizes it (B2) |
| Offer/package | One image URL + offer_image MediaAsset | Existing native picker; UUID association and explicit clear supported | Public image_url, image only | No package gallery or video field; unsupported |
| Clinic brand product | One image URL + product_image MediaAsset | Existing native picker, bilingual brand/sponsor fields; no price | Public showcase image_url, no commerce | Does not imply globally owned brand CRUD; B7 |
| Clinic article | One cover + article_cover MediaAsset | Existing native picker, optional own-clinic author | Public cover_image_url may be relative; Flutter resolves against API media origin | No video/gallery field |
| Entitled clinic profile video | `video_ad_file` FileField, actual MP4/MOV/WebM; profile PATCH; VIP guard | **New** native gallery → signature/size/duration preflight → explicit upload/save, lazy preview, retry/clear confirmation, reopen profile GET | Profile videoUrl/hasVideoAd; existing Home featured media renderer keeps video/poster separate and placement eligibility intact | Native codec + live R2 + actual campaign selection not verified. WebM duration needs working server metadata support; validator rejects unverifiable duration. |
| Featured advertisement campaign | FeaturedAd supports video separately from image poster/media asset; public Home serializer disambiguates MP4 | **No clinic campaign creation/edit/publish route exists.** Profile video is not silently promoted into a campaign | Existing eligible ads remain in Patient carousel; image_url never replaced with MP4 | Ali/product must define campaign ownership, entitlement, moderation, poster and deletion API before exposing management (B2) |
| Branch media / other content | No branch gallery or additional clinic-owned media relation demonstrated | No unsupported UI added | Nothing fabricated | Requires explicit contract before implementation |

Image policy on `/media/upload/`: JPG/JPEG/PNG/WebP, **5 MiB**, maximum **25,000,000 pixels**, verified decode + extension/MIME/signature. No required crop/aspect or minimum dimensions in the backend. Picker may resize to 1600px/85% before upload; server is authority. Frontend signature/size checks are UX checks, not security controls.

Video policy: MP4/MOV/WebM, **25 MiB**, advertised 15 seconds (server rejects beyond 15.5 seconds tolerance). Client probes duration and rejects zero/unknown/too long; backend independently validates. An installed native player is required on real devices. WebM/MOV depend on server duration extraction and device codec support; local evidence specifically validates MP4, not all codecs. No arbitrary file URLs or MP4-as-image behavior.

**إزالة الفيديو المحفوظ تبقى متاحة بعد انتهاء أهلية الرفع، دون السماح برفع بديل.**

**المعرض متعدد الصور مدعوم فعلاً وتمت إضافة واجهته في Flutter.** يربط الخادم كل ملف بالعيادة عند الرفع؛ ليست هناك مصفوفة gallery_images قابلة للحفظ. الصور تنشر فوراً ويمكن حذف كل صورة وحدها. الواجهة العامة تعرض أول عشر صور بترتيب الخادم، ولا يوجد عقد لإعادة الترتيب أو حفظ مسودة دفعة واحدة. فيديو الملف متاح فقط للاستحقاق المناسب، والغلاف ملف صورة منفصل لكنه غلاف العيادة نفسه، وليس poster مستقلاً. لا فيديو للعلاج أو العرض أو المقال أو المنتج أو الممارس في العقد الحالي.

### Evidence for the requested pipeline / إثبات دورة الوسائط

| Supported workflow | Select/preview (Flutter) | Upload/save/reopen/public mapping (real local Django) | What is **not** proved |
|---|---|---|---|
| Logo/cover | Existing native picker and image decoding/persistence regressions preserved | Real multipart PNG profile PATCH; portal GET + public clinic GET agree | Physical native picker, live R2, device restart |
| Multi-image gallery | Actual platform interface multi-selection callback; queued real files; partial failure/retry; two-photo renders; widget reopened from repository | Three real PNG uploads → UUIDs → fresh portal/public GET show three → foreign delete403 → own delete204 → fresh GET two | Native camera permission behavior, production download/cache/device restart |
| Practitioner/offer/product/article | Existing catalog image regressions cover binary upload payload, canonical asset mapping, clear and image precedence | Each real typed PNG upload → returned UUID+URL POST → editor-data GET → public detail URL → omitted PATCH preserves FK → null PATCH → portal/public GET empty | Every individual native editor operated on a physical device |
| Profile showcase video | Native picker interface + actual fixture signature reads, 2s platform event probe, lazy play/disposal, save/reopen/remove; separate cover assertion | Real MP4 bytes pass duration validator → profile multipart PATCH200 → fresh profile/public clinic GET retain .mp4 | Real native video decode, deployed Home placement or actual FeaturedAd generation |

The layered tests are intentional. They are not represented as one live end-to-end run. After deployment, Ali/QA must execute every row on a disposable owned clinic with native Android/iOS pickers, force refresh, terminate/relaunch, and view it from a different patient session. No genuine production image or rating has been invented to fill evidence gaps.

## Corrected Flutter defects / عيوب Flutter المصححة

1. `category_repository.dart`, category field/manager, portal service: removed unauthorized route fallback and fictitious local CRUD; paginated browse/selection stays functional. Missing-category blocked state is localized and explicit.
2. `clinic_catalog_repository.dart`, new `clinic_treatment_editor.dart`: no automatic first-category selection; only canonical category UUID is sent; decimal price retained (`250.75`, not `250`); blank optional price is null; invalid input does not become zero; fabricated default 750 removed. Names/descriptions trimmed; Arabic optional as Django permits.
3. Treatment PATCH no longer turns missing practitioner data into an empty list. Form initializes existing assignments, supports paged selection/removal, and sends an intentional complete list. No branch relationship is fabricated.
4. Treatment edit no longer forces suspended/rejected content to active; status omitted, is_active preserved, moderation message explicit. Genuine server errors keep all form fields and chosen category/staff intact. Duplicate save/picker guards and opening-session checks added.
5. `clinic_portal_service.dart`: acknowledged creates/updates/deletes invalidate an older page generation before updating the visible collection; no stale GET overwrites a successful treatment/catalog edit. Catalog mutation invalidates dashboard loaded state; dashboard refetches when selected again. Failed deletes after session switch rethrow rather than presenting success in the next account.
6. `clinic_media_repository.dart`, `clinic_media_screen.dart`, shared picker: previously no Clinic Portal multi-image association editor despite backend support. New management entry under Profile reads actual media IDs, checks MIME/clinic identity, appends uploads, deletes one saved asset at a time, retains failed queue items, and shows completed-file progress plus an indeterminate in-flight indicator. It does not falsely claim byte-level upload percentage. Confirmed uploads are removed from the retry queue; no automatic resend loop.
7. Profile video now has a native-file upload/preview/save/remove workflow with duration/size preflight. Player starts only on tap, pauses on lifecycle change and is disposed on exit/replacement/discard. Cover is separate; no nonexistent poster/campaign fields sent. Non-entitled clinics do not get an upload action; removal of an existing owned video remains available, matching Django null semantics.
8. Existing profile/practitioner/product/article/offer forms validate the opening session before saving. Map update adds duplicate-tap/loading guard and checks the opening session after the map chooser. Media/treatment editors stop displaying private state after identity changes.
9. Removed fabricated fallback specialties/certifications and offer descriptions. Blank server-supported text stays blank. Product repository drops any supplied price at its boundary; product UI remains a brand showcase.
10. Category sheet uses a single scrollable directory with explicit close action, keyboard insets, existing selection preservation, no broken nested Add Category dialog. Small-screen Light/Dark EN/AR renders and failure-preservation tests cover the replacement.

## Remaining findings and exact backend work / النتائج المتبقية وتغييرات الخادم

### B1 — P0: global categories need an authorized writer or request workflow (Ali + product owner)

**Existing:** source anchors above; no clinic write permissions, no category request model/API; global CASCADE delete is unsafe. **Desired:** retain global taxonomy ownership. Recommend **Super Admin-only global CRUD**, plus an optional clinic category-request review process. Do not give a clinic authority to rename/delete records used by other clinics.

**المطلوب:** تحديد ملكية التصنيف صراحة. التوصية هي CRUD عالمي للسوبر أدمن فقط، مع طلب تصنيف من العيادة إن كان مطلوباً. لا تجعل التصنيف المشترك قابلاً للتعديل أو الحذف من عيادة واحدة. هذه واجهات مقترحة وليست موجودة أو مفعلة في التطبيق.

Minimal implementation proposal (documentation only; **not deployed**, no Django files edited):

- New `apps/treatments/admin_serializers.py::AdminCategorySerializer`, `admin_views.py::AdminCategoryViewSet`, `urls_admin.py`; include at **proposed** `/api/v1/admin-portal/treatment-categories/` in `api/v1/urls.py` after matching actual admin naming convention. Permission `core.permissions.roles.IsSuperAdmin`; no fallback to public/clinic endpoints.
- Fields: UUID/read-only; name_en required trimmed nonblank ≤200, name_ar optional trimmed ≤200; slug read-only server-generated ≤220 stable on edit; display_order nonnegative; is_active bool. No arbitrary icon URL editor: keep existing icon read-only until typed native icon upload contract is defined.
- POST201 flat category; PATCH200; GET paginated `count,next,previous,results`; DELETE204 only if unreferenced; in-use409 with stable code. Prefer archive `is_active=false`; preserve existing links. Existing assigned archived category behavior must be specified: preserve relation during unrelated treatment PATCH; block assigning it to a new treatment. Public GET remains active-only.
- Atomic slug allocation from trimmed English name, suffix on collision (including simultaneous identical names); catch uniqueness races and return a controlled field error, not500. Decide normalized-name duplicate policy explicitly; current schema allows duplicates. Never infer it from slug uniqueness.
- Change `Treatment.category.on_delete` from CASCADE to **PROTECT**, `makemigrations`, review/apply migration, catch `ProtectedError` at the writer. No deletion of existing taxonomy/data migration is necessary; do not recreate UUIDs.

Illustrative safety core for Ali to integrate, not a complete copy-and-deploy view:

```python
# proposed apps/treatments/models.py relationship change -> migration required
category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="treatments")

# proposed global admin view; serializer and collision-safe slug creation required
from django.db.models.deletion import ProtectedError
from rest_framework import status, viewsets
from rest_framework.response import Response
from core.permissions.roles import IsSuperAdmin

class AdminCategoryViewSet(viewsets.ModelViewSet):
    permission_classes = [IsSuperAdmin]
    serializer_class = AdminCategorySerializer
    queryset = Category.objects.order_by("display_order", "name_en", "id")

    def destroy(self, request, *args, **kwargs):
        try:
            self.perform_destroy(self.get_object())
        except ProtectedError:
            return Response({"error": {"code": "CATEGORY_IN_USE",
                "message": "Archive this category or reassign its treatments first."}},
                status=status.HTTP_409_CONFLICT)
        return Response(status=status.HTTP_204_NO_CONTENT)
```

Proposed schema examples:

```json
{"name_en":"Skin care","name_ar":"عناية بالبشرة","display_order":0,"is_active":true}
```

```json
{"id":"<uuid>","name_en":"Skin care","name_ar":"عناية بالبشرة","slug":"skin-care","display_order":0,"is_active":true}
```

Optional request workflow: new CategoryRequest model (`clinic` FK from authenticated context, names, pending/approved/rejected status, resolved_category FK, reviewer/time/reason). **Proposed** clinic POST/list-own `/clinic-portal/category-requests/`; admin review endpoint separate. Never accept client clinic UUID to choose ownership. Unique pending normalized-name request per clinic or idempotency key; approve transaction creates/reuses global record. Requires a new table/migration and audit log. Do not add this frontend until Ali ships the contract.

Ali regression requirements: create201/reload; required-name400 fields; patients/clinic staff/admin denied global writes403; missing auth401; duplicates/concurrent slug collisions controlled; PATCH trims both languages/stable slug; in-use delete409; unreferenced204; archive hidden from public new selection but existing treatment not lost; no clinic A/B mutation of global records; optional requests list only own clinic and only Super Admin can approve. Then update Flutter capability and tests against deployed contract, not a guessed version flag.

### B2 — P1: gallery ordering/drafts and unsupported media relations (Ali + product)

Existing `apps/clinics/serializers.py::get_clinic_gallery_images`, `apps/media/models.py`, `urls.py/views.py`, profile SerializerMethodField: oldest10 asset URLs, immediate attachment at upload; DELETE physically removes a single file. No draft association update, explicit ordering, atomic batch save, campaign CRUD, treatment/offer video field or separate profile poster. Existing supported gallery is usable without any schema change.

**المعرض الحالي صالح للاستخدام دون تغيير Django.** إعادة الترتيب/المسودة/الملصق المستقل/إدارة الحملات ليست مدعومة. لا يجوز إرسال حقول جديدة وإظهار رسالة نجاح. لا تضف فيديو لكل أنواع المحتوى لمجرد أن رفع ملف عام يقبل امتداد فيديو.

If approved, use an ordered ClinicGalleryItem relation (`clinic`, `asset`, `position`, unique clinic+asset), migrate existing clinic_gallery assets in created_at/id order, validate same-clinic image MIME, list with asset UUID/order/URL, atomic replace/reorder with a revision/ETag to avoid lost updates. Proposed `PATCH /clinic-portal/gallery/ {"revision":n,"asset_ids":["<uuid>"]}` must explicitly define replace semantics and409 conflicts; do not send it from current Flutter. Existing upload remains authenticated. Add a separate draft/publication state if immediate publishing is unacceptable.

For campaign management, define clinic ownership FK, existing entitlement checks, image poster MediaAsset and separate video MediaAsset, moderation state writable only by admin, publication scheduling only for ads (never lead booking), owner-scoped list/create/PATCH/archive APIs. New relation/ownership may need migrations; inspect existing FeaturedAd model before proposing schema. No clinic campaign editor exists in this delivery. Treatment/other video needs explicit product authorization, matching model+serializer+public detail fields and independent file validators first.

Test additive upload not replacement; >10 legacy assets; reorder persistence/conflicts; draft not public; unrelated image deletion preserved; all foreign/private asset refs denied; MP4 never returned as image poster; expired/ineligible placement suppressed. Deploy migrations and preserve existing asset URLs/UUIDs; no destructive file cleanup during rollout.

### B3 — P1: upload policy parity and safe retry/storage lifecycle (Ali)

Files: `apps/clinics/portal_serializers.py` logo/cover ImageFields vs `apps/media/serializers.py`, `validators.py`, `portal_images.py`, `config/storage_backends.py`, production settings.

- Profile logo/cover ImageField decodes images, but does not explicitly apply the shared 5MiB/25MP/type policy used by `/media/upload/`. Add shared **image-only** validation for both; reject oversized/decompression/spoofed files even if bypassing Flutter. No migration needed; tests must include direct multipart attacks and unchanged-field PATCH.
- Generic media upload validates allowed bytes but should additionally enforce allowed MIME by media_type. Never allow a video in `clinic_gallery`/portrait/product_image/offer_image/article_cover. Current downstream gallery filters images and catalog mixin rejects non-image attachments; rejecting earlier avoids orphan/mislabelled assets. No new UI media type. Test400 with stable `error.fields.file` and no stored object.
- Client retries are manual and exclude acknowledged files. If a server saves but its response is lost, duplicate-free retry is **not guaranteed**. Add server-supported per-owner idempotency keys/content hash with persisted response/unique constraint and TTL policy (migration if new table/columns). Define proposed header and409 replay-conflict behavior before frontend adoption. No invented header is currently sent.
- Profile FileField replacement/null may leave old storage objects; unlinking a catalog image preserves MediaAsset for possible reuse, whereas DELETE/media physically removes it. Define reference-aware cleanup/retention and audit hooks. Do not eagerly delete shared public assets or rewrite signed URLs. Any GC table/migration depends on the chosen retention design.

**التحقق على الخادم إلزامي حتى مع وجود تحقق Flutter.** يجب توحيد حدود الشعار والغلاف وربط MIME بنوع الوسيط. إعادة المحاولة بعد فقد الرد قد تكرر الملف؛ الواجهة لا تدّعي ضمان عدم التكرار في هذه الحالة. تنظيف الملفات القديمة يحتاج سياسة تحافظ على الصور المشتركة والمراجع القائمة.

### B4 — P1: backend role policy is broader than strict portal product roles (Ali/security owner)

`apps/clinics/portal_permissions.py::IsClinicPortalAccess/get_user_clinic` allows `clinic_staff` for most catalog/profile writes and admits Super Admin; without membership the latter can fall back to the first available clinic. This is explicit backend behavior, not a demonstrated clinic-A-to-B IDOR. Leads intentionally let Super Admin read all but deny operational mutations.

Decide permissions explicitly per action. Use an administrator-only write permission for destructive catalog/profile/branch operations if staff must be read-only; retain approved operational staff lead permissions separately. Remove arbitrary-clinic Super Admin fallback for writes in favor of explicit admin endpoints/target selection. No migration unless a permission matrix is stored. Request schema must not accept clinic ownership from a clinic client; denied action403 without mutating objects. Tests: every role/action matrix, inactive/multi-membership, cross-clinic object404, no fallback clinic mutation. Flutter navigation cannot substitute for server authorization.

**الأدوار في الخادم أوسع من واجهات المنتج.** المطلوب مراجعة سياسة الموظف والسوبر أدمن لكل عملية ومنع اختيار عيادة عشوائية للكتابة. لم نثبت تسريباً بين عيادتين في الاختبارات؛ لا نساوي استثناء صلاحية مقصوداً بثغرة IDOR مؤكدة.

### B5 — P1 release verification: production R2/HTTPS delivery (Ali/infrastructure + device QA)

`CloudflareR2Storage` is present (S3v4, region auto, no default ACL, no overwrite, endpoint/bucket/custom_domain via settings). Presence is not deployment proof. Confirm actual default storage/env settings, public custom-domain HTTPS, bucket object permissions, response Content-Type, cache invalidation, URL expiry policy, and byte-range206 for video. Keep credentials private, bucket listing disabled, ownership checks on authenticated upload/delete. Public clinic imagery may be publicly readable by design; private content must remain private.

Use an approved disposable clinic. Upload native files, record **asset UUID/type and host/path without signed query strings**, save, reopen, refresh, terminate/relaunch, then verify public patient image decode/video and old/deleted asset policy. Inspect a minimal HEAD/GET of an owner-approved public asset without JWT; do not paste full signed URLs or patient data into tickets. If a deployed response differs from this source, capture sanitized field names/statuses and update the contract before blaming Flutter. No Django source change is inherently required for this verification; storage changes depend on observed configuration.

**وجود إعداد R2 لا يثبت عمله في الإنتاج.** يلزم اختبار الملفات العامة عبر HTTPS ونوع المحتوى والـRange للفيديو، ثم إعادة تشغيل التطبيق وفحص واجهة المريض. لا ترسل مفاتيح التخزين أو JWT أو روابط موقعة كاملة ضمن التقارير.

### B6 — P2: stable catalog ordering and moderation policy (Ali)

`portal_views.py` uses name-only ordering for treatments, display_order/name for practitioners, created_at for other catalogs. Add unique UUID tie-breakers to paginated lists to avoid duplicate-name/timestamp page instability. No schema migration required for correctness (review indexes separately); same request/response schema. Tests with >20 equal names/times and concurrent insertions, page boundaries without duplicate/missing rows.

Portal serializers currently permit moderation status writes; treatment UI now preserves existing status on edit. Product/offer/article/practitioner UI preserves existing status in edits. If only Super Admin should approve/reject, enforce server-side read-only moderation transitions and default pending for submissions. This is a policy decision, not a source-proven guarantee of independent moderation. Test403/400 forbidden transitions, clinic-scoped publication flags, unchanged status on ordinary PATCH, public visibility; migration only if stored defaults/data changes are approved.

**أضف ترتيباً ثابتاً باستخدام UUID، وحدد من يملك اعتماد المحتوى في الخادم.** حفاظ Flutter على حالة المراجعة لا يمنع عميلاً معدلاً من إرسال status طالما يقبله serializer.

### B7 — P2: brand showcase schema and patient push copy (Ali/product)

`apps/products/portal_serializers.py`/public serializer still expose legacy price and clinic-owned records. Flutter sends/displays no prices and adds no cart/contact/purchase UX. If independent brand ownership is required, define separate admin-owned brand/advertisement CRUD, serializer/permission/public filtering; do not reuse a clinic tenant implicitly. Deprecating legacy price in public schema needs compatibility review; dropping stored data requires a separate approved migration. Test no-commerce API/UI projection and role ownership.

`apps/leads/views/clinic_views.py::partial_update` still includes `#reference_code` in **patient push notification body** on Contacted. This conflicts with the owner's patient-facing reference-hiding preference, although clinic operational IDs should remain. Recommended copy change only: remove visible reference from patient title/body; preserve lead_id/reference internally in authorized notification data if needed for routing. No migration. Test patient-facing text contains no reference; owner checks and clinic tracking remain. This branch does not duplicate PR11's patient-screen changes.

**المنتجات تبقى عرض علامات تجميل فقط.** الحقول القديمة في الخادم لا تبرر إضافة تجارة. كما أن إشعار المريض ما زال يتضمن رقم الطلب في النص؛ احذفه من النص المرئي مع إبقاء التتبع الداخلي وصلاحياته.

## Remaining Flutter/product capabilities / قدرات واجهة متبقية

**F1 — P2, Flutter owner:** dedicated branch create/edit/delete UI is absent even though backend supports it; `loadBranches` currently reads only page1. Setup navigation sends branch/location users to Profile's clinic map. Do not describe that as branch CRUD. Add a separate paged branch manager if branch administration is required, with native phone component, same-clinic writes, SafeArea/keyboard/confirmation and backend main-branch consistency tests. This audit did not fabricate branch rows or extend the approved UI into a new branch-management product. Backend CRUD itself is verified by supplied tests.

The existing local setup fallback also treats partial identity/one branding image/map as complete more leniently than the server. It is only an offline estimate; backend submit may correctly return incomplete onboarding. A later focused change should display the checklist fetch failure/estimate explicitly and let only `is_ready_for_review` from a fresh server response enable submission. Do not weaken Ali's readiness validation.

**F2 — P2, QA:** changed editors are covered in EN/AR, Light/Dark, constrained height and keyboard inset tests. This is not a claim that every modal has been manually operated on a real phone. Existing large legacy profile dialogs have not been redesigned; screen-reader/native permission and codec QA remains required.

**الواجهات المتبقية ليست نقصاً في Django:** إدارة صفوف الفروع غير موجودة كواجهة مستقلة، وتقدير الإعداد المحلي تقريبي. لا ندّعي اكتمال هذه القدرات أو الاختبار اليدوي لكل نافذة على جهاز فعلي. الأولوية الحالية أصلحت خلل التصنيفات المضلل وأضافت إدارة الوسائط المدعومة دون تغيير التصميم المعتمد.

## Security and regression scope / الأمان والانحدار

- Actual source/tests enforce treatment/practitioner/offer/product/article/branch clinic-scoped querysets; current backend suites test permissions and CRUD. Controlled probes deny Clinic A get/PATCH/delete of Clinic B treatment (404), foreign staff assignment400, patient treatment write403, patient clinic media upload403, and foreign media delete403. Public image URL exposure for approved public content is intentional.
- Session epoch checks remain in service/network infrastructure. Added opening-session form guards prevent an editor opened under A submitting under B; media/treatment views clear or hide private state. Tests cover delayed save/session changes and old GET races. No JWT/auth-interceptor rewrite or token storage change was introduced.
- No Django, auth/signing/native configuration, patient design, referral, product commerce or lead-scheduling change. Mandatory Arabic success copy remains `تم إرسال طلبك وستتواصل العيادة معك`. Preference persistence and first-launch EN/Light tests remain in the full suite.
- No fabricated real photographs, ratings, certifications, descriptions, patients or operational records. QA photos/neutral video are test fixtures only and are not bundled production content.
- No permission bypass, live production mutation, token/header logging or test skip was used. Unsupported category success scenarios remain an explicit server acceptance gate, not a mocked claim.

## Safe implementation/deployment order / ترتيب التنفيذ الآمن

1. Review category ownership with the product owner. Ali implements B1 using Super Admin-only writes + PROTECT, acceptance tests and migration backup. Do not temporarily enable public POST or clinic global mutation.
2. Deploy migrations before writers. Verify API version/routes/permissions in staging with disposable QA roles. Capture sanitized statuses and UUIDs; do not include tokens or patient fields. Keep read-only category selection usable throughout.
3. Only after confirmed deployment add the corresponding authorized frontend management/request capability. Current Clinic Portal release must still state category CRUD unavailable until then.
4. Deploy B3/B4 policy hardening independently with compatibility tests. Verify existing legitimate uploads/operational staff permissions before enforcement; never loosen ownership for a demo.
5. Perform B5 per-type native media acceptance (select → upload → save → reopen → refresh → relaunch → patient display). Inspect public CDN response and bytes; repeat partial failure/retry/deletion and expired-entitlement cases.
6. Preserve PR11 signing/iOS/privacy changes on later integration. No automatic merge or store deployment is authorized by this task.

**انشر تغييرات التصنيفات بعد المراجعة والاختبار والترحيل، ثم فعّل واجهتها فقط بعد إثبات العقد الحي.** لا تفتح الكتابة العامة كحل مؤقت. اختبر التخزين والرفع بعد النشر على عيادة تجريبية مصرح بها، واترك هذه الـPR وPR11 مفتوحتين دون دمج تلقائي.

## PR11 overlap and exact manifest / التداخل وقائمة الملفات

This branch starts from merged PR10 `main`, not PR11. PR11 head reviewed: `872f20f7b0f2703f561069671e40c76e4488e6bc`. The overlap is `clinic_profile_screen.dart`: retain PR11 `AccountPrivacyActions` import/widget **and** this branch's media navigation, session guards, map feedback and honest defaults when integrated. PR11 API client, patient reference redaction, deletion/privacy controls, signing and iOS configuration are not copied or removed here. No release-readiness source files were silently overwritten.

[Exact changed-file manifest](clinic-portal-audit/CHANGED_FILES.txt) is generated relative to the stated base, including test fixtures, all 28 before/after PNGs, evidence, this handoff and CI render capture. [Verification and CI](clinic-portal-audit/VERIFICATION.md) record tested revisions/platform limits. Leave the dedicated Clinic Portal PR open and unmerged.
