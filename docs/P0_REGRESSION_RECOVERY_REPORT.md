# P0 regression recovery — PR13

2026-10-26 · `codex/final-backend-integration-client-preview` ·
[PR13](https://github.com/majd-khalifa/AestheticWay/pull/13), open/unmerged.
Recovery baseline: `bb9a6762354b06e9f7392234a037ed5497d3154f`.
The interrupted working tree was preserved. No replacement branch, reset,
Django edit, signing change, publication or merge.

## Findings, corrections and evidence ownership

| Report | Independently established cause / limit | Frontend correction |
|---|---|---|
| Nurse creation without a photo fails | Portrait is optional. Source API accepts Doctor, Nurse and licensed_professional without it (201). Flutter types are correct. **Confirmed defect:** a blank optional title was populated from specialty;120-character specialty produced an invalid120-character title (limit100),400. Display fallback also repopulated that title on edit. The owner's exact rejected payload/status was unavailable, so this is a reproducible cause, not proof of the exact physical failure. | Blank optional fields stay blank. Required English name/200-character names and specialties/100-character titles match source. Preserve raw API text separately from display fallbacks, including edit and toPortalJson. Safe localized field errors + HTTP status, input preservation and duplicate-submit guards. Nurse create→edit→new repository read covered; real source edit/read and25-record20+5 tenant-scoped pagination pass. |
| Gallery selection/upload/persistence | Active-clinic multipart upload/asset ACK/list/new authenticated profile read/delete succeeds against source. bb9a676's gallery protocol was unchanged from earlier working versions except video diagnostics. **Physical-device failure remains unexplained.** Confirmed frontend gaps: multi-selection could push Save below the viewport; no per-file transport progress; partial-failure profile refresh/uncertain-save feedback was weak; a stale GET could remove an acknowledged photo from the visible list. | Persistent queue/save bar, clear selection-vs-saving copy, progress/cancellation, accurate HTTP/file errors, acknowledged-ID receipts until fresh reads confirm them, and fresh profile refresh after partial success. Remove acknowledged files from the queue; never resend them automatically. Ambiguous failures require saved-list review and explicit retry confirmation; missing/invalid local files issue no POST and are not mislabeled uncertain server saves. Stale verification notices clear after read-back. |
| Dubai directory includes Abu Dhabi / editor address says Sharjah | An active Dubai branch of an Abu Dhabi headquarters is a legitimate match. Source also incorrectly matches inactive/deleted Dubai branches. Profile PATCH persists contradictory city/emirate/address/coordinates. Nearest-branch metadata may copy headquarters emirate into a Dubai branch. | Canonical bilingual city/emirate aliases, explicit address-conflict warning/block, UAE coordinate envelope/order validation, invalidated confirmation after address edits, and matching fresh privateGET. Patient directory cards explain differing primary city without inventing a matched branch; known inconsistent public profiles advise confirming the address. Unknown cities in a partial client catalog are not falsely called contradictory. Backend repair is still required. |
| Missing Nearby km | Source GPS nearby returns numeric distance_km and correct nearest-branch coordinates. Manual city endpoint intentionally returns null. **Confirmed Home defect:** granting GPS left cards on the city Home feed; the GPS endpoint was not used there. Dedicated Nearby distance was also below the full media card. | GPS Home uses the existing clinics/nearby endpoint through NearbyDiscoveryController, displays server distance next to identity, retains horizontal premium cards and server order, and provides full paginated list/map choices. Home previews first five only. Nearest-branch names are identified when supplied. Dedicated Nearby shows distance within the card. Manual browsing remains distance-free; foreground origin is never invented or persisted. Route/tab/background cleanup remains. |
| Heavy video bar | Solid bottom control strip obscured media throughout playback. | Translucent gradient,2px progress, controls hide after3s while playing and reappear on tap. Paused/buffering/error states and accessibility navigation keep controls visible.48dp touch targets, mute/pause/fullscreen/retry, RTL, reduced motion,15s carousel coordination and controller/timer cleanup retained. Working player/upload/save contracts were not replaced. |

## Verification and artifacts

- Local `dart format .` completed; `flutter analyze` **zero issues**;
  full `flutter test` **1,206 passed / zero failed**, including23 new
  regression/render tests. `git diff --check` clean.
- [Actual before/after Flutter captures](p0-regression-recovery/README.md):28
  baseline +28 updated430×1000 frames, EN/AR × Light/Dark, seven surfaces.
  Genuine decoded fixture images; these are not generated screenshots or
  production API/GPS/R2/native-video evidence. No existing goldens were replaced.
- [Machine-readable verification](p0-regression-recovery/verification.json) and
  [exact changed-file manifest](p0-regression-recovery/CHANGED_FILES.txt).
- 21 isolated source API observations, including valid/invalid practitioner
  requests, edit/read/pagination, image upload/read/delete, pending-clinic403,
  geography acceptance, ineligible branch matching and inconsistent nearest-
  branch emirate. All413 backend source files remain byte-identical.
- Full Flutter analyzer/tests and native Windows/Ubuntu, Android APK/AAB,
  macOS unsigned iOS Release/hosted test conclusions are recorded for the final
  pushed head in PR13. Prior bb9a676 results must not substitute for this run.
  Android CI uses a disposable verification certificate; iOS Release is unsigned.
  No production signing or store/device-distribution acceptance is implied.
- Dev-only geolocator platform-interface dependency is pinned to the already
  resolved4.4.1 to test the real Home permission→position→endpoint transition.
  Production package versions, native minimums and signing are unchanged.

## Remaining dependencies and honest limits

[One bilingual Ali handoff](P0_REGRESSION_RECOVERY_BACKEND_HANDOFF_FOR_ALI.md)
contains exact source requests/responses and expected fixes for contradictory
geography, inactive/deleted branch matching and nearest-branch emirate metadata.
It also explains the source image-upload403 for pending clinic accounts, without
assuming that was the owner's device state. The active clinic's image journey
does not reproduce the reported live failure. New UI error fields/status and
the device checklist enable the next failure to be identified safely.

Google identity linking remains independent from the manual entrance. No
Google-derived coordinates or translations are copied to durable manual data
or OSM. A proposed proof-bound, explicitly consented adoption operation needs
server provenance/version/refresh/expiry policy before implementation. No new
Google endpoint was called, SDK installed, key committed or iOS minimum raised.
Coordinate/text checks are not administrative-boundary geocoding.

No physical device or live authenticated production request was available to
this execution. Owner-reported existing VIP upload/restart/play/delete/cover
preservation, Google linking and Nearby eligibility successes remain attributed
to the owner; new recovery behavior still needs a device run. Account-deletion
OTP receipt remains unverified; deletion security was not changed.

## Preserved functionality

Patient luxury layout/category artwork, Clinic and Super Admin workflows, role
isolation, public approval/eligibility, JWT refresh, pagination/caching, verified
Google ratings, consultation leads/My Requests, deletion protections, five
patient tabs, English/Light first install and saved preferences/onboarding.
No prices/cart/calendar, fabricated clinic/media/rating/distance/translation,
license/authority UI, or unsupported backend success was introduced.

[Physical Android checklist](P0_REGRESSION_RECOVERY_ANDROID_QA.md) separates
automated findings, source behavior and checks still required on the owner device.
