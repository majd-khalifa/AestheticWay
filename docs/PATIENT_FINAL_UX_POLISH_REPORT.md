# Final Patient UX polish, placeholders and saved preferences

Existing branch: `codex/patient-luxury-design-reference-lock`. Existing [PR #10](https://github.com/majd-khalifa/AestheticWay/pull/10), targeting `main`. Baseline: `a5ec85d3e189110800e9da1385f7f4df02aed59a`. No new PR or automatic merge.

## Delivered behavior

The current request explicitly replaces the preceding compact missing-media policy. Patient cards and details now retain the same photographic frame for genuine, missing and failed media. A shared, neutral AESTHETIC WAY panel uses the approved navy/champagne palette, an AW monogram and fine linework. It contains no stock content, invented clinic photography or invented metadata. Light/dark styles and localized image-unavailable semantics are deliberate.

`PatientImage` wraps the existing `LuxuryImage` with this patient-only fallback. Actual source/provider priority, native file/URI support, media cache keys, physical decode bounds and network error handling remain intact. Missing portraits do not become clinic logos. Clinic/Admin upload previews and the shared production image resolver remain unchanged. Product packshots still use `BoxFit.contain`, with their existing decode budget and frame proportions.

Coverage includes Featured carousel/Home cards, clinic directory, profile gallery/hero and logos, staff/portraits, treatment cards/list thumbnails/detail hero, product cards/detail hero/inquiry thumbnail, offers, articles/detail/author thumbnails, and consultation context thumbnails. Split cards select layout by width and text scale, not media presence. Empty galleries retain the real gallery's 16:9 hero without fake thumbnails or counts. Intrinsic staff/offer rows have explicit starting image heights so source image dimensions cannot enlarge a card unexpectedly.

## Preferences: actual gap and fix

English and Light were already the declared defaults; startup already awaited storage restoration before `runApp`. Those correct behaviors remain. The actual gaps were unsequenced writes during rapid changes and swallowed device-write errors. A reusable preference state now serializes durable writes, prevents a late startup read from replacing an in-session choice, and exposes saving/failure state. Profile shows localized progress and an explicit Retry if a device write fails, rather than silently implying persistence.

Existing secure-storage keys `aw_pref_locale` and `aw_pref_theme_mode`, Android encrypted-store options and iOS keychain accessibility remain unchanged. A cold instance restores English/Arabic and Light/Dark/System. Empty or invalid values yield English/Light even if the host is dark. Logout continues deleting auth keys only. No dependency, auth, signing or startup-route changes were needed. Force-killing the process before the OS completes a write cannot be promised durable; progress remains visible until completion. Native device/keychain lifecycle verification remains separate from mocked storage regression coverage.

## Consultation rejection and My Requests

The single inline rejection panel now uses calmer English/Arabic copy. A possible duplicate is described as a rejection, never evidence that a previous request exists. A throttle says the current form is unchanged. Actual server wait metadata remains distinguished from the client's local backpressure estimate. There is no concurrent toast, automatic POST retry, fake success or optimistic history entry.

Regression tests exercise one POST for repeated taps, intact name/phone/dial code/notes/consent and selections after rejection, unchanged retry payload, recovery to My Requests and normal back to the retained form. The existing submit spinner, session/disposal guards, success snapshot and exact Arabic success message `تم إرسال طلبك وستتواصل العيادة معك` remain.

My Requests is verified against the read-only ca15dc6 contract and an intercepted repository response, not a live account:

- `GET /api/v1/leads/my/?page=1&page_size=20` is authenticated and account-owned. No client-supplied patient/account selector. Subsequent pages remain bounded and deduplicated.
- Sent/Contacted/Closed filters send `status=new/contacted/closed` immediately. Re-selecting the active filter now avoids a redundant GET. Pull-to-refresh remains available.
- Server reference, timestamp and known status are required; localized clinic/service/practitioner summaries map without invented rows, dates, totals or branches.
- Every history route open loads afresh. An acknowledged successful POST notifies mounted history; a rejected POST does not invent a row or trigger a background history fetch on every attempt. Opening the explicit recovery route fetches fresh history when requested.
- Empty/filter-empty/error states remain distinct. Failed next-page loads retain prior rows and explicit retry; normal back returns to the source route. Profile, success and rejection recovery all expose My Requests.

No new parser defect or wrong history endpoint was found in the current branch. A genuinely empty or throttled server response must be investigated server-side; it is not replaced with synthetic frontend data.

## Remaining backend dependencies / الاعتماديات المتبقية

All **390** supplied ca15dc6 snapshot files remain byte-for-byte unchanged. These are source findings, not confirmation of the current live deployment:

| Dependency | Evidence and required follow-up | العربية |
| --- | --- | --- |
| Duplicate rejection | Source uses a 30-second account/clinic/name/treatment-or-service predicate; practitioner/branch do not distinguish it. Cache-lock failure is not proof of a saved row. Ali should review the predicate and return explicit safe rejection/retry metadata. | مراجعة شرط التكرار ورسالة الرفض ومدة الانتظار على الخادم؛ الرفض ليس إثباتاً لحفظ طلب سابق. |
| Shared throttle history | Source LeadCreationThrottle checks 10/hour while inheriting DRF `user` cache scope, sharing history with default authenticated operations. Existing bilingual handoff proposes a separate lead scope while retaining protection. Flutter does not relax or bypass it. | فصل نطاق عدّ طلبات الاستشارة عن التصفح مع الإبقاء على الحماية؛ لا يوجد تجاوز من التطبيق. |
| Production media/history/Google delivery | Live authenticated history, uploaded-object availability, deployed revision and Google provenance remain unverified. Runtime policy prevents access to aestheticway.ae; fixture renders prove layout/decoding only. Capture sanitized evidence on the real device/server. | يلزم تحقق فعلي من الاستجابة والوسائط وبيانات Google؛ الصور التجريبية ليست إثباتاً للإنتاج. |
| Google/cache consistency | Earlier ca15dc6 review found retained rating aggregates after Place ID removal and unmatched Home cache invalidation keys. The Flutter Place-ID guard remains active. Confirm whether newer deployed server code resolves these findings. | التحقق من مسح التجميعات وتحديث الذاكرة المؤقتة في النسخة المنشورة؛ حارس Place ID محفوظ في Flutter. |

See [lead cooldown predicates and proposed Django follow-up](LEAD_COOLDOWN_REVIEW_FOR_ALI.md) and [bilingual Google/media handoff with safe PowerShell capture](PATIENT_ANDROID_QA_HANDOFF_FOR_ALI.md). No backend changes are required merely to display the neutral fallback or persist local settings. Source-reported server limitations must not be represented as newly verified live failures.

## Render review and regression validation

[102 before / 102 after Flutter frames, 12 request-flow captures and 36 comparison boards](patient-final-polish/README.md) show retained media geometry, decoded fixture photos, Light/Dark and representative Arabic RTL. The capture manifest records actual library and harness SHA-256 values. These Linux-hosted Android-target renders do not establish physical Android/iOS or production-content correctness. Existing reference mapping and photos remain visual references/test fixtures only.

New regression coverage includes cold restoration and root first frame, fresh defaults under a dark host, logout preference retention, write ordering, delayed-read races, visible storage failure/retry, decoded image pixels, exact frame/card geometry, corrupt-file fallback and semantic language refresh. Existing image/provider/fallback, responsive, security, performance, Clinic and Super Admin tests remain. Full suite: **630 passing** locally; analyzer: **zero issues**. Media render matrix: **78 passing**; focused request QA: **31 passing**. Format and diff checks are clean.

An intentional new `patient_placeholders_v3` golden family owns the new missing-gallery frame. Historical baselines remain unchanged; native Linux/Windows exact rasters and shared 1/16dp geometry continue to detect regressions. See [golden provenance](../test/goldens/patient_placeholders_v3/provenance.json) for native capture/adoption evidence. Native Ubuntu CI run39732045569 passed630 full tests,184 focused tests and analysis0 for the implementation commit. Native Windows candidate capture passed8; all four images were reviewed and their geometry/style records exactly matched the Linux shared baseline before adoption. Its first focused run had176 passes and8 missing new-family baseline failures, not production regressions or a claimed full Windows pass. Final PR-head native CI is reported in the delivery and PR checks. [Native review images](patient-final-polish/README.md#native-golden-review) preserve the evidence.

Clinic/Super Admin, JWT, pagination/backpressure, real media and Google field mapping, internal commercial-placement entitlements and five patient navigation tabs are preserved. No fabricated reviews/metadata, new commerce/scheduling, Django edits, dependency upgrades, release-signing changes or spam-protection bypass.

## Exact Flutter source files changed

- [`lib/core/localization/app_locale.dart`](../lib/core/localization/app_locale.dart)
- [`lib/core/preferences/persistent_preference.dart`](../lib/core/preferences/persistent_preference.dart)
- [`lib/core/theme/theme_service.dart`](../lib/core/theme/theme_service.dart)
- [`lib/core/widgets/patient_image.dart`](../lib/core/widgets/patient_image.dart)
- [`lib/core/widgets/patient_media_banner.dart`](../lib/core/widgets/patient_media_banner.dart)
- [`lib/core/widgets/patient_media_placeholder.dart`](../lib/core/widgets/patient_media_placeholder.dart)
- [`lib/core/widgets/preference_save_status.dart`](../lib/core/widgets/preference_save_status.dart)
- [`lib/features/appointment_lead/presentation/screens/appointment_request_screen.dart`](../lib/features/appointment_lead/presentation/screens/appointment_request_screen.dart)
- [`lib/features/appointment_lead/presentation/screens/my_requests_screen.dart`](../lib/features/appointment_lead/presentation/screens/my_requests_screen.dart)
- [`lib/features/appointment_lead/presentation/widgets/lead_rejection_notice.dart`](../lib/features/appointment_lead/presentation/widgets/lead_rejection_notice.dart)
- [`lib/features/articles/presentation/screens/article_detail_screen.dart`](../lib/features/articles/presentation/screens/article_detail_screen.dart)
- [`lib/features/clinics/presentation/screens/clinic_profile_screen.dart`](../lib/features/clinics/presentation/screens/clinic_profile_screen.dart)
- [`lib/features/clinics/presentation/widgets/patient_clinic_card.dart`](../lib/features/clinics/presentation/widgets/patient_clinic_card.dart)
- [`lib/features/clinics/presentation/widgets/patient_clinic_gallery.dart`](../lib/features/clinics/presentation/widgets/patient_clinic_gallery.dart)
- [`lib/features/offers/presentation/widgets/patient_offer_card.dart`](../lib/features/offers/presentation/widgets/patient_offer_card.dart)
- [`lib/features/practitioners/presentation/screens/practitioner_profile_screen.dart`](../lib/features/practitioners/presentation/screens/practitioner_profile_screen.dart)
- [`lib/features/practitioners/presentation/widgets/patient_practitioner_card.dart`](../lib/features/practitioners/presentation/widgets/patient_practitioner_card.dart)
- [`lib/features/products/presentation/screens/products_screen.dart`](../lib/features/products/presentation/screens/products_screen.dart)
- [`lib/features/products/presentation/widgets/brand_product_media.dart`](../lib/features/products/presentation/widgets/brand_product_media.dart)
- [`lib/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart`](../lib/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart)
- [`lib/features/profile/presentation/screens/profile_screen.dart`](../lib/features/profile/presentation/screens/profile_screen.dart)
- [`lib/features/treatments/presentation/screens/treatment_detail_screen.dart`](../lib/features/treatments/presentation/screens/treatment_detail_screen.dart)
- [`lib/features/treatments/presentation/screens/treatments_screen.dart`](../lib/features/treatments/presentation/screens/treatments_screen.dart)

Test changes: `test/patient_final_polish_test.dart` (22 new cases), `test/patient_android_qa_test.dart`, `test/patient_visual_recovery_test.dart`, `test/patient_design_lock_test.dart`, `test/media_interaction_polish_test.dart`, `test/offer_lead_and_dropdown_safety_test.dart`, `test/patient_portal_visual_test.dart`, and `test/support/clinic_golden_geometry.dart`. The visual tests now explicitly mock secure storage before changing settings; scrolling reaches lazily built clinic tabs after the intentionally taller gallery. Assertions and timeouts remain intact.
