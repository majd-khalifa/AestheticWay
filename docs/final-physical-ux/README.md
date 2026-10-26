# Actual Flutter-rendered comparisons

2026-10-26 · Linux Flutter3.41.5/Dart3.11.3 ·430×1000 at DPR1.
The identical preview harness ran on unmodified detached baseline **f20ab75** and
the current working tree:8 tests/36 captures per version, all passing.
[PNG dimensions/hashes and identical harness hashes](render-manifest.json).

These are genuine Flutter `RepaintBoundary` captures, not generated artwork.
All names/records are explicitly disposable fixtures; photos are genuine
decoded [test-only media](../../test/fixtures/media/README.md). No fixture data
is added to production. Reduced motion holds the Featured poster for capture.
The video player is tested with an explicit platform fake; these captures do
not demonstrate a native texture, real playback, production Google, live R2 or
GPS. OSM tiles stay offline under the widget HTTP boundary: the gray map with
pin/attribution is intentional test evidence, **not claimed live cartography**.

| Surface | Main implementation | Before → after |
|---|---|---|
| Featured Clinics, Light EN | `featured_ads_carousel.dart`, `patient_video.dart` | [Comparison](comparison_featured_light_en.png) |
| Patient clinic video/gallery, Dark AR | patient `clinic_profile_screen.dart`, `patient_clinic_gallery.dart` | [Comparison](comparison_patient_profile_dark_ar.png) |
| GPS distance/origin and request CTA, Light EN | `nearby_clinics_screen.dart` | [Comparison](comparison_nearby_gps_light_en.png) |
| Independent entrance/business entry, Light EN | `clinic_location_selector.dart` | [Comparison](comparison_clinic_location_light_en.png) |
| Three-step locality selector, Dark AR | `uae_location_picker.dart` | [Comparison](comparison_locality_dark_ar.png) |
| Directory filter, Dark EN | `filter_bottom_sheet.dart` | [Comparison](comparison_filters_dark_en.png) |
| Exact selected Google identity, Light AR | `google_business_screen.dart` | [Comparison](comparison_google_selected_light_ar.png) |
| Manual city browsing without kilometers, Dark AR | `nearby_clinics_screen.dart` | [Comparison](comparison_nearby_manual_dark_ar.png) |

Every row/surface has all four modes. The raw full-size directories are
[before](before/) and [after](after/); filenames end in `light_en`, `light_ar`,
`dark_en`, `dark_ar`. Nine surface prefixes: `featured`, `patient_profile`,
`nearby_gps`, `nearby_manual`, `locality`, `clinic_location`, `google_business`,
`google_selected`, `filters`.

Reviewed output: photographic proportions/branding remain; profile now has an
opt-in video first slot and retained photo thumbnail. The distance badge is
visible without adding kilometers to manual browsing. Locality selected-state
contrast, parent path, search, reset and filter hierarchy remain readable in
Light/Dark and RTL. Exact Google detail coordinates are text/Google inspection,
never placed on the OSM map. No existing golden baseline was overwritten.

Reproduce current captures from the repository root:

```sh
flutter test test/final_physical_ui_preview_test.dart \
  --dart-define=ONBOARDING_REVIEW_CAPTURE_DIR=/absolute/output/path \
  --reporter expanded
```

For baseline comparison, create a detached worktree atf20ab75, copy only this
test harness plus `test/support/offline_map_test_cache.dart`, and run the same
command there. Do not modify baseline production files or check out over the
working branch. Fonts and decoded-image settling use the existing shared test
helpers. Native Windows/Ubuntu CI uploads its own current-commit captures.

[Verification](verification.json) · [Exact changed-file manifest](CHANGED_FILES.txt) ·
[Full report/device checklist](../FINAL_PHYSICAL_UX_REPORT.md) ·
[Bilingual backend gaps](../FINAL_PHYSICAL_UX_BACKEND_GAPS_FOR_ALI.md).
