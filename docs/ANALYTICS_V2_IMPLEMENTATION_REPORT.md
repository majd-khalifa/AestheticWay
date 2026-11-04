# Analytics V2 Flutter integration

Date: 2026-11-04 (Asia/Damascus). Branch: `codex/analytics-v2-patient-integration`. Base: merged `main` at `bf7534db9fce915b0be01d0bcbd5e245bf1c4258`.

Implementation is present; production event emission is **OFF by default**. Automated source/mock/render verification does not establish live authenticated ingestion/reporting or physical-device success. No live events, lead creation, account creation, migrations, deployment or application publication were performed.

## Verified source and authority

The supplied archive SHA-256 matches `a426851463e1413d86edde6524d97fbf04407c6d4e591e7be3ce5ee08cc094a5`. All 360 source paths, sizes, SHA-256 hashes and Git blob SHA-1 identities match `SOURCE_MANIFEST.tsv`; the five provenance files identify commit `76a9566176c630d5ac810d874e081339bc70b9c5` and tree `4f6402f002434294860e886556cbb84ea496ccda`. No source redaction/modification was required for this task. The 69 excluded tracked paths prevent reconstructing the entire original Git tree from this focused archive; commit attribution is supported by the owner-supplied archive hash/provenance, not a fresh remote checkout or independent deployment inspection.

Django was extracted outside the Flutter repository and kept unchanged. Tests/capture ran against in-memory SQLite, temporary filesystem-only storage, mock providers and blocked network access using the existing fail-closed isolation helper. Original source tests: **102 passed, 4 PostgreSQL-specific checks skipped** (concurrent ingestion and EXPLAIN plans). Source migrations ran only in that disposable database. Synthetic Django API fixtures are in `test/fixtures/analytics_v2_contract.json`; they contain no patient notes, names, credentials or runtime records. Synthetic clinic names and UUIDs are test-only.

The previous 5fd66e6 handoff is not the V2 contract authority. Source 102-test success does not independently establish PostgreSQL concurrency, production migration application or running SHA. Network policy blocks the production host and no approved authenticated QA setup is configured: **LIVE_ANALYTICS_V2_UNVERIFIED**. Owner-reported public clinics200/JSON remains separate evidence.

## Backend-to-Flutter contract mapping

| Django source | Actual contract | Flutter mapping |
| --- | --- | --- |
| `apps/analytics/urls.py`, `views.py` | POST `analytics/events/`; private JSON endpoint.201/`created`,200/`duplicate`,409/`CONFLICT`. Accepted ACK includes the exact event UUID and `ingestion_version:2`;201 also serializes event fields. | `DioPatientEventSender`, `PatientAnalytics`: require status/version/UUID match. Invalid ACK never becomes an acknowledged event. Conflict/validation/permission failures are terminal; no invented success. |
| `apps/analytics/security.py` | JWT authenticated active, verified, nondeleted patient; staff/superuser excluded.4096-byte JSON bound. Fixed minute limits peer300/user60, plus configured rolling user limit. Throttle fails closed when cache is unavailable. | Client checks logged-in verified patient and nonempty access token; server remains authoritative for active/deleted/staff flags (not exposed by `UserProfileSerializer`). Existing origin/path/refresh protection retained. No guest, clinic or admin emission path. |
| `apps/analytics/serializers.py` | Required canonical UUID `event_id`, enum `event_type`. Non-app events require eligible active/approved/nondeleted clinic; optional active/nondeleted branch must belong to clinic. app_open is platform-only. `anonymous_id`, object fields are optional; client lead_submitted rejected. | Typed five-event enum; UUID-validated clinic/branch attribution; omit anonymous/user/object/timestamp/actor/version fields entirely. Only known nearest-branch association is included; never infer a branch from a phone or coordinates. Backend mismatch400 is not retried with changed attribution. |
| Same serializer | Metadata is enum-only: source, surface/screen/source_screen, category, action; optional branch_id must match explicit branch. Values at most32 chars. | Emits ONLY `{source:patient_app,surface:<typed enum>,action:open/view/tap}`. Actual surfaces: app,home,clinic_list,clinic_profile,clinic_details,maps. No arbitrary map, inquiry text, contact details, user/installation ID, JWT, signed URL or service description. Payload stays below4096 bytes by construction. |
| `apps/analytics/views.py:_payload_matches` | Replay binds actor HMAC, user, ingestion_version2 and full validated payload; changed actor/body conflicts409. | One UUID and immutable body per logical event; the same object/UUID is reused on transport retry and JWT refresh. No new UUID on retry. |
| `apps/admin_portal/urls.py`, `analytics_reporting.py` | GET `admin/analytics/clinics/`, GET `admin/clinics/<uuid>/analytics/`. Active nondeleted Super Admin only. | Dedicated `AnalyticsV2Repository` uses relative canonical API paths and a local role guard, plus session snapshots before accepting responses. No Clinic Portal membership impersonation or guessed fallback route. |
| `ReportQuery` | `date_from`, `date_to`, `search` max120, `include_deleted` defaultfalse, `page`>=1, `page_size`1–100 default20, `series_page`>=1, `series_page_size`1–100 default31, `compare` defaultfalse. Exact YYYY-MM-DD; years2000–9998; inclusive window at most366 days. Default today−30 through today. | `AnalyticsV2Query`; explicit Dubai calendar dates, bounded parameters, page1 on filter changes. EN/AR/UUID search is server-side. No client filtering/sorting pretending to cover the complete directory. |
| `scope`, `bounds` | All nondeleted clinics of every status/tier by default; include_deleted opt-in. Search name_en/name_ar case-insensitively or exact UUID. Stable primary-key ordering. Inclusive Dubai UTC+4 dates become UTC start and exclusive next-day end. | Preserve all returned statuses; archived indicator and opt-in. Require exact echoed dates, timezone `Asia/Dubai`, schema_version2 and matching UTC bounds. Never reinterpret host/Windows local timezone as reporting timezone. |
| `AdminClinicAnalyticsList` | `{count,next,previous,results,...metadata}`. Clinic rows: clinic_id,name_en,name_ar,status,setup_status,subscription_tier,is_deleted and metrics. Metadata includes dates/UTC bounds/generated_at/definitions/platform. | Typed page/clinic/metadata. Use count and next as pagination signals; returned URLs are never followed with credentials. Reconstruct trusted relative path/query for subsequent pages. Results from only one page are not platform totals. |
| `metrics`, `observed` | Five metrics: clinic_views,whatsapp_taps,call_taps,maps_taps,lead_submissions. `recorded_counts` includes legacy+V2 events for four interaction types; `trusted_recorded_counts` uses only V2. Both lead entries come from saved **consultation Lead records**, not raw lead events. | Distinct canonical/observed/validated-or-saved values. No client lead event or duplicate counting of raw server lead events. No lifetime/selected-period mixing. |
| `coverage`, `coverage_map` | Each metric has `{state:complete/partial/unavailable,reason}`. `counts` is null unless operator-attested coverage spans the entire requested interval; then trusted count can legitimately be0. Intervals union; future coverage is clipped at generated time. | Preserve null. Render canonical unavailable as `—`, never0. Complete zero is shown0. Ignore raw reason text in favor of fixed bilingual state labels. Show observed/trusted numbers separately, never as evidence of complete coverage. |
| `metrics`, `metadata` | `total_events` is null unless all five canonical counts exist. `recorded_total_events` sums only source-defined observations. `unique_authenticated_accounts` is deliberately null. `platform.app_opens` has recorded_count,trusted_recorded_count,count,coverage. No platform total of clinic events is supplied here. | No unique-user/rate/growth fabrication. No summing page rows/top ten into platform totals. app_open is not allocated to clinics. Canonical totals must be present and consistent; client never fills a missing total. |
| `AdminClinicAnalyticsDetail` | `{...metadata,result,daily_series:{count,page,page_size,results:[{date,...metrics}]},comparison:null-or-previous-interval}`. | ID/window-bound detail and paged explicit server days. No missing dates synthesized as zero. Typed comparison parsing tested; UI does not invent growth percentages. |
| `apps/analytics/services.py`, migration0004 | Server-owned saved-lead accounting, source_lead OneToOne and trust/coverage fields. No automatic historical trust/coverage backfill. | No lead_submitted client enum. Client never creates coverage rows or claims that validation/migration alone makes historical data complete. |

## Event collection and privacy controls

- `AW_ENABLE_PATIENT_ANALYTICS` is a compile-time bool defaulting to **false**. No release/preview workflow/helper enables it. Tests inject enabled instances with synthetic senders; this is not production activation.
- New authenticated app-session entry emits at most one app_open. Foreground resume/rebuild does not repeat it. Cold process restart starts a new app session; this metric is not unique people.
- clinic_view means a successful public clinic-detail lookup and a profile visible on the current completed route, in the foreground and active ticker, for500ms with at least half its area on-screen. Offstage/covered/preloaded carousel cards are not views. One view per clinic per authenticated app session, capped at200 distinct clinics; reaching the cap suppresses additional observations rather than growing memory or recounting evicted entries.
- Home/VIP/Featured, directory, Nearby, offer/treatment/practitioner/product navigation converge on the patient profile. Shared contact sheet and direct profile/Nearby Maps paths are covered. Patient My Requests contact actions are attributed to their clinic; platform support and Clinic Portal contact launchers are not instrumented. No new brand-product contact/purchase UI was introduced.
- Calls/WhatsApp/Maps record a genuine tap intent after local destination availability checks, not call connection, message delivery or physical arrival. Two-second deduplication uses type+clinic+branch across shared entry points. No duplicate listener/rebuild emission.
- Queue is memory-only: at most20 waiting events plus one active; event lifetime2 minutes; at most one explicit retry;8-second request deadline. Respect Retry-After only within bounded lifetime and at most60 seconds.400/401/403/409/413 and malformed acknowledgments never loop. JWT refresh may replay the same event body once under existing interceptor protections.
- Session snapshots/epochs stamp every event. Logout, role/verification changes and account switching cancel active work and clear pending events, timers, view/tap keys and ephemeral diagnostics. Profile dwell is restarted across identity changes. No durable identifiers/queue survive logout or cold restart.
- Telemetry has a dedicated Dio transport using the existing AuthInterceptor. Its503/429 cannot put consultation/API work into shared backpressure. Auth headers stay on the configured HTTPS origin and `/api/v1/` prefix; redirects remain disabled. Local preparation and transport failures cannot block actual contact handoff.
- ACK diagnostics are in-memory status counts only; they are not reporting metrics, successful conversions or a public UI. No raw responses, user contact values or secrets are logged.

## Super Admin UI and preservation

The default Analytics tab is now Clinic Analytics V2. The separate Legacy records tab preserves PR15's raw summaries, operational clinic inspection, lifetime counters and isolated period consultation drill-down. Lazy tab retention preserves each tab's state. Legacy data is explicitly not an attested V2 report.

The new UI provides bilingual server search, bounded directory paging, archive opt-in, date filters, clinic selection, canonical/observed/trusted counts, platform app opens, paged daily values and the existing date-filtered My Requests supervision drill. Revisions and session guards reject stale list, clinic, date and account responses. Loading, retry and error states are localized; duplicate reads are guarded. Premium admin colors/components and EN/AR Light/Dark remain in use. No Patient layout/artwork/navigation, phone behavior, media priority, consultation rules, signing or application IDs were changed.

## Verification evidence and limits

Final counts, file manifest and CI links accompany the Draft PR and `analytics-v2/verification.json`. Actual Flutter renders cover EN/AR × Light/Dark, clinic selection and complete zero versus unavailable values, plus narrow RTL at160% text scale. Screenshots contain only synthetic source-test records, not live clinic information.

The first default-concurrency full run hit an existing three-second native-video fixture completion guard. The exact failing video test passed in isolation with its original assertion/deadline unchanged. The subsequent controlled run passed the existing tests and exposed a new account-switch dwell regression. The visibility gate now cancels the previous identity’s timer, requires a fresh 500 ms dwell, checks the captured session again, and explicitly schedules a frame when an identity notification arrives while Flutter is idle. A post-frame callback alone otherwise remained stranded without a scheduled frame. A deterministic regression checks no early event for the replacement identity and exactly one event after its full dwell. Final results are recorded below; earlier failures are not represented as passing runs.

Final local verification (Flutter 3.41.5 / Dart 3.11.3 on Linux):

| Check | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed .` | 303 files checked, zero changes |
| `flutter analyze --no-pub` | Zero issues |
| Full `flutter test --no-pub --concurrency=2 --reporter expanded` | **1,338 passed, zero failures** |
| Focused event/report/render suite | **58 passed**, including the final identity/dwell correction |
| `git diff --check` and staged diff review | Pass; exact manifest has43 paths, including16 reviewed render PNGs |
| Backend source integrity after isolated tests | All360 files unchanged; manifest/path/size/SHA-256/Git blob checks pass |
| Native Windows/Ubuntu | Exact-head run/check links are added to the Draft PR after push; no prior-run result is substituted |

No new iOS/Android release compilation, provider/device test or live Analytics V2 verification is claimed. PostgreSQL concurrency/index-plan checks remain skipped. Existing backend source 102-pass evidence is local SQLite only. Native Windows/Ubuntu CI validates Flutter on those hosts, not live production counters or native mobile device behavior.

## Physical Android QA and safe enablement

1. Obtain explicit QA authorization, approved verified-patient and Super Admin identities, eligible approved public clinics and known active branch associations. Prefer isolated HTTPS staging. Record environment/commit/build without passwords, tokens or patient data. Do not create production QA accounts, events or leads without separate approval.
2. Ali/operator verifies actual running commit, applied0004 and live authenticated V2 GET schemas/permissions. This environment's host policy and absent credentials prevent those reads here. Public clinics200 alone is insufficient. Complete PostgreSQL concurrency/plan acceptance separately.
3. Default build: confirm zero event POSTs for all roles and ordinary usage. Only after approval, supply `--dart-define=AW_ENABLE_PATIENT_ANALYTICS=true` and an explicitly approved HTTPS `API_BASE_URL` to the existing QA run/build process. This flag was not enabled in production helpers and no build was produced by this task. Rebuild with the flag absent/false to disable; there is no remote switch that can silently activate it.
4. With the approved test patient: enter app once, resume/background, rebuild/navigate tabs; inspect one logical app_open per session. Visit each genuine Home/Featured/directory/offer-linked clinic profile; wait500ms. Rebuild/return in the same session without duplicate profile events. Preload/offscreen carousel cards must not emit clinic_view.
5. Tap Call, WhatsApp and Maps once from profile/contact sheet/Nearby and request history; verify correct clinic, known branch where available, enum-only metadata and one UUID per logical intent. Rapid duplicate taps coalesce; a later deliberate tap is a distinct event. Handoff continues when tracking is denied/offline. Never claim a connected call or delivered message.
6. Verify real201 created and200 duplicate UUID/version ACKs. For an authorized isolated retry scenario, retain the same UUID/body.409 is terminal, not a new UUID retry. Exercise400 branch mismatch,401/403,429,5xx, network loss, deadline and logout/account switching without leaking the old queued event to another account. Keep diagnostics to allowlisted status/code/UUID/operation and business attribution; never share Authorization headers or raw private payloads.
7. Super Admin: search EN/AR/UUID over more than20 synthetic staging clinics, all tiers/statuses and permitted archived records; verify stable pages, selected clinic, inclusive Dubai date bounds and daily-series paging. Change filters/selections mid-flight; only the latest response may display. Confirm saved consultation counts come from genuine approved QA requests, not raw lead events.
8. Without coverage attestation, canonical counts **must remain null/—**, even if an accepted event increases trusted_recorded_counts. Compare observed versus trusted rows and server ACKs first. Operator must attest only real collection AND retained-database intervals; do not seed coverage or mark legacy events trusted to make the UI show numbers. Complete zero requires an actually covered interval. Current-day/future windows can remain partial because coverage is clipped at generated time.
9. Verify protected patient/clinic/staff accounts cannot read Super Admin reports or submit unauthorized patient events; preserve Clinic Portal tenant isolation. Check genuine media/VIP placement, all five patient tabs, international phones, exact Arabic lead success and saved theme/language after restart. No fabricated ratings or old historical data is assumed in the clean database.

**Remaining gate:** source-grounded Flutter implementation and mock tests are review evidence. Live authenticated endpoint compatibility, approved physical-device ingestion/report reconciliation, actual coverage/retention and PostgreSQL acceptance remain external prerequisites. Leave the PR draft and unmerged. No production telemetry activation is authorized by this report.

**عربي:** تم فحص مصدر76a9566 والتحقق من بصمات الملفات، ولم يُعدّل Django أو تُرسل بيانات إلى الإنتاج. العلم `AW_ENABLE_PATIENT_ANALYTICS` معطّل افتراضياً. الأعداد الموثوقة تبقى غير متاحة عند غياب التغطية؛ الصفر الحقيقي يحتاج فترة مكتملة مثبتة. يلزم تفويض QA وهويات معتمدة وبيئة HTTPS، والتحقق من الردود الحية والتغطية واختبارات PostgreSQL والجهاز. لا ترسل كلمات مرور أو JWT أو بيانات مرضى، ولا تُنشئ تغطية أو أحداثاً وهمية لإظهار أرقام.

## Review artifacts

- [Exact changed-file manifest](analytics-v2/CHANGED_FILES.txt)
- [Source/verification summary](analytics-v2/verification.json)
- [English Light](analytics-v2/renders/v2_light_en_overview.png) · [English Dark](analytics-v2/renders/v2_dark_en_overview.png)
- [Arabic Light](analytics-v2/renders/v2_light_ar_overview.png) · [Arabic Dark](analytics-v2/renders/v2_dark_ar_overview.png)
- [Clinic detail EN](analytics-v2/renders/v2_dark_en_clinic.png) · [Clinic detail AR](analytics-v2/renders/v2_light_ar_clinic.png)
- [Complete zero EN](analytics-v2/renders/v2_light_en_zero.png) · [Unavailable EN](analytics-v2/renders/v2_dark_en_unavailable.png)
- [Complete zero AR](analytics-v2/renders/v2_dark_ar_zero.png) · [Unavailable AR](analytics-v2/renders/v2_light_ar_unavailable.png)

<details>
<summary>Historical phase1 blocker (2026-11-03), resolved by the supplied archive; retained for provenance</summary>

# Analytics V2 — phase 1 findings and blocking contract dependency

Date: 2026-11-03 (Asia/Damascus).

**Status: BLOCKED BEFORE IMPLEMENTATION. No Analytics V2 integration or live verification is claimed.**

## Baseline and source authority

- Verified latest fetched `origin/main`: `bf7534db9fce915b0be01d0bcbd5e245bf1c4258` (PR15 and PR16 merges preserved).
- New local branch: `codex/analytics-v2-patient-integration`, based directly on that main; no merged feature branch reused.
- Ali-reported deployed backend: `76a9566176c630d5ac810d874e081339bc70b9c5`; reported migration `analytics.0004_trusted_events_and_coverage`. Neither source contents nor deployed identity/migration evidence independently verified here.
- Connected GitHub GET for that commit returns404; repository GET also returns404. Read-only `git ls-remote` returns403. These are access failures, not proof the repository/commit does not exist.
- No matching source archive or `0004_trusted_events_and_coverage` migration was found in the available attachments/workspace sources. Existing5fd66e6 and earlier snapshots are historical only and were not substituted as V2 authority.
- Current enforced network policy permits neither production hostname; no production identity is configured. No live request, registration, lead creation, telemetry, deletion, OTP dispatch or database operation was performed. Owner-reported public clinics200/JSON does not establish authenticated Analytics V2 compatibility.

## Frontend findings — existing behavior, not a V2 schema

| Surface | Current implementation | Integration still required after contract inspection |
| --- | --- | --- |
| App startup | `lib/main.dart`; identity restoration and protected startup verification already exist. No app_open emitter found. | Authenticated verified-patient lifecycle semantics, bounded deduplication and session-safe event lifetime. |
| Home / VIP / Featured | `features/home/presentation/screens/home_screen.dart` navigates to clinic profile; cards are built/preloaded without an event service. | Define source-confirmed visibility metric; do not treat carousel build/preload as a view. |
| Clinic directory | `features/clinics/presentation/screens/clinics_list_screen.dart` opens patient profile and shared contact sheet. | Integrate logical interactions once; do not emit both card and destination views for one metric without a specified definition. |
| Patient clinic profile | `features/clinics/presentation/screens/clinic_profile_screen.dart` has shared contact actions and direct external Maps actions. | Cover all real contact/map paths with valid clinic/branch attribution, without delaying or falsely claiming external conversions. |
| Contact sheet / Nearby | `features/clinics/presentation/widgets/contact_options_sheet.dart`, `features/locations/presentation/nearby_clinics_screen.dart`, `core/utils/maps_launcher.dart`. | Avoid global launcher instrumentation that would count staff/admin or unrelated Google rating/support actions. Preserve manual pin versus verified business identity. |
| Offers and indirect navigation | `features/offers/presentation/offer_actions.dart`; treatment/practitioner/product detail routes can lead to patient clinic profile. | Audit shared handoffs and destination visibility; preserve product showcase boundaries. |
| Super Admin reporting | `features/admin/data/admin_repository.dart:getAnalytics` calls `ApiConfig.adminAnalytics` (`admin/analytics/`), validates requested date echoes and uses legacy model fields. | Real V2 paginated directory/detail schemas and coverage parsing are missing, not inferred from older examples. |
| Metric availability | `AdminAnalyticsModel.recordedCount` preserves absent platform metrics as unavailable using availability metadata. Legacy entry parsers still have zero fallbacks. | Introduce V2 nullable semantics only from verified fields; do not treat legacy numeric defaults as trusted V2 coverage. |
| Clinic selection / requests | Existing analytics screen uses operational clinic directory paging, lifetime record information and period request drill-down, with availability warnings. | This is not V2 per-clinic analytics. Keep lifetime and period data separate; do not relabel current output as V2. |
| Race / role boundaries | `AdminPortalService` has session/revision-scoped reporting; shared AuthInterceptor protects API origin and session refresh. | Preserve these protections while adding V2 flows and all requested failure/session-change tests. |
| Clinic Portal | Existing clinic dashboard has tenant-scoped interaction fields. | Do not count Clinic Portal actions as patient events or repurpose its membership endpoints for Super Admin. |

Searches covered `lib/core`, all `lib/features` and startup for analytics routes/event types, direct URL launches, Maps helpers, clinic-profile entry points and reporting state. No runtime event ingestion call or client lead_submitted emitter was found. Metadata allowlists, trusted coverage fields and V2 response keys remain UNKNOWN until the new backend is supplied.

## Exact contracts required to unblock implementation

The following are requested verification targets, **not verified deployed routes or invented schemas**:

1. `POST /api/v1/analytics/events/`: actual serializer fields/types/required values, allowed event types and metadata values, authenticated verified-patient eligibility, actor binding, UUID replay/conflict comparison, clinic/branch validation, payload bounds/throttles, 201/200 acknowledgment fields and 400/401/403/409/429 error contracts. Confirm no client lead_submitted and no sensitive metadata.
2. `GET /api/v1/admin/analytics/clinics/`: exact versioning, search/filter parameters, pagination shape/limits/order, localized names/stable identifiers, nullable counts, saved-lead accounting, coverage states and any platform totals. Do not infer names from the old proposed handoff.
3. `GET /api/v1/admin/clinics/<uuid:clinic_id>/analytics/`: exact fields, permission/deleted/archive behavior, reporting date/timezone boundaries, coverage/history semantics, daily-series availability and error responses.
4. Migration0004 and related models/services/tests: trust/coverage provenance, legacy event inclusion/exclusion, uniqueness/indexes, user/session semantics and server-owned canonical leads. Reported migration application is not schema documentation.

Please supply a backend source archive at76a9566 (or a containing commit with demonstrable ancestry) including analytics models, serializers, views, URLs, services/validators, permissions/authentication, migration0004, relevant tests and referenced account/clinic/lead contracts. Exclude real credentials, `.env`, signing keys, database exports, patient records and provider secrets. An accessible read-only repository connection is an alternative.

**عربي:** التنفيذ متوقف قبل كتابة تكامل V2 لأن مصدر الخادم النهائي غير متاح: وصول GitHub يعيد404 وGit يعيد403. نحتاج أرشيف المصدر للنسخة76a9566 أو نسخة تتضمنها، مع serializers/views/URLs والصلاحيات والترحيل0004 واختبارات التغطية والثقة. لا ترسل كلمات مرور أو JWT أو بيانات مرضى. وثائق5fd66e6 القديمة ليست عقد V2، ونجاح GET العام لا يثبت نجاح الإدخال أو التقارير المحمية.

## Event-emission status and production gate

There is currently **no new emitter and no new emission flag**. No telemetry is emitted by this task. Do not confuse absence of implementation with a tested disabled-by-default V2 implementation.

After source verification, implement the sender behind an explicit disabled-by-default emission flag unless approved staging/production QA identities and authorization are supplied. Flag name and enablement instructions will be documented with the real implementation. An enabled build flag must never bypass verified-patient checks, server permissions, safe metadata, session isolation, bounded queues or approved QA scope. No arbitrary wire fields, queue behavior or success criteria were implemented without their contract.

## Verification and work manifest

- Existing Super Admin analytics regressions: **17 passed** (`flutter test --no-pub test/super_admin_analytics_forensic_test.dart --reporter expanded`). This verifies preserved legacy read-side behavior only, not V2 ingestion/reporting/security.
- No runtime/API/native/Firebase/signing/dependency/test-fixture changes. Main's phone, media, luxury UI and session fixes preserved.
- Full suite/analyzer/new Windows/Ubuntu V2 CI not rerun for this Markdown-only blocked phase. Previously reviewed CI is baseline evidence, never proof of new V2 code or deployed behavior.
- Current changed-file manifest: this Markdown report only. No implementation commit or PR created while the essential contract is missing.
- No APK/AAB/IPA build, publication, backend edit, deployment, migration or production write occurred.

## Resume sequence

Inspect the supplied final source first; map every wire field/ack/error/coverage rule with source paths; then implement typed authenticated patient events and genuine server reporting. Add synthetic isolated unit/widget/API regressions for the requested roles, retries/conflicts, session switching, branch validation, paging/search, nullable/historical coverage, EN/AR and Light/Dark. Then run formatting, analyzer, complete Flutter tests and native Windows/Ubuntu CI, commit/push this dedicated branch and open the requested Draft PR against main. Physical authenticated QA remains separate, requires approved identities/authorization and must reconcile real acknowledgments/server counts without fabricating events or leads.

</details>
