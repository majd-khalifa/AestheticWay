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
| Android release CI | **PASS** on code commit `75a7e199f7df959d254bf0b4401373a9da7447f9`, [native job](https://github.com/majd-khalifa/AestheticWay/actions/runs/39955046873/job/120418682326): signed Release APK **67.8MB**, AAB **54.0MB**; compile/target36, min24; APK v2 signature verified; all AAB entry digests/signature, 16KB bundle packaging and six 64-bit ELF libraries passed. Missing-signing-key rejection passed. Disposable QA certificate only. See `android-aab.json`, `apk-signature.txt`, `apk-sha256.txt`. |
| iOS/macOS CI | **PASS** on the same code commit, [native macOS job](https://github.com/majd-khalifa/AestheticWay/actions/runs/39955046873/job/120418681697): Xcode26.2 build17C52 / iOS26.2 SDK, **33.0MB unsigned device Release Runner.app**, all six app/plugin/Flutter privacy manifests; **2 hosted XCTest cases passed / 0 failed** on iOS26 simulator. Bundle ID/deployment13.0/families1,2 preserved; `ios-compilation.json`. No signed IPA or physical iPhone/iPad claim. |
| Native Ubuntu/Windows CI | **PASS on both native hosts**, [Windows](https://github.com/majd-khalifa/AestheticWay/actions/runs/39955100633/job/120418858627) / [Ubuntu](https://github.com/majd-khalifa/AestheticWay/actions/runs/39955100633/job/120418858897): analyzer0, focused existing regressions307, clinic regressions22, full suite**818**, new integration/navigation**28**, candidate golden capture9. Windows preview helper parsed successfully. This is actual GitHub-hosted native Windows execution, not physical Windows/Android device QA. |
| Owner-reported Android | Prior successful patient consultation → My Requests → Clinic Portal → Contacted/Closed. Owner evidence, not agent-operated or repeated production QA. |
| Production/device limits | Live hostname blocked here; real deployed source/CDN/Google/OTP/restart and account deletion not verified. Native permissions/activity death and store compliance still require owner QA. |

Formatting: **239 Dart files, 0 pending changes**; staged and unstaged diff checks clean.

Commands: `dart format .`, `flutter analyze`, `flutter test`, `git diff --check`; focused `flutter test test/final_integration_contract_test.dart --timeout 60s`. Backend probe is `tool/audit_clinic_contracts.py --backend-root <read-only-1f1e4bf-root> --output <outside-repo.json>` using an isolated dependency environment. Never run a destructive test against a real account.

## Immutable evidence and branch state

The links above identify the first fully verified consolidated **production-code** commit `75a7e199f7df959d254bf0b4401373a9da7447f9`. Subsequent evidence/report-only commits leave `lib/`, `test/`, `android/`, `ios/`, dependencies, tool scripts and workflow files unchanged. PR checks also run for the final documentation head; see the consolidated PR checks for the latest run. No APK/AAB/IPA or private signing material is committed.

- Consolidated PR: https://github.com/majd-khalifa/AestheticWay/pull/13 — open, main target, unmerged.
- Original PR11 head `872f20f7b0f2703f561069671e40c76e4488e6bc` and PR12 head `43e68249a522a69169cf1cb018dd63b0c2353ec1` are preserved as ancestors and their PRs remain open/unmerged.
- Native artifacts are retained by GitHub for 14days; the committed non-secret verification metadata remains here. R2, live Google/OTP delivery and physical release installation are still unverified.
