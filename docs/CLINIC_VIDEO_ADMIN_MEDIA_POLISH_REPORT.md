# PR #13 — Clinic video entitlement and administrative media polish

Date: 2026-10-23. Branch: `codex/final-backend-integration-client-preview`.
Incremental baseline: `86c82bdd7900728bb336b4d8cb6bbd845e5fdd23`.
This update preserves the existing integration branch, Patient design, role isolation, signing configuration and backend source. PR #13 remains open; nothing is published or merged.

## Evidence and limits

- The supplied physical Android screenshots establish the reported disabled video control, blank gallery card and poorly framed review media. They do **not** establish the private API payload or the failed image's HTTP/decoder error. Private screenshots and contact details are not copied into this repository.
- Backend authority is the supplied `1f1e4bf` archive, SHA-256 `48d385acc256ebba450ede43e515f475daf1ae8ed3de80319e68429833f7c1ff`. All **403** extracted source-file hashes remain unchanged.
- [Controlled Django evidence](admin-media-polish/controlled-django-contracts.json) contains **139 actual view responses**, using disposable users, force-authenticated requests, in-memory SQLite and local test storage. This is source-contract evidence, not production JWT, Cloudflare R2 or live CDN verification.
- [Render comparisons](admin-media-polish/README.md) use actual Flutter widgets and decoded fixture files. Fixtures are labeled QA data and are never installed as production fallback photographs. No production clinic data or tokens are included.
- No physical Android/iOS device or live VIP credentials were available here. The affected production URL, R2 persistence, current deployed response and complete physical upload/restart/playback sequence remain **unverified**. Previous successful user-reported consultation QA remains separate historical evidence.

## P0 diagnosis: why a VIP badge and a disabled video picker coexisted

1. `apps/admin_portal/serializers.py::AdminClinicDetailSerializer` returns the real database `subscription_tier`.
2. `apps/clinics/portal_serializers.py::ClinicProfilePortalSerializer.Meta.fields` **omits `subscription_tier`** from both private GET and PATCH acknowledgments. Its comment lists the field as non-editable; omission also inadvertently prevents reading it.
3. Previously, `ClinicModel.fromJson` converted an absent or unrecognized tier to Basic with no separate indication of uncertainty. `ClinicPortalService` initialized and replaced its profile with that model. Therefore a truthful Super Admin VIP badge did not imply that Clinic Media had received a VIP tier.
4. The picker tested the resulting Basic enum. A profile refresh or successful unrelated PATCH could silently disable the picker again. This contract mismatch was missed in the previous pass; a tier badge or the source permission check alone was insufficient evidence.
5. Django's `validate_video_ad_file` and `validate` require the **database tier `vip`** for a non-null video. Featured and Basic are legitimately rejected with 400. `is_featured`, display labels and setup approval do not grant this capability.

### Implemented correction

`ClinicModel.subscriptionTierKnown` distinguishes absent/unsupported values from a confirmed Basic tier. The legacy enum default remains compatible with existing Patient parsing, but it is no longer sufficient to authorize the video control.

`ClinicCatalogRepository` reads the current authenticated private profile first. If and only if the tier is omitted/blank, it requests the **existing** `GET /api/v1/clinics/<same-clinic-UUID>/` and accepts only a matching UUID and a recognized read-only tier. It copies only that tier; private contacts, media and other fields are never overwritten by a public projection. An explicit private Basic, Featured or unknown future tier cannot be overridden by public VIP. Session changes invalidate both responses. No local VIP cache, new endpoint, editable tier or `is_featured` inference is used.

The source public detail reads the database without a view cache decorator, but only exposes active, non-deleted clinics. An unpublished VIP clinic therefore remains honestly **unknown** when the private field is omitted. Refresh/retry is visible; Ali's private read-only projection fix remains necessary for that case. Network/intermediary freshness in production is not proven by source inspection.

Clinic Media verifies the current owned profile on entry, resume, before native selection and before video writes. Stale VIP does not survive a current Basic/Featured response. Profile failures cannot authorize uploads. Gallery mutations also require a verified current clinic. Role/session changes remove private controls and pending selections. Server permissions remain the final authority.

### Actual API and permission matrix

| Operation/state | Source contract and current Flutter behavior |
|---|---|
| Read entitlement | Authenticated `GET /api/v1/clinic-portal/profile/`; same-UUID public detail only when the private tier is absent. No invented permission endpoint. |
| Upload | Authenticated `PATCH /api/v1/clinic-portal/profile/`, Dio-generated multipart boundary, **actual `video_ad_file` binary**, MP4/MOV/WebM MIME. No URL string, `media_asset`, poster field or subscription write. |
| Limits | 25 MiB; UI guidance 15 seconds; native/source decoder acceptance ceiling 15.5 seconds. Actual file size, signature and duration are checked; Django independently validates content. |
| Save acknowledgment | Requires same clinic and an HTTP(S) saved video reference. Missing/contradictory 200 acknowledgments do not produce success. A fresh GET checks the saved/removed state; refresh failure reports that verification is outstanding. |
| Remove | JSON `PATCH {"video_ad_file": null}`. Existing video can be removed after downgrade. Confirmation preserves clinic cover. |
| Poster | Clinic cover is the existing fallback poster. This profile has no independent poster field. Cover editing explicitly states that it changes the clinic cover. |
| VIP + active membership | Real binary accepted in the controlled Django probe. Requires active/non-deleted user and exactly one active clinic membership. |
| Featured/Basic | Real binary rejected 400 by Django; Flutter selection stays disabled with a truthful explanation. |
| Pending VIP clinic | Private profile 200, public detail 404, binary PATCH 200 in controlled Django tests. Setup approval is not an additional video gate. Missing private tier blocks safe frontend determination until Ali's fix. |
| Suspended/rejected/deleted clinic or inactive/deleted user | Server permission denies access; no client bypass. |
| Patient / Super Admin without clinic membership | Patient portal write rejected 403; Super Admin fallback reads do not permit clinic writes. Clinic Media remains a clinic-role screen. |

Cancellation sends no write. Native codec/format/size errors remain local failures. HTTP 400/403, network failure and incomplete acknowledgments retain the selected valid video for a deliberate retry; no automatic mutation retry is introduced. Saved video remains lazy and is never passed to an image provider.

## P0 gallery diagnosis and correction

The exact failed production object cannot be diagnosed from a blank rectangle alone. Expired/private/404 CDN links, HTML error bodies, corrupt bytes, stalled requests and R2 object loss remain distinct possibilities. No storage diagnosis is asserted without the affected response.

The confirmed frontend presentation defect was the lack of an explicit first-frame state and recoverable failed-image presentation in these portal frames. New portal-only `PortalMediaFrame` uses:

- bounded 16:9 photographic frames, square contained logos, controlled portraits and contained product imagery;
- a neutral branded skeleton until an actual decoded frame arrives;
- an explicit neutral failure panel after genuine network/decoder errors, with localized retry;
- targeted eviction of the mounted resize/original provider keys on retry, without changing signed URLs, clearing the global cache or concealing failures;
- tap-to-expand originals with `BoxFit.contain`, lazy bounded decode and existing media-cache priority;
- no invented photographs, no MP4-as-image rendering and no removed ownership/deletion checks.

Real HTTP fixture bytes are decoded in tests: a pending response becomes an actual image, and HTTP 403, corrupt bytes and HTML error bodies produce a failure panel that recovers on retry. Existing multi-image upload, partial failure, delete confirmation, page refresh and duplicate guards remain covered. A visible frame is not proof of live R2 persistence; use the device checklist below.

## P0/P1 visual changes

| Surface | Implemented files and treatment |
|---|---|
| Clinic Media | `clinic_media_screen.dart`, `portal_media_frame.dart`: bounded gallery, explicit image states, expandable images, truthful entitlement verification/recovery, original native upload flow. |
| Submitted Clinic Profile | `admin_clinic_reviews_screen.dart`: contained square logo; bilingual identity/city; separate setup and account status; rounded 16:9 cover with full original viewer; sections for profile, contacts, location/branches, catalog counts, submission and supported approval. |
| Super Admin Clinic Details | `admin_clinic_detail_sheet.dart`, `admin_components.dart`: contained logo, bounded expandable cover; existing management, offers shortcut, scrolling and status controls retained. |
| Clinic Dashboard/setup | `clinic_dashboard_screen.dart`, `clinic_setup_checklist_card.dart`: compact contained logo; honest unknown tier; compact checklist rows; distinct review state; responsive stacked actions at narrow width/large text. |
| Clinic Profile/catalog | `clinic_editorial_header.dart`, `clinic_catalog_cards.dart`, `clinic_profile_screen.dart`: shared portal frames; contained brand products/logos; bounded editorial offers and controlled practitioner portraits. |
| Category moderation | `category_requests_screen.dart`: scoped theme-aware cards, borders, filled status selector and bottom-safe padding. CRUD, moderation, counters and permissions unchanged. |

All four Light/Dark × English/Arabic variants are rendered for six surfaces plus the video section. Additional 320dp/180% text-scale review and image-error renders exercise narrow layouts. Media pickers retain `LuxuryImagePickerField`; no raw URL fields or unsupported content types were added.

Admin review source does **not** project the complete gallery or full practitioner/treatment records. The UI displays supported cover/video and real counts, explicitly states the gallery limitation and never queries arbitrary clinic-owned media. Existing supported approve remains guarded, confirmed and refreshed; no fabricated reject endpoint is introduced.

## Verification

The focused tests exercise real multipart bytes, cancellation, stale/current/missing/unknown tiers, profile failure/recovery, wrong UUID, expired session, server downgrade before selection, real-file invalid/oversize/codec errors, 400/403/network/incomplete acknowledgment retry, save/reopen/play/remove, real decoded images, fullscreen fit, small frames, text scaling and RTL.

`admin_media_visual_test.dart` is intentionally runnable unchanged at the baseline commit to produce comparable before/after renders. Existing Patient goldens are neither overwritten nor relaxed. The CI matrix runs these tests on native Windows and Ubuntu; the unchanged native release workflow compiles Android Release APK/AAB with a disposable verification key and iOS Release on macOS. Final counts, commit and native run links are recorded in the PR update; [local evidence](admin-media-polish/verification.json) records results captured before committing.

## Required physical Android checks (not performed here)

1. Use an authorized, disposable **real VIP** clinic. Open Clinic Media after login and after account switch; refresh. Capture only tier/boolean/status diagnostics, never JWTs or private profile content.
2. Select a genuine supported ≤15-second, ≤25-MiB clip. Check cancellation, denial of photo access, loading, duplicate taps, interruption and deliberate retry. Confirm the request uploads binary bytes, not a device path or URL.
3. Save, observe server acknowledgment, refresh, close/reopen the editor, kill/relaunch the app, then play the saved video. Verify foreground/background pause and meaningful decoder failure.
4. Confirm public HTTPS delivery from the deployed storage/CDN host with correct video MIME, accessible byte ranges and valid image bytes. Inspect expired/404/HTML responses separately. Never publish full signed URLs or private file names.
5. Remove the video with confirmation; refresh/restart and verify absence. Preserve the independent clinic cover. Test downgrade to Featured/Basic: no new upload, existing removal still available.
6. Add two real gallery images, save, reopen, refresh and restart. Confirm prior images remain, delete only the intended owned asset and verify Patient delivery. Simulate offline/expired URL/corrupt image: bounded fallback and localized retry must appear.
7. Repeat English/Arabic, Light/Dark, narrow phone and large system text. Verify original-image expansion and approval confirmation in authorized Super Admin review. Do not publish patient/contact information in QA artifacts.

Remaining backend items are narrowly documented in the [bilingual Ali handoff](CLINIC_VIDEO_BACKEND_HANDOFF_FOR_ALI.md). Production deployment and physical media persistence remain acceptance checks, not claims of completed live verification.
