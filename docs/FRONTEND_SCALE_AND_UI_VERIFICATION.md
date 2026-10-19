# AESTHETIC WAY — final scale and UI verification

Date: 19 October 2026. Flutter 3.41.5 / Dart 3.11.3. Cumulative patch base: `9c6d211d618ba33bdca2413d0b3bcf109ab9873a`.

## Implemented in Flutter

- Patient, clinic and admin navigation mount only visited tabs, retain visited state and publish tab activity. The supplied admin shell has **five** tabs, despite the request's four-tab description. Portal overview/all-data calls coalesce concurrent invocations; dashboards no longer preload unrelated catalogs. Referral status and initial secure-storage reads also coalesce.
- `PagedCollection` owns first-page and next-page flights, pagination metadata, ID deduplication, retry position and a 350 ms search/filter timer. Request generations invalidate older results **when input changes**, before the timer fires. Public and portal catalog/lead repositories send `page_size=20`; widgets construct at most 20 models from a page even if an older server returns too much.
- Directory screens use lazy builders, scroll boundaries and explicit Load More/Retry controls. Public clinic profile directories fetch on first tab visit. Profile catalogs preview six rows with lazy View All sheets; admin clinic offers and clinic lead notes have separately scoped paged previews. Native paged selectors replace large clinic/category/author/service/practitioner menus.
- `AuthInterceptor` shares one refresh Future, reuses a newer token for late 401s, clones multipart data for one retry and preserves sessions on validation/transient errors. Session/credential generations reject an old refresh after logout/account change. Secure-storage writes are serialized so a pending token write cannot persist after a later logout.
- Camera/gallery selection requests 1600 × 1600 maximum dimensions and quality 82. Local previews and all network image paths have bounded decode widths. The app image cache uses 120 entries / 64 MiB; **active image streams and the rest of the process are additional memory**, so this is not a 64 MiB process-memory guarantee.
- VIP videos allocate only when their slide is visible/active. They pause/release on slide/tab/route/background transitions; late initialization cannot start playback. The carousel timer also stops outside the viewport or active foreground route. Repeating decorative sheen animation was removed.
- Global cards use restrained shadows and hairline borders; shared buttons use native focus/disabled/loading behavior and flexible labels. Typography has a consistent height/weight rhythm; dark muted foreground tokens meet normal-text contrast on the shared card surface. Both light default and navy dark themes remain.
- Products use neutral studio framing, brand/sponsor typography and editorial headings, with an adaptive one-column layout on narrow screens or enlarged text. Product details use genuine clinic lookup and no fabricated clinic/rating fallback. No prices/cart/contact buttons were added. Clinic rating/source text is readable in RTL and LTR. Login/register footer and role-selector overflows and the patient request-sheet header overflow were repaired.
- Inquiry-only lead copy, UAE phone input, link/points referrals, native uploads and role boundaries from the previous fixes remain covered by the existing regression suite.

## Directory coverage

| Area | Paging / bounded rendering |
|---|---|
| Home | Bounded summary: 8 categories, 10 ads/offers/nearby clinics; View All opens directories; local preview search and city changes debounce |
| Clinics, products, offers, articles, treatments, practitioners | Server pages of 20, request-generation guards, lazy lists/grids and next-page guards |
| Public clinic profile | Staff/treatments/offers load on selected profile tab; branch preview six with directory capability support |
| Patient requests | Pages of 20; status changes debounce and stale results are ignored |
| Clinic leads/practitioners/treatments/offers | Per-directory page state and debounced search/filter queries where exposed |
| Clinic profile products/articles/other catalogs | Six-row previews, paginated View All, paged category/author selectors |
| Clinic lead notes | Fresh detail metadata; paginated GET notes when supported; bounded local paging for older embedded responses |
| Admin clinics/leads/moderation | Independent page state per collection, paged clinic selector, server search parameters and lazy rendering |
| Admin clinic offers / analytics | Separately scoped offer pages; bounded analytics preview with lazy View All for returned summary rows |

Search over an already bounded home preview, a finite country list, or unsaved form values does not require a server request. Country selection remains local. Editing a form or toggling moderation is an explicit write, not a debounced search operation.

## Verification results

- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub --reporter expanded`: **205 passed, zero failures**. The original 184 tests remain, with selector/page-size assertions updated for the intended new behavior; 21 tests were added.
- New tests cover first-visit tab mounting/state preservation/activity; 500 duplicate initial/scroll calls; 350 ms debounce and responses arriving out of order; next-page failure/retry/deduplication; overlarge response caps; disposal and old-session completion; **500 concurrent 401s sharing one refresh**; finalized multipart retry; logout while refreshing; ordered credential persistence; actual portal-load coalescing; video tab/background/vertical-visibility disposal and late initialization; 320 px layouts at 160% text in Arabic/English and light/dark; keyboard-safe auth forms; thousand-row bounded previews; and shared-token contrast.
- Optional product UI previews were rendered in a separate test run at 390 px / normal text with locally loaded Noto test fonts. They use fixture names and the real empty-image placeholder. These are widget renderings, not device screenshots or production catalog photos.
- `git diff --check`: clean. Both exported patch bases are independently checked and applied to scratch copies before packaging; exported changed/deleted files are compared byte-for-byte.
- **622 original backend source files match their original hashes.** No backend implementation or migration was edited.
- All **56 Python blocks** in the handoff parse. An isolated Django 5.2.4 / SQLite in-memory proposal probe validated **12 index definitions against real model fields**, the lead aggregate's result and one-query behavior, and four pagination cases including omitted/oversized size parameters. This is not execution/integration validation of every proposed backend patch.

## Backend deployment dependencies and limits

Read section 9 of `BACKEND_FIXES_FROM_CODEX_AUDIT_FOR_ALI.md` together with the preceding security/media/provisioning fixes. Current Django ignores moderation search and clinic-treatment category filtering; its practitioner filter needs the combined nurse/licensed types parameter. Those server changes must deploy before these filters can be treated as full-dataset search. Public category search already exists; preserve it and its real UUIDs.

Branch/notes paging is capability-gated: deploy the route and `branches_directory_url` / `notes_directory_url` together before bounding embedded legacy arrays. Older responses can still contain large JSON payloads; a Flutter render/model cap cannot prevent an old server from transporting or decoding those bytes. Keep deterministic server ordering. Clinic discovery now retains server ranking; unsupported local-only sort controls were removed.

The appended backend specification covers every requested app plus home/analytics: pagination/nesting, related-object joins, dashboard aggregation, encrypted durable delivery outbox, strict provider/storage timeouts, existing Google sync protections, indexed ordered paging, database connection budgets, Redis stampede/invalidation behavior and scoped/atomic throttle requirements. It also records an owner-scope fix for notification-device deletion.

The unchanged backend suite was **not rerun as a new clean suite**; the prior audit baseline remains 561 passed, 2 failed, 3 errors. Ali must implement, migrate and integration-test the proposals. Redis locking/Lua, PostgreSQL plans/concurrent indexes, Celery recovery, signed R2 URLs and real email/FCM behavior require their actual services.

Neither 500-user deployed capacity nor 60/120 FPS has been certified. The handoff defines staging load and physical-device profile/release acceptance gates. No production APK was built, signed or deployed in this workstream.

## Applying the deliverables

The archive contains the cumulative patch, an incremental patch from the previously delivered fixes, changed source files, deletion manifest, this verification, the backend handoff, machine-readable checks and logs. Choose one application path:

1. Original checkout at the base commit above: `git apply --check AESTHETIC_WAY_FRONTEND_FIXES.patch`, then `git apply AESTHETIC_WAY_FRONTEND_FIXES.patch`.
2. Previous delivered fixes already applied: use `AESTHETIC_WAY_SCALE_UI_INCREMENTAL.patch` with the same check/apply sequence.
3. A divergent branch: review/rebase the patch; do not overwrite unrelated changes with the source-file copy.

Then run `flutter pub get`, `flutter analyze`, and `flutter test` with Flutter 3.41.5. The added direct development dependency on `video_player_platform_interface` supports platform lifecycle tests; the lockfile is included. Coordinate the backend release before production validation.
