# Consolidated client preview and MacBook handoff

Use branch `codex/final-backend-integration-client-preview`. This is a QA build runbook; no store upload or publication is authorized. New integration preserves the reviewed patient design and PR11 release-signing fail-closed configuration. For store upload credentials and Play App Signing ownership, retain [the original release runbook](MOBILE_RELEASE_RUNBOOK.md).

## Exact Windows QA-signed APK commands

Prerequisites: Flutter **3.41.5** / Dart3.11.3, Git, JDK17+ with `java`, `keytool`, `jarsigner` on PATH, Android SDK platform36, build-tools36.0.0, NDK28.2.13676358, accepted SDK licenses. This PowerShell helper generates a **disposable** RSA key outside the repository, builds, verifies the actual signature and hashes the result, removes the key and restores pre-existing signing environment settings. It never uploads anything.

```powershell
cd C:\Users\MVJD\Desktop\UAE_project\AestheticWay
git fetch origin
git switch codex/final-backend-integration-client-preview
git pull --ff-only origin codex/final-backend-integration-client-preview
flutter --version
flutter doctor -v
flutter doctor --android-licenses
flutter pub get
dart format .
flutter analyze
flutter test
# Pick an appropriate positive local QA version code. Also compiles a QA AAB.
.\tool\build_android_preview.ps1 -BuildNumber 20 -IncludeBundle
Get-FileHash .\build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
```

The helper passes exactly `--dart-define=API_BASE_URL=https://aestheticway.ae/api/v1/` to `flutter build apk --release` and optional `flutter build appbundle --release`. APK: `build/app/outputs/flutter-apk/app-release.apk`. AAB: `build/app/outputs/bundle/release/app-release.aab`. Neither file, keys nor passwords belongs in Git. Do not print environment secrets or use passwords as command-line literals.

A disposable key changes on each run and cannot update an app signed by another key or by Play. Use an isolated QA device/profile or an intentionally managed external QA key. Do not uninstall an existing app containing needed data merely to resolve a signature mismatch. A successful compile/signature check does not prove a device launch or production connectivity.

## Physical Android preview matrix (owner to perform)

Use authorized disposable accounts, no genuine patient records and no destructive production probes. Record build SHA/hash, device/OS, role and result without tokens/contact data.

| Flow | Expected check |
|---|---|
| First launch/preferences | Empty-storage English+Light, then selected Arabic/English and theme survive process kill/restart; reinstall/keychain cases separate |
| Inquiry/history | One lead POST per tap burst; exact Arabic success; My Requests refresh; no patient reference labels; real cooldown leaves inputs and recovery path |
| Clinic leads | Same owned lead listed and updated Contacted/Closed; foreign clinic/patient access rejected |
| Category proposal | Existing active category selection; propose bilingual missing category; pending status without premature selection; duplicate notice; form text retained |
| Admin category moderation | Super Admin only, paged requests/count; approve and refresh Clinic directory; reject with reason; archive/reactivate; safe delete with in-use rejection |
| Clinic media | Select multiple native images, preview/remove queue, upload/progress/failure/manual retry; save/reopen/restart/public-patient render; VIP video real playback/poster separate; no MP4-as-image |
| Deletion | Disposable account only; code delivery, invalid/expired/network states, explicit consent, confirmed logout and stale JWT denial; last-admin safeguards; do not use real owner accounts |
| API36/native release | Edge-to-edge, predictive back, permissions/limited gallery, Android activity death, keyboard and large fonts, 16KB device; signed release cold/warm launch, media/network/external links |

Owner's prior physical Android consultation/Clinic status success is recorded as **user-reported** evidence in the report, not this agent's completed smoke matrix.

## macOS / iOS engineer handoff

Use a Mac with **Xcode26.2 / iOS26 SDK**, Flutter3.41.5, Ruby3.3+ compatible with pinned Bundler4.0.20, CocoaPods from committed `ios/Gemfile.lock`, accepted Xcode licenses, iOS13.0 minimum, `com.aestheticway.aestheticWay`. Keep Podfile/lock, privacy manifests, entitlements, localized native permission strings and iOS icons from PR11.

```bash
xcode-select -p
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
flutter --version
flutter pub get
cd ios
gem install bundler --version 4.0.20 --no-document
bundle _4.0.20_ install
bundle _4.0.20_ exec pod install
cd ..
flutter build ios --release --no-codesign --dart-define=API_BASE_URL=https://aestheticway.ae/api/v1/
open ios/Runner.xcworkspace
```

Verify Bundle ID **`com.aestheticway.aestheticWay` in the actual project before provisioning**; the application ID is recorded in the CI evidence/runbook. Do not substitute an arbitrary registered ID. Confirm supported iPhone/iPad families, deployment targets, URL/link association entitlements, aggregated native privacy manifests and actual App Store privacy declarations in Xcode.

For a signed IPA: Apple Developer Program access, registered App ID, matching App Store Connect app, distribution identity/profile and private signing access are required. Select the correct team in Runner in the **workspace**, then use Xcode Product → Archive / Validate App. Alternatively, with an owner-maintained external export-options plist matching actual provisioning:

```bash
flutter build ipa --release --build-name=1.0.0 --build-number=20 \
  --dart-define=API_BASE_URL=https://aestheticway.ae/api/v1/ \
  --export-options-plist=/absolute/path/outside/repository/ExportOptions.plist
```

A signed archive/IPA requires the owner's credentials and is not established by unsigned CI. No TestFlight upload is part of this task. After separate publication approval, follow the original release runbook for Organizer validation, App Store Connect processing and beta-review role-access instructions. Before that, test a real iPhone/iPad: secure-storage retention/reinstall, photos/camera deny/limited/HEIC, video playback and lifecycle, external links, OTP/deletion and all three role flows. Preserve production role isolation; review access must use privately provided least-privilege accounts, never a bypass.

## CI evidence

`mobile-release-readiness.yml` runs on the new branch: disposable signed APK/AAB, resolved target36, signature/AAB/16KB inspection, missing-key rejection; Xcode26 unsigned release build and hosted simulator tests. Windows/Ubuntu workflow runs focused regressions, analyzer and full suite, plus integration renders. Exact completed jobs/results and remaining limitations are in [verification](final-integration/VERIFICATION.md). Old PR11 evidence alone is not presented as a new build.
