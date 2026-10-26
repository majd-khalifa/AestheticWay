# Ali — remaining physical-UX backend contracts / العقود الخلفية المتبقية

2026-10-26 · PR13 · authoritative read-only source465bf3089dba98a2b0b4145e728daec3c533b0f1.
No Django changes. Requirements below are **proposals, not existing endpoints**.

## Confirmed missing contracts

| Priority | Source evidence | Exact requirement / frontend boundary |
|---|---|---|
| P1 · Google pin adoption | `apps/clinics/models.py` has durable ordinary clinic latitude/longitude; `portal_serializers.py` exposes them. `portal_views.py:655–765` returns temporary proof-bound Details; no pin-source/expiry/adoption contract exists. | Define an authenticated, tenant-scoped, explicitly confirmed adoption operation using a fresh selected-place proof. Store coordinate provenance, selected Place ID and expiry, with refresh/deletion within the applicable Google retention limit. Keep independent owner-entered entrance coordinates separately; a manual correction must neither relabel itself Google-verified nor mutate Place ID. Reject expired/mismatched/user-crossing proof and stale clinic identity; document idempotency, ACK and freshGET shapes. No client adoption call is currently made. |
| P1 · Geographic bias | `portal_views.py:573–653` reads only `query`, `session_token`, `language_code`; no catalog-city or location-bias input. | Add a validated canonical catalog emirate/city context, with source-owned UAE restriction and documented Google locationBias/locationRestriction semantics. Preserve a shared Autocomplete→Details session and permission/throttle/error handling. Flutter currently discloses optional city **query text**; it does not claim true geographic bias. |
| P1 · Localized address details | `services/google_places.py:609–650` returns one `formatted_address`, locality, emirate_code, AE and coordinates; it does not return an atomic bilingual structured address. No authenticated localized reverse-geocoding route exists in supplied URLs. | Return actual provider EN/AR address components, explicit language/source, absent-language nulls and required attribution; never generated translations. Bind any reverse-geocode contract to authorized clinic editing, UAE bounds, selected catalog city/emirate, provider policy and retention. Resolve contradictory city/emirate data server-side. Document fields and errors before Flutter consumes them. |
| P1 · Address provider governance | Existing Flutter performs explicit Nominatim address lookup, not business-name autocomplete. Per-process1req/s/cache cannot enforce the public instance's application-wide limit or switch all installed clients at runtime. | Supply an authenticated/appropriately protected address proxy or approved commercial/self-hosted provider with aggregate throttling, caching, runtime provider routing, attribution, minimal logs and safe error/Retry-After contracts. Do not assume any proxy endpoint is already implemented. |

**عربي:** لا يزال اعتماد إحداثيات Google كدبوس دائم يحتاج عقداً صريحاً مع
مصدر الإحداثيات ومدة الاحتفاظ وتحديثها أو حذفها، وحماية إثبات الاختيار وملكية
العيادة. الدبوس اليدوي مستقل ولا يثبت هوية نشاط Google. البحث الحالي يدعم
إضافة اسم المدينة إلى نص الاستعلام فقط، وليس انحيازاً جغرافياً حقيقياً.
نحتاج تفاصيل عناوين إنجليزية/عربية فعلية من المزود مع توضيح اللغة الناقصة
والإسناد، وخدمة بحث عناوين تضبط الحد الإجمالي وتسمح بتغيير المزود. لا توجد
استدعاءات Flutter لمسارات مقترحة غير موثقة، ولا تُختلق ترجمة أو إحداثيات.

## Existing unresolved findings — referenced, not reopened

- The unassigned Super Admin Google-write fallback remains in the same supplied
  source; Flutter already rejects that role. Exact reproduction and required
  authorization fix: [backend465bf30 report, remaining dependency4](BACKEND_465BF30_INTEGRATION_REPORT.md).
- OTP receipt remains unverified. The source SMS factory only registers
  console/mock providers; deletion suppresses those as production delivery and
  can use eligible verified email. Current API reports provider acceptance,
  masked channel/destination, not delivery receipt. No channel/security change
  was made. The same report contains the exact provider dependency.

**عربي:** ملاحظة صلاحية السوبر أدمن القديمة مذكورة بالرابط ولم تُفتح كمشكلة
جديدة. وصول OTP فعلياً غير مثبت؛ قبول المزود للطلب لا يثبت التسليم. تبقى
حماية الحذف واشتراطات المشرف الأخير كما هي.

## Live evidence needed only if an upload problem recurs

Owner now reports Android video upload/restart/play/delete and cover preservation
PASS. There is no new independently confirmed server timeout or gallery defect.
For a recurrence, correlate only UTC attempt time, generated X-Request-ID, stage,
elapsed time, HTTP status and size band. Check actual ingress body/time limits,
worker/object-storage timing, PATCH ACK, a new authenticated profileGET and the
matching R2 object's MIME/Range support. Do not share JWTs, OTPs, proofs, private
URLs, payload dumps or personal data. Source archive has no deployed ingress or
worker timeout configuration; Flutter's480s send/120s receive budgets do not
prove those server limits.

**عربي:** إذا تكرر فشل الفيديو نحتاج ربط الطلب الآمن بوقت المحاولة ومعرّفه
والمرحلة والمدة وحالة HTTP وفئة الحجم، ثم تأكيد PATCH وGET جديد وملف R2.
لا نفترض وجود عطل خادمي جديد ولا مشكلة مستقلة في معرض الصور، ولا نطلب رموزاً
أو روابط خاصة أو بيانات أشخاص.

Policies reviewed2026-10-26: [Google Places](https://developers.google.com/maps/documentation/places/web-service/policies),
[Google terms §14](https://cloud.google.com/maps-platform/terms/maps-service-terms),
[Nominatim](https://operations.osmfoundation.org/policies/nominatim/).
