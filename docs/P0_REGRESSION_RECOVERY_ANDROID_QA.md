# Physical Android QA — recovery build

2026-10-26 · PR13 · record the actual final commit/APK build number from PR13.
All boxes below are **not performed by this execution**. Do not infer device,
production API or R2 success from fixture screenshots or source tests.

## Practitioner — highest priority

- [ ] As a genuinely assigned clinic admin, create **Nurse without a portrait**,
  using short genuine EN/AR names and optional text fields. Confirm saved list,
  refresh, close/reopen app and edit/read-back.
- [ ] Repeat Doctor and Specialist. A portrait remains optional; blank Arabic
  text/title/bio must not become an invented translation after reopening.
- [ ] Enter a101–200-character specialty with title empty. Save must not inject
  an overlong title. Reopen Edit: title stays empty. Set a genuine title≤100,
  edit bio, save and verify after fresh retrieval.
- [ ] Exceed an actual field limit: validation must identify the field before
  submission. For server rejection, keep all values/photo/type, show safe
  localized field messages and HTTP status; no success toast or retry loop.
- [ ] Create/edit with a real supported portrait, verify asset ownership and
  persisted image; test cancellation, permission denial and page2 records.

## Gallery — diagnose the still-unverified device failure

- [ ] Record clinic account activation separately from setup/publication. Source
  pending-account image uploads are403; do not bypass or confuse this with VIP.
- [ ] Pick1 then several genuine images using Gallery and Camera where supported.
  The queue/save action remains visible; selection alone is clearly not saving.
- [ ] Upload JPG/PNG/WebP≤5MiB/25MP. Watch per-file progress, actual201 asset ACK,
  fresh saved list and private profile. Verify patient gallery remotely.
- [ ] Refresh/reopen editor, force-close/restart, and compare the same real saved
  images. Verify public HTTPS delivery independently (not just a cached local file).
- [ ] Reject an unsupported/corrupt/oversized/missing file: precise localized
  feedback, queue retained, no fabricated success. A missing local file sends noPOST.
- [ ] Interrupt near the second image's completion. Acknowledged images are not
  reuploaded; uncertain files require saved-list review. If an uncertain file is
  already present, remove it from the queue. Explicit retry confirmation only;
  no automatic ambiguous POST retry or duplicate tap upload.
- [ ] Cancel during transfer, then inspect saved state before any retry. Delete
  one actual saved asset, refresh/restart and verify removal/tenant isolation.
- [ ] Confirm gallery actions never change the independent cover or VIP video.

If failure recurs, capture **only** build SHA, exact action/stage, HTTP status,
safe field/code names, timing and coarse size band. Screen-record only with
consent and redact personal data. Do not send JWTs, OTPs, patient details, raw
requests/responses, signed URLs or personal filenames. A201 ACK without matching
fresh remote retrieval/CDN delivery is not a complete physical persistence PASS.

## Geography and Nearby

- [ ] Existing Dubai city + Sharjah-only address shows a correction warning;
  Save stays blocked. Correct actual address/city and explicitly confirm entrance.
- [ ] Editing either address after pin confirmation invalidates it. Cancel keeps
  prior saved data. Save requires matching freshGET; reopen verifies coordinates,
  city/emirate and genuine available languages. No inferred translations.
- [ ] Inspect legitimate headquarters/branch differences and a real active branch.
  Do not mark backend inactive/deleted branch filtering fixed by this frontend PR.
- [ ] Grant foreground location **and obtain a current UAE position**. Home must
  call GPS clinics/nearby, show actual server km and nearest branch, and link to
  the full paginated list/map choices. Compare server order across all tiers.
- [ ] Switch to manual emirate/city/area browsing: no invented km/center origin.
  Test permission denied/disabled, outside-UAE, empty, retry, background/return,
  logout, page2 and large text/system navigation insets.
- [ ] Google proof-bound link/unlink still works and refreshes identity/rating
  state. Linking alone does not move the entrance. No unsupported adoption action.

## Video and preserved workflows

- [ ] On Featured and patient profile: play, buffer, pause, sound, fullscreen/back,
  hide/show controls, decoder failure/retry. Playing controls hide after3s;
  paused/screen-reader controls remain accessible and photography stays visible.
- [ ] Hold carousel at4s during play/buffering; explicit pause holds indefinitely;
  completion/15s advances once. Manual swipe, reduced motion, offscreen, tab,
  route/background/logout stop or release playback correctly.
- [ ] Re-run the already owner-confirmed VIP large MP4 upload→PATCH ACK→freshGET→
  restart/play→delete journey; failed uploads preserve selection and never replay
  automatically. Cover remains independent.
- [ ] Consultation lead/My Requests, role security, deletion protections, onboarding,
  first-launch English/Light, saved EN/AR/RTL/theme and admin workflows remain.
- [ ] Repeat representative small phones,180% text, EN/AR, Light/Dark and iOS
  camera/gallery/player paths when a real iOS device is available. Native CI
  compilation/hosted XCTest does not replace that device QA.
