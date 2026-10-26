# P0 recovery — actual Flutter before/after evidence

2026-10-26 · identical harness on unchanged **bb9a676** and updated Flutter
production code.28 raw captures per version (seven surfaces × EN/AR × Light/Dark),
430×1000/DPR1, plus seven side-by-side comparisons. Each four-test preview run
passes. [Hashes, dimensions and renderer provenance](render-manifest.json).

| Surface | Concrete comparison | Implementation |
|---|---|---|
| Nurse without portrait;120-character specialty and blank title | [Old400 form → saved Nurse](comparison_practitioner_result_light_en.png) | `clinic_practitioners_screen.dart`, `practitioner_model.dart` |
| Actual saved/pending image rendering; safe rejected upload feedback and persistent Save | [Dark Arabic](comparison_gallery_failure_dark_ar.png) | `clinic_media_screen.dart`, `media_upload_service.dart`, `api_exception.dart` |
| Explicit Dubai/Sharjah address conflict | [Light English](comparison_location_conflict_light_en.png) | `clinic_location_selector.dart`, `clinic_location_integrity.dart` |
| Home GPS endpoint and actual-response km | [Light English](comparison_home_gps_light_en.png) | `home_screen.dart`, `home_gps_nearby_section.dart` |
| Dedicated Nearby distance within card identity | [Dark Arabic](comparison_nearby_distance_dark_ar.png) | `nearby_clinics_screen.dart`, `patient_clinic_card.dart` |
| Featured video translucent overlay | [Dark Arabic](comparison_featured_controls_dark_ar.png) | `patient_video.dart` |
| Clinic profile video translucent overlay | [Light English](comparison_profile_controls_light_en.png) | `patient_video.dart` |

Raw images: [before](before/) · [after](after/). Prefixes: `practitioner_result`,
`gallery_failure`, `location_conflict`, `home_gps`, `nearby_distance`,
`featured_controls`, `profile_controls`; suffixes `light_en`, `light_ar`,
`dark_en`, `dark_ar`.

These are actual Flutter RepaintBoundary screenshots. Names/API/GPS responses
are disposable fixtures; photos are genuine decoded [test-only assets](../../test/fixtures/media/README.md).
The long specialty deliberately exercises a boundary; it is not production
content. Baseline form failure uses the same source-confirmed title-length rule.
The gallery400 fixture demonstrates rejection feedback; it is not evidence that
the owner's real photo was corrupt. Offline OSM tiles render gray and are not
live cartography. Video poster captures use reduced motion; player behavior and
auto-hide are tested with an explicit platform fake, not claimed native playback.
No production data, Google response, R2 delivery or physical-device PASS is implied.

Reviewed output preserves photographic geometry, category placeholders and the
horizontal Home rhythm, while making GPS mode/distance, correction warnings,
field errors and gallery Save discoverable. The control gradient obscures less
media; its playing-state3s auto-hide, pause/accessibility exceptions and lifecycle
cleanup have separate widget assertions. No old golden was overwritten or weakened.

Reproduce from repository root:

```sh
flutter test test/p0_recovery_previews_test.dart \
  --dart-define=ONBOARDING_REVIEW_CAPTURE_DIR=/absolute/output/path \
  --reporter expanded
```

For baseline, create a detached worktree atbb9a676 and copy only this preview
test plus `test/support/recovery_preview_fixtures.dart`. Existing shared font,
image-settling and offline-map helpers are already in that commit. Do not change
baseline production files or overwrite the current branch. Native Windows and
Ubuntu CI produce their own current-commit captures.

[Root-cause report](../P0_REGRESSION_RECOVERY_REPORT.md) ·
[Android checklist](../P0_REGRESSION_RECOVERY_ANDROID_QA.md) ·
[Bilingual Ali handoff](../P0_REGRESSION_RECOVERY_BACKEND_HANDOFF_FOR_ALI.md) ·
[Source observations](source-evidence.json) · [Verification](verification.json) ·
[Exact file manifest](CHANGED_FILES.txt).
