# Targeted Android QA rendered comparisons

Actual Flutter widget renders at **390×844 logical pixels**, Android target presentation, captured on **Linux**, Flutter **3.41.5**, Dart **3.11.3**. These are not physical Android captures, not production API evidence, and not native Windows verification. Data/people/brands shown are explicit test fixtures. Photograph provenance remains in `test/fixtures/media/README.md`. No fixture is injected into production code.

The baseline is unchanged production commit `229ad3d`; after frames use the production/library hashes in [capture_manifest.json](capture_manifest.json). The 20 before frames, 24 after frames and 20 comparison boards cover the targeted changes. Historical eight-reference previews and owned Linux/Windows goldens remain in their previous directories untouched.

| Focus | Before → after | Variants / evidence |
| --- | --- | --- |
| Missing clinic media and repeated actions | [Comparison](comparisons/directory_absent_light_en.png) | [Dark Arabic](comparisons/directory_absent_dark_ar.png); identity is compact, actions share a row at ordinary phone text size. |
| Genuine clinic photo | [Comparison](comparisons/directory_media_light_en.png) | [Dark Arabic](comparisons/directory_media_dark_ar.png); genuine 3:2 photo remains prominent; async guarded actions preserved. |
| Missing product media | [Comparison](comparisons/products_absent_light_en.png) | [Dark Arabic](comparisons/products_absent_dark_ar.png); supplied brand/product identity replaces redundant showcase strip. |
| Genuine product packshot | [Comparison](comparisons/products_media_light_en.png) | [Dark Arabic](comparisons/products_media_dark_ar.png); contained packshot and substantial framing preserved. |
| Staff portraits / missing portraits | [Photo](comparisons/practitioners_media_light_en.png), [absent](comparisons/practitioners_absent_light_en.png) | [Dark RTL portrait](comparisons/practitioners_media_dark_ar.png); portrait-led layout preserved. |
| Duplicate consultation rejection | [Light English](comparisons/rejection_light_en.png) | [Dark English](comparisons/rejection_dark_en.png), [light Arabic](comparisons/rejection_light_ar.png), [dark Arabic](comparisons/rejection_dark_ar.png). Baseline is deliberately scrolled to reveal both old error messages. Revised form automatically reveals one notice beside Submit. |
| History navigation and wording | [Comparison](comparisons/history_navigation_light_en.png) | Normal back button, My Requests title and truthful status labels. Baseline All count only represented its loaded page. |
| Profile discoverability while editing | [Comparison](comparisons/profile_edit_light_en.png) | My Requests stays above the expanded editing form. |
| Neutral role labels | [English](comparisons/roles_light_en.png), [Arabic](comparisons/roles_light_ar.png) | Doctor/Nurse/Specialist remain distinct without claims of licensing. Wire type `licensed_professional` remains unchanged. |
| History at 160% text | [Light English](after/history_light_en_large_text.png), [light Arabic](after/history_light_ar_large_text.png), [dark English](after/history_dark_en_large_text.png), [dark Arabic](after/history_dark_ar_large_text.png) | Full practitioner names wrap; no overflow. These are after-only stress renders, not mismatched-size before/after comparisons. |

The new photos are not product/clinic replacements: they are the same attributed test assets used by the existing preview harness. Valid synthetic rating fixtures explicitly carry a configured test Place ID. That change preserves the meaning of the positive rating tests; separate tests cover the real defect where an ID is empty but cached numbers remain. A configured ID does not establish actual Google business ownership.

Review against the approved references: component library 02 and Home 03 retain media-rich clinic composition; Products 07 retains contained packshot and editorial brand identity; Staff 05 retains portrait-led cards; Consultation 06 and Styleguide 08 retain palette, hierarchy and form composition, with business-rule deviations already approved. No photographs, fictional ratings, appointment selectors or shopping actions are copied from the references.

To regenerate only review images (absolute capture directories; no active golden baselines are overwritten):

```bash
flutter test test/media_first_previews_test.dart --update-goldens \
  --dart-define=MEDIA_FIRST_CAPTURE_DIR=/absolute/review/after \
  --name '(directory|products|practitioners)_(absent|media)_(light_en|dark_ar)'
flutter test test/patient_android_qa_test.dart --update-goldens \
  --dart-define=ANDROID_QA_CAPTURE_DIR=/absolute/review/after
```

For historical captures, use an isolated checkout of `229ad3d`, the media-preview command above with a before directory, and copy [baseline_capture_test.dart.txt](baseline_capture_test.dart.txt) to `test/android_qa_baseline_preview_test.dart` in that checkout. Run it with `ANDROID_QA_CAPTURE_DIR=/absolute/review/before`. It deliberately verifies the historical double toast/banner, missing back button and licensing labels. It is not a test to copy onto the fixed branch. Existing media settling still waits for genuine decoded mounted provider frames; no timeouts were raised and no image assertions or tests were skipped.

Host fonts may render the UAE flag as missing emoji glyphs; the phone widget's actual flag/dial code is preserved. Accessibility/RTL layout is covered here; native Android emoji, keyboard, system bars and production media still require device confirmation.
