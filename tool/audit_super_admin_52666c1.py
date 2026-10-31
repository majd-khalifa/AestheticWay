"""Offline source evidence, never a live production analytics/deletion probe."""

import argparse
from datetime import datetime, timezone as dt_timezone
import hashlib
import json
import logging
import os
from pathlib import Path
import sys
from uuid import UUID

from isolated_django_audit import isolated_django_audit


parser = argparse.ArgumentParser()
parser.add_argument("--backend-root", required=True, type=Path)
parser.add_argument("--output", required=True, type=Path)
args = parser.parse_args()
root = args.backend_root.resolve()
args.output = args.output.resolve()
if args.output.is_relative_to(root):
    raise RuntimeError("Audit output must remain outside the read-only backend")


def inventory():
    return {
        p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in root.rglob("*") if p.is_file()
    }


before = inventory()
source_tree_sha256 = hashlib.sha256(
    json.dumps(before, sort_keys=True, separators=(",", ":")).encode()
).hexdigest()
if source_tree_sha256 != "c4358997205f608b350169e7b7985187108918fd30eb8868b68063cf93a792d4":
    raise RuntimeError("Backend source does not match the supplied 52666c1 snapshot")
sys.dont_write_bytecode = True
sys.path.insert(0, str(root))
os.environ["DJANGO_SETTINGS_MODULE"] = "config.settings.testing"
os.environ["SECRET_KEY"] = "isolated-synthetic-audit-not-a-production-secret"
logging.disable(logging.CRITICAL)
records = []

with isolated_django_audit() as assert_local:
    import django
    django.setup()
    assert_local()
    from django.conf import settings
    from django.core.cache import cache
    from django.core.management import call_command
    from rest_framework.test import APIClient
    from apps.accounts.models import ClinicUser, User
    from apps.accounts.services.sms import MockSmsProvider
    from apps.analytics.models import AnalyticsDailyAggregate, AnalyticsEvent
    from apps.analytics.tasks import analytics_daily_rollup
    from apps.clinics.models import Clinic
    from apps.leads.models import Lead

    settings.DEBUG = False
    settings.ALLOWED_HOSTS = ["testserver"]
    call_command("migrate", verbosity=0, interactive=False)
    client = APIClient(raise_request_exception=False)
    admin = User.objects.create_user(phone="+971500000010", role="super_admin")
    patient = User.objects.create_user(phone="+971500000011", role="patient", is_verified=True)
    owner = User.objects.create_user(phone="+971500000012", role="clinic_admin")
    clinic = Clinic.objects.create(name_en="Synthetic source fixture", status="active", setup_status="approved")
    ClinicUser.objects.create(user=owner, clinic=clinic, role_in_clinic="admin")
    route = "/api/v1/admin/analytics/"

    # Reproduce only the observed shape, using explicit synthetic source records.
    for i in range(7):
        lead = Lead.objects.create(clinic=clinic, patient=patient, reference_code=f"AUDIT-{i}", consent_accepted=True)
        AnalyticsEvent.objects.create(event_type="lead_submitted", clinic=clinic, user=patient, object_type="lead", object_id=lead.pk)
    client.force_authenticate(user=admin)
    result = client.get(route)
    fields = ["total_events", "app_opens", "clinic_views", "whatsapp_taps", "call_taps", "maps_taps", "lead_submissions"]
    shape = {key: result.data[key] for key in fields}
    assert list(shape.values()) == [7, 0, 0, 0, 0, 0, 7]
    records.append({"case": "seven_lead_only_shape", "http": result.status_code, "metrics": shape, "scope": "synthetic records, not device or live database evidence"})

    # Check that a real persisted API lead emits its analytics record server-side.
    cache.clear()
    client.force_authenticate(user=patient)
    response = client.post("/api/v1/leads/", {"clinic": str(clinic.pk), "patient_name": "Synthetic source patient", "patient_phone": "+971500000011", "consent_accepted": True}, format="json")
    records.append({"case": "real_lead_create", "http": response.status_code, "saved_leads": Lead.objects.count(), "server_lead_events": AnalyticsEvent.objects.filter(event_type="lead_submitted").count()})
    assert response.status_code == 201
    assert Lead.objects.count() == 8
    assert AnalyticsEvent.objects.filter(event_type="lead_submitted").count() == 8

    # The public ingestion route currently trusts arbitrary attribution/metadata.
    hidden = Clinic.objects.create(name_en="Synthetic unpublished fixture", status="pending", setup_status="draft")
    client.force_authenticate(user=None)
    payload = {"event_type": "lead_submitted", "clinic": str(hidden.pk), "metadata": {"patient_note": "synthetic-only", "event_id": "same-synthetic-id"}}
    one = client.post("/api/v1/analytics/events/", payload, format="json")
    two = client.post("/api/v1/analytics/events/", payload, format="json")
    assert one.status_code == two.status_code == 201
    records.append({"case": "anonymous_duplicate_forged_lead_events", "http": [one.status_code, two.status_code], "duplicate_rows": AnalyticsEvent.objects.filter(clinic=hidden).count(), "has_event_id_ack": "id" in one.data, "sensitive_metadata_accepted": "patient_note" in one.data["metadata"]})
    client.force_authenticate(user=admin)
    summary = client.get(route).data
    assert summary["total_events"] == 10 and summary["lead_submissions"] == 8
    records.append({"case": "raw_events_diverge_from_saved_leads", "total_events": summary["total_events"], "saved_leads": summary["lead_submissions"]})

    for i in range(12):
        c = Clinic.objects.create(name_en=f"Synthetic directory {i:02d}", status="active", setup_status="approved")
        AnalyticsEvent.objects.create(event_type="clinic_view", clinic=c)
    all_clinics = client.get(route).data
    filtered = client.get(route, {"clinic_id": str(clinic.pk), "page": 2}).data
    assert all_clinics == filtered
    assert len(all_clinics["clinic_engagement"]) == 10
    records.append({"case": "analytics_clinic_and_page_filters_ignored", "same_response": True, "returned_clinics": 10, "row_fields": sorted(all_clinics["clinic_engagement"][0])})
    directory = client.get("/api/v1/admin/clinics/", {"page_size": 2, "page": 2})
    assert directory.status_code == 200 and directory.data["count"] == 14
    records.append({"case": "admin_directory_pagination", "http": 200, "count": directory.data["count"], "page2_rows": len(directory.data["results"])})

    # Every important admin read is role guarded; do not impersonate clinic staff.
    endpoints = ["dashboard/", "clinics/", "leads/", "offers/", "products/", "articles/", "analytics/", "analytics/referrals/", "settings/", "audit/", "treatment-categories/", "brand-product-categories/", "category-requests/"]
    for role, user, expected in [("anonymous", None, 401), ("patient", patient, 403), ("clinic_admin", owner, 403), ("super_admin", admin, 200)]:
        client.force_authenticate(user=user)
        statuses = {p: client.get("/api/v1/admin/" + p).status_code for p in endpoints}
        assert set(statuses.values()) == {expected}, (role, statuses)
        records.append({"case": "admin_read_role_matrix", "role": role, "statuses": statuses})

    client.force_authenticate(user=admin)
    assert client.get(route, {"from": "2026-10-31", "to": "2026-09-30"}).status_code == 400
    assert client.get(route, {"from": "invalid"}).status_code == 400
    bounds = [datetime(2026, 9, 29, 19, 59, 59, tzinfo=dt_timezone.utc), datetime(2026, 9, 29, 20, 0, tzinfo=dt_timezone.utc), datetime(2026, 10, 30, 19, 59, 59, tzinfo=dt_timezone.utc), datetime(2026, 10, 30, 20, 0, tzinfo=dt_timezone.utc)]
    for moment in bounds:
        event = AnalyticsEvent.objects.create(event_type="maps_tap")
        AnalyticsEvent.objects.filter(pk=event.pk).update(timestamp=moment)
    period = client.get(route, {"from": "2026-09-30", "to": "2026-10-30"}).data
    # Other fixtures are outside this fixed historical interval on the audit date.
    assert period["maps_taps"] == 2
    records.append({"case": "inclusive_dubai_date_bounds", "maps_inside": 2, "date_from": period["date_from"], "date_to": period["date_to"], "configured_timezone": settings.TIME_ZONE})

    # Nullable platform rollup keys are not protected from duplicate NULL rows.
    AnalyticsDailyAggregate.objects.create(date="2025-01-01", clinic=None)
    AnalyticsDailyAggregate.objects.create(date="2025-01-01", clinic=None)
    try:
        analytics_daily_rollup("2025-01-01")
    except AnalyticsDailyAggregate.MultipleObjectsReturned:
        records.append({"case": "nullable_platform_rollup_not_unique", "duplicate_rows": 2, "rerun_error": "MultipleObjectsReturned"})
    else:
        raise AssertionError("Expected source platform-rollup collision was not reproduced")

    # Full real request/confirm path, with only the local mock OTP provider.
    for index, user_id in enumerate(["abcdef00-0000-4000-8000-000000000001", "abcdef11-0000-4000-8000-000000000002"]):
        cache.clear()
        MockSmsProvider.reset()
        person = User.objects.create_user(id=UUID(user_id), phone=f"+97150000100{index}", role="patient", is_verified=True)
        client.force_authenticate(user=person)
        start = client.post("/api/v1/auth/me/deletion/request/", {}, format="json")
        assert start.status_code == 200
        code = MockSmsProvider.sent_messages[-1]["code"]
        finish = client.post("/api/v1/auth/me/deletion/confirm/", {"code": code}, format="json")
        person.refresh_from_db()
        records.append({"case": "deletion_same_six_hex_prefix", "fixture_index": index, "request_http": start.status_code, "confirm_http": finish.status_code, "inactive": not person.is_active, "stored_phone_length": len(person.phone), "schema_phone_max_length": User._meta.get_field("phone").max_length})
        assert finish.status_code == (200 if index == 0 else 500)

    assert inventory() == before, "Supplied backend source changed"

args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps({"backend_commit_stamp": "52666c1711469ec8a3689cf54f93c1c5fa963e6e", "source_tree_sha256": source_tree_sha256, "source_files_unchanged": len(before), "evidence_scope": "SQLite, temporary local media, network denied, synthetic fixtures; no production evidence", "records": records}, indent=2) + "\n", encoding="utf-8")
print(f"Offline source audit complete: {len(records)} observations; {len(before)} source files unchanged")
