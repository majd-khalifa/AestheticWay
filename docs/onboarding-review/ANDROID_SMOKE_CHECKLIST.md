# Physical Android client-preview checklist

**Not executed by this agent.** Use disposable authorized accounts in the intended QA environment. Do not delete a real account, expose credentials, or alter production clinical content. Record build SHA/API host/server commit/time (Asia/Damascus) and sanitized screenshots. Native CI widgets and build compilation do not establish physical-device picker/codec behavior.

- [ ] Empty app store: English + Light, introduction, visible localized Skip; Skip → Login. Reopen/cold stop/start → Login, no repeat slides.
- [ ] Complete slides instead of Skip, then cold restart. Replay if exposed must not reset completion. Validate durable storage error/retry without pretending success.
- [ ] Select Arabic + Dark, sign in; close/reopen and logout; choices remain. Reinstall with retained/cleared storage separately; do not assume iOS Keychain or backups disappear.
- [ ] For Patient, Clinic Admin, Super Admin: sign in, cold launch → own role portal, logout → Login; Android back must not reveal private screens. Test expired/revoked tokens and account switching, including an older user missing the intro flag.
- [ ] Complete the existing approved account-deletion fixture procedure; credentials/routes removed, introduction/preferences not accidentally reset. No navigation loop. Preserve sole-clinic-admin / last-super-admin blockers.
- [ ] Super Admin Dashboard: Category Requests count agrees with server pending count; one tap opens Pending. Approve and reject with reason; count/list/taxonomy refresh. Resume, pull-to-refresh and re-entry update once; simulate network failure (unknown/retry, not fabricated0).
- [ ] Content secondary Category Requests entry works. Patient/clinic accounts cannot access global moderation by navigation or direct requests.
- [ ] Dashboard and Clinics → Clinic Reviews. Clearly see Submitted **loaded** filter, global-count unavailable notice and next-page button. Do not mistake account pending for setup submitted.
- [ ] Open authorized submitted clinic, inspect available fields/media/branches/counts, scroll to approve. Confirm combined setup approval + account activation, double tap safely, reopen/refresh clinic setup → approved. Cancel must perform no POST.
- [ ] Verify rejected fixture status/readiness guidance. **Backend blocker:** no supported setup Reject action/reason/global count; do not simulate this as a completed end-to-end API flow.
- [ ] Home/Clinics/Leads/Content/Insights at five unchanged indexes. Arabic RTL, Light/Dark, narrow phone and increased accessibility text: no clipping or misrouted destinations.
- [ ] Provision a genuinely eligible clinic on the server. Inspect sanitized profile tier (`vip`), then native Gallery video → actual duration/size check → preview → upload → reopen → restart → Patient preview where publicly exposed. Record actual HTTPS/CDN result; never paste tokens/phone/patient data.
- [ ] Noneligible clinic: deliberate explanation + disabled selection, no fabricated entitlement. Existing video after downgrade can be removed with confirmation; replacement cannot upload. Wrong server entitlement produces a clear localized failure.
- [ ] Gallery multiple images: select real files → upload progress → failure/retry remaining files → save/reopen/restart → Patient display; deleting one preserves others. Independent cover remains an image; never feed MP4 to an Image widget.
- [ ] Preserve approved Patient design, lead-only consultation, exact Arabic confirmation, My Requests refresh, five Patient tabs, absence of regulatory identifiers and subscription marketing.

Existing patient consultation → My Requests → Clinic Portal → Contacted/Closed is owner-reported physical evidence from an earlier build, not proof that these new screens have been exercised on this build.
