# Final physical-QA handoff / تسليم المتبقي لعلي

2026-10-25 · PR13 · latest supplied read-only source **401560bdb06bd739f74eb42a88c68fc748e43dbb**. This is the concise current handoff. Earlier resolved/missing-endpoint reports are not repeated as new defects. Django was not edited. No message, production mutation or credential was sent to a third party.

## P0 — Physical VIP video save still fails / فشل حفظ فيديو VIP على الجهاز

**Newest evidence is user-reported:** Android local preview works; **Upload and save video returns HTTP500**. Persistence/restart/remote playback remain unverified. Ali's earlier200/200/R2-206 report does not establish that this failing device attempt succeeded. Gallery multi-image upload/deletion remains previously user-reported PASS; do not open a separate gallery defect.

Flutter wire test independently verifies: authenticated `PATCH /api/v1/clinic-portal/profile/`, genuine MP4 bytes in one `video_ad_file` part, `video/mp4`, correct multipart boundary/content length, no stray cover/gallery/tier field, no500 retry, and no success/state replacement after rejection. A successful PATCH still requires a fresh authenticated profileGET with the same clinic/media/cover. Failed500 keeps the selected file and locks repeat upload until an explicit read-only verification. Local preview is now explicitly labelled unconfirmed.

**Required server evidence from the actual failed attempt:**

1. Deployed commit/migration, app build, UTC attempt timestamp and a sanitized server request/correlation ID where available. Record distinct preflightGET, multipartPATCH and subsequent verificationGET statuses/duration. No full request body or Authorization header.
2. Exact Gunicorn/Django exception class and failing save/validation/storage line, with secrets, clinic/user contacts, proofs and URLs removed. Inspect `request.FILES['video_ad_file']` existence, size/type, seek position **after every validator and before storage**, actual byte length uploaded and persistence transaction outcome. Source `seek(0)` fixes do not prove the running worker uses them.
3. Correlate Nginx request size/body buffering/timeouts with upstream response. Verify the deployed limit accepts a25MB file plus multipart overhead. Do not assume a new HTTP500 is an EOF or body-limit failure: size limits often produce413; identify the actual exception.
4. Verify R2 SDK error/status/operation and object byte size/type with authorized server access. Do not send keys, bucket credentials, private paths, full/signed URLs, JWT or patient data. A200 profile response with a nonempty URL is insufficient proof of decodable content.
5. On the authorized disposable VIP device: PATCH200 → fresh privateGET200 → same remote object → HTTPS video type and Range206 → force-stop/reopen → remote playback. Then explicit JSON `{"video_ad_file":null}` removal, freshGET/restart and unchanged cover/gallery. Record booleans/statuses, not personal data.

**عربي:** الدليل الأحدث من الجهاز هو HTTP500 بعد رفع وحفظ الفيديو، وليس خطأ المعرض. صيغة Flutter واسم الحقل والبايتات صحيحة في اختبار مستقل. نحتاج استثناء الخادم الفعلي وإصدار النشر وتوقيت المحاولة وحالة الملف قبل التخزين ونتيجة R2، دون أسرار أو روابط خاصة. لا نعتبر المعاينة المحلية أو تقرير نجاح سابق إثبات حفظ هذه المحاولة.

## P0 — Email deletion OTP cannot use persisted verification / تعارض توثيق البريد ورمز الحذف

Source-confirmed **four actual isolated API responses**, with delivery mocked: email-change request200 → email-change confirm200 → deletion request200 dispatches only SMS → after phone removal, deletion request400 `NO_VERIFIED_DELIVERY_CHANNEL`, even though the email OTP was confirmed. [Sanitized evidence](physical-qa-remediation/email-source-evidence.json).

`User` has general `is_verified`, but **no persisted `is_email_verified` field/property**. `ProfileChangeService.confirm_email_change` updates email and general verification; `AccountDeletionService` checks `getattr(user,'is_email_verified',False)`, which stays false after reload. Existing email-change request/confirm routes exist; the email-ready state they need is missing. Current request also forbids changing to the same email, so it is not a verification endpoint for an already-registered address.

**Additional confirmed source delivery blocker:** `apps/accounts/services/sms.py:get_sms_provider` registers only `console` and `mock`; its unknown-provider fallback is `ConsoleSmsProvider`. Console/mock return `True` without an actual SMS gateway, and the base default is `SMS_PROVIDER=console`. The console implementation also logs the OTP/contact, so it must not run in production. This source can therefore accept a deletion SMS request without delivering a real SMS. The deployed configuration/code still needs verification; this is not proof of the exact device attempt's provider.

**Ali:** implement/configure a genuine production SMS provider with gateway acceptance/receipt handling; reject console/mock/unknown configurations in production rather than silently accepting dispatch. Do not log OTPs or raw contacts. Confirm carrier/provider delivery with redacted evidence. A configured provider name is insufficient when no corresponding implementation exists in the supplied factory.

**Ali:** define/migrate durable email-verification state (and timestamp/purpose as appropriate), set it only after the matching email OTP, reset it on email changes, and use that same state in deletion. Expose safe channel capability/status if frontend choice is intended. Preserve purpose-bound OTP expiry/attempt/cooldown, authenticated session, last/sole-admin and token/PII cleanup safeguards. Return actual accepted delivery entries and a safe explicit failure when dispatch is rejected. Provider acceptance is not handset/inbox delivery: inspect provider receipts/status with redacted diagnostics and correct delivery configuration.

No source-confirmed deletion-specific password/secure-reauth alternative exists. Generic login/reset-password OTP is **not** a deletion proof. If an alternative is required, supply a documented purpose-bound short-lived server contract; Flutter will not invent a channel or bypass OTP. The app keeps honest destination/resend feedback, recognizes the actual nested service error, and directs unresolved delivery to platform support.

**عربي:** مصنع SMS في المصدر يدعم console وmock فقط، والاسم غير المعروف يعود إلى console الذي يُرجع نجاحاً دون إرسال فعلي ويسجل الرمز/الهاتف. يلزم مزود إرسال حقيقي ورفض الإعدادات التجريبية أو غير المعروفة في الإنتاج وعدم تسجيل الرموز. إعداد الإنتاج الفعلي غير متحقق هنا. تأكيد رمز تغيير البريد لا يحفظ علامة التوثيق التي يفحصها مسار الحذف؛ لذلك لا تُستخدم قناة البريد بعد إعادة التحميل. وحّد حالة توثيق البريد في النموذج وخدمتي التغيير والحذف مع الحفاظ على جميع الضوابط. لا يوجد بديل إعادة مصادقة خاص بالحذف في المصدر، ولا يجوز استخدام رمز الدخول أو إعادة تعيين كلمة المرور بديلاً عنه. قبول SMS لا يثبت وصوله.

## P0 — Nearby stays disabled / إبقاء الأقرب معطلاً

No newer approval fix was supplied.401560b's nearby/Home queries return active draft/unapproved clinics; the public serializer cannot support a safe frontend approval filter. Keep the adapter disabled. Supply corrected committed source and verify approved/public visibility before dedup/pagination, real GPS/radius validation, explicit `distance_km`, Basic/Featured/VIP equality, closest active confirmed branch and stable page2. Manual city selection without GPS must never acquire invented coordinates/distances. Source/manual top-ten and missing nearest-branch coordinates remain in the preceding contract handoff; no undocumented client calls were added.

**عربي:** لا يُفعّل الأقرب قبل استلام وفحص إصلاح ظهور العيادات المعتمدة للعامة. اختبر جميع الباقات وأقرب فرع والمسافة الخادمية والترقيم قبل التفعيل؛ لا نقدّر المسافات محلياً.

## Existing Google follow-up and SDK keys / متابعة Google والمفاتيح

Dedicated autocomplete/details/link/unlink routes are implemented and tested independently of the map widget. They are not reported missing. The unresolved staff-write permission, generic PUT bypass and provider-error/URL-proof issues remain as precisely recorded in [the401560b handoff](BACKEND_401560B_REMAINING_GAPS_FOR_ALI.md); no newer source was supplied to close them. Real provider delivery remains unverified here. Safe Flutter name fallback now uses actual `formatted_text` if `main_text` is empty.

Embedded Maps separately awaits restricted platform SDK keys and an explicitly approved minimum-iOS/dependency decision; the app remains iOS13 and SDK-free. [Production readiness plan](GOOGLE_MAPS_PRODUCTION_READINESS_PLAN.md). No server Places key is placed in Flutter, and successful ratings sync/`linked_verified_place` never proves Business Profile ownership.
