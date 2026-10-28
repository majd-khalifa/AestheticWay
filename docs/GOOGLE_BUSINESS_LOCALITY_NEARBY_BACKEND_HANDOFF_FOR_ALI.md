# Google Business, canonical localities and nearby — handoff for Ali / تسليم لعلي

> Historical09f49bb snapshot. Superseded for current contracts by [401560b integration report](BACKEND_401560B_INTEGRATION_REPORT.md) and [remaining verified gaps](BACKEND_401560B_REMAINING_GAPS_FOR_ALI.md),2026-10-25. Earlier missing-endpoint/OTP-destination and tier-order findings below are not claims about the new source.

2026-10-24 · PR13 `codex/final-backend-integration-client-preview` · supplied source **09f49bbd22131f6dad49a65a5167de5396f03797**. No later committed/deployed contracts were provided. Django is read-only. Items below marked proposed are **not live endpoints or implemented Flutter HTTP adapters**.

## 1. Verified current contract / العقد الحالي المؤكد من المصدر

`GET/PATCH /api/v1/clinic-portal/profile/` uses `ClinicProfilePortalSerializer`, `ClinicProfileAPIView` and `IsClinicPortalAccess`. `google_place_id` and `google_maps_url` are writable fields; ratings/count/sync fields are read-only. `Clinic.save()` clears stale ratings/count/timestamp/error and resets sync state when Place ID changes. The source backend uses Places API(New) only for periodic `rating,userRatingCount` synchronization; there is no authenticated autocomplete/details/verified-link workflow in the supplied URL configuration.

**Current supported unlink payload**:

```json
{"google_place_id":"","google_maps_url":""}
```

Empty strings are intentional: these are blankable string fields, not nullable image fields. Flutter verifies the current clinic/expected old Place ID before PATCH, validates acknowledgment, then requires a fresh private GET with the same clinic and empty Place ID. No retry loop or optimistic linked/unlinked success. Manual pin, clinic description, cover, video and gallery are omitted from that PATCH.

**Independent source evidence:** [7 actual isolated API responses](maps-business-readiness/source-evidence.json) demonstrate profile read, manual coordinate PATCH preserving Google identity/URL, unlink/cache reset, fresh read, role denial and anonymous denial. Another source probe within those7 confirms a generic PATCH accepts an unverified non-empty Place ID. All **405 source files unchanged**. SQLite/temporary storage/synthetic identities; no production, Google or R2 traffic.

**عربي:** المصدر يدعم قراءة الارتباط ومسحه بالحقول الفارغة أعلاه. تعديل الدبوس اليدوي لا يرسل معرّف Google أو رابط النشاط. التحقق تم محلياً على نسخة المصدر، وليس إثباتاً للنشر أو ملكية نشاط حقيقي.

## 2. P0 — Protect Place identity and provenance / حماية هوية النشاط

**Confirmed gap:** generic clinic profile PATCH accepts an arbitrary non-empty `google_place_id` with no Google lookup, selected-result proof or ownership verification. A pending/successful ratings sync is **not** business ownership verification. The new Flutter search/link capabilities remain disabled by default; it never sends a typed business name as a linkage identity or derives the Place ID from name similarity.

Ali must define a server-owned linkage workflow before enabling autocomplete/link/relink:

- Authenticated clinic administrator with active membership, same-clinic tenant binding; define staff/super-admin permissions separately rather than borrowing clinic-scoped privileges. Pending/unpublished clinic rules must be explicit.
- Prevent unverified non-empty Place ID writes through generic profile PATCH. Preserve a compatible blank-clear path until a replacement unlink action is deployed and its contract supplied to Flutter.
- Fetch/validate the selected Google Place ID server-side; validate country/coordinates and exact selected result. Name resemblance alone never grants authorization. Bind a short-lived selection proof to authenticated user, clinic, Place ID and intended action; make it single-use and verify expiry/replay. Do not trust client-provided ratings/name/address/coordinates as canonical proof.
- Define what “verified” actually means. Places public data can establish that a business exists, **not that the caller owns its Google Business Profile**. Use documented platform review/attestation, or an approved Google Business Profile authorization/ownership process if ownership proof is required. Keep Google OAuth/server credentials on the server.
- Return a distinct **association verification state** and evidence/review policy. Do not reuse `google_sync_status`: existing values `not_configured/pending/synced/failed` concern ratings synchronization only. Flutter's future verification enum is not mapped to an invented JSON field.

**عربي:** قبول معرّف غير فارغ عبر تعديل الملف العام بلا إثبات اختيار ثغرة مؤكدة في التحقق. يجب ربط الإثبات بالمستخدم والعيادة والمكان ومنع إعادة استخدامه. وجود النشاط في Places أو نجاح مزامنة التقييم لا يثبت ملكية Google Business. يلزم تعريف منفصل لحالة مراجعة الارتباط، دون اعتبار تشابه الأسماء أو مربع موافقة المستخدم دليلاً خادمياً على الملكية.

## 3. Proposed Places(New) contracts — URLs/methods still required from Ali

No route names below are guessed or called. Ali must supply the actual URLs, methods, serializers, permissions, response/error envelopes and deployed source commit.

| Operation | Required request semantics | Required response semantics |
|---|---|---|
| Autocomplete | Unicode business query; language `ar/en`; UUIDv4 session token; same-clinic authorization; UAE country restriction; bounded rate/quota/query length | Real Google Place IDs, display/structured main text and formatted secondary/address text; attribution requirements; genuine empty/error result |
| Place details | Selected Place ID and **same Autocomplete session token/project**, language | Exact same ID; display name; formatted address; normalized locality/country; actual coordinates; vetted Google Maps URI; server-issued selection proof/expiry |
| Link/relink | Place ID + valid proof, expected old association/revision; authenticated tenant | Atomic acknowledgment and authoritative association; separate verification/sync states; documented pending/rejected behavior; subsequent private GET |
| Unlink | Expected current Place ID/revision, authenticated tenant | Atomic clear and cache invalidation, preserved manual pin/media; fresh profile read; explicit conflicts |

Use Google **Places API(New)**, not legacy Find Place/Text Search as a substitute for Autocomplete. Suggested minimum Details mask for this UI: `id,displayName,formattedAddress,location,googleMapsUri,addressComponents` (components only for locality/country validation). Trim further if a normalized backend contract makes components unnecessary. Do not request `*`, reviews, photos, phone or website for this linking screen. Rating sync remains the existing separate minimal mask `rating,userRatingCount`.

Flutter already debounces350ms; issues a random UUIDv4 token per session; shares it across query refinements and terminal Details; retires it after selection/details, cancel, empty query, screen/session replacement and language switch. A **local3-minute token cap** avoids indefinite reuse; it is application policy, not a claim about Google's service expiry. Align server TTL/billing lifecycle and project/key ownership. Expired/failed Details starts a new selection session, never automatic paid requests or retries.

**عربي:** زودنا بالمسارات الفعلية والحقول والأخطاء قبل تفعيل الاستدعاءات. جلسة Autocomplete تستخدم رمزاً عشوائياً واحداً حتى Details ثم تُنهى؛ لا يعاد استخدامه بعد الإلغاء أو تغيير الحساب/اللغة. البحث الحقيقي والتفاصيل والإثباتات تبقى خادمية. لا نطلب صوراً أو مراجعات أو حقولاً غير لازمة.

## 4. Atomicity and truthful refresh / الذرية والتحديث الصادق

Current unlink has a frontend pre-read/check and post-write verification, but the existing generic PATCH has **no server CAS/revision guard**. A concurrent update can race between read and clear. Do not describe this as server-atomic protection. Future link/relink/unlink must lock/check the expected association or revision transactionally and return a documented409 on conflict; double submit must be idempotent or rejected safely. After an uncertain write Flutter requires refresh before another write; it never assumes a timeout rolled back.

Define safe400 invalid/expired proof,401 expired session,403 role/tenant,409 stale association/incomplete review,429 quota/Retry-After and provider/network failures. Do not expose API keys, proof/session tokens, signed links or private provider diagnostics in response messages/logs.

**عربي:** فحص Flutter قبل وبعد الطلب لا يغلق سباق التزامن في الخادم. يلزم قفل/إصدار للارتباط واستجابة409 واضحة. لا تعتبر المهلة تراجعاً تلقائياً ولا تعرض نجاحاً قبل القراءة الجديدة.

## 5. Seven emirates → cities → areas / الإمارات والمدن والمناطق

The current app has seven stable frontend emirate codes, **15 partial cities and9 partial areas** reused from the existing location editor. These are compatibility identifiers, **not backend foreign keys or a complete UAE catalog**. Cities and areas remain separate; e.g. Jumeirah is an area of Dubai, Al Ain is a city of Abu Dhabi, and the Dibba municipalities are distinct.

Ali must supply:

1. Reviewed authoritative catalog and source/version, stable IDs/codes, parent relationships, localized names and aliases, pagination/cache/ETag policy and inactive/migration behavior. Define full-city/all-area selections and distinguish “unknown” from a fabricated area.
2. Migration from existing case-insensitive `city`/`emirate` text and historical spellings/Arabic variants/renamings. Do not silently break existing clinic records or locale-independent identity.
3. Actual filters and clinic/branch write fields for canonical emirate/city/area IDs. Until supplied, Flutter sends only supported **city text** in discovery filters and clearly says area filtering is not active. Clinic/admin editors may prepend explicitly selected area text to editable localized addresses while preserving existing address content; **no unsupported `area_id` is sent**.
4. Address/area changes must never invent coordinates, auto-confirm an emirate center or change the linked Place ID. Optional copy-from-business to manual pin needs an explicit separately confirmed action/contract, not silent coupling.

**عربي:** القائمة الحالية جزئية وليست كتالوج الإمارات الكامل. مطلوب معرفات خادمية ثابتة وعلاقات صحيحة وترجمة وأسماء بديلة وخطة ترحيل. حالياً الترشيح الفعلي حسب المدينة فقط؛ اختيار المنطقة لا يُقدَّم كترشيح خادمي ناجح. عناوين العيادة تبقى نصوصاً قابلة للمراجعة ولا تُخترع إحداثيات أو يتغير ارتباط Google تلقائياً.

## 6. Genuine nearby / الأقرب فعلياً

The supplied discovery endpoints remain **tier-first**, not nearest-first. `distance` is metres on PostGIS but squared degrees on SQLite; branches are not nearest-branch deduplicated. See [existing UAE handoff](UAE_NEARBY_QA_BACKEND_HANDOFF_FOR_ALI.md). No new source was supplied to supersede that evidence.

Future contract must specify all approved+active+visible clinics regardless of tier; confirmed eligible branch coordinates; closest branch per clinic; deduplication **before pagination**; true distance-first stable ties; explicit server `distance_km`; radius/coverage/no-result validation; max20/page; noN+1 and location-aware cache invalidation. A manual-locality query needs an explicit verified origin/reference and distance label “from selected locality”; it cannot imply distance from the patient. Unknown units/reference or descending distance responses are rejected, not sorted locally and renamed nearest.

Flutter's nearby screen is an existing Home route, **not a sixth tab**. It has list/map states, contextual foreground permission/manual fallback, stale query/session/background guards and retained server order/pagination. Default adapter is **unavailable and emits zero HTTP calls**. Fixture-only data demonstrates future behavior. Current patient city listings are never portrayed as geographical nearest. Sponsored Featured placement remains a separate unchanged concept.

**عربي:** يجب أن يحسب الخادم الكيلومترات والمسار المرجعي ويختار أقرب فرع ويحذف التكرار قبل الترقيم لكل العيادات المعتمدة والنشطة. لا ترتيب محلي لأول صفحة ولا تحويل وحدات مبهمة. وضع الخريطة/القائمة محضر بالواجهة، لكن خدمة الأقرب غير مفعلة حتى وصول العقد الحقيقي.

## 7. Android/iOS Google Maps SDK and credentials / إعداد الخرائط والمفاتيح

**Current reality:** app has `flutter_map`/OpenStreetMap for manual pins, `url_launcher` Google Maps universal links on Android/iOS and `geolocator` foreground permission. **No `google_maps_flutter`/native Google Maps renderer or restricted client keys are configured.** No private Places key was added. Google place previews never draw Google Places content on OSM; a renderer boundary and honest unavailable state remain until approved SDK/keys/terms are ready.

Before enabling the embedded renderer:

- Review/pin a compatible Google Maps Flutter/native SDK and minimum OS requirements against current Flutter3.41.5 and iOS13 target. Do not silently raise the deployment target or alter signing.
- Separate Android Maps SDK client key restricted to actual package **`com.aestheticway.aesthetic_way`** and allowed signing certificate SHA-1s; production uses the Play App Signing certificate, not only upload/debug certificates. Restrict APIs and separate debug/release/environments.
- Separate iOS Maps SDK client key restricted to exact bundle ID **`com.aestheticway.aestheticWay`** and APIs. Server Places key is distinct, restricted server-side and never included in Flutter/native bundles/API responses.
- Inject client configuration through approved external CI/native build configuration, not committed credentials/keystores. Client SDK keys are extractable identifiers and depend on correct platform restrictions. Never use an unrestricted shared key or weaken TLS/signing to make it work.
- Preserve Google attribution/terms: approved official assets for Places results without a map; Google map attribution when rendered; obey current data-caching/display requirements and avoid Google Places content on a non-Google map. Current production has no search results to attribute. Fixture screenshots are not evidence of compliant live Google SDK delivery.
- Test Android/iOS device SDK initialization, locale/RTL/themes, pin confirmation, external navigation, permission revocation, API-restriction failures and quota failures. No hardware/Google provider verification occurred here.

**عربي:** الخريطة اليدوية الحالية OpenStreetMap ومعلَّمة بذلك، والروابط الخارجية تفتح Google Maps. العرض المدمج من Google لم يُهيَّأ بعد. مطلوب مفاتيح عميل مقيدة بالتطبيق وشهادته/معرّفه، ومفتاح Places الخاص بالخادم يبقى في الخادم فقط. يجب الالتزام بنسبة المحتوى وشروط Google وعدم وضع بيانات Places فوق خريطة غير تابعة لها.

## 8. Prior blockers still open / العوائق السابقة

This task does not fix or reclassify production VIP video save evidence, missing OTP delivery channel/destination, received-referral PII after deletion, approved-setup rejection transition or stale moderation notes. See [UAE QA handoff](UAE_NEARBY_QA_BACKEND_HANDOFF_FOR_ALI.md) and [source-confirmed privacy/review gaps](BACKEND_09F49BB_REMAINING_GAPS_FOR_ALI.md). Gallery multi-image upload/delete remains **user-reported physical PASS**. No Django/source signing change, merge or publishing.
