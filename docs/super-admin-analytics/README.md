# Super Admin audit evidence

Frontend base: `8f48a80c311080299591f4f51dc3141914d6fb5b` (merged PR #13). Feature branch: `codex/super-admin-analytics-forensic-audit`. Backend: supplied `52666c1711469ec8a3689cf54f93c1c5fa963e6e` snapshot; deployment unverified.

## Reports

- [Full audit and priority findings](../SUPER_ADMIN_FULL_FORENSIC_AUDIT.md)
- [Event provenance and ownership matrix](../SUPER_ADMIN_ANALYTICS_EVENT_MATRIX.md)
- [Bilingual backend handoff for Ali](../SUPER_ADMIN_ANALYTICS_BACKEND_HANDOFF_FOR_ALI.md)
- [Implemented Flutter work and next steps](../SUPER_ADMIN_ANALYTICS_FLUTTER_ACTION_PLAN.md)
- [Acceptance checklist](../SUPER_ADMIN_ANALYTICS_ACCEPTANCE_CHECKLIST.md)
- [Backend source and integration verification](../BACKEND_52666C1_INTEGRATION_VERIFICATION.md)
- [Final local verification and changed-file manifest](verification.json)

## Actual Flutter renders

These are real widget-rendered PNGs at 430×1100, not generated mockups. They use synthetic, explicitly labelled fixtures to reproduce the reported metric shape, and canonical test fonts for consistent bilingual rendering. They do not prove real ingestion, production record provenance, native platform rendering, physical-device success or deployment. No screenshots or synthetic clinics were added to production app assets.

| Locale/theme | Report top | Daily totals and directory entry |
| --- | --- | --- |
| English / Dark | [Render](renders/analytics_dark_en_top.png) | [Render](renders/analytics_dark_en_directory.png) |
| Arabic RTL / Dark | [Render](renders/analytics_dark_ar_top.png) | [Render](renders/analytics_dark_ar_directory.png) |
| English / Light | [Render](renders/analytics_light_en_top.png) | [Render](renders/analytics_light_en_directory.png) |
| Arabic RTL / Light | [Render](renders/analytics_light_ar_top.png) | [Render](renders/analytics_light_ar_directory.png) |

Representative English/Dark and Arabic RTL/Light renders were visually reviewed. All four top/directory pairs are captured from actual Flutter output. Layout tests also exercise localization and both themes; existing broader admin tests exercise increased text sizes. This is not a physical Android/iOS acceptance claim.

## Reproduce safely

Use a disposable local Python virtual environment with the supplied backend's requirements. Set BACKEND_ROOT to the safely extracted read-only snapshot, outside the Flutter repository. Run from the Flutter root:

```bash
python tool/audit_super_admin_52666c1.py \
  --backend-root "$BACKEND_ROOT" \
  --output /tmp/aw-super-admin-source-evidence.json
python -m unittest discover -s tool/tests -v
flutter test test/super_admin_analytics_forensic_test.dart \
  test/admin_hardening_test.dart test/admin_portal_test.dart \
  test/portal_load_coalescing_test.dart
flutter analyze
flutter test
git diff --check
```

Screenshot capture is opt-in; normal tests write no previews. To reproduce the render pairs locally, add `--dart-define=ADMIN_ANALYTICS_CAPTURE_DIR=/tmp/aw-admin-renders` when running `test/super_admin_analytics_forensic_test.dart`.

The probe refuses a source tree other than the supplied snapshot and refuses an output path inside that backend, checks all 413 hashes before/after, initializes only RAM SQLite and temporary filesystem storage aliases before Django setup, blocks network and uses synthetic users/local OTP providers. It intentionally asserts the documented backend defects; its passing result is reproduction evidence, not server remediation. Never point it at a deployed Django process or change the guard to enable remote storage/database access.

The source-tree digest is SHA256 of UTF-8 JSON with sorted path→SHA256 entries and compact separators. [Source evidence](source-evidence.json) contains only synthetic status/count results; [archive delta](backend-delta.json) lists the six changed source paths; [review index](review-index.json) records baseline scope locations, not proof of exhaustive runtime or penetration coverage.

## Preserved review package

The original 34-file patch was recovered on the same branch and checked against all 15 preserved source/test/helper hashes. The six audit reports, original source evidence and all eight renders are retained. Only documentation/evidence status is updated during preparation for the new draft PR; Flutter behavior is unchanged from the completed audit. See verification.json for current local checks and the exact file manifest. The draft PR is the source for its committed SHA, Windows/Ubuntu CI links and live check status. Backend findings remain unresolved until Ali supplies and verifies the required contracts; no ingestion writes are activated.
