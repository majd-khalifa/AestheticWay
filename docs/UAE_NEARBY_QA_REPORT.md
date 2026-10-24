# Physical Android QA correction and UAE location readiness

2026-10-24. Existing PR13 / `codex/final-backend-integration-client-preview`, increment from `e87dc682e2a8eff5d8f2cc3dca926b5848569428`.

The corrected reproduction is authoritative: **Upload and save video** triggered the service-unavailable banner. Multi-image gallery upload/delete passed the user's physical Android test. This increment does not diagnose an independent gallery defect. Django and production signing remain unchanged.

## Evidence and release status

| Priority / area | Observed | Source-confirmed / implemented | Live verification |
|---|---|---|---|
| P0 VIP upload | Device local preview worked; save action failed with generic unavailable copy. | Valid real MP4 PATCH/GET works in isolated Django; local storage fault500 reproduced; Flutter save pipeline and error placement corrected. | Actual failing production operation/status, R2 playback and process restart **not verified**. |
| P0 OTP | Sole admin denied; another account obtained challenge but channel/receipt unclear. | Actual API provides no masked destination/channel; UI says so, preserves cooldown/entry; sole-admin has safe portal exit. | Provider delivery/receipt and operational transfer path **not verified**. |
| P1 geography | Two-city discovery controls were hardcoded; Home sent city only. | Reusable seven-emirate→city selector and optional foreground provider; no fabricated distance or location. | Canonical complete backend catalog **missing**. |
| P1 nearest | Endpoints accept coordinates. | Source/probe proves tier-first ordering and incompatible distance units; typed unavailable boundary, honest city-browse fallback. | True distance-first/deduplicated branch results **blocked by server contract**. |
| Gallery/review/lead/preferences | User reports physical PASS. | Existing regressions retained; gallery state independent from video. | Reported evidence only, not rerun on a device here. |
| Privacy/transition gaps | Previous actual-source responses confirmed3 defects. | No newer source remediates received-referral PII, approved rejection or stale notes. | Still require Ali fixes/review. |

No production credentials, reachable disposable account or physical Android/iOS device is available. Managed egress policy does not allow `aestheticway.ae` or its media host. No policy bypass attempted. Backend provenance remains the supplied09f49bb archive; no new deployment inferred.

## Flutter corrections

### Video save transaction

`ClinicMediaScreen._chooseVideo` retains native file/MIME/size/native-duration validation and picker cancellation. `_saveVideo` refreshes authenticated entitlement before the write, locks duplicate taps and submits only `video_ad_file` through `MediaPayloadBuilder`/Dio multipart. `ApiClient.patch` now accepts optional progress/cancellation without changing JWT refresh, no-redirect HTTPS, multipart-boundary or backpressure policy.

`ClinicPortalService.updateShowcaseVideo` validates same-clinic PATCH acknowledgment, remote video and unchanged cover, then requires fresh private profile GET and matching object path/cover/removal state. Signed query tokens may rotate and are not logged. No local media preview or PATCH alone becomes durable success. Service state changes only after verification. A failed/malformed/wrong-clinic/old-video/changed-cover GET retains selection and cannot claim saved.

Typed `ShowcaseVideoFailure` reports upload/acknowledgment/reload/persistence and a safe HTTP status when available. Exact production failure remains unknown: the previous generic English text is also used for500/502/504, not just503. Ambiguous writes require **GET-only** check before explicit resend; acknowledged-but-unverified changes retain an in-memory receipt so recovery never repeats the file upload. Cancel does not assume rollback. New video selection, cover mutation and saved-video removal stay locked during an uncertain write, so GET-only reconciliation cannot discard a newly selected replacement or compare against an independently changed cover. Local discard and playback remain available. Error/status are adjacent to video controls. Gallery cards/queue/error handling are separate.

Cover-as-poster contract is preserved; no new poster field. Basic/Featured cannot gain video entitlement from the UI. A new service instance test is not labeled actual Android process death.

### Deletion

The actual request200 schema contains success/message/expires_in/resend_cooldown only. No guessed profile phone or invented delivery payload was used. Honest channel-unknown feedback, visible resend countdown and six-digit entry remain. Confirmation/400/401/403/409/expiry/session cleanup/logout navigation remain tested. Sole-clinic-admin has localized explanation and actual return-to-portal navigation; backend replacement/closure is a separate release dependency, not faked client capability.

### UAE hierarchy and foreground location

`UaeLocationRepository` separates catalog loading from presentation; bundled compatibility data has seven emirates and15 explicitly partial cities, frontend-stable codes/localized labels/legacy aliases. It is **not a supplied or verified backend canonical catalog** and not “all UAE cities”. No new catalog API is called. `city` continues as source-supported case-insensitive text; canonical ID payloads wait for Ali.

Shared picker replaces Home header, Home manual controls, filter bottom sheet, directory city controls, clinic map editor and Super Admin city selector. Emirate and city save separately (Al Ain belongs to Abu Dhabi). Existing unknown locality text stays visible. Map centers/district shortcuts only reposition the preview and require explicit exact-pin confirmation; they are not auto-saved clinic coordinates.

One Home `PatientLocationController` owns the city/GPS state. `geolocator` low accuracy supports contextual foreground use, denied/permanently denied/off/timeout/clearly outside coverage/manual fallback, duplicate guard and generation-based cancellation of stale work. Raw GPS is not persisted or sent to the current discovery endpoints, and is released on background/logout/account switch/dispose. No cold-start location prompt or background permission. GPS state changes do not repeat unchanged city feed queries. City changes retain350ms debounce, clear old display/flight and use existing pagination20. No reverse-geocoder network call was added.

`NearbyClinicsRepository` is a typed future adapter boundary with explicit unavailable default. Current endpoints are not nearest; no client sort of the first page, km conversions from unit-ambiguous `distance`, invented radius/ordering query or sixth tab. Home uses “Browse clinics…” with locality and See all into the existing filtered directory. Featured placement logic is untouched and remains separate from proximity. The bounded UAE envelope is not country polygon/city proof.

Android foreground coarse/fine permissions, iOS When-In-Use rationale and Always-permission bypass are added. No production signing changes. Store worksheet now describes actual location processing and pending policy deployment.

## Validation and artifacts

- Read-only executable probe: `tool/audit_geo_video_contracts.py`; **11 actual responses passed**, all **405 source files unchanged**. See [sanitized source evidence](uae-nearby-qa/source-evidence.json).
- New regressions: `test/uae_location_qa_test.dart`; video stages/recovery in `test/admin_media_polish_test.dart`; reusable actual HTTP500 render scenario `test/video_save_qa_preview_test.dart`. Existing gallery, entitlement, review, deletion, patient media and startup checks retained. Existing doubles accept new optional progress/cancel parameters.
- `test/clinic_portal_polish_test.dart` now asserts district preview stays unconfirmed until explicit exact-pin confirmation. Deletion navigation test settles/scrolls the actual confirm button after expanded honest feedback. Home payload assertion uses canonical `Dubai` text; backend uses`iexact`.
- [Rendered comparisons and provenance](uae-nearby-qa/README.md): actual Flutter before `e87dc68` versus current output, Light/Dark, English/Arabic, unknown OTP destination, picker and inline video error. Decoded QA fixtures are **not production media**. No existing golden baselines overwritten.
- Full validation result and native run links are recorded in the updated PR13 description / current commit checks. Artifact [file manifest](uae-nearby-qa/CHANGED_FILES.txt) lists this increment; prior reports remain historical evidence.

## Physical Android acceptance matrix — not executed here

Use authorized disposable accounts. Record build/backend commit, OS/device and safe HTTP statuses; never JWT/OTP/phone/patient data or signed URLs.

| Case | Required observation | Status |
|---|---|---|
| VIP draft/submitted/rejected | Select valid device video → local preview → multipartPATCH → same-clinic200 → freshGET same remote object → remote playback | Source/mock tested; device unverified |
| Actual process restart | Force-stop/reopen → privateGET → remote playback, no local preview fallback | Unverified |
| Saved removal | Confirm → JSONnullPATCH → GET/restart shows no video, cover unchanged | Source/mock tested; device unverified |
| Basic/Featured/revoked permission | Picker/write blocked/appropriate server rejection; no tier mutation | Source/mock tested; device unverified |
| Bad/large/long/MIME/codec | Clear video-adjacent failure, nofalse success; selected input/retry as appropriate | Mock/source coverage; hardware codec unverified |
| Cancel/picker denial/background | No invented saved state; one flight; background pauses; ambiguous cancel checked withGET | Automated partial; physical unverified |
| Timeout/400/403/5xx/expiredJWT | Distinguish write vs reload; no repeatedPATCH; retained selection; one failure and read-only recovery | Automated; actual failing deployment unverified |
| R2 | HTTPS video type/byte range206, object survives restart and tenant-correct reload | Unverified |
| Gallery add/delete | Multiple native selections, append, remove exactlyone, reopen/patient display | **User physical PASS**, existing automated non-regression |
| Admin review/lead/preferences | Count/reject/reason/resubmit/approve, lead status, EN/Lightfirstlaunch and persistedchoices | **User physical PASS**, preserved automated regressions |
| OTP successful provider | Reachable authorized recipient, realchannel/mask once contract exists, resend/expiry/badcode, logout | Delivery unverified; frontend/source tested |
| Sole admin | Clear block, real return path; authorized replacement/closure then deletion | Userblock observed; transfer/closure backend dependency |
| GPS | Approximate/full granted, denied/forever/off/timeout, manual supersedes pendingGPS, account switch/background | Provider/widget tested; native device unverified |
| Coverage/manual | Seven emirates, partialcitysearch/aliases, ambiguousDibba distinct; outsidearea truthful fallback | Automated; canonical seed approval pending |
| True nearest | Allapprovedactive, nearestbranch, dedup, stableties/page2/radius/noresults/missingcoords, tier-independent km | **Blocked: source contract absent**, not claimed by fixtures |
| Accessibility | RTL EN/AR, Light/Dark,320dp/largetext, loading/error/retry/nav unchanged | Flutter renders/regressions; hardware screenreader unverified |

Detailed production evidence requests, exact current/proposed contracts and bilingual outstanding dependencies: [handoff for Ali](UAE_NEARBY_QA_BACKEND_HANDOFF_FOR_ALI.md). Passing Flutter tests do not fix the three prior server defects or establish live R2/OTP/proximity delivery.
