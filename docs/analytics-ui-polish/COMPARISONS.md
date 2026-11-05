# Flutter-rendered comparisons

Before: production UI at88537f8. After: the presentation polish. The same synthetic fixtures, fonts and logical viewports are used for each pair. These are actual Flutter renders, not physical-device captures. V2 viewport390×844; Legacy430×1100. Additional responsive/long-page evidence follows.

<details><summary>V2 overview</summary>

| Mode | Before | After |
| --- | --- | --- |
| English · Light | [![Before](before/v2_light_en_overview.png)](before/v2_light_en_overview.png) | [![After](after/v2_light_en_overview.png)](after/v2_light_en_overview.png) |
| English · Dark | [![Before](before/v2_dark_en_overview.png)](before/v2_dark_en_overview.png) | [![After](after/v2_dark_en_overview.png)](after/v2_dark_en_overview.png) |
| العربية · فاتح | [![Before](before/v2_light_ar_overview.png)](before/v2_light_ar_overview.png) | [![After](after/v2_light_ar_overview.png)](after/v2_light_ar_overview.png) |
| العربية · داكن | [![Before](before/v2_dark_ar_overview.png)](before/v2_dark_ar_overview.png) | [![After](after/v2_dark_ar_overview.png)](after/v2_dark_ar_overview.png) |

</details>

<details><summary>Selected clinic</summary>

| Mode | Before | After |
| --- | --- | --- |
| English · Light | [![Before](before/v2_light_en_clinic.png)](before/v2_light_en_clinic.png) | [![After](after/v2_light_en_clinic.png)](after/v2_light_en_clinic.png) |
| English · Dark | [![Before](before/v2_dark_en_clinic.png)](before/v2_dark_en_clinic.png) | [![After](after/v2_dark_en_clinic.png)](after/v2_dark_en_clinic.png) |
| العربية · فاتح | [![Before](before/v2_light_ar_clinic.png)](before/v2_light_ar_clinic.png) | [![After](after/v2_light_ar_clinic.png)](after/v2_light_ar_clinic.png) |
| العربية · داكن | [![Before](before/v2_dark_ar_clinic.png)](before/v2_dark_ar_clinic.png) | [![After](after/v2_dark_ar_clinic.png)](after/v2_dark_ar_clinic.png) |

</details>

<details><summary>Expanded daily records</summary>

| Mode | Before | After |
| --- | --- | --- |
| English · Light | [![Before](before/v2_light_en_daily.png)](before/v2_light_en_daily.png) | [![After](after/v2_light_en_daily.png)](after/v2_light_en_daily.png) |
| English · Dark | [![Before](before/v2_dark_en_daily.png)](before/v2_dark_en_daily.png) | [![After](after/v2_dark_en_daily.png)](after/v2_dark_en_daily.png) |
| العربية · فاتح | [![Before](before/v2_light_ar_daily.png)](before/v2_light_ar_daily.png) | [![After](after/v2_light_ar_daily.png)](after/v2_light_ar_daily.png) |
| العربية · داكن | [![Before](before/v2_dark_ar_daily.png)](before/v2_dark_ar_daily.png) | [![After](after/v2_dark_ar_daily.png)](after/v2_dark_ar_daily.png) |

</details>

<details><summary>Complete zero</summary>

| Mode | Before | After |
| --- | --- | --- |
| English · Light | [![Before](before/v2_light_en_zero.png)](before/v2_light_en_zero.png) | [![After](after/v2_light_en_zero.png)](after/v2_light_en_zero.png) |
| English · Dark | [![Before](before/v2_dark_en_zero.png)](before/v2_dark_en_zero.png) | [![After](after/v2_dark_en_zero.png)](after/v2_dark_en_zero.png) |
| العربية · فاتح | [![Before](before/v2_light_ar_zero.png)](before/v2_light_ar_zero.png) | [![After](after/v2_light_ar_zero.png)](after/v2_light_ar_zero.png) |
| العربية · داكن | [![Before](before/v2_dark_ar_zero.png)](before/v2_dark_ar_zero.png) | [![After](after/v2_dark_ar_zero.png)](after/v2_dark_ar_zero.png) |

</details>

<details><summary>Unavailable canonical counts</summary>

| Mode | Before | After |
| --- | --- | --- |
| English · Light | [![Before](before/v2_light_en_unavailable.png)](before/v2_light_en_unavailable.png) | [![After](after/v2_light_en_unavailable.png)](after/v2_light_en_unavailable.png) |
| English · Dark | [![Before](before/v2_dark_en_unavailable.png)](before/v2_dark_en_unavailable.png) | [![After](after/v2_dark_en_unavailable.png)](after/v2_dark_en_unavailable.png) |
| العربية · فاتح | [![Before](before/v2_light_ar_unavailable.png)](before/v2_light_ar_unavailable.png) | [![After](after/v2_light_ar_unavailable.png)](after/v2_light_ar_unavailable.png) |
| العربية · داكن | [![Before](before/v2_dark_ar_unavailable.png)](before/v2_dark_ar_unavailable.png) | [![After](after/v2_dark_ar_unavailable.png)](after/v2_dark_ar_unavailable.png) |

</details>

<details><summary>Legacy overview</summary>

| Mode | Before | After |
| --- | --- | --- |
| English · Light | [![Before](before/analytics_light_en_top.png)](before/analytics_light_en_top.png) | [![After](after/analytics_light_en_top.png)](after/analytics_light_en_top.png) |
| English · Dark | [![Before](before/analytics_dark_en_top.png)](before/analytics_dark_en_top.png) | [![After](after/analytics_dark_en_top.png)](after/analytics_dark_en_top.png) |
| العربية · فاتح | [![Before](before/analytics_light_ar_top.png)](before/analytics_light_ar_top.png) | [![After](after/analytics_light_ar_top.png)](after/analytics_light_ar_top.png) |
| العربية · داكن | [![Before](before/analytics_dark_ar_top.png)](before/analytics_dark_ar_top.png) | [![After](after/analytics_dark_ar_top.png)](after/analytics_dark_ar_top.png) |

</details>

## Additional acceptance evidence

The sparse long-page input contains32 dates, a real gap in that synthetic response, and observed7/trusted3 under unavailable coverage. The UI shows only the returned dates and does not convert canonical null to zero.

- [English · Light · long daily page](after/long_daily_light_en.png)
- [English · Dark · long daily page](after/long_daily_dark_en.png)
- [العربية · فاتح · long daily page](after/long_daily_light_ar.png)
- [العربية · داكن · long daily page](after/long_daily_dark_ar.png)
- [Arabic Light ·320px/160%](after/layout_320_light_ar.png)
- [Arabic Dark ·320px/160%](after/layout_320_dark_ar.png)
- [English Light ·1024px tablet](after/layout_1024_light_en.png)
- [Arabic Dark ·1024px tablet](after/layout_1024_dark_ar.png)
