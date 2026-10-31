# Analytics acceptance checklist and evidence gates

Date: 2026-10-31 (Asia/Damascus). Frontend base: **8f48a80c311080299591f4f51dc3141914d6fb5b**, verified current origin/main and PR #13 merge. Feature branch: **codex/super-admin-analytics-forensic-audit**. Backend archive commit stamp: **52666c1711469ec8a3689cf54f93c1c5fa963e6e**; provided source, **deployment unverified**. Django is read-only. Test fixtures and screenshots are not production evidence.

## Local source and frontend gates

- [x] Verify main `8f48a80` and new isolated branch; retain all PR #13 fixes.
- [x] Archive commit stamp 52666c1711469ec8a3689cf54f93c1c5fa963e6e; SHA256 82bd1337a3e935a444ba2367ec1a35efbcfbd560d15d1d244f1d46a67fe905fc; exactly six changed files; 413 source files protected by before/after hashes.
- [x] Safe probe: RAM SQLite, temporary filesystem-only aliases, network blocked, synthetic accounts/OTP/providers, no production credentials. Four role reads ×13 routes =52 expected status outcomes.
- [x] 99 original account-deletion/analytics/admin tests passed in isolation; newly found flaws separately reproduced rather than hidden by their green result.
- [x] Reproduce the seven-lead-only shape and actual local saved-lead 201 → one server analytics event. Do not equate this fixture with the owner's real seven records.
- [x] Demonstrate legacy ingestion duplicate/forged events, ignored clinic/page filters, nullable platform-rollup duplicate and same-prefix deletion 500.
- [x] Implement availability/date/series/race/session/clinic-directory/scoped-lead/search corrections using only actual contracts.
- [x] Final `dart format .`: clean; analyzer: zero issues; full Flutter suite: 1,247 passed; focused suite: 91 passed; storage-isolation tests: seven passed; `git diff --check`: clean. [Exact verification](super-admin-analytics/verification.json).
- [x] Capture eight actual Flutter renders for EN/AR, RTL, Light/Dark; review representative EN/Dark and AR/Light output. Synthetic fixtures only; no production measurement claim. [Render index](super-admin-analytics/README.md).

## Mandatory backend acceptance — before activating collection

- [ ] Versioned schema and coverage metadata; anonymous/auth role behavior, no client-owned identity override.
- [ ] Same event_id/body submitted twice produces one row and matching persisted/duplicate ACK; mismatched body 409; concurrent requests, network loss after commit and retries all tested.
- [ ] lead_submitted cannot be ingested by clients; saved Lead produces one canonical event across retry/rollback/reconciliation. A rejected/cooldown lead changes neither counter.
- [ ] app_open rejects clinic attribution; only legitimate clinic interactions can bind to an eligible clinic/branch; private/draft/deleted/inactive/foreign objects rejected.
- [ ] Metadata denies contact numbers, URLs/message text, service/medical notes, full GPS, reference codes, JWT/OTP and arbitrary extra keys. Body limits, scoped throttles, retention/deletion and no-body logging tested.
- [ ] Platform rollup NULL key uniqueness, concurrent task reruns and stale-row repair verified on PostgreSQL.
- [ ] At least 21 clinics including zero-activity, mixed tiers/statuses/archived records: all pages/search independent of top 10, stable count/order, no cross-tenant detail leakage.
- [ ] Dedicated period clinic totals/series, nullable genuine unique-account counts and canonical platform totals; no summing top 10 or mixing lifetime counts with report windows.
- [ ] Dubai midnight edges, inclusive Sep 30–Oct 30 (31 dates), leap dates, empty periods, invalid/reversed/oversized ranges, UTC conversions and trend grouping verified consistently.
- [ ] Scale evidence from sanitized PostgreSQL representative data: indexed aggregation, query/latency budgets, payload size, stable pages and bounded dates. No live load test by this audit.

## Physical/staging end-to-end plan

Use explicitly approved disposable QA accounts/clinics; reset only fixture data, never public production metrics. Capture app/backend build IDs and UTC timing plus sanitized status/count deltas, not request bodies or credentials.

| User action | Required delta/evidence |
| --- | --- |
| Authenticated cold launch / restore | One app_open globally, clinic null; token refresh/resume/tab rebuild add none under the agreed definition |
| Open genuine clinic profile from Home/Featured/Nearby/directory | One clinic_view after successful visible detail; rebuild/autoplay/preload/failing GET adds none |
| Call / WhatsApp / Maps | One correctly attributed handoff attempt per accepted CTA; cancellation/unsupported OS handler remains an attempt, never a completed real-world action |
| Save consultation | Real 201 Lead, then exactly one saved Lead in My Requests/Clinic/Admin and canonical analytics; failures keep fields and add no success |
| Network timeout after accepted event | Same UUID retry yields duplicate ACK, one stored event; no UI blocking/notification storm |
| Account switch/logout | Queue and private results cannot move across identities; no stale report overwrites |
| Any clinic and date drill | Choose clinic beyond first 20/top 10, compare API totals/series and Lead records using identical Dubai bounds |
| Account deletion | Receive genuine OTP via verified channel, confirm success, verify fresh access/refresh blocked and PII/analytics retention policy; same-prefix fixtures both delete successfully after Ali's collision fix |

## Production sign-off (still unchecked)

- [ ] Ali confirms deployed SHA/migrations/settings; do not infer deployment from ZIP or 99 passing local tests.
- [ ] Real provider delivery and deletion confirmation pass on approved physical accounts; no OTP/channel bypass.
- [ ] Client confirms genuine UAE GPS distances on the already delivered APK; no APK replacement by this task.
- [ ] Production analytics sample reconciles known actions and dates end-to-end; explain any prior seven/zero snapshot with actual row provenance.
- [ ] CI/new-patch native Windows/Ubuntu and release-device checks completed where required. This task's local results must not be labelled native Windows/iOS or production success.
- [ ] Owner reviews privacy/retention declarations and authorizes deployment/publication separately. No automatic merge or publication.
