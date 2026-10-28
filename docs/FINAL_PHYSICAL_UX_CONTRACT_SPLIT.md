# Physical UX contract split — inspected before implementation

2026-10-26 · starting frontend `f20ab75ed5e0be5148771b104e9c3ac5d6b2b73c` · PR13 · read-only backend465bf30. No production code had been changed when this mapping was written.

| Concern | Existing source contract / defect | Implementation boundary |
|---|---|---|
| Featured video | Carousel has an independent4s periodic timer; player loops and seeks at15s without notifying the carousel | Coordinate player states and one-shot slide timer. Hold during initialization/buffering/play/pause; advance once on completion/15s, never on user pause. Keep manual interaction, reduced motion and lifecycle cleanup. |
| Patient profile | Public approved-clinic detail exposes `video_url`/`video_ad_file`, already parsed; profile only mounts photo gallery | Render an opt-in bounded public video only after a fresh successful matching public detail response. Preserve gallery, branding and all existing actions. |
| Weak-network upload | Correct multipart PATCH `clinic-portal/profile/`, `video_ad_file`, global30s connect/60s send/60s receive; strict ACK+GET already exists | File-only endpoint options, not global changes. Default25MiB at512kbit/s≈410s plus70s margin→480s send;120s receive; configurable bounded compile-time budgets. No automatic body replay, including after auth refresh. Preserve uncertain-state read-only reconciliation. |
| Google selection | Authenticated POST `{autocomplete,details,link,unlink}/` beneath `clinic-portal/profile/google-business/`; autocomplete reads only query/session_token/language_code; Details returns one requested-language formatted_address plus locality/emirate_code/AE/coords/proof | Reuse endpoints. Explicit optional city text context in query is not API geographic bias. Keep proof and identity confirmation. Offer separately confirmed pin adoption with fresh private profile acknowledgment/reload; never write Google identity through general PATCH. |
| Entrance/address | OSM/Nominatim explicit address search currently moves only the marker; no address prefill; manual map accepts worldwide bounds | Parse actual returned localized/address component data, confirm overwriting edited fields, reject outside-UAE coordinates/city conflicts. Google content stays on attributed detail panels/external Google Maps, never OSM. For a linked Google identity, entrance correction uses independently entered coordinates/external Google inspection until a keyed Google renderer is approved. |
| Localized details | Backend has no atomic EN+AR address or authenticated reverse-geocode/provider-proxy contract; no production Nginx/Gunicorn timeout config is in archive | Do not invent fields/endpoints or translations. Preserve unavailable language as blank/editable for review. Write one bilingual Ali handoff for precise missing contracts and deployment checks. |
| Nearby/filter | Server gives ordered distance_km for GPS, null for manual browsing; source public eligibility/nearest-branch/pages verified; existing UI has plain distance text | Add localized visible distance badges and origin heading, maintain server order and null suppression; safe-area/card actions and premium selection/filter hierarchy. No area centroid or unsupported area request. |

Owner-reported physical Android PASS: video upload/restart/play/delete/cover preservation, live Nearby eligibility/order, bilingual locality selection and real Google linking. OTP receipt remains **unverified**. New automated tests/renders are separate evidence.

Policy references checked2026-10-26: [Google Places policies](https://developers.google.com/maps/documentation/places/web-service/policies), [Nominatim usage policy](https://operations.osmfoundation.org/policies/nominatim/). Places content shown with a map requires a Google map; limited-space text attribution remains Google Maps. Existing deliberate OSM address search stays explicit, rate-limited and attributed; production aggregate limits/provider switchability need a server proxy, not per-device throttling claims.

## Post-policy implementation decision

The table above recorded the initial plan, not a promise that every proposed
backend capability existed. Further review of [Maps Service Specific Terms,
§14.2–14.3](https://cloud.google.com/maps-platform/terms/maps-service-terms)
identified the no-non-Google-map restriction and maximum30-day temporary caching
of Places coordinates. Backend465bf30 has ordinary durable clinic coordinates,
without source/expiry tracking or a separate proof-bound pin-adoption contract.
Therefore **Google-coordinate adoption was not implemented**. Google inspection
and explicit proof-bound identity linking remain usable; the owner may edit an
independent entrance on the existing OSM editor. Google response coordinates
are never copied into that map or silently persisted as manual coordinates.
The earlier numeric-only-linked-editor proposal was also not used: linking
does not remove a working independent manual editor. Exact proposed backend
requirements are in [the new bilingual handoff](FINAL_PHYSICAL_UX_BACKEND_GAPS_FOR_ALI.md).
