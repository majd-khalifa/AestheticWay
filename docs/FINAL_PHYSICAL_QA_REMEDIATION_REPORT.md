# Final physical-QA remediation

2026-10-25 · existing PR13 / `codex/final-backend-integration-client-preview` · baseline32498e331f972fa0a036c46d98d39bd78c1207fe. Latest supplied Django source remains401560bdb06bd739f74eb42a88c68fc748e43dbb; no newer fix/archive was assumed. Django and production signing are unchanged.

## Results

| Finding | Implemented / verified | Remaining evidence |
|---|---|---|
| Physical VIP saveHTTP500 | Real serialized-request test validates authenticated one-part MP4 PATCH, exact bytes, MIME/boundary/length and omitted unrelated fields;500 cannot replace active state or trigger automatic retry. UI keeps selection, labels local preview unconfirmed and blocks repeat upload until explicit verification. | User-reported physical500 remains **unresolved**. Source/local success is not production save proof. Ali must correlate actual deployed worker/proxy/storage exception. |
| Save acknowledgment | Existing same-clinic PATCH acknowledgment → fresh authenticated GET → same media/cover verification preserved. New tests reject failed/mismatched freshGET with no second PATCH. | Remote object delivery, R2 Range206, force-stop/reopen playback and cover/gallery-preserving removal must still be verified on the actual device/server. |
| Location sheet | Shared responsive Emirate→City→Area path, localized search/clear, selected cards/checkmarks, Back/close/cancel, explicit confirmation, pinned summary/action, compact short lists and accessible empty/retry states. | Physical catalog loading is **user-reported PASS**. New UI itself is Flutter-rendered/tested here, not independently device-approved. |
| Saved geography | Valid saved city/area restored; back navigation retains draft; changing parent clears descendants; old free-text locations remain visible; actual source catalog used throughout Home/directory/onboarding/profile/admin shared field. Duplicate opens guarded; changed sessions discard stale results. | No invented canonical area FK or unsupported filter; existing address compatibility remains. |
| Nearby | Disabled adapter preserved; no new GPS query/estimated distance or sixth tab. | Requires supplied server fix enforcing approved/public visibility, closest valid branches, all tiers, real radius/km and pagination. |
| Deletion | Source API probe proves confirmed email cannot satisfy missing persisted email-verification state. The SMS factory contains only console/mock and returns console on unknown names; those report acceptance without a real gateway. Deployed provider configuration remains unverified. Flutter now recognizes actual nested `fields.code` no-channel sentinel and gives delivery/retry/support guidance without removing OTP. | SMS dispatch acceptance is not delivery. No documented secure deletion reauthentication alternative exists; no password/reset OTP substitution or invented email channel was added. |
| Google Business | Existing authenticated autocomplete/details/proof-bound link/unlink and fresh profile state remain independent of the map. Actual `formatted_text` is used if `main_text` is empty; no synthetic name/result. | No independent live Google delivery/ownership claim; unresolved server permission/PUT/provider issues remain referenced in the current handoff. |
| Embedded Maps | Compatible package set resolved in a separate project; platform credential templates prepared and ignored-local-file paths protected. | App stays SDK-free/iOS13. Restricted keys and an explicit supported minimum-OS choice are required. SDK candidates were not compiled into this app. |

## Code and test scope

- `lib/features/locations/presentation/uae_location_picker.dart`: all shared picker consumers inherit the same layout/state fix. The existing manual map editor/coordinates and business identity separation are preserved.
- `lib/features/google_business/data/google_business_repository.dart`: use a genuine provider formatting fallback, not an invented label; actual response remains `suggestions`.
- `lib/features/clinic_portal/presentation/screens/clinic_media_screen.dart`, `services/showcase_video_change.dart`: truthful preview/save failure feedback, preserved selection and existing read-only recovery. No upload retry or fake success.
- `lib/core/network/api_exception.dart`, `lib/features/auth/presentation/screens/account_deletion_screen.dart`: exact safe nested service code, existing masked delivery and OTP lifecycle, clear missing-delivery help. No new mutation endpoint/channel.
- `config/maps/*`: inactive reviewed configuration examples; `.gitignore` protects actual local values. Native app configuration, iOS minimum, dependency lock and signing code were not modified.
- Added10 locality tests +5 wire/error tests; expanded video failure renders from2 to4 language/theme cases: **17 net new tests**. Existing lazy-screen tests now scroll to actual controls and use precise keys, preserving all navigation/cleanup/selection assertions. No skip, removed assertion, relaxed golden threshold or timeout increase.
- Full test/analyzer/format/diff and native CI results are recorded in [verification](physical-qa-remediation/verification.json) and PR13. The native pipeline runs the new group and uploads its own renders.

## Evidence and delivery

[22 reviewed before/after/failure renders](physical-qa-remediation/README.md), with a matching viewport and baseline capture harness; no historical goldens overwritten. [Exact changed-file manifest](physical-qa-remediation/CHANGED_FILES.txt).

[Email source evidence](physical-qa-remediation/email-source-evidence.json):4 isolated actual API responses with mocked providers; confirms email-change200/200, SMS-only deletion200 and no-channel400 after phone removal. [Rechecked Google/video source evidence](physical-qa-remediation/google-video-source-evidence.json):25 isolated API responses, genuine MP4 local byte persistence and fresh-client verification, with known source gaps. All410 source files unchanged. Neither probe uses production Google, SMS/email or R2.

The **single current backend handoff** is [here](FINAL_PHYSICAL_QA_REMAINING_BACKEND_HANDOFF_FOR_ALI.md); it contains required evidence for the actual physical500, the concrete email-state defect and the still-required nearby approval fix, with references to unresolved Google security issues. It does not reopen resolved missing-route, gallery, referral or admin-review findings. [Maps plan and official sources](GOOGLE_MAPS_PRODUCTION_READINESS_PLAN.md).

Physical follow-up must use authorized disposable accounts and distinguish actual PATCH/GET statuses, decoded remote playback and provider delivery from preview/dispatch acceptance. Preserve English/Light first launch, persisted language/theme/onboarding, five patient destinations, lead-only confirmations, role isolation, media/security/performance and category/review flows. PR13 remains OPEN/UNMERGED; nothing is published.
