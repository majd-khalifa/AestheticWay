# Final physical-QA UX remediation — PR13

2026-10-26 · branch `codex/final-backend-integration-client-preview` ·
[PR13](https://github.com/majd-khalifa/AestheticWay/pull/13), open and unmerged.
Starting commit: `f20ab75ed5e0be5148771b104e9c3ac5d6b2b73c`.
Backend465bf30 remains read-only. This report supersedes older physical-QA
status statements; it does not retroactively turn source tests into device QA.

## Result and implementation

| Area | Correction and exact implementation |
|---|---|
| Featured carousel | `featured_ads_carousel.dart` now coordinates one4s image timer with `PatientVideoPhase`. Initializing/buffering/playing/user pause hold the slide; completion or15s playback position advances once, with no loop/seek timer. Manual swipe, indicator, viewport, route/tab/background and reduced motion remain authoritative. URL/playlist changes clear stale holds. |
| Patient video | New `core/widgets/patient_video.dart` provides lazy, muted, opt-in playback, bounded poster/contain fitting, pause, sound, fullscreen, loading, decode failure/retry and release on navigation/background/logout. The public profile waits for a fresh matching public detail response and rejects explicitly unpublished statuses before adding video as the first slot of `patient_clinic_gallery.dart`; all actual photos remain selectable. An existing/stale model alone cannot authorize a video player. |
| Upload reliability | `video_upload_policy.dart` applies only to a multipart `video_ad_file` PATCH.25MiB at512kbit/s≈410s plus70s margin gives480s send,120s receive; connect remains30s and ordinary API send/receive60s. `AW_VIDEO_UPLOAD_SEND_SECONDS` (60–1800) and `AW_VIDEO_UPLOAD_RECEIVE_SECONDS` (30–600) configure this endpoint. Auth refresh may renew credentials but cannot replay this video body. Selection, progress, cancellation, read-only uncertain-save reconciliation and strict PATCH ACK→fresh privateGET validation remain. |
| Upload diagnosis | The repository/client capture an allowlisted upload diagnostic: stage, elapsed_ms, actual HTTP status or none, generated X-Request-ID and coarse file-size band. Clinic Media reveals it only in an error support expansion. No body, token, phone, signed URL or file path is included. HTTP401/403/413/429/500/502/504, timeout, cancellation and connection loss remain failures; local playback is never a save receipt. |
| Exact entrance/address | `clinic_address_search.dart` parses only genuine UAE result/address fields, with one explicit search/s and small memory cache. The editor routes pasted business names to authenticated Google search; ordinary address results can prefill actual available languages only after confirmation before replacing text. Raw bilingual model fields prevent display-language fallback becoming a fabricated editor translation. UAE bounds, lat/lng order, catalog consistency and a separate entrance confirmation are enforced. The map has a stable key/retained editor lifetime, fixing detach/reattach while scrolling. |
| Location persistence | New `ClinicPortalService.updateClinicCoordinates` sends only city/emirate/address_ar/address_en/latitude/longitude. Fresh privateGET must match clinic, coordinates, city, emirate and raw addresses before UI success. No Google identity/media/full-profile rewrite. Cancel and failure keep the prior saved location. |
| Google identity | Existing authenticated autocomplete/details/proof/CAS link/unlink are preserved. Pasted names are cleaned of bidi control characters and whitespace; optional disclosed city text is added to query, never an undocumented bias field. Exact place/address/PlaceID/coordinates are inspectable with Google Maps attribution and explicit identity confirmation. Linking does not imply ownership or move the manual entrance. Google results are never rendered on OSM. |
| Nearby | Genuine server distance has a visible localized badge, GPS vs manual-city headings and safe bottom padding. Manual city responses have no distance badge; backend order, tiers, closest branch, pagination and map-link selection are unchanged.320dp/180% text regression checks the final request action remains visible above a34dp inset. |
| Locality/filter polish | Strong selected states, localized prominent search, parent breadcrumbs, explicit reset/back/confirm, safe-area sheet and wrapping filter header. Previous selection is a draft until confirmation. Apply guards duplicate/stale-session taps. No hardcoded district centroid is saved as an actual entrance. |

## Deliberate incomplete scope / backend dependencies

**Google-derived pin adoption is not implemented.** Ordinary backend coordinates
have no provider source/expiry/adoption contract. Applicable Places retention/map
restrictions prevent silently persisting selected Google coordinates as manual
data or putting them on OSM. The verified business can be inspected/linked;
manual entrance editing remains independent. True geographic bias, atomic
bilingual details/reverse-geocoding and production-wide address-provider routing
also need documented backend contracts. [One bilingual Ali handoff](FINAL_PHYSICAL_UX_BACKEND_GAPS_FOR_ALI.md)
contains exact requirements; no invented API calls were added.

Restricted Maps SDK keys and the existing iOS minimum/SDK decision remain
necessary for an embedded Google map. External Google Maps and distance list/map
choices remain available. No SDK, minimum OS, signing, secrets or Django changes.

## Automated evidence

- Local `dart format .` completed; `flutter analyze` **zero issues**;
  `flutter test` **1,183 passed / zero failed**, including39 new regression/render
  tests; `git diff --check` clean. All413 backend source hashes remain unchanged.
- Genuine19,925,044-byte neutral H.264 MP4,64×64/2.000s: full FFmpeg decode succeeds.
  Generated from the existing fixture, never bundled or committed as a large file.
- Slow320s controlled transport succeeds with480s endpoint budget (it remains
  pending beyond the old60s limit); actual multipart bytes/progress are checked.
  Loss near completion, cancellation,120s ACK timeout, read-only reconciliation,
  all listed HTTP failures and401 refresh-without-body-replay are covered.
- Carousel4s/15s, buffer, manual pause/swipe, reduced motion, route/tab/background,
  decode failure/retry/logout, public detail gating, invalid/unpublished video,
  mute/fullscreen/back and existing late initialization/offscreen tests remain.
- Address language truth, overwrite cancellation, missing-language preservation,
  city/emirate conflict, UAE/reversed/nonfinite coordinates, partial PATCH plus
  freshGET/stale response and Google identity preservation are asserted.
- [Before/after render index and hashes](final-physical-ux/README.md);
  [exact file manifest](final-physical-ux/CHANGED_FILES.txt).
- Local and native result counts are recorded in `final-physical-ux/verification.json`
  and PR13 checks. Native evidence must refer to the pushed commit. Android CI
  uses a disposable verification key; iOS Release is unsigned. Neither proves
  installation, production signing, TestFlight or store publication.

## Physical-device checklist and result ownership

| Check | Owner-reported current Android result | This execution |
|---|---|---|
| VIP select/upload/save, force-close/restart, play/delete | PASS | Automated wire/state/player-platform tests; no physical device |
| Video removal preserves cover; multi-image gallery add/delete | PASS | Existing guards/regressions preserved; no new gallery defect |
| Live Nearby eligibility and distance ordering | PASS | Fixture/API-contract tests; no independent live GPS request |
| EN/AR locality selection and real Google Business link | PASS | Bilingual rendered/widget regressions; no independent live Google call |
| Account-deletion OTP actually received | **NOT VERIFIED** | Flow/security unchanged; source acceptance metadata is not delivery |
| New carousel hold, patient video,19MiB weak-network attempt | Needs new owner device run | Automated results only |
| New exact entrance, cancellation/reopen and large-text last CTA | Needs new owner device run | Widget/render coverage only |

On Android/iOS repeat:4s boundary while playing/buffering, explicit pause for>15s,
completion once, image advance, manual swipe, background/return, mute and
fullscreen back. Check a saved public video after cold start, missing/failed
media, live19MiB upload with throttled connection, cancel/near-completion loss,
freshGET before retry, and cover-preserving deletion. Verify address overwrite
cancel, genuine available languages, selected city/emirate, corrected entrance,
save/reopen and unchanged PlaceID. Confirm real GPS vs manual no-km, nearest
branch/page2, denied/outside-UAE/offline recovery and the final CTA with large
text/system inset. Use only controlled accounts and safe support metadata.

All existing patient design, category-specific artwork, role isolation, five
tabs, English/Light first install, saved language/theme/onboarding, JWT,
pagination/caching and lead-only consultation behavior are preserved. No fake
clinics, ratings, distances, translations, success receipts or production media
were introduced. Screenshot fixture records are test-only.
