# Restricted Maps SDK configuration — prepared, inactive

These templates are **not loaded by the current app**. They contain no usable key. Embedded Google Maps is blocked by missing restricted SDK keys and the current iOS13 minimum. Do not copy them into native targets until the dependency/minimum-OS decision in [the readiness plan](../../docs/GOOGLE_MAPS_PRODUCTION_READINESS_PLAN.md) is explicitly accepted and tested.

- Android: supply `AW_ANDROID_MAPS_SDK_KEY` from a local/CI secret store; apply the reviewed Gradle/manifest snippets after adding the compatible SDK. Restrict the key to package `com.aestheticway.aesthetic_way` plus the real signing-certificate SHA-1 and Maps SDK for Android. A Play upload-key fingerprint is not the Play App Signing fingerprint.
- iOS: supply `AW_IOS_MAPS_SDK_KEY` via an ignored generated `.xcconfig`, reference it through Info.plist, and initialize Google Maps only in the approved SDK build. Restrict to bundle `com.aestheticway.aestheticWay` and Maps SDK for iOS.
- Use different keys for platform/environment. Client SDK keys are extractable from compiled apps; application/API restrictions are the protection. Never use `GOOGLE_PLACES_API_KEY`, service-account JSON, an unrestricted server key or signing credentials here.
- Do not print keys, include them in Dart defines/source, commit generated files or publish build logs with values. A missing key must fail an intentionally enabled map build, rather than supply `DEFAULT_API_KEY` and show a broken map. Current external-map/OSM fallbacks stay operational.
