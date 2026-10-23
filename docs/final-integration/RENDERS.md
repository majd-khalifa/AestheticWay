# Integration screen renders

Actual Flutter widget renders, 430×1000 logical pixels, fixture font ownership from `test/support/patient_visual_harness.dart`. Local disposable synthetic taxonomy/account data only. These are not production records, physical-device evidence or store listing screenshots. Patient design baselines were not changed.

| Screen | Light EN | Light AR | Dark EN | Dark AR |
|---|---|---|---|---|
| Super Admin categories | [Render](admin_categories_light_en.png) | [Render](admin_categories_light_ar.png) | [Render](admin_categories_dark_en.png) | [Render](admin_categories_dark_ar.png) |
| Super Admin request moderation | [Render](admin_category_requests_light_en.png) | [Render](admin_category_requests_light_ar.png) | [Render](admin_category_requests_dark_en.png) | [Render](admin_category_requests_dark_ar.png) |

- [Clinic requests — Light EN](clinic_category_requests_light_en.png)
- [Deletion challenge/error — Light EN](account_deletion_light_en.png)

Reviewed against the existing portal theme. Category management is intentionally operational; no patient-design overhaul, generated photographs or fictional production content were introduced. EN/AR text, themed contrast, RTL alignment, moderation controls and readable localized error feedback were inspected.

Reproduce:

```bash
flutter test test/final_integration_contract_test.dart --timeout 60s --reporter expanded \
  --dart-define=FINAL_INTEGRATION_CAPTURE_DIR=/absolute/path/outside/repository
```

Native Windows captures also passed and were visually reviewed (Arabic Dark categories and deletion error state): [Windows artifact](https://github.com/majd-khalifa/AestheticWay/actions/runs/39955100633/artifacts/12501219972), 14-day retention. The regular committed renders above remain permanent local Flutter evidence.
