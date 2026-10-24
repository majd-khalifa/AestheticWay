# AESTHETIC WAY — PHYSICAL ANDROID QA FIXES + TRUE NEARBY CLINICS + UAE LOCATION CATALOG
**For Codex — Flutter principal implementation brief**  
Date: 2026-10-24  
Frontend repository: `majd-khalifa/AestheticWay`; **existing PR #13** `codex/final-backend-integration-client-preview`, last known head `e87dc682e2a8eff5d8f2cc3dca926b5848569428`.
Backend reference: provided archive `09f49bb` plus any later committed and deployed update from Ali. **Read-only Django. Do not edit backend or invent endpoints.**

## Role & change controls
Act as Principal Flutter Architect, Premium UAE Patient UX Director, Mobile Security/Privacy Engineer and Backend Contract Auditor. Preserve Clinic, Patient and Super Admin features, current Light/Dark + English/Arabic, English/Light on first install, stored preferences/onboarding, security/performance hardening, pagination max 20, 350ms debounce, shared 401 refresh lock, five patient tabs, real media priority, VIP internal targeting, lead-generation-only consultations with exact success `تم إرسال طلبك وستتواصل العيادة معك`. No guest, no cart/checkout/product prices or medical licensing claims. No fake clinics, ratings, distances, coordinates or placeholder-as-data. **Update existing PR #13, do not merge, change release signing or create a duplicate PR.**

## Field QA evidence and priorities
**Verified on physical Android:** 10/12 listed acceptance checks passed: gallery multiple-image add/delete, Super Admin count/reject/feedback/resubmit/approve, review image framing in Light/Dark, patient lead and status, persisted language/theme, first-run-only onboarding.

**Not verified:** saved VIP video after actual app/process restart; saved-video removal preserving cover. Video local preview/playback worked, but user could not establish lasting server persistence. **Corrected physical reproduction:** tapping **Upload and save video** triggers the toast/banner `The service is temporarily unavailable. Please try again.` near the top of the Clinic Media screen; previously loaded gallery photos happen to remain on screen. **Do not diagnose an independent gallery refresh failure from this.** Gallery add/delete was PASS. Delete account for sole clinic administrator was denied; another account requested a six-digit challenge but screen did not identify delivery channel/masked destination; receipt not verified.

**Separate backend confirmed blockers from previous source audit:** received-referral PII after deletion, admin rejection of approved setup, stale moderation notes after resubmission. Do NOT patch Django: update bilingual Ali handoff; Flutter must not present false success or pretend these are secure.

## P0-1 — Real VIP upload persistence
Trace `ClinicMediaScreen._chooseVideo`, `_saveVideo`, `ClinicPortalService.updateShowcaseVideo`, `ClinicCatalogRepository.updateClinicProfile`, `PATCH clinic-portal/profile/` and the subsequent `GET` refresh. **Exact reported failure is triggered by tapping the `Upload and save video` button:** `The service is temporarily unavailable. Please try again.` Identify whether the failing operation is multipart PATCH, immediate GET, or exception translation. A selected local `VideoPlayerController.file` preview is **not** evidence of persistence.
- Reproduce with a disposable authorized VIP account and REAL physical Android capture if available; otherwise clearly label not run. Observe button state, upload transition, HTTP status/error, same-clinic server acknowledgment, fresh GET/video URL, R2 playback and full app process restart; do not log JWT/full signed links.
- On save success require durable server-confirmed remote video state. If PATCH succeeds but a subsequent GET lacks the video, show one explicit localized save/reload failure rather than clearing local selection and pretending success. Do not infinitely resend multipart writes or ignore stale-session guards. Provide progress, retry, cancel, error details without raw private backend strings.
- Do not overwrite the clinic cover; `cover_image` is distinct from `video_ad_file` and acts as fallback poster in the existing contract. A selectable video-poster thumbnail is an **optional future P1 requirement requiring explicit Ali contract**; do not invent `video_poster` in Flutter. If user wants this, report backend change and preserve current cover.
- Verify remove saved video then fresh GET/restart, cover remains unchanged. Prove VIP pending/unpublished, Basic/Featured deny; use actual private read-only `subscription_tier`, no privilege escalation.
- Include malformed MIME/duration/size, picker permission/cancel, network timeout, 400/403, expired session, app backgrounding, Android codec issue, CDN range response and account switch test cases.

## P0-2 — Account deletion UX and delivery
Trace response model of `POST auth/me/deletion/request/` and `confirm/`. Distinguish sole-active-clinic-admin block from *actual OTP delivery*.
- Surface `masked_destination` and verified `delivery_channel` **only if source/backed response actually supplies them**, with UI translations and a visible resend cooldown. Never invent the target/claim delivery. If fields absent, document precise Ali API requirements rather than guessing from user profile.
- Display a useful protected exit path for `SOLE_CLINIC_ADMIN` (transfer/add replacement administrator or request reviewed closure), linked only to actual supported actions; do not permit an unauthorized delete or dead-end user for store privacy compliance. Handle blocked case clearly and no false success.
- Test with authorized disposable reachable account, validated provider outcome, expiry, resend, incorrect code, screen/session switch, confirmed logout without stale route. Do not store/log/display OTP outside the actual input screen or publish test identities.
- Preserve user choices and privacy policy references. Include an account deletion QA matrix.

## P1-3 — Video error placement + gallery NON-regression (corrected)
The generic service-unavailable message was **caused by pressing Upload and save video**. Treat it as part of **P0-1**; do **not** file a standalone gallery failure without a separate failing gallery HTTP trace. The actual gallery multi-image upload/delete was PASS. Identify the exact failing **video** operation and show the video-specific localized error adjacent to video controls. Preserve gallery content and acknowledged uploads without duplicate retry; test gallery refresh independently for regression, stable media bounds, and original-image expand. Preserve genuine errors but attach them to the correct operation.

## P1-4 — TRUE nearby clinics in Home, not simply renamed Discover clinics
**Approved user decisions:** location source = `both` (contextual foreground GPS permission + manual location selection), clinic eligibility = `all` active/visible patient-facing clinics, location hierarchy = `emirates` (seven Emirates, then cities).

Current Flutter source already has `NearbyClinicsSection`, `HomeRepository.getHomeFeed({city,latitude,longitude})`, and `ClinicsRepository.getClinics({city,latitude,longitude,page})`. However `HomeScreen._loadFeed()` currently passes city only; HomeHeader and FilterBottomSheet hardcode Dubai/Abu Dhabi; `nearby_clinics` is not proven distance-ordered. Reuse/refactor rather than building an unrelated sixth tab or redundant standalone screen.

**P0 architectural constraint:** before implementing, confirm in Django source or Ali's updated contract that existing `/api/v1/home/feed/` or `/api/v1/clinics/` truly filters/orders by distance and returns correct nearest eligible clinics. If not supported, implement a typed client interface and fixture-backed tests, document backend dependency for Ali; **never implement fake client-side sorting over one paginated result and call it 'nearest'.** Do not invent or call undocumented endpoints in production.

### UX
- Home section: `Clinics Near You` / `عيادات قريبة منك`, below Featured Clinics (paid placement remains separate) and wherever it fits approved editorial hierarchy; image-first cards, clinic name, accurate locality, computed approximate `x.x km away` only if backend supplies server-computed distance from confirmed coords, consultation CTA, See All into the current clinic directory prefiltered appropriately.
- Contextual `Use my location` action with rationale; Android/iOS When-In-Use permission only, allow approximate location. No automatic force prompt at cold start, no background tracking. Handle denied/deniedForever/GPS off/timeout/off-UAE with manual emirate→city fallback and clear status.
- Use one location controller/source of truth, prevent race between GPS and manual selection, invalidate stale flight/cache upon city/region/session changes, manage widget disposal, cache location cautiously, avoid precise location persistence beyond need. Persist user-selected manual city if product policy accepts, never persist raw GPS on user profile by default.
- When no valid nearby coordinates/coverage, show truthful fallback `Browse clinics in <city>` or all emirates (without distance badges), distinct from nearby section; no empty blank area or invented nearest list.
- Keep filters/search, bounded pagination, images, five patient tabs, bilingual RTL/light/dark, 320dp and large text accessibility intact.

### Locations catalog
- The UAE has seven **Emirates**, not seven total cities. Use a validated canonical backend location catalog with stable emirate and city codes, localized labels and aliases. Sources e.g. UAE official government (`https://u.ae/en/about-the-uae/the-seven-emirates`). Cities and districts are separate levels; include Al Ain, Hatta, Khor Fakkan, Kalba, Dibba etc according to verified seed. Never claim a short hardcoded list is 'all cities'.
- Replace hardcoded Dubai/Abu Dhabi in HomeHeader, FilterBottomSheet, ClinicsListScreen quick chips, all patient discovery filters, clinic location onboarding/editor, and relevant Super Admin city selectors with a reusable hierarchical emirate→city picker, loading/search/empty states and compatibility for stored old spellings.
- Align with Ali's real `locations` API only if it exists; otherwise isolate behind a repository interface and file a backend dependency. Preserve current working Dubai/Abu Dhabi behavior during incremental rollout. Do not treat the latitude/longitude of an emirate center merely used to position a map as a confirmed clinic location.
- City selected should filter backend by canonical ID/slug where supported; locale changes only label not ID; maintain existing filters and city chips without overflow in Arabic/English.

### Ranking, privacy, performance
- Nearest `distance_km` must be backend-derived from confirmed clinic/branch coords with true distance ordering and stable ties. No use of a fabricated Dubai center, zero coordinates, false Google ratings, invalid Maps links or exposing subscription tier to patients.
- Separate paid Featured carousel from proximity section; sort proximity by distance not tier, include all approved/active visible clinics, avoid duplicate clinic entries even with multiple branches. Do not limit selection to a single first page before sorting.
- Debounce/filter, avoid redundant GPS/HTTP calls and N+1, cache by canonical location/appropriate coarse geo tiles and invalidate correctly. No precise coords in telemetry; update Privacy Policy/Play Data Safety, manifest Android coarse/fine as justified and iOS `NSLocationWhenInUseUsageDescription`, no background permission.

## P0-5 — Backend gaps that MUST remain visible to release manager
Record prior source-confirmed received referral deletion PII, approved rejection transition defect and stale notes in updated bilingual handoff. Do not treat a passing Flutter test as remediation. Require Ali deployed commit, real Android VIP persistence proof and reachable OTP delivery, and source-confirmed location API before declaring feature complete.

## Mandatory QA coverage
- Full physical-Android case matrix for video save-triggered error and persistence, gallery non-regression, OTP delivery/sole admin, nearby GPS granted/reduced/denied/deniedForever/off, manual emirate/city selection, outside UAE, active/hidden clinics, multiple branches, missing/outlier coordinates, radius/no results, pagination tie-breaking, Arabic/English and Light/Dark.
- Widget/contract tests must demonstrate **server-derived distance, not client guesses**; verify pagination and alias migrations, HTTP error states, stale async prevention, logout/account switching and no user GPS leak.
- Render actual Flutter screen comparisons before/after. Do not rely solely on CI.
- `dart format .`, `flutter analyze` zero issues, `flutter test` full pass, `git diff --check`, native Windows/Ubuntu CI, Android APK/AAB, iOS Release compilation, best-effort native simulator tests with honest outcome.

## Deliverables
1. Compact table: observed vs source-confirmed vs live verified, P0/P1.
2. Fixed Flutter video save/error states and account-deletion channel UX (only if backed); gallery non-regression test (not an assumed gallery defect).
3. Locations API contract proposal vs actual backend contract and migration plan (no invented endpoint).
4. Full list of changed files and regression tests.
5. Render comparisons and physical Android steps.
6. Exact bilingual Markdown handoff `docs/UAE_NEARBY_QA_BACKEND_HANDOFF_FOR_ALI.md`, containing precise Ali changes required and previous confirmed P0/P1 privacy defects.
7. Final commit, push existing branch and update PR #13 without merging.

**Final acceptance:** no false 'saved' claim for local video preview; no false 'OTP sent' to unspecified destination; users can select any UAE Emirate and canonical city; truly nearby results include all eligible clinics, use confirmed coordinates with server-calculated distance, and never disclose internal subscription tier.