# Gallery and ratings — actual Flutter renders

2026-10-27 · EN/AR × Light/Dark · 430×1000/DPR1. These are actual Flutter
RepaintBoundary screenshots, not generated images or physical-device screenshots.
All Place IDs, rating numbers, API errors and clinic data are disposable fixtures.
The queued photo is a genuine decoded test asset. The HTTP400 example tests safe
error handling; it is **not** the owner's confirmed pre-Save failure or a claim
that their image was corrupt. No live Google/API/R2 delivery is established.

| Surface | Light EN | Light AR | Dark EN | Dark AR |
|---|---|---|---|---|
| Gallery queue, Save and safe rejection details | [Render](renders/c25e901_gallery_rejection_light_en.png) | [Render](renders/c25e901_gallery_rejection_light_ar.png) | [Render](renders/c25e901_gallery_rejection_dark_en.png) | [Render](renders/c25e901_gallery_rejection_dark_ar.png) |
| Correct numeric Google fields rendered by the existing patient component | [Render](renders/c25e901_rating_valid_light_en.png) | [Render](renders/c25e901_rating_valid_light_ar.png) | [Render](renders/c25e901_rating_valid_dark_en.png) | [Render](renders/c25e901_rating_valid_dark_ar.png) |
| Private association pending; refresh and identity explanation | [Render](renders/c25e901_rating_pending_light_en.png) | [Render](renders/c25e901_rating_pending_light_ar.png) | [Render](renders/c25e901_rating_pending_dark_en.png) | [Render](renders/c25e901_rating_pending_dark_ar.png) |

Reviewed for readable bounded media, persistent CTA, safe LTR diagnostics within
RTL, no new patient design, and truthful separation of identity/sync status.
The gallery diagnostics tile is deliberately expanded/scrolled into view.
Existing golden files were not overwritten or relaxed. New Windows/Ubuntu CI
runs capture the same current-head scenarios as separate review artifacts.

Reproduce:

```sh
flutter test test/gallery_ratings_physical_qa_test.dart --reporter expanded \
  --dart-define=ONBOARDING_REVIEW_CAPTURE_DIR=/absolute/output/path
```

[Render hashes/provenance](render-manifest.json) · [Verification](verification.json) ·
[Changed files](CHANGED_FILES.txt) · [Root-cause report](../GALLERY_RATINGS_C25E901_QA_REPORT.md) ·
[Current bilingual Ali handoff](../GALLERY_RATINGS_C25E901_HANDOFF_FOR_ALI.md) ·
[Physical retest checklist](../GALLERY_RATINGS_C25E901_ANDROID_RETEST.md).
