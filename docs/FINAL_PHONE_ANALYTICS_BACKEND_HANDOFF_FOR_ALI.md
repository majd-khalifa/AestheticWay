# Final phone and analytics handoff for Ali / التسليم النهائي لعلي

Date: 2026-11-02 (Asia/Damascus). Authoritative supplied source: `5fd66e60d76350ac1feb2a044bf2e8544ecfc318`. Previous source: `52666c1`. **PRODUCTION_BACKEND_VERSION_UNVERIFIED**. Source was inspected/tested read-only, with disposable SQLite/local media, blocked network and synthetic users. No production registration, event, deletion, database or migration operation was performed.

## What is fixed in this source / ما تم إصلاحه في المصدر

- Accounts migration `0007_alter_user_phone`: phone storage is now 64 characters; deletion uses the full UUID. Two same-prefix deletion fixtures both confirmed 200. Previous 24-bit tombstone collision is resolved in source; provider/deployment/device success is not established.
- Analytics migration `0003_remove_analyticsdailyaggregate_unique_daily_aggregate_per_clinic_and_more`: unique event_id UUID, branch attribution, indexes and separate partial uniqueness for platform/day versus clinic/day. Duplicate platform rows are now rejected locally.
- Ingestion now requires event_id; 201/created and 200/duplicate acknowledge it; different body with the same UUID returns 409. Client lead_submitted is rejected. Do not describe the old unrestricted schema as the current schema.
- Registration already uses Python phonenumbers and accepts a valid Syrian E.164 example with a unique valid email (actual local POST201 and read-back). The 20→64 storage change does not explain failure of a 13-character Syrian number.

**عربي:** إصلاح معرّف الحذف الكامل وقيد تجميع المنصة ومعرّف الحدث موجودة ومختبرة محلياً في النسخة الجديدة. لا نستنتج أنها منشورة. نجح تسجيل مثال سوري صحيح؛ لا يمكن تحديد سبب محاولة المستخدم الفعلية دون استجابة منقحة، ولا نفترض صحة الرقم أو عدم تكرار البريد.

## Current API contracts / العقود الموجودة فعلياً

| Endpoint | Verified supplied-source behavior |
| --- | --- |
| POST `/api/v1/auth/register/` | full_name, phone, required email, password, optional device_platform; normalize_phone uses phonenumbers. Invalid/duplicate phone, invalid/duplicate/missing email produce HTTP400 VALIDATION_ERROR with error.fields. Successful201 has user_id/otp_purpose/expires_in; it is not proof of email receipt. |
| POST `/api/v1/analytics/events/` | Actual fields: event_id, event_type, optional anonymous_id/clinic/branch/object_type/object_id/metadata. Types app_open, clinic_view, whatsapp_tap, call_tap, maps_tap; client lead_submitted rejected. Actual statuses:201 created,200 duplicate,409 CONFLICT. No schema_version/coverage ACK exists. |
| GET `/api/v1/admin/analytics/` | Super Admin only; date_from/date_to or from/to; raw event totals, saved Lead count, sparse trends and top ten clinic ID/name/events_count. clinic_id/page are ignored. |
| GET `/api/v1/clinic-portal/analytics/` | Current membership and rolling30-day period; not a Super Admin arbitrary-clinic endpoint. |
| GET `/api/v1/admin/clinics/`, `/admin/clinics/<uuid>/`, `/admin/leads/` | Directory/search/pagination, real clinic inspection and date-filtered operational consultation drill are supported and preserved from reviewed PR #14. Lifetime clinic leads_count is not a period engagement summary. |

Flutter now performs country-aware validation, lossless international paste and safe bilingual error translation. Email is required before POST. It does not claim a valid numbering pattern proves assignment, reachability or ownership. A wrong/duplicate supplied value must still be rejected by Django.

## Remaining P0 ingestion work / متطلبات جمع الأحداث المتبقية

Source-grounded local reproductions (not live-server findings):

1. `_payload_matches` ignores request.user. A second authenticated user replaying another user's UUID/body receives duplicate 200. Bind identity to event ownership before ACK; mismatched actor must never receive persisted/duplicate acknowledgment for its action. Return a non-enumerating conflict/permission response.
2. Branch-only payload derives an unpublished clinic after clinic field validation. Resolve branch→clinic first, then require clinic active, approved/public and not deleted plus branch active/not deleted and belonging to it. Require clinic attribution for clinic/contact types; app_open must remain clinic/branch-free. Define allowed roles explicitly; private staff/admin actions are not patient clinic engagement.
3. Metadata permits arbitrary strings under screen/surface/etc. A synthetic token-like value is accepted. Use bounded enum values (not just key/phone/email substring checks); reject nested/unknown keys, arbitrary object_type/object_id and identity overrides. Keep branch as its validated UUID field. Enforce body size, scoped abuse limits and trusted proxy handling.
4. Saved lead events still contain reference_code/lead_type/service_name. A real local Lead 201 reproduced those metadata key names. Remove inquiry context from new analytics; audit historical minimization under an approved retention policy. Use a transaction/outbox and a unique server-owned Lead event identity so retry/repair never counts a Lead twice. Never ingest client lead_submitted.
5. Version coverage/trusted-event provenance. Existing raw events can be incomplete or poisoned. Do not label them canonical totals or unique people. Retention/backfill/deletion policy and privacy declarations need owner approval.

**عربي:** بقيت ثغرات: ACK لا يطابق هوية المرسل، ويمكن تجاوز أهلية العيادة عبر فرع فقط، وتُقبل قيم نصية حساسة تحت حقول مسموحة. كما تُخزن معلومات الخدمة ورقم الطلب في حدث الطلب الخادمي. يلزم ربط الهوية والتحقق بعد اشتقاق العيادة وقيم metadata محددة ومحدودة وتسجيل الطلب مرة واحدة خادمياً. لا تُفعّل Flutter جمع الأحداث قبل إصلاح ذلك وتأكيد النشر.

## PROPOSED missing reporting routes — NOT PRESENT / مسارات مقترحة غير موجودة

- **PROPOSED GET `/api/v1/admin/analytics/clinics/`** — page/page_size≤100, search (Arabic/English name or exact clinic UUID), date_from/date_to, include_deleted with Super Admin-only access. Include all lifecycle states/tiers and zero-record clinics, not only top ten.
- **PROPOSED GET `/api/v1/admin/clinics/<uuid:clinic_id>/analytics/`** — same window/authorization/archived semantics and verified clinic identity. Patient/clinic roles denied even for a guessed UUID. Do not reuse membership analytics or fetch all patient rows for totals.

Both paths returned 404 locally in supplied 5fd66e6. Flutter does not call them. Register them only after implementation and tests in Ali's repository, e.g. path('analytics/clinics/', AdminClinicAnalyticsList.as_view()) and path('clinics/<uuid:clinic_id>/analytics/', AdminClinicAnalyticsDetail.as_view()). These are proposals, not deployment claims.

Response must echo schema_version/timezone/dates/start/end-exclusive/generated_at, stable clinic ID/localized names, per-type counts, genuine saved leads, canonical total and per-metric coverage. Global app_open is excluded from clinic totals. Unique authenticated accounts must be separately defined and nullable. Never sum top ten as platform totals or add raw lead events to saved Lead counts.

**عربي:** المساران غير موجودين. يجب البحث والترقيم في كل العيادات حسب الفترة، مع تمييز القيمة غير المتوفرة عن الصفر، وفصل المستخدمين الفريدين وفتح التطبيق العام عن إحصاءات العيادة. لا تستخدم Flutter تجميعاً محلياً مضللاً بديلاً عن الخادم.

## Runnable PROPOSED read-side example / مثال Python مقترح قابل للتشغيل

The following complete module uses current model names and was executed only in a disposable isolated process. It is not copied into Django or installed as a route. It deliberately exposes raw recorded_counts separately and keeps canonical total_events/unique users null until a trusted-event/collection-coverage migration is supplied. Deploying this scaffold alone does not satisfy complete trusted analytics.

```python
# PROPOSED ONLY: apps/admin_portal/analytics_reporting.py; not installed/deployed.
from datetime import datetime, time, timedelta, timezone
from uuid import UUID
import re
from zoneinfo import ZoneInfo
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from apps.admin_portal.permissions import IsSuperAdmin
from apps.analytics.models import AnalyticsEvent
from apps.clinics.models import Clinic
from apps.leads.models import Lead

DUBAI = ZoneInfo('Asia/Dubai')
EVENTS = {
    'clinic_views': 'clinic_view', 'whatsapp_taps': 'whatsapp_tap',
    'call_taps': 'call_tap', 'maps_taps': 'maps_tap',
}

class ReportQuery(serializers.Serializer):
    date_from = serializers.DateField(required=False, input_formats=['%Y-%m-%d'])
    date_to = serializers.DateField(required=False, input_formats=['%Y-%m-%d'])
    search = serializers.CharField(required=False, allow_blank=True, max_length=120)
    include_deleted = serializers.BooleanField(required=False, default=False)

    def to_internal_value(self, data):
        for key in ('date_from', 'date_to'):
            if key in data and not re.fullmatch(r'\d{4}-\d{2}-\d{2}', str(data[key])):
                raise ValidationError({key: 'Use exact YYYY-MM-DD'})
        return super().to_internal_value(data)

    def validate(self, data):
        today = datetime.now(DUBAI).date()
        start = data.setdefault('date_from', today - timedelta(days=30))
        end = data.setdefault('date_to', today)
        if start > end or (end - start).days >= 366:
            raise ValidationError('Use an ordered report window of at most 366 calendar dates.')
        return data

class ReportPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


def report_scope(request):
    query = ReportQuery(data=request.query_params)
    query.is_valid(raise_exception=True)
    q = query.validated_data
    start = datetime.combine(q['date_from'], time.min, DUBAI).astimezone(timezone.utc)
    end = datetime.combine(q['date_to'] + timedelta(days=1), time.min, DUBAI).astimezone(timezone.utc)
    clinics = Clinic.objects.all()
    if not q['include_deleted']:
        clinics = clinics.filter(deleted_at__isnull=True)
    # Do not filter to active/top-ten clinics: this is an authorized Admin report.
    search = q.get('search', '').strip()
    if search:
        match = Q(name_en__icontains=search) | Q(name_ar__icontains=search)
        try:
            match |= Q(pk=UUID(search))
        except ValueError:
            pass
        clinics = clinics.filter(match)
    return q, start, end, clinics.order_by('name_en', 'pk')


def clinic_rows(clinics, start, end):
    ids = [c.pk for c in clinics]
    # Two grouped queries for the selected page, not one query per clinic/metric.
    events = AnalyticsEvent.objects.filter(
        clinic_id__in=ids, timestamp__gte=start, timestamp__lt=end,
        event_type__in=EVENTS.values(),
    ).values('clinic_id').annotate(**{
        key: Count('pk', filter=Q(event_type=kind)) for key, kind in EVENTS.items()
    })
    event_map = {r['clinic_id']: r for r in events}
    lead_map = dict(Lead.objects.filter(
        clinic_id__in=ids, created_at__gte=start, created_at__lt=end,
    ).values('clinic_id').annotate(n=Count('pk')).values_list('clinic_id', 'n'))
    rows = []
    for clinic in clinics:
        counts = {key: event_map.get(clinic.pk, {}).get(key, 0) for key in EVENTS}
        counts['lead_submissions'] = lead_map.get(clinic.pk, 0)
        rows.append({
            'clinic_id': str(clinic.pk), 'name_en': clinic.name_en, 'name_ar': clinic.name_ar,
            'status': clinic.status, 'setup_status': clinic.setup_status,
            'recorded_counts': counts,
            # Never count raw lead_submitted rows a second time, or assign app_open.
            'recorded_total_events': sum(counts.values()),
            # Old events lack verifiable trust/collection provenance. These remain
            # unavailable until Ali supplies a validated-event/coverage migration.
            'total_events': None, 'unique_authenticated_accounts': None,
            'coverage': {'state': 'unverified_legacy', 'reason': 'No trusted collection provenance'},
        })
    return rows


def report_metadata(q, start, end):
    return {
        'schema_version': 2, 'timezone': 'Asia/Dubai',
        'date_from': q['date_from'].isoformat(), 'date_to': q['date_to'].isoformat(),
        'start_utc': start.isoformat(), 'end_utc_exclusive': end.isoformat(),
        'generated_at': datetime.now(timezone.utc).isoformat(),
    }

class AdminClinicAnalyticsList(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request):
        q, start, end, clinics = report_scope(request)
        paginator = ReportPagination()
        page = paginator.paginate_queryset(clinics, request, view=self)
        result = paginator.get_paginated_response(clinic_rows(page, start, end))
        result.data.update(report_metadata(q, start, end))
        return result

class AdminClinicAnalyticsDetail(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request, clinic_id):
        q, start, end, clinics = report_scope(request)
        clinic = get_object_or_404(clinics, pk=clinic_id)
        return Response({
            **report_metadata(q, start, end),
            'result': clinic_rows([clinic], start, end)[0],
        })
```

Offline validation of this exact example: 21 clinics across all tiers, page2 beyond 20/top-ten, Arabic and UUID search, clinic detail, zero rows, permissions401/403/403/200, malformed/reversed/oversized dates, Dubai UTC boundaries, and **four list queries** (count + clinic page + grouped events + grouped leads). Two raw lead_submitted rows plus one real saved Lead are counted only once as a saved Lead; global app_open is never assigned to the clinic. Source code was executed from memory, not a Django file. [Proposal evidence](final-phone-analytics/proposal-evidence.json).

### Required completion beyond the scaffold

Add trusted collection provenance, including an explicit validated-event marker/schema and collection start/retention bounds. Defaults/backfills must not mark old events trusted. Compute canonical totals only over verified eligible events plus genuine saved Leads, once each; return unavailable/partial coverage outside that window. Add paged per-clinic daily series/comparison only where real covered data exists. Keep existing unversioned raw fields backward-compatible; negotiate the new response version rather than silently changing meanings.

Use the supplied clinic/event/timestamp and lead clinic/created_at indexes; inspect PostgreSQL EXPLAIN ANALYZE with representative sanitized data. Avoid the existing directory's multi-join count multiplication and one query per clinic. Document query/payload/latency limits and bounded windows. Nullable unique-user counts are not fabricated from events or registered accounts.

### Migrations and Django regression acceptance

- Confirm accounts0007 and analytics0003 applied in the actual deployment. Before adding partial uniqueness to old data, privately inspect duplicates; agree deterministic repair/recomputation and backup/rollback. No destructive cleanup or migration was executed here.
- New event trust/coverage and canonical server-lead uniqueness require explicit migrations. Preserve OTP purpose, verified channels, last-admin/sole-clinic-admin protections, JWT invalidation and deleted-account login checks.
- Test invalid/duplicate/valid international phones and email, required email, existing uniqueness, provider failure after account creation, inactive/deleted records and concurrent registration. Persisted User does not prove OTP delivery. No test-specific phone bypass.
- Test identity-bound same-ID retry, timeout after commit, concurrent duplicate/conflict, client lead rejection, branch-only pending/deleted/inactive/foreign clinic, missing clinic, app_open attribution, role/session switching, metadata enums/size/sensitive values and transaction rollback.
- Test21+ clinics, all tiers/statuses/archived states, every page, bilingual search, empty/zero/uncollected states, known counts, canonical versus raw totals, lead rejection/deduplication, Dubai midnight/leap dates and stable ordering. Test PostgreSQL concurrency/uniqueness and query budgets; SQLite is insufficient for release sign-off.

**عربي:** المثال يعمل على النماذج الحالية لكنه يعرض السجلات الخام مع حالة تغطية غير متحققة، ولا يختلق إجمالياً موثوقاً أو مستخدمين فريدين. يلزم إكمال علامة الثقة وفترة التغطية والترحيلات واختبارات PostgreSQL والتزامن والأذونات. لا يكفي نشر المثال وحده لاعتماد التحليلات للإنتاج.

## Deployment/version verification checklist / قائمة التحقق من النشر

Status: **PRODUCTION_BACKEND_VERSION_UNVERIFIED; MIGRATION_STATUS_UNVERIFIED**.

Ali should privately correlate the actual running Gunicorn/Celery release artifact SHA and source import path, not just a local checkout or a stale OpenAPI page. Record the deployed commit, worker rollout, API/schema build identifier, and readonly `python manage.py showmigrations accounts analytics --plan` output (no database DSNs/credentials). Verify required migrations are checked and schema constraints/indexes exist; do not infer application from a ZIP.

On explicitly approved staging fixtures: prove valid Syrian registration→201→canonical read-back→real verified-channel OTP receipt→verification/login; prove each error class with sanitized HTTP/code/field names. Prove saved Lead reconciliation and event deduplication after ingestion safety fixes. Compare the report with known actions and exact Dubai bounds. Keep raw phones, emails, notes, JWTs, OTPs, full GPS and payload bodies out of shared logs.

Only after staged acceptance and owner authorization should operators verify equivalent production behavior using approved accounts. Codex did not mutate or probe live registration/analytics/deletion. Existing physical client passes stay owner-reported; replacement Android QA and provider verification are still required.

**عربي:** يجب توثيق معرّف النسخة التي تشغلها الخدمات فعلياً وحالة الترحيلات، وليس معرّف الأرشيف فقط. اختبر التسجيل والإرسال الحقيقي والتحقق وإحصاءات الأفعال على staging أولاً، وشارك الحالة والكود وأسماء الحقول فقط دون بيانات شخصية أو رموز. لا يوجد إثبات نشر أو نجاح جهاز جديد من هذا التنفيذ.
