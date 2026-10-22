# Category media artwork and first-launch preferences

PR: [#10](https://github.com/majd-khalifa/AestheticWay/pull/10), branch `codex/patient-luxury-design-reference-lock`. Approved baseline: `a4f56e492c58494c0912333139aeb58e5a4e9908`. This is a scoped follow-up; the luxury layouts, typography, five navigation tabs, Featured placement, Clinic/Admin portals and consultation/My Requests work are preserved. The PR remains open for review, without automatic merging.

## Artwork and integration

The former cover-sized AW/circle motif is replaced by eight original vector compositions. Only the square logo category uses a compact AW hallmark. All other categories are recognizable through their forms, not a changed caption. No runtime assets are downloaded or generated, and no stock imagery, real-world identities, product labels, medical claims or photography are invented.

[Art family overview, full-resolution renders and comparisons](patient-media-family/README.md) includes both themes, all four language/theme combinations, 390px and 320px widths, real fixture pixels, missing sources and genuine corrupt-file decoder failures. Screenshots are actual Flutter output with explicitly synthetic test records; they do not establish production content availability.

| Typed category | Original composition | Patient components |
| --- | --- | --- |
| `clinicCover` | Layered architectural arches, recessed planes and stepped plinth | Featured carousel poster/fallback; clinic directory cover; gallery hero/thumbnails; clinic photograph thumbnail on treatment detail |
| `clinicLogo` | Square, finely framed AW hallmark | Clinic-card identity and clinic-profile identity slots |
| `product` | Two abstract, unlabelled cosmetic vessels and a botanical accent | Brand showcase card/detail media; product inquiry thumbnail |
| `treatment` | Layered contours, an abstract drop and botanical forms | Home/clinic treatment cards; treatment directory thumbnails and detail hero |
| `offer` | Folded envelope, champagne band and ribbon | Home, clinic and directory promotional cards |
| `article` | Offset editorial sheets, abstract drop cap and ruled columns | Article directory/card and detail cover |
| `practitioner` | Faceless illustrative silhouette in a soft portrait panel | Practitioner directory/card/profile and article author avatars |
| `consultation` | Overlapping conversation forms | Consultation clinic-context thumbnail when the selected clinic photo is absent |

The required category parameter is compile-time enforced on `PatientImage`, `PatientMediaBanner` and `PatientMediaPlaceholder`. Layouts own dimensions and clipping; category selection changes only fallback artwork. Banner ratios, split-card widths, portrait heights, product packshot `contain`, touch targets, source-specific media precedence, decode budgets and 20-item lazy paging remain intact. A real picture and missing/failed fallback occupy the same frame. Total card height can still respond to genuine text/metadata and accessibility scaling.

The painter scales paths uniformly, omits fine editorial detail on small thumbnails and uses theme-specific ivory/pearl/taupe or navy/champagne planes. Artwork captions explicitly say Illustration or Image unavailable, with Arabic equivalents. Screen-reader labels distinguish a missing source, a decode failure and a known video in an image field; localized hints name the motif and state that it is a neutral illustration. Caption ink meets 4.5:1 against the darkest/lightest respective base gradient endpoints; the artwork itself is decorative. No new animations, image-generation APIs, graphics packages or font dependencies were introduced.

See [asset inventory](patient-media-family/asset_inventory.json) for exact source/PNG sizes, renderer methods, format and purpose. Runtime artwork is one shared Dart/Canvas source, not eight raster downloads. Documentation PNGs are review evidence, not application assets. APK-size delta is not claimed without an Android build.

## Real-media priority and failure integrity

Existing parsers and legitimate source-specific fallbacks retain their contract-defined order. A genuine source uses the original provider/cache path; no subject-based filtering, replacement clinic photo, portrait substitution or changed media URL is introduced. The patient wrapper passes an optional typed error panel to `LuxuryImage`; its default remains null, preserving existing Clinic/Admin fallback behavior. The shared resolver, upload/cache persistence, signed URL handling, provider keys, decode bounds and video playback/controller logic are unchanged.

Known video extensions are rejected by the patient image wrapper and product image component before an image codec/network request. Extensionless sources still rely on the backend image field and actual decoder result; no HEAD request or content fabrication is added. Explicit video fields remain handled by the existing video player. If a deployed serializer puts video/invalid objects in image fields, that data-contract defect still needs server-side investigation.

`PatientMediaFallbackReason` exposes `missing`, `loadFailed` or `unsupportedSource` in widget diagnostics and semantics. It never stores or prints a URL, query token, patient field, backend exception or entity identity. No new production logging is added. Missing photos do not become clinic logos for staff. Gallery counts/thumbnails remain derived solely from supplied real entries, with no invented count or replacement media.

## First-launch root cause and correction

The baseline already used English/Light defaults, awaited secure-storage hydration before `runApp`, serialized preference writes, guarded stale reads and exposed storage-write failures. Those fixes and the keys `aw_pref_locale` / `aw_pref_theme_mode` remain unchanged. Android encrypted-store options, iOS keychain accessibility, auth-only logout clearing and explicit System theme support remain compatible with saved preferences.

The remaining visual defect was outside those defaults: `SplashScreen` always painted a navy canvas, while Android's night LaunchTheme/NormalTheme inherited a black native theme. Android 12+ also needed an explicit OS splash background. A new installation could therefore look dark even when Flutter's actual theme choice was Light.

The Flutter splash now uses the hydrated app theme and corresponding system-bar contrast. Its official logo remains unchanged. Android day/night startup resources use a neutral ivory canvas, including explicit API31+ splash surfaces. Native startup displays no locale-dependent text and does not attempt to read encrypted preferences before Flutter initializes. Saved Dark/System still takes effect in the first **Flutter application** frame; a neutral native pre-engine surface is not a saved-theme reset. `main()` now has an awaitable `Future<void>` signature for direct bootstrap tests; its initialization ordering and session/role security remain unchanged. iOS already has a white native storyboard and needs no change for fresh Light launch.

Tests invoke the real `main()` with empty or stored values under an Arabic/Dark dispatcher, inspect the first application frame's locale, direction, theme and splash background, then dispose its navigation timer. Explicit Light remains Light when OS brightness changes; Dark and System retain their intended behavior. Existing cold-instance restoration, logout retention, ordered toggles, late-read race and visible write-failure/retry tests remain in the suite. Screenshot fixtures establish their fake frame epoch before `runApp`; no production animation is removed or delayed to satisfy a test.

## Validation and evidence boundaries

Local Flutter 3.41.5 / Dart 3.11.3: **737 full-suite tests pass; analyzer zero issues**. The **336-case screen render matrix** passes, including both widths, all four theme/language combinations and actual/missing/corrupt media. New automated coverage adds **107 cases**: 96 category/theme/language/frame/provider tests, two video-source safety tests, one full artwork golden and eight startup/OS preference tests. Existing assertions and timeout values remain; no tests are skipped, removed or made permissive.

The new failure-render helper listens to genuine image streams and requires the intended corrupt provider to fail while other sources decode real pixels. Failed decodes leave ImageCache, so public widget-tree reassembly reconnects ImageState in the real async zone before its new error is awaited. It neither suppresses arbitrary errors nor treats a placeholder as a successful photo. Existing normal-frame decode settling remains unchanged.

The intentional new `patient_category_placeholders_v4` family retains separate exact Linux/Windows rasters and the shared 1/16dp geometry/style guard. The all-category contact sheet is also an exact native golden. The regression workflow adds the two new test files and captures that sheet alongside clinic candidates; pinned actions, permissions, signing and deployment behavior are unchanged. Native Windows run39754509562 exposed a fixture mismatch: `File.fromUri` normalizes Windows separators while a constructed raw path retained mixed separators. Corrupt-fixture detection now compares canonical absolute file URIs. That same probe exposed deletion of a decoder-mapped temporary source before Windows released the mapping. Both harnesses now read a checked-in, intentionally invalid fixture for the process lifetime; real FileImage/codec failure and provider assertions remain mandatory. No catch-and-ignore cleanup, skipped case, fake image or larger timeout is used. Its nine native capture cases passed; five rasters were visually reviewed and all four clinic geometry/style JSON snapshots exactly matched Linux before adoption. Ubuntu run39754509562 passed 737 full tests, 291 focused tests and analysis with zero issues for the original implementation. This initial probe was not a passing Windows validation. Older golden families and historical capture manifests remain intact. See [native provenance](../test/goldens/patient_category_placeholders_v4/provenance.json). After the fixture correction, [native validation run 39755812602](https://github.com/majd-khalifa/AestheticWay/actions/runs/39755812602) passed on **Ubuntu 24.04 and Windows Server 2022** at code commit `cdc0e11f445ebd2b7a3baf770eae98346e80ea61`: **737 full tests, 291 focused tests and analyzer zero issues on each host**, plus nine candidate-capture cases per host and the Windows offline privacy check. Subsequent documentation changes do not change application/test code; final PR-head checks remain required. Linux success alone is not called Windows verification.

**Physical Android/iOS execution is unavailable here; native Android resource compilation was not performed.** Automated dispatcher/storage fixtures and Linux-hosted Android-target renders do not prove physical cold launches or OEM splash behavior. No live API, deployed serializer, real upload availability or Google delivery is claimed verified. Django, production media, consultation cooldowns, backend spam protection, JWT refresh, source metadata/rating rules, signing and release configuration are untouched.

## Physical-device acceptance checklist

Use a dedicated QA device/account. The data-clear command below deletes this app's local login and preferences; do not run it on an installation whose local state must be retained. No token, password or patient payload is needed for these steps.

1. In Android Settings, choose Arabic as the device language and turn on Dark theme. For the first-install case, prepare the current debug build and clear **only this QA installation**:

   ```powershell
   flutter build apk --debug
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   adb shell pm clear com.aestheticway.aesthetic_way
   adb shell am force-stop com.aestheticway.aesthetic_way
   adb shell monkey -p com.aestheticway.aesthetic_way -c android.intent.category.LAUNCHER 1
   ```

2. Record the launch from before tapping the icon. The OS/native surface should be neutral Light; the first Flutter app frame should be Light and the onboarding/login UI English/LTR, regardless of the device's Arabic/Dark settings. Repeat on pre-Android12 and Android12+ if available, including a small device and enlarged system text. No patient portal is available before authentication.
3. Log into a QA account. In Profile choose Arabic and Light; wait until Saving preference disappears and no retry error is shown. Force-stop and reopen with the last two commands. Verify Arabic/RTL and Light. Repeat for English/Dark and Arabic/Dark, then English/Light. Do not call a warm activity resume a cold launch.
4. With Light explicitly selected, change OS brightness to Dark and back, including an OS scheduled transition. App content must remain Light. Select System in Profile and repeat; app content should now follow the OS. Then select Light and verify it stops following.
5. After the saved setting is committed, log out, force-stop and reopen. Language/theme must remain saved while authentication is absent. Upgrade using `adb install -r` without `pm clear`; existing settings must survive. An uninstall/OS restore or iOS keychain retention scenario must be assessed separately, not described as empty storage.
6. With owner-authorized QA records, verify real photos, records with absent media and a controlled unreachable/corrupt test media object. Compare the category art and dimensions to the linked renders. Never alter genuine production media to create this scenario. Verify profile/gallery, Featured carousel, products, treatments, offers, articles, practitioners and the consultation context in both languages/themes.
7. On iOS use the existing signing workflow on a QA device, repeat the same in-app save/force-quit/relaunch/logout/System cases, and verify the native-to-Flutter transition. Do not assume uninstall clears the keychain. Do not revoke auth/secure storage or modify production signing to induce storage failure; automated adapters cover controlled failure/retry.

Write down device model, OS/API, app commit/build, cold-start method and observed first-frame locale/theme. Captures should exclude account details and patient content. Report any OEM/native discrepancy before claiming device acceptance.

## Exact implementation files

### Flutter production sources

- [`lib/core/widgets/luxury_image.dart`](../lib/core/widgets/luxury_image.dart)
- [`lib/core/widgets/patient_image.dart`](../lib/core/widgets/patient_image.dart)
- [`lib/core/widgets/patient_media_banner.dart`](../lib/core/widgets/patient_media_banner.dart)
- [`lib/core/widgets/patient_media_placeholder.dart`](../lib/core/widgets/patient_media_placeholder.dart)
- [`lib/features/appointment_lead/presentation/screens/appointment_request_screen.dart`](../lib/features/appointment_lead/presentation/screens/appointment_request_screen.dart)
- [`lib/features/articles/presentation/screens/article_detail_screen.dart`](../lib/features/articles/presentation/screens/article_detail_screen.dart)
- [`lib/features/articles/presentation/screens/articles_screen.dart`](../lib/features/articles/presentation/screens/articles_screen.dart)
- [`lib/features/clinics/presentation/screens/clinic_profile_screen.dart`](../lib/features/clinics/presentation/screens/clinic_profile_screen.dart)
- [`lib/features/clinics/presentation/widgets/patient_clinic_card.dart`](../lib/features/clinics/presentation/widgets/patient_clinic_card.dart)
- [`lib/features/clinics/presentation/widgets/patient_clinic_gallery.dart`](../lib/features/clinics/presentation/widgets/patient_clinic_gallery.dart)
- [`lib/features/home/presentation/widgets/featured_ads_carousel.dart`](../lib/features/home/presentation/widgets/featured_ads_carousel.dart)
- [`lib/features/offers/presentation/widgets/patient_offer_card.dart`](../lib/features/offers/presentation/widgets/patient_offer_card.dart)
- [`lib/features/practitioners/presentation/screens/practitioner_profile_screen.dart`](../lib/features/practitioners/presentation/screens/practitioner_profile_screen.dart)
- [`lib/features/practitioners/presentation/widgets/patient_practitioner_card.dart`](../lib/features/practitioners/presentation/widgets/patient_practitioner_card.dart)
- [`lib/features/products/presentation/widgets/brand_product_media.dart`](../lib/features/products/presentation/widgets/brand_product_media.dart)
- [`lib/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart`](../lib/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart)
- [`lib/features/splash/presentation/screens/splash_screen.dart`](../lib/features/splash/presentation/screens/splash_screen.dart)
- [`lib/features/treatments/presentation/screens/treatment_detail_screen.dart`](../lib/features/treatments/presentation/screens/treatment_detail_screen.dart)
- [`lib/features/treatments/presentation/screens/treatments_screen.dart`](../lib/features/treatments/presentation/screens/treatments_screen.dart)
- [`lib/features/treatments/presentation/widgets/patient_treatment_card.dart`](../lib/features/treatments/presentation/widgets/patient_treatment_card.dart)
- [`lib/main.dart`](../lib/main.dart)

### Tests and helpers

- [`test/media_first_previews_test.dart`](../test/media_first_previews_test.dart)
- [`test/patient_final_polish_test.dart`](../test/patient_final_polish_test.dart)
- [`test/patient_media_family_test.dart`](../test/patient_media_family_test.dart)
- [`test/patient_portal_visual_test.dart`](../test/patient_portal_visual_test.dart)
- [`test/patient_startup_preferences_test.dart`](../test/patient_startup_preferences_test.dart)
- [`test/patient_visual_recovery_test.dart`](../test/patient_visual_recovery_test.dart)
- [`test/support/clinic_golden_geometry.dart`](../test/support/clinic_golden_geometry.dart)
- [`test/support/settle_expected_media_errors.dart`](../test/support/settle_expected_media_errors.dart)

### Native startup UI resources

- [`android/app/src/main/res/drawable-v21/launch_background.xml`](../android/app/src/main/res/drawable-v21/launch_background.xml)
- [`android/app/src/main/res/drawable/launch_background.xml`](../android/app/src/main/res/drawable/launch_background.xml)
- [`android/app/src/main/res/values-night-v31/styles.xml`](../android/app/src/main/res/values-night-v31/styles.xml)
- [`android/app/src/main/res/values-night/styles.xml`](../android/app/src/main/res/values-night/styles.xml)
- [`android/app/src/main/res/values-v31/styles.xml`](../android/app/src/main/res/values-v31/styles.xml)
- [`android/app/src/main/res/values/colors.xml`](../android/app/src/main/res/values/colors.xml)
- [`android/app/src/main/res/values/styles.xml`](../android/app/src/main/res/values/styles.xml)

### Regression CI

- [`.github/workflows/flutter-visual-regressions.yml`](../.github/workflows/flutter-visual-regressions.yml)

New golden files are under `test/goldens/patient_category_placeholders_v4/`; review evidence, asset inventory and hashes are under `docs/patient-media-family/`. Older reports and their capture manifests remain historical. All pre-existing commits and Clinic Portal history remain in the branch.

Test-only fixture additions: [`test/fixtures/media/intentionally_corrupt_image.fixture`](../test/fixtures/media/intentionally_corrupt_image.fixture), documented in [`test/fixtures/media/README.md`](../test/fixtures/media/README.md). The fixture is plain text, not a runtime application asset.
