# Google Business, locality hierarchy and nearby frontend readiness

> Historical09f49bb snapshot. Superseded for current contracts by [401560b integration report](BACKEND_401560B_INTEGRATION_REPORT.md) and [remaining verified gaps](BACKEND_401560B_REMAINING_GAPS_FOR_ALI.md),2026-10-25. Earlier missing-endpoint/OTP-destination and tier-order findings below are not claims about the new source.

2026-10-24 · existing PR13 / branch `codex/final-backend-integration-client-preview` · baseline `52dbc041a86a5eda0aa01c938aa410294a37558d`.

## Audited existing pieces and changes

| Area | Existing | Implemented in this increment | Still unavailable |
|---|---|---|---|
| Maps | Manual OpenStreetMap pin preview/editor and vetted Google Maps links | Clear provider/identity separation; manual navigation only from confirmed coordinates | Embedded Google Maps SDK/renderer and restricted client keys |
| Google identity | Private `google_place_id`, URL and server Places(New) ratings sync | Clinic-only association review, sync state, safe confirmed clear, fresh-GET verification, isolated search/details/link interfaces and frontend verification states | Real autocomplete/details/link proof/ownership/CAS contracts; no non-empty Place ID writes enabled |
| Localities | Seven emirates / partial15 cities | Searchable city→area stage,9 partial areas, parent validation, aliases, reusable picker and preserved legacy city/address fields | Authoritative complete catalog, canonical backend IDs/area filters/migration |
| Nearby | Foreground permission and unavailable query boundary | Home map/list route, permission revocation/background handling, paged query state, server order/reference validation, closest-branch map interface | Actual distance-first/eligible/deduplicated server contract and live map renderer |

No new Google/nearby/catalog HTTP endpoints were invented or activated. Current association read/clear uses existing source-confirmed clinic profile GET/PATCH only. Google Maps universal links remain actual user-triggered platform navigation, not business linking or a guessed match.

## Google Business workflow

Clinic Profile → **Location & Google Business** → review the stored association. The UI distinguishes stored identity, unavailable ownership verification, ratings sync pending/synced/failed, loading and error. A successful rating sync never proves ownership. The future typed verification states pending/verified/rejected are **not parsed from invented backend JSON fields**.

The current supported clear operation requires confirmation, current-clinic/expected-ID pre-read, exact empty-string PATCH and matching private GET. It does not send name/contact/pin/media fields. Uncertain writes block subsequent mutation until refresh; no automatic replay or optimistic “verified” result. Generic PATCH lacks CAS, so source-concurrency protection remains an explicit backend gap.

The production search field is honestly disabled. Its repository/controller supports350ms debounce, real suggestion IDs/addresses, one UUIDv4 Autocomplete session shared through Details, retirement on terminal selection/cancel/empty query/dispose/session/language change and a local3-minute token cap. Names never auto-select or link. A future result must match the chosen Place ID, valid coordinates/UAE coverage/country and a server proof; explicit human confirmation is required before a permitted link call. It still requires server authorization/ownership policy. No private API key or provider diagnostics are displayed/logged.

An injected renderer can later show the exact selected place through approved Google Maps SDK credentials. Today the UI says embedded Google Maps is unconfigured and can open the exact Place ID externally. It never paints Google Places content on OSM or presents a fake map/search result as production.

## Manual pin and three-level compatibility

Both clinic profile location-save paths now omit Google identity and business URL. Editing a reception/entrance pin cannot silently relink a business. The existing OSM map remains labeled as manual. City/area shortcuts only reposition the map preview; an exact pin must be confirmed before save. Manual navigation requires valid stored coordinates, without falling back to a similar clinic name.

The reusable picker supports **Emirate → City → Area** plus whole-city selection, search, partial-catalog/empty/error/loading states, localized labels and stable frontend codes. It is used from Home header/manual controls, directory/filter sheet, clinic onboarding/profile location editor and Super Admin clinic editor. Invalid city/area combinations fail validation. Locale affects labels, not identity. Existing addresses are preserved; explicit area selection can be added to editable localized address text. No unsupported area FK is sent to Django.

Home/directory continue source-supported city filtering and tell users when a chosen area cannot yet be applied as a server filter. No silent fake area-specific or nearest result. GPS is optional, foreground-only, held in memory and released on background/logout/account switch. Revoked permission clears the location without another forced prompt.

## Nearby map/list preparation

The new Home entry opens a route with list/map modes; the five bottom tabs remain unchanged. Default repository is unavailable and does not call HTTP. Manual fallback opens the existing city directory. A supplied future adapter may provide all eligible clinics and confirmed closest-branch coordinates; pages retain server order and deduplicate clinic IDs. Invalid/unknown distance reference, a device reference without device coordinates, descending distance or inconsistent later-page references stays an error. No sorting of the first page, inferred kilometres or paid-tier proximity boost.

Distance labels identify device versus selected-locality origin. Query changes invalidate old data/reference immediately; stale responses after manual selection, logout/background/dispose cannot repopulate results. Pagination remains20 with duplicate-load guards and existing retry behavior. The Google map surface is injectable; until configured it explains the limitation and offers vetted navigation for genuine returned branch coordinates. No fabricated marker, city center, rating, clinic or map tile is invented.

## Evidence, verification and limitations

- Source archive remains09f49bb; [7 isolated source responses](maps-business-readiness/source-evidence.json), **405 source files unchanged**. The probe confirms current manual-pin preservation and blank-clear/cache reset, permission denial, and the unverified non-empty Place ID write gap. These are not production/Google/R2 calls.
- `test/google_business_readiness_test.dart` covers explicit identity/proof, token lifecycle/debounce, error/uncertain write and fresh GET, role/session isolation, full manual editor save, separate verification/sync states and320dp/180% layouts.
- `test/nearby_locality_readiness_test.dart` covers three-level parents/search, permissions/revocation, no-call unsupported adapter, Basic-before-VIP server order, reference validation, dedup/pagination, stale/background/session behavior and RTL/themes.
- Existing Clinic Portal staff/treatment/navigation test now scrolls to each lazy section and checks the explicit manual-pin navigation label. No assertions/skips were removed. All prior video/gallery/review/category/consultation/privacy/startup regressions remain.
- [Actual Flutter renders](maps-business-readiness/README.md) use clearly disposable fixtures for future adapters; they are not evidence of a working live Google service. No generated business photos or fabricated production data were added.
- Final local analyzer/test counts, formatting/diff verification and exact changed-file manifest are in [verification](maps-business-readiness/verification.json) and [manifest](maps-business-readiness/CHANGED_FILES.txt). Exact-head native checks are linked in the updated PR13 description.

Backend/source/native-key dependencies and precise contract requests: [bilingual handoff for Ali](GOOGLE_BUSINESS_LOCALITY_NEARBY_BACKEND_HANDOFF_FOR_ALI.md). No physical Android/iOS Google search, embedded SDK, production catalog or nearby-service verification occurred. Source/deployment limitations are not marked resolved by fixture tests. Django and production signing are unchanged. PR13 must remain open and unmerged.
