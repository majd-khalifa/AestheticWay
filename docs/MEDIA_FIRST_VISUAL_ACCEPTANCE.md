# Media-first visual acceptance

Reviewed 21 October 2026 (Asia/Damascus). Branch: `codex/media-first-luxury-interaction-polish`, stacked on `codex/performance-latency-readiness` at `242aa8763a4f170cafa6f81c0f978b2998113092`.

Targeted component changes preserve the existing Patient, Clinic and Super Admin work. No Django, release signing, security/session architecture, pagination, debounce or API backpressure implementation was changed. No PR is merged by this task.

## Rendered evidence

These are **actual Flutter widget renders**, at 390 × 844 logical pixels with Android target styling, not mockups or screenshots from a physical device. Synthetic public records and Google values are fixture data only. The clinic/offer photograph is the existing repository onboarding interior asset; its use here does not establish rights or production clinic identity. Product packaging and portrait calibration images explicitly say FIXTURE. They test containment/cropping and decoding, not real product or doctor content. No generated person, new stock image, or invented clinic media is added to production. A separate existing watermarked onboarding asset was inspected and excluded from this new evidence.

All seven views have populated/absent media × Light/Dark English, plus both media states in Dark Arabic RTL: **42 PNGs**. The consultation preview intentionally keeps an operation pending to show the real shared control; absence/presence does not change this control. Production OffersScreen navigation is separately tested with a delayed clinic repository, error and retry.

| View | Media/light | Media/dark | Absent/light | Absent/dark | Arabic/media | Arabic/absent |
|---|---|---|---|---|---|---|
| Home VIP carousel | [PNG](previews/media_first/home_media_light_en.png) | [PNG](previews/media_first/home_media_dark_en.png) | [PNG](previews/media_first/home_absent_light_en.png) | [PNG](previews/media_first/home_absent_dark_en.png) | [PNG](previews/media_first/home_media_dark_ar.png) | [PNG](previews/media_first/home_absent_dark_ar.png) |
| Clinics listing | [PNG](previews/media_first/directory_media_light_en.png) | [PNG](previews/media_first/directory_media_dark_en.png) | [PNG](previews/media_first/directory_absent_light_en.png) | [PNG](previews/media_first/directory_absent_dark_en.png) | [PNG](previews/media_first/directory_media_dark_ar.png) | [PNG](previews/media_first/directory_absent_dark_ar.png) |
| Clinic profile/gallery | [PNG](previews/media_first/clinic_media_light_en.png) | [PNG](previews/media_first/clinic_media_dark_en.png) | [PNG](previews/media_first/clinic_absent_light_en.png) | [PNG](previews/media_first/clinic_absent_dark_en.png) | [PNG](previews/media_first/clinic_media_dark_ar.png) | [PNG](previews/media_first/clinic_absent_dark_ar.png) |
| Brand showcase | [PNG](previews/media_first/products_media_light_en.png) | [PNG](previews/media_first/products_media_dark_en.png) | [PNG](previews/media_first/products_absent_light_en.png) | [PNG](previews/media_first/products_absent_dark_en.png) | [PNG](previews/media_first/products_media_dark_ar.png) | [PNG](previews/media_first/products_absent_dark_ar.png) |
| Offers listing | [PNG](previews/media_first/offers_media_light_en.png) | [PNG](previews/media_first/offers_media_dark_en.png) | [PNG](previews/media_first/offers_absent_light_en.png) | [PNG](previews/media_first/offers_absent_dark_en.png) | [PNG](previews/media_first/offers_media_dark_ar.png) | [PNG](previews/media_first/offers_absent_dark_ar.png) |
| Practitioner cards | [PNG](previews/media_first/practitioners_media_light_en.png) | [PNG](previews/media_first/practitioners_media_dark_en.png) | [PNG](previews/media_first/practitioners_absent_light_en.png) | [PNG](previews/media_first/practitioners_absent_dark_en.png) | [PNG](previews/media_first/practitioners_media_dark_ar.png) | [PNG](previews/media_first/practitioners_absent_dark_ar.png) |
| Consultation busy control | [PNG](previews/media_first/busy_media_light_en.png) | [PNG](previews/media_first/busy_media_dark_en.png) | [PNG](previews/media_first/busy_absent_light_en.png) | [PNG](previews/media_first/busy_absent_dark_en.png) | [PNG](previews/media_first/busy_media_dark_ar.png) | [PNG](previews/media_first/busy_absent_dark_ar.png) |

[Open the screenshot gallery](previews/media_first/index.html). Reproduce using:

```bash
flutter test test/media_first_previews_test.dart --update-goldens \
  --dart-define=MEDIA_FIRST_CAPTURE_DIR=/absolute/path/to/capture-directory
```

This command generates review artifacts. The normal suite does not rewrite them. Existing `test/goldens/patient_clinic_*.png` remain unchanged; no golden expectations were replaced merely to silence a failure. Tests wait for real decoded frames. The FileImage fixture providers are warmed at their exact bounded sizes outside the fake test clock; unreadable images fail instead of being captured blank.

## Visual decisions and acceptance

- **VIP:** responsive 16:9 real media before identity; paid sponsorship is explicit and distinct from subscription-only partner priority. The clinic logo is contained separately. Verified-source Google presentation is preserved; fixture numbers are not production verification. Consultation precedes exploration.
- **Clinics:** 3:2 photographs, smaller contained logos and tighter identity/action spacing. Missing or failed photography leaves a compact card, not an empty media panel. The last card remains scrollable above the navigation; MainNavScreen keeps its existing non-extended body and safe-area navigation.
- **Profile:** responsive 16:9 gallery panels use actual container constraints and deduplicate covers/gallery entries. Missing gallery produces no photo panel. A source without independent gallery records cannot demonstrate a real multi-photo clinic gallery.
- **Products:** contained packaging, approximately 4:5 at small card widths, with bounded height for wide cards. Brand and sponsor remain readable. Absent photos use compact brand identity. No price, purchase, cart, checkout, call or WhatsApp action was added.
- **Offers:** real 16:9 banners, clear clinic association, source descriptions limited to a readable excerpt, permitted offer prices and consultation inquiry. Original source strings are preserved; no CMS marketing text is invented.
- **Practitioners:** real portrait sources get 3:4 framing; missing portraits use a small identity fallback. Type/specialty/clinic stay flexible. The labeled portrait fixture validates geometry only. No rating, license registry or qualification was fabricated.
- **Feedback:** SilverButton measures idle and progress content together, preserving dimensions. Loading retains contrast, readable localized progress and a spinner; semantics expose progress. The activated action alone locks. Inline contextual errors allow the same action to retry. Instant card/detail/filter navigation retains native pressed feedback without artificial network delays. Interactive LuxuryCard adds button semantics and keyboard activation.
- **Video:** a real video with no poster has measurable bounds; a record with no media still collapses. Only active, visible, foreground, current-route/tab video allocates a controller. Leaving disposes it; late initialization cannot play. Reduced motion requires explicit play. Controls provide loading, pause/play and retry; playback remains muted and bounded to 15 seconds.
- **Themes:** existing navy `#070C1A`, dark gold `#D4AF37`, accessible light gold `#9A7B1C`, warm light surfaces and deep typography are retained. Reviewed English Light/Dark and representative Arabic RTL renders. Existing 320px/large-text theme/locale tests remain; new photo-layout coverage includes 320px and 600px RTL at 1.6× text.

Visual review corrected two actual issues before acceptance: gallery sizing based on the whole window, and a progress label constrained to the idle text's height. The bounded carousel also scrolls when directly hosted in a short viewport. Missing-media screens intentionally show available content only; a short dataset is not filled with fabricated cards.

## Behavior and verification

The reusable `AsyncActionButton` starts a local synchronous duplicate guard before awaiting, displays progress immediately, checks session, route/tab and mounting after prerequisites, and restores state in `finally`. Account changes, disposed routes, hidden tabs and cancelled API requests do not trigger stale navigation or stale error display. No underlying security architecture was replaced.

Applied to Home/Offers inquiry and clinic exploration, Home/directory/profile consultation, clinic staff/offer consultation, practitioner-profile consultation, and referral copy/share. Login/register/reset/OTP flows retain their existing repository/session logic and use the improved shared loading control plus synchronous duplicate guards. OTP resend retains its separate lock with matched icon dimensions. Product/article/practitioner detail taps already navigate immediately through pressed cards; filter Apply is synchronous and remains a native pressed action.

The Offers list also shows its loading skeleton during the initial pending fetch, rather than prematurely displaying an empty result.

Tests retain genuine file/asset/network decoding, provider-type checks, signed URL preservation and fallback assertions. New coverage includes media priority, ambiguous video-as-image payloads, posterless video, reduced motion, 15-second seeking, button size/semantics, pre-frame duplicate taps, independent actions, error/retry, awaited navigation, session/disposal/tab cancellation, actual OffersScreen delayed fetch/retry, responsive photos and the 42 rendered cases. The delayed-video lifecycle test now asserts visible progress without calling `pumpAndSettle` on an intentionally unresolved indeterminate animation; its no-late-play and disposal assertions remain.

Final Linux gates:

| Gate | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool` | 205 files, 0 changes |
| `flutter analyze` | 0 issues |
| `flutter test --reporter expanded` | **496 passed, 0 failed** |
| Regression count | Original 436 retained + 60 new (15 media/action, 3 video, 42 render cases) |
| Render capture matrix | 42/42 passed, with actual decoded frames |
| Existing clinic goldens | Unchanged; original comparisons pass |
| `git diff --check` | Passed |
| Django reference inventory | All 641 file hashes unchanged |
| History | Clinic `c6fe01d`, Super Admin `47127b7`, Windows `e15030d`, Patient `a535ac7`, Security `811b1bb`, Performance `242aa87` are all ancestors |

PRs #6, #7 and #8 were verified open and unmerged before publication. The performance branch remains at the requested baseline; `main` was not changed. This branch adds one reviewable media/interaction commit on top.

## Remaining limits and backend dependencies

- **Live images remain unverified.** No authorized production response/object or successful live upload was supplied. A valid URL may still be inaccessible, expired, absent from storage or non-image bytes. This work fixes confirmed display behavior; it does not declare production persistence repaired.
- Latest archive already contains shared clinic/Home serialization and scoped catalog image handling. Confirm deployment parity. Ad video/poster ambiguity and cover-only gallery are confirmed source limitations. CDN access, storage flags/persistence, ownership validation on string references and signed expiry require backend validation. See the bilingual [handoff for Ali](MEDIA_FIRST_BACKEND_HANDOFF_FOR_ALI.md).
- Low-quality CMS strings such as `anything`, absent licensed photos or missing brands require source/content-owner action. They are not silently rewritten. No production dataset was supplied to quantify affected records.
- Linux Flutter tests use real image decoding and a fake video platform for lifecycle policy. Windows-target styling/path tests are not native Windows execution. Android-target previews are not an emulator/device run. Native Windows file IO, physical Android/iOS video codecs, GPU/performance, OS sharing, backgrounding and network/CDN playback require device validation. No native production-video or signed-CDN delivery claim is made.
