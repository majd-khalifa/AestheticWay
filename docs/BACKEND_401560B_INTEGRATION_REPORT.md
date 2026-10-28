# Backend401560b integration and QA

2026-10-25 · existing PR13 · `codex/final-backend-integration-client-preview` · frontend baseline `5bdfc27c1c093775bcd553142dcb29646573329c`.

The supplied archive comment identifies **401560bdb06bd739f74eb42a88c68fc748e43dbb**. Its410 source files were compared with09f49bb before integration and remain byte-identical after the audit. Django/native signing were not modified. Ali's report describes693 backend tests and deployed video/R2/proxy checks; those are **engineer-reported evidence**, not independent production/device verification by this task.

## Contract decisions

| Contract | Actual401560b source | Flutter result |
|---|---|---|
| Google autocomplete | POST `clinic-portal/profile/google-business/autocomplete/`; JSON `query`, UUID `session_token`, `language_code`; response **`suggestions`**, not report's `results` | Enabled authenticated adapter;350ms debounce,2–120 characters; actual main/secondary text; no name-based auto-link |
| Place details | POST `.../details/`; `place_id`, same session token/language; `display_name`, address, coordinates, country, URL, opaque `selection_proof`, `proof_expires_in:300` | Exact-ID/UAE/coordinate validation; explicit selection/confirmation; local proof deadline; no proof persistence/logging |
| Link/relink | POST `.../link/`; proof+Place ID+`expected_current_place_id`;200 full private profile;400 invalid/expired/reused proof;409 stale association | Dedicated POST only; exact Details maps URL avoids server retaining old URL; validate selected-place acknowledgment then fresh private GET; uncertainty blocks replay until refresh |
| Unlink | POST `.../unlink/`; expected current ID; blank identity/URL, cleared ratings/cache/status | Replaces old generic PATCH clear with atomic source contract; confirm; fresh GET; no pin/media fields sent |
| Link state | Read-only `google_link_status`: unlinked / linked_verified_place / pending_review / rejected; separate `google_sync_status` | Accurate state mapping; “selected place verified” explicitly **does not prove Google Business Profile ownership**; ratings sync never establishes ownership |
| Catalog | Three GETs `locations/emirates/`, `locations/cities/`, `locations/areas/`; actual responses are **bare lists** | Server-loaded searchable7-emirate /23-city /50-area snapshot; stable codes, bilingual labels, parent validation, bounded paginated-envelope compatibility; foreign next URLs never followed |
| GPS nearby | GET `clinics/nearby/`; requires both coordinates, `radius_km`, numeric pages; Haversine `distance_km`, nearest branch ID, tier-independent order | Transport implemented/tested; **production query remains gated because actual source exposes active draft profiles** |
| Manual nearby | GET `home/nearby-clinics/?city=...`; no coordinates means null distances; source slices queryset to10 | Adapter preserves null distance; no guessed city center, invented area filter or claim of full pagination |
| Home feed | `home/feed/` supports `nearby_clinics`; proximity path differs from manual tier-ranked browse | Existing sponsored/browse UI preserved. No newly enabled GPS feed that would bypass the same source eligibility gap |
| VIP video | PATCH private profile; actual multipart field `video_ad_file`; freshGET; JSON null removal | Existing ACK→freshGET→persistence receipts retained. Added localized400/403/413/429/5xx/timeout advice; selection preserved; no automatic repeat multipart |
| Deletion OTP | POST `auth/me/deletion/request/`; channel/masked destination/**actual deliveries**/expiry/cooldown | Prefer real successful-delivery entries; fallback only to supplied masked top-level fields; unexpected raw contacts suppressed; request acceptance never promises delivery |
| Sole administrator |400 `SOLE_CLINIC_ADMIN` + allowlisted `resolution_options`; explicit deactivate or transfer POST | Typed confirmation+consent for clinic suspension; explicit existing-member UUID+consent to appoint another admin; no automatic clinic/account mutation; require authoritative ACK |
| Account confirmation | Existing OTP confirm contract and refresh-token cleanup | Prior invalid/expired OTP, stale-session, private-cache/token cleanup and acknowledged-deletion navigation tests retained |

Paths above are relative to `/api/v1/`. Generic profile PATCH no longer assigns arbitrary non-empty Place IDs in the new source. Flutter does not use generic PUT as an alternative. Current server **PUT bypass** and staff-mutation permission defects are detailed in the handoff.

## Implementation boundaries

- Clinic Profile → Location & Google Business now uses actual server search/details/link/unlink. Real suggestions only; no fixture data enters production. Existing350ms debounce/UUIDv4 session lifecycle and logout/language/stale-response guards remain. Details terminates the autocomplete session. Local3-minute search-token cap is application policy, not Google's advertised TTL.
- Both manual-pin save paths continue omitting `google_place_id` and `google_maps_url`; shortcuts move the preview but require an explicit exact-pin confirmation. OSM is still clearly manual and never displays Places content.
- Server catalog is used from Home, directory filters, clinic onboarding/profile and Super Admin editing through the shared picker. Historic free-text names/addresses remain readable; Al Dhannah maps to source code `ruwais`. The backend has no persisted area FK/filter, so explicit area selection remains part of editable address text and unsupported area filtering is disclosed. This curated server snapshot is not advertised as a complete UAE gazetteer.
- Nearby remains a Home route, never a sixth tab. Its transport preserves server order, nullable manual distances, branch identity and numeric pagination. A nearest-branch ID without coordinates never becomes a misleading HQ map pin/direction. Existing foreground consent, denied/revoked/background/logout behavior remains. The default adapter cannot query until a supplied backend revision closes approved/public visibility.
- Sole-admin “transfer ownership” actually **promotes another current member while retaining the caller as admin**. UI says so. No source-backed member-list endpoint exists; the dialog accepts an explicitly obtained existing-member UUID and does not invent a directory. Deactivation suspends the clinic; it does not delete an account or promise client-side reactivation.
- Google attribution uses the official compact text alternative in narrow mobile result panes, with an untranslated single-line14sp sans-serif400 black/white treatment and source separation. Details carries attribution within its card. No third-party attributions absent from the supplied server response are invented. Public app Terms/Privacy must accurately incorporate Google usage before store release; see handoff.

## What changed since09f49bb

Source now contains the four Places(New) routes, proof/CAS checks, read-only link state and migration0010; catalog endpoints and source data; real Haversine nearby; OTP delivery metadata; sole-admin resolution routes; file rewind/fresh-profile video handling. Source/tests also address incoming referral PII cleanup, invalid reject transitions and stale review notes on resubmission. Previous reports are retained as historical evidence and linked to this replacement; their earlier blanket “no endpoints”/“no OTP destination” limitations are superseded.

## Verification

- [Source evidence](backend-401560b-qa/source-evidence.json): **25 actual isolated API responses**. Local SQLite, mocked Google transport, temporary storage; no production/Google/R2/OTP traffic. Confirms actual keys/shapes, manual pin preservation, direct PATCH rejection, CAS, expired/replayed proof rejection, valid video bytes, a new authenticated-client reload and cover/gallery-preserving deletion. Also reproduces staff mutation, generic PUT bypass, draft exposure and manual top-ten limit.
- **40 relevant Django tests passed independently** (new P0/P1 remediations + Places sync); original source tests were not edited and this is not a rerun/endorsement of Ali's full693 claim.
- Added30 Flutter regressions covering wire contracts, proof expiry/reuse/stale state, server catalog hierarchy/pagination, nearby distance semantics, OTP destinations, safe error metadata, explicit clinic exit, video feedback, EN/AR and Light/Dark. Full-suite and native results are recorded in [verification](backend-401560b-qa/verification.json) and the updated PR13 body.
- [Actual rendered previews](backend-401560b-qa/README.md) use clearly disposable test data, not live search/device screenshots. No old golden baselines were overwritten.
- [Exact changed-file manifest](backend-401560b-qa/CHANGED_FILES.txt).

## Native maps assessment and limits

No SDK keys are configured/provided. Existing safe external exact-Place-ID/confirmed-coordinate navigation remains; there is no claim of a functional embedded Google Maps renderer. Public package metadata retrieved for this audit: latest `google_maps_flutter2.19.0` requires Dart3.13/Flutter3.47, beyond pinned3.11.3/3.41.5. Candidate2.13.1 supports this Dart/Flutter toolchain, but inspected iOS implementation2.15.5 requires iOS14 and Google Maps8.4–9.x; app minimum is13. Current native configuration/dependency lock/signing were preserved. A separately reviewed minimum-OS/dependency decision and restricted Android/iOS keys are needed before enabling embedded maps.

Sources: [Places attribution policy](https://developers.google.com/maps/documentation/places/web-service/policies), [plugin metadata](https://pub.dev/packages/google_maps_flutter), [candidate iOS implementation](https://pub.dev/packages/google_maps_flutter_ios/versions/2.15.5).

**Not independently verified:** deployment commit/migration, Nginx30M/120s configuration, live Google suggestions/details, proof replay across production workers, actual SMS/email delivery, physical restart/playback, HTTPS R2 Range206 or store-signing credentials. Physical gallery upload/deletion and consultation/status flows remain previously **user-reported PASS**; the video failure was after **Upload and save video**, not gallery refresh. No new gallery defect is asserted.

Remaining source/configuration dependencies and exact physical QA steps: [bilingual handoff](BACKEND_401560B_REMAINING_GAPS_FOR_ALI.md), [physical Android checklist](backend-401560b-qa/PHYSICAL_ANDROID_QA.md). PR13 stays open; no store publish or merge.
