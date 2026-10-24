> Historical source snapshot: the current 09f49bb findings supersede the old missing-tier/filter/count/reject/gallery items. See [the current integration report](BACKEND_09F49BB_INTEGRATION_QA_REPORT.md) and [remaining confirmed issues](BACKEND_09F49BB_REMAINING_GAPS_FOR_ALI.md).

# 1f1e4bf — remaining backend and release dependencies / المتطلبات المتبقية

23 October 2026, Asia/Damascus. Read-only source audit; **660 supplied tests pass locally**, plus 101 controlled responses. No live deployment, production OTP or Cloudflare R2 delivery claim. Earlier d1023b0 reports are historical; category management and deletion endpoints now exist.

## Implemented contracts / العقود المتوفرة والمربوطة

**EN:** Flutter now integrates clinic category requests, Super Admin category CRUD/moderation, and authenticated two-step account deletion. These are no longer missing APIs. Clinic global writes remain prohibited; Admin routes and permissions are distinct. Gallery, single catalog images, profile video, decimal treatments and practitioner assignments remain supported. No Django changes were made.

**AR:** تم ربط طلبات التصنيفات للعيادات وإدارة التصنيفات ومراجعتها للمشرف العام، وحذف الحساب بخطوتين موثقتين. لم تعد هذه الواجهات مفقودة. لا يحق للعيادة تعديل التصنيفات العامة مباشرة. بقيت المعارض والصور والفيديو المدعوم والأسعار العشرية وربط الممارسين محفوظة. لم نعدّل Django.

## P0 before store submission / قبل التقديم للمتاجر

1. **Public deletion guidance and policy accuracy.** `apps/site_pages/urls.py` has `/privacy/`, `/terms/`, `/contact/`, no dedicated account-deletion resource. The privacy template directs users to email support; Arabic wording promises deletion of all associated data, whereas the service retains records described below. A dedicated URL is not inherently required if an existing public page meets every Play requirement, but the console URL must clearly identify this app, explain how to request deletion, data erased/retained and retention periods. Verify unauthenticated HTTPS accessibility and real operator/contact details. Apple in-app initiation is now implemented; acceptance and any necessary retention remain owner/legal/store-review decisions. Do not declare store compliance passed from source alone.

   **AR:** توجد صفحات الخصوصية والشروط والتواصل، ولا يوجد مورد مخصص لحذف الحساب. تحيل السياسة الحالية المستخدم إلى البريد وتعد الصياغة العربية بحذف جميع البيانات، بينما تحتفظ الخدمة ببعض السجلات. يجب أن يشرح رابط Play العام اسم التطبيق وخطوات الحذف والبيانات المحذوفة والمحتفظ بها ومدد الاحتفاظ، مع التحقق من إتاحته دون تسجيل دخول عبر HTTPS. أصبحت بداية الحذف داخل التطبيق متاحة؛ لا يعني ذلك قبول المتاجر تلقائياً.

2. **Deletion data lifecycle and truthful receipt.** `apps/accounts/services/account_deletion.py:confirm_deletion` anonymizes User name/phone/email, disables account/memberships, removes device tokens, anonymizes lead contact snapshots and blacklists refresh tokens. It does **not** erase free-text `Lead.notes`, `LeadNote.note`, patient-scoped MediaAsset files, referral associations/profile, OTP audit history or backups/logs. Shared clinic records must remain. These are confirmed retention surfaces, not an assertion that all retention is unlawful. Identify legally necessary records and periods; erase/anonymize other personal data, including sensitive free text/media, in a durable job with auditable completion. The response currently says “personal data permanently deleted” despite the narrower operations; align it with actual lifecycle and policy. Flutter uses deliberately qualified consequences rather than repeating that blanket claim.

   **AR:** تخفي الخدمة بيانات الاسم والهاتف والبريد وتعطل الحساب والعضويات وتحذف رموز الأجهزة وتخفي بيانات التواصل في الطلبات وتبطل رموز التحديث. لكنها لا تمحو نصوص ملاحظات المرضى/العيادة أو ملفات وسائط المريض أو ارتباطات الإحالة أو سجلات الرموز والنسخ الاحتياطية. يجب إبقاء سجلات العيادة المشتركة وتحديد ما يلزم الاحتفاظ به قانونياً ومدته، وحذف بقية البيانات عبر عملية دائمة قابلة للتدقيق. يجب مطابقة رسالة النجاح والسياسة مع ما يُنفّذ فعلياً.

3. **PII in deletion logs.** The final logger call includes the original phone number. Remove/redact it and audit log retention/access; do not log OTPs or JWTs. This report contains no actual user phone/token.

   **AR:** يسجل السطر الأخير في خدمة الحذف رقم الهاتف الأصلي. يرجى إزالته/إخفاؤه ومراجعة صلاحيات السجلات ومدد الاحتفاظ. لا تسجل رموز OTP أو JWT.

4. **Real delivery and identity verification.** `request_deletion` sends to phone plus any non-empty `user.email`, without a separate email-verification predicate. Confirm trusted channel policy and production SMS/email provider handling of `purpose=account_deletion`, rate limits, delivery and abuse controls. Local mock delivery passing does not establish production delivery. Test only disposable authorized accounts with another active admin where required.

   **AR:** ترسل الخدمة إلى الهاتف وإلى أي بريد غير فارغ دون تحقق مستقل من توثيق البريد. يرجى تأكيد سياسة وسيلة التحقق الموثوقة ودعم مزودي الرسائل لغرض الحذف وضوابط الإساءة والتسليم الحقيقي، باستخدام حسابات اختبار مصرح بها فقط.

## P1 consistency and concurrency / الاتساق والتزامن

- **Deletion safeguards race:** sole-admin checks occur before `transaction.atomic()` without locking the relevant administrator set. Concurrent last-two-admin deletions are not proven safe. Serialize business-continuity safeguards; add concurrency tests with PostgreSQL. The local SQLite tests do not establish race safety.
- **Lifecycle failures:** cache proof is consumed inside the DB transaction but cache is not transactional; token/device/lead cleanup exceptions are broadly caught. A rollback, storage/provider error or lost response can produce an ambiguous result. Use an idempotent deletion receipt and durable cleanup/outbox with retry, plus tests for partial failures. Never return full-purge success if cleanup failed.
- **Category request races/moderation:** pending duplicate check has no matching DB uniqueness/concurrency guard. Review methods do not require current pending status or lock requests; approval can reactivate an existing archived category, and previous rejection_reason is not cleared on approval. Add serialized pending transitions, explicit conflict responses and constraints. Flutter disables duplicate actions and offers moderation only for rows returned pending; client guards do not solve server races.
- **Category names/slugs:** case-insensitive duplicate checks and slug allocation are application checks; add concurrency-safe constraints/retry if needed. Document server search support separately; Admin view currently exposes pagination without declared searchable fields.

**AR:** افحص الحذف المتزامن لآخر مشرفين بقفل مناسب داخل معاملة PostgreSQL؛ تحقق من عدم إعلان النجاح عند فشل التنظيف الجزئي، ووفر إيصالاً ثابتاً وإعادة محاولة آمنة. طلبات التصنيف لا تملك قيداً يمنع الطلبات المعلقة المكررة بالتزامن، ولا تشترط المراجعة بقاء الحالة معلقة. الموافقة قد تعيد تنشيط تصنيف مؤرشف ولا تمسح سبب الرفض السابق. يجب حماية انتقالات الحالة على الخادم؛ حراسة الأزرار في Flutter غير كافية لضمان ذلك.

## Media source limitations that remain / حدود الوسائط التي لا تزال موجودة

- Source still has no Treatment image/video relationship, no offer/practitioner/article/product video association, no clinic campaign association/editor API, no gallery reorder/draft array contract, and no independent profile-video poster field. No such UI was invented.
- Gallery public projection remains oldest10 images. Individual media DELETE is supported, but replacing/clearing single profile/catalog associations does not prove physical old-file garbage collection. Document retention/storage cleanup before claiming file erasure.
- Validators and role-write fallback fixes in 1f1e4bf are recognized as **resolved source gaps**; see the new report rather than the obsolete d102 blocker list.

**AR:** لا تزال علاقات وسائط العلاج وفيديو العروض والممارسين والمنتجات والمقالات وترتيب المعرض وواجهة حملات العيادة وملصق فيديو مستقل غير متوفرة. العرض العام للمعرض يقتصر على أول عشر صور. إزالة الارتباط لا تثبت حذف الملف القديم من التخزين. تم الاعتراف بإصلاحات التحقق وصلاحيات الكتابة الجديدة ولم نعد نسجلها كموانع قديمة.

## Live verification handoff / التحقق من الإنتاج

Confirm deployed source/migrations (new CategoryRequest/PROTECT/media alias migrations), authenticated endpoint permissions, real registered-channel OTP delivery, old access/refresh rejection after disposable deletion, gallery HTTPS/CDN/cache behavior after save/restart, current Google Place-ID/rating fields, and backend public policy contents. Keep tokens, patient notes, contacts and passwords out of screenshots/logs/tickets. The existing sanitized public-clinic capture helper remains available; no production write/deletion was performed here.

**AR:** تحقق من نشر الالتزام والهجرات الجديدة، وصلاحيات الواجهات وتسليم رموز التحقق وإبطال الجلسات بعد حذف حساب اختبار، واستمرار الوسائط عبر HTTPS بعد إعادة تشغيل الجهاز، وحقول Google الحقيقية ومحتوى السياسات. لا ترسل بيانات المرضى أو الرموز أو كلمات المرور في الأدلة.
