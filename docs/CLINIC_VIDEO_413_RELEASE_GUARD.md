# Clinic showcase video: HTTP 413 release safeguard / حماية رفع فيديو العيادة

Date: 2026-11-04 (Asia/Damascus). Base: current main `758f991bd78913dcee0cba6f532fdab96d410d3b` (includes merged PR17). Branch: `codex/clinic-video-413-release-guard`.

## Evidence and diagnosis

The owner reports a real Android release build can select/preview a gallery video but receives HTTP413 after **Upload and save video**. The actual file byte length, encoded request length, deployed limit, responding hop and correlated server log are not supplied. No production upload was attempted by this task. This investigation uses current Flutter code and isolated Flutter tests only; no Django source, settings or infrastructure was modified or treated as independently verified live behavior.

**Confirmed:** Flutter permits a video file up to **25 MiB = 26,214,400 bytes**, whereas the original caption said25MB. Multipart framing adds bytes beyond the file size. Local validation cannot establish the deployed maximum request size. HTTP413 reports that a server/intermediary rejected the request size; it does not establish whether Nginx, a CDN/WAF/hosting ingress, application middleware or another hop returned it. It is not evidence of a picker failure or an existing-video conflict.

**Suspected root cause:** the effective deployed request-body ceiling is below the actual multipart body. The rejecting hop and its configured threshold remain unverified. No evidence supports deleting an existing video first, an arbitrary smaller guaranteed file limit or a timeout-only fix.

## Exact Flutter path and request

| Stage | Current implementation and behavior |
| --- | --- |
| Select/validate | `ClinicMediaScreen._chooseVideo`: authenticated matching clinic profile refreshed; server-reported VIP entitlement required. Gallery `ImagePicker.pickVideo(maxDuration:15s)`. Existing file, nonzero length, <=25MiB, extension/signature checked by `MediaFilePolicy`. Native player probes nonzero duration <=15.5s tolerance. The picker option does not guarantee trimming/compression. |
| Queue/preview | `_videoPath` is local state; selection and playback are not a save receipt. Native file is not compressed, base64 encoded or uploaded during selection. |
| Explicit save | `_saveVideo` → `ClinicPortalService.updateShowcaseVideo(path)` → `ClinicCatalogRepository.updateClinicProfile({'video_ad_file':path})`. The new UI guard prevents this call when release-disabled or after a413 in the editor. |
| Payload | `MediaPayloadBuilder` uses `MultipartFile.fromFile`, filename `upload.mp4`, `.mov` or `.webm`; MIME respectively `video/mp4`, `video/quicktime`, `video/webm`. Exactly one file field **`video_ad_file`** for this operation; no gallery images, cover/logo, editable tier or poster bundled into this save. |
| Endpoint/headers | Authenticated **PATCH `https://api.aestheticway.ae/api/v1/clinic-portal/profile/`**. Dio generates `multipart/form-data; boundary=…`. AuthInterceptor clears an inherited JSON Content-Type for FormData, attaches JWT only to the allowed API origin, adds Accept/Accept-Language and disables redirects. No credentials in support output. |
| Transport | Existing video-specific send480s/receive120s defaults, progress, cancellation and generated X-Request-ID. `aw_no_video_body_replay` prevents JWT refresh from replaying the body; no automatic upload retry. Longer timeouts do not fix a body-size rejection. |
| Confirmation | PATCH response must match clinic identity, acknowledge a remote video and preserve cover identity. A **fresh authenticated private profile GET** must match that video and cover before the service updates state or reports verified saving. Errors preserve the selected file and do not fabricate success. |
| Replacement | Client uses the same PATCH/file field when an old video exists, without DELETE or nulling it first. This expresses replacement through the existing profile contract; it is not independent proof of current production replacement behavior. Existing tests cover acknowledged replacement and reload. Both new and replacement413 paths are now tested. |
| Removal | Explicit confirmation, JSON PATCH **`{"video_ad_file":null}`**, then matching fresh GET. No video file body; cover is not sent/changed. Playback and removal remain available under the release gate and existing authorization. |

## Chosen release action

`VideoUploadPolicy.clinicShowcaseUploadsEnabled` reads **`AW_ENABLE_CLINIC_SHOWCASE_VIDEO_UPLOAD`**, default **false in all build modes**. No release/preview helper or CI enables it. All production navigation constructs `const ClinicMediaScreen()` and therefore uses this default. The widget parameter is dependency injection for isolated enabled/disabled tests, not a remote permission or entitlement override.

- New uploads and replacements are unavailable by default. The localized, accessible notice explicitly says so; a selected video's upload control is disabled, with an additional handler guard against stale callbacks.
- VIP users can still choose a valid video for **local preview only**, retain/discard it, and see that it has not been saved online. The normal release screen no longer advertises25MB as an available upload promise.
- Existing saved-video playback, confirmed JSON removal, clinic cover/logo and all gallery image selection/upload/delete behavior remain intact. Basic/Featured/unknown-tier restrictions remain intact.
- If an explicitly enabled QA build gets413, that editor pauses further upload/replacement attempts, retains the file, displays real HTTP413 and safe support diagnostics, and cannot restart the upload from a captured old callback. Images and JSON removal remain separate.
- The QA-only enabled caption and local validation now use the correct **MiB** unit and distinguish local limits from the unverified effective server limit. File-size limits themselves are unchanged; image policy is unchanged.

Compression is not a dependable release fix without a verified ceiling and codec/quality/device validation. Splitting/chunking requires a documented backend contract, which the client does not have. Deleting first can destroy the working video without making the next request smaller. No such behavior or new upload endpoint was introduced.

This is a frontend release safeguard, **not a deployed server repair**. Already installed APKs remain unchanged and continue to need server remediation or a new approved build. No APK, signing configuration, key, app ID, backend or production data was changed/published by this task. Analytics emission remains at its existing disabled default.

## Ali handoff — exact server evidence and checks

1. Confirm deployed commit SHA and the actual ingress chain for `api.aestheticway.ae`. Correlate one owner-authorized failed attempt by UTC timestamp and the app's X-Request-ID, HTTP413 and coarse size band. Obtain file bytes and total multipart Content-Length (no file content, personal filename, local path, JWT, phone, raw body or signed URLs).
2. Identify the rejecting layer. Review effective Nginx `client_max_body_size` for the matching server/location and any more-specific overrides (`nginx -T` locally; share only redacted relevant directives). Check upstream status and the Nginx error such as `client intended to send too large body`. Empty upstream status suggests a pre-upstream rejection; an upstream413 requires tracing that upstream. Response branding alone is not proof.
3. If the supported app file maximum remains25MiB, every request-body ceiling must allow **25MiB plus multipart overhead**. A reviewed, route-appropriate Nginx `client_max_body_size 30m;` is an example compatible ceiling for this one-file request, **not a verified current setting or an instruction applied here**. Verify any CDN/WAF/LB/Hostinger ingress cap as well. Retain authentication, entitlement/rate limits and the independent per-file validator; do not make global upload sizes unlimited.
4. Check current Django/DRF multipart parser, explicit file validators/custom upload handlers, and middleware that reads the raw body. **`FILE_UPLOAD_MAX_MEMORY_SIZE` is a memory-to-disk spooling threshold, not the accepted file maximum.** `DATA_UPLOAD_MAX_MEMORY_SIZE` concerns non-file form-data/body reads depending on the code path; raising it alone is not a universal upload fix. Keep temporary disk space/permissions and bounded resource usage appropriate. Verify actual values/code paths before proposing a change.
5. Inspect narrowly redacted access/error logs: status, upstream_status, content_length/request_length, request_time/upstream_response_time and X-Request-ID. Do not log Authorization, request_body, tokens, signed URLs or private records. Review timeouts/disk/R2 only if correlated evidence supports them; this413 itself is not proof of R2 failure.
6. Return the responding hop, effective supported file/request ceilings, change/deployed SHA and authorized end-to-end evidence. A config statement or mock201/200 is not proof of a physical upload.

## التسليم لعلي — التشخيص والحماية

**المؤكد:** فشل الرفع على أندرويد بعد الضغط على الرفع والحفظ بحالةHTTP413 حسب اختبار المالك. قبول الملف ومعاينته محلياً لا يثبتان حفظه. يسمح Flutter بملف25MiB أي26,214,400 بايت، ويضيف multipart بيانات أخرى. لا نعرف بعد حجم ملف المحاولة أو سقف الخادم الفعلي أو الطبقة التي أعادت413؛ لا يجوز الجزم بأن السبب هو فيديو قديم أو Nginx تحديداً.

**حماية الإصدار:** العلم `AW_ENABLE_CLINIC_SHOWCASE_VIDEO_UPLOAD` معطل افتراضياً. رفع فيديو جديد أو استبداله متوقفان، مع الإبقاء على اختيار الفيديو للمعاينة المحلية وحفظ الاختيار عند الخطأ وتشغيل الفيديو المحفوظ وإزالته بتأكيد. لم تتغير صور المعرض أو الشعار أو الغلاف أو صلاحيات الأدوار. في QA المفعّل صراحةً، تؤدي413 إلى وقف محاولات الرفع الإضافية في المحرر نفسه، دون إعادة تلقائية ودون نجاح وهمي.

**العقد الحالي في Flutter:** ملف فعلي واحد باسم `video_ad_file` عبر PATCH إلى `https://api.aestheticway.ae/api/v1/clinic-portal/profile/`، مع boundary يولده Dio وتوثيق JWT. الاستبدال يستخدم الحقل نفسه دون حذف مسبق. الحذف JSON بقيمةnull، ولا يرسل الغلاف. نجاح الحفظ يتطلب إقرار PATCH ثم GET خاصاً جديداً يطابق الفيديو والعيادة والغلاف.

**المطلوب من علي:** نسخة النشر الفعلية، وسلسلة البروكسي، وسجل محاولة مصرح بها مرتبط بالتوقيت وX-Request-ID وحجم الملف والطلب دون أي أسرار. افحص `client_max_body_size` الفعلي وتجاوزات server/location وأي سقفCDN/WAF/استضافة، وحدد هل413 قبل upstream أم منه. إذا استمر حد الملف25MiB فيجب السماح بزيادة multipart؛ قيمة30m في Nginx مثال للمراجعة وليست إعداداً تحققنا منه. راجع validators وparsers وmiddleware وقراءة الجسم الخام. `FILE_UPLOAD_MAX_MEMORY_SIZE` عتبة نقل من الذاكرة إلى القرص وليس حد قبول الملف، ورفع `DATA_UPLOAD_MAX_MEMORY_SIZE` وحده ليس علاجاً عاماً. لا تنشر إعدادات كاملة أو JWT أو جسم الطلب أو روابط موقعة. لم نغير Django أو الخادم ولم نرسل رفعاً للإنتاج.

## Re-enable / physical Android acceptance

Keep the default off until Ali verifies the effective contract and explicit QA authorization exists. Only an approved QA build may use `--dart-define=AW_ENABLE_CLINIC_SHOWCASE_VIDEO_UPLOAD=true`; that flag does not bypass VIP/auth permissions. No helper was altered to set it. Reopening an editor or selecting a smaller file is not evidence the server is fixed.

Retest on the actual release/device/network with and without an existing video: supported files below and above2.5MiB, representative10/24MiB and a valid file at the25MiB boundary; record total multipart bytes. A26MiB file must fail locally with **no PATCH**. Check new/replacement PATCH acknowledgment → fresh matching private GET → reopen → process restart → patient playback, preserving cover and old video on rejection. Verify413/401/403/5xx/cancel do not fake success or auto-repeat, selection survives, and JSON removal/images still work. Do not claim production success from these synthetic tests.

## Verification

Final analyzer, affected-test, format/diff and exact-head CI results are recorded below and in the Draft PR before delivery. The taller release warning required the existing gallery-confirmation test to scroll its message into view; all persistence, single-POST and no-PATCH assertions remain intact. Earlier capture-heavy local runs also hit unchanged three-second native-fixture guards; those tests passed without increasing deadlines or dropping assertions in the subsequent checks. No live upload or server limit verification is claimed.


| Final local check | Result |
| --- | --- |
| Flutter toolchain | Flutter3.41.5 / Dart3.11.3, Linux |
| `dart format .` | 303 files, zero changes |
| `flutter analyze --no-pub` | Zero issues |
| Affected regressions:12 test files, `--concurrency=1 --reporter expanded` | **274 passed, zero failures** |
| New targeted scenarios | Nine: release default; four EN/AR Light/Dark previews without upload; two HTML413 states; saved-video playback/removal; one-file replacement |
| Existing oversized-video assertion | 26MiB rejected before native decoding and PATCH; original assertion/deadline retained |
| Separate gallery/ratings and portal visual checks | 24 +24 passed |
| `git diff --check` / scope and secret-pattern review | Pass; four production files, seven test files and this report only |
| Production/server/device verification | Not performed; owner-reported413 remains unresolved on the server |

Native Windows/Ubuntu complete-suite evidence is linked in the Draft PR for the exact pushed commit. The new UI renders were captured in all four language/theme variants; native CI also captures them as review artifacts. A mocked player surface is not evidence of physical video decoding or production persistence.

### Exact changed-file manifest

- `docs/CLINIC_VIDEO_413_RELEASE_GUARD.md`
- `lib/core/services/media_file_policy.dart`
- `lib/core/services/video_upload_policy.dart`
- `lib/features/clinic_portal/presentation/screens/clinic_media_screen.dart`
- `lib/features/clinic_portal/services/showcase_video_change.dart`
- `test/admin_media_polish_test.dart`
- `test/admin_media_visual_test.dart`
- `test/backend_401560b_integration_test.dart`
- `test/clinic_media_contract_test.dart`
- `test/gallery_ratings_physical_qa_test.dart`
- `test/onboarding_review_workflows_test.dart`
- `test/video_save_qa_preview_test.dart`
