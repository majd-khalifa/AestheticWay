# Onboarding / review increment — verification ledger

The source for this increment starts at `c8da3d76da2767db4614da87263fe72d14672120` on existing PR13. Prior PR11/12 and historical Clinic Portal changes remain ancestors. No native signing/project/dependency files changed in this increment; the existing Android/iOS CI workflows remain enforced. No Patient golden baselines changed.

| Evidence | Result / scope |
|---|---|
| Formatting | `dart format .` across242 Dart files; final repeat reports0 pending changes. |
| Analyzer | `flutter analyze` — **zero issues** on local Linux, Flutter3.41.5 / Dart3.11.3. |
| Full Flutter suite | **853 passed /0 failed**, local Linux,2m06s; no skips, raised timeouts, dropped image decoding or weakened golden thresholds. |
| New regression file | **35 tests**, device-local completion/restart/storage errors, all-role startup/logout, failed/replaced session, server-only counts/refresh/coalescing/permissions, full supported admin approve path, rejected/stale states, localized setup/video controls and320dp nav. Includes a delayed pre-moderation count-response test and two delayed-storage tests proving startup cannot resurrect logout/replaced identity. |
| Focused workflows | Onboarding/review + existing admin group: **48 passed**. Existing gallery/video native-picker/file fixtures and lifecycle coverage remain passing. |
| Actual Django source execution | **122 responses passed** using the real1f1e4bf views/serializers/models, disposable force-authenticated users, in-memory SQLite and local test media. Includes complete setup submit→verify→clinic refresh, separate suspend/activate, ignored setup filter/PATCH, nonexistent Reject, readable rejected fixture resubmission, VIP MP4 persistence/public projection and Basic denial/removal. See controlled ledger. |
| Read-only integrity | **403 source file hashes unchanged** vs supplied archive inventory, including models/serializers/views/URLs. Archive SHA in `source-integrity.json`. |
| Backend full suite | Previous unchanged-source baseline: **660 passed**; not reclassified as a newly executed full run in this increment. |
| Rendered output |35 real Flutter PNGs from current fixtures; see `RENDERS.md`. Linux widget renderer with Android presentation/fonts; also captured in native Windows/Ubuntu CI artifacts. No physical Android screenshot/codec/live-R2 claim. |
| Native Windows/Ubuntu | Existing PR workflow now also runs the new35-test file/captures, analyzer and full suite on both hosts. **Use current PR13 head checks for actual run conclusions**, not the historical818-test baseline. |
| Android/iOS release preservation | `.github/workflows/mobile-release-readiness.yml` still builds disposable-signed API36 APK/AAB and unsigned iOS Release plus hosted XCTest on macOS. `android/`, `ios/`, dependencies and signing remain unchanged. Current-head run links are available under PR13 checks. No production keys, signed IPA or store upload. |
| Physical / live dependencies | No owner-operated device on this increment; actual QA-clinic tier, deployed API version, real Android picker/codec/process death, R2/HTTPS and production JWT behavior are unverified. Previous consultation journey is owner-reported only. |

PR and native execution links: https://github.com/majd-khalifa/AestheticWay/pull/13/checks . Match the Actions run head to the delivered commit. Historical native evidence remains separately under `../final-integration/VERIFICATION.md`; it must not stand in for a newer commit's checks.

Reproduce locally (Flutter3.41.5):

```sh
dart format .
flutter analyze
flutter test
git diff --check
flutter test test/onboarding_review_workflows_test.dart \
  --dart-define=ONBOARDING_REVIEW_CAPTURE_DIR=/absolute/output/path
python tool/audit_clinic_contracts.py --backend-root /read-only/backend-1f1e4bf \
  --output /outside/backend/controlled-django-contracts.json
```

The Python probe requires the supplied backend's declared dependencies and refuses non-memory/non-test settings; do not point a generic test runner at a live database. The newer audit still leaves backend source unchanged. Full-store removal is tested, physical uninstall semantics are not: Keychain/backup persistence can survive reinstall.
