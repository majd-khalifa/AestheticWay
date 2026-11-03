# Final integration evidence — backend 5fd66e6

Authoritative archive:415 files, ZIP comment 5fd66e60d76350ac1feb2a044bf2e8544ecfc318, archive SHA256 8bffd159c3ceda9f847efbbfb5c6232b7eeecca651486b6a8e2d5a74ba2d05a9. `source-evidence.json` records 19 controlled observations. `backend-delta.json` records two additions/eight modifications versus 52666c1. `proposal-evidence.json` applies only to the PROPOSED module embedded in the bilingual handoff, not any installed endpoint.

Reproduce in a disposable Python environment with the supplied backend requirements, from the Flutter repository:

```bash
python tool/audit_final_phone_analytics_contracts.py --backend-root "$BACKEND_ROOT" --output /tmp/aw-final-contracts.json
python -m unittest discover -s tool/tests -v
flutter test test/final_phone_registration_test.dart test/super_admin_analytics_forensic_test.dart
flutter analyze
flutter test
git diff --check
```

The helper enforces the exact supplied source-tree digest, output outside Django, in-memory SQLite, temporary filesystem-only storage before initialization, blocked sockets and before/after 415-file hashes. All contact/OTP/provider values are synthetic. It intentionally reproduces remaining defects and asserts resolved behavior. A successful probe is not deployment/device success.

The full 141 original source tests were run in a separate fresh isolated process using Django labels: apps.accounts.tests.test_account_deletion, apps.analytics.tests, apps.admin_portal.tests and apps.leads.tests.test_patient_flow. Do not combine seeded probes with this runner: SQLite test setup can inherit the probe's fixtures. No source tests were changed.

The previous PR #14 is still draft/open and was not merged. Its reviewed commit was cherry-picked onto verified origin/main. Current local and remote CI evidence/manifest are recorded in verification.json and the new draft PR respectively. No native release configuration, signing identity or delivered APK changed.
