# Google Maps production readiness

2026-10-25 · PR13 · pinned Flutter3.41.5/Dart3.11.3 · Android minimum24, compile/target36 · iOS minimum13.0. **Embedded Maps is not enabled.** This plan prepares integration without changing minimum OS, production signing, dependencies or credentials.

## Independently checked compatibility

Public pub.dev metadata/native package sources were inspected and a separate disposable project resolved the following exact set successfully with the pinned Flutter SDK. The application's own pubspec/lockfile were not changed.

| Component | Resolved candidate | Verified requirement / result |
|---|---|---|
| `google_maps_flutter` |2.18.1|Dart^3.10, Flutter≥3.38; fits3.11.3/3.41.5. Latest2.19.0 requires newer Dart/Flutter and is not selected.|
| Android implementation |2.19.10|minSdk24; native `play-services-maps:20.0.0`; fits existing min24/compile36. Metadata/resolution only; SDK not compiled into this app.|
| Maintained iOS SDK10 implementation |`google_maps_flutter_ios_sdk10:2.19.0`|Dart^3.11/Flutter≥3.41; GoogleMaps~>10.0; **iOS16 minimum**. Actual resolved Flutter plugin registration selects SDK10 rather than the legacy default.|
| Maintained iOS SDK9 alternative |`google_maps_flutter_ios_sdk9:2.19.0`|Same Flutter/Dart fit; **iOS15 minimum**, GoogleMaps9.x. Requires explicit support/decommissioning review before selecting this older native major.|
| Legacy default iOS implementation |2.18.7|Maintainer marks it as not receiving future feature updates. It is not the recommended new production path.|

**There is no current production-supported dual-platform configuration here that preserves iOS13.** Do not pin an obsolete SDK merely to hide that conflict. Product/release owners must explicitly choose whether to retain13 with the existing external-map fallback, or approve a supported minimum-OS migration (SDK10/iOS16 recommended for assessment; SDK9/iOS15 is a separate reviewed alternative). No decision was silently made in code. A successful Dart package resolution is not an Xcode/SDK build or a working map.

[Machine-readable inspected metadata](physical-qa-remediation/maps-sdk-assessment.json) includes the exact candidate dependency/native requirements and isolated-resolution result.

## Credentials and prepared configuration

The [configuration templates](../config/maps/README.md) are inactive, contain no key and are not loaded by native build targets. They provide:

- Android Gradle environment-provider and manifest fragments for `AW_ANDROID_MAPS_SDK_KEY`. An intentionally enabled SDK build must reject missing configuration. No debug-signing fallback or signing-block modification.
- iOS ignored local xcconfig → Info.plist substitution → AppDelegate initialization, retaining current implicit-engine plugin registration and startup ordering. The SDK is configured only in the approved dependency target.
- `.gitignore` excludes actual local SDK configuration. Real keys are supplied through local/CI secure configuration, never substituted into committed examples or logs.

Use a separate Android key restricted to package **com.aestheticway.aesthetic_way**, the actual distribution **Play App Signing** certificate SHA-1 (separate development key/certificate as required), and **Maps SDK for Android** only. The upload-key certificate is not automatically the Play signing certificate. Use a separate iOS key restricted to **com.aestheticway.aestheticWay** and **Maps SDK for iOS** only. Separate development/staging/production projects or keys; set billing/quota alerts. SDK keys are extractable from compiled apps, so application/API restrictions matter even when build-time injection is used. No unrestricted fallback key.

The private server `GOOGLE_PLACES_API_KEY` remains server-side, restricted to Places API(New) and server egress as supported. It must never enter Dart, manifests, IPA/APK assets, Git or client logs. Autocomplete and terminal Details use the same backend project/session;350ms debounce and minimum field masks control requests. Do not promise free usage: billing depends on the current Google session/SKU policy and configured project.

## Map behavior to implement after approval/keys

1. **Clinic Business selection:** keep the working authenticated backend autocomplete/details/proof/CAS workflow. Inject a genuine bounded GoogleMap into `GoogleBusinessScreen.mapBuilder`, centered only on the exact selected Details coordinates/Place ID. Keep the explicit identity checkbox. `linked_verified_place` verifies selected-place data, not Business Profile ownership. No Places result on OSM.
2. **Manual pin:** independent model/state and explicit pin confirmation. Do not write `google_place_id` or `google_maps_url` when editing manual coordinates. Never auto-save a default city/emirate center. Preserve separate OSM/manual fallback until a keyed renderer is actually verified.
3. **Patient clinic map:** only source-confirmed public clinic/branch data; no private admin/subscription metadata, guessed coordinates or invented clinic markers. A fixed marker needs no patient GPS permission. External navigation remains available on genuine coordinates/Place ID.
4. **Nearby map/list:** keep disabled until the backend public-approval fix is supplied and verified. Then preserve server kilometre ordering, radius, all eligible tiers, clinic deduplication and closest valid branch across pages. A `nearest_branch_id` without confirmed branch coordinates must not point to HQ. No additional undocumented lookup or sixth tab.
5. **Lifecycle/performance:** lazy-create map surfaces on the active route/tab, dispose controllers/subscriptions, avoid eager maps in photograph cards, preserve Arabic directionality without mirroring geographic coordinates. Show loading/offline/auth/config failures and a safe external-navigation fallback. Do not claim “working map” from a blank tile surface.
6. **Attribution/privacy:** retain visible Google Maps attribution and any actual provider attribution; ensure insets/RTL/controls do not cover it. Use approved Google basemap styling or platform map scheme for Light/Dark. Keep public app Terms/Privacy aligned with Maps/Places usage; store only permitted data and retain Place ID as identity. No client prefetch/cache of Places photos/reviews.

## Required enablement verification

- Resolve/pin the chosen set in a reviewed app branch, inspect Podfile.lock/native SDK privacy manifests, and run real Android release/iOS release builds on the approved minimum/SDK versions. No claim that this plan's SDK candidates were compiled into the current app.
- Validate keys on signed Android debug/release and actual Play App Signing builds, and iOS debug/distribution bundles. Check missing/wrong restriction errors without printing key values. No need to share private keys, passwords or signing material in QA logs.
- Physical Android/iOS: render actual tiles, exact selected business marker, independent manual pin, external navigation, rotation/RTL/Light/Dark, background/resume, denied/revoked location and correct nearest branch after its backend contract is fixed.
- Regression: existing image/video, portal/security/consultation/localization/privacy/pagination tests remain green. Fixture map-builder tests are not physical SDK verification.

Sources checked2026-10-25: [Flutter configuration](https://developers.google.com/maps/flutter-package/config), [official OS/software support](https://developers.google.com/maps/software-support), [wrapper2.18.1](https://pub.dev/packages/google_maps_flutter/versions/2.18.1), [Android2.19.10](https://pub.dev/packages/google_maps_flutter_android/versions/2.19.10), [maintained iOS SDK10](https://pub.dev/packages/google_maps_flutter_ios_sdk10/versions/2.19.0), [iOS SDK9](https://pub.dev/packages/google_maps_flutter_ios_sdk9/versions/2.19.0), [legacy iOS maintenance notice](https://pub.dev/packages/google_maps_flutter_ios/changelog), [key security](https://developers.google.com/maps/api-security-best-practices), [Places policy](https://developers.google.com/maps/documentation/places/web-service/policies).
