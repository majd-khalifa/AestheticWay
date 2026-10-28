# Remaining401560b dependencies / المتبقي لعلي

2026-10-25 · READ-ONLY source `401560bdb06bd739f74eb42a88c68fc748e43dbb` · PR13. These findings replace earlier broad “missing contract” reports. The new Google/OTP/catalog/video contracts **exist** and Flutter integrates their safely supported behavior. See [25 actual source responses](backend-401560b-qa/source-evidence.json). No production credentials or patient data are needed for the source reproductions.

## P0 — Public nearby exposes unapproved profiles / ظهور ملفات غير معتمدة

`apps/clinics/views.py:ClinicNearbyAPIView` and `apps/home/views.py:get_home_nearby_clinics_queryset` filter `status=active, deleted_at IS NULL`, but not `setup_status=approved`. An isolated active/draft clinic with valid coordinates is returned by `/api/v1/clinics/nearby/`200. The public serializer omits setup status, so Flutter cannot distinguish an unpublished draft safely. The new adapter's production `supported` remains false; no hidden bypass flag was added.

**Ali:** apply the actual public-visibility policy to both clinic and branch eligibility before proximity, dedup and pagination; add tests excluding active draft/submitted/rejected profiles while including approved Basic/Featured/VIP independent of tier. Retain deterministic distance/ID order, active branches, real kilometre values and optional GPS. Supply the committed source before frontend activation. Existing city-directory/sponsored behavior was preserved; also audit its eligibility and Home feed under the same policy.

**عربي:** المصدر يعيد عيادة نشطة بحالة إعداد مسودة، ولا يرسل حالة الاعتماد للعامة. لا يمكن لـFlutter تصفية ذلك بأمان. يلزم تقييد الاستعلامات بالاعتماد والظهور العام قبل المسافة والترقيم، مع اختبارات للحالات الأربع وجميع الباقات. محول الأقرب جاهز ومختبر لكن غير مفعل للمريض حتى إصلاح هذا العيب المؤكد.

## P0 — Google mutation authorization / صلاحيات تعديل ربط Google

All four Google views use `IsClinicPortalAccess`, which accepts `clinic_staff` memberships. Actual POST unlink by a staff user returns200. Link/details/autocomplete use the same permission path. Flutter rejects patient/staff/super-admin use of this clinic-admin workflow, but client guards cannot secure the server.

**Ali:** use administrator-and-active-membership authorization for association writes; keep tenant resolution authoritative. Define whether staff may search read-only and test patient, staff, foreign-clinic and ambiguous/multiple-membership cases. Never infer authorization from a name match or successful rating synchronization.

**عربي:** موظف العيادة يستطيع تعديل الارتباط في المصدر. امنع التعديل إلا للمشرف المخوّل والعضوية الصحيحة. حماية Flutter باقية لكنها ليست بديلاً لحماية الخادم.

## P0 — Generic PUT bypass / تجاوز الحماية عبر PUT

`ClinicProfilePortalSerializer.validate` applies its non-empty Place-ID guard only when `request.method == PATCH`. Actual PUT with `name_en` and an arbitrary new `google_place_id` returns200. The profile view exposes PUT. Flutter uses the dedicated proof-bound link POST and never falls back to PUT, so this must be closed server-side.

**Ali:** enforce identity assignment policy for every mutation path, including PUT/admin provisioning as applicable; isolate trusted proof consumption from generic serializer writes. Add PUT/partial PATCH regressions. Legacy blank-clear compatibility remains a separate operation; do not weaken verification to maintain it.

**عربي:** حماية PATCH لا تشمل PUT؛ أثبت الاختبار قبول معرّف غير متحقق عبر PUT. عمّم الحماية على جميع طرق التعديل ولا تستخدم Flutter كحاجز أمني وحيد.

## P1 — Google provider truthfulness, URL and attribution / دقة خدمة Google

- Actual autocomplete returns `suggestions`, not report's `results`. Missing key, provider failure and no matches all return200 empty suggestions. Flutter cannot classify these as confirmed “no business exists”; it now says no suggestions returned and search may be unavailable. Return a safe documented provider-unavailable status/code; keep keys/provider bodies out of responses/logs.
- Proof stores only user/clinic/place IDs; it is an opaque random cached token, not the report's signed/encrypted payload. Link accepts client `google_maps_url`, otherwise may retain the **old** association URL or build `cid=<PlaceID>` (CID is not Place ID). Flutter submits only the exact selected Details URL, and external navigation uses `query_place_id`. Bind the vetted URL/details to the proof or resolve it server-side; prevent direct URL reassignment from misrepresenting linked identity.
- Details defaults missing country toAE and missing emirate toDU; do not infer these from absent provider data. Reject unverified coverage; Flutter additionally validates coordinates/country, but cannot detect a fabricated server default.
- Preserve actual provider attributions in the normalized response when required. Flutter includes visible unlocalized Google Maps attribution and never renders Places data on OSM. Ensure public application Terms/Privacy incorporate the necessary Google references. [Official policy](https://developers.google.com/maps/documentation/places/web-service/policies).
- Production proof replay/CAS must be checked with the deployed shared cache and multiple workers. A local source test is not production concurrency evidence.

**عربي:** ميّز خطأ الخدمة عن عدم وجود نتائج، واربط رابط الخريطة الحقيقي بالإثبات خادمياً. لا تفترضAE/DU عند غياب بيانات Google. أبقِ الإسنادات الحقيقية وسياسة الخصوصية والشروط دقيقة، وتحقق من كاش الإنتاج وإعادة استخدام الإثبات عبر العمال.

## P1 — Catalog, manual discovery and branch navigation / الدليل والتصفح اليدوي والفروع

- Source catalog responses are **lists**, currently7 emirates,23 cities,50 curated areas. They are supported, not an exhaustive country catalog. Stable codes distinguish both Dibba cities. Supply catalog version/refresh policy as it evolves.
- Clinic models/profile/admin serializers have no persisted canonical area ID; clinic lists have no area filter. Flutter stores explicit district text only inside the existing editable localized address, and discloses city-level filtering. Specify migration/backward-compatible canonical assignment before sending new FKs.
- `/clinics/nearby/` requires coordinates; report's manual fallback applies to the Home route, not that endpoint. `/home/nearby-clinics/` manual query is sliced to10 **before pagination**;12 matching source fixtures still produce count10/nextnull. Remove this cap for a complete list, or document the route as a preview and provide a properly paginated manual discovery contract.
- `nearest_branch_id` exists but list response supplies HQ coordinates only. Flutter does not navigate to HQ while describing a branch distance. Supply confirmed nearest-branch coordinates/address or a stable authorized public branch lookup contract for precise map/directions.
- Canonical code filters do not consistently match legacy full-text database city/emirate values. Flutter preserves legacy names; verify normalization/aliases for Madinat Zayed, Ruwais/Al Dhannah and full-name emirates before requiring code-only writes/queries.

**عربي:** الدليل الحالي معتمد لكنه غير شامل لكل مناطق الدولة. لا يوجد حقل منطقة دائم أو ترشيح منطقة في نماذج العيادة. التصفح اليدوي محدود بعشر نتائج قبل الترقيم، وإحداثيات أقرب فرع غير مرفقة. نحتاج عقوداً واضحة لهذه النقاط وتوافق الأكواد مع القيم القديمة.

## P1 — OTP and administrator exit / الرمز وخروج المشرف

New delivery fields are integrated. `deliveries` lists accepted dispatches; it has no guaranteed delivery receipt/status. Flutter prefers that list rather than assuming top-level SMS succeeded if only email did. No unmasked response destination is displayed. `NO_VERIFIED_DELIVERY_CHANNEL`, cooldown and last/sole-admin safeguards remain honest.

`transfer-ownership/` promotes an existing active membership; it does **not** demote the caller or provide a member-list API. Flutter explains this and requires an explicit UUID plus consent. Deactivation requires a typed localized confirmation and consent; no automatic deletion follows. Verify target **user** activity/deletion as well as membership activity server-side and avoid returning phone numbers in messages/logs. Validate OTP provider success/failure and final anonymization against disposable authorized accounts on production separately.

**عربي:** قبول إرسال الرمز لا يثبت وصوله. نقل الإدارة الحالي يضيف مشرفاً ولا يزيل صلاحيات المشرف القديم، ولا يوجد دليل أعضاء. التعطيل لا يحذف الحساب تلقائياً. تحقق من نشاط المستخدم الهدف ومن إخفاء بياناته وعدم الاكتفاء بنشاط عضويته.

## Configuration and physical evidence / الإعداد والتحقق على الجهاز

No private/server Places key goes into Flutter. Android Maps SDK key must be separate, restricted to `com.aestheticway.aesthetic_way` + actual Google Play App Signing SHA-1 (and separate development certificate when needed), API-restricted to Maps SDK for Android. iOS key: `com.aestheticway.aestheticWay`, Maps SDK for iOS only. Server key stays server-side, Places API(New), server network restriction, quotas/billing/alerts and minimum masks.

Current Flutter3.41.5/Dart3.11.3 cannot use latest plugin2.19.0 (requires3.47/3.13). Reviewed candidate2.13.1 fits Flutter, but inspected iOS2.15.5 requires iOS14 while app targets13. No unapproved minimum-OS bump or signing/key change was made. Embedded maps awaits an agreed supported dependency/OS matrix and restricted keys; external Maps navigation works through existing validated URLs.

Ali-reported401560b deployment,693 tests, Nginx30M/120s and R2 Range206 are recorded as reported. Independent evidence here is source/localCI only. Use the [physical checklist](backend-401560b-qa/PHYSICAL_ANDROID_QA.md) for real Google/OTP/video/restart checks; return only sanitized statuses and booleans, never JWT, phone, password, proof, full media URL or patient data.
