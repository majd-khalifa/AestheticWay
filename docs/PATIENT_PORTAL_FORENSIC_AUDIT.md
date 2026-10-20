# Patient Portal forensic audit and implemented correction

2026-10-20 · Repository `majd-khalifa/AestheticWay` · branch `codex/patient-portal-luxury-production-overhaul`.

## Scope, evidence and safety

The baseline is fetched `origin/main` **848237d96efc4472537809448e637ce0e15cb3bc**, with **323 passing tests and zero analyzer issues**. Clinic Portal commit `c6fe01dfc16c0409c0766769cf51505b579cd85f`, Super Admin commit `47127b71e22d67b99d2ca81e8838e15ad583605e` and Windows image fix `e15030ddc69d4f96776b45edfc6a9535e47607dd` are ancestors. Work is on a dedicated branch; main is not modified, force-pushed or merged.

All 19 supplied Android screenshots were visually inspected outside Git. They demonstrate layout/content presentation, not API responses. They contain private test-account information and are not included here. The latest supplied backend reference was inspected read-only, especially public serializers/querysets, Home, leads, referrals, media and Places services. No authenticated production API call/upload, production database access or Django mutation was performed. Reference source is not proof of the deployed version.

Project rules and relevant architecture/API/product/image/Google documentation were reviewed. Older documents describe guest browsing, regulatory fields, date selectors and discount codes; the current user requirements and strict project skill supersede those stale descriptions. Current Patient behavior is documented here and in the Ali handoff.

## Confirmed root causes and implemented behavior

| Priority | Before, verified in source | Implemented correction |
| --- | --- | --- |
| P0 | `ClinicModel.fromJson` relabeled legacy `rating/review_count` as Google, defaulted verification/hours/city, mapped `is_featured` to VIP. | Only validated Google fields produce a badge; valid tier is parsed independently; missing verification/hours/city remain absent. Missing setup status is unknown. |
| P0 | Home synthesized a 4.8 clinic after failure and populated sponsored space with ordinary clinics. | No synthetic clinic; actual `featured_ads` drive sponsored placements. Ad tier remains separate from clinic subscription tier. Basic filler removed. |
| P0 | Practitioner/article failures created 4.9 clinics, Dubai coordinates, sample phone and invented hours; article code invented a doctor, specialty, experience, reviews and languages. | Fetch genuine clinic/practitioner; preserve original trustworthy content; missing/failed relationships disable or reject inquiry and offer retry. Author must match clinic. |
| P0 | Treatment detail searched only the first clinic page and substituted its first unrelated clinic. | Retrieve the treatment's actual clinic directly. No arbitrary destination; unavailable association stays unavailable. Real treatment ID is retained for inquiries. |
| P0 | Referral service could manufacture personal links, issue codes, debit points and verify/redeem; visible copy promised vouchers. | Link + server-ledger points + confirmed milestones only. Authentic returned link required. All legacy mutation entry points are disabled and do not call endpoints. Legacy response DTOs remain internal compatibility only. |
| P0 | `LeadsRepository` manufactured success in `FLUTTER_TEST`, including failed connections; UI could show success for an unconfirmed result and invent a reference. | Removed environment bypasses; actual UUID destination and confirmed response/reference/timestamp required. Tests inject explicit fixtures. No random reference or offline success. |
| P1 | Home discarded actual ad association/media; Home search pretended a bounded feed was a complete search. | Parse actual nested ad clinic, image/video and placement tier. Search submits to the server-backed clinic directory, preserving city. |
| P1 | Large dark emblem fallback banners hid missing content and dominated layouts. | Quiet theme-aware fallback, real image first, real clinic logo second, official emblem/custom neutral fallback last; bounded decoding/caching retained. No invented photography. |
| P1 | Duplicate directory/home cards, misleading verified count, duplicate location, map buttons without actual destination and invented distance. | Shared `PatientClinicCard`; content-sized identity/actions; actual optional cover; known location only; real Google badge with verified map behavior; valid contact actions only. |
| P1 | Clinic profile nested viewport-sized tabs reserved enormous empty areas and hid detail errors. | One natural-height scroll document, lazy paged tab data, compact empty/error/retry states, actual contact/maps/hours only. Staff and offer inquiry preserve real entity context. |
| P1 | Product brand fallback used clinic identity; fixed-height product cards left large blank space. A previously disconnected inquiry component displayed product price. | Real brand/sponsor only; responsive content-sized rows, contained media, secondary advertising-clinic attribution, supported general inquiry. Removed product price from inquiry; no shopping/direct contact controls. |
| P1 | Lead phone prefill stripped international codes; paged branch/practitioner selections outside summaries could be lost; consent defaulted on in product inquiry. | Preserve full E.164 into shared input; retain selected objects; meaningful branch selection; explicit consent, duplicate-submit/session guards, inline modal errors and frozen success copy. |
| P1 | Filter/query failure could retain records belonging to the old query. | Clear old-filter records immediately, invalidate in-flight responses, preserve 350ms debounce/page size and shared refresh lock. Same-query refresh can retain known content with retry affordances. |
| P2 | Fixed horizontal rating/type badges, summary header and profile status overflowed at larger text; static category grid clipped labels. | Wrapping badges/headers, flexible status/theme controls, adaptive discovery shortcuts, compact integrated retry and reserved bottom navigation space. |

### Code anchors

- `lib/features/clinics/models/clinic_model.dart` — `fromJson`, `hasGoogleRating`, `mapsUri`, independent subscription mapping.
- `lib/features/clinics/presentation/widgets/google_clinic_rating.dart` — genuine Google badge; optional accessible Maps interaction.
- `lib/features/clinics/presentation/widgets/patient_clinic_card.dart` — shared card and actual contact/inquiry eligibility.
- `lib/features/home/data/models/home_feed_model.dart` — ad entity/placement/media contract, separate clinic model.
- `lib/features/home/presentation/screens/home_screen.dart` — true sponsored feed, server directory search and safe offer inquiry.
- `lib/features/clinics/presentation/screens/clinic_profile_screen.dart` — natural tab layout, lazy page collections, error recovery, genuine destination.
- `lib/features/practitioners/presentation/screens/practitioner_profile_screen.dart`, `lib/features/articles/presentation/screens/article_detail_screen.dart`, `lib/features/treatments/presentation/screens/treatment_detail_screen.dart` — removal of fabricated entities.
- `lib/features/appointment_lead/data/leads_repository.dart` — actual destination/response validation, no test-environment production bypass.
- `lib/features/appointment_lead/presentation/screens/appointment_request_screen.dart` — international phone, actual offer/treatment/branch/practitioner context, consent/submission/session guards.
- `lib/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart` — clinic-null supported inquiry, no prices, explicit consent and inline failures.
- `lib/features/referral/services/referral_service.dart`, `models/referral_model.dart`, `data/referral_repository.dart`, `presentation/screens/referral_screen.dart` — authenticated personal link/status presentation, no code mutations.
- `lib/core/data/paged_collection.dart` — immediate query invalidation and stale-filter clearing; existing single-flight and pagination retained.
- `lib/core/widgets/luxury_image.dart` — actual provider/fallback hierarchy retained, presentation simplified.

## Google data semantics

`google_rating` must be finite and within 1–5. A supplied review count must be a positive integer for a numerical badge; an explicit zero/negative count with a rating is inconsistent and is not presented. Missing review count is not invented: a valid rating may display alone. Generic `rating/review_count` cannot become Google data. No `0.0 ★` or automatic “New on Google Maps”.

| Supplied evidence | Patient behavior |
| --- | --- |
| Valid Google rating + valid Google destination | Genuine Google badge, tappable with accessible Maps semantics. |
| Valid Google rating, no destination | Genuine source badge without a false map interaction. |
| Actual destination, no rating | Maps action only; no numeric stars or new-listing claim. |
| Neither | No rating/map claim. Known clinic content remains usable. |

Maps destinations use recognized Google links, a provided Place ID or finite coordinate pair; `(0,0)` is unavailable, and valid zero latitude/longitude individually are supported. No default city coordinates. Clinic verification, setup/moderation status, featured flag and subscription tier do not substitute for one another. A real paid ad's placement metadata does not rewrite its clinic's subscription.

## Media pipeline findings

1. Django owns persistence and storage delivery. Profile logo/cover are ImageFields; media assets expose `file.url`; public catalog fields expose computed URL properties. The reference already contains URL-resolution helpers and catalog asset support. Missing/invalid production media cannot be diagnosed from a fallback screenshot alone.
2. Existing Flutter fixes already choose a nonblank supported media alias, normalize relative Django paths using the configured origin, preserve external signed URLs, and select NetworkImage/FileImage/AssetImage. The merged Windows drive/UNC fix is preserved. This task also accepts the backend lead-summary `profile_image_url` avatar alias.
3. `LuxuryImage` still shows a pending primary image without prematurely selecting fallback. Actual decoding/load failure may use a real logo, then a custom/official fallback. Logos/products contain; clinic/article covers crop. No cache-busting query is appended to signed URLs.
4. Local media pointers are bounded/session-scoped and invalidate on replacement/new URL/missing local file/session clear. They improve immediate display; they do not prove durable backend persistence. Existing upload/cache/portal regression tests remain in the suite.
5. New deterministic HTTP tests exercise actual PNG decoding, expired signature/403, 500, empty/corrupt/HTML bytes and wrong content type. Invalid bytes fall back; valid PNG bytes decode even under an incorrect MIME header. Existing tests retain canonical/alias precedence, CDN/signed query preservation, pending/error/replacement, local files/file URIs/assets/Windows provider types and real native-file decoding on Linux.
6. Confirmed backend issues are documented for Ali: reduced/raw Home serialization; missing Home offer image; broad string `/media/` stripping that can destroy an external URL. Production CDN access, signature lifetimes and authenticated persistence remain deployment checks. Treatment photo/duration fields are absent from the reference public contract; the UI cannot create them.

Upload repositories, multipart retry cloning, the shared 401 refresh flight and image decode/cache budgets were preserved. Upload diagnostics now print only development-only status/error type, never full signed URLs or request errors containing private paths/tokens.

## Screen-by-screen implementation coverage

| Visual state / connected screen | Source finding and delivered behavior |
| --- | --- |
| 01 Featured Home | Oversized fallback/ad substitution corrected. Authentic ad records and compact editorial identity, restrained media, swipe and accessible selection; no paid filler. |
| 02 Directory | Sparse fixed-feeling cards replaced by shared content-sized card, honest count and known location/Google metadata. |
| 03 Products | Balanced one/two/many presentation; genuine brand/sponsor; no clinic-as-brand or price. |
| 04 Offers | Smaller intentional missing-media state, wrapped price/inquiry actions and actual offer context. Genuine offer prices remain allowed. |
| 05 Profile | Actual verification basis, points/link referral copy, flexible status and theme controls, calmer shared surfaces/retry. |
| 06 Referrals | Rebuilt as authentic invitation link, copy/share, actual points/invitations and verified milestones; no code workflow. |
| 07 Treatments empty | Compact published-empty state, useful refresh and real category resolution; no fabricated catalog items. |
| 08 Practitioner list | Professional directory hierarchy retained/refined; real type/specialty/clinic/photo, neutral unknown type, no invented qualification/rating. |
| 09 Branch consultation | Duplicate picker wrappers removed; paged actual branch selection retained beyond initial summary. |
| 10 Practitioner detail | Fake clinic/contact/hours removed; real relationship required, visible retry, inquiry icon. |
| 11 No-branch consultation | No forced single/empty branch choice; shared full-prefix phone, meaningful optional fields, explicit consent. |
| 12 Articles | Compact cover/fallback, real source text/author/date only. Missing date not replaced with “today”. |
| 13 Article detail | Readable longer body, derived reading estimate, verified author navigation/inquiry; no fake doctor/clinic. |
| 14 Home → directory | Category shortcuts to existing bottom tabs; full server search/filter directory for search and actual medical-category requests. |
| 15 Home discovery | Truthful discovery label; shared cards; invented distance/map-to-first-clinic removed. |
| 16 Filter sheet | Content-aware constrained sheet and keyboard handling; city + actual searchable categories only. Selected localized category names retained. Unsupported sort/practitioner filter state removed. |
| 17 Clinic About/Map | Natural document, actual optional imagery/description/location/hours, separate rating/map availability and retry. |
| 18 Clinic staff | Lazy published data with compact empty and explicit error states; more pages and genuine staff inquiries. |
| 19 Clinic offers | Natural content, actual offer UUID/title preserved, visible error/empty distinction and paging. |
| Product Detail/inquiry | Actual brand identity, secondary advertising clinic only, existing supported brand-product lead with optional clinic; no price/cart/purchase/direct contact. |
| Treatment Detail | Direct actual clinic association; no first-page/first-clinic substitution; safe unavailable/retry. |
| Success/My Requests | Confirmed-only success, frozen Arabic statement, real reference/time, personal status/paging/details. Historical timestamps do not enable scheduling. |
| Contact sheet | Actual phone/WhatsApp/Maps only; missing channels omitted, no invented distance, scrollable on small screens. |
| Login/registration/OTP/reset | Required authentication/native phone rules retained; missing/unknown roles fail closed to sign-in, and clinic/admin roles do not enter the patient inquiry guard. No guest/manual referral-code input. |
| Bottom navigation/back | Exactly Home/Clinics/Products/Offers/Profile; lazy stack preserved, content space reserved, existing back behavior retained, shortcuts avoid stacking ordinary destination tabs. |

The original screenshots include placeholder/test-like CMS titles and sparse data. These are content-quality evidence, not authorization to invent medical text, identities or biographies. No real screenshot/account details were copied into fixtures or reports.

## Referral and inquiry contracts

The current status endpoint already supplies invitation links, qualified counts, ledger points and milestone flags. Genuine backend thresholds are 20/+100, 35/+175, 50/+250, with a separate 10-point qualifying referral award. Flutter displays `current_points` and does not infer a production balance from invitation count. A missing status/link disables copy/share and displays unavailable/retry. Count-reached and server-awarded states are not conflated.

Consultations POST `/api/v1/leads/` with real `clinic`, `patient_name`, full E.164 `patient_phone`, `consent_accepted`, optional `service_name`, `notes` and valid `branch/practitioner/treatment/offer` IDs. Offer lead carries `lead_type=offer` and its real title. No date/slot/time selector or payment. Independent product inquiry uses actual `product`, `lead_type=product_inquiry`, contact/consent/notes and no invented clinic. Django reference already supports that shape. Clinic ownership and treatment/practitioner assignment validation remain server responsibilities.

Success appears only for a confirmed response with genuine reference and timestamp. Exact Arabic statement: **تم إرسال طلبك وستتواصل العيادة معك**. Rapid duplicate taps are blocked, 429/failures remain failures, and a response from an obsolete account session cannot produce a new account's success screen.

## Backend dependencies and limits

See the bilingual [Ali handoff](PATIENT_PORTAL_BACKEND_GAPS_FOR_ALI.md) for evidence, existing class/endpoint names, proposed Python, authorization, compatibility/migration considerations, tests and deployment order.

Confirmed reference gaps: incomplete Home Google/media/tier fields and banner serialization; destructive string-media normalization; active legacy referral mutations; AllowAny lead creation and non-patient personal-history access; ordering without unique tie-breakers; incomplete geo validation; unavailable treatment media/clinical metadata; clinic hours/verification without current public backing; placeholder review endpoints. Brand/sponsor public fields and Places caching **already exist** in the reference and are not reported as invented missing APIs. Data completeness, workers/credentials and deployed versions need Ali's verification.

No native Android release/device or native Windows test run was possible here. Linux tests validate Flutter contracts/layout/actual image decoding; they do not certify Android codecs, OS app handlers, secure-storage plugins, camera/gallery or Windows file behavior. Real upload persistence and live Places/CDN operations still require the device/staging checklist.

## Automated verification

- Baseline: `flutter analyze` **0 issues**; `flutter test` **323 passed**.
- Final quality gates: `dart format .` completed; `flutter analyze` **0 issues** (3.1 seconds); full `flutter test` **372 passed, 0 failed** (72 seconds); `git diff --check` passed. All **1,258 backend reference files** match their original SHA-256 hashes. Final pre-push fetch still resolves `origin/main` to `848237d96efc4472537809448e637ce0e15cb3bc`.
- New integrity coverage: genuine Google fields/range/counts, tier independence, missing metadata, known practitioner types, four rating/map cases, actual ad contract, brand identity, authentic links/ledger/milestones, invalid destinations, false/offline responses, clinic-null product inquiry, real offer/international phone/consent/double-submit, strict missing/cross-role identity, real alternate-language source fallback without CMS rewrites and stale-filter failures.
- New visual coverage: 320/360/390/430 dp × EN/AR × Light/Dark at 160% text, initially and scrolled, across Home/directory/products/offers/practitioners/detail/treatments/articles/detail/clinic/form/referrals/profile. Additional error/retry and product-consent journeys. Four fixture-driven readable goldens under `test/goldens/`; font is bundled only for tests with its redistribution license.
- Existing Clinic Portal, Super Admin, refresh-lock/pagination/media and Windows-path regression tests are retained. Outdated assertions that required vouchers, fabricated Google values or test-only production success were replaced with stronger current business checks and explicit fixtures; no tests were skipped to obtain a pass.
- `dart format .` also formats previously unformatted Dart in shared/auth/portal/test files; those mechanical changes do not enable unsupported backend features.

Use [the release checklist](PATIENT_PORTAL_LUXURY_QA_CHECKLIST.md) for Android acceptance. Synthetic goldens are reviewable layout evidence, not photographs of a tested production APK.

## Complete changed-file manifest

101 files, including the three reports, shared/domain/screen implementation, regression updates, four synthetic PNG previews and a licensed test-only font. Formatting-only changes are included in this complete manifest. No private reference screenshot or Django file is included.

- `docs/PATIENT_PORTAL_BACKEND_GAPS_FOR_ALI.md`
- `docs/PATIENT_PORTAL_FORENSIC_AUDIT.md`
- `docs/PATIENT_PORTAL_LUXURY_QA_CHECKLIST.md`
- `lib/core/auth/guest_auth_guard.dart`
- `lib/core/data/paged_collection.dart`
- `lib/core/localization/app_locale.dart`
- `lib/core/network/api_exception.dart`
- `lib/core/services/device_token_service.dart`
- `lib/core/services/media_upload_service.dart`
- `lib/core/services/support_service.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/utils/contact_launcher.dart`
- `lib/core/utils/entity_id.dart`
- `lib/core/utils/maps_launcher.dart`
- `lib/core/utils/source_text.dart`
- `lib/core/widgets/app_snackbar.dart`
- `lib/core/widgets/luxury_animations.dart`
- `lib/core/widgets/luxury_empty_state.dart`
- `lib/core/widgets/luxury_error_view.dart`
- `lib/core/widgets/luxury_image.dart`
- `lib/core/widgets/luxury_loading_skeleton.dart`
- `lib/core/widgets/luxury_section_header.dart`
- `lib/core/widgets/luxury_shimmer.dart`
- `lib/core/widgets/practitioner_badge.dart`
- `lib/core/widgets/rating_chip.dart`
- `lib/data/mock_data.dart`
- `lib/features/appointment_lead/data/leads_repository.dart`
- `lib/features/appointment_lead/presentation/screens/appointment_request_screen.dart`
- `lib/features/appointment_lead/presentation/screens/appointment_success_screen.dart`
- `lib/features/articles/models/article_model.dart`
- `lib/features/articles/presentation/screens/article_detail_screen.dart`
- `lib/features/articles/presentation/screens/articles_screen.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/data/models/auth_models.dart`
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/otp_screen.dart`
- `lib/features/auth/presentation/screens/reset_password_screen.dart`
- `lib/features/clinic_portal/data/models/clinic_badge_counts_model.dart`
- `lib/features/clinic_portal/data/models/clinic_dashboard_model.dart`
- `lib/features/clinics/models/clinic_model.dart`
- `lib/features/clinics/presentation/screens/clinic_profile_screen.dart`
- `lib/features/clinics/presentation/screens/clinics_list_screen.dart`
- `lib/features/clinics/presentation/widgets/contact_options_sheet.dart`
- `lib/features/clinics/presentation/widgets/filter_bottom_sheet.dart`
- `lib/features/clinics/presentation/widgets/google_clinic_rating.dart`
- `lib/features/clinics/presentation/widgets/patient_clinic_card.dart`
- `lib/features/home/data/home_repository.dart`
- `lib/features/home/data/models/home_feed_model.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/widgets/active_offers_section.dart`
- `lib/features/home/presentation/widgets/category_grid.dart`
- `lib/features/home/presentation/widgets/featured_ads_carousel.dart`
- `lib/features/home/presentation/widgets/home_header.dart`
- `lib/features/home/presentation/widgets/nearby_clinics_section.dart`
- `lib/features/navigation/main_nav_screen.dart`
- `lib/features/offers/models/offer_model.dart`
- `lib/features/offers/presentation/screens/offers_screen.dart`
- `lib/features/practitioners/models/practitioner_model.dart`
- `lib/features/practitioners/presentation/screens/practitioner_profile_screen.dart`
- `lib/features/practitioners/presentation/screens/practitioners_screen.dart`
- `lib/features/products/models/product_model.dart`
- `lib/features/products/presentation/screens/product_detail_screen.dart`
- `lib/features/products/presentation/screens/products_screen.dart`
- `lib/features/products/presentation/widgets/brand_product_media.dart`
- `lib/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/features/referral/data/referral_repository.dart`
- `lib/features/referral/models/referral_model.dart`
- `lib/features/referral/presentation/screens/referral_screen.dart`
- `lib/features/referral/services/referral_service.dart`
- `lib/features/splash/presentation/screens/splash_screen.dart`
- `lib/features/treatments/models/category_model.dart`
- `lib/features/treatments/models/treatment_model.dart`
- `lib/features/treatments/presentation/screens/treatment_detail_screen.dart`
- `lib/features/treatments/presentation/screens/treatments_screen.dart`
- `test/backend_enhancements_compatibility_test.dart`
- `test/categories_and_modules_test.dart`
- `test/clinic_catalog_test.dart`
- `test/discovery_repositories_test.dart`
- `test/fixtures/fonts/DejaVuSans.ttf`
- `test/fixtures/fonts/LICENSE-DejaVu.txt`
- `test/goldens/patient_clinic_dark_ar.png`
- `test/goldens/patient_clinic_dark_en.png`
- `test/goldens/patient_clinic_light_ar.png`
- `test/goldens/patient_clinic_light_en.png`
- `test/image_display_regression_test.dart`
- `test/leads_integration_test.dart`
- `test/ltr_field_test.dart`
- `test/luxury_image_and_actions_test.dart`
- `test/offer_lead_and_dropdown_safety_test.dart`
- `test/patient_portal_integrity_test.dart`
- `test/patient_portal_visual_test.dart`
- `test/patient_profile_live_test.dart`
- `test/production_readiness_live_test.dart`
- `test/production_refinements_test.dart`
- `test/products_articles_live_test.dart`
- `test/referral_and_client_feedback_test.dart`
- `test/snackbar_contrast_test.dart`
- `test/support/patient_fixtures.dart`
- `test/widget_test.dart`
