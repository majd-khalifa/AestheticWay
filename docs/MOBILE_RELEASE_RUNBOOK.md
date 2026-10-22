# Reproducible release builds and smoke checks

Reproducibility here means pinned toolchains/locked dependencies and an auditable artifact hash. Signed outputs are not promised byte-identical, especially when CI deliberately creates a fresh disposable certificate.

Use the exact release-readiness commit reviewed in PR #11. Do not publish from a working tree containing unrelated changes. These steps build artifacts; they do not upload anything to Google Play or App Store Connect.

## Windows: signed Android App Bundle

Requirements: Flutter **3.41.5** / Dart3.11.3, Git, JDK17 (`java`, `keytool`, `jarsigner` on PATH), Android SDK command-line tools, accepted SDK licenses, platform API36, build-tools36.0.0 and NDK28.2.13676358. Android Studio's SDK Manager can install them. Keep the upload keystore outside the project; recover/register the existing upload key rather than generating a replacement for an existing Play listing. Never put passwords in a `.ps1`, `.env`, `key.properties`, chat, Git or Flutter dart-defines.

PowerShell (run at repository root):

```powershell
git switch codex/mobile-release-readiness
git pull --ff-only
git status -sb
flutter --version
java -version

# Adapt this path to your Android SDK installation.
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
& "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
& "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" 'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358'
flutter doctor -v

# An existing, externally stored UPLOAD keystore. No file is copied into Git.
$env:AW_ANDROID_STORE_FILE = Read-Host 'Absolute external upload-keystore path'
$env:AW_ANDROID_KEY_ALIAS = Read-Host 'Existing upload-key alias'
function Read-ReleasePassword([string] $Prompt) {
    $secure = Read-Host $Prompt -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}
try {
    $env:AW_ANDROID_STORE_PASSWORD = Read-ReleasePassword 'Keystore password'
    $env:AW_ANDROID_KEY_PASSWORD = Read-ReleasePassword 'Key password'
    # Choose a versionCode greater than every artifact already in Play Console.
    $nextBuild = [int](Read-Host 'Unused Play versionCode')
    & .\tool\build_android_release.ps1 -BuildNumber $nextBuild -BuildName '1.0.0'
    if (-not $?) { throw 'Release build failed; do not distribute.' }
} finally {
    Remove-Item Env:AW_ANDROID_STORE_PASSWORD, Env:AW_ANDROID_KEY_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:AW_ANDROID_STORE_FILE, Env:AW_ANDROID_KEY_ALIAS -ErrorAction SilentlyContinue
}

# Final output, after a successful build:
Get-Item .\build\app\outputs\bundle\release\app-release.aab
Get-FileHash .\build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
jarsigner -verify .\build\app\outputs\bundle\release\app-release.aab
keytool -printcert -jarfile .\build\app\outputs\bundle\release\app-release.aab
```

Environment variables necessarily hold the passwords while Gradle runs. Use a trusted local terminal, do not print the environment or use command tracing, close the session afterwards and restrict filesystem access. The script requires all four settings, rejects a keystore inside the repository and checks native command exit codes. Release Gradle never falls back to debug signing.

For independent bundle inspection, download [official bundletool1.18.3](https://github.com/google/bundletool/releases/tag/1.18.3), verify SHA256 `a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29`, then:

```powershell
java -jar C:\ExternalTools\bundletool-all-1.18.3.jar validate --bundle=.\build\app\outputs\bundle\release\app-release.aab
java -jar C:\ExternalTools\bundletool-all-1.18.3.jar dump manifest --bundle=.\build\app\outputs\bundle\release\app-release.aab --module=base
java -jar C:\ExternalTools\bundletool-all-1.18.3.jar dump config --bundle=.\build\app\outputs\bundle\release\app-release.aab
```

Verify package `com.aestheticway.aesthetic_way`, target36/min24, debuggable absent/false, backups false, cleartext false and PAGE_ALIGNMENT_16K. The Linux CI verifier additionally verifies every signed ZIP entry and 64-bit ELF LOAD alignment; a Windows installation alone is not a 16KB-page device test.

### Play App Signing / protected build workflow

The signed AAB is signed with the **upload key**. Google Play signs delivered APKs with the separately managed **app-signing key**. Existing listing/package identity must match; do not rotate either key as part of this audit. Use the Play app-signing SHA256 (not upload/debug SHA256) for future `assetlinks.json`.

`.github/workflows/mobile-release-readiness.yml` generates a short-lived non-production verification certificate in runner temporary storage and deletes it after real compilation. It uploads only non-secret validation reports, never its private key or a test-signed distributable. This verifies signing mechanics, not ownership of the production upload key.

`.github/workflows/android-signed-bundle.yml` is prepared for owner use **after** review/merge. It only accepts main, uses protected environment `android-release`, and never calls Play APIs. The owner must configure required reviewers/branch restrictions and externally managed secrets `AW_ANDROID_UPLOAD_KEYSTORE_BASE64`, `AW_ANDROID_STORE_PASSWORD`, `AW_ANDROID_KEY_ALIAS`, `AW_ANDROID_KEY_PASSWORD`, plus public environment variable `AW_ANDROID_UPLOAD_CERT_SHA256`. None were configured by this task. Run manually with an unused versionCode; review the three-day AAB artifact before any later manual store action. The workflow verifies the actual upload-certificate fingerprint. Never attach signing material to a PR/issue/artifact.

## macOS: Xcode26 / iOS IPA

Requirements: an Apple-supported Mac with macOS Sequoia15.6 or a compatible later version for the chosen **Xcode26.2**, iOS26.2 SDK, Xcode command-line tools/license accepted, Flutter3.41.5, Ruby/Bundler and CocoaPods1.16.2. Check [Apple's exact Xcode compatibility table](https://developer.apple.com/xcode/system-requirements) before installing. CI uses the available `macos-15` standard runner (actual first-run Flutter SDK architecture was ARM64) with `/Applications/Xcode_26.2.app`; it fails instead of silently using an older SDK. Native project minimum stays iOS13; compatibility on the oldest physical OS and iPad remains a device gate. Existing Bundle ID is **`com.aestheticway.aestheticWay`**, case preserved.

```sh
export DEVELOPER_DIR=/Applications/Xcode_26.2.app/Contents/Developer
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
flutter --version
flutter pub get
cd ios
bundle install
bundle exec pod install
cd ..

# Real device-architecture compilation, WITHOUT signing; this is not an IPA.
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace
```

In Xcode's Runner target choose the authorized Apple Developer team, register the exact App ID in Certificates/Identifiers/Profiles and the App Store Connect app record, and configure distribution signing/provisioning. Preserve Keychain group `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)` and the existing Bundle ID/team prefix to retain credentials. No Associated Domains capability is claimed configured. Use Runner.xcworkspace, not the bare `.xcodeproj`.

To create a **signed archive and IPA**, after the owner configures signing in Xcode, export the App Store distribution options from Organizer to an external `ExportOptions.plist` with the correct team ID and method. Keep any local copy named `ExportOptions.local.plist` outside Git:

```sh
next_build=123 # Replace with an unused App Store Connect build number.
flutter build ipa --release --build-name=1.0.0 --build-number="$next_build" \
  --dart-define=API_BASE_URL=https://aestheticway.ae/api/v1/ \
  --export-options-plist=/absolute/external/path/ExportOptions.plist
ls -lh build/ios/ipa/*.ipa
```

The example build number is illustrative, not a claim that123 is available. `--no-codesign` cannot produce a distributable signed IPA. Apple team membership, app registration, valid distribution identity/profile, agreements, export-compliance answers and private credentials are owner prerequisites. No signing team/certificate/IPA/TestFlight acceptance is verified by an unsigned CI build.

### Explicit TestFlight owner steps (not performed here)

1. Review the signed archive in Xcode Organizer → Validate App. Inspect aggregated privacy manifests, entitlements, Bundle ID/version, symbols and warnings. Supply truthful encryption/export-compliance answers; do not blanket-claim an exemption.
2. After a separate publication authorization, use Organizer → Distribute App → App Store Connect, or Apple's Transporter, to upload the signed build. This task does **not** authorize or perform that upload.
3. Wait for processing in App Store Connect; complete App Privacy, Privacy Policy URL, age rating, support information, beta review instructions and privately supplied role accounts.
4. Add the processed build to an internal TestFlight group. External testers require Apple's beta review where applicable. Record actual iPhone/iPad OS/device/build results before App Store submission.

## Release smoke matrix and go/no-go

Use test accounts/records in a reachable isolated environment; never change JWT checks, OTP validation or role routing for review. Confirm the production hostname/HTTPS configuration in the **built** application. Record build SHA, AAB/IPA hash, signer identity, OS/device and each result.

| Surface | Required real release checks |
|---|---|
| Cold launch | Empty storage → English/Light; saved EN/AR and Light/Dark/System survive restart. Native Android/iOS launch → hydrated Flutter frame; no debug banners. Keychain retained on reinstall is tested separately from empty first install. |
| Authentication/roles | Verified patient, clinic_admin, super_admin enter only their portal; expiry refresh/logout/account switching clears private routes and cached identity; denied roles fail on server. |
| Patient inquiry/history | One POST per tap burst; exact Arabic success; no reference displayed/announced; actual history UUID/status persists; rejection retains all fields/consent and one notice; My Requests works immediately after a lead-specific429; Contacted/Closed reflect staff updates. |
| Authorization negative cases | With two owned test patients A/B: B's UUID detail aliases return404 for A; references/path fragments are not lookups; list/count stay scoped to A; clinic users cannot access another clinic's requests. Preserve server enforcement independent of hidden labels. |
| Media | Genuine uploaded logo/cover/images/video display; missing/failed decode keeps approved caption-free artwork; camera/gallery cancel/deny/limited-library states recover; Android activity death lost-data recovery, iOS HEIC on a real device and video playback/foreground lifecycle require native QA. |
| API36 | API24 and API36 device/emulator, Android16 edge-to-edge/system bars/back, keyboard, rotation/large screen, font scaling, permissions and 16KB page-mode device. Compilation/ELF checks do not replace these tests. |
| External links | Call/WhatsApp/Maps/Privacy/Terms/email success and missing-app failure; return/back safe. Incoming verified App Links/Universal Links are a documented separate blocker, not assumed to work. |
| Privacy/deletion | Registration and every role can reach public policies; support-assisted email clearly requests rather than completes deletion. **Do not mark deletion compliance passed until the backend lifecycle and public web request route are deployed and tested.** |
| Catalog/review | No patient subscription labels, fabricated Google ratings/reviews, product prices/cart/checkout, regulatory numbers or scheduling controls. Audit real records and media rights; fixtures are not store screenshots/demo data. |

Closed-testing preparation: complete the P0 items in [the report](MOBILE_RELEASE_READINESS_REPORT.md), store worksheet and Ali handoff. For personal developer accounts created after13 November2023, [Google currently requires](https://support.google.com/googleplay/android-developer/answer/14151465) at least12 opted-in testers continuously for14 days before applying for production access. The owner must verify account type/eligibility and the actual console requirements; this audit has no console access and does not claim those criteria are met.
