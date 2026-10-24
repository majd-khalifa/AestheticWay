# Physical Android QA, VIP video and UAE proximity — handoff for Ali / تسليم لعلي

2026-10-24. Flutter PR **#13**, branch `codex/final-backend-integration-client-preview`.
Read-only source: archive commit **09f49bbd22131f6dad49a65a5167de5396f03797**. No later backend source or deployed contract was supplied for this increment. Previous deployment claims are not live verification.

## Evidence / الأدلة

- **User-reported physical Android PASS:** multiple gallery images uploaded and deleted; admin review counts/reject/owner feedback/resubmit/approval; lead/status flow; stored language/theme; first-run onboarding. **Do not open a gallery defect from the video screenshot.**
- **User-reported FAIL:** tapping **Upload and save video** displays “The service is temporarily unavailable. Please try again.” Local video preview works. Durable video save, real process restart and cover-preserving video deletion remain unverified.
- **Independent isolated source probes:** actual valid multipart MP4 PATCH200 → fresh authenticated GET200 → local storage object exists → JSON-null removal200 preserves cover. Basic/Featured upload400. Invalid duration400. Injected storage failure500. All three discovery routes return a farther VIP before a nearer Basic. OTP request200 lacks channel/destination. **11 responses; 405 source files unchanged**, [sanitized evidence](uae-nearby-qa/source-evidence.json). SQLite, temporary local storage and mocked OTP provider are not R2/production/device evidence.
- **تصحيح ضروري:** خطأ الخدمة ظهر عند حفظ الفيديو، وليس تحديث المعرض. رفع وحذف صور المعرض ناجحان وفق اختبار المستخدم. الاختبارات المحلية لا تثبت النشر أو وصول رمز التحقق أو استمرارية فيديو R2 على الجهاز.

## P0 — Identify the failing video operation / تحديد عملية الفيديو الفاشلة

Existing verified contract remains:

```text
GET   /api/v1/clinic-portal/profile/
PATCH /api/v1/clinic-portal/profile/
  multipart/form-data; boundary=<Dio-generated>
  video_ad_file=<actual MP4/MOV/WebM bytes>
GET   /api/v1/clinic-portal/profile/  # fresh private read, same authenticated clinic
PATCH /api/v1/clinic-portal/profile/  JSON {"video_ad_file": null} # removal
```

`subscription_tier` is private read-only; only actual `vip` enables upload. Pending/submitted clinics with valid membership can use the same contract. `cover_image` is independent. There is **no independent `video_poster` profile field**. No new endpoint or client entitlement override was introduced.

Source: `apps/clinics/portal_serializers.py:113`, `portal_views.py:137`, `apps/media/validators.py:149`, `config/storage_backends.py`. Limits:25MB,15s target/15.5s validation grace, actual allowed MIME/magic and verifiable positive duration. Source tests distinguish valid/invalid files. A synthetic storage exception produces500; this is a diagnostic reproduction, **not the established cause of the physical failure**.

Flutter now distinguishes upload, acknowledgment, fresh-profile reload and persistence validation. It does not clear the local selection or announce success after an unverified GET. No multipart retry loop; an ambiguous write requires a read-only inspection before another upload. Retry-After/global backpressure is retained. Video errors appear adjacent to video controls; gallery state stays independent.

**Required production evidence (authorized disposable VIP only):**

1. Deployed backend commit and frontend build/OS version; UTC attempt time and a sanitized server-generated request/trace ID.
2. Separate preflightGET, multipartPATCH and post-PATCHGET **HTTP statuses**, elapsed time, method and route template. Do not assume the English banner means503: Flutter also maps other5xx to a generic unavailable message. A local throttle is a fourth possibility and is explicitly identified by its error metadata.
3. PATCH acknowledgment and freshGET both identify the same clinic and the same remote video object path; compare privately. Export only booleans (`same_clinic`, `same_object`, `cover_unchanged`), not clinic identities, signed URLs, authorization headers or response bodies.
4. For4xx: safe structured code/field name, tier/membership decision and validation reason. For5xx: private exception class/stack and storage operation, R2 credentials **readiness only**, bucket permissions, proxy request-size/time limits and body buffering. Never paste credentials, JWT, raw signed links, account phone or patient data.
5. Check remote HTTPS status, video content type, actual bytes and range request206/Content-Range/Accept-Ranges; inspect codec on the physical device. Header/body observations require authorized live access; local preview is insufficient.
6. Force-stop/reopen the app and GET again; play the remote object. Remove saved video, GET/restart again; verify video absent and cover unchanged. If a write timed out, inspect before retrying.

**عربي:** نحتاج حالة HTTP لكل من PATCH ثم GET، ومعرّف تتبع آمن وتوقيت المحاولة وإصدار النشر. لا تكفي رسالة «الخدمة غير متاحة» لتحديد السبب أو افتراض503. راجع سجل الاستثناء والتخزين وحدود الوكيل دون مشاركة أسرار. تحقق من الفيديو البعيد بعد إيقاف التطبيق وإعادة فتحه؛ المعاينة المحلية ليست إثبات حفظ.

## P0 — Account deletion delivery / قناة إرسال رمز الحذف

Actual `POST /api/v1/auth/me/deletion/request/`200 fields are **only**:

```json
{"success": true, "message": "<server message>", "expires_in": 600, "resend_cooldown": 60}
```

Expiry/cooldown values are illustrative; Flutter uses actual returned values. Source dispatches SMS and optionally verified email; it does **not** return which provider accepted delivery. Flutter does not guess from user profile, display a full address, or equate provider acceptance with receipt. It shows that the request was accepted but the channel/destination was not supplied, keeps OTP entry and visible resend cooldown. No guessed destination-field mapping was added.

**Ali contract proposal — not implemented or called:** return allowlisted `delivery_channel` plus server-produced `masked_destination` for the channel(s) actually accepted; if multiple, define a typed `deliveries[]` schema. Define provider-accepted vs delivered status honestly; do not claim actual receipt without delivery evidence. Add tested privacy masking and OpenAPI examples. Resend expiry, invalid/used code, provider failure and stale-session behavior need live reachable-account QA.

`SOLE_CLINIC_ADMIN` is a real400 safeguard, **not an OTP delivery failure**. Flutter provides a clear explanation and a real return-to-portal exit. The source has no clinic-owner replacement-admin/closure workflow suitable for this screen; do not add a fake link. Ali/product must supply an authorized transfer or reviewed closure route and public deletion instructions that allow eligible users to complete deletion without an indefinite dead end.

**عربي:** لا توجد حالياً حقول قناة الإرسال أو الوجهة المخفية. أضفها من نتيجة مزود الإرسال الحقيقية مع توثيق تعدد القنوات وحماية الخصوصية. منع المشرف الوحيد مستقل عن إرسال الرمز. يلزم مسار مخوّل لاستبداله أو مراجعة إغلاق العيادة؛ زر العودة ليس بديلاً عن إتمام طلب الحذف.

## P0/P1 — Preserve previously confirmed defects / العيوب المؤكدة السابقة

No supplied source change has remediated these. See [previous source probes and exact models/actions](BACKEND_09F49BB_REMAINING_GAPS_FOR_ALI.md).

| Priority | Confirmed source issue | Required server fix / المطلوب |
|---|---|---|
| P0 privacy | Successful deletion leaves received `ReferralInvite.invitee_phone` and personal note when the deleted patient is `referred_user`. | Cover both sent and received referral PII with approved retention/deletion/anonymization. Phone is unique; blanket empty-string replacement is unsafe. / شمول الدعوات المستلمة وعدم ترك الهاتف والملاحظات الشخصية. |
| P1 integrity | `reject-setup` accepts an already approved setup. | Submitted-only atomic row-locked transition; correct409; test races/direct API, not only Flutter guards. / منع رفض الملف المعتمد عبر تحقق ذري من الحالة. |
| P1 feedback | Resubmission retains old moderation notes in DB/admin detail. | Clear current rejection feedback on accepted resubmission; retain audit history separately; validate draft/rejected transitions. / مسح سبب الرفض الحالي عند إعادة التقديم مع حفظ سجل تدقيق منفصل. |

## P1 — True nearby discovery / العيادات الأقرب فعلياً

**Actual09f49bb contract:**

- `/api/v1/clinics/`: active/nondeleted clinic queryset; `city` and `emirate` case-insensitive text filters; page/page_size (20 max). Geo keys `latitude`/`longitude` exist, but ordering is **tier_rank → distance → rating → display_order → name → pk**.
- `/api/v1/home/nearby-clinics/` uses the same tier-first approach. `/home/feed/` takes10 results from it. Home city filter exists; no confirmed canonical `city_id`/`emirate_id` or general Home emirate filter.
- `distance` is PostGIS **metres** on PostgreSQL and **squared coordinate degrees** on SQLite. There is no uniform `distance_km`. Only clinic-level coordinates are considered; closest active branch/clinic deduplication and radius filtering are absent. Active queryset does not independently require setup approval.
- **No canonical location-catalog API** exists in supplied URL configuration. Do not assume Ali's work-in-progress is deployed.

**Implemented frontend boundary:** optional foreground low-accuracy location, manual emirate→city picker, seven stable emirate IDs and a clearly partial15-city compatibility seed. Existing `city` text is sent to existing routes; no invented catalog/nearby route, `city_id`, radius, ordering or coordinates are sent by the new Home location flow. No client sorting over one page. Legacy `distance` is no longer parsed as kilometres. Home says browse by city/UAE, never labels current results nearest. Paid Featured carousel remains separate and unchanged. GPS stays in memory and is discarded on background/logout/account switch; not persisted, logged or sent while proximity support is unavailable. The bounding envelope rejects clearly unsupported coverage; it does not prove UAE municipality membership.

**Proposed contract requirements for Ali (not a production API claim):**

1. Publish a versioned canonical emirate/city catalog with stable codes/IDs, localized names, reviewed government/municipality sources and aliases. Seven emirates are not seven cities. Cities such as Al Ain/Hatta/Khor Fakkan/Kalba and the distinct Dibba municipalities must belong to their actual emirate. Districts are a separate level. Approve/migrate the bundled compatibility seed; do not call15 entries “all cities”. Define aliases of historical spellings and renamed cities, including Ruwais/Al Dhannah, so existing stored text still matches.
2. Choose and document **one existing endpoint extension or a new approved route**; supply source, URLs, permissions, serializer and tests before Flutter enables it. Require finite in-coverage coordinates and define radius/accuracy bounds and400 shapes. Accept canonical location IDs only after they exist.
3. Distance-first query across **all approved+active+visible** clinics, closest eligible confirmed main/branch coordinate per clinic, deduplicate before pagination; exclude null/zero/outlier coordinates. Stable ordering by distance then immutableclinic/branch tie-breaker, independent of tier. Return explicit server `distance_km` with consistent units and formula on supported DBs, canonical locality, selected branch and paginated next/count metadata. Never use emirate/map centers as clinic positions.
4. Bound page_size20; radius/no-result behavior; stable ties across pages; noN+1; spatial indexes; cache keys include location/coarse tile/radius/filter/language and invalidate on clinic/branch/media/approval changes. Define privacy retention before sending any patient coordinates. Production PostgreSQL/PostGIS tests must cover multiple branches and paid-vs-nearest ranking.
5. Document API errors/auth/session behavior and deployed commit. Only then implement the HTTP adapter for `NearbyClinicsRepository`; existing default adapter is explicitly unavailable and sends **zero HTTP requests**.

**عربي:** المصدر الحالي يرتب الاشتراك قبل المسافة، ولا يُرجع كيلومترات موحدة أو أقرب فرع. لذلك لا نزعم وجود بحث «الأقرب». المطلوب كتالوج مواقع قانوني موحد ومراجَع، وترتيب خادمي بالمسافة أولاً لكل العيادات النشطة والمعتمدة، وحذف التكرار قبل الترقيم، ووحدة `distance_km` صريحة، واختبارات قواعد البيانات والتخزين المؤقت والخصوصية. لن تُستعمل نقاط مراكز الإمارات كمواقع عيادات أو اختراع مسارات قبل وصول العقد.

## Store/privacy rollout / الخصوصية والنشر

Android coarse/fine declarations support user-selected approximate permission; no background location. iOS When-In-Use rationale and `BYPASS_PERMISSION_LOCATION_ALWAYS=1` only. `geolocator_apple` supplies a no-tracking privacy manifest; final packaging is a CI/native check, not proof of policy compliance.

Public Privacy Policy must describe optional on-device foreground location and manual selection. Current new UX sends no GPS off-device. Before enabling any server proximity feature, reassess approximate/precise data sent, linked identity/JWT, retention, processors, console Data Safety/App Privacy and access logging/redaction. Public policy deployment is unverified. Production signing is untouched; no store publishing.
