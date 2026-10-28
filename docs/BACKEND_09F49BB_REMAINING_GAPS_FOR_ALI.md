# Ali — remaining confirmed 09f49bb issues / المشكلات المؤكدة المتبقية

Source: **`09f49bbd22131f6dad49a65a5167de5396f03797`**, supplied Git-archive comment; archive SHA in [QA report](BACKEND_09F49BB_INTEGRATION_QA_REPORT.md). Date: 2026-10-24. Django is unchanged. **671 local tests passed**, plus [38 real isolated view probes](backend-09-integration/controlled-contracts.json). These are SQLite/mock-provider/local-storage tests, not independent production or PostgreSQL concurrency evidence.

**Resolved in this source / تم تأكيد إصلاحها:** private read-only tier, owner rejection-reason projection, server setup filter/global submitted count, reject route, Admin gallery/staff/treatment projection, anonymous bilingual deletion page, stricter verification and approved-resubmission rejection. The previous handoffs are historical; please do not reimplement those items.

## P0 — received referral retains deleted patient's personal data

`apps/accounts/services/account_deletion.py::confirm_deletion` clears notes only on `ReferralInvite.objects.filter(referrer=locked_user)`. The real deletion probe creates an invite with the patient as `referred_user`, confirms deletion through its OTP endpoint, then reloads the invite: **`invitee_phone` and its personal note remain**, while the user is deactivated and personal media is removed.

**المؤكد:** بعد حذف حساب المريض فعلياً عبر مسار الرمز، يبقى رقم هاتفه والنص الشخصي في الدعوة التي استقبلها. الكود ينظف ملاحظات الدعوات التي أرسلها المستخدم فقط، ولا ينظف بيانات الدعوة المرتبطة به كمستخدم مُحال إليه.

Please cover received invites and records matching the pre-anonymization phone, and sanitize relevant free text while preserving only required non-identifying ledger history. `invitee_phone` is unique and limited to 20 characters: do not replace every phone with the same empty value. Use a schema-compatible unique non-PII marker, a justified nullable schema, or an explicit deletion/retention design. Keep analytics without retaining contact identifiers. Add endpoint tests asserting no original phone/note remains, including received invites. Review the success receipt and public retention statements against the actual implementation.

يرجى تنظيف الدعوات المستقبلة والسجلات المطابقة للهاتف الأصلي قبل إخفائه، مع مراعاة قيد التفرد وطول الحقل. احتفظ بالسجلات الإحصائية الضرورية دون بيانات اتصال، وأضف اختبارات حذف تتحقق من زوال الهاتف والملاحظات من الدعوات المستقبلة أيضاً. لا يعد نجاح الواجهة دليلاً على اكتمال محو البيانات.

## P1 — reject action lacks a submitted-state guard

`apps/admin_portal/views.py::_handle_reject_setup` locks the row but unconditionally sets `setup_status=rejected`. The probe verifies **200 on a previously approved setup**. Flutter re-reads and exposes reject only for submitted profiles; that cannot prevent concurrent transitions or a direct authorized API call.

**المؤكد:** يسمح مسار الرفض برفض ملف سبق اعتماده. يوجد قفل للصف لكنه لا يفحص انتقال الحالة. حراسة Flutter وحدها لا تمنع السباق أو الاستدعاء المباشر.

After `select_for_update()` and before mutation, require `setup_status == submitted`; otherwise return 409 with a documented stable code such as `INVALID_SETUP_TRANSITION`. Preserve account `status`. Add approved/draft/rejected and competing-decision tests on PostgreSQL, not only SQLite. If revoking an existing approval is a product requirement, define a separate explicit audited action instead of silently using setup rejection.

## P1 — resubmit retains prior moderation notes

`apps/clinics/portal_views.py::ClinicSubmitForReviewAPIView.post` writes submitted state/timestamp but does not clear `moderation_notes`. The reject → owner-resubmit probe confirms old notes remain in the database and Admin detail. The owner alias hides them outside rejected state; Flutter also avoids presenting them as current rejection feedback.

**المؤكد:** بعد التصحيح وإعادة الإرسال تبقى ملاحظة الرفض القديمة في البيانات وتفاصيل الإدارة، رغم أنها لا تعود سبب رفض حالي للمالك.

Clear current rejection feedback as part of the atomic resubmission transition, retain history in the audit log, and include the field in `update_fields`. Also explicitly guard draft/rejected → submitted; the current implementation only rejects approved state. Add tests proving current feedback clears and reviewed/submitted states cannot be mutated through unintended transitions.

## Contract documentation corrections / تصحيح التوثيق

- Verify actually returns **`CLINIC_NOT_SUBMITTED` / `CLINIC_SETUP_INCOMPLETE`**, 409. The report names `INVALID_SETUP_TRANSITION / INCOMPLETE_ONBOARDING`. Flutter supports both naming sets and does not infer success.
- Reject returns a **small action acknowledgment**, not full `AdminClinicDetailSerializer`; Flutter re-fetches detail.
- Admin detail has `moderation_notes`, not a separate `setup_rejection_reason` field. Private profile/checklist provide the reason alias.
- Practitioner summaries use `type`, without reported `is_active/display_order`. Treatment summaries use `price`, not `starting_price`, and omit descriptions/category UUID/media. Flutter does not invent missing fields or render regulatory identifiers.
- The public deletion page is locally verified anonymous 200. Its live HTTPS deployment and operational backup-retention claims need separate evidence. Ali's reported live R2 MP4 result remains **engineer-reported**, not independently verified here.

Additional validation discrepancy: full-tree `ruff check --no-cache` with Ruff 0.17.2 reports 104 findings; the reported clean-lint result was not reproduced at that tool version/scope. No automatic lint fix was run.

فحص Ruff للقراءة فقط بالإصدار 0.17.2 أعاد 104 ملاحظات على الشجرة الكاملة؛ لم نغيّر Django لتصحيحها ولا نعدّها كلها انحدارات جديدة.

لا توجد تعديلات Django ضمن PR #13. يرجى توحيد التوثيق مع الاستجابات الفعلية وتقديم دليل إنتاج منقح عند توفره، دون JWT أو رموز تحقق أو بيانات مرضى أو روابط موقعة كاملة.
