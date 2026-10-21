# Patient Portal visual regression recovery

2026-10-20 · PR [#6](https://github.com/majd-khalifa/AestheticWay/pull/6) · branch `codex/patient-portal-luxury-production-overhaul`.

This is the presentation recovery following `31e5a3c8acb1621baee613081d4c8feb789afe35`. The previous visual baseline is `848237d96efc4472537809448e637ce0e15cb3bc`. The original PR's data integrity and role/lead/referral corrections are retained. No Django file was modified; PR #6 is not merged.

## Restored behavior

- **Home premium carousel:** genuine VIP/Featured advertisement placements and publicly listed premium subscription partners can appear. A partner subscription no longer requires an ad row. The app obtains missing clinic metadata from one existing public directory page, preserves real ad identity/tier/media separately, prioritizes VIP, retains server order within a tier and excludes Basic/unknown tiers. `is_featured` never proves payment. A directory failure preserves valid ads and offers a localized retry.
- **Premium presentation:** clinic photography, readable brand identity, gold partner labels, genuine Google information and consultation CTA appear before category shortcuts. Cards use measured content height rather than a nested vertical scroll/fixed height. Swipe, muted 15-second video, viewport/tab/lifecycle playback controls and autoplay pause remain; reduced-motion preferences stop autoplay.
- **Clinic profile:** bounded photography, a prominent contained logo and clinic identity card, source-backed rating/location, clear consultation/contact actions, scrollable understated tabs and a separate information card. Branch pagination starts with an actual directory response. Missing/failed covers collapse rather than becoming a large grey emblem panel.
- **Catalog:** shared clinic, practitioner and offer cards restore photo hierarchy, portrait geometry, readable typography and clear actions. Products use actual supplied brand/sponsor identity; missing product photography becomes a compact brand presentation. Product media uses contain, photographic banners use cover and logos use contain. Article covers also collapse when absent/broken. No substitute photos or medical copy are invented.
- **Media normalization:** recover only the recognized Django first-party `/media/https%3A/...` or `/media/https:/...` wrapper. Valid external CDN/signed URL bytes and the existing first-party HTTPS/path normalization are preserved. Original network/local-file/file-URI/asset/Windows-provider and upload acknowledgement/cache tests remain intact.

The design references supplied in the recovery request were consulted for neutral surfaces, editorial rhythm and consultation hierarchy: [SMPLY](https://dribbble.com/shots/27056997-Luxury-Aesthetic-Clinic-Website-Design-Minimal-Editorial-UI), [Zoe](https://dribbble.com/shots/26907469-Zoe-Aesthetic-Clinic-Website-UI-UX), and [Masterly](https://dribbble.com/shots/25962947-Mobile-Responsive-Website-Design-for-Aesthetic-Clinic-Masterly). No reference artwork was copied.

## Actual Flutter comparison renders

The eight comparisons below contain **previous main on the left and recovered PR #6 on the right**. Both versions were rendered with the same public synthetic fixture and readable test fonts at 390 × 844 logical pixels. Home, Products, Offers and Clinic Directory include their actual navigation shell. Clinic photography reuses an existing application onboarding asset only within the test fixture; it is not claimed to belong to the sample clinic. Missing product/portrait photos are intentionally missing. No private account screenshots or invented production photos are committed.

| Screen | Comparison |
| --- | --- |
| Home English Light | [View](visual-recovery/compare_home_light_en.png) |
| Home English Dark | [View](visual-recovery/compare_home_dark_en.png) |
| Clinic Profile English Light | [View](visual-recovery/compare_clinic_light_en.png) |
| Clinic Profile Arabic Dark | [View](visual-recovery/compare_clinic_dark_ar.png) |
| Products | [View](visual-recovery/compare_products_light_en.png) |
| Offers | [View](visual-recovery/compare_offers_light_en.png) |
| Practitioner Directory | [View](visual-recovery/compare_practitioners_light_en.png) |
| Clinic Directory | [View](visual-recovery/compare_directory_light_en.png) |

Separate original renders are retained in `visual-recovery/previous-main/` and `visual-recovery/recovered/`. Historical renders intentionally retain historical behavior, including source defaults that the current app no longer fabricates. These are Flutter widget renders, not Android APK/device screenshots.

Reproduce the recovered screenshots from the repository root:

```bash
flutter test test/patient_recovery_previews_test.dart --update-goldens \
  --dart-define=RECOVERY_CAPTURE_DIR="$PWD/docs/visual-recovery/recovered"
```

The capture output option is explicit; an ordinary `flutter test` does not overwrite screenshot artifacts. Historical main was rendered in a detached worktree using the same fixture/capture harness, without changing historical production files.

## Windows golden mismatch investigation

The original golden harness inherited host-specific Material defaults. `ThemeData` chooses padded tap targets on Android and shrink-wrapped targets on Windows, plus different default density. Changing `platform` through `copyWith` does not recalculate those already-initialized properties. Windows-platform simulation reproduced differing layout pixels. The harness also allowed asynchronous asset decoding to finish after `pumpAndSettle`, and an unspecified serif/default button font could vary or render test-font blocks.

The harness now explicitly selects Android presentation, standard density, padded tap targets, bundled test fonts and Material icons, and waits for genuine decoded image frames. The four clinic goldens are compared **exactly**, with no tolerance increase, under both Android and Windows `TargetPlatformVariant` values. The intentional recovery layout changes were rendered and visually reviewed before accepting the new golden images. Staff/offer navigation, provider-type checks, actual decoding and error/fallback assertions remain.

This verifies the Flutter platform-dependent defaults on Linux; it does **not** establish that every native Windows rasterizer difference is resolved. A native Windows run and the original Windows diff artifacts remain necessary to rule out additional host-specific differences. No test is skipped or removed.

## Validation

- `dart format .` completed.
- `flutter analyze`: **0 issues**.
- Full `flutter test`: **392 passed, 0 failed**.
- Width coverage: **320, 360, 390 and 430 dp**, Arabic/English, Light/Dark, **160% text**, initial and scrolled patient screens. Exact four clinic snapshots additionally run for simulated Android/Windows hosts.
- New contract/media tests cover subscription-only visibility, independent ad/clinic tiers, priority and deduplication, Basic/unknown exclusion, bounded public-directory enrichment/failure, known malformed URL recovery, signed URL preservation, actual image decoding and collapsing corrupt/missing banners, and product identity without price/photo fabrication.
- All existing Clinic Portal, Super Admin, session/role, lead, referral, pagination, shared refresh-lock, media lifecycle and Windows-path regressions remain in the suite.
- `git diff --check` passes. Prior Clinic Portal, Super Admin and Windows image-fix commits remain ancestors. All **1,258** backend reference file SHA-256 values match the saved snapshot.

## Remaining deployment/device limitations

Read [the bilingual handoff for Ali](PATIENT_VISUAL_RECOVERY_BACKEND_GAPS_FOR_ALI.md) for exact contracts and proposed Python changes. The backend still needs consistent Home serializers/request context, image versus video asset handling, durable storage and signed-URL/cache correctness, independent approval/contract entitlement evidence, and fair delivery beyond the bounded first 20 clinics/10 ads. Flutter cannot verify contract expiry from fields the server does not supply. Low-quality source content needs editorial review; the app preserves source medical copy.

The environment proxy denied the production API tunnel with HTTP 403. No production binary response, authenticated upload/persistence or deployed backend version was verified. No native Android release/device or native Windows run was performed. The automated results and comparison renders support review; device acceptance remains in [the release checklist](PATIENT_PORTAL_LUXURY_QA_CHECKLIST.md).

## Changed implementation paths

| Area | Files |
| --- | --- |
| URL/media and content-height layout | `lib/core/network/api_config.dart`; new `lib/core/widgets/patient_media_banner.dart`, `content_sized_page_view.dart` |
| Home contract and presentation | `lib/features/home/data/home_repository.dart`, `data/models/home_feed_model.dart`, `presentation/screens/home_screen.dart`, `presentation/widgets/featured_ads_carousel.dart`, `home_header.dart`, `active_offers_section.dart` |
| Clinics | `lib/features/clinics/presentation/screens/clinic_profile_screen.dart`, `presentation/widgets/patient_clinic_card.dart` |
| Offers and practitioners | Their directory screens plus new `lib/features/offers/presentation/widgets/patient_offer_card.dart` and `lib/features/practitioners/presentation/widgets/patient_practitioner_card.dart` |
| Products | `lib/features/products/presentation/screens/products_screen.dart`, `product_detail_screen.dart`, `presentation/widgets/brand_product_media.dart` |
| Articles | `lib/features/articles/presentation/screens/articles_screen.dart`, `article_detail_screen.dart` |
| Regression evidence | `test/patient_portal_visual_test.dart`; new `test/patient_visual_recovery_test.dart`, `patient_recovery_previews_test.dart`, `support/settle_preview_images.dart`; four reviewed clinic goldens; the comparison images linked above |

No separate security/scalability workstream was started. This change completes the original visual recovery scope only.
