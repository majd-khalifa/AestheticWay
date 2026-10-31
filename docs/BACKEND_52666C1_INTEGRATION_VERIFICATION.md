# Backend 52666c1 — source identity and integration verification

Date: 2026-10-31 (Asia/Damascus). Frontend base: **8f48a80c311080299591f4f51dc3141914d6fb5b**, verified current origin/main and PR #13 merge. Feature branch: **codex/super-admin-analytics-forensic-audit**. Backend archive commit stamp: **52666c1711469ec8a3689cf54f93c1c5fa963e6e**; provided source, **deployment unverified**. Django is read-only. Test fixtures and screenshots are not production evidence.

## Identity

Provided archive: AESTHETIC_WAY_BACKEND_52666c1_SOURCE.zip. Git-archive ZIP comment is 52666c1711469ec8a3689cf54f93c1c5fa963e6e. SHA256: 82bd1337a3e935a444ba2367ec1a35efbcfbd560d15d1d244f1d46a67fe905fc. It contains 413 regular source files, safely extracted outside Flutter. Identity is the supplied archive's commit stamp and byte hash, not independent proof of AWS deployment or a signed Git attestation.

Comparison to the previously supplied c25e901ec10c7c3f751462b414d90d5ab88d3c85 snapshot confirms **exactly six modified paths**, no additions/deletions:

| Path | Verified change |
| --- | --- |
| apps/accounts/services/account_deletion.py | User UUID tombstone prefix shortened from 12 to 6 hex; phone prefix +deleted_ becomes +del_ |
| apps/accounts/tests/test_account_deletion.py | Expected prefix updated and length<=12 assertion added |
| config/settings/production.py | sys import; pytest/test-run heuristic; SSL redirect environment switch defaults true outside tests; secure cookie flags disabled only in detected test run |
| config/settings/testing.py | Explicitly disables redirect/session-secure/CSRF-secure in test settings |
| conftest.py | Autouse fixture disables SSL redirect for tests |
| pytest.ini | Explicit --ds=config.settings.testing, retaining default testing module |

No analytics, clinic, lead, product, referral, model or migration file changed. These six edits do not change the analytics contracts. Previously reported Google-association/gallery-isolation concerns need separate verification; this audit did not reproduce or resolve them, and does not negate the owner’s physical gallery/video/rating passes. Test settings still import base storage config; the isolated test boundary remains essential even with the new settings changes.

## Account deletion assessment

`Django apps/accounts/services/account_deletion.py:347` changes a normal anonymized phone from 21 characters to 11. `Django apps/accounts/models.py:80` declares max_length 20 and unique=True; the original 21-character value can fail on PostgreSQL after a valid OTP. The change logically addresses that specific length cause. SQLite does not enforce VARCHAR lengths, so normal-flow 99-test success alone would not prove the original production exception or its deployment fix.

A genuine local request/confirm flow succeeds with mocked delivery. However, the new 24-bit UUID prefix is not unique: two users sharing the first 6 hex characters yield 200 then 500 on confirmation. The second remains active. This is separately reproduced with synthetic UUIDs; no real accounts, OTP delivery or production storage was touched. Required collision-free schema/tombstone work is specified in the bilingual Ali handoff. Frontend must continue clearing sessions only after acknowledged success, preserving honest 400/401/403/409/5xx handling and sole-admin protections.

Production/test changes do not implement a new SMS provider, verify inbox/handset delivery, change the OTP proof contract or establish deployed cache/session health. Outside a detected test run, secure cookies remain true and redirect defaults true, but operators can override SECURE_SSL_REDIRECT. Verify trusted TLS/proxy settings privately; avoid using production settings test-mode results as security/deployment evidence.

## Actual analytics contracts and frontend compatibility

- POST analytics/events: exists but unsafe for activation as specified; no idempotent event acknowledgment, trusted client lead protection or metadata minimization.
- GET admin/analytics: date aliases supported, Dubai-based configured calendar dates, raw event counters, saved Lead count, sparse daily totals, fixed top 10 clinic IDs/names/counts. No per-clinic filter/page/unique-user/coverage contract.
- GET clinic-portal/analytics: own membership/rolling 30 days, not an arbitrary admin clinic.
- GET admin/clinics and admin/leads: real server search/pagination and supported operational date filters; used by the safe Flutter inspection/drill corrections.
- GET admin/analytics/referrals: lifetime counts only.
- Global brand-product/category, treatment category, moderation, review, settings and audit routes already exist. Their missing frontend tools are not new backend requirements.

## Local verification and limits

[Probe evidence](super-admin-analytics/source-evidence.json): 14 controlled observations including 52 role-read outcomes, actual local lead 201/server event creation, reproduction of metric shape, event poisoning/duplication, ignored filters, date boundaries, rollup uniqueness and deletion collision. Original source suites: 99 passed. Test environment: in-memory SQLite, filesystem-only temporary storage, network blocked, test providers, synthetic fixtures, no credentials.

All 413 before/after source hashes remain unchanged. Tests do not prove PostgreSQL constraints/concurrency/plans, R2/CDN delivery, production ingestion/metrics, deployed 52666c1, real OTP delivery or physical device success. The owner's earlier Android passes remain owner-reported evidence only. No backend fixes were applied.

## Integration verdict

**GO for reviewing source-compatible Flutter read-side corrections after their tests pass. NO-GO for complete trusted analytics and for declaring production deletion fixed.** Deploy and verify Ali's server fixes first, then typed Flutter instrumentation/complete reporting, then controlled staging/production/device reconciliation. Preserve the single app, role isolation, existing consultation/media flows, English/Light defaults and persisted preferences. Keep Django and signing unchanged and do not merge/publish automatically.

Final frontend checks: format clean, analyzer zero issues, **1,247 full-suite tests passed**, **91 focused tests passed**. Audit storage safety: seven regression tests passed. [Check results and exact file manifest](super-admin-analytics/verification.json). These are local Linux results, not native Windows/macOS, physical-device or deployed-server verification.
