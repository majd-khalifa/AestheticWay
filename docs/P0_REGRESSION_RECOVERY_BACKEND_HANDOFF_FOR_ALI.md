# Ali — confirmed P0 source findings / نتائج مؤكدة من المصدر

2026-10-26 · PR13 · read-only Django465bf3089dba98a2b0b4145e728daec3c533b0f1.
Evidence is an isolated SQLite/APIClient run with local test storage, not production
or physical-device evidence. [Recorded observations](p0-regression-recovery/source-evidence.json)
and [reproducible probe](../tool/audit_p0_recovery_contracts.py). All413 source files
remain unchanged. No Django code, migrations or deployment configuration was edited.

## 1. P0 — contradictory geography is accepted and persisted

Authenticated clinic owner:

```http
PATCH /api/v1/clinic-portal/profile/
Content-Type: application/json

{"city":"Dubai","emirate":"Abu Dhabi","address_en":"Sharjah","latitude":"25.3463","longitude":"55.4209"}
```

Actual source response **200**, including `city: Dubai`, `emirate: Abu Dhabi`,
`address_en: Sharjah`, `latitude: 25.3463000`, `longitude: 55.4209000`.
`apps/clinics/portal_serializers.py` does not reconcile these fields against the
catalog/administrative geography. Flutter now rejects an explicit catalog
city/emirate conflict and obvious contradictory address text, checks the UAE
coordinate envelope/order, and requires owner entrance confirmation plus freshGET.
Text/envelope checks cannot prove actual city membership or correct old records.

Required: server validation on every write path, canonical city/emirate values,
explicit errors per field, and a reviewed repair process for existing bad data.
Use documented authoritative administrative boundaries/provider data for real
coordinate membership; do not infer it from an address substring or city center.
Do not rewrite existing locations, translations or Google identities silently.

**عربي:** يقبل المصدر فعلياً مدينة دبي مع إمارة أبوظبي وعنوان الشارقة ويعيد200.
يجب التحقق خادمياً من المدينة والإمارة والإحداثيات في كل مسارات التعديل، وإرجاع
أخطاء واضحة للحقول. يلزم تدقيق السجلات القديمة؛ فحص النص وحدود الإمارات في Flutter
لا يثبت موقع المدخل داخل المدينة ولا يصلح البيانات تلقائياً.

## 2. P0 — directory matches inactive/deleted branches

Create three approved/active clinics with headquarters `city: Abu Dhabi`.
Each has a `city: Dubai` branch: one active, one `is_active=false`, one with
`deleted_at` set. Then:

```http
GET /api/v1/clinics/?city=Dubai
```

Actual source response **200 includes all three clinics**. The active Dubai
branch is a legitimate match even though the card's primary city is Abu Dhabi.
The inactive/deleted branch matches are defects. Source:
`apps/clinics/locations_catalog.py:build_location_filter_q` applies
`branches__city__iexact/icontains` without branch eligibility constraints.

Required: match headquarters or an eligible active/nondeleted branch belonging
to that public clinic. Bind city/emirate conditions to the **same** branch; use
canonical branch city→emirate mapping rather than assuming a branch emirate DB
field exists. Keep clinic approval/activity/deletion guards, distinct clinics,
stable ordering and correct page counts. Return a documented `matched_branch`
summary or equivalent match-origin metadata so clients can explain the result
without guessing. Flutter preserves pagination and flags a differing primary
city; it does not falsely certify a matching branch or drop rows client-side.

**عربي:** نتيجة مقرّهـا أبوظبي قد تكون صحيحة إذا كان لها فرع نشط في دبي. الخلل
المؤكد أن الترشيح يشمل أيضاً فرع دبي غير النشط أو المحذوف. يجب تقييد مطابقة الفرع
بحالته وربطه بالعيادة العامة المؤهلة، مع ثبات الترتيب وعدد الصفحات وإرجاع الفرع
الذي سبب المطابقة. Flutter لا يختلق فرعاً ولا يحذف نتائج ليخفي الخلل.

## 3. P1 — Nearby branch emirate can describe headquarters

Controlled fixture: headquarters in Abu Dhabi, active branch with `city: Dubai`,
coordinates25.2315/55.3242. Request:

```http
GET /api/v1/clinics/nearby/?latitude=25.23201&longitude=55.32471&radius_km=50
```

Actual source **200** returns server `distance_km: 0.08` and the correct nearest
branch coordinates/city, but `nearest_branch.emirate: Abu Dhabi`.
`PublicClinicListSerializer.get_nearest_branch` falls back to the clinic's
emirate when the branch has no such attribute. Required: resolve the branch's
emirate from its canonical city or authoritative branch data, never headquarters
fallback for a known different city. Test cross-emirate branches, metadata,
eligibility, distance ordering and pagination together. Flutter uses actual
distance and branch identity, and does not use this contradictory emirate as a
GPS origin or silently invent a replacement.

**عربي:** أعاد المصدر مسافة صحيحة0.08 كم وفرعاً في دبي، لكنه نسب إمارة أبوظبي
إلى الفرع اعتماداً على مقر العيادة. يلزم استخراج إمارة الفرع من مدينته الفعلية
بدلاً من نسخ إمارة المقر. لا تُستنتج إحداثيات أو مسافات بديلة في Flutter.

## Source-confirmed media restriction; physical failure still unproven

`POST /api/v1/media/upload/`, multipart `file`, `media_type: clinic_gallery`
or `practitioner_avatar`, `clinic_id`: active assigned clinic **201**; the same
membership with `Clinic.status=pending` **403**:

```json
{"error":{"code":"PERMISSION_DENIED","message":"Clinic is suspended or inactive."}}
```

`MediaUploadSerializer.validate` requires an active clinic, while ordinary
clinic-portal text CRUD accepts pending clinics. Keep account activation distinct
from setup/publication approval. Clarify/align authorized onboarding media policy
or return explicit capabilities/actionable denial codes. Never relax ownership,
suspension or deletion guards. This conditional restriction is reproduced; it is
**not proof that the owner's failing device had a pending clinic**. Source active
gallery upload→asset ACK→list→new authenticated profile read→delete succeeds.

**عربي:** رفع الصور ينجح للعيادة النشطة ويرفض العيادة ذات حالة الحسابpending
بـ403، حتى مع العضوية الصحيحة. تعديل النصوص يسمح بهذه الحالة. يلزم توحيد سياسة
وسائط الإعداد أو توضيح الصلاحيات والرفض، دون تجاوز الملكية أو إتاحة الموقوف
والمحذوف. لم نثبت أن هذا هو سبب فشل جهاز المالك، ولا يوجد دليل على فشل R2 جديد.

No confirmed backend practitioner bug: Doctor/Nurse/licensed_professional without
portrait **201**. Nurse edit/fresh read **200**;25-record pagination returns20+5
without overlap/foreign tenants. The old Flutter-derived120-character title
returns400 correctly; an explicitly empty optional title returns201. Invalid
enum/overlength fields remain correctly rejected. Do not add a portrait requirement.

## Explicit Google-place→pin adoption requirement (proposal only)

There is no deployed adoption contract in465bf30. Keep existing proof-bound
identity link/unlink unchanged. Before any Flutter adoption action, Ali must
document an authorized clinic-admin operation; for example the **proposed**
`POST /api/v1/clinic-portal/profile/google-business/adopt-location/` accepting
`place_id`, a fresh action-specific `selection_proof`, `consent_accepted:true`,
`expected_current_place_id`, and `expected_location_version`.

The existing link proof is single-use and does not establish a reusable pin
coordinate receipt. Re-fetch/bind authoritative coordinates server-side; reject
expired/consumed/cross-user/cross-clinic proofs and stale versions. Do not trust
client coordinates. Return clinic identity, location version, actual coordinates,
source/place provenance, acquisition/expiry times and refresh state. Store Google
and independent manual entrance data separately; manual correction must not
claim Google verification or modify business identity. Enforce applicable Google
coordinate retention/refresh/deletion (maximum30-day temporary cache where
applicable), attribution, Google-map display restrictions and stale-coordinate
exclusion from public Nearby. Require explicit user confirmation/consent before
overwriting data and an auditable freshGET contract. This route/fields are a
design requirement, **not an endpoint Flutter calls**.

**عربي:** اعتماد موقع Google كدبوس يحتاج عقداً جديداً موثقاً وإثباتاً حديثاً خاصاً
بالعملية وموافقة صريحة، مع حفظ المصدر والمدة وتحديث/حذف البيانات وفق السياسة.
إثبات الربط مستهلك لمرة واحدة ولا يبرر تخزين إحداثيات يرسلها العميل. يجب فصل
الدبوس اليدوي عن هوية Google وعدم ادعاء التحقق بعد التصحيح اليدوي. المسار أعلاه
مقترح فقط ولم يُضف أي استدعاء Flutter غير مدعوم.

Policies: [Google Places](https://developers.google.com/maps/documentation/places/web-service/policies),
[Maps service-specific terms §14](https://cloud.google.com/maps-platform/terms/maps-service-terms).
For an actual image failure, collect only build SHA, action/stage, HTTP status,
safe field/code names, timing and size band. No JWT, OTP, patient information,
payload dump, private media URL or personal filename. CDN delivery, device picker
behavior and the owner's exact failing request remain unverified here.
