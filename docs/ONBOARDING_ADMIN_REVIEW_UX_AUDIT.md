# PR13 — One-time onboarding and platform review workflows

Updated 2026-10-23 (Asia/Damascus). Backend source: **1f1e4bf**, read-only. Existing PR13 / `codex/final-backend-integration-client-preview`. This extends the consolidated release/integration work; it does not replace it or redesign the approved Patient Portal. No Django edits, store publication, PR merges or contact with Ali.

## Confirmed frontend defects and corrections

| Defect / root cause | Implemented correction | Files |
|---|---|---|
| Introduction completion existed only in process memory. | Store `aw_pref_onboarding_completed` in the existing secure-storage preference layer. Complete/Skip await a durable write, block duplicate taps and retain a retry notice if saving fails. Replay cannot clear completion. | `onboarding_service.dart`, `onboarding_screen.dart`, `main.dart` |
| Logout rebuilt a splash route; invalid startup verification could change the session epoch and strand the splash. | Session-aware app root sends established logged-out sessions directly to Login. Splash distinguishes its own verification logout from a replacement identity. Valid refreshed roles enter their own portal. Authentication/session restoration records completion for established users missing the flag. | `guest_auth_guard.dart`, `auth_repository.dart`, `splash_screen.dart`, `main.dart` |
| Category requests were buried in taxonomy management. | Top Dashboard quick action opens Pending directly, plus Content secondary entry. Pending count uses the real `count` envelope, never loaded-row length. Refresh on entry, resume, pull, return and successful approve/reject; coalesce flights and discard old-session responses. | `admin_dashboard_screen.dart`, `admin_offers_screen.dart`, `admin_review_service.dart`, `category_request_repository.dart` |
| Submitted setup had no obvious admin review route. | Clinic Reviews from Dashboard and Clinics. Paged server reads with explicit Submitted **loaded-pages-only** filter, honest unknown global count, profile inspection, supported approve-and-activate confirmation, strict acknowledgments and authoritative refresh. No invented Reject button. | `admin_clinic_reviews_screen.dart`, `admin_clinics_screen.dart`, `admin_repository.dart`, `admin_clinic_model.dart` |
| Setup copy implied medical/regulatory review; approved status disappeared from Dashboard. | Neutral platform wording, including replacing server practitioner checklist copy by item key. Keep all true setup states visible; approved/submitted cannot be resubmitted. Rejected may resubmit only with server readiness. Offline estimates cannot authorize production submission. Refresh has loading/failure feedback. | `clinic_setup_checklist_card.dart`, `clinic_dashboard_screen.dart`, `clinic_portal_service.dart` |
| Ineligible video upload appeared absent. | Intentional localized entitlement explanation and disabled gallery control. Preserve eligible picker/upload/preview/reopen/remove, and removal after downgrade. Friendly field-level video denial. | `clinic_media_screen.dart`, `api_exception.dart` |
| Fourth admin tab incorrectly advertised only Offers. | Same indexes/destinations: Home, Clinics, Leads, Content, Insights; الرئيسية، العيادات، الطلبات، المحتوى، التحليلات. | `app_locale.dart` |

Full relative paths: [task manifest](onboarding-review/TASK_CHANGED_FILES.txt). Cumulative manifest includes original PR11/12 release/media fixes, not just this increment: [all files vs main](onboarding-review/CUMULATIVE_CHANGED_FILES.txt).

## Navigation and preference behavior

- Truly empty device storage: **English + Light**, splash → introduction → mandatory authentication. Skip skips slides only, never authentication.
- Completed introduction survives a new service/process. Login, role changes, ordinary logout, failed refresh and account credential deletion do not delete device preferences. There is no `resetOnboarding` path.
- Cached sessions are verified/refreshed through the existing auth contract before portal access. Established users missing the introduction marker are not interrupted by slides.
- Patient, Clinic Admin and Super Admin logout return to Login and private navigation snapshots are purged by the existing session-key app root.
- Full storage removal restores empty-store defaults. Reinstallation is **storage dependent**: iOS Keychain can survive uninstall; Android backup/restore policy can also affect restored preferences. We tested empty versus retained stores, not a physical uninstall on either OS. An app reinstall must not be falsely claimed to always clear secure storage.
- Storage failure is not reported as durable success. Existing session/security guards, JWT transport protections and language/theme keys are preserved.

## Exact setup contract matrix — source plus executed disposable views

All paths below are relative to `/api/v1/`. JSON unless marked multipart.

| Action | Actual contract | Frontend behavior / limit |
|---|---|---|
| Read clinic setup | `GET clinic-portal/profile/setup-checklist/`, authenticated clinic membership. Returns `clinic_id`, `setup_status`, `progress_percentage`, `is_ready_for_review`, `items[{key,title_en,title_ar,is_completed,route}]`. | Backend readiness is authoritative. Practitioner copy is neutralized by key. |
| Submit / resubmit | `POST clinic-portal/profile/submit-for-review/`, `{}`. Requires **both logo and cover**, **both descriptions plus phone OR email**, active nondeleted branch, nondeleted practitioner, nondeleted treatment. Incomplete400: `error:INCOMPLETE_ONBOARDING`, `missing_items`. Success200: `status:success`, `setup_status:submitted`, `submitted_at`, `message`. | Uses neutral local confirmation instead of backend medical-compliance wording; refreshes checklist. UI permits draft/rejected only. Backend currently does not enforce transition source state. |
| List submitted profiles | `GET admin/clinics/?page=N&page_size=20`; IsAuthenticated + IsSuperAdmin. Real filters are account `status`, subscription tier, city, search, ordering. | **No `setup_status` filter or submitted total.** Sending that query is ignored. Local Submitted filter is explicitly limited to loaded pages, with manual next-page navigation. Global count shown unavailable, never guessed from account `pending`. |
| Inspect submitted clinic | `GET admin/clinics/<uuid>/`; Super Admin. Detail includes bilingual names/descriptions, contacts, website, addresses, coordinates, logo, cover, video, branches, setup/account statuses, submission time, notes, catalog counts. | Display available profile fields without regulatory identifiers. API lacks gallery projection and full practitioner/treatment records in this review payload; UI declares the counts-only limit. This is not a complete catalog audit projection. |
| Approve setup | `POST admin/clinics/<uuid>/verify/`, action serializer optional `reason` / `moderation_notes`; Flutter sends `{"reason":"Clinic profile approved through platform review."}`. Success200: `status:success`, `clinic_id`, `new_status:active`, `setup_status:approved`, `is_verified:true`, `moderation_notes`. | Explicitly confirm **approve AND activate**. Re-read detail after confirmation, require same ID and submitted state; verify acknowledgment then GET detail again. No auto-retry. Backend still needs atomic transition guards. |
| Clinic observes approval | `GET clinic-portal/profile/` and checklist return approved plus timestamps. | Refresh status; do not infer account activation from setup state. Portal profile does not include account `status` or moderation/rejection reason. |
| Setup rejection | No setup Reject route. `POST admin/clinics/<id>/reject/`404. `PATCH ... {setup_status:rejected}` ignores read-only/unsupported field. | **BLOCKED BY BACKEND**; no fabricated route or simulated success. Rejected enum can be read and resubmitted if provisioned, but no authorized API decision is available. |
| Ordinary activation/suspension | `POST admin/clinics/<id>/activate/` / `suspend/` with action serializer. Updates account status, preserves setup status. | Existing operational controls stay separate; never substitute for setup rejection. |
| Rejection feedback | Clinic portal profile excludes `moderation_notes` and `rejection_reason`. | Honest rejected-state guidance states reason is unavailable and directs clinic to platform administrator. No invented reason. |
| Category review inbox | `GET admin-portal/category-requests/?status=pending&page=1&page_size=20`, Super Admin. Paged `count,next,results`; `POST <id>/approve/ {}`; `POST <id>/reject/ {rejection_reason}`. | Server count, direct Pending screen, existing review/reason/deduplication/category-directory refresh retained. Missing count metadata/error is unknown, not zero. |

Source anchors in supplied archive: `apps/clinics/portal_views.py:185–304`, `portal_serializers.py:130–180`; `apps/admin_portal/views.py:169–235,390–489,1073+`; `serializers.py:237–355`; backend URL registrations in `apps/admin_portal/urls.py` and clinic portal URLs. Django source remains untouched.

## Video entitlement and media evidence

Actual profile tier `vip` maps to `SubscriptionTier.vipPlatinum` (legacy `vip_platinum` also understood). Unknown/basic/featured tiers cannot grant upload permission. No patient subscription labels or payment/upgrade flow was introduced.

- `PATCH clinic-portal/profile/` multipart sends **real MP4/MOV/WebM bytes as `video_ad_file`**, not a device URL or MediaAsset UUID. Frontend enforces25MiB /15seconds; backend duration validator allows its documented decoding tolerance (15.5seconds). Removal sends JSON `video_ad_file:null`, also allowed after downgrade.
- Logo/cover remain independent image fields. **This profile has no independent video-poster field**: clinic cover is the fallback poster, and the editor explicitly explains that changing it changes clinic cover. Ad-campaign poster contracts must not be confused with this profile contract.
- Existing multiple gallery uploads are additive authenticated `POST media/upload/` assets, scoped to clinic, with pagination, per-file retry and explicit one-photo deletion. No whole-gallery replacement or MP4-as-image conversion.
- Controlled Django fixture: VIP binary MP4 saved, reopened and exposed through public serializer; Basic new binary denied400; Basic removal allowed200. Flutter tests select a real local MP4 through a test native picker, assert save/reopen/remove and independent cover, and use a test video platform for lifecycle. This does **not** validate a physical Android codec or production CDN.
- Actual QA clinic tier was **not supplied**. No new physical screenshots accompanied this text attachment. Eligibility of the owner's clinic, Android gallery permissions/process death/codec, deployed build/API alignment and public HTTPS/R2 delivery remain unverified. Do not describe a source fixture URL as live R2 evidence.

## Verification and remaining acceptance limits

See [current evidence](onboarding-review/VERIFICATION.md), [Flutter renders](onboarding-review/RENDERS.md), [review-only bilingual handoff](ONBOARDING_CLINIC_REVIEW_BACKEND_HANDOFF_FOR_ALI.md), and [physical Android checklist](onboarding-review/ANDROID_SMOKE_CHECKLIST.md).

Confirmed backend gaps: global setup count/filter, setup Reject decision plus safe clinic-visible reason, atomic submit/approve transition guards, and complete authorized review projection for gallery/staff/treatments. Supported submission/approval is implemented; the full requested rejection/global inbox experience cannot honestly be called complete on1f1e4bf.

Prior device consultation evidence remains **owner reported**: patient submit → My Requests → Clinic Portal → Contacted/Closed. This task did not rerun production consultations, delete a real account or use a real user's credentials.
