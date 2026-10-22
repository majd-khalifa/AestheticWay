# Patient media and request-flow render review

Actual Flutter renders from Linux, Android target presentation, 390×844 logical pixels at DPR3. Test-only sample records and decoded photographs are explicitly illustrative; no live API or physical-device verification. Before captures use a5ec85d. After captures use the library/test hashes in [capture_manifest.json](capture_manifest.json).

The current request explicitly replaces compact missing-media layouts with equal media frames. Each comparison has three columns: **before missing media / after branded panel / after decoded test media**. Content height can differ when genuine metadata exists; the media geometry stays the same.

## Before / after comparisons

| Screen | Light English | Dark English | Dark Arabic RTL |
| --- | --- | --- | --- |
| home | [light_en](comparisons/home_light_en.jpg) | [dark_en](comparisons/home_dark_en.jpg) | [dark_ar](comparisons/home_dark_ar.jpg) |
| directory | [light_en](comparisons/directory_light_en.jpg) | [dark_en](comparisons/directory_dark_en.jpg) | [dark_ar](comparisons/directory_dark_ar.jpg) |
| clinic | [light_en](comparisons/clinic_light_en.jpg) | [dark_en](comparisons/clinic_dark_en.jpg) | [dark_ar](comparisons/clinic_dark_ar.jpg) |
| products | [light_en](comparisons/products_light_en.jpg) | [dark_en](comparisons/products_dark_en.jpg) | [dark_ar](comparisons/products_dark_ar.jpg) |
| offers | [light_en](comparisons/offers_light_en.jpg) | [dark_en](comparisons/offers_dark_en.jpg) | [dark_ar](comparisons/offers_dark_ar.jpg) |
| articles | [light_en](comparisons/articles_light_en.jpg) | [dark_en](comparisons/articles_dark_en.jpg) | [dark_ar](comparisons/articles_dark_ar.jpg) |
| practitioners | [light_en](comparisons/practitioners_light_en.jpg) | [dark_en](comparisons/practitioners_dark_en.jpg) | [dark_ar](comparisons/practitioners_dark_ar.jpg) |
| consultation | [light_en](comparisons/consultation_light_en.jpg) | [dark_en](comparisons/consultation_dark_en.jpg) | [dark_ar](comparisons/consultation_dark_ar.jpg) |
| clinic_staff | [light_en](comparisons/clinic_staff_light_en.jpg) | [dark_en](comparisons/clinic_staff_dark_en.jpg) | [dark_ar](comparisons/clinic_staff_dark_ar.jpg) |
| clinic_treatments | [light_en](comparisons/clinic_treatments_light_en.jpg) | [dark_en](comparisons/clinic_treatments_dark_en.jpg) | [dark_ar](comparisons/clinic_treatments_dark_ar.jpg) |
| clinic_offers | [light_en](comparisons/clinic_offers_light_en.jpg) | [dark_en](comparisons/clinic_offers_dark_en.jpg) | [dark_ar](comparisons/clinic_offers_dark_ar.jpg) |
| profile | [light_en](comparisons/profile_light_en.jpg) | [dark_en](comparisons/profile_dark_en.jpg) | [dark_ar](comparisons/profile_dark_ar.jpg) |

## Full-resolution final renders

| Screen | Missing media | Decoded test media |
| --- | --- | --- |
| home | [light_en](previews/after/home_absent_light_en.png) · [dark_en](previews/after/home_absent_dark_en.png) · [dark_ar](previews/after/home_absent_dark_ar.png) | [light_en](previews/after/home_media_light_en.png) · [dark_en](previews/after/home_media_dark_en.png) · [dark_ar](previews/after/home_media_dark_ar.png) |
| directory | [light_en](previews/after/directory_absent_light_en.png) · [dark_en](previews/after/directory_absent_dark_en.png) · [dark_ar](previews/after/directory_absent_dark_ar.png) | [light_en](previews/after/directory_media_light_en.png) · [dark_en](previews/after/directory_media_dark_en.png) · [dark_ar](previews/after/directory_media_dark_ar.png) |
| clinic | [light_en](previews/after/clinic_absent_light_en.png) · [dark_en](previews/after/clinic_absent_dark_en.png) · [dark_ar](previews/after/clinic_absent_dark_ar.png) | [light_en](previews/after/clinic_media_light_en.png) · [dark_en](previews/after/clinic_media_dark_en.png) · [dark_ar](previews/after/clinic_media_dark_ar.png) |
| products | [light_en](previews/after/products_absent_light_en.png) · [dark_en](previews/after/products_absent_dark_en.png) · [dark_ar](previews/after/products_absent_dark_ar.png) | [light_en](previews/after/products_media_light_en.png) · [dark_en](previews/after/products_media_dark_en.png) · [dark_ar](previews/after/products_media_dark_ar.png) |
| offers | [light_en](previews/after/offers_absent_light_en.png) · [dark_en](previews/after/offers_absent_dark_en.png) · [dark_ar](previews/after/offers_absent_dark_ar.png) | [light_en](previews/after/offers_media_light_en.png) · [dark_en](previews/after/offers_media_dark_en.png) · [dark_ar](previews/after/offers_media_dark_ar.png) |
| articles | [light_en](previews/after/articles_absent_light_en.png) · [dark_en](previews/after/articles_absent_dark_en.png) · [dark_ar](previews/after/articles_absent_dark_ar.png) | [light_en](previews/after/articles_media_light_en.png) · [dark_en](previews/after/articles_media_dark_en.png) · [dark_ar](previews/after/articles_media_dark_ar.png) |
| practitioners | [light_en](previews/after/practitioners_absent_light_en.png) · [dark_en](previews/after/practitioners_absent_dark_en.png) · [dark_ar](previews/after/practitioners_absent_dark_ar.png) | [light_en](previews/after/practitioners_media_light_en.png) · [dark_en](previews/after/practitioners_media_dark_en.png) · [dark_ar](previews/after/practitioners_media_dark_ar.png) |
| consultation | [light_en](previews/after/consultation_absent_light_en.png) · [dark_en](previews/after/consultation_absent_dark_en.png) · [dark_ar](previews/after/consultation_absent_dark_ar.png) | [light_en](previews/after/consultation_media_light_en.png) · [dark_en](previews/after/consultation_media_dark_en.png) · [dark_ar](previews/after/consultation_media_dark_ar.png) |
| clinic_staff | [light_en](previews/after/clinic_staff_absent_light_en.png) · [dark_en](previews/after/clinic_staff_absent_dark_en.png) · [dark_ar](previews/after/clinic_staff_absent_dark_ar.png) | [light_en](previews/after/clinic_staff_media_light_en.png) · [dark_en](previews/after/clinic_staff_media_dark_en.png) · [dark_ar](previews/after/clinic_staff_media_dark_ar.png) |
| clinic_treatments | [light_en](previews/after/clinic_treatments_absent_light_en.png) · [dark_en](previews/after/clinic_treatments_absent_dark_en.png) · [dark_ar](previews/after/clinic_treatments_absent_dark_ar.png) | [light_en](previews/after/clinic_treatments_media_light_en.png) · [dark_en](previews/after/clinic_treatments_media_dark_en.png) · [dark_ar](previews/after/clinic_treatments_media_dark_ar.png) |
| clinic_offers | [light_en](previews/after/clinic_offers_absent_light_en.png) · [dark_en](previews/after/clinic_offers_absent_dark_en.png) · [dark_ar](previews/after/clinic_offers_absent_dark_ar.png) | [light_en](previews/after/clinic_offers_media_light_en.png) · [dark_en](previews/after/clinic_offers_media_dark_en.png) · [dark_ar](previews/after/clinic_offers_media_dark_ar.png) |
| profile | [light_en](previews/after/profile_absent_light_en.png) · [dark_en](previews/after/profile_absent_dark_en.png) · [dark_ar](previews/after/profile_absent_dark_ar.png) | [light_en](previews/after/profile_media_light_en.png) · [dark_en](previews/after/profile_media_dark_en.png) · [dark_ar](previews/after/profile_media_dark_ar.png) |
| busy | [light_en](previews/after/busy_absent_light_en.png) · [dark_en](previews/after/busy_absent_dark_en.png) · [dark_ar](previews/after/busy_absent_dark_ar.png) | [light_en](previews/after/busy_media_light_en.png) · [dark_en](previews/after/busy_media_dark_en.png) · [dark_ar](previews/after/busy_media_dark_ar.png) |

Scrolled Home/Clinic/Consultation/Profile images use `_scrolled.png` in [after](previews/after). Raw baseline renders are in [before](previews/before).

## Consultation and history QA captures

- [history_dark_ar_large_text](qa-after/history_dark_ar_large_text.png)
- [history_dark_en_large_text](qa-after/history_dark_en_large_text.png)
- [history_light_ar_large_text](qa-after/history_light_ar_large_text.png)
- [history_light_en_large_text](qa-after/history_light_en_large_text.png)
- [history_navigation_light_en](qa-after/history_navigation_light_en.png)
- [profile_edit_light_en](qa-after/profile_edit_light_en.png)
- [rejection_dark_ar](qa-after/rejection_dark_ar.png)
- [rejection_dark_en](qa-after/rejection_dark_en.png)
- [rejection_light_ar](qa-after/rejection_light_ar.png)
- [rejection_light_en](qa-after/rejection_light_en.png)
- [roles_light_ar](qa-after/roles_light_ar.png)
- [roles_light_en](qa-after/roles_light_en.png)

78 media preview cases produce 102 after frames. The 31-case request QA run produces 12 additional frames. 36 comparison boards retain the original screenshots without altering their UI. Fixture photography is never added as missing record content.

The original eight-reference mapping remains in the [reference recovery report](../PATIENT_REFERENCE_FIDELITY_RECOVERY_REPORT.md). This task preserves that hierarchy, real photo crops/packshot containment, Featured carousel, five tabs and project boundaries.

## Native golden review

- [Linux golden review](native-linux-golden-review.jpg)
- [Windows Server 2022 golden review](native-windows-golden-review.jpg)

Windows candidates from run39732045569 were inspected before adoption. Their four geometry/style JSON records exactly equal the Linux shared records. Native glyph raster differences retain separate exact PNG ownership, without percentage tolerance. Candidate capture passed8 cases; final full-suite CI is reported separately.
