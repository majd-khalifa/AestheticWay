# PR10 — final reference-fidelity recovery

Branch: `codex/patient-luxury-design-reference-lock`. Existing PR: [#10](https://github.com/majd-khalifa/AestheticWay/pull/10), targeting `main`; no automatic merge. This recovery starts from PR10 commit `514f03a3939ed346e5b43b05533d708831b9bdcb`, preserving the prior PR6–9 history and all existing PR10 work. The uploaded independent review was read as the requested acceptance benchmark. The same eight reference images remain visual authority; they are not application assets or functional specifications.

## What changed visibly

- Home has a compact editorial introduction, a genuine photographic featured carousel, adjacent logo/name identity, early horizontal category discovery and image-led offers/discovery. One placement uses a wide photographic composition; multiple placements retain a peeking carousel. Counts/indicators only appear for multiple placements. Internal VIP/Featured eligibility, priority, video controls, 15-second cap, viewport/app/tab lifecycle and reduced-motion rules remain intact; commercial plan labels never appear to patients.
- Directory cards join the photograph and logo/name panel with a restrained champagne rule, compact real location/description/Google metadata, primary consultation and secondary clinic/contact actions. Missing media stays compact, with real clinic identity visible.
- Clinic profile integrates identity beneath the actual gallery instead of a second boxed header. Only multiple genuine photos get a counter/thumbnails/swipe. About has a styled location panel linked to real Maps data, bounded genuine staff/treatment summaries and a visibility-triggered offer preview sharing the same page/flight as its tab. No invented map bitmap, opening hours or Google review bodies.
- Practitioner cards now reserve roughly39% width for a full-height genuine portrait beside identity, supplied specialty/clinic and consultation. Narrow, enlarged-text layouts can stack the portrait. Missing portraits use a compact identity. The directory consultation CTA shows localized progress, suppresses duplicates, fetches the real clinic and safely opens a lead with the actual practitioner selected.
- A single product feature uses the reference07 side-by-side image/copy showcase; multi-item grids retain 4:5 genuine contained product photography. Missing media is a small identity strip, with the supplied brand shown once in the body and sponsor hierarchy retained. No product prices, purchase/contact actions, carts or ratings.
- Offers use the reference02 split photographic composition where width/text permit, with an enlarged-text stacked alternative. Genuine prices/terms and guarded lead inquiry remain; there is no checkout or scheduling.
- Articles use an editorial cover/ribbon/headline/byline/reading-action hierarchy. Actual publication/author/clinic metadata is conditional. Unknown authors remain unknown; categories, durations, reviews or medical advice are not invented.
- Consultation has a larger selected-clinic photograph and clearer selected-clinic label, display typography and legible consent. It correctly selects gallery photography when the cover is absent. Payload, optional service/practitioner, native phone input, consent, rate-limit handling and exact Arabic confirmation remain unchanged.

## Implemented screen-to-reference mapping

Paths below are relative to `lib/`. Shared typography, patient-only theme scope, fixed five-tab navigation and the existing Profile/loading/error/filter work are preserved from earlier PR10 commits.

| Screen/component | Reference authority | Actual implementation files |
|---|---|---|
| Home / featured / discovery |03 composition,01 density,02 card anatomy,08 materials | `features/home/presentation/screens/home_screen.dart`; `widgets/featured_ads_carousel.dart`, `category_grid.dart`, `nearby_clinics_section.dart`; `core/widgets/content_sized_page_view.dart` (optional padEnds, default preserved) |
| Clinic directory |02 directory card;01/08 identity/material | `features/clinics/presentation/widgets/patient_clinic_card.dart` consumed by existing `screens/clinics_list_screen.dart` |
| Clinic profile / About / location |04 gallery, identity/actions, contextual previews;05 dark header | `features/clinics/presentation/screens/clinic_profile_screen.dart`; `widgets/patient_clinic_gallery.dart` |
| Clinic medical staff / practitioner directory |05 portrait-led39% region and adjacent CTA;02/08 | `features/practitioners/presentation/widgets/patient_practitioner_card.dart`; `screens/practitioners_screen.dart`; clinic profile consumer |
| Clinic treatments tab |04/05 contextual hierarchy;08 | Existing `features/treatments/presentation/widgets/patient_treatment_card.dart` and clinic-profile tab retained; actual detail summaries added to About, full paged tab preserved |
| Clinic offers tab / Offers / Home offers |02 compact split/premium photography;03/08 | `features/offers/presentation/widgets/patient_offer_card.dart`; existing Offers/Home consumers; clinic profile |
| Products |07 showcase hero/featured/compact;08 | `features/products/presentation/screens/products_screen.dart`; `widgets/brand_product_media.dart` |
| Articles |07 editorial cover/byline/action;08 | `features/articles/presentation/screens/articles_screen.dart` |
| Consultation |06 selected clinic, grouping/consent/CTA;08 | `features/appointment_lead/presentation/screens/appointment_request_screen.dart` |
| Profile / search / filters / empty / busy / navigation |01/06/08 | Earlier scoped production implementations preserved: `features/profile/presentation/screens/profile_screen.dart`, `features/navigation/main_nav_screen.dart`, patient theme and guarded controls. New compact missing-media copy in `core/widgets/patient_media_banner.dart` |

## Actual rendered comparisons and review

[Open the updated visual evidence index](patient-fidelity-ca15dc6/README.md). It contains102 old and102 revised actual Flutter PNGs, eight six-state before/revised/reference boards and two theme/media/RTL matrices. Before production code is514f03a, with the same final fixture harness/photos used for revised captures. Old original-main evidence remains untouched under `patient-design-lock/`. Each of eight principal screens has populated/missing × light/dark English and representative dark Arabic; extra captures include Profile, real clinic tabs, busy and scrolled content.

The comparisons were inspected for media proportion, identity/CTA placement, missing-state height and RTL. Product/staff checkerboard artwork was replaced with attributed test photographs; source/provenance is in `test/fixtures/media/README.md`. Clinic gallery fixtures now contain two distinct existing clinic/activity photographs; source-shaped detail summaries drive real on-page previews. Earlier preview-only article category/treatment image fields absent from the backend were removed. Test records remain explicitly synthetic. None is in production data or the app media manifest.

Necessary deviations: no generated hero portrait or fictional branding, no unsupported photo category feed (01's icon treatment is used), no product commerce/prices/ratings, no booking wizard/calendar/email requirement, no fictional12-photo count, reviews, hours or static map. Typography/content expand and scrolling remains available at narrow widths and160% text. Genuine media determines composition; missing states intentionally do not mimic photo-filled reference rectangles. A human design review is still required before merger; this report does not grant merge approval.

## Backend compatibility and evidence boundary

[Read the bilingual ca15dc6 handoff](PATIENT_CA15DC6_CONTRACT_REVIEW_FOR_ALI.md). Comparison happened before Flutter integration edits. New source resolves real gallery serialization and video-poster ambiguity; do not ask Ali to implement those again. Standard pagination maximum is now20, upload checks require active clinics for clinic users, and validation adds25MP/fail-closed duration limits. Both old/new snapshots are unchanged by hash.

Confirmed Flutter correction: consultation selected-media mapping now uses genuine gallery fallback instead of cover-only. Unknown article authors are no longer fabricated. Existing logo/catalog/video/Google model mappings already match this source and are preserved with response-shaped regressions. No speculative API rewrite or Django edit.

Remaining production dependencies are deployment version, real linked uploaded objects/public HTTPS storage delivery, actual clinic content, real Google Place IDs/aggregate sync/configuration and physical-device video/media decode. Google review-body/opening-hour contracts remain unavailable; review routes are empty/acknowledgement stubs, not persistence. No live response was supplied or successfully verified here. Archive inspection and fixture rendering do not establish production delivery. The anonymous allowlist-only PowerShell capture remains available and its offline privacy regression passes.

## Protected behavior and scope

No Django, Clinic Portal feature, Super Admin feature, authentication/JWT transport, signing, package dependency or release configuration was changed. Patient design changes remain in Patient components. The shared PageView gains an optional parameter whose default is unchanged. All historical golden files remain byte-for-byte intact. Native image resolution, bounded decoding/cache, pagination/coalescing/debounce, shared401 lock, role/auth-only navigation, referral links, consent and lead-only submission remain covered by the full suite. The five tabs remain Home, Clinics, Products, Offers, Profile; Arabic confirmation remains exactly `تم إرسال طلبك وستتواصل العيادة معك`.

## Verification

Final results and native CI evidence are recorded below after execution. Exact native rasters plus common geometry remain mandatory in the new `patient_reference_fidelity_v2` family; no assertion tolerance, skipped tests or automatic baseline approval. A native Windows CI candidate is reviewed separately before adoption. Linux target-platform variants alone are not Windows verification.

See [complete change manifest](patient-fidelity-ca15dc6/file_change_manifest.json) for cumulative PR10 and this recovery's paths/hashes. Manifest hashing excludes itself to avoid a circular digest.

- Local native Linux / Flutter3.41.5 / Dart3.11.3: **573/573 tests passed**, analyzer **zero issues**, `dart format .` completed, `git diff --check` clean. The24 new tests cover response mappings, gallery-only consultation decoding, honest single-photo controls, real portrait decoding at four widths/both themes/languages/160% text, guarded practitioner lead routing and the lazy/shared offer preview.
- Focused render/responsive run:106 passing (78 preview cases plus28 existing responsive/golden/flow cases);102 PNGs per before/revised capture. Native glyph raster ownership remains separate from Android/Windows TargetPlatform variants.
- Offline public PowerShell redaction regression passes in local PowerShell7.5.4. No live API request, credential, patient record or raw signed media URL is required by that test.
- Native Windows CI review/verification is pending the candidate artifact from this recovery commit; its result is not inferred from Linux. Final native CI evidence will be appended after capture review.
