# Flutter performance, latency and readiness review

Date: 2026-10-20. Baseline: `811b1bbcaf62906f19c851145777a72412266a82`, including the verified visual recovery and security work. Performance branch: `codex/performance-latency-readiness`. Django remained read-only. No production API or media request, stress test or infrastructure change was performed.

## Measurement conditions and limits

The execution environment is headless Linux x86_64 with three reported logical CPUs. `flutter devices --machine` reported only Linux, with hardware rendering unavailable. There is no connected Android device, adb, k6 installation, staging URL, authorized load environment or infrastructure credentials. Flutter unit/widget fixtures run in the test engine, not Android Profile Mode. Their durations are not release/device latency or throughput evidence. The cloud runtime reports no configured external infrastructure capability/identity; deployment topology cannot be inferred from source defaults.

Measurement preceded production changes. `test/performance_probe_test.dart` ran at baseline with mock HTTP adapters and synthetic data; the unchanged card implementation was additionally probed before the image change. The same probes were repeated afterward. Raw summarized observations are retained in [performance/local_probe_measurements.json](performance/local_probe_measurements.json). The real API, databases and CDN were not timed.

| Deterministic local probe | Before | After | What this establishes |
|---|---:|---:|---|
| Twenty overlapping identical Products GET callers | 20 adapter requests | 1 | In-flight deduplication, not twenty real concurrent users. |
| Ten immediate failed next-page attempts | 10 loader failures | 1 | Backoff prevents repeated immediate failures; 20 valid prior records stay visible. |
| Home dependency with feed delay 100 ms, directory delay 150 ms | 250 virtual ms | 150 virtual ms | Independent reads overlap; two requests remain. This is simulated critical-path time, not API latency. |
| First Products screen, synthetic server advertising 520 records | 1 page request, page_size 20 | Same | No eager full-catalog request introduced. Separate test traverses 26 server pages to obtain all 520 unique fixture IDs. |
| First Products response UTF-8 JSON body | 3,772 fixture bytes | Same | Exact uncompressed fixture body bytes; excludes headers, TLS, compression, images and production content. |
| Initially mounted product media cards | 4 | 4 | Lazy sliver rendering in the default 800×600 logical widget viewport. Does not measure scroll FPS. |
| Product media at width 160 logical px, DPR 3, viewport width 390 | decode-width budget 1,080 px | 480 px, height budget 540 px | Card constraints replace screen-width sizing. Original aspect ratio is preserved using ResizeImagePolicy.fit. Budgets are not measured process RSS. |

The baseline probes passed before fixes; post-change assertions are strengthened by the regression suite. A separate generated real 32×4096 PNG is decoded through the production provider and verified to have height <=2160, positive width and preserved aspect ratio. Existing file URI/Windows path/asset/network image tests still perform genuine decoding and fallback assertions. Their prewarm now uses the same bounded production decoder/cache key so asynchronous file IO does not begin inside the widget fake clock. No test was skipped and no timeout was increased.

## Requested device/production baseline

| Metric | Status | Reproducible next measurement |
|---|---|---|
| Cold process startup / warm resume / first content | Not measured on device | Profile build, synthetic patient, cold launch and warm resume separately; timestamp process→first frame and request→first meaningful content. Keep onboarding/auth/keystore/refresh conditions explicit. |
| Home, product directory, clinic search API latency | Not measured remotely | Authorized staging runs with deployment/hardware record; request p50/p95/p99, status and server trace split. Local virtual times above are separate. |
| Tab switch and scrolling frame latency/jank | Not measured on hardware | DevTools Performance + FrameTiming, fixed viewport/DPR/refresh rate, Arabic/English and both themes, warm and cold images. |
| Image decode CPU / texture cost | Not profiled on hardware | DevTools CPU/timeline with representative JPEG/PNG/WebP, thumbnails and wide/tall images. Decode dimension regression is measured separately above. |
| App RSS/heap/native video/GPU memory | Not measured on device | DevTools memory and Android process memory before/after scroll, all visited tabs, video playback, background and session change. |
| Network bytes / failure and retry frequency | Fixture body/counts measured only | DevTools network plus proxy/CDN/server telemetry with synthetic fixtures. Include compressed wire bytes and media egress. |

Use `flutter run --profile -d <authorized-android-device> --dart-define=API_BASE_URL=https://<approved-staging-host>/api/v1/`. Confirm the configured target before login. Authenticate with synthetic accounts manually or an approved secret-backed harness. Record device model/OS, Flutter version, app/backend SHA, display refresh, network shaping/RTT, fixture count, media sizes and cache state. DevTools should collect CPU, memory, timeline and network traces for at least repeated cold/warm trials; report distributions and raw redacted traces. Debug Mode or widget execution time must never be substituted for these measurements.

## Implemented changes

1. **API coalescing and backpressure:** `lib/core/network/api_client.dart` shares only overlapping equivalent default-option GETs. Key includes base URL, token/auth session epochs, locale, path, canonical query and default headers. Custom Options opt out. Completion removes the flight; there is no completed-response/global patient cache. Writes never coalesce or automatically retry, and invalidate in-flight reuse both at invocation and completion. Existing Dio connection reuse/timeouts stay intact.
2. **Retry-After:** `request_backpressure.dart` and `retry_after.dart` implement a base/session-scoped deadline for 429/503, supporting delta seconds and HTTP dates. Without a header, those statuses use 1/2/4/8/16/30-second capped backoff. An already in-flight success does not erase a server deadline; old-session failures cannot throttle a new session. Malformed headers are ignored safely. Delta values have a defensive one-year representation ceiling. No automatic retry timer or queue is created. Writes during an active cooldown fail early rather than being replayed later. Refresh 429/503 metadata now reaches callers without logging out the account.
3. **Paged loading:** `lib/core/data/paged_collection.dart` retains its 20-row server pages, generation guard, 350 ms debounce and deduplication. Failed reads back off exponentially up to 30 seconds, or longer when Retry-After requires it. Query changes invalidate old data immediately; same-query refresh failure preserves valid pages and terminal hasMore. Cancellation is silent lifecycle control. Backoff resets after success, mutation, query change or session clear; no retry/listener timer survives disposal.
4. **Refresh presentation:** Products, Clinics, Practitioners, Treatments, Articles and My Requests retain existing validated cards during a same-query refresh. Different searches/filters still clear obsolete results. Home retains the same-city feed during refresh, but clears it immediately for a different city. Partial loading/errors never fabricate medical facts or success.
5. **Home waterfall:** `HomeRepository` starts feed and one bounded directory page together, handles optional directory failure immediately and preserves valid returned ad records. It still uses existing subscription enrichment to keep the recovered VIP/Featured carousel truthful. Removing the second request depends on Ali adding equivalent metadata/partner summaries to Home; no unsupported API was invented.
6. **Media decoding and stable identity:** `luxury_image.dart` bounds decode height as well as width with aspect-preserving fit; ordinary covers retain their existing width budget. Avatars/fallback logos also have finite decode bounds. Product media uses actual card width and display height, retaining contain/uncropped presentation and hero quality. PatientMediaBanner uses the shared height ceiling. Product rows/cards have stable ID keys. URL signatures and native media input flows are unchanged.
7. **Deterministic time:** `clock` is promoted from its already-resolved transitive dependency to a direct dependency, with **no version upgrade**. Retry clocks now advance under Flutter's fake clock. Existing retry tests assert immediate attempts are blocked, advance the known one-second policy, then validate genuine recovery; this is not a timeout-only fix.

## Audited behavior retained

| Area | Finding / decision |
|---|---|
| Repositories across Patient/Clinic/Admin | Standard requests already send page_size=20 regardless of an oversized pageSize argument. Server envelopes are retained. A client render cap cannot prevent an incompatible server from sending an entire catalog; server max-page enforcement remains Ali's work. |
| PagedCollection | Duplicate initial/scroll work already coalesced within a collection; stale query responses already invalidated. These behaviors were kept rather than replaced. No full-catalog loop exists in initial screen loading. |
| LazyTabStack/navigation | First-visit mounting with retained state, TickerMode/TabActivity and security epoch navigation remain. Repeated real Products tab switches cause one initial request. Keeping visited tabs trades memory for responsiveness; measure real-device steady state before introducing eviction. |
| Home/carousels/video | Existing viewport/tab/route/background pause and disposal remain; inactive slides allocate no controller, late initialization cannot play, video duration is bounded at the existing 15-second ad policy. Tests retain single-active playback and observer/controller cleanup. No animation/shadow redesign was justified by absent hardware traces. |
| Cache | Existing Flutter remote image RAM cache stays at 120 entries/64 MiB; live streams, native codecs and GPU/video memory are additional. LocalMediaCache is session-scoped, bounded to 256 entity pointers and does not own/delete picked files. Acknowledged updates and changed immutable URLs retain image freshness semantics. No disk catalog cache was added. |
| Signed URLs | Full query signatures stay intact in providers and keys. No new completed-response cache stores them. The backend must bound cached serialized URLs to their expiry and expose refresh/expiry metadata for private assets. Already-rendered pixels and existing screen models can outlive a transfer URL: expiry is not erasure/revocation of downloaded content. Universal CDN expiry enforcement remains a documented backend/client contract dependency, not a claimed fix. |
| Session/privacy | GET flights and cooldowns cannot be reused across account/role/base changes. Existing private page/caches clear on logout; stale private responses cancel. No patient records enter a public completed-response cache. |
| Search/listeners | Collection search is 350 ms; stale queries invalidate before the delay. Scroll controllers, debounce timers, page notifiers, lifecycle observers and video controllers have disposal paths. Existing viewport geometry notifications are frame-coalesced. Local country/form searches are finite and need no server call. |
| ETag/offline | No ETag/304 cache was added without a server contract. Valid prior pages survive page failure, and explicit retry recovers after backoff. This is not an offline database or a promise of fresh signed URLs offline. |

## Verification and remaining release dependencies

Final `dart format`, analyzer and full-suite results are recorded in the delivery message and load plan. New tests cover 520-record pagination boundaries, rapid search, in-flight GET identity, mutation invalidation, rate limits/refresh, cancellation, offline recovery, refresh content, real image decoding and repeated tabs; existing security, portal, visual, cache and video tests remain.

The backend needs stable tie-break ordering, max page size 20, Home/media joins and enrichment, cache invalidation/expiry alignment, query-plan-led indexes, worker/database capacity measurements and safe staging infrastructure. See [DJANGO_SCALABILITY_FOR_ALI.md](DJANGO_SCALABILITY_FOR_ALI.md). Execute the authorized scenarios in [SCALABILITY_LOAD_TEST_PLAN.md](SCALABILITY_LOAD_TEST_PLAN.md) before assigning numerical capacity/SLO budgets.

No 1,000-client capacity, release startup, 60/120 FPS or infrastructure readiness level is certified by these local tests. Windows and real Android/iOS verification were unavailable. All prior business boundaries, Clinic/Admin/Patient functional fixes and recovered visual design remain in scope; no Django implementation, payments, schedules, product prices, manual coupons or regulatory UI was introduced.

## Final validation and changed files

- Dart format: 200 files checked, zero changes remaining.
- Flutter analyze: zero issues.
- Full Flutter suite: **436 passed, zero failed** (410 baseline + 26 new tests/probes); no skipped/removed tests or regenerated visual goldens.
- Offline enforce-lockfile check passed; clock 1.1.2 remains the same resolved version, now direct.
- Load harness syntax and seven negative/one positive initialization guards passed with zero HTTP requests; k6 itself and real load were not run.
- Five Django example blocks parse; all 1,258 backend reference hashes are unchanged.

The complete performance diff contains these 31 files:

```text
docs/DJANGO_SCALABILITY_FOR_ALI.md
docs/FLUTTER_PERFORMANCE_AUDIT.md
docs/SCALABILITY_LOAD_TEST_PLAN.md
docs/performance/local_probe_measurements.json
lib/core/data/paged_collection.dart
lib/core/network/api_client.dart
lib/core/network/api_exception.dart
lib/core/network/auth_interceptor.dart
lib/core/network/request_backpressure.dart
lib/core/network/retry_after.dart
lib/core/widgets/luxury_image.dart
lib/core/widgets/patient_media_banner.dart
lib/features/appointment_lead/presentation/screens/my_requests_screen.dart
lib/features/articles/presentation/screens/articles_screen.dart
lib/features/clinics/presentation/screens/clinics_list_screen.dart
lib/features/home/data/home_repository.dart
lib/features/home/presentation/screens/home_screen.dart
lib/features/practitioners/presentation/screens/practitioners_screen.dart
lib/features/products/presentation/screens/products_screen.dart
lib/features/products/presentation/widgets/brand_product_media.dart
lib/features/treatments/presentation/screens/treatments_screen.dart
pubspec.lock
pubspec.yaml
test/admin_hardening_test.dart
test/image_display_regression_test.dart
test/patient_portal_visual_test.dart
test/performance_hardening_test.dart
test/performance_probe_test.dart
test/scale_runtime_test.dart
tool/load/staging_catalog.js
tool/load/validate_guard.cjs
```
