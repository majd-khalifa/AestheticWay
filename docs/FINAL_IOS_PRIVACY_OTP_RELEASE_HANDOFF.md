# Final iOS privacy and email OTP release handoff

Date: 2026-11-06 (Asia/Damascus). Branch: `codex/ios-privacy-email-otp-release`.
Base: `c70adf528dbc41b1d09358262999f09eb25820ce` (current main, including PR19).

## Scope and evidence boundaries

This corrects authentication instructions and the app-owned iOS location disclosure. Authentication endpoints, request payloads, OTP verification and resend rules, role routing, Nearby behavior, location requests and retention logic were not changed. No backend, signing credentials, identifiers, deployment targets, dependencies or release build workflow changed. `AW_ENABLE_PATIENT_ANALYTICS` and `AW_ENABLE_CLINIC_SHOWCASE_VIDEO_UPLOAD` retain their false defaults.

The available read-only backend snapshot is commit `76a9566176c630d5ac810d874e081339bc70b9c5`; all 360 source-file hashes were rechecked against the previously verified archive manifest. Archive SHA256: `a426851463e1413d86edde6524d97fbf04407c6d4e591e7be3ce5ee08cc094a5`. This is source evidence, not independent evidence of the currently deployed email provider, mailbox receipt or production retention configuration. Registration/password-reset email delivery is also owner-reported physical QA evidence. No live OTP request, account creation, production write or Django execution was performed for this task.

## OTP purposes and verified channels

All endpoints below retain the existing `/api/v1/` prefix and HTTPS production origin `https://api.aestheticway.ae/`.

| Purpose | Source-confirmed contract | Delivery and frontend decision |
| --- | --- | --- |
| Registration | `POST auth/register/`, required `email`, phone identifier; 201 with `user_id`, `otp_purpose`, `expires_in` | `RegisterView` calls `OtpService.send_otp(..., email=user.email)`. Show registered-email instructions; never display the phone as the destination. Account creation is announced only after the existing repository validates 201/user ID. |
| Verify registration/login | `POST auth/verify-otp/` with `phone`, six-digit `otp_code`, purpose `registration` or `login` | `OtpService` verifies the phone/purpose-bound challenge; tokens and role routing remain unchanged. Verification is not an email delivery request. |
| Resend registration/login/reset | `POST auth/resend-otp/` with `phone`, `purpose`; 200 with `expires_in`, `resend_cooldown` | `ResendOtpView` uses the email-only `OtpService`. The existing initial/resend 60-second client countdown and duplicate-tap guard remain. Localized confirmation describes a request, not proven mailbox delivery. Login OTP remains supported by this existing screen/contract; no new login-code initiation UI was added. |
| Password recovery | `POST auth/forgot-password/` with `phone`; `POST auth/verify-otp/` purpose `password_reset`; then `POST auth/reset-password/` with the same phone/code and `new_password` | Backend sends to the registered email. Conditional wording does not assert an account exists. A reset screen opens only after verification acknowledgment. Existing reset grant/security and invalid-code/error handling remain. |
| Verify existing/change email | `POST auth/me/email/change/request/` with `new_email`; `/confirm/` with `new_email`, `code` | `ProfileChangeService` sends to the requested email using `mailer.services.send_email`. Existing `VerifyRegisteredEmailScreen` correctly reuses the current account email, requires its own code, and checks fresh `is_email_verified` read-back. Its honest acceptance wording is preserved. |
| Change phone | `POST auth/me/phone/change/request/` and `/confirm/` | Separate service sends SMS to the **new phone**, not the registered email. Repository support remains unchanged; this audit found no exposed Flutter phone-change editor. Do not globally relabel this purpose as email. |
| Delete account | `POST auth/me/deletion/request/` and `/confirm/` | Independent service can dispatch to a real SMS provider and/or verified email. Existing screen parses only server `deliveries` / `delivery_channel` and `masked_destination`; never infer email from a profile. Missing metadata remains unknown, acceptance is not receipt, and last-admin/sole-clinic-admin protections remain. |

Source evidence: `apps/accounts/views.py` (`RegisterView`, `ResendOtpView`, `ForgotPasswordView`, `VerifyOtpView`, `ResetPasswordView`), `services/otp.py`, `services/profile_change.py`, `services/account_deletion.py`, account URLs/serializers and `tests/test_email_otp.py`, `test_profile_change_otp.py`, `test_account_deletion.py`. These tests were inspected; their historical execution is not claimed as new production verification.

Registration/resend/recovery responses do not provide a verified masked destination in this contract. The corrected shared OTP screen therefore uses **registered email**, without displaying a full email, guessing an address or treating `targetContact` as the destination. Phone values still go unchanged through the existing normalization and API fields. Server error handling remains unchanged; successful instructional copy is localized rather than displaying arbitrary older English/phone-oriented server messages.

### Before / after wording

| Surface | Before | After English | After Arabic |
| --- | --- | --- | --- |
| Verification instructions | “We sent a 4-digit verification code to” / «أرسلنا رمز التحقق المكون من 4 أرقام إلى», followed by the phone | Check your registered email for the 6-digit verification code. Look in your inbox and spam folder. | تحقق من بريدك الإلكتروني المسجل للحصول على رمز التحقق المكون من 6 أرقام. راجع البريد الوارد والبريد غير المرغوب فيه. |
| Recovery-code screen | Same generic phone destination | If a matching account exists, check its registered email for the 6-digit recovery code. Look in your inbox and spam folder. | إذا وُجد حساب مطابق، فتحقق من بريده الإلكتروني المسجل للحصول على رمز الاستعادة المكون من 6 أرقام. راجع البريد الوارد والبريد غير المرغوب فيه. |
| Forgot-password form | “via SMS or WhatsApp” / «عبر رسالة نصية أو واتساب» | Enter your registered phone number. If a matching account exists, its recovery code is sent to the registered email, not the phone. | أدخل رقم هاتفك المسجل. إذا وُجد حساب مطابق، فسيُرسل رمز الاستعادة إلى بريده الإلكتروني المسجل، وليس إلى الهاتف. |
| Resend | “A new code has been sent” / «تم إرسال كود جديد إلى هاتفك» | A new code was requested for your registered email. Check your inbox and spam folder; delivery is not confirmed. | قُبل طلب رمز جديد إلى بريدك الإلكتروني المسجل. راجع البريد الوارد والبريد غير المرغوب فيه؛ لم يتم تأكيد وصول الرسالة. |
| Recovery acknowledgment/resend | Raw server message or phone-oriented fallback | If a matching account exists, check its registered email for the recovery code. Delivery is not confirmed. | إذا وُجد حساب مطابق، فتحقق من بريده الإلكتروني المسجل للحصول على رمز الاستعادة. لم يتم تأكيد وصول الرسالة. |
| Registration acknowledgment | Raw English server text or generic OTP notice | Account created. Check your registered email for the verification code. | تم إنشاء الحساب. تحقق من بريدك الإلكتروني المسجل للحصول على رمز التحقق. |
| Development hints | Django-terminal/SMS-provider guidance; unused “1234” demo translation | Removed, without replacement. | أزيلت تلميحات التطوير والرمز التجريبي دون بديل ظاهر. |

The existing six fields now flex within narrow viewports. Their controllers, focus order, auto-verification, validation, loading and error paths remain unchanged. The unused four-digit box hint is corrected to six digits.

## Location: actual processing and manifest decision

1. `patient_location_controller.dart` allows GPS only after a signed-in patient explicitly chooses it. It checks/request foreground permission and calls Geolocator with `LocationAccuracy.low`. The returned coordinates are kept in session memory and discarded on backgrounding/account changes. Manual emirate/city selection remains available. No background permission or temporary full-accuracy escalation was added.
2. `nearby_clinics_repository.dart` sends the returned latitude/longitude doubles, radius and pagination in `GET clinics/nearby/`. It does not round or anonymize coordinates. Manual selection instead calls `home/nearby-clinics/` with actual city/emirate values and no GPS coordinates.
3. The common `AuthInterceptor` attaches the current JWT to Nearby requests. Nearby is not on its token-free authentication endpoint allowlist. Django's default `AestheticJWTAuthentication` resolves that JWT's user even though `ClinicNearbyAPIView` permits public access. Consequently these requests **can be associated with an account**; `AllowAny` does not prove anonymity. There is no pre-transmission de-identification that would justify an unlinked declaration.
4. The inspected Nearby view validates coordinates, computes proximity and returns clinics. It contains no explicit write of a patient's position or telemetry event. The client does not persist GPS to disk or analytics. This does **not** prove production proxy/access/error logs, monitoring or caches discard query coordinates after servicing the request. Their retention, access and identity correlation require Ali's written confirmation.

[Apple defines precise and coarse location by effective resolution](https://developer.apple.com/app-store/app-privacy-details/), not by the requested accuracy setting alone. Low accuracy is a request to Core Location, not a coordinate-rounding boundary. Full-accuracy OS permission can still return a precise position; Approximate Location Services can return coarse data. Both supported cases must be represented, without changing behavior to fit the declaration.

Added app-owned rows using Apple's permitted keys/enums:

| Key | Precise location | Coarse location |
| --- | --- | --- |
| `NSPrivacyCollectedDataType` | `NSPrivacyCollectedDataTypePreciseLocation` | `NSPrivacyCollectedDataTypeCoarseLocation` |
| `NSPrivacyCollectedDataTypeLinked` | `true` | `true` |
| `NSPrivacyCollectedDataTypeTracking` | `false` | `false` |
| `NSPrivacyCollectedDataTypePurposes` | `[NSPrivacyCollectedDataTypePurposeAppFunctionality]` | Same |

This is a conservative collected/linked disclosure for account-associated transmission pending production-retention confirmation, **not a finding that Django persists GPS histories**. Apple distinguishes real-time processing from data accessible beyond servicing a request. Do not use an unverified real-time-only exception or claim “not collected”/“not linked” without evidence covering infrastructure logs and vendors. If Ali proves end-to-end real-time-only handling, the publisher must reassess collection status with that evidence before changing these declarations.

Global tracking remains false; tracking domains remain empty. No source evidence was found for location-based cross-company advertising tracking. App Functionality is supported by Nearby discovery; no location analytics/advertising purpose was added. All eight pre-existing collected-data entries, purposes and accessed-API declarations remain unchanged.

`Info.plist` and its existing English/Arabic `InfoPlist.strings` now explain foreground Nearby use, approximate **or** precise coordinate transmission and the manual alternative. Existing camera/photo descriptions and foreground-only `BYPASS_PERMISSION_LOCATION_ALWAYS=1` remain. Bundle ID `com.aestheticway.aestheticWay`, iOS13 deployment target, Keychain entitlement and native locks are unchanged.

The resolved geolocator_apple2.4.3 SDK manifest has no collected-data rows; that does not describe the app's own HTTP transmission. The resolved image_picker_ios0.8.13+9, flutter_secure_storage9.2.4, package_info_plus9.0.1, url_launcher_ios6.4.1 and video_player_avfoundation2.12.0 source manifests were also inspected. None supplies this missing app location disclosure. No SDK manifest was changed; packaged/merged manifest inspection still belongs to the actual Xcode archive.

Apple references: [Manifest data-use keys](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests), [allowed data-type values](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype), [allowed purpose values](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatypepurposes). Checked 2026-11-06.

### Exact App Store Connect handoff

In **My Apps → Aesthetic Way → App Privacy → Data Types → Location**, retain existing declarations for other categories and declare **Precise Location** and **Coarse Location**. For each, select:

- **App Functionality** as the supported purpose.
- **Yes, linked to the user's identity** (the current request is account-associated).
- **No, not used for tracking**.

Do not select location Analytics, Third-Party Advertising, Developer Advertising or other purposes without new evidence. Keep collection disclosed while the claimed real-time-only retention exception is unverified. These selections and the manifest are separate from the system permission prompt and public policy; none replaces another. The publisher/owner must confirm the infrastructure facts before final App Privacy signoff.

## Public policy and release-signoff dependencies

Read-only retrieval of the supplied [Privacy Policy](https://aestheticway.ae/privacy-policy/) and [account-deletion page](https://aestheticway.ae/delete-account/) was attempted through the web tool but both pages were inaccessible. The managed execution network also excludes that host. Published text, redirects and consistency therefore remain **unverified**, not passed. No access restriction was bypassed. The pre-existing in-app legal link uses `/privacy/`; the owner must confirm it redirects to the supplied canonical policy or authorize a verified link correction. This task does not silently change an unverified web route.

Before public release, the owner/Ali/publisher must confirm that the actual policy covers optional foreground precise/coarse location, authenticated Nearby processing, manual locality, actual service providers and retention/deletion practices. It must not promise coarse-only, anonymous, device-only GPS or verified mailbox receipt if those claims are unsupported. Obtain redacted configuration evidence for proxy/Gunicorn/access/error/monitoring logs and their location-query retention; do not export tokens, real coordinates, email addresses or patient records.

**لـ Ali والناشر:** إرسال رموز التسجيل واستعادة كلمة المرور عبر البريد مثبت في المصدر ومؤكد من المالك، لكن لم نختبر تسليم رسائل إنتاجية. حذف الحساب وتغيير الهاتف لهما عقدان مستقلان؛ لا يجوز تحويلهما افتراضياً إلى البريد. طلبات العيادات القريبة تحمل إحداثيات مع جلسة مصادق عليها، لذا لا نعلن أنها مجهولة الهوية. عرض Nearby لا يحفظ سجل GPS صراحة، لكن يلزم تأكيد احتفاظ سجلات الخادم والوكيل والمراقبة قبل اعتماد استثناء المعالجة الآنية. تعذر جلب صفحتي الخصوصية والحذف؛ يلزم التحقق من النص المنشور والمسار `/privacy/` قبل النشر. لم يُعدّل Django أو التوقيع أو سلوك Nearby.

## Exact changed-file manifest

- `lib/core/localization/app_locale.dart`
- `lib/features/auth/presentation/screens/otp_screen.dart`
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `lib/features/auth/presentation/screens/register_screen.dart`
- `ios/Runner/PrivacyInfo.xcprivacy`
- `ios/Runner/Info.plist`
- `ios/Runner/en.lproj/InfoPlist.strings`
- `ios/Runner/ar.lproj/InfoPlist.strings`
- `test/otp_email_release_test.dart`
- `test/otp_auth_surfaces_test.dart`
- `test/aesthetic_way_test.dart`
- `tool/tests/test_ios_privacy_manifest.py`
- `.github/workflows/flutter-visual-regressions.yml`
- `docs/FINAL_IOS_PRIVACY_OTP_RELEASE_HANDOFF.md`

## Verification and remaining native checks

| Final local check | Result |
| --- | --- |
| Flutter3.41.5 / Dart3.11.3 analyzer | **Zero issues** |
| Full suite, `flutter test --no-pub --concurrency=2 --reporter expanded` | **1,406 passed**, zero failures |
| Focused OTP/localization/authentication-surface suite | **42 passed** |
| Existing registration, deletion and durable-email focused groups plus initial new OTP cases | **75 passed** |
| Offline Python regressions | **13 passed**, including six iOS manifest/configuration checks |
| Format verification |307 Dart files, zero changes |
| Git diff checks | Pass |
| Protected authentication, location, dependency, identifier and release files |20 files identical to main; all eight previous privacy entries preserved |
| Backend integrity |360 source hashes and supplied archive SHA256 verified |
| EN/AR × Light/Dark review |32 actual Flutter captures, 320px at160% text |
| Windows/Ubuntu CI | Exact final-head job/run evidence attached to the PR after push |

An earlier four-worker run hit the existing native-file completion helper's three-second deadline. That unchanged case passed in isolation and in the final full two-worker suite. No assertions, test deadlines, skips, media implementation or video release gates were changed to obtain a pass.

New Flutter coverage includes purpose-specific instructions in EN/AR × Light/Dark, 320px at160% text, no destination/terminal leakage, whole instruction rendering, unchanged phone/purpose requests, guarded resend/cooldown, delivery failure without false success, code retention on422 and server-acknowledged password-reset navigation. Existing registration, deletion and durable-email tests are also rerun. Render captures are actual Flutter test output using synthetic fixtures, not device proof.

No Mac/Xcode or iPhone run is claimed for this task. On the publisher's compatible Mac: use pinned Flutter3.41.5/Xcode26, frozen Bundler/CocoaPods installation, run existing native tests, compile/archive the final reviewed commit, lint the packaged app manifest and generate Xcode's aggregate privacy report. Inspect both location rows and all third-party required-reason manifests. Keep Podfile/Gemfile locks unchanged. No signing identity or signing credential needs to change for these corrections.

On iPhone, test EN/AR and Light/Dark OTP validation/resend/recovery with approved QA accounts; test both Precise Location ON and OFF, permission denial, manual selection, backgrounding and session changes. Confirm foreground-only permission text is localized, no phone/full email appears as the email-code destination, a failed resend is never shown as delivered, and Nearby still uses real server distances. Owner approval and actual mailbox/iPhone/Xcode evidence remain release-signoff steps, distinct from repository test success. Do not deploy or merge automatically.
