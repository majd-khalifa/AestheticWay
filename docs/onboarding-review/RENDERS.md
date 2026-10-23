# Actual Flutter renders — review workflows

These PNGs were rendered by Flutter3.41.5 widget tests with Android presentation, real Roboto/Cairo fonts, explicit disposable fixture responses and real local image decoding. They are **not physical Android screenshots, production API evidence or store screenshots**. Neutral QA names/data are fixtures only. No Patient goldens/artwork or approved Patient geometry changed.

Inspected the Dashboard quick actions, bilingual submitted inbox, review detail, clinic setup states, eligible/ineligible video controls and narrow five-tab navigation. English/Arabic and Light/Dark examples are included. Setup/card renders intentionally isolate the component. Detail captures show the initial viewport; tests scroll to and execute the approval control as well. Video preview uses the existing test platform for lifecycle: no physical codec claim.

Reproduce:

```sh
flutter test test/onboarding_review_workflows_test.dart \
  --dart-define=ONBOARDING_REVIEW_CAPTURE_DIR=/absolute/output/path
flutter test test/clinic_media_contract_test.dart \
  --dart-define=CLINIC_AUDIT_CAPTURE_DIR=/absolute/output/path
```

Native Ubuntu/Windows CI publishes the same captures as review artifacts. Existing gallery/video capture matrix remains in `../clinic-portal-audit/` where available, and the native CI artifact's `clinic-portal-audit` directory. No blind golden regeneration or relaxed thresholds.

| View | Render |
|---|---|
| admin navigation narrow dark ar | [admin_navigation_narrow_dark_ar.png](admin_navigation_narrow_dark_ar.png) |
| admin navigation narrow light en | [admin_navigation_narrow_light_en.png](admin_navigation_narrow_light_en.png) |
| admin review dashboard dark ar | [admin_review_dashboard_dark_ar.png](admin_review_dashboard_dark_ar.png) |
| admin review dashboard dark en | [admin_review_dashboard_dark_en.png](admin_review_dashboard_dark_en.png) |
| admin review dashboard light ar | [admin_review_dashboard_light_ar.png](admin_review_dashboard_light_ar.png) |
| admin review dashboard light en | [admin_review_dashboard_light_en.png](admin_review_dashboard_light_en.png) |
| clinic review profile dark ar | [clinic_review_profile_dark_ar.png](clinic_review_profile_dark_ar.png) |
| clinic review profile dark en | [clinic_review_profile_dark_en.png](clinic_review_profile_dark_en.png) |
| clinic review profile light ar | [clinic_review_profile_light_ar.png](clinic_review_profile_light_ar.png) |
| clinic review profile light en | [clinic_review_profile_light_en.png](clinic_review_profile_light_en.png) |
| clinic reviews dark ar | [clinic_reviews_dark_ar.png](clinic_reviews_dark_ar.png) |
| clinic reviews dark en | [clinic_reviews_dark_en.png](clinic_reviews_dark_en.png) |
| clinic reviews light ar | [clinic_reviews_light_ar.png](clinic_reviews_light_ar.png) |
| clinic reviews light en | [clinic_reviews_light_en.png](clinic_reviews_light_en.png) |
| clinic setup approved dark ar | [clinic_setup_approved_dark_ar.png](clinic_setup_approved_dark_ar.png) |
| clinic setup approved light en | [clinic_setup_approved_light_en.png](clinic_setup_approved_light_en.png) |
| clinic setup draft dark ar | [clinic_setup_draft_dark_ar.png](clinic_setup_draft_dark_ar.png) |
| clinic setup draft light en | [clinic_setup_draft_light_en.png](clinic_setup_draft_light_en.png) |
| clinic setup rejected dark ar | [clinic_setup_rejected_dark_ar.png](clinic_setup_rejected_dark_ar.png) |
| clinic setup rejected light en | [clinic_setup_rejected_light_en.png](clinic_setup_rejected_light_en.png) |
| clinic setup submitted dark ar | [clinic_setup_submitted_dark_ar.png](clinic_setup_submitted_dark_ar.png) |
| clinic setup submitted light en | [clinic_setup_submitted_light_en.png](clinic_setup_submitted_light_en.png) |
| clinic video eligible dark ar | [clinic_video_eligible_dark_ar.png](clinic_video_eligible_dark_ar.png) |
| clinic video eligible light en | [clinic_video_eligible_light_en.png](clinic_video_eligible_light_en.png) |
| clinic video ineligible dark ar | [clinic_video_ineligible_dark_ar.png](clinic_video_ineligible_dark_ar.png) |
| clinic video ineligible light en | [clinic_video_ineligible_light_en.png](clinic_video_ineligible_light_en.png) |
| gallery dark ar | [gallery_dark_ar.png](gallery_dark_ar.png) |
| gallery dark en | [gallery_dark_en.png](gallery_dark_en.png) |
| gallery light ar | [gallery_light_ar.png](gallery_light_ar.png) |
| gallery light en | [gallery_light_en.png](gallery_light_en.png) |
| onboarding fresh light en | [onboarding_fresh_light_en.png](onboarding_fresh_light_en.png) |
| showcase video dark ar | [showcase_video_dark_ar.png](showcase_video_dark_ar.png) |
| showcase video dark en | [showcase_video_dark_en.png](showcase_video_dark_en.png) |
| showcase video light ar | [showcase_video_light_ar.png](showcase_video_light_ar.png) |
| showcase video light en | [showcase_video_light_en.png](showcase_video_light_en.png) |
