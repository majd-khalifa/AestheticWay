# Final Android release blockers and QA replacement checklist

Date: 2026-11-02 (Asia/Damascus). User-reported physical evidence belongs to **build 9001 / main 8f48a80**, not this new branch. No app publication or feature freeze is approved by automated test success.

| Priority | Item | Current disposition / exit evidence |
| --- | --- | --- |
| P0 | International registration/field errors | Targeted Flutter corrections implemented ; 70-country standard examples and Syrian/German widget/wire regressions. The exact physical attempt's invalid-versus-duplicate cause remains unverified. Replacement-device retest required with valid, authorized staging data. |
| P0 | Production backend version/migrations | **PRODUCTION_BACKEND_VERSION_UNVERIFIED; MIGRATION_STATUS_UNVERIFIED**. Enforced network policy blocks production and no production identity is configured. Ali must confirm running artifact SHA and accounts0007/analytics0003. |
| P0 | Engagement collection integrity | Source has improved UUID ACKs, but remaining actor/clinic/metadata/lead-privacy gaps and unverified deployment block activation. No runtime event sender was added. Call/WhatsApp handoff works independently; counters are not claimed collected. |
| P0/P1 | Every-clinic analytics | Current backend still lacks proposed period reporting routes. Reviewed PR #14 clinic search/paging/record inspection and isolated period request drill are preserved. Detailed engagement remains unavailable, never fake0. Ali's runnable proposed scaffold and trust/coverage work are in the bilingual handoff. |
| P1 | Deletion and rollup deployment | Source collision and NULL uniqueness defects are fixed by 5fd66e6. Actual migration/provider/device/concurrency success remains unverified; do not re-list those source defects as unresolved. |
| P1 | Physical QA / external dependencies | Verify replacement registration/OTP, all three portals, real media, existing consultation flows, verified-email deletion and client UAE GPS evidence. No physical device is attached to this execution. |
| P2 / investigate separately | Reported Windows seven-pixel placeholder mismatch | PR #14 native Windows and Ubuntu jobs both passed. No failing raster/provenance supplied for the reported dev run; no exact root cause claimed. Baselines/artwork/tolerances remain unchanged. New draft PR's native results must be read separately. |

## Targeted dependency and rule deviation

One new exact dependency: pure-Dart `phone_numbers_parser:9.0.29` (MIT), compatible with pinned Dart3.11.3; only its lock entry was added. No native plugin, CocoaPod, dependency upgrade or signing/configuration change. Standard examples are explicit test fixtures, never production clinic/contact data.

The current requirement for international numbering and no silent truncation supersedes the earlier universal ten-digit field rule. UAE still shows 10 local digits including trunk0; other selected countries use metadata-derived advisory limits. Overlength input is preserved and rejected, not truncated into a different valid number. Number-pattern validity is not subscriber ownership or reachability.

## Build 9001 replacement — physical Android acceptance

Use an unused increasing build number and the existing disposable-QA signing helper only after review. This task did not build or replace the delivered APK. Example Windows command (verify 9002 is unused first):

```powershell
flutter pub get
flutter analyze
flutter test
./tool/build_android_preview.ps1 -BuildNumber 9002
```

The helper creates and cleans disposable QA signing material, does not access a store upload key and does not publish. Keep the original 9001 APK and its QA notes; do not overwrite it or treat a fresh install as an upgrade/persistence test.

1. Record replacement commit/build, Flutter engine, Android/device locale and API environment without tokens or private URLs. Test fresh English/Light defaults and persisted theme/language after restart.
2. In EN/AR and Light/Dark, search/select UAE and Syria; ensure country flag/+code and LTR phone text remain correct. Enter local trunk0, Arabic/Persian digits, paste full+963/00963 numbers, edit/delete in the middle and reopen the country sheet. Test Germany with an allowed national number longer than 10 digits and Italy's meaningful zero. No number may be silently shortened.
3. Test missing/invalid email, too-short/invalid-format phone, overlength input and a valid authorized phone/email pair on staging. Invalid inputs must not POST. For duplicate phone/email use known disposable staging accounts; check distinct localized fields. Do not infer uniqueness by making repeated live production registrations.
4. Submit once and double-tap: immediate localized loading, one request. Rejections preserve name/phone/email/password/consent. Record only HTTP status, allowlisted API code and validation field names. Unknown errors must not echo server content or private values.
5. Successful registration requires actual201/user_id and then genuine OTP receipt, verification/login. Never display delivery as confirmed merely because dispatch was accepted. Provider failure after an account was created needs Ali's recovery guidance; do not loop account creation.
6. Recheck clinic/practitioner/gallery/VIP video persistence, patient media/Featured carousel, all five patient tabs, consultation→My Requests→Clinic/Admin lifecycle, country/location filters, role isolation and existing language/theme settings.
7. Until separately verified ingestion is enabled, expect explicit incomplete tracking, not measured zero usage. After Ali's changes and a separately reviewed integration: tap genuine profile/Call/WhatsApp/Maps once, compare source attribution/ACK/one row/server totals, and verify failures/retries/session changes do not inflate counts. No synthetic production events.
8. Per-clinic acceptance must include more than 20 clinics, correct clinic/date drill, all tiers, zero versus unavailable states, and no global app_open attribution. Confirm real OTP account deletion and UAE GPS separately with approved accounts; do not fake success.

## Windows seven-pixel investigation protocol

Preserve the exact failing actual/baseline/diff PNGs. Record `flutter --version --machine`, OS/build, renderer manifest from `python tool/visual_test_manifest.py`, target platform, viewport/DPR, font hashes and canonical capture invocation. Run the existing exact native-host golden tests; compare pixel coordinates/channels and geometry with the committed host-owned baseline. A seven-pixel difference alone does not identify an engine/font/DPR cause. Do not regenerate goldens, skip tests or introduce a tolerance as a substitute for evidence.

PR #14 reference evidence (head b1b3c5d): [Windows/Ubuntu run](https://github.com/majd-khalifa/AestheticWay/actions/runs/41210381077), both successful. These results do not certify a new head or reproduce the tester's different machine. Android/iOS Release compilation and physical/provider testing were not performed for this remediation task; native release configuration is unchanged.

## Verdict and sequence

**NO-GO for production publication / Feature Freeze.** Review the targeted Flutter fixes first. Ali verifies deployment and closes remaining ingestion/reporting/privacy gaps; reconcile contracts and stage the separately approved integration; then execute replacement-device and provider acceptance before production sign-off. Never merge/publish automatically.
