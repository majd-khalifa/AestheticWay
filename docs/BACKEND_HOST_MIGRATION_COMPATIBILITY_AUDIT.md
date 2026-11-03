# Backend host migration compatibility audit

Date: 2026-11-03 (Asia/Damascus). Audited frontend baseline: PR #15, `297a3ddae6eedd079820ca4ee3232101ca738eec`. This audit does not certify a production deployment or data migration. Django, production services, Firebase configuration and signing remain unchanged. Pending analytics work remains pending.

## Compatibility matrix — audited baseline and corrections

| Area | Source-grounded finding | Live evidence / disposition |
| --- | --- | --- |
| Default API | Baseline default was `https://aestheticway.ae/api/v1/`. Ali now confirms canonical `https://api.aestheticway.ae/api/v1/`; central default updated. Runtime/compile-time override precedence retained. | Canonical selection is OWNER/ALI-CONFIRMED; independent live reachability/TLS/schema remain UNVERIFIED. |
| Alternative API | `https://api.aestheticway.ae/api/v1/` works with configuration, same-origin policy and relative media resolution in offline tests. | DNS, TLS chain/hostname/expiry, HTTPS, JSON schema and redirects UNVERIFIED for BOTH hosts. Neither is certified live. |
| Build sources | Updated preview/release helpers, public capture default, Android readiness/signed-bundle CI and iOS readiness build define to the confirmed API subdomain. | Every current build path uses the canonical root with `/api/v1/` preserved. Website/invite/privacy origins unchanged. No artifacts rebuilt here. |
| Credential boundary | `AuthInterceptor` permits only configured HTTPS origin/path; strips supplied Authorization on public auth requests; disables redirects on normal and refresh requests; one refresh and one replay maximum per request. | Existing security retained. Migration tests assert cross-host rejection and 301/302/307/308 rejection without forwarding/replay. |
| Refresh failure | Refresh 401/403 clears authentication; network/503 does not. Credential epochs prevent stale responses reinstalling a session. | Isolated adapter tests cover 401/403/network/503, one refresh, retained theme key and no loop. No live JWT used. |
| Startup failure — confirmed Flutter defect | Splash caught every `/auth/me/` failure and called `AuthState.logout()`, deleting cached tokens/user even for outages or transient 401. | Corrected: retain credentials behind startup verification gate, offer localized Retry and explicit Sign in again. No protected portal opens based only on a cached role. Definitive interceptor logout still routes to login. |
| Preferences | Token clearing deletes only access, refresh and cached user keys; locale/theme/onboarding are separate. | Existing preference regressions plus retained-theme refresh test; Clear Storage is not the normal migration remedy. |
| Relative media | `/media/`, storage names and videos resolve against configured API origin, not `/api/v1/`. | Both host configurations tested. Actual storage/CDN object availability UNVERIFIED. |
| Absolute media | Existing/new-host HTTPS URLs and CDN/signed URLs remain on their own origin; signed bytes preserved. Unsigned first-party HTTP normalization is existing behavior. | Do not rewrite signed URLs or old-host objects blindly. Old provider shutdown can break absolute URLs even with correct parsing; Ali must verify storage continuity. |
| Public site / Maps | Privacy/deletion and invite URLs use website origin `aestheticway.ae`; Maps uses authorized Google external links. These are not API endpoints. | Website routes, app links, Places/rating synchronization and delivery after migration UNVERIFIED. No bulk domain replacement. |
| Push | `DeviceTokenService` can POST token/platform/app_version to configured `notifications/devices/`; source has no registration caller and no Firebase Messaging dependency. | End-to-end FCM acquisition/registration/delivery is not established. Not a newly proven hosting defect; do not claim unchanged Firebase implies working push. No Firebase configuration change. |
| Android | Actual `:app:printReleaseConfiguration --offline` succeeded: ID `com.aestheticway.aesthetic_way`, compile/target36, min24, NDK28.2.13676358, signingConfigured=false. INTERNET permission; cleartext disabled; no host pin. | Native configuration compatible with valid public HTTPS on either host; TLS/network/device behavior still unverified. No signing material created/accessed. |
| iOS | ATS defaults (no arbitrary-load exception), no API-host pin; iOS13 deployment target and Bundle ID `com.aestheticway.aestheticWay` unchanged. | No macOS/Xcode available; no fresh iOS compilation/device result claimed. A valid trusted HTTPS certificate remains mandatory. |
| Analytics | Previous ingestion/privacy/reporting gaps have not been supplied as resolved. | No sender, synthetic events, invented reporting endpoint or fake counters added. |

## Canonical root decision — Ali confirmation incorporated

Network policy is currently enforced and allows neither production hostname; TCP grants and production identities are absent. Live requests were not attempted through another route. Status: **CANONICAL_API_ENDPOINT_OWNER_CONFIRMED** (`https://api.aestheticway.ae/api/v1/`), **LIVE_API_COMPATIBILITY_UNVERIFIED**, **PRODUCTION_BACKEND_VERSION_UNVERIFIED**, **MIGRATION_EVIDENCE_UNVERIFIED** (Ali reports all applied; exact output absent).

Run the committed helper on the owner's Windows machine using PowerShell7.2+:

```powershell
pwsh -NoProfile -File ./tool/check_backend_hosts_readonly.ps1
```

It performs DNS/TLS validation and one unauthenticated public GET per candidate (`/api/v1/clinics/?page_size=1`), with default certificate validation, no cookies, no credentials and redirects disabled. Output includes statuses, content type, redirect destination origin/path, and JSON field names only. It does not print clinic records, tokens or signed media URLs. Run locally; do not use CI to bypass this environment's network policy. The helper was not executed against production in this environment.

Ali confirms the API subdomain is canonical and the website-host API reportedly works. The old AWS provider is retired. Default/build configuration now follows that explicit contract without depending on redirects or the retired server. Owner must still capture direct HTTPS200 JSON and certificate evidence for the canonical root; stop sign-off if it redirects or fails. JSON key presence alone is not full model/data compatibility or proof of an exact backend commit.

**Confirmed clean-database context (reported by Ali):** Hostinger PostgreSQL contains base schema and one newly created Superuser only. Previous clinic/patient accounts, leads, media associations and historical analytics were NOT migrated and are unavailable. Treat empty lists as a clean deployment, not successful historical migration or measured zero historical activity. A separate approved decision must establish whether to migrate/archive/retire historical data, and how to communicate account recovery/re-registration; do not restore or create anything automatically. No old account/JWT or content/entitlement continuity is promised. Only Ali's already created Superuser is reported to exist; no credentials were supplied or used.


## Ali — deployment and migration acceptance / التحقق المطلوب من علي

Provide safe aggregate/boolean evidence, not database dumps or private records:

1. Running artifact/full Git SHA on every web/worker instance; database migration listing, including accounts0007 and analytics0003 where part of the deployed source; deployment timestamp and rollback identifier. A source archive is not running-version evidence.
2. Confirm the intentionally clean inventory using safe aggregate counts and Superuser role evidence. Obtain a separate approved migration/archive/account-recovery decision before any historical restoration, re-onboarding or account creation. If migration is later approved, reconcile records, ownership/memberships, leads, catalog, subscriptions and media associations with aggregate counts and orphan checks. Do not send names, phones, passwords, tokens, patient records or raw lead metadata.
3. Confirm VIP/Featured entitlements, approval/publication/activation, gallery tenant isolation, R2 object retention and public HTTPS delivery. Check old absolute media references and separate video/poster/cover objects. No client hostname replacement can restore missing files.
4. State JWT signing/issuer/audience/blacklist continuity and intended handling of pre-migration tokens. Verify genuine login/refresh/role flows on authorized staging accounts; do not share JWTs. Confirm OTP/email provider delivery separately from dispatch acceptance.
5. Document historical backup custody/availability, authorized retention/deletion and a separately approved rollback/migration decision; do not imply backups or rehearsal already exist. Confirm required services/settings for the clean database. No production DB access or writes were performed here.
6. Verify public privacy/account-deletion routes, Google Places association/rating integrity and location/nearby behavior. Pending analytics identity/clinic/privacy/reporting work from the final Ali handoff remains a blocker.

**عربي:** أكّد علي أن قاعدة Hostinger جديدة وتحتوي المخطط الأساسي ومشرفاً جديداً فقط. الحسابات والعيادات والطلبات والتحليلات القديمة لم تُنقل وهي غير متاحة. يلزم قرار منفصل ومعتمد بشأن نقل البيانات أو أرشفتها وآلية استعادة الحسابات، مع إثبات SHA المنشور ومخرجات showmigrations المنقحة وصلاحيات المشرف الجديد. لا ترسل بيانات مرضى أو رموز وصول أو كلمات مرور. صلاحية HTTPS لا تثبت اكتمال نقل البيانات. يجب التحقق من الملفات القديمة وR2 وإرسال OTP والاستعادة من النسخ الاحتياطية. لم تُنفّذ أي كتابة أو ترحيل أو تجربة حساب إنتاجي هنا، وما زالت إصلاحات التحليلات السابقة غير مكتملة.

## Verification and QA recommendation

Current verification results and CI links are recorded in the stacked draft PR. Tests use synthetic fixtures/adapters; none demonstrates live service or physical-device success. Retain the original APK and build9001 QA history. Do not generate a final APK until independent canonical endpoint checks and the clean-environment/account-history decision are reviewed. The existing disposable-preview helper now selects the canonical subdomain; after approval use an unused increasing build number and require genuine fresh login against existing authorized accounts. Never forward old JWTs across origins or automatically create replacement accounts. A new disposable key cannot update an APK signed by a different disposable key: preserve the existing install/data and use a separate QA device/profile when required rather than recommending Clear Storage.

Physical acceptance must cover expired access/valid refresh, invalid migrated refresh, offline launch/retry without token loss, all three roles, saved theme/language/onboarding, genuine media after restart, VIP video, consultation/My Requests, Google links, and migrated content. Test accounts and writes require separate owner authorization; this task performed none against production.

**NO-GO for migration/publication sign-off** until canonical live compatibility, running version/migration evidence, the clean-database/historical-data decision, provider delivery and authorized device workflows are verified. The local startup correction can be reviewed independently. No PR is auto-merged.

## Exact change scope

- `lib/core/network/api_config.dart`: canonical production default/comment only; site/media security unchanged.
- `lib/features/splash/presentation/screens/splash_screen.dart`: outage-safe session verification gate.
- `test/patient_visual_recovery_test.dart`, `test/image_display_regression_test.dart`, `test/clinic_portal_completion_test.dart`: relative-media expected origin updated to canonical host; existing absolute/signed URL assertions preserved.
- `test/onboarding_review_workflows_test.dart`: invalid-session fixture now uses genuine HTTP401 with no refresh credential; authentication rejection remains distinct from HTTP403 permission denial.
- `test/security_hardening_test.dart`: concrete revocation fixture; canonical build/origin/media/redirect/refresh/startup regressions.
- `tool/build_android_preview.ps1`, `tool/build_android_release.ps1`, `tool/capture_public_clinic_contract.ps1`: canonical API literal only.
- `.github/workflows/flutter-visual-regressions.yml`: native Windows parses the four relevant PowerShell helpers without executing requests or touching credentials.
- `.github/workflows/mobile-release-readiness.yml`, `.github/workflows/android-signed-bundle.yml`: canonical build defines, including iOS; signing logic untouched.
- `tool/check_backend_hosts_readonly.ps1`: credential-free owner verification helper (PowerShell7.2+; not executed here).
- `docs/PROJECT_HANDOFF.md`, `docs/FINAL_CLIENT_PREVIEW_RUNBOOK.md`, `docs/MOBILE_RELEASE_RUNBOOK.md`: active API/build instructions use canonical host and release gates remain explicit.
- This report.

No Firebase, dependencies, Android/iOS native project settings, Django, migrations, live data or production signing changes. No telemetry or final APK generated.

### Safe evidence commands for Ali

Run in the actual deployed release environment with its existing settings, without exporting credentials:

```bash
git rev-parse HEAD
python manage.py showmigrations --plan
```

Supply the full deployed SHA with deployment/process evidence tying it to active web/workers, and redacted successful migration names plus applied markers. A checkout SHA alone is insufficient. Do not share settings, environment values, connection strings, error tracebacks, usernames, patient data or secrets. These commands are requests for Ali; they were not run against production by this audit.

## Final local results

- Flutter3.41.5 / Dart3.11.3, Linux: full suite **1,280 passed, zero failed**; focused auth/media/config/preferences/onboarding **154 passed**; security file **37 passed**; analyzer **zero issues**.
- Dart format verification and `git diff --check` passed. Actual offline Gradle resolved release-configuration task passed (API36/min24); no APK/AAB/IPA built or signing credentials generated.
- Windows/Ubuntu CI is requested by the stacked draft PR; consult that exact head's run links in the PR. Earlier PR15 CI results are not results for this patch. Native PowerShell parse runs offline only; no live host probes are executed in CI.
- No current macOS/iOS compilation, native physical-device test, live API response, production DB access or provider delivery verification. No final APK generated.

### Changed-file manifest

- `.github/workflows/android-signed-bundle.yml`
- `.github/workflows/flutter-visual-regressions.yml`
- `.github/workflows/mobile-release-readiness.yml`
- `docs/BACKEND_HOST_MIGRATION_COMPATIBILITY_AUDIT.md`
- `docs/FINAL_CLIENT_PREVIEW_RUNBOOK.md`
- `docs/MOBILE_RELEASE_RUNBOOK.md`
- `docs/PROJECT_HANDOFF.md`
- `lib/core/network/api_config.dart`
- `lib/features/splash/presentation/screens/splash_screen.dart`
- `test/clinic_portal_completion_test.dart`
- `test/image_display_regression_test.dart`
- `test/onboarding_review_workflows_test.dart`
- `test/patient_visual_recovery_test.dart`
- `test/security_hardening_test.dart`
- `tool/build_android_preview.ps1`
- `tool/build_android_release.ps1`
- `tool/capture_public_clinic_contract.ps1`
- `tool/check_backend_hosts_readonly.ps1`
