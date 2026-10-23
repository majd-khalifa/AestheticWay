# Release handoff for Ali / تسليم متطلبات الإصدار إلى علي

> Historical d1023b0 evidence. Backend availability conclusions are superseded by [the 1f1e4bf integration report](FINAL_BACKEND_INTEGRATION_REPORT.md) and [current bilingual handoff](FINAL_INTEGRATION_BACKEND_HANDOFF_FOR_ALI.md).

Source / المصدر: user-supplied `AESTHETIC_WAY_BACKEND_SOURCE_d1023b0.zip`, compared against ca15dc6. The Flutter branch contains no Django modifications. The supplied newer snapshot is authoritative; production deployment is not inferred from an archive.

## Completed backend changes recognized / تغييرات الباك إند المعترف بها

**EN:** d1023b0 isolates `lead_create` (20/hour), uses a 15-second consultation duplicate window including branch/practitioner, supplies Retry-After: 15 and releases a lock after failed persistence. It also sanitizes stale Google ratings and invalidates Home/clinic caches. These are present in source; please do not reimplement the old ca15dc6 throttle proposal. The patient create/list/detail serializer fields and URLs remain compatible with Flutter. The user reports successful physical Android submission/history/clinic status transitions; this is user-reported QA, not an agent-run production authorization test.

**AR:** المصدر الأحدث يعزل حد إنشاء الطلبات `lead_create` إلى 20 طلباً في الساعة، ويستخدم نافذة منع تكرار 15 ثانية تتضمن الفرع والممارس، ويرسل `Retry-After: 15` ويحرر القفل عند فشل الحفظ. كما يصلح تقييمات Google القديمة وإبطال ذاكرة Home والعيادات. هذه التعديلات موجودة في المصدر؛ لا نطلب إعادة تنفيذ مقترحات ca15dc6 القديمة. حقول ومسارات إنشاء/عرض الطلبات متوافقة. أفاد المستخدم بنجاح دورة الطلب وتغيير حالته على جهاز Android فعلي؛ هذا دليل مستخدم، وليس اختبار صلاحيات إنتاج أجراه الوكيل.

Flutter correction / تصحيح Flutter: a lead POST 429 now cools down that write path while allowing GET My Requests; global GET 429/service 503 protection remains. Repeated writes are blocked without automatic retries. No server throttle bypass or fabricated success is introduced.

## P0: real account/data deletion / حذف الحساب والبيانات فعلياً

**Verified source / المصدر المتحقق منه:** `apps/accounts/urls.py` has registration/login/profile/OTP routes but no deletion; `apps/accounts/views.py:MeView` permits GET/PATCH/HEAD/OPTIONS only. `apps/accounts/models.py` has `deleted_at`/`is_active`; these fields do not implement a deletion lifecycle. `apps/site_pages/urls.py` exposes privacy/terms/contact but no dedicated deletion page. The privacy template tells users to email the configured support address. No self-service deletion job, confirmation contract or completion/retention evidence was found.

**EN:** Flutter now exposes existing public legal pages and an explicitly support-assisted email request from each role. It neither calls an invented DELETE endpoint nor logs out/claims success when a mail composer opens. This discoverability improvement does not remove the release blocker. Google accepts an accessible external request resource, which can include clear support instructions if all requirements are met; a custom web API is not intrinsically mandated. The current privacy page's prominence, live availability and operational deletion process are unverified. Apple generally requires an in-app deletion flow and restricts mandatory email/support-only flows outside its regulated-industry exception; do not assume that a clinic-discovery app qualifies for that exception.

**AR:** يعرض Flutter الآن صفحات السياسة والشروط الموجودة وطلب حذف عبر البريد بمساعدة الدعم داخل كل دور، مع توضيح أن فتح البريد لا يرسل الطلب ولا يحذف الحساب. لا نستدعي DELETE وهمياً ولا نسجل خروجاً أو نجاحاً مزيفاً. هذا التحسين لا يغلق مانع الإصدار. يمكن لمورد ويب واضح ومتاح يتضمن تعليمات طلب الحذف أن يفي بمتطلب Google إذا استوفى بقية الشروط؛ واجهة ويب مخصصة ليست إلزامية بحد ذاتها. لم نتحقق من إتاحة الصفحة الحالية ووضوح الطلب وتنفيذه تشغيلياً. تشترط Apple عموماً بدء الحذف داخل التطبيق وتقيّد الاعتماد الإلزامي على البريد/الدعم خارج استثناء القطاعات المنظمة؛ لا نفترض أن دليل العيادات يستحق هذا الاستثناء تلقائياً.

### Proposed contract — NOT deployed / عقد مقترح غير منشور

Agree the final API with Flutter before implementation. These names are proposals only and are **not** called by the current app:

| Proposed route | Required behavior |
|---|---|
| POST `/api/v1/auth/me/deletion/request/` | IsAuthenticated; derive identity from request.user, never a supplied user ID. Require recent reauthentication; issue a short-lived purpose-bound confirmation challenge to an already verified channel. Throttle/expire atomically; no user enumeration. |
| POST `/api/v1/auth/me/deletion/confirm/` | Validate confirmation/reauth proof once, transactionally initiate deletion/anonymization, revoke refresh tokens and prevent further access. Return an honest accepted/pending/completed state; never call a soft-disable alone completed deletion. |
| GET `/account-deletion/` (public website proposal) | App/company named, publicly reachable without app reinstall, prominent request method, secure identity verification, data erased/retained and real timelines. Rate limit forms and avoid revealing account existence. The Play Console deletion URL must point to the verified resource. |

**Implementation requirements / متطلبات التنفيذ:**

1. **Own-account authorization / صلاحية الحساب نفسه:** authenticate every private request, bind the challenge to request.user/session/purpose, reject another user's UUID/reference, and prohibit role/user-id injection. Do not accept clinic/super-admin JWT authority as permission to erase another user's personal account through self-service.
2. **Data lifecycle / دورة حياة البيانات:** inventory account name/email/phone, lead contact snapshots/notes, clinic memberships, referral relationships, uploaded media, analytics, email/push queues, token tables and backups. Scrub/delete/anonymize as appropriate, including object storage and cached snapshots. Record a minimal non-PII audit event. Exact retention exceptions and time limits need operator approval and truthful public disclosure; no invented legal retention period.
3. **Business continuity / استمرارية العمل:** a clinic administrator's personal-account deletion must not silently cascade-delete clinic records or other patients' information. Define ownership transfer/last-admin handling. Define last-super-admin replacement safely. Provide a request/status path rather than an unexplained permanent denial.
4. **Tokens and cache / الرموز والذاكرة المؤقتة:** blacklist all refresh tokens, enforce deleted/inactive checks for existing access JWTs, invalidate user/private caches and all derived identity snapshots. A previously issued access token must not continue reading history. Make deletion idempotent and safe across partial failures/retries.
5. **User feedback / إبلاغ المستخدم:** distinguish submitted/pending/completed, state real completion timing and retained categories. If asynchronous, add a secure receipt/status/notification design that still works after login is disabled. Do not require sending passwords or OTPs to support staff.

Suggested service boundary (design sketch, not Django edits):

```python
# Proposed only: new authenticated confirmation view, server-bound identity.
user = request.user
proof = serializer.validated_data
reauthentication.verify_once(user=user, purpose="account_deletion", proof=proof)
receipt = account_deletion.request_for_user(user=user)
# Service owns transaction, role/membership safety, data purge and token revocation.
return Response(receipt.public_state(), status=receipt.http_status)
```

### Required backend acceptance tests / اختبارات القبول المطلوبة

- Patient A cannot confirm/request deletion for B; expired/replayed/wrong-purpose OTPs fail; forged role/user fields are ignored/rejected.
- All three account roles have an explicit supported lifecycle; clinic records/other users survive correctly; last-owner handling is tested.
- Old access/refresh tokens are rejected after deletion acceptance as specified, PII snapshots/media/caches are erased/anonymized, and retained data/timeline match the policy.
- Repeated delete requests are idempotent; job/storage failures are recoverable; backup-retention policy is explicit.
- Public web request remains usable without installing/logging into the app, resists enumeration/abuse and never embeds credentials in links/logs.

## P1: object authorization confirmation / تأكيد صلاحيات الكائنات

**Source review:** `apps/leads/views/patient_views.py:MyLeadsAPIView`, `MyLeadsCountAPIView`, `MyLeadDetailAPIView` derive the patient from request.user. Both `/leads/my/<uuid>/` and `/leads/<uuid>/` use the same patient-filtered detail view. URL converters accept UUIDs; no public reference lookup was found. `PatientLeadSerializer` omits clinic internal notes/history. No confirmed cross-patient IDOR was found. This source conclusion is not an authenticated live penetration test.

**AR:** مسارات قائمة وعدد وتفاصيل طلبات المريض تربط السجلات بـrequest.user، ومسارا التفاصيل يستخدمان العرض نفسه مع تصفية المريض. لم نجد بحثاً عاماً برقم المرجع ولا ثغرة مؤكدة تسمح لمريض بقراءة طلب مريض آخر. هذا استنتاج من المصدر وليس اختبار اختراق حي بحسابات إنتاج.

Please run isolated tests with two authorized fixture patients A/B and two clinics: A gets 404 for B's UUID through **both** detail aliases, list/count never include B, clinic A cannot update clinic B's lead, patient cannot use clinic/admin routes. Preserve legitimate clinic/admin operational references. `IsPatient` in `core/permissions/roles.py` also allows super_admin; review that exception against the product's strict role policy. It does not by itself expose other patients through the filtered patient view.

Frontend defence in depth rejects malformed/reference/path detail IDs and discards unexpected internal-note fields in patient parsing; it does not replace these backend checks. The patient UI no longer displays or announces references, while internal IDs and staff displays remain.

## P1: public deployment and link/metadata dependencies / متطلبات النشر والروابط والبيانات

- Verify unauthenticated HTTPS 200 HTML at `https://aestheticway.ae/privacy/` and `/terms/`, with real operator identity, support channel, processors, sensitive-data categories, retention and deletion instructions. Available tools could not retrieve the public pages; no live availability claim is made.
- Confirm SupportInfoView `support_phone`, `support_whatsapp`, `support_phone_display` and configured email/legal contact are current. Flutter now consumes the prefixed keys; email remains an existing app fallback unless a supported source supplies it.
- If create-response direct detail navigation is wanted, add a backward-compatible lead `id` UUID to the successful 201 response; currently only the reference is returned. Do not infer a UUID from that reference. Existing history/status flow is working per user report and remains unchanged.
- For verified incoming `/invite/...`, agree route/attribution behavior and publish correct Android `/.well-known/assetlinks.json` using the **Play app-signing** certificate, plus Apple `/.well-known/apple-app-site-association` with the real team and Bundle ID. Existing `/r/...` redirects and outbound invite text do not establish native Universal/App Links.
- Confirm deployed d1023b0 and test the actual public media fields/Places aggregates/cache invalidation. Archive fixes and fixture renders are not evidence of live delivery. No private/secret API response is needed in Git; use the existing sanitized capture procedure if evidence is supplied.

لا توجد تعديلات Django في هذا الفرع. يجب التحقق من بقاء بصمات ملفات الأرشيف 393 دون تغيير قبل التسليم. / No Django edits belong in this frontend PR; all 393 archived file hashes must remain unchanged at delivery.
