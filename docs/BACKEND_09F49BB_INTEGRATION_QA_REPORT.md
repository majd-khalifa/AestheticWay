# PR #13 — Backend 09f49bb integration and VIP video QA

Date: 2026-10-24. Branch: `codex/final-backend-integration-client-preview`.
Frontend baseline: `c0257182b075ce5834af7e2d4a40903fd70b8d45`.

## Source provenance and verification boundaries

The supplied Git archive comment identifies **`09f49bbd22131f6dad49a65a5167de5396f03797`**. Archive SHA-256: **`0fdd6b75b850466c9d63e1dc64665fa7d2c9db4dcfc6ff8db32b225eb59b7b61`**. Compared with the preceding `1f1e4bf` snapshot, 11 files changed and two files were added. All **405** extracted source files remain byte-for-byte unchanged after testing.

The connected GitHub identity receives 404 for the private backend commit lookup. Therefore the complete commit identifier is archive provenance, not independently verified GitHub history or production deployment evidence. Ali's supplied report contains a `<COMMIT_HASH>` placeholder and reports production R2 delivery; neither statement substitutes for a deployed API response captured by this audit.

Independent local checks:

- **671 backend tests passed**, using the supplied `config.settings.testing`, SQLite, mock communication providers and temporary local media. No production database, credentials, OTP delivery or R2 objects were accessed.
- `makemigrations --check --dry-run`: **No changes detected**.
- Additional read-only full-tree `ruff check --no-cache` with Ruff **0.17.2** reports **104 findings** (imports/unused symbols and other configured lint rules). Ali's clean-lint statement was not reproduced at this version/scope. These include existing files; no Django lint fixes were applied, and they are not classified as new runtime/API blockers.
- [38 real Django-view probes](backend-09-integration/controlled-contracts.json) exercised pending VIP binary persistence, read-only tiers, review transitions, filtering beyond page one, tenant isolation, deletion OTP endpoints and the anonymous HTML route. Source hashes were checked before and after.
- Flutter tests use real decoded file/image fixtures and actual multipart streams; the video platform adapter supplies controlled native lifecycle events. These are not physical codec, background process-death or live CDN tests.

This environment's enforced network policy excludes `aestheticway.ae` and `media.aestheticway.ae`. Live deployment, public HTTPS delivery, byte-range video playback, production JWT behavior and physical Android restart/persistence remain **unverified here**. Ali's reported successful production MP4/HTTP 200 is recorded as **backend-engineer-reported evidence only**. Earlier user-reported physical consultation QA remains historical evidence for consultations, not VIP video.

## Contract comparison and Flutter corrections

| Contract | Actual 09f49bb source | Flutter implementation |
|---|---|---|
| Private clinic GET/PATCH | `ClinicProfilePortalSerializer` now returns read-only `subscription_tier`, `moderation_notes`, `setup_rejection_reason`. The reason alias is populated only while setup is rejected. | Existing recognized-tier parser accepts the private value directly. No public lookup occurs for a known tier, including pending/unpublished profiles. Legacy missing-tier recovery stays available; unknown values never grant VIP. Owner/checklist models now retain the rejection reason. |
| Binary showcase video | `PATCH /api/v1/clinic-portal/profile/`, multipart **`video_ad_file` bytes**. DB tier `vip` required for non-null files. Basic/Featured rejected; all tiers may remove with JSON null. | Native gallery picker, 25 MiB signature/size checks, 15-second guidance and source-matching 15.5-second decoder tolerance retained. Same-clinic acknowledgment and fresh GET are verified; failures retain a deliberate retry path. Play/pause feedback is localized. |
| Review inbox | `GET /api/v1/admin/clinics/?setup_status=submitted` performs independent setup filtering and paginates. Ordinary `status` still represents account activation. | `AdminRepository.getClinics(setupStatus: ...)` sends the filter on every page. Inbox uses server results/total instead of filtering loaded rows. Filter changes invalidate old page responses. A server returning mismatched setup states produces a compatibility error. |
| Global review count | `GET /api/v1/admin/dashboard/` supplies `submitted_setup_count`. | Nullable `submittedSetupCount` preserves unknown versus a genuine zero. Dashboard review action displays the global value. Count reads coalesce, refresh on entry/resume/decisions, and reject late pre-decision or previous-session results. Account-pending counts remain separate. |
| Approve | `POST /api/v1/admin/clinics/<uuid>/verify/`, body may contain `reason`. Source returns a **small acknowledgment**, sets approved + active, clears moderation notes and rechecks completeness under a row lock. | Confirm dialog explains both effects. Repository re-reads submitted state, sends POST, verifies clinic/status/setup acknowledgment, then re-reads full approved/active detail. No optimistic approval. |
| Reject | `POST /api/v1/admin/clinics/<uuid>/reject-setup/`, body **`rejection_reason`**, trimmed non-empty, at most 1000 chars. Source returns `status`, `clinic_id`, `setup_status`, `rejection_reason`, `moderation_notes`; **not full detail**. Account status is preserved. | Required bounded reason dialog, duplicate guard, submitted-state pre-read, exact acknowledgment validation and full detail re-read. UI limits this action to submitted profiles. It cannot close the backend's concurrent transition gap. |
| Conflicts | Actual verify codes: **`CLINIC_NOT_SUBMITTED`**, **`CLINIC_SETUP_INCOMPLETE`**, HTTP 409. Owner resubmit approved: **`ALREADY_APPROVED`**, 409. Incomplete owner submit: **`INCOMPLETE_ONBOARDING`**, 400 with string `error`. | Parser safely retains/localizes source codes and the reported aliases **`INVALID_SETUP_TRANSITION` / `INCOMPLETE_ONBOARDING`**. Both nested and simple error envelopes are handled without retaining raw diagnostics. Conflicts refresh visible state and never report a successful decision. |
| Owner resubmit | `POST /api/v1/clinic-portal/profile/submit-for-review/` returns `status=success`, `setup_status=submitted`. Server prevents approved resubmission, but retains old moderation notes. | Only draft/rejected ready forms expose submission. Missing or contradictory acknowledgments fail; no default-to-submitted success. Submitted models hide old rejection feedback. Checklist refresh keeps the server authoritative. |
| Review media/content | Admin detail includes `gallery_assets`, `gallery_images`, `practitioners`, `treatments`; all queried from the retrieved clinic. | Typed review-only models, role/session-guarded shared inspection widget, bounded gallery, original-image expansion, portrait fitting, actual category/status fields and batched reveal of supplied records. No public staff lookups or foreign asset traversal. |
| Account deletion | Purpose-bound `POST auth/me/deletion/request/` → success/600-second validity/60-second resend; confirm with `code` and optional `refresh_token`. Structured blocked safeguards are **400**, not uniformly 409. | Existing exact request/confirm mapping retained. OTP/consent/challenge are cleared on actual account replacement; a new code requires fresh consent. 400/403/409 do not manufacture logout/success, 401 follows existing auth handling. A confirmed deletion clears private identity/cache/navigation and returns to Login while preferences remain persisted. |

Source/report differences matter: `AdminPractitionerSummarySerializer` supplies **`type`**, not `practitioner_type`; it does not supply the reported `is_active`/`display_order`. Treatment summaries supply `id`, bilingual names, `category_name`, **`price`**, `status`, `is_active`, `created_at`; they do not supply the reported descriptions, category UUID, `starting_price` or treatment media. The UI renders supported identity/category/state without inventing those missing fields or introducing product commerce. Regulatory fields returned by Django are excluded from the new inspection models/widgets.

## VIP journey acceptance matrix

| Scenario | Verified result / boundary |
|---|---|
| Private VIP + draft/submitted/rejected setup, pending account | Picker enabled from the private tier alone. New widget journeys assert **zero public detail requests**. Source probe confirms pending VIP private GET/PATCH succeeds while public detail is 404. |
| Selection and cancellation | Existing real native-picker fixtures retained; cancellation sends no mutation. |
| Valid upload | Real two-second MP4 fixture, multipart stream contains actual MP4 bytes; no editable tier, media URL string, invented poster or asset field is sent. |
| Save/reload | Same-clinic HTTP(S) acknowledgment and subsequent profile GET verified. Source storage object exists and a fresh Django client reloads the saved reference. |
| Cold frontend service | Dispose screen → reset clinic service → restore repository → fetch private profile again → render saved video. Selected device path is not used as persisted server state. |
| Preview/play/pause | Controlled native video events and play/pause calls exercised. Hardware decoding/production HTTP range delivery remain physical checks. |
| Remove after playback | Confirmed JSON null PATCH, source/UI reload show no video; clinic cover remains unchanged. Waiting is tied to native-operation completion, not a larger timeout. |
| Basic/Featured | New binary rejected by source; client refuses stale VIP grants and keeps removal available for saved videos. |
| Missing/future tier; wrong UUID; expired session | Unknown/retry or denied state. No inferred VIP from badge, `is_featured`, old session or a foreign DTO. |
| Constraints/errors | Existing invalid signature, oversize, zero/long duration, decoder failure, cancellation, 400/403, network and incomplete acknowledgment tests retained. No automatic write retry or fabricated success. |

## Review and privacy behavior

Approval explicitly includes activation because that is what the verified endpoint does. Rejection is a profile decision and preserves activation. Separate activate/suspend operations remain intact. The inbox and global count refresh after decisions; stale decision responses cannot replace a newer session or counter generation. Rejection details are re-fetched rather than treating an acknowledgment as a full clinic DTO.

Clinic owners see actual localized review feedback and the existing edit/checklist actions. Feedback is shown only for rejected setup and sanitized against prohibited regulatory labels. Submission remains guarded by completeness, state and a verified acknowledgment. Source still needs stronger transition guards and note cleanup; see the handoff.

New review media uses source ownership, genuine supplied URLs and MIME checks. `gallery_assets` is authoritative when present; `gallery_images` is a compatibility alias when the asset projection is absent, preventing duplicate or stale gallery display. Video URLs are excluded from image galleries. Empty, failed and pending frames remain distinct. Portraits expand without cropping; treatment rows remain compact because the supplied summary has no image field. Records are revealed in batches without inventing a pagination endpoint for the unpaginated detail arrays.

The account-deletion source improves lead-note clearing and personal media deletion. The probes independently confirm personal asset removal, OTP rejection and acknowledged deactivation. However, a received `ReferralInvite` retains the deleted patient's `invitee_phone` and personal note: only notes on invites **sent by** the user are cleared. This is a confirmed privacy gap, not a Flutter mapping defect. Production PostgreSQL concurrency, storage deletion failure handling and operational backup retention are not proven by the SQLite suite.

The new anonymous `/account-deletion/` view and bilingual template return 200 in the local Django test client. Their presence is verified; public deployment, HTTPS delivery, company metadata accuracy and the stated encrypted-backup retention operation require live/operational evidence.

## Visual evidence, changed files and native validation

- [Actual Flutter renders](backend-09-integration/README.md): gallery, clinic review, staff/treatments, owner feedback, cold VIP state; Light/Dark × English/Arabic and 320dp/180% text cases. These are explicitly labeled, decoded QA fixtures, not production clinic photographs or physical QA claims.
- [Incremental changed files](backend-09-integration/CHANGED_FILES.txt) and [cumulative changes vs main](backend-09-integration/CUMULATIVE_CHANGED_FILES.txt).
- [Verification ledger](backend-09-integration/verification.json), [source contract probes](backend-09-integration/controlled-contracts.json), [source comparison](backend-09-integration/backend-source-diff.txt).
- Formatting, analyzer, full Flutter tests and diff checks are run before commit. Final exact-commit CI outcomes and run/job links are recorded in [PR #13](https://github.com/majd-khalifa/AestheticWay/pull/13), including any remaining native-host limitation; previous commits' successful builds are not substituted for this update.

Native signing files, dependencies and production Android/iOS project configuration are unchanged. Android CI retains API 36, real APK/AAB compilation, disposable verification signing and fail-closed checks. macOS CI now selects and initializes the pinned Xcode explicitly and bounds/logs simulator discovery, with one current-runner-user service restart if discovery stalls. Actual XCTest still executes; the existing 12-minute step and 120-second test/destination limits are unchanged. No skip, larger timeout or production UX change is used to manufacture a passing comparison.

The [bilingual remaining-issues handoff](BACKEND_09F49BB_REMAINING_GAPS_FOR_ALI.md) supersedes the prior missing-tier/filter/count/gallery/rejection findings for this source version. Older reports remain historical evidence.

## Physical Android sign-off — not performed here

1. Deploy the intended backend and install the final Flutter build using external protected signing. Use an owned disposable QA VIP clinic; do not publish real clinic contacts, patient information, JWTs, OTPs or signed media URLs.
2. Test a pending/submitted unpublished VIP. Refresh Clinic Media: the private response must carry `subscription_tier=vip`; picker is enabled without relying on public visibility. Switch accounts and repeat; no prior clinic state should remain.
3. Cancel selection; deny gallery permission; select an invalid, oversized and over-duration file; test an unsupported codec. Each must stop safely with one localized error and no false save.
4. Upload a genuine supported ≤15-second/25-MiB video. Check immediate feedback and duplicate-tap protection. Confirm actual binary upload, server acknowledgment, reload, close/reopen and a full process restart.
5. Play, pause and background/foreground the saved clip. Privately verify the actual HTTPS/CDN object, video MIME and range delivery. Separate transport/expiry failures from decoder failures. Then remove it, reload/restart and confirm the cover is preserved.
6. Downgrade the owned QA clinic to Featured/Basic through an authorized Super Admin. Replacement upload must remain denied; existing removal must still work. Never change tier through clinic PATCH.
7. Upload real owned gallery images and a portrait. Open Super Admin review before approval; inspect source-scoped gallery, original expansion, staff/category/status and both themes/languages. Verify unrelated clinic/patient assets never appear.
8. Submit a ready draft, verify server-filtered inbox/count, reject with required feedback, inspect that account activation is unchanged, reopen owner checklist, correct and resubmit, then approve. Exercise stale/409 and incomplete cases; no client success may precede acknowledgment and refreshed state.
9. For account deletion, use a **disposable authorized test account**, purpose-bound OTP and explicit consent. Check invalid/expired code, resend cooldown, permission conflict and session replacement. Confirm successful deletion returns to Login with no private back stack and preserves language/theme/onboarding. Backend referral-PII sign-off remains blocked by the confirmed handoff item.

Safe public-page check on Windows (no authentication or private response):

```powershell
curl.exe --fail --silent --show-error --location --proto '=https' --max-redirs 3 `
  'https://aestheticway.ae/account-deletion/' `
  -o "$env:TEMP\aw-account-deletion-public.html" `
  -w "HTTP %{http_code}; content-type %{content_type}`n"
```

Review the downloaded **public** HTML for bilingual instructions and accurate retention/support information. A 200 page response does not prove authenticated deletion or R2 persistence.
