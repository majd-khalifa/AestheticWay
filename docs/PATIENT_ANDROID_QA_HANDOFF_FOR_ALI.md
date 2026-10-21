# Android patient QA handoff / تسليم ملاحظات جودة تطبيق المريض

Review date: 2026-10-22, Asia/Damascus. Backend inspected: supplied `ca15dc6`, read-only. Flutter: existing PR #10. The lead throttle also shares DRF's default `user` cache scope; see the separate cooldown review for this source-confirmed collision and a proposed isolated scope.

Current observations from the user's physical-device QA brief are distinguished from independently verified source. No new Android screenshot files accompanied this request; earlier screenshot archives predate these observations.

## English: Google rating provenance and stale records

The reported Brautyplus 4.9 / 1204 rating after removal of another clinic's temporary Place ID is **not live-verified here**. Runtime network policy does not allow aestheticway.ae. Do not use fixture renders as production API evidence.

Confirmed source paths:

1. `apps/clinics/models.py:87–105`: Place ID and cached rating/count are separate fields. Model `save()` at line 210 only generates a slug; it does not reset rating provenance.
2. `apps/clinics/portal_serializers.py` allows Place ID updates with rating/sync aggregates read-only. `apps/admin_portal/serializers.py:287` similarly exposes edit fields; no source hook was found clearing aggregates on Place ID changes. Removing the wrong ID alone can leave old numbers in the row.
3. `apps/clinics/services/google_places.py:248–255`: no-ID sync marks `not_configured` but saves only sync status/error/updated_at. It does **not** clear old rating/count/last-sync. Batch sync at line 341 skips missing-ID rows. Cached values survive actual network failures deliberately, which is different from retaining another Place ID's values.
4. Public list/detail serializers expose raw Google fields without a `rating_source_place_id` or last-sync binding. Flutter maps only `google_rating`/`google_reviews_count`, never legacy/internal ratings. Its new badge guard also requires a nonempty Place ID; fresh records with empty ID hide orphan aggregates across Home, directory and detail. No Brautyplus name/value special case exists.
5. `apps/home/views.py:27–47,186–224`: response cache TTL **300 seconds**. Keys are `aw:home:feed:default`, `aw:home:feed:city:<city>`, `aw:home:feed:geo:<rounded-lat>:<rounded-lng>`.
6. `apps/clinics/scale_signals.py:invalidate_clinic_caches` deletes `snap:home_feed` and other snapshot keys via `core/cache_snapshots.py:invalidate_snapshot`. These exact deletes do **not** match the Home response keys above. Therefore a normal clinic save can leave a pre-edit feed until TTL expires. Bulk `QuerySet.update` also bypasses model signals. No cache flush or production mutation was performed.
7. Directory/detail view source has no response-cache decorator. Flutter `SingleFlight` coalesces concurrent GETs and removes completed futures; it does not persist completed JSON. Mounted screens retain model objects until refreshed/reopened. `HomeRepository` replaces cached-feed clinics by UUID only where matched in its one bounded directory page, retaining the original feed entry otherwise or if the optional directory request fails. Server/CDN/device timestamps remain needed.

**Important limitation:** a nonempty ID is necessary, not proof that the ID belongs to that clinic. An old feed still containing the former ID, or a wrong but configured ID, cannot be authenticated by Flutter alone. No claim that Brautyplus is correct on the deployed server is made.

Ali follow-up, after evidence capture:

- Match the actual clinic UUID, current Place ID and intended Google business record privately. Compare a fresh detail response, matching paginated directory record and all affected Home city/geo variants with UTC capture timestamps and deployed revision. Recheck after at least the 300-second Home TTL; proxy/CDN caches may need separate diagnosis.
- On Place ID **change/removal**, clear rating, review count and last-sync provenance atomically; mark sync unconfigured/pending as appropriate. Bind aggregates to the Place ID used to fetch them, and serialize only a matching binding. Preserve cached values on a transient API error only when that binding still matches.
- Align transactional invalidation with actual Home cache keys (e.g. a bounded version token shared by key builder and mutation hooks), including admin edits and sync saves. Never run broad cache flushing or data deletion as an unreviewed repair.
- Re-sync only after confirming the clinic's real Place ID; do not paste another clinic's ID to make stars appear. Review stale aggregate sorting as well as display. Add backend tests for changed/removed IDs, sync error with same ID, all feed key variants and transaction rollback.

### Safe public evidence capture (PowerShell; no patient credentials)

Endpoints: anonymous `GET /api/v1/clinics/?search=Brautyplus&page_size=20`, `GET /api/v1/clinics/<clinic-uuid>/`, paginated `GET /api/v1/clinics/`, and `GET /api/v1/home/feed/` with the same city/geo filter used on the phone. Never include JWTs, cookies, patient history, auth responses, passwords, contact fields or full media URLs in shared output.

Run in a clean PowerShell terminal; do not enable transcription/debug response logging. Discovery below retains public results in memory and prints only the matching UUID. Check spelling privately if no match; never print the raw response.

```powershell
$ErrorActionPreference = 'Stop'
try {
  $publicResult = Invoke-RestMethod -Method Get -MaximumRedirection 0 -TimeoutSec 20 `
    -Uri 'https://aestheticway.ae/api/v1/clinics/?search=Brautyplus&page_size=20'
  $clinicCandidates = @($publicResult.results | Where-Object {
    $_.name_en -eq 'Brautyplus' -or $_.name_ar -eq 'Brautyplus'
  })
  if ($clinicCandidates.Count -ne 1) { throw 'Match not unique' }
  $clinicUuid = [guid]$clinicCandidates[0].id
  Remove-Variable publicResult, clinicCandidates
  # Existing audited script performs anonymous allowlisted projection only:
  ./tool/capture_public_clinic_contract.ps1 -ClinicId $clinicUuid `
    -OutputPath './public-clinic-contract-sanitized.json'
} catch {
  # Do not print $_: it may include response bodies or URLs.
  Write-Host 'Public capture failed or clinic match was not unique. No raw response was shared.'
}
```

The existing script reports UTC time, endpoint success, bounded directory membership, configured-ID boolean, rating/count and media host/hash/shape, without contacts, secrets, patient data or signed media query strings. Its default directory comparison covers only page one; a missing match is **not** proof that the clinic is absent. Ali should inspect further pages/filtered feeds privately using the same allowlist. Do not share private admin sync errors; they can contain keys or vendor response diagnostics.

## English: media/content cleanup, separate from Flutter repairs

| Reported item | Classification and evidence still needed | Authorized next action for Ali/clinic admin |
| --- | --- | --- |
| Anime/cartoon clinic cover/video | User-reported inappropriate upload (B); latest physical pixels/record/URL not independently supplied. A successfully decoded animation is not a Flutter mapping fix. | Identify clinic UUID and selected cover/gallery/video/poster asset privately; review actual bytes, ownership and suitability; replace through native upload after content-owner approval. Do not reuse reference photography. |
| Personal portrait on cosmetic product | User-reported semantic content mismatch (B), not proof of cropping or wrong endpoint. | Match product UUID and media asset, verify independent brand ownership/publication, replace with owner-approved product media or leave genuine media absent. No price/cart/contact additions. |
| Phone-gallery screenshot as staff portrait | User-reported inappropriate image (B), distinguish from decoder failure. | Review practitioner UUID/avatar asset and replace using approved portrait with consent. Never infer identity from image detection or delete automatically. |
| No clinic/product photograph | Missing content (C). Source confirmed repeated generic fallback strip; removed at card consumers. | Upload real content when available; Flutter now keeps the actual clinic/brand identity compact. Do not fabricate clinics, descriptions or images. |
| Broken/expired/blocked image | URL/decoding condition (D), not established for these reported records. | Record redacted host/path hash, MIME, HTTP status, redirect/CORS policy as applicable, signed URL expiry and actual decode result privately. Verify storage access and returned absolute URL. Do not publish patient data or signed URLs. |
| Placeholder-like names/descriptions | User-reported editorial quality issue; no verified UUIDs or current public responses yet. | Review exact records/localized copy with owners; correct or unpublish through existing authorized moderation. Privately check whether sample seeding was used; the presence of `apps/clinics/management/commands/seed_data.py` alone does not prove any production record came from it. Do not synthesize clinical claims. |

Actual Flutter scope (A): redundant generic missing-image strips removed from clinic/product list cards; genuine clinic photos stay 3:2, product packshots stay contained with existing substantial media proportions, practitioners retain reference-led portraits. Directory actions share a row at normal phone text size, then stack on narrow/large-text layouts while keeping at least 48dp button targets and async duplicate guards. Request-history practitioner text wraps instead of overflowing. Source cannot determine whether an image contains a person, an anime scene or a gallery screenshot; no image classifier or content rewrite was introduced.

## العربية: التقييمات والكاش وجودة المحتوى

لم يتم تأكيد استجابة Brautyplus الحية أو استمرار 4.9 و1204 هنا؛ سياسة الشبكة تمنع الاتصال بالمضيف، ولقطات Android الجديدة غير مرفقة. معاينات الاختبار بيانات اصطناعية ولا تثبت بيانات الإنتاج.

- مصدر Django يفصل Place ID عن التقييم والعدد المخزنين. حذف المعرف لا يصفرهما تلقائياً. خدمة المزامنة عند غياب المعرف تغيّر حالة المزامنة فقط، والمزامنة الجماعية تتجاوز السجلات بلا معرف.
- كاش Home مدته 300 ثانية ويستخدم `aw:home:feed:*`، بينما إشارات تعديل العيادة تحذف مفاتيح `snap:home_feed` مختلفة. لذلك قد يبقى رد Home السابق حتى انتهاء المدة رغم تعديل السجل. عرض الدليل/التفاصيل لا يستخدم كاش استجابة في المصدر المتاح.
- Flutter لا يخزن ردود JSON المكتملة في طبقة HTTP؛ يدمج الطلبات المتزامنة فقط. الشاشة المفتوحة تحتفظ بنموذجها حتى التحديث. إثراء Home يطابق UUID من صفحة دليل واحدة محدودة؛ عدم وجود السجل أو فشل الدليل يبقي بيانات التغذية الأصلية.
- حارس العرض الجديد يخفي التقييم إذا كان المعرف فارغاً، ويحافظ على الأرقام الحقيقية ذات المصدر المهيأ. المعرف غير الفارغ وحده **لا يثبت** ملكيته للعيادة؛ رد مخزن يتضمن المعرف القديم يحتاج تصحيحاً خادمياً ودليلاً حياً. لا استثناء باسم Brautyplus ولا أرقام أو معرفات مخترعة.
- المطلوب من علي: مقارنة UUID والتفاصيل والدليل وHome مع أوقات UTC وإصدار النشر، والتأكد من المعرف الحقيقي بشكل خاص. عند تغيير/حذف المعرف تُصفّر المجاميع ومصدر المزامنة بشكل ذري، وتُربط المجاميع بالمعرف الذي جُلبت له. تُصحح مفاتيح الإبطال الفعلية وتُختبر المعاملات، دون مسح شامل للكاش أو حذف آلي لبيانات المستخدمين.
- تعليمات PowerShell أعلاه للقراءة العامة فقط وتنتج ملفاً مسموح الحقول. لا رموز دخول أو كلمات مرور أو هواتف أو مرضى أو ردود خام؛ المطابقة في صفحة الدليل الأولى فقط ليست إثباتاً للغياب من بقية الصفحات.
- الأنمي وصورة الشخص على المنتج وصورة معرض الهاتف مشكلات محتوى مبلغ عنها، ولم نتحقق من سجلاتها الحالية أو ملفاتها. يراجع المسؤول الأصل والمعرف والملكية والموافقة ثم يستبدل المحتوى عبر الرفع الأصلي؛ لا صور مرجعية كأصول إنتاج، ولا توليد بدائل، ولا حذف تلقائي.
- فراغ المحتوى يعالج بهوية مختصرة للعيادة/العلامة بدلاً من لافتات متكررة. فشل الرابط/فك الترميز يحتاج فحص الحالة ونوع الملف والانتهاء وسجلات تخزين منقحة، ولا يجوز افتراضه من موضوع الصورة غير المناسب.
- أزيلت ادعاءات الترخيص التي ينشئها التطبيق من شارات الممارسين؛ تبقى «طبيب» و«ممرض» و«أخصائي» بحسب نوع الخادم، وتبقى قيمة API `licensed_professional` كما هي. أوصاف العيادات الأصلية لا تُحرّف آلياً، ويجب مراجعة أي ادعاءات غير مناسبة ضمن المحتوى نفسه.
- لم تُعدّل ملفات Django أو حماية الرسائل المزعجة أو التوقيع أو تسجيل الدخول أو عزل الأدوار. تفاصيل حدود الطلبات وتوصياتها في `LEAD_COOLDOWN_REVIEW_FOR_ALI.md`.
