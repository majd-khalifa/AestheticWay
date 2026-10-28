> Historical source snapshot: the current 09f49bb findings supersede the old missing-tier/filter/count/reject/gallery items. See [the current integration report](BACKEND_09F49BB_INTEGRATION_QA_REPORT.md) and [remaining confirmed issues](BACKEND_09F49BB_REMAINING_GAPS_FOR_ALI.md).

# Clinic review workflow — handoff for review only / للمراجعة فقط

Source audited: **1f1e4bf**. No Django files changed. These are findings/proposals for review; no backend implementation, deployment or communication with Ali was authorized or performed.

المصدر المدقق: **1f1e4bf**. لم نعدّل Django. ما يلي نتائج واقتراحات للمراجعة فقط، وليس تكليفاً بتنفيذ أو نشر تغييرات على الخادم. لم يتم التواصل مع علي.

## Supported now / المدعوم حالياً

- Clinic submits complete checklist through `POST /api/v1/clinic-portal/profile/submit-for-review/ {}`. Admin inspects `GET /api/v1/admin/clinics/<id>/` and approves with `POST .../verify/ {reason}`. **Verify also activates the account**; Flutter confirms both effects. Clinic GET profile/checklist observes approval. Local disposable view tests executed this cycle successfully.
- ترسل العيادة الملف المكتمل للمراجعة، ويفحصه المشرف العام ثم يوافق عبر `verify/`. **هذا المسار يفعّل الحساب أيضاً**، ولذلك توضّح الواجهة الأثرين قبل التأكيد. اختُبرت دورة الإرسال والموافقة وتحديث حالة العيادة ببيانات مؤقتة محلية.
- Category requests already have pending filter/count plus approve/reject/reason. Do not implement duplicate endpoints or reclassify this feature as missing.
- طلبات التصنيفات تدعم بالفعل العدد والتصفية والموافقة والرفض مع السبب. لا حاجة لافتراض فقدان هذه العقود أو تكرارها.
- VIP profile video binary upload and downgraded-video removal work in controlled source fixtures. Production R2 delivery and the actual QA clinic tier remain unverified.
- رفع فيديو العيادة المؤهلة وحذفه بعد خفض الصلاحية يعملان في الاختبار المحلي. تسليم R2 وصلاحية عيادة الاختبار الفعلية غير مثبتين بعد.

## P0 — Reliable submitted inbox / صندوق الملفات المرسلة

`AdminClinicViewSet.get_queryset` has no setup-status filter; an unknown `setup_status=submitted` parameter is ignored. Existing `status=pending` is account state, **not** setup review. No global submitted-setup count is returned. Flutter displays a Submitted loaded-pages-only filter and an unavailable-global-count notice.

لا يدعم استعلام العيادات تصفية حالة الإعداد؛ معامل `setup_status` يُتجاهل. حالة الحساب `pending` مختلفة عن إرسال الملف. لذلك لا يمكن استنتاج عدد المراجعات عالمياً من الصفحات المحمّلة.

Review proposal: add a validated independent `setup_status` filter and authoritative count in an approved existing dashboard/list contract; preserve pagination and Super Admin permission. Test account-active/setup-submitted and account-pending/setup-draft separately, all pages, empty/error cases. Do not turn this into polling or a push-channel assumption.

اقتراح للمراجعة: تصفية مستقلة لحالة الإعداد وعدد صحيح ضمن عقد معتمد، مع إبقاء الترقيم والصلاحيات. تُختبر حالات الإعداد منفصلة عن تفعيل الحساب، ولا يُفترض وجود قناة إشعارات.

## P0 — Setup Reject and clinic feedback / رفض الإعداد وإظهار الملاحظات

There is no setup rejection action. `POST .../reject/`404 and PATCH `setup_status` is ignored. Ordinary activate/suspend must not be repurposed. Clinic profile serializer omits moderation/rejection reason, despite the model's rejected enum.

لا يوجد إجراء API لرفض الإعداد، ولا يقبل PATCH تغيير حالته. تفعيل/إيقاف الحساب ليسا قرار رفض للملف. لا تُعاد ملاحظات الرفض في رد ملف العيادة الحالي.

Review proposal: an explicitly authorized setup decision contract, required bounded reason on rejection, moderation actor/time/audit log, ownership-safe clinic-visible feedback projection, preserved activation state, atomic allowed transition checks. Select the endpoint/schema with Ali **before** implementation; this document does not claim such an endpoint exists. Permit rejected → submitted only after the same completeness checks. Avoid exposing internal-only notes or other clinics' data.

اقتراح للمراجعة: عقد قرار خاص بالإعداد مع سبب إلزامي محدود الطول عند الرفض وسجل تدقيق، وملاحظات آمنة للعيادة المالكة، وفحص انتقالات ذري دون خلط حالة الحساب. يجب اعتماد المسار والحقول أولاً؛ لا تدّعي هذه الوثيقة وجود API جديد.

## P0 — Atomic transition protection / حماية انتقالات الحالة

`verify/` unconditionally approves/activates, without requiring submitted status or completeness. Submit unconditionally writes submitted after checklist passes, including previously approved profiles. Flutter hides invalid actions, re-reads before approve and prevents duplicate taps; this cannot secure direct API calls or eliminate concurrent updates.

ينفذ `verify/` الموافقة والتفعيل دون اشتراط حالة مرسل للمراجعة. ويمكن لمسار الإرسال إعادة ملف مقبول إلى مرسل. حماية Flutter لا تحل محل تحقق ذري في الخادم ولا تمنع الطلبات المباشرة.

Review proposal: explicit transition policy, transaction/row locking or revision precondition, consistent conflict response, retry/idempotency behavior, regression tests for simultaneous decisions and approved resubmission. Keep medical/regulatory certification separate from platform moderation.

اقتراح: سياسة انتقالات مع قفل/إصدار وتعارض واضح واختبارات تزامن. موافقة المنصة ليست اعتماداً طبياً أو تنظيمياً.

## P1 — Complete safe inspection / الفحص الكامل الآمن

Admin clinic detail has counts, not complete practitioner/treatment data or clinic gallery. Provide an ownership/role-safe inspection projection or supported paged associations if full submitted-content approval is required. Do not use public active-only APIs to pretend to inspect unpublished staff/services. Do not include regulatory registry fields in Flutter UI.

يعرض رد المشرف أعداد الفريق والعلاجات دون السجلات الكاملة أو معرض الصور. يلزم عقد فحص آمن للمحتوى غير المنشور إن كان مطلوباً للموافقة الكاملة. لا تُستخدم واجهات عامة تخفي المحتوى المعلق للإيحاء بفحصه كله، ولا تُعرض بيانات الجهات التنظيمية.

## P1 — Neutral messages and live evidence / النصوص المحايدة والإثبات الحي

Backend checklist practitioner title and submission message still imply licensing/medical compliance review. Flutter replaces those known display strings with neutral platform copy. Consider neutralizing source responses after review. Need sanitized deployed clinic tier/media URLs and observed HTTPS/CDN playback before marking production media verified; never provide JWTs, passwords, OTPs or patient data.

تحتوي بعض رسائل الخادم عبارات توحي بترخيص أو تدقيق طبي. عُدّلت الواجهة إلى نصوص محايدة. تُراجع رسائل المصدر لاحقاً. يلزم إثبات حي منقح للصلاحية والوسائط قبل اعتماد الإنتاج، دون رموز دخول أو كلمات مرور أو OTP أو بيانات مرضى.

Evidence: `docs/onboarding-review/controlled-django-contracts.json` —122 local responses;403 unchanged source hashes. Fixtures use in-memory SQLite/local test storage/force-authentication, not production JWTs, Postgres or R2.
