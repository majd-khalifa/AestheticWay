# Patient Portal — approved design reference lock

Branch: `codex/patient-luxury-design-reference-lock`. Base: `b33a287a5fd4d8473044f93ca03f044bf083fd42` (`origin/main`, merged PRs #6–#9). Approved design archive SHA-256: `bd6d22fc988f3ca140c7dbd59198c60c13ed71341b853271800f612bf687de99`. The user approved the screen mapping and deviations before production edits.

## Result

The Patient Portal uses an ivory/champagne light presentation and midnight/navy dark presentation, bundled Playfair Display headings, Arabic-capable Noto Sans Arabic body typography, media-led cards, gold CTAs and the fixed Home / Clinics / Products / Offers / Profile navigation. Genuine media remains prominent. Missing or failed photography becomes a compact content-sized strip; missing product media uses supplied brand identity. There are no large empty photographic stages or invented replacement photographs. A real video may reserve a 16:9 playback stage to permit visibility detection and codec initialization.

The Featured Clinics carousel remains prominent. Home's real placement selection, stable entitlement priority, bounded directory enrichment, active-slide/tab/route/viewport lifecycle, reduced-motion controls and 15-second video policy are unchanged. VIP/FEATURED subscription badges and paid-placement details have been removed from patient presentation, not from internal entitlement logic.

## Screen-to-reference implementation mapping

All paths below are relative to `lib/`. Reference numbers correspond to the exact filenames in the approved archive.

| Target | References | Implemented files/components |
|---|---|---|
| Home | 03 Home; 01 Design System; 02 Components | `features/home/presentation/screens/home_screen.dart`; widgets `home_header.dart`, `category_grid.dart`, `featured_ads_carousel.dart`, `active_offers_section.dart`; shared clinic cards used by `nearby_clinics_section.dart`. |
| Clinics Directory | 02 Clinic Directory Card; 01/08 | `features/clinics/presentation/screens/clinics_list_screen.dart`; `widgets/patient_clinic_card.dart`, `google_clinic_rating.dart`: strong 3:2 real photo, separate identity/logo, genuine Google aggregate and Explore CTA. |
| Clinic Profile | 04 light; 05 dark header; 08 | Patient `features/clinics/presentation/screens/clinic_profile_screen.dart`; new `widgets/patient_clinic_gallery.dart`: real-count gallery, selectable thumbnails/swipes, four visible icon tabs, primary consultation and outlined contact/Maps actions. |
| Clinic medical staff / Practitioners | 05; 02 Doctor/Specialist Cards | `features/practitioners/presentation/widgets/patient_practitioner_card.dart`; patient directory/detail screens. Real portraits occupy 36% of available card width (bounded 90–170dp); absent portraits use 48dp identity. |
| Clinic treatments | 04/05 tabs; 02/08 material/card language | New `features/treatments/presentation/widgets/patient_treatment_card.dart`; clinic tab replaces plain rows with media, category, description and supported detail navigation. Treatment directory/detail receive patient styling. |
| Clinic offers | 04 Featured Offer; 02/08 | Clinic tab and `features/offers/presentation/widgets/patient_offer_card.dart`. |
| Products list / detail | 07 product cards/hero; 08 | `features/products/presentation/screens/products_screen.dart`, `product_detail_screen.dart`, `widgets/brand_product_media.dart`: contained real packaging media, actual brand/sponsor, description and showcase navigation. No price, cart, product rating or direct product contact. |
| Articles list / detail | 07 editorial cards/detail; 08 | `features/articles/presentation/screens/articles_screen.dart`, `article_detail_screen.dart`: large 16:10 covers, display headings, actual category/author/publication metadata. |
| Offers list | 02 Premium/Compact Offer Cards; 03; 08 | `features/offers/presentation/screens/offers_screen.dart`, `widgets/patient_offer_card.dart`: genuine imagery, localized inquiry, real offer terms/pricing where supplied. No checkout. |
| Consultation | 06; 08 form states | `features/appointment_lead/presentation/screens/appointment_request_screen.dart`: larger real selected-clinic image, grouped supported fields, white/midnight input surfaces, consent and guarded loading/submission CTA. Success and request-history routes receive scoped patient styling. |
| Profile | 01/08; 06 field states | `features/profile/presentation/screens/profile_screen.dart`: scoped materials/type, grouped cards, visible localized refresh progress, refresh coalescing and synchronous save guard. |
| Search/filter/empty/loading/navigation | 06; 08 | Screen controls, existing `filter_bottom_sheet.dart`, skeleton/empty/error widgets inherit scoped tokens; `features/navigation/main_nav_screen.dart` uses the fixed five-tab pill navigation and Home icon. |
| Shared patient system | 01/08 | New `core/theme/patient_design.dart`, `patient_theme_tokens.dart`; conditional hooks in `app_colors.dart`, `silver_button.dart`, `editorial_heading.dart`; `patient_media_banner.dart`. No Patient token extension means existing Clinic/Admin styling is retained. |

## Rendered visual review

[Open the preview index](patient-design-lock/README.md). It contains **96 before and 96 after PNGs**, generated by the Flutter software renderer at 390×844 logical pixels, DPR 3, capture ratio 1. Each of the eight mandatory screens has populated-media and missing-media states in light English, dark English and representative dark Arabic RTL. Additional renders show Profile, clinic Staff/Treatments/Offers tabs, busy feedback and scrolled Home/Consultation/Profile. The four-width 160% text test matrix additionally covers both languages and both themes at 320/360/390/430dp.

Eight comparison boards place the merged-main render, updated Flutter render and the approved reference together. Two matrices expose all eight required screens across media/theme/RTL states. Render bytes are recorded in `patient-design-lock/capture_manifest.json`.

These previews are **synthetic test data, not production evidence**. Clinic/offer/article fixtures reuse an existing onboarding image; product/practitioner fixtures are explicitly labelled packaging/portrait test images. Neither sample records nor reference photographs were added to production data/assets. The fixture render demonstrates that valid source images genuinely decode; it does not claim the live server supplies them.

## Deliberate deviations

- Generated portrait/clinic branding, fake ratings, commerce, calendar icons implying scheduling and differing navigation tabs are excluded. The Home introduction preserves the heading/spacing hierarchy with brand typography, without importing the generated portrait.
- Actual data determines card size, metadata and gallery count. The backend snapshot supplies only a cover-backed one-item gallery. No fictional 12-image gallery, review-avatar strip, unsupported hours, fabricated category photos or unsupported favorites were added.
- Categories retain existing functional destinations and icon-led tiles (01's pattern). No backend category photo field exists in the supplied contract to reproduce 03's photo tiles honestly.
- Consultation uses the supported single lead form; no extra required email, scheduling or artificial three-step workflow. The exact Arabic success remains `تم إرسال طلبك وستتواصل العيادة معك`.
- Only real backend Google rating/count fields are eligible. No practitioner/product/internal ratings appear. Genuine offer prices remain informational; cosmetic products have no prices or purchases.
- Cards expand for localized text and accessible text scaling; mobile fields stack. Shadows/borders and typography are aligned to references without copying phone frames or fictional assets.

## Functional, security and performance preservation

The redesign retains session/JWT epoch checks, stale-result cancellation, role boundaries, consent, secure token storage, API transport/retry rules, bounded/coalesced reads, 20-record pagination, search debounce, image decode/cache limits and video lifecycle. No Clinic Portal or Super Admin feature file, Django file, signing configuration or release credential was modified. New assertions verify patient-theme scope, genuine gallery decoding/selection, bounded missing media and profile progress/duplicate guards and Google-rating-to-Maps progress/failure recovery. The 78-render matrix also rejects patient tier labels. Existing navigation, offer-to-lead, stale async, media decode, security and performance tests remain active.

## Verification and remaining limits

- Flutter 3.41.5 / Dart 3.11.3. Local native Linux: `dart format`, `flutter analyze` (zero issues), full `flutter test` (**549 passing**), and 78 preview tests pass.
- Historical clinic goldens, including `clinic_profile_v2`, are preserved. The intentional production design uses `patient_design_lock_v1`: exact native rasters plus shared geometry/style snapshots, without tolerance/skip. All four native Windows baseline captures were reviewed. The 156-test native Windows focused run (including exact goldens/real decoding) passed in [run 39593240258](https://github.com/majd-khalifa/AestheticWay/actions/runs/39593240258). Final full-suite/analysis checks are attached to [PR #10](https://github.com/majd-khalifa/AestheticWay/pull/10). Linux target-platform variants are not native Windows verification.
- [Bilingual backend handoff](PATIENT_DESIGN_LOCK_BACKEND_HANDOFF_FOR_ALI.md) distinguishes verified archive contracts from unverified live API/storage/Google deployment and includes a public-only PowerShell diagnostics script.
- Live API reads were blocked by this environment's proxy, not an observed Django denial. No live media persistence, production image decode or Google sync success is claimed. The unavailable live JSON does not block the completed layout work.
