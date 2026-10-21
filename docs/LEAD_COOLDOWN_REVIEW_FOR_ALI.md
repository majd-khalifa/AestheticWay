# Lead cooldown review for Ali / مراجعة تكرار طلبات الاستشارة

Date / التاريخ: 2026-10-22 (Asia/Damascus). Examined source: supplied Django `ca15dc6`; **no Django files changed**. These are source-contract findings, not verification of the deployed server. Flutter baseline: `229ad3d`, existing PR #10.

## English: exact current behavior

| Concern | Source and behavior |
| --- | --- |
| Endpoint | `POST /api/v1/leads/`, `apps/leads/urls.py`; `apps/leads/views/patient_views.py:26`, `LeadCreateAPIView.create()` starts at line 35. Authentication and `IsPatient` are mandatory; patient ownership is assigned from `request.user`, not a submitted patient ID. |
| General throttle | `LeadCreationThrottle(UserRateThrottle)`, lines 22–23: **10/hour at lead creation, using the authenticated account key**. The view explicitly selects this class (line 33), overriding default throttle classes. Its inherited scope is `user`; its explicit rate overrides the global user rate. The separately declared `core.throttles.LeadCreateThrottle` and settings `lead_create` scope are not the class selected here. |
| Shared-scope defect | In pinned DRF 3.15.2, `UserRateThrottle.scope = "user"` and `cache_format = "throttle_%(scope)s_%(ident)s"`. This subclass does not override scope, so its `throttle_user_<user-pk>` history is shared with the default `UserRateThrottle` (`2000/hour`) on other endpoints, including authenticated public clinic reads and history. Unrelated admitted API calls can populate that list and block lead creation before ten lead attempts. The ten-entry check is **not an isolated lead-only counter**. Source confirms a collision path; live cache contents/deployed settings remain unverified. |
| What counts toward throttle | DRF checks before serializer validation and view creation. Attempts admitted by the throttle, including attempts subsequently rejected by validation/duplicate protection, consume that rolling history. A rejected throttle attempt creates no lead. Applies to consultation, offer and product-inquiry submissions. |
| Consultation duplicate window | Lines 57–91: **30 seconds**, only `lead_type == consultation`; offer and product-inquiry leads bypass this duplicate block, but still use the hourly throttle. |
| Atomic cache key | `lead_lock:{clinic_uuid_or_general}:{authenticated_user_id}:{normalized_patient_name}:{normalized_treatment_uuid_or_service_name}`. Name/service normalization is `strip().lower().replace(' ', '_')`. Atomic `cache.add(..., timeout=30)` via `core/throttles.py:atomic_acquire_rate_lock`. |
| Database duplicate predicate | Consultation + authenticated patient + clinic + exact patient name + `created_at >= now−30 seconds`, then exact treatment when supplied, otherwise `treatment IS NULL` + exact service text. DB name/service matching is not the lock's normalized matching. |
| Fields not matched | Practitioner, branch, phone, notes and offer are not discriminators in this consultation duplicate rule. A genuinely different practitioner or branch with the same clinic/patient/name/service can therefore be blocked within 30 seconds. Changing only notes or phone also does not distinguish a request. Different treatment/service normally changes the key; ordinary cache/DB failures and normalization collisions remain separate concerns. |
| Duplicate response | HTTP **429**, raw `{"detail":"A request for this service at this clinic was already submitted recently."}`. No application error code, no `retry_after`, no `Retry-After` set by this manual `Response`. It bypasses the global exception wrapper. Flutter now maps only that exact contract sentence to sanitized `DUPLICATE_LEAD`. |
| Hourly throttle response | HTTP **429**, `{"error":{"code":"RATE_LIMIT_EXCEEDED","message":"…","retry_after":N_or_null}}`, through `core/exceptions/handler.py:custom_exception_handler` (lines 42, 93–96). Pinned DRF 3.15.2 `Throttled` rounds a supplied wait upward to whole seconds; `SimpleRateThrottle.wait()` returns `None` when the shared history length exceeds ten, so this collision can yield `retry_after: null` and no header; standard `rest_framework.views.exception_handler` sets `Retry-After` when the exception has a wait. Verified against upstream DRF 3.15.2 `exceptions.py:226–244` and `views.py:86–91`; production proxies may alter headers, and the live response was not captured. |
| Is a rejected attempt saved? | Duplicate return is before `serializer.save()` (line 96), initial status history and notifications: **no new lead from that rejection**. An existing cache lock is not proof an earlier lead was saved: the lock is acquired before save, and a save failure leaves it until expiry. Cache exceptions fail closed and can produce the same duplicate response. Do not tell the patient this rejected attempt created a request. |
| Successful request | HTTP **201** only after save; body contains `success`, `lead_reference`, `confirmation_message`, `created_at` (lines 167–172). The authenticated account's successfully stored row is included in `GET /api/v1/leads/my/`, newest first, subject to selected status/pagination and later legitimate deletion/state changes. |
| History ownership | `MyLeadsAPIView.get_queryset()` lines 175–193 filters `patient=request.user`; `MyLeadDetailAPIView` lines 196–207 applies the same restriction and returns 404 across accounts. Detail routes `/leads/my/<uuid>/` and `/leads/<uuid>/` are aliases to that patient-scoped view. |
| History contract | `PatientLeadSerializer` returns `id`, `reference_code`, `new/contacted/closed`, `created_at`, localized clinic/branch/practitioner/treatment/offer/product summaries. Pagination is 20, maximum 20. No appointment reservation is made. |

### Flutter behavior delivered by this review

One persistent localized notice appears beside Submit and scrolls into view. No additional snackbar for that rejection. Duplicate and general throttling have different explanations. Form name, dial code/phone, notes, consent, treatment and practitioner selections remain intact. In-flight submissions are guarded synchronously. Header and numeric envelope delays are honored conservatively; locally estimated transport backpressure is never presented as a server-requested duration. The UI reports the server-requested duration, without inventing a 30-second countdown or promising acceptance after it. A valid “View My Requests” action opens account-owned history; back restores the original form. Existing transport backpressure and server protection remain enabled.

Navigation: **Profile → My Requests** (first menu item, above the expanded profile form); or **successful consultation → View My Requests**; or **rejection notice → View My Requests**. Tap a record for clinic/service/practitioner/date/reference details. Normal AppBar/system back works. Filters map Sent→`new`, Contacted→`contacted`, Closed→`closed`; pull to refresh and bounded pagination are retained. “All” no longer misrepresents a loaded page or filtered count as a global total.

### Proposed Django follow-up; NOT implemented

Keep the intended 30-second duplicate window and 10/hour lead budget. First separate the colliding cache scope while retaining the default user protection; proposed code only, requiring Ali's review:

```python
class LeadCreationThrottle(UserRateThrottle):
    scope = "lead_create"  # dedicated history; settings already name this scope
    rate = "10/hour"

# On LeadCreateAPIView, preserve the default user allowance too:
throttle_classes = [UserRateThrottle, LeadCreationThrottle]
```

This keeps the configured 2000/hour general-account protection and 10/hour dedicated lead protection rather than sharing their histories. Test normal authenticated browsing plus lead submissions, separate users, cache keys and rolling expiry. Do not deploy or clear live throttle caches from this review.

 Product policy should explicitly decide whether changing practitioner/branch is a different inquiry. If it is, change **both** the atomic key and DB predicate together:

```python
# Proposal only, inside the existing consultation guard:
branch = serializer.validated_data.get("branch")
practitioner = serializer.validated_data.get("practitioner")
branch_ident = str(branch.pk) if branch else "none"
practitioner_ident = str(practitioner.pk) if practitioner else "none"
lock_key = (
    f"lead_lock:{clinic_id_str}:{patient_ident}:{clean_name}:{clean_treat}"
    f":{branch_ident}:{practitioner_ident}"
)
# Keep timeout_seconds=30 and the existing account throttle unchanged.
# Add these to the existing dup_filter, preserving all existing predicates:
dup_filter = dup_filter.filter(branch=branch, practitioner=practitioner)
```

Also distinguish a held duplicate lock from unavailable cache service: the current boolean helper collapses them. Return a safe temporary-unavailability response for cache failures rather than falsely implying an existing saved lead. Use a structured `DUPLICATE_LEAD` envelope and a trustworthy server wait based on remaining lock/window duration. Consider an account-scoped idempotency key for transport retries; do not silently resubmit or turn a rejected POST into success. Test same intent simultaneously across workers, different practitioner/branch, offer/product bypass, cache failure, validation failure, failed save, rolling hourly throttle and cross-account history. This review does not authorize changing spam policy or deleting leads.

## العربية: النتائج الدقيقة والتوصيات

- المسار هو `POST /api/v1/leads/`، والدالة `LeadCreateAPIView.create` في `apps/leads/views/patient_views.py`. المستخدم يجب أن يكون مريضاً مسجلاً، وملكية الطلب تؤخذ من `request.user` حصراً.
- توجد حمايتان من حيث نوع الفحص: **10 محاولات في الساعة لكل حساب** عبر `LeadCreationThrottle`، و**نافذة تكرار مدتها 30 ثانية للاستشارات فقط**. محاولات التحقق المقبولة من محدد المعدل تدخل في رصيده حتى إن رفضها التحقق أو كاش التكرار لاحقاً. طلبات العروض والمنتجات تخضع لحد الساعة، ولا تدخل شرط تكرار الاستشارة.
- **عيب إضافي مثبت في المصدر:** صنف حد الطلبات يرث نطاق الكاش `user` نفسه المستخدم افتراضياً لباقي الطلبات الموثقة، رغم اختلاف الحد 10/ساعة مقابل 2000/ساعة. لذلك قد تملأ قراءة الدليل أو سجل الطلبات هذا التاريخ وتمنع الإرسال قبل عشر محاولات استشارة. لا يوجد عداد معزول للطلبات في النسخة المتاحة. التوصية الموثقة هي نطاق `lead_create` مستقل مع الإبقاء على محدد المستخدم العام؛ لا تعديل أو مسح للكاش الحي هنا.
- مفتاح الكاش يجمع العيادة والحساب واسم المريض والعلاج أو نص الخدمة. قاعدة البيانات تفحص الاستشارة والحساب والعيادة واسم المريض وتاريخ آخر 30 ثانية، ثم العلاج أو نص الخدمة. التطبيع في مفتاح الكاش لا يطابق المقارنة النصية الدقيقة في قاعدة البيانات.
- الطبيب/الممارس والفرع والهاتف والملاحظات ليست مفاتيح تمييز. لذلك قد تُرفض استشارة مختلفة لنفس العيادة إذا كان الاختلاف فقط في الممارس أو الفرع خلال النافذة.
- رفض التكرار الحالي يعيد **429** مع `detail` فقط؛ لا رمز خطأ تطبيقي ولا مدة انتظار موثوقة في الجسم أو `Retry-After`. رفض حد الساعة يمر بمعالج الأخطاء ويعيد `RATE_LIMIT_EXCEEDED` و`retry_after`؛ DRF يوفر ترويسة الانتظار عند وجود مدة. إذا تجاوز تاريخ النطاق المشترك عشر محاولات فقد تكون المدة `null` ولا توجد ترويسة انتظار؛ لا يجوز اختراع مدة في Flutter. لم نلتقط استجابة الخادم الحي لتأكيد سلوك الوكيل.
- الرفض يحصل قبل حفظ السجل؛ **المحاولة المرفوضة لا تنشئ طلباً جديداً**. وجود القفل لا يثبت حفظ طلب سابق، فقد يفشل الحفظ بعد إنشاء القفل، كما أن عطل الكاش يُغلق المسار احترازياً بالرسالة نفسها.
- الطلب المحفوظ بنجاح يعود ضمن `GET /api/v1/leads/my/` للحساب نفسه، مرتّباً بالأحدث ومع ترقيم الصفحات ومرشح الحالة. مسار التفاصيل مقيد أيضاً بالحساب ويرفض الوصول إلى طلب مريض آخر. الحالات الصحيحة: تم الإرسال `new`، تم التواصل `contacted`، مغلق `closed`؛ لا تأكيد موعد أو حجز.
- تعديل Flutter يعرض **تفسيراً واحداً** بجوار زر الإرسال ويحتفظ بكل المدخلات والموافقة والاختيارات. تظهر مدة الانتظار فقط إذا أعادها الخادم. زر «عرض طلباتي» لا يدّعي إنشاء سجل من الرفض، والرجوع يعيد النموذج كما كان.
- الوصول: **الملف الشخصي ← طلباتي**، أو زر متابعة الطلبات بعد النجاح، أو زر الطلبات داخل رسالة الرفض. يمكن فتح تفاصيل السجل والتحديث بالسحب والتنقل بين الصفحات والرجوع طبيعياً. تبويبات المريض الخمسة لم تتغير.
- التعديل المقترح أعلاه **توثيق فقط ولم يُطبّق**: بعد قرار المنتج بأن تغيير الممارس/الفرع يمثل استشارة مختلفة، يُضافان معاً إلى مفتاح القفل وشرط قاعدة البيانات مع إبقاء 30 ثانية و10/ساعة. كذلك يجب فصل عطل الكاش عن التكرار الحقيقي وإرجاع رمز منظم ومدة انتظار محسوبة. لا تعطيل للحماية ولا حذف لبيانات المرضى.
