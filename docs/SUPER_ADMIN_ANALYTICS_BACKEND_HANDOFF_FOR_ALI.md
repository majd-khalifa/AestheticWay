# Ali — analytics and deletion handoff / تسليم التحليلات والحذف

Date: 2026-10-31 (Asia/Damascus). Frontend base: **8f48a80c311080299591f4f51dc3141914d6fb5b**, verified current origin/main and PR #13 merge. Feature branch: **codex/super-admin-analytics-forensic-audit**. Backend archive commit stamp: **52666c1711469ec8a3689cf54f93c1c5fa963e6e**; provided source, **deployment unverified**. Django is read-only. Test fixtures and screenshots are not production evidence.

**NO-GO for complete production analytics. This is a source-grounded contract proposal, not a deployment claim. / لا يمكن اعتماد التحليلات الكاملة للإنتاج؛ العقود المقترحة أدناه ليست منشورة أو منفذة.**

## Existing routes — verified in supplied source / المسارات الموجودة

| Existing endpoint | Actual behavior and limits |
| --- | --- |
| POST /api/v1/analytics/events/ | AllowAny, six event choices, user derived from auth, clinic/object IDs and arbitrary metadata accepted, server timestamp. Duplicate 201s accepted; no event-ID ACK. |
| GET /api/v1/admin/analytics/?from=YYYY-MM-DD&to=YYYY-MM-DD | Super Admin only; inclusive configured-timezone calendar window, raw event totals + real Lead count, sparse daily raw totals, only top 10 clinic ID/name/events_count. clinic_id/page are ignored. |
| GET /api/v1/clinic-portal/analytics/ | Current membership only, rolling 30 days; not a global Super Admin per-clinic endpoint and must not be impersonated/reused. |
| GET /api/v1/admin/clinics/?search=...&page=... | Real paginated directory; include_deleted supported by source but not exposed in current analytics selector. Detail returns all-time leads_count, not period engagement. |
| GET /api/v1/admin/leads/?clinic=<uuid>&date_from=...&date_to=... | Real read-only operational lead drill. Returns authorized patient fields; do not use it as a bulk analytics export. Invalid dates currently ignored; require strict 400 server validation. |
| GET /api/v1/admin/analytics/referrals/ | Lifetime successful invites and positive points; no date filter. |

**عربي:** يوجد مسار تجميع عام محدود وعرض خاص بعضوية العيادة، ولا يوجد عقد كامل موثق لتحليل أي عيادة حسب الفترة. لا تُجمع قائمة العشر عيادات لاستنتاج الإجمالي. واجهة Flutter تعرض عدم توفر التحليل التفصيلي بدلاً من اختلاق قيم.

## P0: event integrity, privacy and canonical lead accounting

Reproduce in isolated source: anonymous POST twice with event_type=lead_submitted, a pending clinic UUID and metadata containing a synthetic patient_note/event_id. Both return 201 and persist two rows without creating a Lead. The platform raw total diverges from saved leads. `Django apps/analytics/views.py:18`, `Django apps/analytics/serializers.py:6`, `Django apps/analytics/models.py:15`.

Required Django work (PROPOSED, not applied):

1. Version ingestion schema. Accept a UUID event_id and allowlist only legitimate client types. Reject client lead_submitted. Reject clinic attribution on app_open; require an eligible known clinic on clinic/contact events and validate optional branch/content ownership. No staff/private/internal actions in patient engagement.
2. Database unique event_id, payload digest conflict detection (409 same ID/different body), request replay atomicity, response {event_id, status: persisted|duplicate, schema_version}. New 201 and duplicate 200 acknowledge the same logical event. Never echo forbidden metadata or user-supplied identities.
3. Strict tiny allowlisted metadata (source enum and optional branch UUID); no patient notes/service names/reference codes, contact destination numbers/URLs, exact GPS, JWT/OTP/device tokens or arbitrary JSON. Server-derived authenticated user/role; anonymous collection requires an approved lawful/product policy and scoped abuse protection, not a caller-chosen stable fingerprint.
4. Dedicated scoped auth/IP throttles, body-size cap, per-session/clinic abuse controls, trusted proxy configuration, audit/admin anomaly visibility. Default global throttles alone are insufficient against poisoning and arbitrary clinic UUIDs. Preserve anonymous 401/role403 rules on admin reports.
5. Saved Lead is authoritative. One server-owned canonical event per persisted Lead ID, with a DB uniqueness condition and transactional/outbox handling. Current best-effort caught event write can leave a real Lead without an event. Do not double-count Flutter + backend events. Validate event.object_id maps to that actual Lead and clinic before historical reconciliation; existing arbitrary ingestion makes raw rows untrusted.
6. Remove service_name/reference_code from new analytics events (`Django apps/leads/views/patient_views.py:184`); review historical minimization/deletion with an auditable dry-run migration/management command, no live destructive operation by Codex. PROPOSE raw retention 30 days, aggregate 13 months, owner/legal approval required. Delete/anonymize linked raw event identity on account deletion, including identifying metadata. Counters with expired/uncollected history must expose unavailable coverage rather than zero.

**عربي:** أثبت الاختبار قبول حدثي طلب استشارة مزورين دون إنشاء طلب حقيقي. يلزم معرّف حدث فريد وACK قابل للتحقق ومنع إدخال lead_submitted من العميل والتحقق من العيادة والفرع وتقييد الحقول والحجم والمعدل. الطلب المحفوظ هو المرجع ويُسجل مرة واحدة خادمياً. يجب حذف معلومات الخدمة والملاحظة ورقم الطلب من التحليلات واعتماد سياسة احتفاظ ومسح مرتبطة بحذف الحساب. لا تفعّل إعادة المحاولة في Flutter قبل ضمان عدم تكرار الأحداث في الخادم.

## PROPOSED reporting contracts — not present/deployed

**PROPOSED GET /api/v1/admin/analytics/clinics/**

Query: from, to, search, page_size(max 100), cursor or stable page; optional status/tier/include_deleted under Super Admin permission. Start from authorized Clinic queryset, include zero-activity clinics with coverage state, not only clinics with event rows. Stable sort with clinic UUID tie-breaker. Return count/next/results (or documented cursor equivalent), reporting timezone, inclusive dates and half-open UTC boundaries, generated_at, collection schema/version/coverage.

Each clinic row: clinic_id, name_en/name_ar, status/setup status (admin only), clinic_views, whatsapp_taps, call_taps, maps_taps, lead_submissions, canonical total_events, nullable unique_authenticated_accounts, availability for each metric. Global app_opens must never be assigned to a clinic. Null/unavailable and numeric 0 must be distinct. No patient rows, contact details, medical text, raw event metadata or entitlements in patient APIs.

**PROPOSED GET /api/v1/admin/clinics/<uuid>/analytics/**

Same date/permission semantics, verified clinic ID, summary plus paginated daily series and optional comparison period with explicit dates. Compare only genuinely covered periods. A visit/session/contact attempt is not a unique user or completed treatment. Require object-level authorization even if UUID is guessed. Preserve Clinic Portal current-tenant isolation and do not repurpose its membership endpoint for Super Admin.

**PROPOSED extension of existing platform summary**

Preserve the existing unversioned raw total_events meaning for old clients. Negotiate/version the new schema explicitly before defining total_events as canonical in v2; expose recorded_event_rows separately for diagnostics. Do not silently change a legacy response field’s semantics. Canonical total = valid non-lead interactions + authoritative saved Lead count (each once); do not sum arbitrary old lead_submitted rows or top 10. Unique counts are separately named and availability-aware. All referral, operational/lifetime and reporting-period sections explicitly identify scope.

Timezone: document Asia/Dubai, from 00:00 inclusive to(next day)00:00 exclusive; convert to UTC for indexed comparisons. Current Sep 30–Oct 30 interval is **31 inclusive calendar dates**, not a rolling 30-day period. Echo timezone/bounds and reject malformed/reversed/excessive windows. Date defaults and daily grouping must share the same zone. No floating device-local conversion.

**عربي:** المساران أعلاه **مقترحان وغير موجودين**. يلزم ترقيم وبحث في جميع العيادات وإظهار العيادات ذات الصفر مع حالة التغطية، وفصل المستخدمين الفريدين عن الأحداث، وفصل فتح التطبيق العام عن العيادات، وإرجاع إجماليات صحيحة وسلسلة يومية موثقة. استخدم حدود منتصف الليل بتوقيت دبي مع نهاية حصرية لليوم التالي وأعد النطاق والمنطقة الزمنية صراحةً.

## PROPOSED concrete wire schema / نموذج عقد مقترح

These examples specify future behavior only; Flutter sends none of these payloads yet. UUIDs are synthetic schema examples, not production identities.

```json
{
  "schema_version": 2,
  "event_id": "00000000-0000-4000-8000-000000000100",
  "event_type": "clinic_view",
  "clinic": "00000000-0000-4000-8000-000000000200",
  "metadata": {"source": "clinic_profile"}
}
```

For app_open, clinic must be null. For branch-specific handoffs, allow only a validated branch UUID in metadata in addition to the fixed source enum. Timestamp/user/role come from the server; reject unexpected body keys. An acknowledged event returns:

```json
{
  "schema_version": 2,
  "event_id": "00000000-0000-4000-8000-000000000100",
  "status": "persisted"
}
```

First persist: 201. Identical replay: 200 with status duplicate and the same UUID. Same UUID/different normalized payload: 409 with a safe error code; no overwrite. Reports must echo schema_version, timezone, date_from/date_to, UTC start/end-exclusive, generated_at, counts and per-metric coverage. An uncollected measurement is null with an explicit reason; 0 means a valid recorded measurement under its stated coverage. Agree maximum reporting windows and cursor/page format before implementing clients.

**عربي:** الأمثلة توضح عقداً مستقبلياً فقط. لا تستخدم Flutter هذه الحقول حالياً. يجب اعتماد إصدار صريح، وإرجاع معرّف الحدث نفسه مع حالة الحفظ أو التكرار، ورفض اختلاف المحتوى بالمعرّف نفسه، وفصل القيمة غير المتوفرة عن الصفر. تُشتق الهوية والوقت من الخادم وتُرفض الحقول الزائدة.

## P1: indexed aggregation and rollup consistency

`Django apps/analytics/models.py:46` nullable unique(date,clinic) allows duplicate platform NULL rows. Two source rows cause `Django apps/analytics/tasks.py:13` to throw MultipleObjectsReturned. Add an appropriate partial unique constraint for clinic IS NULL plus per-clinic uniqueness (migration/dedup review), atomic upserts and concurrency tests. Remove/recompute stale rollups when source records/associations are erased. Do not treat sequential task rerun tests as proof of concurrent safety.

Use indexed timestamp/clinic/event_type access paths and grouped/subquery aggregation over the selected window. Avoid one full raw scan per metric/clinic and the directory's potentially multiplying multi-table count joins. For thousands of clinics: count/page first, aggregate selected IDs or query indexed daily rows, stable ties, bounded date range and paged trend series. Provide PostgreSQL EXPLAIN ANALYZE on a sanitized representative dataset and query-budget tests. SQLite tests do not establish production plans, row locks or performance.

**عربي:** القيد الحالي لا يمنع تكرار صف المنصة ذي clinic=NULL؛ ثبت فشل إعادة التجميع عند وجود صفين. يلزم قيد جزئي وفحص التزامن والتنظيف المدروس قبل الترحيل. اختبر خطط PostgreSQL والتجميع المفهرس وحدود الفترة والترقيم؛ نجاح SQLite أو قلة عدد الاستعلامات لا يثبت قابلية التوسع.

## P0: account-deletion collision remaining in 52666c1

`Django apps/accounts/models.py:80` permits 20 characters. Previous +deleted_ plus 12 hex characters was 21, logically explaining a PostgreSQL length failure after valid OTP. Current +del_ plus 6 hex is 11 and the normal mocked flow passes, but it uses only 24 bits of the UUID in a unique phone field. Source-reproduced users abcdef00-0000-4000-8000-000000000001 and abcdef11-0000-4000-8000-000000000002: request 200 each; first confirm 200; second confirm 500 (unique collision), remaining active.

Existing contracts are unchanged: authenticated POST `/api/v1/auth/me/deletion/request/` (the isolated probe used `{}`), followed by POST `/api/v1/auth/me/deletion/confirm/` with the newly issued `code`. Reproduce only in disposable local/staging fixtures: create the two synthetic UUIDs above, request a fresh OTP for each, confirm each once and read back is_active. Do not expose OTPs in logs. Expected: both confirmations acknowledge successful deletion and both users are inactive; actual local source result is 200/inactive then 500/still active. Real OTP delivery was not exercised.

Required PROPOSED fix: retain a collision-free full UUID tombstone in a dedicated unique deletion identifier or widen the internal phone field appropriately (e.g.64) and use +del_ plus the full UUID hex (37 chars). Supply the migration, preserve inactive/login validation, phone reuse, token/PII purge, OTP purpose/attempt/cooldown and last/sole-admin protections. Do not shorten again or fake frontend success. Add same-prefix, normal flow, stale access/refresh, email-verified, cleanup rollback and concurrent deletion tests against PostgreSQL. No code/migration was applied here.

**عربي:** الإصلاح الجديد يعالج الطول السابق21 مقابل الحقل20، لكنه يختصر UUID إلى6 خانات فقط. ثبت نجاح حذف المستخدم الأول وفشل الثاني الذي يشاركه هذه البداية بحالة500. استخدم UUID كاملاً مع حقل مناسب أو معرّف حذف فريد وترحيل مدروس، دون تجاوز OTP أو حماية آخر مشرف. النشر والإرسال الحقيقي وإثبات نجاح الحذف على الجهاز ما زالت غير متحققة هنا.

## Work that already exists — do not create duplicate endpoints

Global brand product POST/PATCH/DELETE and brand-product-category CRUD exist in this source, with clinic-owned product edit restrictions. Treatment categories and category-request moderation exist separately. Platform settings allowlist and audit log reads exist. Their missing Flutter management surfaces are Codex work, not new Django API gaps.

## Production evidence requested safely

Ali should privately confirm deployed commit/migrations, sanitized counts by event type for the exact Dubai interval, trusted versus untrusted lead-event reconciliation, validated ingestion responses, worker/rollup coverage and retention configuration. For deletion correlate UTC time, HTTP status, redacted exception class/constraint and field length; never share code/OTP, JWT, phone/email, patient text, raw event payload, full GPS or credentials. Archive identity/test success is not deployment evidence. Use a disposable authorized QA account and approved clinic/place associations; do not test destructive deletion on real operator accounts.
