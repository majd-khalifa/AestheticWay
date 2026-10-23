# Final backend integration and client-preview readiness

Date: 23 October 2026 (Asia/Damascus). Backend source: supplied `1f1e4bf` archive, SHA-256 `48d385acc256ebba450ede43e515f475daf1ae8ed3de80319e68429833f7c1ff`.

This report supersedes **contract availability** findings in the d1023b0 Clinic Portal and release reports. Those reports and their screenshots remain historical evidence, not the current category/deletion capability statement. No Django file was modified.

## Consolidation and scope

New branch: `codex/final-backend-integration-client-preview`, based on current `origin/main` `b402d3bf7cc46c73cc1f142c7e93c4066e92d594`. Normal merges preserve PR11 head `872f20f7b0f2703f561069671e40c76e4488e6bc` and PR12 head `43e68249a522a69169cf1cb018dd63b0c2353ec1`, including historical Clinic Portal commit `c6fe01dfc16c0409c0766769cf51505b579cd85f`.

Both merges were clean. The overlapping `clinic_profile_screen.dart` retains the account/privacy actions, logout and release integration from PR11 **and** PR12's media-management entry, image edits, coordinates and session guards. No file was resolved by choosing an entire old version. PR11/12 remain open; the consolidated PR targets main and is not merged. Patient artwork, navigation, preferences, consultation UX, signing safeguards and iOS native configuration are preserved.

See [changed-file manifest](final-integration/CHANGED_FILES.txt) for every cumulative file relative to main and [integration-only manifest](final-integration/INTEGRATION_FILES.txt). Binary screenshots and fixtures are test/documentation artifacts, never production clinic content.

## Source delta before Flutter integration

Compared all files with the supplied d1023b0 snapshot: **10 added, 18 changed, 0 removed**, **403 latest files**. [Exact path delta](final-integration/backend-delta.json).

| Contract | 1f1e4bf evidence | Flutter behavior |
|---|---|---|
| Clinic category requests | `api/v1/urls.py`; `apps/treatments/urls_category_requests.py`, `serializers_category_requests.py`, `views_category_requests.py` | GET/POST `clinic-portal/category-requests/`. JSON `{name_en,name_ar}` only; English required <=200, Arabic optional <=200. Authenticated clinic role, clinic derived from membership. New requests stay **pending**, never selected as categories. Paged pending/approved/rejected history, rejection reasons, manual refresh and directory refresh on return. |
| Duplicate requests | `ClinicCategoryRequestViewSet.create` | 400 `CATEGORY_ALREADY_EXISTS` refresh/select guidance; 409 `DUPLICATE_CATEGORY_REQUEST` pending-history guidance. Both retain form inputs and do not retry automatically. |
| Super Admin taxonomy | `apps/admin_portal/urls.py`, `AdminTreatmentCategorySerializer`, `AdminTreatmentCategoryViewSet` | GET/POST `admin-portal/treatment-categories/`; PATCH/DELETE `<uuid>/`. Names, `display_order>=0`, `is_active`; slug/icon remain server-owned. Create/edit/archive/reactivate and paged listing. No clinic route fallback. |
| Safe category deletion | `Treatment.category` now PROTECT; view checks all related treatments | 409 `CATEGORY_IN_USE` explains archive or reassign. Existing treatments survive; no client cascade. Inactive categories cannot be newly assigned; preserving an existing archived category on edit is allowed by the new serializer. |
| Moderation | `AdminCategoryRequestViewSet` | GET `admin-portal/category-requests/?status=pending` with server count/paging; POST `<uuid>/approve/` `{}`; POST `<uuid>/reject/` `{rejection_reason}`. Rejection text persists until confirmation; pending count refreshes after acknowledgment. Approved category directory refreshes on return. |
| Deletion request | `apps/accounts/urls.py`, `views_deletion.py`, `services/account_deletion.py` | POST `auth/me/deletion/request/` `{}`. `reason` optional, not needed. Require `success:true`; read `expires_in` and `resend_cooldown`. Registered-channel OTP; 600s expiry, 60s resend cooldown, request throttle 5/hour, five failed proofs per challenge. No account ID in payload. |
| Deletion confirm | Same files; authenticated request user's identity | POST `auth/me/deletion/confirm/` `{code,refresh_token}`; code generated as six digits (serializer max10). Explicit permanent-deletion consent plus code. Require `success:true` before clearing tokens/profile, device token, private portal/referral/media caches and navigating to Login. Failure preserves inputs/account; stale completion cannot clear a replacement login. |
| Safeguards | `check_deletion_safeguards`, rechecked on confirmation | Localized `LAST_SUPER_ADMIN`, `SOLE_CLINIC_ADMIN`, `ACCOUNT_ALREADY_INACTIVE`; no frontend bypass. Invalid/expired challenges have DRF `VALIDATION_ERROR` with `fields.code`, not invented OTP machine codes. |

**No server-backed Admin search is claimed:** this viewset has no declared searchable fields. Pagination remains real. Cosmetic brand-product taxonomy remains a separate model/contract, never reused as treatment taxonomy; unrelated global brand authoring was not added by this task.

## New backend fixes recognized; old blockers retired

- Category CRUD, clinic proposals and moderation now exist; previous “all category writes unsupported” conclusion is obsolete. **Clinic direct global mutations remain forbidden**; public/category and clinic catalog mutation guards stay intentionally read-only. Admin uses separate verified endpoints.
- Deletion endpoints/lifecycle now exist; the old support-email-only workaround has been replaced for patient, clinic_admin, clinic_staff and super_admin settings.
- Logo/cover validators now use shared signature/MIME/size/dimension validation. Generic media upload now enforces image-only media types and AD_VIDEO video MIME; practitioner_portrait is an additional accepted alias. Existing practitioner_avatar remains supported.
- Portal list ordering adds UUID tie-breakers. No client pagination/security rollback.
- Super Admin writes through Clinic Portal now require explicit membership; the previous arbitrary-clinic write fallback is closed. Read-only fallback remains in Django but Flutter maintains portal role isolation.
- Patient notification body no longer interpolates consultation reference; internal payload IDs/references remain operational. Patient display suppression from PR11 stays intact.
- Treatment category deletion now protects references, and editing preserves an already assigned archived category.

## Preserved media capability matrix

| Content | Verified supported upload/association | Limit / intentional boundary |
|---|---|---|
| Clinic logo/cover | Binary profile multipart PATCH `logo`, `cover_image`; null explicitly clears | JPG/PNG/WebP, signature and dimensions validated; no raw URL editor |
| Clinic gallery | Multiple native image selections queued; each POST `media/` file + `media_type=clinic_gallery` + owned clinic UUID; existing paged assets and single-asset DELETE | Additive uploads, per-file error/manual retry; public gallery derives oldest10 images. No gallery-array replacement or invented reorder/draft API |
| Clinic showcase video | Profile multipart `video_ad_file`; canonical video URL reopened and played only on tap; null removes association | VIP upload entitlement; existing video removable after downgrade. <=25MiB, <=15.5s duration, signature checks. Cover serves as separate poster source; no MP4 as image |
| Practitioner | `/media/` practitioner_avatar typed asset UUID + avatar URL through portal serializer | Single portrait; alias practitioner_portrait additionally accepted by backend. No practitioner gallery/video association |
| Offer / product / article | Typed owned media asset UUID plus image/cover URL, explicit clear, omitted image preserved | One image each; products remain brand showcases with no prices/cart/purchase |
| Treatment | Category UUID, nullable decimal price, practitioner UUID list | No treatment media field or video relationship in this source. Missing support documented, never invented |
| Featured campaign | Existing independent ad model/media types | No new clinic campaign association CRUD in this source; no unsupported editor added |

Existing Flutter media/treatment regression tests cover native pickers, queue selection/removal, failure/retry, save/reopen, canonical remote URLs, patient rendering, real PNG decoding and real MP4 signature/duration fixtures. The controlled Django ledger executes actual serializers/views with local test storage; it does **not** prove production Cloudflare R2 delivery, physical gallery permissions, persistence across a real device restart or live entitlements.

## Evidence boundaries

- **Performed here:** all **660 supplied Django tests pass** on Linux/Python3.12.14/Django5.2.4, isolated SQLite `:memory:`, locmem cache/email, test SMS/storage. This independently reproduces the owner's test count, not their deployment claim; it is not PostgreSQL/Redis/R2 or exact production lock verification.
- **Performed here:** **101 controlled Django responses** with disposable local role fixtures exercise old media/treatment workflows and new requests/approvals, protected CRUD, archived assignment, cross-clinic denial, deletion success/safeguards/expired proof/unauthenticated denial. [Sanitized ledger](final-integration/controlled-django-contracts.json). No OTP/JWT proof is retained in the ledger. All **403 backend file hashes remain unchanged**.
- **Flutter/CI/build results:** recorded in [verification](final-integration/VERIFICATION.md) as jobs finish. Actual Flutter renders are indexed in [renders](final-integration/RENDERS.md); local synthetic fixture content is clearly distinguished from production media.
- **Owner-reported physical Android QA**, from the prior release task: a patient successfully submitted a consultation, saw it in My Requests; Clinic Portal saw the same lead and changed Contacted then Closed. Not performed by this agent and not repeated against production.
- **Not verified live:** deployed commit fingerprint, production JSON/CDN/Google delivery, OTP delivery, private review accounts, native device permissions/kill-restart, production account deletion. The environment's network policy blocks `aestheticway.ae`; no bypass or fabricated response was used. Source compatibility is not live deployment proof.

## Remaining release dependencies

See the bilingual [Ali handoff](FINAL_INTEGRATION_BACKEND_HANDOFF_FOR_ALI.md). Self-service UI is implemented, but store compliance is not declared complete while public deletion guidance, accurate retention/privacy disclosures, lifecycle completeness and real-device/native checks remain outstanding. No real account was deleted. No release was published.

Other inherited release gates remain: privately provisioned review accounts for all roles; production Play upload identity/App Signing and Apple provisioning; accurate Data Safety/App Privacy/Health Apps declarations and operator/media-rights metadata. API36 physical smoke, Android picker activity-death recovery (`retrieveLostData` remains absent), verified incoming invite App Links/Universal Links, and the iOS13/14 support decision remain P1 work/verification from PR11. Unsigned/synthetic CI does not close those gates. No role bypass or new production content was added.

Client-preview Windows commands and the MacBook/iOS handoff: [runbook](FINAL_CLIENT_PREVIEW_RUNBOOK.md).
