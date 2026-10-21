# Django scalability handoff for Ali / تسليم قابلية التوسع لعلي

Date / التاريخ: 2026-10-20. Django references were **read-only**. Ali owns every backend/infrastructure change below. Examples are integration proposals anchored to the supplied source, not deployed or benchmarked backend patches. No live topology, SQL plan, service capacity, cache hit ratio or production credentials were inspected.

**لم نعدّل Django أو البنية التحتية.** الأمثلة مقترحات دمج مبنية على المصدر؛ علي مسؤول عن تنفيذها واختبارها ونشرها. إعدادات المستودع لا تثبت ما هو منشور فعلياً. لم نجْر اختبار ضغط أو استعلامات على بيانات المرضى أو الخادم الحي.

Start from the security fixes in [SECURITY_HARDENING_FOR_ALI.md](SECURITY_HARDENING_FOR_ALI.md). Preserve patient/clinic ownership, read-only Super Admin lead supervision, media validation and token controls while optimizing. Optimization is never permission bypass or fabricated data. See [SCALABILITY_LOAD_TEST_PLAN.md](SCALABILITY_LOAD_TEST_PLAN.md) for staging authorization and measurement requirements.

## 1. Verified source versus deployment / المصدر مقابل النشر

| Component | Source fact | Deployment evidence still required |
|---|---|---|
| PostgreSQL | `config/settings/base.py:95` selects PostgreSQL, CONN_MAX_AGE default 60 and connect_timeout 10 | Real version, CPU/RAM/IOPS, extensions, max_connections, pool/proxy, active/waiting sessions and backups. |
| Cache/queue | Base settings configure django-redis with five-second socket/connect timeouts, Redis URL default localhost, Celery broker/result backend and task limits | Actual Redis/Celery deployment, shared versus isolated namespaces, capacity, failover, queue lag and worker isolation. |
| Object storage | `USE_R2_STORAGE` switch, optional AWS bucket, otherwise filesystem; `config/storage_backends.py` R2 S3-compatible class, random names, overwrite false | Which branch is active, CDN/bucket ACL, signing/expiry, origin/cache behavior, object lifecycle and transfer cost. Do not assume Cloudflare/AWS. |
| App/edge | No authoritative deployed worker/replica/edge topology in the inspected reference | WSGI/ASGI server, threads/workers, resource limits, TLS/HTTP version, proxy keepalive/compression and request/queue limits. |
| Queries/cache | Pages and some joins/indexes already exist; Home already caches for 300 seconds | EXPLAIN/actual query counts, p95/99 latency, cache hit ratio and invalidation behavior in representative staging. |

**المطلوب:** قدم وصفاً غير سري للبنية الفعلية والنسخ وحدود الموارد قبل ضبط العمال أو الاتصالات. لا تستخدم افتراضاً بأن وجود إعداد Redis أو R2 يعني أنه يعمل في الإنتاج.

## 2. P0 — Bound pages and make order deterministic / حدود الصفحات وترتيب ثابت

`core/pagination/standard.py:StandardResultsPagination` defaults to 20 and accepts page_size/per_page, but **max_page_size=100**; CursorResultsPagination also allows 100. Flutter now always requests 20 across public, Clinic and Admin lists. `apps/admin_portal/views.py` defines its own pagination, so inspect that maximum too. `HomeCategoriesAPIView` has pagination disabled; keep Home's bounded category preview separate from a full management directory.

Proposal: set standard maximum to 20; inventory exceptions and version explicitly justified contracts instead of allowing arbitrary caller sizes. Retain envelope keys count/next/previous/results/current_page/page_size for current Flutter. A client `.take(20)` only protects parsing/rendering; it cannot undo network transfer or JSON decoding of an oversized response.

```python
from core.pagination import StandardResultsPagination
from rest_framework.filters import OrderingFilter

class BoundedCatalogPagination(StandardResultsPagination):
    page_size = 20
    max_page_size = 20

class StableOrderingFilter(OrderingFilter):
    def get_ordering(self, request, queryset, view):
        ordering = super().get_ordering(request, queryset, view)
        if not ordering:
            return ordering  # preserve explicitly annotated clinic queryset order
        fields = list(ordering)
        if not any(f.lstrip("-") in ("pk", queryset.model._meta.pk.name) for f in fields):
            fields.append("pk")
        return fields

# ProductListAPIView: pagination_class = BoundedCatalogPagination
# ordering = ("-created_at", "-pk")
# Replace its OrderingFilter with StableOrderingFilter where caller ordering
# is supported, so ?ordering=name_en also has a tie breaker.
# ClinicListAPIView.get_queryset: append "pk" to order_by_args after existing
# tier/distance/rating/display/name ordering. Do not erase tier ranking.
```

`ProductListAPIView` orders only by created_at; clinic ordering ends with name_en; practitioners use display_order/name_en; several offers/articles directories also lack a unique tie-breaker. Add deterministic pk ordering on all public/portal/Admin variants without changing paid-tier policy. Existing branch/detail summaries already include pk tie-breakers; retain them.

Page-number ordering with a unique tie-breaker is deterministic for a fixed dataset, but concurrent insertions/deletions can still shift offsets. Flutter deduplication prevents duplicate display, not all possible omissions during churn. Only introduce cursor/keyset pagination through a versioned, tested contract: current Flutter increments integer pages and treats next as a boolean; it does not send cursor tokens. Do not switch the existing route to CursorResultsPagination and claim compatibility. Use counts where necessary; consider `has_more`/limit+1 or a cursor endpoint for very deep high-churn catalogs after client support and UX review.

**تأثير التوافق والترحيل:** لا ترحيل بنيوي للحدود والترتيب. قد يتأثر عميل قديم يطلب 100، لذا نسّق النشر وتحقق من جميع الصفحات. تحويل الصفحة إلى cursor يحتاج عقداً جديداً وتعديلاً في Flutter؛ لا تنفذه خفية. اختبر 520 سجلاً، التعادل في الوقت/الاسم، حذف/إضافة أثناء التصفح، وعدم تغيير ترتيب VIP/Featured.

## 3. P0 — Fix confirmed join and overfetch paths / الربط والتحميل الزائد

**Products/offers/articles:** public queries already select_related clinic/media_asset (articles also author_practitioner). Keep these joins; do not claim they are absent. Product/offer compact clinic serializers already exist. Audit remaining nested properties rather than adding prefetch indiscriminately.

**Practitioners:** `apps/practitioners/views.py:PractitionerListAPIView.get_queryset:36` selects only clinic. `PublicPractitionerListSerializer.avatar_url` invokes `Practitioner.avatar_url`, which dereferences media_asset at `models.py:97`. Rows with an asset can therefore add per-row queries. The detail serializer's related treatment filter may bypass a broad prefetch; measure the exact accessed queryset.

**Home:** `get_home_featured_ads_queryset:54` selects clinic but `FeaturedAd.image_url` / FeaturedAdSerializer.get_video_url access media_asset. Join it. `get_home_offers_queryset` currently serializes a broad nested clinic including lengthy descriptions/contacts; decide a compact Home-specific summary without removing required branding/map/real Google data.

```python
# Preserve every existing role/status/deleted/active filter and ordering.
# At the end of PractitionerListAPIView.get_queryset:
# return <existing-filtered-queryset>.select_related("clinic", "media_asset")

# Existing Home query helper:
# FeaturedAd.objects.filter(...).select_related("clinic", "media_asset")...

# Query-count regression structure in an isolated backend test:
from django.db import connection
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIRequestFactory
from apps.products.views import ProductListAPIView

def measured_product_query_count():
    request = APIRequestFactory().get("/api/v1/products/", {"page_size": 20})
    with CaptureQueriesContext(connection) as captured:
        response = ProductListAPIView.as_view()(request)
        response.render()  # force serializer evaluation
    assert response.status_code == 200
    assert len(response.data["results"]) <= 20
    return len(captured)
# Seed 1 then 20 valid synthetic related rows and compare counts. The desired
# invariant is constant query count, not an invented measured count here.
```

**Clinic detail:** `ClinicDetailAPIView` broadly prefetches all branches/practitioners/treatments__category. Its serializer then filters/orders/slices each related manager to six, which can issue fresh queries while the broad prefetch has already materialized the entire relation. This is concrete wasted work even for a single detail request. Remove unused broad prefetches and let the existing bounded summary queries run, or use matching Prefetch(to_attr=...) queries **and change the serializer to read those attributes**. Prefetch plus a subsequent different `.filter()` does not solve the problem. Keep paginated View All routes for the rest of the data.

Do not apply `.only()` mechanically: an omitted accessed field causes deferred per-row SQL. Bound lead notes/history, category selectors and Admin dashboard summaries; avoid embedding all private records. Existing patient/clinic filters and readonly supervision remain mandatory.

**التطبيق والاختبار:** افحص عدد الاستعلامات عند 1 و20 سجلاً مع أصول وسائط حقيقية. أضف الربط الناقص للوسائط، وأزل prefetch غير المستخدم في تفاصيل العيادة. لا تحمّل جميع الأطباء/الفروع ثم تقص العرض إلى ستة. لا ترحيل مطلوب، ويجب اختبار كل حقل في السيريالايزر قبل تقليص البيانات.

## 4. P0 — Home contract and cache invalidation / عقد Home وإبطال الكاش

Current Home: max 8 categories, 10 ads, 10 offers and 10 nearby clinics; cached for 300 seconds with rounded two-decimal geo keys. These are useful bounds. `PublicClinicSerializer` omits subscription/media metadata used by the recovered carousel. Flutter therefore performs **two bounded reads**, now overlapping. Ali can remove that dependency with a versioned enriched Home DTO: authentic tier, normalized logo/cover/video URLs and at most 20 active partner summaries with city/geo filtering. Reuse ranked query helpers and compact safe fields; do not invent ads or use is_featured as a paid subscription substitute. Flutter must explicitly support the new capability before removing its directory fallback.

**Confirmed invalidation mismatch:** Home reads `aw:home:feed:default`, `aw:home:feed:city:*` or `aw:home:feed:geo:*`. `apps/clinics/scale_signals.py` invalidates `snap:home_feed` / `snap:clinics_list` and clinic snapshot names. Those are different keys; transaction-on-commit handling alone does not invalidate the Home cache. Independent brand Product/Article changes with clinic=None also bypass the clinic-scoped invalidator. Resolve the actual key scheme, not just signal registration.

A compatible generation namespace avoids unsafe wildcard scans and protects against an older cache-fill request writing into the current generation after a content edit:

```python
import uuid
from django.core.cache import cache
from django.db import transaction

PUBLIC_VERSION_KEY = "aw:public-content:version:v2"

def public_generation():
    return cache.get_or_set(PUBLIC_VERSION_KEY, lambda: uuid.uuid4().hex, timeout=None)

def invalidate_public_content():
    transaction.on_commit(lambda: cache.set(
        PUBLIC_VERSION_KEY, uuid.uuid4().hex, timeout=None
    ))

# In HomeFeedAPIView, preserve the existing normalized city/geo key builder:
# cache_key = f"{get_home_feed_cache_key(city, lat, lng)}:v2:{public_generation()}"
# Call invalidate_public_content on approved changes/deletion to Clinic, Offer,
# FeaturedAd, Category, Product and Article, including independent global records.
# Keep clinic-scoped invalidation where needed; bulk update paths must explicitly
# invalidate too because QuerySet.update does not fire post_save.
```

Handle cache outages with monitored bounded DB fallback rather than an unbounded stampede. Add a measured cache-fill lease: one worker rebuilds, other callers use an eligible bounded stale **public** snapshot or receive a short Retry-After response. Do not serve stale suspended/moderated content or private records. Lock wait/lease durations must fit measured build time/request budget, and stale eligibility must account for signed media expiry. No universal lock TTL or production hit-ratio result is asserted here.

Never cache patient leads, tokens or per-user profile responses under a public key. Public catalog cache keys include normalized filters, page/size, ordering and relevant locale/version. Do not key by Authorization or unbounded raw search/coordinates, and do not accidentally use private `request.user` personalization in a shared DTO. Use explicit cache policy for public summaries; private responses should use no-store unless a separately approved user-scoped design exists.

**Signed URLs/ETag:** currently there is no demonstrated end-to-end ETag/304 contract. Do not send If-None-Match from Flutter without a matching cached body/identity/expiry strategy. Prefer caching safe object IDs/immutable paths then signing private URLs close to response generation, or cap response TTL at `min(content freshness, earliest signed expiry - clock skew margin)`. Define an `expires_at` contract and re-fetch behavior for private media; client RAM pixels are not proof of ongoing access. Never append cache-busting queries to a signed URL. Public immutable thumbnails can have long cache headers; private signed resources cannot be treated as permanently public.

**الترحيل والنشر والتراجع:** لا ترحيل بنيوي لتغيير مفاتيح الكاش أو DTO إضافي. استخدم namespace جديداً، واترك القديم ينتهي دون FLUSHALL. اختبر حفظ/إيقاف/حذف العيادة والإعلان والمنتج المستقل بعد transaction commit، وكذلك bulk updates وسباق إعادة البناء. عند التراجع أبقِ سياسة الخصوصية والإبطال؛ يمكن تعطيل الكاش المتأثر مؤقتاً بدلاً من تقديم محتوى غير صالح. إزالة طلب Flutter الثاني تحتاج تنسيق عقد جديد وليست نتيجة تلقائية لنشر هذا المقترح.

## 5. Query plans, search and indexes / الخطط والفهارس والبحث

Products already has composite indexes on clinic/status/active/deleted and status/active/deleted/created_at. Clinics already indexes status/deleted/tier/city and other ordering fields. Do not blindly recreate these. Retrieve actual migrations/catalog indexes and use representative filtered query plans, including OFFSET depth and COUNT(*), before adding indexes.

```python
from apps.products.models import Product, ContentStatus

qs = Product.objects.filter(
    is_active=True, status=ContentStatus.ACTIVE, deleted_at__isnull=True
).select_related("clinic", "media_asset").order_by("-created_at", "-pk")
# Start with estimated plan on isolated staging; no patient data is printed.
plan = qs[:20].explain(format="json", analyze=False)
# After explicit staging approval compare ANALYZE/BUFFERS with real fixture
# cardinality, cold/warm cache, filters and deeper pages. Never infer IOPS or
# concurrency capacity from SQL construction or a SQLite in-memory probe.
```

Potential PostgreSQL candidate, **only if the plan proves it useful and not redundant**, is a partial `(created_at DESC, id DESC)` live-product index. Clinic geo ranking combines tier Case, distance, rating and names; one naive B-tree will not eliminate every annotated sort. Verify PostGIS deployment before relying on spatial functions/indexes. Source has a non-Postgres fallback, not proof of production PostGIS.

```python
# Proposed PostgreSQL-only migration shape; replace dependency after reviewing
# the real migration graph. This block is not an applied migration.
from django.db import migrations, models
from django.db.models import Q
from django.contrib.postgres.operations import AddIndexConcurrently

class Migration(migrations.Migration):
    atomic = False
    dependencies = [("products", "REPLACE_WITH_REVIEWED_LATEST_MIGRATION")]
    operations = [AddIndexConcurrently(
        model_name="product",
        index=models.Index(
            name="product_live_created_id",
            fields=["-created_at", "-id"],
            condition=Q(status="active", is_active=True, deleted_at__isnull=True),
        ),
    )]
```

Search uses DRF SearchFilter across English/Arabic names/descriptions/brands. B-tree name indexes do not generally accelerate `%contains%` ILIKE search. Evaluate pg_trgm GIN on the actual matching expressions/normalization or a deliberate full-text design; DRF/Django may use UPPER/casts, so a raw trigram column index may not match the generated expression. Confirm Arabic tokenization, Unicode, ranking, minimum query length and query plans before adopting a search service. Bound query length/filter cardinality and preserve correct full-dataset filtering. Do not fetch 500 records to search on the phone.

**Database effects/rollback:** new indexes require reviewed migrations, write amplification/disk estimates and measured plan comparison. Build concurrently on PostgreSQL, monitor locks/IO, verify index validity and use a concurrent removal strategy for rollback. Do not run this illustrative migration unchanged, on SQLite, or during an unapproved production test. Stable ordering and joins need no schema migration. Reassess large counts only when plans show a problem; 520 records alone does not justify a new database/search platform.

**بالعربية:** الفهارس المركبة موجودة بالفعل. قارن EXPLAIN والبحث والصفحات العميقة وعدّ النتائج قبل إضافة فهرس. بحث contains بالعربية والإنجليزية يحتاج دراسة التعبير الفعلي وpg_trgm أو بديل مناسب، وليس افتراض أن فهرس الاسم يكفي. إنشاء فهرس جديد يحتاج ترحيلاً ومراقبة وعودة آمنة، ولا يثبت قدرة 1000 مستخدم.

## 6. Media variants, video and external services / الوسائط والفيديو والخدمات الخارجية

The server validates size/type and uses random immutable storage paths. Add a bounded post-validation variant pipeline: product contain variants at useful physical widths (e.g. 320/640/960), avatar small variants, cover crops at declared aspect ratios, preserving an appropriate high-quality original/detail variant. These are proposed sizes, to tune with device/DPR/media measurements. Re-encode safely after security validation/EXIF policy; do not reduce every original to a blurry thumbnail. Use supported JPEG/WebP/PNG as appropriate, test decoder/library security updates and document orientation/alpha handling.

Variant URLs need immutable version/content-hash paths, width/height/MIME and expiry metadata where private. Keep the original URL for legacy clients during rollout; do not mutate its signature. A proposed variants JSON field or related MediaVariant model requires a migration/backfill/job-status design; it does not exist simply because Flutter can decode smaller. Prioritize active catalog variants lazily/bounded in a queue, and avoid deleting originals while referenced. Signed private thumbnails need the same authorization and expiry policy as originals.

VIP ads keep the 15-second policy. Provide efficient, validated mobile video encoding, poster, bitrate/resolution/duration metadata and range requests/CDN delivery; use HLS only if measured benefit justifies added infrastructure. Limit processing concurrency/memory, reject unprobeable duration per the security handoff, preserve no offscreen autoplay/no simultaneous playback in Flutter. CDN range caching and device codec memory must be measured independently of API JSON latency.

`apps/clinics/services/google_places.py` already has fixed-host requests, configurable timeouts/retries, cached-field preservation, a distributed sync lock and active-clinic iteration; `apps/clinics/tasks.py` invokes scheduled sync. Public clinic list/detail do not call Places per user request in this snapshot. Preserve that design. Verify scheduler/credentials/quota and bounded background concurrency rather than moving Places into the request path. Timeouts/retries for storage, email/FCM and Places must fit queue budgets with jitter/caps and clear delivery status; never replay a consultation because a notification failed.

**الترحيل والتوافق:** أضف صوراً مصغرة مشتقة آمنة مع أبعاد وصلاحية واضحة، ولا تستبدل الأصل أو توقع رفع Flutter المحدود للأبعاد أن يقلل بايتات الملف الأصلي في الشبكة. أي جدول/حالة معالجة جديدة تحتاج ترحيلاً وbackfill محدوداً وخطة تراجع تحافظ على الأصول. تحقق من تشغيل المهام وCDN والمدة الفعلية للفيديو قبل ادعاء الجاهزية.

## 7. Workers, connections and horizontal scaling / العمال والاتصالات والتوسع

Define an actual connection budget before changing counts: application replicas × worker processes × potential DB-using concurrency, plus queue/scheduler/admin/maintenance connections, must fit the database/pool's tested budget with headroom. Increasing Gunicorn workers by a generic CPU formula can make DB saturation worse. Measure CPU-bound serialization, blocking IO, request service time and queueing; tune WSGI threads/processes or ASGI under that workload. Do not multiply connections blindly or switch server types as a substitute for removing N+1.

If actual infrastructure uses PostgreSQL, evaluate a supported connection pool/proxy and health checks. Transaction pooling requires testing session-dependent features, server-side cursors, prepared statements and ORM iteration settings. Confirm `CONN_MAX_AGE`/health behavior with the chosen pool and rollout; no pool was verified in this environment. For other deployment choices use compatible equivalents instead of assuming managed AWS/Cloudflare services.

Use shared cache/queue/object storage where horizontal replicas need coordination; local process memory is not a cross-worker throttle/idempotency lock. Apply the security handoff's atomic OTP/rate/idempotency changes. Enforce durable patient/action-scoped lead idempotency through a reviewed transactional design; current consultation duplicate lock is short-lived and excludes offers/products. A database-backed idempotency table/unique constraint requires migration and response-replay/expiry tests. Flutter never blindly retries writes.

Edge checklist: TLS termination, upstream keepalive/connection reuse, bounded request/body/timeouts, separate public cache and private no-store policy, JSON compression (not double-compressing already-compressed media), CDN origin limits and safe CORS. Private user data cannot enter a shared public proxy cache. Configure graceful shutdown/drain, health/readiness probes, bounded queues, retry ceilings and resource/cost alarms before adding replicas. Test Redis outage, worker death and peak recovery safely in staging.

**Monitoring/backups:** route-template/status latency and in-flight gauges, API worker CPU/RSS/restarts, query counts/plans/locks/connections, cache hit/eviction/latency, queue lag/outbox failures, CDN egress/origin hit ratio and correlation IDs without patient details/tokens/signed queries. Verify encrypted database backups, object retention/versioning as appropriate, restore tests and owner-approved RPO/RTO. Neither a backup setting nor an untested snapshot establishes recoverability.

**بالعربية:** حدّد ميزانية اتصالات قاعدة البيانات لجميع نسخ التطبيق والمهام قبل زيادة العمال. وجود Redis أو التخزين في ملف الإعداد ليس دليلاً على نشره. اختبر pooling والتوسع الأفقي والتوقف التدريجي والنسخ الاحتياطي والاستعادة. راقب p95/p99 والاتصالات والصفوف والذاكرة والتكلفة دون بيانات شخصية. لا تعالج الحمل بتعطيل الصلاحيات أو حدود OTP أو بإعادة إرسال طلبات المرضى.

## 8. Acceptance, deployment and rollback / القبول والنشر والتراجع

1. Inventory real infrastructure, deploy the security fixes, seed isolated fixtures and capture baseline plans/query counts/device traces. No capacity claim before representative measurement.
2. Deploy compatible 20-row/stable-order/join/overfetch fixes, test all API envelopes and authorization, then cache generation/invalidation and enriched Home capability. Test cold/warm and failure behavior.
3. Add only plan-justified indexes with reviewed migrations, media variant pipeline and explicit mobile capability support. Keep old URL fields and page routes during transition.
4. Establish numerical SLO/resource budgets after baseline; run authorized 100→500→1,000 client scenarios with actual telemetry and operational abort owner. Widget/Future counts do not certify capacity.
5. Stage immutable deployment artifacts, verify migration plans and backup restore readiness, monitor rollouts. Roll back a bad index independently, expire/version changed cache keys, disable new media processing if needed and retain existing originals. Never roll back to an unsafe permission/token/media validation path.

**القبول:** يجب أن يثبت الاختبار صحة البيانات والصلاحيات مع الأداء، لا سرعة استجابة فارغة أو بيانات مختلقة. وثّق SHA التطبيق والخادم والبنية والحمل المعروض والمحقق والأخطاء والاستعادة والقيود. جميع المقترحات هنا تعتمد على تنفيذ علي والتحقق المرحلي؛ لم نعدّل Django ولم نشهد دعماً منشوراً لعدد 1000 عميل.
