# Consolidated verification ledger

All results distinguish local execution, native CI, owner-reported QA and unverified production dependencies. No production content edits/deletions, store uploads or PR merges.

| Check | Evidence/status |
|---|---|
| Merge preservation | Both source PR heads and historical Clinic Portal commit pass `git merge-base --is-ancestor ... HEAD`; clean merges `7e505a5` (PR11) and `87f5f93` (PR12). Native Android/iOS files equal PR11 versions. |
| Backend source tests | 660 passed, Linux Python3.12.14/Django5.2.4, isolated in-memory SQLite/locmem/test storage. Reused audit venv; this is not a production Python3.13/Postgres lock claim. |
| Actual Django view contracts | 101 responses pass, 403 source file hashes unchanged. `controlled-django-contracts.json`; generated ephemeral secret and disposable role fixtures only. |
| Flutter analyzer | **Zero issues**, final local analysis after all production/test changes. |
| Flutter full suite | **818 passed / 0 failed**, final full local Linux run, Flutter3.41.5/Dart3.11.3 (2m00s). Focused new contract/navigation group: **28 passed**. |
| Renders | `RENDERS.md`, real Flutter widget rendering with explicit local QA fixture data/fonts. No patient golden baselines changed. |
| Local Android attempt | Attempted real signed release APK with external disposable QA key, removed afterwards. **Blocked before compilation:** managed proxy returned 403 downloading the required Flutter Android engine artifact from storage.googleapis.com. No local release compilation claimed. |
| Android release CI | New branch workflow enabled: APK + AAB with disposable external signing; signature/manifest/target36/16KB inspection and missing-key failure gate. Actual job results will be recorded after completion. |
| iOS/macOS CI | PR11 Xcode26/CocoaPods/privacy configuration preserved. New branch workflow enabled; unsigned device Release compilation and hosted iOS26 simulator tests. Results pending native CI, not assumed from prior PR11. No signed IPA/physical iPhone claim. |
| Native Ubuntu/Windows CI | New consolidated PR runs the existing pinned Flutter3.41.5 suite and new contract/render tests. Actual results pending; local Linux is not native Windows verification. |
| Owner-reported Android | Prior successful patient consultation → My Requests → Clinic Portal → Contacted/Closed. Owner evidence, not agent-operated or repeated production QA. |
| Production/device limits | Live hostname blocked here; real deployed source/CDN/Google/OTP/restart and account deletion not verified. Native permissions/activity death and store compliance still require owner QA. |

Formatting: **239 Dart files, 0 pending changes**; staged and unstaged diff checks clean.

Commands: `dart format .`, `flutter analyze`, `flutter test`, `git diff --check`; focused `flutter test test/final_integration_contract_test.dart --timeout 60s`. Backend probe is `tool/audit_clinic_contracts.py --backend-root <read-only-1f1e4bf-root> --output <outside-repo.json>` using an isolated dependency environment. Never run a destructive test against a real account.
