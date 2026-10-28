# Physical Android QA —401560b integration

2026-10-25. **Checklist, not a claim that device checks were performed.** Use authorized disposable patient/clinic-admin accounts and an eligible VIP clinic. Keep production patients/credentials out of screenshots and reports. Never delete a real operational account to test this flow.

Record frontend SHA, app version/build, device model/Android version, deployed backend SHA/migration and sanitized HTTP status/route/UTC timing. Never paste access/refresh tokens, session/proof tokens, OTPs, phone/email, patient data or full signed media URLs.

| Journey | Required physical result | Evidence status here |
|---|---|---|
| Existing multi-image gallery add/remove | Existing gallery loads; add/delete persist after reopen; independent of video | Prior **user-reported PASS**, not rerun by this agent |
| Google exact-business search | Authorized clinic admin searches AR/EN; actual Google suggestions/address; same session through Details; no match by resemblance | Source/wire/UI tested; real provider **unverified** |
| Google confirmation | Compare real name/address/Place ID/map externally; explicit checkbox; link200, fresh profileGET200, `linked_verified_place` label says selected place only, not ownership | Source/wire/UI tested; physical **unverified** |
| Proof/CAS | Wait beyond actual proof TTL, try expired selection; no fake success; select again. Concurrent link/unlink returns409; refresh before another mutation. Never replay a consumed proof | Source expiration/replay/CAS reproduced; production multiworker **unverified** |
| Unlink/manual pin | Confirm unlink; ratings clear; gallery/cover/video/pin unchanged. Manual pin change never relinks Google. Reopen/restart then verify | Source/local tests; physical **unverified** |
| VIP video select/cancel | Genuine short H.264 MP4; cancel picker leaves state safe; basic/featured do not gain upload entitlement; submitted clinic uses real private tier | Existing regressions/source; physical **unverified** |
| VIP upload | Select → preview → Upload and save video → actual multipartPATCH200 → fresh authenticated profileGET200; same clinic and remote object; do not infer success from local preview | Local genuine MP4 byte persistence passed. Ali reports production200/200; **not independently live-verified** |
| Video restart/play | Force-stop without clearing app data; reopen; freshGET; saved remote video appears and plays. Check HTTPS type/video and Range206 through authorized operator | Ali reports R2 Range206; agent physical/R2 **unverified** |
| Video errors |400 constraints;403 permissions;413 proxy body limit;429 cooldown;5xx/timeouts retain safe selection and require verification before repeat. No duplicate tap/retry loop | Automated feedback/receipt tests; physical/server fault injection **unverified** |
| Video removal | Explicit removal → JSON null PATCH200 → freshGET; restart; no video, same cover and pre-existing gallery | Actual local source null removal preserves cover/gallery; physical **unverified** |
| OTP destination | Request deletion on disposable account; actual SMS/email masked destination(s), no raw contact/guessed delivery; resend cooldown; provider failure honest | Source fields and Flutter UI tested; actual delivery **unverified** |
| Sole clinic administrator | No automatic suspension/transfer. Cancel does nothing; typed confirmation+consent suspends only after ACK. Explicit existing member UUID+consent appoints admin while caller remains admin | Source routes and Flutter confirmation tests; physical **unverified** |
| Confirm deletion | Bad/expired OTP keeps inputs/account; valid acknowledged deletion clears session/private caches and returns login; new account/session cannot be cleared by old response | Existing regression suite retained; real deletion **unverified** |
| Canonical locality | All seven emirates;23 cities/50 curated areas for supplied snapshot; distinguish both Dibbas; Ruwais/Al Dhannah compatibility; parents reset correctly in Home/directory/onboarding/profile/admin | Source-backed catalog/wire/UI tested; production catalog **unverified** |
| Nearby | **Blocked pending server approval filter.** Do not claim activation or label city lists geographically nearest. After supplied fix, test Basic-before-farther-VIP, dedup/nearest branch/page2/null manual distance | Source draft exposure reproduced; new adapter disabled |
| Preferences/portals | Fresh English/Light; save AR/Dark, restart; five patient tabs, lead-only success text, roles isolated; Clinic/Admin workflows retain behavior | Full regression/native CI evidence in PR; physical this increment **unverified** |

Maps SDK keys/embedded renderer are not configured. Google Place content is not displayed on OpenStreetMap. External Google Maps opens the exact verified Place ID or explicitly confirmed stored coordinates. Nearest branch ID alone is not a navigable coordinate.

For safe video evidence, report only: preflight/PATCH/freshGET HTTP statuses, `same_clinic`, `same_object`, video present/absent, cover/gallery unchanged booleans, size/duration/codec and Range status/type. Server operators should correlate a sanitized request ID and timestamp with Nginx/Gunicorn/storage logs without sending log bodies or secrets.
