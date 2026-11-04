# Super Admin Analytics — presentation polish

Date: 2026-11-05 (Asia/Damascus). Branch: `codex/super-admin-analytics-luxury-polish`.

Verified main baseline: `88537f88dce71844c1a24682daa661f1052887e4`, including merged PR17 and PR18. The working tree was clean at intake. The environment restart preserved this branch and all edits.

This task changes Super Admin presentation only. Analytics models, repositories, controller, service calculations, endpoints, permissions, authentication, Patient/Clinic Portal design and native/release configuration remain unchanged. Both `AW_ENABLE_PATIENT_ANALYTICS` and `AW_ENABLE_CLINIC_SHOWCASE_VIDEO_UPLOAD` retain their disabled defaults. No production event submission, live data modification, backend operation, application build/publication or merge occurred.

## What changed

| Surface | Presentation change | Implementation |
| --- | --- | --- |
| V2 overview | One period header; restrained search/filter card; archived option collapsed with a visible active-filter description; compact platform summary; no prominent clinic UUIDs | `analytics_v2_panel.dart` |
| Clinic selection | Tapping a clinic opens its report immediately in a bounded, scrollable sheet. Clinic name and period stay visible. Close/back returns to the retained directory, without a new list request | `analytics_v2_panel.dart` |
| Selected-clinic KPIs | Two columns on ordinary phones, up to five on tablets. Wide/single-column tiles align the number with the label. No repeated decorative icons | `analytics_presentation.dart` |
| Metric interpretation | Short Complete/Partial/Unavailable badges; canonical values remain separate from Observed and Trusted/Saved. Full definitions live in one accessible help sheet | `analytics_presentation.dart` |
| Daily reports | Collapsed by default. Select among the dates actually returned on the current server page; inspect all five canonical/observed/trusted values for that date. Server Previous/Next controls remain | `_DailyReport` in `analytics_v2_panel.dart` |
| Legacy records | Compact KPIs, one coverage warning, nearby operational clinic selection, grouped daily/top-clinic sections and unchanged lifetime referral information | `admin_analytics_screen.dart` |
| V2/Legacy tabs | Short, localized labels, inherited app typography, responsive touch targets and retained LazyTabStack state | `admin_analytics_screen.dart` |

Technical clinic IDs remain available in an explicit Clinic record details disclosure and exact-UUID server search. They are no longer the main subtitle of every directory card. Clinic operational inspection, period-filtered consultation drill-down, top-clinic preview/See All, date reset, referral loading/errors and retry controls remain available.

The sheet uses the existing session snapshot to clear private identity/content after an account switch; the controller's response revisions and role guards are unchanged. Live locale changes update the report labels without another analytics fetch. The separate Legacy source warnings remain explicit: recorded zero does not establish complete collection, and all-time clinic/referral records are not selected-period analytics.

## Accuracy and scope checks

- `counts` and `total_events` are displayed as returned by the existing model: null remains **—**, genuine complete zero remains **0**. Coverage badges use the existing enum directly.
- `recorded_counts`, `trusted_recorded_counts`, `recorded_total_events` and platform app-open fields remain distinct. Saved consultations still come from the existing saved-lead contract. No extra sum, unique-user estimate, rate, trend or growth percentage was added.
- Daily date options come exclusively from `detail.days`; the frontend creates no missing dates and filters out no returned date. Pagination continues to use `seriesPage`, `seriesPageSize`, `dayCount` and the existing controller's `select` method. A date's observed activity remains inspectable even when its canonical count is unavailable.
- Search, archived inclusion, directory pagination and Dubai UTC+4 period boundaries use the same query/repository code. Tab switching retains the V2 search/report state and keeps Legacy operational collections separate.
- No global admin theme/component was restyled. New shared UI helpers apply only to Analytics. No patient screen, image/video handling, consultation rule, phone/authentication flow, dependency or release-signing file changed.

## Rendered review

The latest message contained no new image attachments. Available historical device context and the reported scrolling/readability problems informed the review; no claim is made that a new device screenshot set was inspected.

Actual Flutter before/after renders use the same synthetic source-derived fixture data and pinned Flutter/font harness. The before captures use unmodified production UI at the baseline commit. No generated photographs or fabricated live metrics were introduced. The additional long-page test supplies a clearly synthetic 32-date response, with a gap and nonzero observed data under unavailable coverage, to verify presentation; its dates exist only in test input.

See [before/after comparisons](analytics-ui-polish/COMPARISONS.md), [verification/protected-file hashes](analytics-ui-polish/verification.json) and [exact changed-file manifest](analytics-ui-polish/CHANGED_FILES.txt). Render PNGs in the manifest are intentional review evidence, not production assets or build output.

Review covers English/Arabic, Light/Dark, clinic details, expanded daily records, complete zero, unavailable coverage and Legacy. Additional renders/tests cover 320px at160% text and1024px tablets. At large text scale, full labels use more vertical space and tiles switch to one column; this preserves readability without clipping. Dates remain LTR within RTL layouts. All new controls use standard accessible Flutter controls and existing app colors.

No existing patient golden baseline or comparison threshold was changed. Widget assertions verify actual values, server requests, selected-date contents, zero/null distinction, session changes, loading/error/retry/empty states and responsive layouts. Final analyzer/full-suite/native CI results accompany this report and the Draft PR.

## Remaining acceptance

No new backend contract or release blocker was identified by this presentation task. Owner approval of the new UI on a physical device remains a separate acceptance step; native Windows/Ubuntu tests and synthetic renders do not establish Android/iOS device verification. Existing production telemetry/video-upload gates and their prior release dependencies remain unchanged. No fresh analytics integration, video investigation or backend deployment audit was performed.

**عربي:** هذا التغيير لتحسين عرض تحليلات المشرف العام فقط. بقيت عقود البيانات والحسابات والصلاحيات وحدود الفترة والترقيم كما هي. القيم غير المتاحة تبقى «—» والصفر الحقيقي يبقى0، مع فصل المرصود عن الموثوق والمحـفوظ. لا ينشئ العرض تواريخ أو اتجاهات أو نسباً، ولا يخفي بيانات يوم وارد من الخادم. بقي علما إرسال الأحداث ورفع الفيديو معطلين افتراضياً. صور المقارنة رُسمت فعلياً بواسطة Flutter ببيانات اختبار اصطناعية؛ لم تُرسل بيانات للإنتاج ولم يُعدّل Django أو توقيع التطبيق. تبقى المراجعة البصرية على الجهاز خطوة قبول منفصلة.


## Final local verification

| Check | Result |
| --- | --- |
| Flutter3.41.5 / Dart3.11.3 analyzer | **Zero issues** |
| `dart format --output=none --set-exit-if-changed .` |305 files, zero changes |
| Full suite, `flutter test --no-pub --concurrency=2 --reporter expanded` | **1,364 passed, zero failures** |
| Final focused presentation/Legacy capture suite | **41 passed**, including17 new presentation cases |
| Live language change | Regression reproduced before the fix and passed after; no extra metrics request |
| Existing data/auth/config/dependency files |14 protected Git blobs identical to the baseline |
| `git diff --check` | Pass |
| Before/after review assets |56 intentional PNGs; same-fixture comparisons plus sparse/large-text/tablet evidence |
| Windows/Ubuntu CI | Exact final-commit job/run evidence is attached to the Draft PR after push |

Only three production Dart files change, all under Super Admin presentation. The remaining code changes are two test files and the focused test/capture workflow. The manifest also includes this report, comparison index, verification summary and the intentionally captured review images.
