# PR #10: caption-free placeholder artwork

This is the approved artwork from commit `a75308f985b631be887d2724bdc4dff0c3888359`, with only the visible footer captions removed. The before/after originals are actual Flutter 3.41.5 renders with the same fixtures and unchanged screen harness. They are Linux-hosted renders of the Android-target presentation, not physical-device screenshots or evidence of live API delivery.

## Change and preservation

`lib/core/widgets/patient_media_placeholder.dart` is the **only production file changed**. `_PremiumArtwork.paint()` no longer constructs or paints the caption `TextPainter`. The painter's now-unused language/failure arguments and caption-only logo guard were removed. The AW identity hallmark's separate `TextPainter` remains part of the approved logo motif.

All eight composition methods are byte-for-byte identical to the approved source. Gradients, colors, viewboxes, translation, stroke scaling, compact/portrait handling, frame sizes, aspect ratios and all consumers remain unchanged. All four clinic geometry/style JSON records are byte-for-byte unchanged. No new visible label or watermark replaces the captions.

The enclosing `Semantics(image: true)` retains its original localized missing-image, decode-failure and unsupported-media labels, category description and “not a photograph” hint. Arabic strings therefore intentionally remain in accessibility metadata; they are no longer passed to the artwork painter. Language and failure state can update announcements without changing the artwork pixels.

No navigation, consultation, My Requests, Google metadata, media resolution/upload/cache logic, entitlement priority, Django, signing, theme/locale storage or first-launch code changes. Existing startup regression tests continue to verify English/Light defaults and saved choices. Existing real-image decoding, provider-type and fallback assertions are retained.

## Before/after Flutter comparisons

Each comparison places **before on the left, after on the right**. Headers above screenshots and labels in the all-category contact sheet are review-only annotations, not text inside production media. Raw unaltered screenshots are in [before](before) and [after](after).

| Surface | Light English | Dark English | Light Arabic RTL | Dark Arabic RTL |
|---|---|---|---|---|
| Featured Clinics / Home | [Compare](comparisons/home_absent_light_en.png) | [Compare](comparisons/home_absent_dark_en.png) | [Compare](comparisons/home_absent_light_ar.png) | [Compare](comparisons/home_absent_dark_ar.png) |
| Clinic Directory | [Compare](comparisons/directory_absent_light_en.png) | [Compare](comparisons/directory_absent_dark_en.png) | [Compare](comparisons/directory_absent_light_ar.png) | [Compare](comparisons/directory_absent_dark_ar.png) |
| Clinic Profile | [Compare](comparisons/clinic_absent_light_en.png) | [Compare](comparisons/clinic_absent_dark_en.png) | [Compare](comparisons/clinic_absent_light_ar.png) | [Compare](comparisons/clinic_absent_dark_ar.png) |
| Products | [Compare](comparisons/products_absent_light_en.png) | [Compare](comparisons/products_absent_dark_en.png) | [Compare](comparisons/products_absent_light_ar.png) | [Compare](comparisons/products_absent_dark_ar.png) |
| Offers | [Compare](comparisons/offers_absent_light_en.png) | [Compare](comparisons/offers_absent_dark_en.png) | [Compare](comparisons/offers_absent_light_ar.png) | [Compare](comparisons/offers_absent_dark_ar.png) |

Full comparison overviews: [Light EN](overview_light_en.png), [Dark EN](overview_dark_en.png), [Light AR](overview_light_ar.png), [Dark AR](overview_dark_ar.png).

All eight motifs, both themes and three frame classes: [before](before/placeholder_family.png), [after](after/placeholder_family.png). The contact sheet includes 48 real Flutter-painted panels. Offers' narrow directory image frames already omitted captions; those comparisons appropriately remain pixel-identical rather than introducing a new visual change.

Genuine corrupt-file decoder failures, with original reason announcements retained:

| Surface | Light English failure | Dark Arabic RTL failure |
|---|---|---|
| Featured Clinics | [Compare](comparisons/home_failed_light_en.png) | [Compare](comparisons/home_failed_dark_ar.png) |
| Clinic Directory | [Compare](comparisons/directory_failed_light_en.png) | [Compare](comparisons/directory_failed_dark_ar.png) |
| Clinic Profile | [Compare](comparisons/clinic_failed_light_en.png) | [Compare](comparisons/clinic_failed_dark_ar.png) |
| Products | [Compare](comparisons/products_failed_light_en.png) | [Compare](comparisons/products_failed_dark_ar.png) |
| Offers | [Compare](comparisons/offers_failed_light_en.png) | [Compare](comparisons/offers_failed_dark_ar.png) |

## Verification and baseline ownership

- `test/patient_media_family_test.dart`: 16 new pixel/accessibility regressions cover eight categories × two themes. Each compares all three fallback reasons in both languages at the exact RGBA level and verifies the image semantics flag, localized label and neutral-illustration hint. The reviewed all-category golden and exact equality together guard against reintroducing painted captions. Existing 99 family tests keep genuine decoding, provider and geometry assertions.
- Before and after: **120 screen cases each**, five surfaces × three media states × four theme/language combinations × two widths (390/320dp). Each revision produced 168 PNGs including scrolled screens. Of the 168 pairs, 78 are pixel-identical; changed frames lose caption pixels only. Thirty full-resolution comparison figures and 31 original images per revision are retained here; all 168 pair hashes and difference bounds are in [review_manifest.json](review_manifest.json).
- Active `patient_category_placeholders_v4` rasters are intentionally updated for this user-approved caption removal. Historical output remains available at the prior commit and in this folder. Linux and Windows keep their own **exact native raster** baselines and unchanged shared geometry checks; no thresholds, skips, timeout increases or placeholder-widget substitutions.
- Local Linux formatting, analyzer, focused/full suite and native-host results are recorded below once completed. Native Windows candidates require visual and shared-geometry review before adoption. An initial stale-caption golden failure is not represented as a Windows pass.

### Validation results

Local Linux: **753/753 full tests**, **307/307 focused regressions**, analyzer **0 issues**, full `dart format .` and `git diff --check` clean. The 16 new regressions, 120 after-render cases and nine Linux golden capture cases pass. The complete artwork-sheet comparison changes exactly 4,494 pixels in seven eight-pixel footer bands; all portrait/thumbnail frames and the logo row remain exactly unchanged.

Native candidate review is complete: [run 39765113736](https://github.com/majd-khalifa/AestheticWay/actions/runs/39765113736), source commit `612c0e9ba9cce3706967fe1dfecd65da741eed76`. Ubuntu passed 753 full tests, 307 focused tests, analyzer zero and all nine capture cases. Windows passed 298 non-golden focused checks and all nine candidate capture cases; the nine expected comparisons against its old caption-bearing goldens failed. This initial Windows probe is **not** a full native Windows pass.

The five Windows-native rasters were visually reviewed before adoption. All four shared clinic geometry/style records match Linux byte-for-byte. The Windows family differs from its own prior baseline only in 3,955 caption pixels across seven nine-pixel footer bands; all portrait/thumbnail frames and the AW motif remain unchanged. Native font rasterization explains the eight-pixel Linux versus nine-pixel Windows caption bands; separate exact host baselines remain mandatory. [Native clinic review](native-windows-clinic-review.png), [native complete family](native-windows-family.png), [exact difference bounds/hashes](native-windows-pixel-review.json).

The authoritative **final revision's** native Windows/Ubuntu full-suite and analysis results are attached to [PR #10 checks](https://github.com/majd-khalifa/AestheticWay/pull/10/checks) and recorded with their exact tested SHA/run URL in its description. The candidate-review run above must not be confused with that final baseline-adoption verification. No tests or thresholds were weakened to adopt these baselines.

## Reproduce

```sh
dart format .
flutter test test/patient_media_family_test.dart
flutter test test/media_first_previews_test.dart --name 'Media-first preview (home|directory|clinic|products|offers)_(media|absent|failed)_' --dart-define=PREMIUM_PLACEHOLDER_REVIEW=true --dart-define=MEDIA_FIRST_CAPTURE_DIR=/absolute/review/output --update-goldens
flutter analyze
flutter test
git diff --check
```

The existing Ubuntu 24.04 / Windows Server 2022 PR workflow also runs focused regressions, analysis, the full suite, native capture cases and Windows offline public-response redaction checks. Its pins, permissions and test strategy are unchanged.

There is **no new backend dependency** for this local vector-only correction. Live media/Google delivery is outside this task and is not newly claimed as verified. Previous [artwork/startup work](../PATIENT_FINAL_PLACEHOLDERS_AND_PREFERENCES_REPORT.md) and all earlier PR #10 fixes remain intact. PR #10 stays open and unmerged.
