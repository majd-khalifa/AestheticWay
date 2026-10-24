# AESTHETIC WAY — Backend P0 QA Gaps + UAE Geo Discovery Contract
**For Ali / لعلي — Technical handoff**  
Date: 2026-10-24  
Flutter reference: PR #13, branch `codex/final-backend-integration-client-preview`, commit `e87dc682e2a8eff5d8f2cc3dca926b5848569428`  
Django source reference: `09f49bbd22131f6dad49a65a5167de5396f03797` (archive provenance, not independent proof of deployment).  
**Do not regress** consultation leads, patient/clinic/admin role isolation, existing API fields, pagination max 20, paid placement ordering, Google Places or R2 media contracts.

## 0. Scope and evidence classification
We completed physical Android **UI acceptance checks**, not network/backend traces. User-reported: **10/12 passed**, **2/12 not yet verified** (video persisted after app/process restart; remove saved video without changing cover). Admin review approvals, rejection/resubmit, gallery add/delete, patient leads, statuses, preferences and onboarding passed. Physical evidence shows: a local-selected VIP video previews but persistence after save is not confirmed; the exact banner "The service is temporarily unavailable. Please try again." appeared **after tapping Upload and save video** on the Clinic Media screen, while gallery photos happened to remain visible; account deletion by the only admin is blocked, and a new clinic's deletion challenge says "Code sent" without revealing a destination. These are **observations**, not yet a proven server root cause.

Source-audited residual defects **already confirmed by Codex in the supplied 09f49bb archive**, separately from the phone observations: a received referral retains deleted patient's `invitee_phone` and note; `reject-setup` can reject an approved setup; after reject→resubmit previous `moderation_notes` remain; tree-wide Ruff v0.17.2 emitted 104 findings (check scope/version; not all regressions).

## P0-A. VIP showcase video: persisted storage and acknowledgment
**Observed on physical Android:** after selecting a VIP clip and tapping **Upload and save video**, the UI showed `The service is temporarily unavailable. Please try again.` above the gallery. The selected local video could be previewed, but there is **no confirmed successful server save** and persistence after restart remains unverified. Existing gallery photos remaining on the page do not imply that a gallery API call failed. The cover still looks the same.
- **Reproduce the specific failure on the Save button.** Inspect authenticated `PATCH /api/v1/clinic-portal/profile/` multipart field **`video_ad_file`**, private read-only `subscription_tier` (`vip` required), actual HTTP status/error envelope, timeouts/size limits/proxy/CDN behavior, successful transaction and R2 object metadata. Trace whether the error comes from the PATCH itself, subsequent profile refresh, or the client exception mapping; do not automatically attribute it to gallery GET.
- Correlate **one disposable authorized VIP QA upload** with server logs using non-PII request/correlation identifiers and timestamp, without publishing JWTs, OTPs, full signed URLs or private media contents. Confirm 2xx, actual response body, subsequent **fresh** `GET /api/v1/clinic-portal/profile/` `video_ad_file`/video URL, DB persisted reference, object existence, HTTPS `200`/`206` range response and `Content-Type: video/mp4`.
- Verify same-clinic UUID; avoid stale cache, failed storage transaction, early 2xx without durable object, or read serializer omission. Verify saved video survives a fresh authenticated session and application process restart (Android steps with Flutter).
- Test VIP draft/submitted/approved where policy permits; Basic/Featured replacement denied, removal allowed; 25MiB and 15 seconds and actual codec/MIME guards, server permission 400/403, cancellation. Do not disable server authorization.
- **Important:** current media contract deliberately keeps clinic `cover_image` separate from `video_ad_file`; unchanged cover is **expected**. The cover currently acts as a fallback poster. If an independent selectable *video poster* is required, design a **new optional read/write field** and migration/API/test contract as a separately approved P1 feature, never overwrite cover implicitly. Return recommendation and effort estimate instead of silently changing the profile contract.
- Provide a redacted actual request/response sample and outcome by tier, followed by latest deployment commit.

## P0-B. Account deletion delivery, sole-admin exit and verified channel
**Observed:** sole admin of active clinic gets blocked, while a different clinic/account gets the six-digit challenge UI but the destination is undisclosed and delivery unverified.
- Inspect `POST /api/v1/auth/me/deletion/request/` and `/confirm/`, `SOLE_CLINIC_ADMIN` and `LAST_SUPER_ADMIN` checks, provider configuration, SMS send result, verified-email eligibility, queue/worker, actual masked delivery channel and provider delivery/acceptance state. No OTP in responses or logs.
- Extend the **authenticated** response safely to include `delivery_channel: "sms"|"email"`, `masked_destination` (e.g. `+971******123`), `expires_in`, `resend_cooldown`. Values are **proposed response fields**, not claimed as currently implemented. Derive from the actual destination to which the challenge was sent; never leak an unverified address or full contact. Generic copy should say 'request accepted' when provider acknowledgment does not prove final delivery. Make error codes/message clear when no valid reachable channel exists.
- Do not bypass the sole clinic admin safeguard. Supply a verified and auditable path: transfer ownership/add another authorized admin **or** close/deactivate associated clinic with an explicit ownership-and-retention policy, allowing user account deletion thereafter. Ensure stores' account-deletion requirements can actually be fulfilled without an endless block; retain privileged last-Super-Admin safeguards.
- Test disposable real-reachable SMS and verified-email destinations on production with user approval, resend/expiry, wrong code, provider outage; do not require owner to paste the OTP into any chat.
- Review `account-deletion/` public information for actual backup retention/privacy alignment.

## P0-C. Previously confirmed source privacy/state defects
1. **Received referral PII:** On confirmed deletion `ReferralInvite` rows where the deleted user is **recipient/referred_user** retain `invitee_phone` and note. Scrub all retained instances keyed by recipient and pre-anonymization phone; respect uniqueness/length constraints, preserve only non-identifying analytics. Add tests for both inbound/outbound referrals and no reappearance after reload. This is a privacy blocker.
2. **Reject-setup state guard:** `apps/admin_portal/views.py::_handle_reject_setup` currently accepts an approved setup. After `select_for_update`, reject only `submitted`; return a stable `409 INVALID_SETUP_TRANSITION` (or confirmed equivalent) otherwise, preserve account activation, add PostgreSQL racing approve/reject regression.
3. **Resubmission notes:** On rejected/draft → submitted clear current `moderation_notes`/current rejection aliases transactionally; preserve audit history. Explicitly forbid approved/submitted erroneous transitions. Test DB and both serializers, not only Flutter UI.
4. Review the 104 Ruff full-tree results using pinned config/version; report introduced versus pre-existing findings rather than claiming whole-tree zero.

## P1-D. Gallery regression check — NOT a reported independent gallery failure
**Correction from the physical tester:** the generic `The service is temporarily unavailable` message appeared **on pressing Upload and save video**, not on gallery refresh or image upload. Therefore classify this primarily under **P0-A video save**; do **not** open a separate gallery API incident from this screenshot. Gallery multi-image upload/delete was reported PASS. As a non-blocking regression check, verify the existing gallery loads/refreshes and images survive video save failures, and that the video failure banner is located beside the **video save** action rather than misleadingly at the top of the gallery. Only file a gallery backend defect if independent network trace proves a gallery endpoint failed.

## New feature P1 — Nearby Clinics + all UAE Emirates/cities
**Approved product behavior:** GPS **only after contextual opt-in while app in use**, plus **manual Emirates→Cities selection**; include **all active, patient-visible clinics**, sorted by true distance if coordinates are available. This is separate from the sponsored Featured carousel; clinic subscription tier must remain private from patients. Missing/denied GPS never blocks browsing or lead submissions.

### Existing code surface (not proof backend performs actual proximity sorting)
- `GET /api/v1/home/feed/` parsed `nearby_clinics` and Flutter `HomeRepository.getHomeFeed(latitude,longitude,city)` already forwards parameters.
- `GET /api/v1/clinics/` Flutter `ClinicsRepository.getClinics(latitude,longitude,city,page,page_size)` also forwards parameters.
- Flutter currently loads the Home feed by **city only**, and only exposes Dubai and Abu Dhabi in the Home selector; `NearbyClinicsSection` is actually labeled **Discover clinics**.
- `ClinicCoordinates.parse` rejects invalid/synthetic zero coordinates. Clinic location selector has emirate centers only as map **camera seeds**; never persist those as clinic locations without user confirmation.

### Contract discovery and implementation decision
First inspect the actual Django source for geo ordering/filtering of `home/feed` and public clinics. Reuse existing endpoints **if** they already guarantee genuine distance ordering and all active visible clinics. Otherwise add version-compatible API(s) such as **proposed**:

`GET /api/v1/clinics/nearby/?latitude=25.20&longitude=55.27&radius_km=20&page=1&page_size=20`

or extend the existing `GET /api/v1/clinics/?latitude=...&longitude=...&ordering=distance` plus existing `home/feed` projection. **These are designs to confirm, NOT existing endpoint claims.**

**Output requirements:** stable clinic ID, localized names, city/emirate canonical keys, clinic cover/logo real HTTPS URL, optional `distance_km` derived by server, optionally nearest valid **active branch** ID/location when nearest branch determines proximity. `distance_km` must be null/omitted when unverified; never invent distance, map location, rating or opening hours. Deterministic sort `distance asc, clinic ID asc`; clinic deduped with nearest eligible verified branch; stable pagination capped at 20 with total/next/previous. Publish whether nearby is within selectable radius or nearest N, with clear zero results and a manual-location fallback.

**Geo validation and security:** reject out-of-range/nonfinite coordinates and invalid radius with 400; restrict request coordinates to sensible UAE search window as appropriate without breaking location outside UAE (manual selector must still work); avoid exact geolocation logging, avoid retaining users' GPS as profile field, and avoid public access to admin-only/tier details. Enforce active/visible clinics, filter out unconfirmed/outlier `(25.2048,55.2708)` default Dubai records and `(0,0)` placeholders. Use stored, confirmed coordinates; consider branches and clinics with missing coordinates separately for city searches. Protect against large geo scans, rate abuse and stale caching. Use indexed bbox-first query + distance refinement (PostGIS if available, otherwise SQL-appropriate implementation) and cache coarse-grained (city/tile/radius) not raw precise coordinates in cache keys. Avoid N+1 and maintain 20-per-page pagination.

### Canonical Emirates→cities catalog
Official seven Emirates: Abu Dhabi, Dubai, Sharjah, Ajman, Umm Al Quwain, Ras Al Khaimah, Fujairah (https://u.ae/en/about-the-uae/the-seven-emirates). This is **not** the full set of cities. Create/confirm a canonical expandable bilingual location catalog with stable immutable `emirate_code`, `city_code` or slug, `name_en`, `name_ar`, `emirate`, `is_active`, `display_order`, aliases for Arabic/spelling variants. Use official UAE/open government datasets to source and validate complete cities; avoid hardcoding a guess as an exhaustive list. Example seed targets to verify: Abu Dhabi City, Al Ain, Madinat Zayed/Al Dhafra region; Dubai, Hatta; Sharjah, Khor Fakkan, Kalba, Dibba Al Hisn; Ajman, Masfout, Manama; Umm Al Quwain, Falaj Al Mualla; Ras Al Khaimah, Al Jazirah Al Hamra; Fujairah, Dibba Al Fujairah. Check jurisdiction and city-vs-district classification before seed.

**Proposed** public endpoint `GET /api/v1/locations/emirates/` returning Emirates with nested/cursor-paged city choices, or `GET /api/v1/locations/cities/?emirate=DU`; never assume route exists without verifying. Avoid changing older `city` string compatibility unexpectedly. Map existing records (`Dubai`, `دبي`, `Abu Dhabi`, `أبوظبي`, `Ras Al Khaimah`, etc.) to canonical codes with a reviewed migration; do not bulk assign fake cities or coords. Make clinic onboarding, branch edit, Super Admin clinic edit, public clinic filters and home selection use this catalog; preserve old saved filters gracefully.

### Nearby response sketch (**proposed**, not verified)
```json
{
  "count": 2,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "<actual-clinic-uuid>",
      "name_en": "<actual name>",
      "name_ar": "<actual name>",
      "emirate_code": "DU",
      "city_code": "dubai",
      "latitude": 25.2,
      "longitude": 55.27,
      "distance_km": 2.4,
      "cover_image": "https://media.aestheticway.ae/<actual-saved-object>"
    }
  ]
}
```
The placeholders above are **illustrative schema values only**, not real clinic data.

### Caching and behavior matrix
- Permission granted + valid live fix: nearest real active visible clinics, distance labels only if computed; do not use user-selected manual city as GPS location.
- Approximate/reduced accuracy: provide appropriately qualified approximate results; no exaggerated precision.
- Denied/deniedForever/services off/timeout/user outside UAE: show manual Emirates→city selector, not error lockout.
- No nearby eligible clinics: show true empty state and useful user-invoked browse-all alternative.
- Location changes/city changes/session swap: invalidate stale results; never display previous city's cards under new label.
- Selected city may include clinic without coordinates, but **do not** display a fake `km away` distance.
- Page through at least 3 pages with tied distances, branches, differing city aliases, inactive/unapproved clinic, no-location clinics and concurrent record insertions.
- Preserve patient discovery, featured/ads placement, treatment/service/offer results and consultation leads, Arabic RTL/English LTR, Light/Dark, initial English/Light.

## Required Ali deliverables
1. New deployed **real commit SHA**, changes and migration numbers, and production confirmation with redacted evidence (do not substitute `<COMMIT_HASH>`).
2. Root-cause + fixed/explained **VIP Save video** error (the banner was triggered by pressing Save, not by gallery refresh); non-regression verification for gallery; deletion delivery channel and sole-admin compliant exit path.
3. Corrected privacy and review-transition regression results; PostgreSQL concurrency evidence.
4. Actual supported endpoint paths, query parameters, JSON response fixtures, error codes, permissions and page semantics for proximity + city catalog.
5. Data migration/backfill for real Emirates/cities **without fake coordinates**, rollout and reversible migration plan, schema compatibility.
6. Source-verified tests, production smoke test evidence from owned QA data, media persistence and location correctness; benchmarking under 1k+ clinic fixture and cache invalidation evidence.
7. Short bilingual handoff clarifying what Flutter should update; no secrets, PII or raw location telemetry.

## Concise Arabic summary / ملخص للعلي
الاختبارات الميدانية نجحت بوظائف المريض والموافقات واللغة، لكن نحتاج إثبات حفظ الفيديو فعلياً بعد إعادة تشغيل التطبيق؛ لا نعتبر بقاء غلاف العيادة عيباً لأن الغلاف منفصل عن الفيديو. ظهرت رسالة تعذر الخدمة **عند الضغط على رفع وحفظ الفيديو** وليس عند تحديث صور المعرض؛ يجب تتبع PATCH الفيديو والاستجابة ثم GET الملف وليس اعتبارها عطل معرض مستقل. في حذف الحساب، منع المدير الوحيد مقصود لكنه يحتاج مسار خروج مشروع؛ صفحة OTP لا تعرض قناة إرسال أو وجهة مخفية ويجب التحقق من وصول الرسالة فعلياً. بالإضافة إلى 3 مشاكل مؤكدة سابقاً في مصدر Django (خصوصية إحالة مستلمة، رفض ملف معتمد، استمرار ملاحظات الرفض)، نحتاج تصميم نطاق العيادات القريبة: كل العيادات النشطة الظاهرة، GPS بإذن اختياري أثناء الاستخدام أو اختيار إمارة ثم مدينة، مسافات حقيقية فقط، خريطة ومدن موثوقة وبدون إحداثيات افتراضية، والترتيب والصفحات والأمان والكاش الصحيح.