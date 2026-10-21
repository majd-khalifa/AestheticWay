# Scalability and load-test plan

Status, 2026-10-20: **not executed against a server**. No staging endpoint, authorized infrastructure, synthetic account set or physical Android device was supplied. The checked-in k6 artifact was syntax/guard validated locally; k6 is not installed here. Local widget concurrency is not a capacity certification.

Baseline application commit is `811b1bbcaf62906f19c851145777a72412266a82`; performance changes build on it. Preserve the security handoff and both prior PR dependencies. Never run this plan against production without a separate approved operational plan; this harness rejects the known production API hosts outright.

## Preconditions and operator authorization

Ali/infrastructure owner must record the exact staging API/CDN hosts, deployment SHAs, test window, maximum VUs/request rate, allowed fixture mutations, monitors, abort operator and cleanup plan. Merely having a URL or token is not load authorization. Use an isolated staging database/cache/object namespace and synthetic users, clinics, products and notes. Verify staging email/FCM routes use test sinks, cannot contact real recipients, and cannot mutate production analytics/referral state.

Record actual infrastructure: host/container CPU and memory limits, replica count, app server type/workers/threads, connection pool, database version/vCPU/RAM/storage/IOPS, max connections, Redis/cache version/resources, queue workers and brokers, storage/CDN topology, compression/TLS termination, network RTT and load-generator region/resources. Source PostgreSQL/Redis/R2 settings are not proof those services are deployed.

Seed at least 520 synthetic independent brand products with active/public moderation state; hundreds of clinics spread across cities/tiers; related practitioners/treatments/offers/articles and sufficiently distinct search matches. Include realistic description lengths, localization and media sizes. Confirm normal page_size=20, stable ordering and genuine nonempty responses before generating traffic. Load-bearing fixtures and JWTs stay outside Git; do not record request bodies or signed media URL query strings in exported logs.

Capture a pre-run deployment/database snapshot and test-only data cleanup identifiers. Never flush a shared Redis instance or kill a production service to create cold-cache/failure conditions. Arrange security patches first; do not load-test a known vulnerable branch as a public service.

## Required scenarios

| # | Scenario | Load shape / implementation | Assertions and measurements |
|---|---|---|---|
| 1 | 100 clients browsing clinics | `clinics100`: 30 s gradual ramp, 2 min hold, 30 s drain; 2–5 s think time | Correct city/tier order, 20-row envelope, statuses, p50/p95/p99 and connection/DB load. Extend steady state only after baseline. |
| 2 | 500 clients public catalog pages | `catalog500`: stagger Products/Practitioners/Offers/Articles, pages 1–3 | No eager full-catalog result, no N+1 growth per row; observe counts/search/query cost and response/media bytes separately. |
| 3 | 1,000 clients starting Products | `products1000`: peak 1,000 active k6 VUs requesting first page, with ramp/think time | Every request asks page_size=20. Measure actual simultaneous in-flight requests; 1,000 VUs does not imply 1,000 simultaneous HTTP requests. Compare cold/warm service/CDN conditions. |
| 4 | Search/filter bursts | `search` plus device search test: 50 VUs changing city/query | API search latency/CPU/DB plans, bounded key cardinality; device verifies 350 ms debounce, one final query and no obsolete city/category result. k6 cannot test Flutter debounce. |
| 5 | Home/carousel/media-heavy browsing | `home`, then `home_media` with up to three approved synthetic CDN fixtures per iteration | Feed query count, cache hit/miss, signature expiry, bytes, compression, image/video requests. Device verifies frame/codec/memory behavior and 15-second ad policy. k6 downloads do not decode/render video. |
| 6 | Rapid tab changes | `tab_mix` is an API workload approximation; real device repeated Home→Products→Clinics→Offers | Record actual request count, frame latency, mounted controllers/listeners and retained memory. Repeated visited tabs should not refetch solely from rebuilding. |
| 7 | Moderate consultation writes | `leads`: five separate synthetic patient VUs, **one write per VU**, no retry | Authorized patient, consent true, matching clinic/relations, exactly acknowledged records. Directly verify durable idempotency under a separately bounded duplicate test. No real patient contacts, notifications or appointment scheduling. |
| 8 | Cold/warm cache | `cold_warm`: operator isolates a new test namespace, then repeats identical dataset/run | Compare DB reads, cache hit ratio, CPU, payload and latency. Never use FLUSHALL. Distinguish app RAM, API data cache, DB buffer cache, object/CDN cache and TLS/connection warmup. |
| 9 | Temporary backend failure | `failure`: approved isolated fault proxy returns a bounded sequence of 503/429 + Retry-After, then recovery | No retry storm, no write replay, preserved prior pages, backoff/deadline honored, no false success. Run real Flutter test through proxy for actual app behavior; k6 applies only its documented client behavior. |
| 10 | Ramp, peak and recovery | `ramps`: 50→100→500→100→0 with monitored stages | Time to return to baseline queue/DB/latency after peak; no monotonic memory/connection growth or growing retry load. Raise peak only after owner approval. |

The script's counts/durations are **test inputs**, not observed performance. Run one scenario at a time first. A closed VU model with think time reduces offered request rate when the server slows; add a separately approved constant-arrival-rate experiment after measuring interaction rates to detect queueing/coordinated-omission effects. Do not derive required RPS by equating users to requests.

## Guarded harness

Artifacts: [staging_catalog.js](../tool/load/staging_catalog.js) and [validate_guard.cjs](../tool/load/validate_guard.cjs).

The initialization guard requires an exact approved HTTPS `/api/v1` target, explicit staging/synthetic acknowledgement and a sufficient VU cap. It refuses the known production apex/www/api hosts, mismatched targets, missing consent-to-test configuration and missing write/media fixtures. This does not itself establish owner authorization; configuration must follow the preconditions above. Redirects are disabled. No script operation flushes caches or changes infrastructure.

After owner approval, on the isolated load generator:

```bash
# Replace only with the host and cap recorded in the approved staging plan.
export AW_LOAD_BASE_URL='https://approved-staging.example.test/api/v1'
export AW_LOAD_APPROVED_HOST='approved-staging.example.test'
export AW_LOAD_AUTHORIZED='staging-synthetic-only'
export AW_LOAD_MAX_VUS='100'
export AW_LOAD_SCENARIO='clinics100'
k6 run tool/load/staging_catalog.js
```

For catalog500/products1000 explicitly update the scenario **and** approved cap after earlier stages pass. JWT files are optional for existing public AllowAny catalog endpoints; such runs measure public API service traffic rather than authenticated mobile sessions. Authenticated scenarios require a sufficiently varied synthetic account pool in `AW_LOAD_FIXTURE_FILE`; one token shared by 1,000 VUs primarily measures a single user's throttle and is not representative. No authentication bypass or temporary production rate-limit removal is permitted. Token expiry/refresh testing is a separate bounded session scenario.

The untracked fixture file for leads contains at least five records with `synthetic: true`, `access_token`, `clinic_id`, `name` and `phone`, all from isolated staging. The script derives the patient server-side through authentication; it does not send a chosen patient ID. Clean up only acknowledged synthetic records. For `home_media`, supply `AW_LOAD_MEDIA_FILE` containing approved synthetic HTTPS URLs and `AW_LOAD_APPROVED_MEDIA_HOST`; only that exact CDN host is requested, no API bearer is sent, and signatures are unchanged. Review fixture file sizes/transfer budgets before enabling media.

Do not use HTTP-debug output or archive a k6 bundle containing embedded account fixtures. URL/error system tags are disabled to avoid leaking signed tokens or identifiers. Route tags are static. Use the built-in `data_received` metric for transferred bytes; custom decoded-body characters are not bytes. Export only safe aggregates or redacted traces. Configure long-term storage retention and access.

Local validation performed here:

```bash
node --input-type=module --check < tool/load/staging_catalog.js
node tool/load/validate_guard.cjs
```

Result: syntax valid; seven unsafe/unconfigured initialization cases rejected; one configured staging initialization accepted; **zero HTTP requests**. This validates guard logic only, not k6 runtime compatibility or server throughput. The current operator stop condition is unexpected statuses >=10% after the initial 30 seconds. Treat 429 separately as a capacity/throttle signal, never hide it as successful browsing. Stop manually as soon as backend health or the authorized request budget is threatened.

## Measurements and operational stop conditions

| Layer | Required telemetry |
|---|---|
| Load generator | Request/iteration rate; VUs; p50/p95/p99 by route/status; timeout/network error rate; separate 429 rate; data_received/data_sent; CPU/RAM and connection limits of generator. |
| API workers / edge | Concurrent in-flight request gauge (not inferred from VUs), queue/wait/service time, worker CPU/RSS/restarts, event/connection saturation, keepalive/TLS, compression, upstream timeouts and status. |
| Database | Query count per request, representative EXPLAIN plans, p95 execution and lock waits, active/waiting connections, buffer/cache hits, reads/temp files, CPU/IOPS, replication lag where relevant. |
| Cache/queue | Hit ratio by cache family, evictions/memory/latency, refresh-lock contention, queue lag/retries/dead-letter count, stale serving and invalidation correctness. |
| Media/CDN | Origin fetches, hit ratio, latency, bytes/egress, object status/content type/range behavior, signature expiry and thumbnail coverage. |
| Device | Profile-mode startup/content/tab distributions, frame build/raster/jank against actual display refresh, heap/RSS/native/GPU/video memory, scroll, request count and offline recovery. |
| Recovery | Time from peak/fault removal until queues, errors, p95 and connections return to a defined baseline band. Record the band before the run. |

Assign owners to live monitors and stop at the approved resource/cost limit, sustained errors, unsafe DB connection occupancy/lock waits, growing queue lag, memory growth/restarts, unexpected notifications or any production route/identity. The harness's error abort threshold is an operational safety check, not a service SLO. Do not disable safety throttles simply to manufacture a successful throughput number; report their effect and design an explicitly scoped staging policy when needed.

## Performance budgets — pending measured hardware baseline

No capacity/SLO has been established. After Phase 1 and the first 1/10/100-client runs, use a reviewed numerical budget sheet containing: device p95 cold/warm/start-content/tab times; frame deadline `1000 / refresh_hz` ms (16.67 ms at 60 Hz, 8.33 ms at 120 Hz); tolerated missed-frame fraction; p95/p99 per API route; error/429 rates; bytes per first page/media; steady-state/peak memory; DB connection/CPU headroom; cache hit ratio; and recovery time. The display deadlines are physical timing facts, not achieved frame performance.

Latency, jank, error, payload, memory and cost budgets remain unassigned until the hardware/service baseline is measured. The existing 20-record page bound, 350 ms debounce and 15-second ad rule are contract invariants, not achieved latency SLOs. For each later numerical threshold record the baseline distribution, sample count, expected user experience, server cost, owner approval and regression tolerance. Then configure explicit k6 thresholds and device acceptance gates; do not retroactively fit budgets to hide poor results. The harness error abort threshold is only an operator-reviewed stop condition.

## Regression evidence and reporting template

Local Flutter gates cover deterministic invariants, not server load: pagination boundaries, page-size caps, 350 ms rapid filters, deduplication, late responses, current-session reads, 429/503 and refresh, cancellation, content retention, offline recovery, real image decoding, cache behavior, inactive video disposal and repeated tabs. The final suite/result is reported with the publishing commit. The measured local counts/fixture bytes are in [FLUTTER_PERFORMANCE_AUDIT.md](FLUTTER_PERFORMANCE_AUDIT.md).

For every later load run record: authorization ID/window; app/backend/load-script SHAs; topology/resources; fixture distribution and account count; offered versus achieved load; cold/warm definition; p50/p95/p99 and statuses by route; all layer metrics above; stop/recovery events; correctness checks; cost; raw redacted artifact locations; limitations; and a pass/fail against **pre-approved** budgets. Only then make a narrowly scoped statement about the measured capacity. Never certify 1,000 users using widget tests, Futures, an unmeasured worker formula or VU counts alone.
