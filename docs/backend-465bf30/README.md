# Source465bf30 integration evidence

See [the report and current bilingual handoff](../BACKEND_465BF30_INTEGRATION_REPORT.md).

- `verification.json`: archive/source provenance, local suite and genuine-media decode evidence.
- `source-evidence.json`:44 redacted isolated API observations; mocked providers, disposable local storage. No production delivery claim.
- `CHANGED_FILES.txt`: exact frontend-repository file manifest relative to3bb882b.
- Screenshots below are actual Flutter renders using disposable fixtures/neutral branded placeholders. They are **not** production clinic photographs, Google responses or device QA. All prior approved artwork is unchanged.

| State | English Light | Arabic Light | English Dark | Arabic Dark |
|---|---|---|---|---|
| Enabled Nearby list | [Render](nearby_enabled_light_en.png) | [Render](nearby_enabled_light_ar.png) | [Render](nearby_enabled_dark_en.png) | [Render](nearby_enabled_dark_ar.png) |
| Confirmed map choices, external navigation | [Render](nearby_map_choices_light_en.png) | [Render](nearby_map_choices_light_ar.png) | [Render](nearby_map_choices_dark_en.png) | [Render](nearby_map_choices_dark_ar.png) |

Regenerate with `flutter test test/backend_465bf30_integration_test.dart --dart-define=ONBOARDING_REVIEW_CAPTURE_DIR=<absolute-output-directory>`.

Source probe: `python tool/audit_backend_465bf30_contract.py --backend-root <read-only-extracted-backend465bf30> --output <outside-backend>/source-evidence.json`. Uses an isolated in-memory database and temporary storage, mocks providers, disables bytecode writes and verifies every source hash. Requires the backend test dependencies. It never contacts production.
