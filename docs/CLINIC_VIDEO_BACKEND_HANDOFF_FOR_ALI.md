> Historical source snapshot: the current 09f49bb findings supersede the old missing-tier/filter/count/reject/gallery items. See [the current integration report](BACKEND_09F49BB_INTEGRATION_QA_REPORT.md) and [remaining confirmed issues](BACKEND_09F49BB_REMAINING_GAPS_FOR_ALI.md).

# Ali — Confirmed clinic video/review contracts / عقود الفيديو ومراجعة العيادة

Backend source: **`1f1e4bf`**, read-only. Date: 2026-10-23. Flutter PR: **#13**.
Evidence: [139 real isolated Django responses](admin-media-polish/controlled-django-contracts.json); all 403 source hashes unchanged. Force-authenticated fixture requests and local storage are not live JWT/R2 verification.

## 1. P0: expose the existing tier read-only in the private profile

**Confirmed:** `apps/clinics/portal_serializers.py::ClinicProfilePortalSerializer` omits `subscription_tier` from GET and PATCH responses. Admin detail and public active-clinic detail return it. A real pending VIP clinic can upload according to the server validator, while public detail returns 404; Flutter therefore cannot safely determine that clinic's entitlement.

**المؤكد:** مُسلسِل الملف الخاص لا يعيد `subscription_tier` في استجابة القراءة أو الحفظ. تفاصيل الإدارة والتفاصيل العامة للعيادة النشطة تعيده. تسمح صلاحيات الخادم برفع فيديو لعيادة VIP قيد المراجعة، لكن تفاصيلها العامة تعيد 404؛ لذلك لا يمكن للتطبيق تحديد أهليتها بأمان دون الحقل الخاص.

Proposed change **for Ali to implement in Django**, not applied by Codex:

```python
class ClinicProfilePortalSerializer(serializers.ModelSerializer):
    # Existing declarations unchanged.
    subscription_tier = serializers.CharField(read_only=True)

    class Meta:
        model = Clinic
        fields = [
            # Keep EVERY existing field.
            # Add:
            "subscription_tier",
        ]
        read_only_fields = [
            # Keep EVERY existing read-only field.
            # Add:
            "subscription_tier",
        ]
```

This is an insertion recipe, **not a replacement of the existing field lists**. Retain all current serializer fields, validation and permissions. Do not make the tier editable or grant Featured uploads.

هذا مثال للإضافة وليس لاستبدال قوائم الحقول الحالية. احتفظ بجميع الحقول والتحقق والصلاحيات. يجب أن يبقى الاشتراك للقراءة فقط، ولا تُمنح فئة Featured صلاحية VIP.

Required Django tests / اختبارات مطلوبة:

- GET and successful profile PATCH return the current DB tier for active and pending assigned clinics.
- A clinic-admin PATCH attempting `subscription_tier="vip"` cannot upgrade Basic/Featured; the stored tier and returned tier remain unchanged.
- VIP binary upload succeeds; Featured/Basic binary upload fails. Null video removal remains supported. Existing inactive-user, suspended/deleted-clinic and membership restrictions remain enforced.
- لا تسمح بتغيير الاشتراك من بوابة العيادة؛ اختبر الرفع الحقيقي، الرفض للفئات غير المؤهلة، وإزالة الفيديو مع الحفاظ على صورة الغلاف.

Flutter currently joins **only** a missing tier from the existing same-UUID public detail when available. It never infers VIP from a badge or `is_featured`. Unknown/unpublished cases expose refresh instead of pretending Basic or VIP. Returning the private field removes this dependency automatically.

## 2. Admin review does not project the complete saved gallery

**Confirmed:** `AdminClinicDetailSerializer` supplies logo, cover, video, branch information and catalog counts, but no complete clinic-gallery projection. Flutter shows only those authorized fields and makes this limitation explicit. No global media traversal, foreign asset query or fabricated route was added.

**المؤكد:** تعيد تفاصيل الإدارة الشعار والغلاف والفيديو والفروع وأعداد المحتوى، لكنها لا تعيد معرض صور العيادة الكامل. يعرض التطبيق الحقول المصرح بها فقط ولا يبحث في وسائط عيادات أخرى.

If full review-gallery inspection is required, extend the **existing authorized Admin detail serializer** with a documented read-only projection of the same clinic's non-deleted gallery assets (stable asset ID, HTTPS URL, MIME, optional actual ordering metadata). Derive clinic scope from the retrieved object; keep Super Admin permissions; exclude unrelated/private patient assets. Define bounded pagination/order explicitly rather than accepting an undocumented Flutter array.

إذا كانت مراجعة المعرض الكامل مطلوبة، أضف إسقاطاً موثقاً للقراءة فقط داخل تفاصيل الإدارة الحالية، مقيداً بالعيادة المعروضة ووسائطها غير المحذوفة. وثّق الترتيب والتصفح، ولا تُظهر وسائط المرضى أو وسائط عيادات أخرى.

## 3. Not diagnosed as backend defects / أمور لم تثبت كعيوب خادم

- The blank physical-device gallery image has no captured URL response/decoder trace. Expiration, private R2 delivery, missing object, HTML response and corruption remain **unverified possibilities**. Please test the affected owned object privately; do not export tokens, clinic contacts or signed URLs.
- فشل صورة الجهاز لا يثبت ضياع الملف في R2. يلزم فحص استجابة الملف ونوعه وصلاحيته فعلياً، مع حماية البيانات والروابط الموقعة.
- Existing profile video uses the clinic cover as poster; there is no separate poster field. Flutter states this and does not invent one. The supported 25-MiB/15-second workflow does not require a new upload endpoint.
- No additional setup-approval gate was found for VIP video. Pending clinics can pass the existing permissions. Production deployment may differ; do not claim live success from fixtures.

Prior setup review count/filter/rejection limitations remain documented in [the earlier review handoff](ONBOARDING_CLINIC_REVIEW_BACKEND_HANDOFF_FOR_ALI.md). This update neither assumes they were fixed nor invents new implementations. No Django, R2 configuration or signing files were changed.
