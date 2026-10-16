# Backend Specification: Google Maps Ratings & Review Counts Caching

**Document Version:** 1.0.0  
**Target Project:** AESTHETIC WAY Backend (Django REST Framework)  
**Consumer:** AESTHETIC WAY Mobile App (Flutter iOS/Android)  
**Target Environment:** Production (`https://aestheticway.ae`)  
**Status:** Approved Engineering Specification  

---

## 1. Executive Summary & Cost Protection Architecture

### 1.1 Objective
The AESTHETIC WAY platform features premium medical aesthetic and dermatology clinics across Dubai and Abu Dhabi. Displaying real-time social proof—specifically authentic **Google Maps ratings** (e.g., `4.9 ★`) and **total review counts** (e.g., `385 reviews`)—is critical for patient trust and conversion.

However, calling Google Maps Platform APIs directly from mobile client apps or proxying live requests on every clinic view introduces extreme financial risk, latency penalties, and quota exhaustion.

### 1.2 Core Cost Protection Principles

```
+-----------------------------+
|   Patient Mobile Clients    |
|   (Thousands of Requests)   |
+--------------+--------------+
               |
               v   (Zero Google API cost)
+-----------------------------+
|    Aesthetic Way Backend    |
|    PostgreSQL Database      |
|  (Cached Ratings & Counts)  |
+--------------^--------------+
               |
               |   (Daily Batch at 03:00 GST / 1 Request per Clinic / 24h)
               |   (Strict Field Masking: rating,user_ratings_total)
+--------------+--------------+
|     Google Places API       |
|    (Places Details SKU)     |
+-----------------------------+
```

1. **Zero Client-Side Calls & Zero Live Proxying:**
   - The Flutter mobile application **never** queries Google Places API directly.
   - The backend API endpoints (`GET /api/v1/clinics/` and `GET /api/v1/clinics/{id}/`) serve ratings directly from indexed PostgreSQL fields (`google_rating`, `google_reviews_count`).
   - Serving 1,000,000 clinic impressions from PostgreSQL costs **$0.00** in Google Cloud Platform (GCP) fees.

2. **Strict Field Masking (SKU Containment):**
   - The Google Places Details API charges based on the data requested.
   - If fields are omitted or `*` is passed, Google charges for all categories (Basic, Contact, Atmosphere) at over **$25.00 per 1,000 requests**.
   - By specifying **strictly** `fields=rating,user_ratings_total` (Legacy Places API) or `X-Goog-FieldMask: rating,userRatingCount` (Places API New), requests are categorized under the minimum applicable SKU tier, protecting the monthly $200 recurring credit.

3. **Immutable `google_place_id` Resolution:**
   - Search/Find Place calls (`Find Place from Text` / `Text Search`) cost **$17.00 – $32.00 per 1,000 requests**.
   - The sync pipeline **never** uses text searching.
   - Each clinic's unique `google_place_id` is entered or validated **once** by administrators during clinic onboarding in Django Admin. Subsequent updates perform direct place lookup by ID only.

4. **Monthly Credit & Cost Budget Model:**
   - 500 active clinics synced once daily = `500 requests/day × 30 days = 15,000 requests/month`.
   - At ~$5.00 per 1,000 Atmosphere Place Details calls, 15,000 requests cost **~$75.00/month**.
   - This remains **well within Google Cloud's $200.00 free monthly credit**, resulting in a net cost of **$0.00/month**.

---

## 2. Google Cloud Platform (GCP) Setup Guide

### 2.1 API Enablement
1. Log in to the [Google Cloud Console](https://console.cloud.google.com/).
2. Select or create the production project: `aesthetic-way-production`.
3. Navigate to **APIs & Services > Library**.
4. Search for and enable **Places API** (or **Places API (New)**).
5. Ensure Geocoding API and Maps JavaScript API are **disabled** unless explicitly used elsewhere, avoiding accidental usage.

### 2.2 API Key Creation & Security Restrictions

> **CRITICAL SECURITY REQUIREMENT:** Never leave a Google Maps API key unrestricted. An unrestricted key can be scraped and exhausted within minutes.

1. Navigate to **APIs & Services > Credentials**.
2. Click **Create Credentials > API Key**. Name it: `aesthetic-way-backend-places-sync`.
3. Configure **Application Restrictions**:
   - Select **IP addresses (web servers, cron jobs, etc.)**.
   - Add the static outbound/egress public IPv4 addresses of the production Django server / Docker host:
     ```
     185.xxx.xxx.xxx/32
     ```
   - *Note:* Do not use HTTP Referrer restrictions; server-side Python requests have no browser referrer header.
4. Configure **API Restrictions**:
   - Select **Restrict key**.
   - Check **Places API** (and Places API New if using the v1 endpoint).
   - Uncheck all other APIs.
5. Save the key.

### 2.3 Budget Alerts & Hard Quotas
1. Navigate to **Billing > Budgets & Alerts**.
2. Create a monthly budget of **$200.00 USD**.
3. Configure alerts at:
   - **50% ($100.00)** — Standard informational notification.
   - **80% ($160.00)** — Warning notification to the engineering team.
   - **100% ($200.00)** — Urgent alarm before out-of-pocket costs begin.
4. In **APIs & Services > Places API > Quotas**:
   - Set **Requests per day** cap to **2,000 requests/day** (a hard ceiling preventing runaway loops).
   - Set **Requests per minute** to **120 requests/minute**.

### 2.4 Django Environment Variable Configuration
Store the key in the server's `.env` file (never commit to git repository):

```bash
# /path/to/aesthetic_way_backend/.env
GOOGLE_PLACES_API_KEY="AIzaSyA-ExampleKeyHere1234567890abcdef"
GOOGLE_PLACES_SYNC_ENABLED=True
GOOGLE_PLACES_REQUEST_TIMEOUT_SECONDS=5.0
```

In `backend/settings.py` (or `apps/clinics/conf.py`):
```python
import os

GOOGLE_PLACES_API_KEY = os.environ.get("GOOGLE_PLACES_API_KEY", "")
GOOGLE_PLACES_SYNC_ENABLED = os.environ.get("GOOGLE_PLACES_SYNC_ENABLED", "True").lower() == "true"
GOOGLE_PLACES_REQUEST_TIMEOUT_SECONDS = float(os.environ.get("GOOGLE_PLACES_REQUEST_TIMEOUT_SECONDS", "5.0"))
```

---

## 3. Django Database Models Schema

Update `apps/clinics/models.py` on the `Clinic` model:

### 3.1 Model Fields Specification

| Field Name | Type | Options | Purpose |
| :--- | :--- | :--- | :--- |
| `google_place_id` | `CharField` | `max_length=255, blank=True, default="", db_index=True` | Unique Google Place ID (e.g., `ChIJ...`) |
| `google_maps_url` | `URLField` | `max_length=500, blank=True, default=""` | Verified Google Maps link for patient navigation |
| `google_rating` | `DecimalField` | `max_digits=3, decimal_places=2, null=True, blank=True, db_index=True` | Synced rating (e.g. `4.85`) |
| `google_reviews_count` | `PositiveIntegerField` | `null=True, blank=True, default=0, db_index=True` | Synced total user review count |
| `google_last_synced_at` | `DateTimeField` | `null=True, blank=True, db_index=True` | Timestamp of last successful sync |
| `google_sync_status` | `CharField` | `max_length=20, choices=GoogleSyncStatus.choices, default='not_configured'` | Status indicator for admin dashboard |
| `google_sync_error` | `TextField` | `blank=True, default=""` | Debug error trace on failure |

### 3.2 Python Model Implementation

```python
# apps/clinics/models.py
import uuid
from django.db import models


class GoogleSyncStatus(models.TextChoices):
    NOT_CONFIGURED = "not_configured", "Not Configured (No Place ID)"
    PENDING = "pending", "Pending First Sync"
    SYNCED = "synced", "Successfully Synced"
    FAILED = "failed", "Sync Failed"


class Clinic(models.Model):
    # ... existing fields (id, name_en, name_ar, slug, etc.) ...

    # Google Maps Integration Fields
    google_place_id = models.CharField(
        max_length=255,
        blank=True,
        default="",
        db_index=True,
        help_text="Google Maps Place ID (e.g., ChIJN1t_tDeuEmsRUsoyG83frY4). Used for automated rating sync."
    )
    google_maps_url = models.URLField(
        max_length=500,
        blank=True,
        default="",
        help_text="Direct URL to clinic Google Maps listing."
    )
    google_rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        null=True,
        blank=True,
        db_index=True,
        help_text="Cached Google Maps rating (1.00 - 5.00)."
    )
    google_reviews_count = models.PositiveIntegerField(
        null=True,
        blank=True,
        default=0,
        db_index=True,
        help_text="Cached total number of Google user reviews."
    )
    google_last_synced_at = models.DateTimeField(
        null=True,
        blank=True,
        db_index=True,
        help_text="Timestamp of the most recent successful Google Places sync."
    )
    google_sync_status = models.CharField(
        max_length=20,
        choices=GoogleSyncStatus.choices,
        default=GoogleSyncStatus.NOT_CONFIGURED,
        db_index=True,
        help_text="Current Google Places synchronization health status."
    )
    google_sync_error = models.TextField(
        blank=True,
        default="",
        help_text="Error message if the last sync attempt failed."
    )

    class Meta:
        ordering = ["display_order", "-is_featured", "name_en"]
        indexes = [
            models.Index(fields=["status", "google_rating"]),
            models.Index(fields=["google_sync_status", "google_last_synced_at"]),
        ]

    def save(self, *args, **kwargs):
        # Auto-update status when place_id is added or removed
        if not self.google_place_id:
            self.google_sync_status = GoogleSyncStatus.NOT_CONFIGURED
        elif self.google_sync_status == GoogleSyncStatus.NOT_CONFIGURED:
            self.google_sync_status = GoogleSyncStatus.PENDING
        super().save(*args, **kwargs)
```

### 3.3 Django Database Migration File
Create migration file `apps/clinics/migrations/000X_add_google_places_caching_fields.py`:

```python
# Generated by Django
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('clinics', '0001_initial'),  # Adjust to latest migration
    ]

    operations = [
        migrations.AddField(
            model_name='clinic',
            name='google_reviews_count',
            field=models.PositiveIntegerField(
                blank=True,
                db_index=True,
                default=0,
                help_text='Cached total number of Google user reviews.',
                null=True,
            ),
        ),
        migrations.AddField(
            model_name='clinic',
            name='google_last_synced_at',
            field=models.DateTimeField(
                blank=True,
                db_index=True,
                help_text='Timestamp of the most recent successful Google Places sync.',
                null=True,
            ),
        ),
        migrations.AddField(
            model_name='clinic',
            name='google_sync_status',
            field=models.CharField(
                choices=[
                    ('not_configured', 'Not Configured (No Place ID)'),
                    ('pending', 'Pending First Sync'),
                    ('synced', 'Successfully Synced'),
                    ('failed', 'Sync Failed'),
                ],
                db_index=True,
                default='not_configured',
                help_text='Current Google Places synchronization health status.',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='clinic',
            name='google_sync_error',
            field=models.TextField(
                blank=True,
                default='',
                help_text='Error message if the last sync attempt failed.',
            ),
        ),
        migrations.AlterField(
            model_name='clinic',
            name='google_place_id',
            field=models.CharField(
                blank=True,
                db_index=True,
                default='',
                help_text='Google Maps Place ID (e.g., ChIJN1t_tDeuEmsRUsoyG83frY4). Used for automated rating sync.',
                max_length=255,
            ),
        ),
        migrations.AlterField(
            model_name='clinic',
            name='google_rating',
            field=models.DecimalField(
                blank=True,
                db_index=True,
                decimal_places=2,
                help_text='Cached Google Maps rating (1.00 - 5.00).',
                max_digits=3,
                null=True,
            ),
        ),
        migrations.AddIndex(
            model_name='clinic',
            index=models.Index(fields=['status', 'google_rating'], name='clinic_status_rating_idx'),
        ),
        migrations.AddIndex(
            model_name='clinic',
            index=models.Index(fields=['google_sync_status', 'google_last_synced_at'], name='clinic_sync_health_idx'),
        ),
    ]
```

---

## 4. Service Layer Implementation

Create `apps/clinics/services/google_places.py`:

```python
"""
Service layer for syncing Google Maps ratings and review counts.
Strict cost-control field masking: rating, user_ratings_total only.
"""
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
import logging
import time
from typing import Optional, Tuple

from django.conf import settings
from django.utils import timezone
import requests

from apps.clinics.models import Clinic, GoogleSyncStatus

logger = logging.getLogger("apps.clinics.google_places")


@dataclass
class GooglePlaceRatingResult:
    place_id: str
    rating: Optional[Decimal]
    reviews_count: int
    raw_status: str


class GooglePlacesAPIException(Exception):
    """Base exception for Google Places API failures."""
    pass


class GooglePlacesRateLimitException(GooglePlacesAPIException):
    """Raised when Google responds with OVER_QUERY_LIMIT or 429."""
    pass


class GooglePlacesSyncService:
    """
    Manages server-side querying and caching of Google Places details.
    Enforces timeout, retry, field masking, and rate limiting.
    """

    DETAILS_URL = "https://maps.googleapis.com/maps/api/place/details/json"

    def __init__(self, api_key: Optional[str] = None, timeout: float = 5.0):
        self.api_key = api_key or getattr(settings, "GOOGLE_PLACES_API_KEY", "")
        self.timeout = timeout or getattr(settings, "GOOGLE_PLACES_REQUEST_TIMEOUT_SECONDS", 5.0)
        self.session = requests.Session()

    def fetch_place_rating(self, place_id: str) -> GooglePlaceRatingResult:
        """
        Calls Google Places Details API with strict field masking.
        Fields requested: ONLY 'rating,user_ratings_total'.
        """
        clean_place_id = (place_id or "").strip()
        if not clean_place_id:
            raise ValueError("place_id cannot be empty")

        if not self.api_key:
            raise GooglePlacesAPIException("GOOGLE_PLACES_API_KEY is not configured in Django settings.")

        params = {
            "place_id": clean_place_id,
            "fields": "rating,user_ratings_total",
            "key": self.api_key,
        }

        try:
            response = self.session.get(
                self.DETAILS_URL,
                params=params,
                timeout=self.timeout,
            )
            response.raise_for_status()
            data = response.json()
        except requests.exceptions.Timeout as exc:
            logger.error("Google Places API timed out for place_id=%s", clean_place_id)
            raise GooglePlacesAPIException(f"Network timeout after {self.timeout}s") from exc
        except requests.exceptions.RequestException as exc:
            logger.error("Google Places API network error for place_id=%s: %s", clean_place_id, str(exc))
            raise GooglePlacesAPIException(f"Network error: {str(exc)}") from exc
        except ValueError as exc:
            logger.error("Invalid JSON response from Google Places API for place_id=%s", clean_place_id)
            raise GooglePlacesAPIException("Invalid JSON received from Google") from exc

        api_status = data.get("status", "UNKNOWN")

        if api_status == "OK":
            result = data.get("result", {})
            raw_rating = result.get("rating")
            raw_count = result.get("user_ratings_total", 0)

            decimal_rating: Optional[Decimal] = None
            if raw_rating is not None:
                try:
                    decimal_rating = Decimal(str(raw_rating)).quantize(Decimal("0.01"))
                except (InvalidOperation, TypeError, ValueError):
                    decimal_rating = None

            reviews_count = int(raw_count) if isinstance(raw_count, (int, float)) else 0

            return GooglePlaceRatingResult(
                place_id=clean_place_id,
                rating=decimal_rating,
                reviews_count=reviews_count,
                raw_status=api_status,
            )

        if api_status in ("OVER_QUERY_LIMIT", "RESOURCE_EXHAUSTED"):
            logger.critical("Google Places API quota exceeded or rate limit hit: status=%s", api_status)
            raise GooglePlacesRateLimitException(f"Quota exceeded: {api_status}")

        if api_status in ("NOT_FOUND", "ZERO_RESULTS", "INVALID_REQUEST"):
            error_message = data.get("error_message", f"Google API returned status: {api_status}")
            logger.warning("Google Place ID invalid or not found (place_id=%s, status=%s): %s",
                           clean_place_id, api_status, error_message)
            raise GooglePlacesAPIException(f"{api_status}: {error_message}")

        if api_status == "REQUEST_DENIED":
            error_message = data.get("error_message", "Request denied by Google API.")
            logger.critical("Google Places API key rejected (REQUEST_DENIED): %s", error_message)
            raise GooglePlacesAPIException(f"REQUEST_DENIED: {error_message}")

        raise GooglePlacesAPIException(f"Unhandled Google Places status: {api_status}")

    def sync_clinic(self, clinic: Clinic) -> Tuple[bool, str]:
        """
        Synchronizes a single clinic instance.
        Preserves existing cached values on failure.
        """
        if not clinic.google_place_id:
            clinic.google_sync_status = GoogleSyncStatus.NOT_CONFIGURED
            clinic.google_sync_error = "No google_place_id configured for clinic."
            clinic.save(update_fields=["google_sync_status", "google_sync_error"])
            return False, "No place_id configured"

        try:
            res = self.fetch_place_rating(clinic.google_place_id)
            clinic.google_rating = res.rating
            clinic.google_reviews_count = res.reviews_count
            clinic.google_last_synced_at = timezone.now()
            clinic.google_sync_status = GoogleSyncStatus.SYNCED
            clinic.google_sync_error = ""
            clinic.save(update_fields=[
                "google_rating",
                "google_reviews_count",
                "google_last_synced_at",
                "google_sync_status",
                "google_sync_error",
            ])
            logger.info("Synced clinic '%s' (ID: %s): rating=%s, reviews=%s",
                        clinic.name_en, clinic.id, res.rating, res.reviews_count)
            return True, f"Success: {res.rating}★ ({res.reviews_count} reviews)"

        except GooglePlacesRateLimitException as exc:
            # Do NOT wipe existing rating! Preserve cached data.
            clinic.google_sync_status = GoogleSyncStatus.FAILED
            clinic.google_sync_error = f"Rate limit: {str(exc)}"
            clinic.save(update_fields=["google_sync_status", "google_sync_error"])
            raise

        except Exception as exc:
            # Preserve existing rating, record error trace
            clinic.google_sync_status = GoogleSyncStatus.FAILED
            clinic.google_sync_error = str(exc)
            clinic.save(update_fields=["google_sync_status", "google_sync_error"])
            logger.warning("Failed to sync clinic '%s' (ID: %s): %s", clinic.name_en, clinic.id, str(exc))
            return False, str(exc)

    def sync_all_active_clinics(self, throttle_delay_seconds: float = 0.1) -> dict:
        """
        Iterates over all active clinics with a configured place_id and syncs ratings.
        Includes polite inter-request delay to prevent quota bursts.
        """
        active_clinics = Clinic.objects.filter(
            status="active",
            deleted_at__isnull=True,
        ).exclude(google_place_id="")

        total_count = active_clinics.count()
        success_count = 0
        failure_count = 0
        logger.info("Starting Google Places sync for %d active clinics.", total_count)

        for clinic in active_clinics.iterator(chunk_size=100):
            try:
                success, _ = self.sync_clinic(clinic)
                if success:
                    success_count += 1
                else:
                    failure_count += 1
            except GooglePlacesRateLimitException:
                logger.critical("Aborting batch sync early due to Google rate limit / quota exhaustion.")
                break
            except Exception as exc:
                failure_count += 1
                logger.error("Unexpected error syncing clinic %s: %s", clinic.id, str(exc))

            if throttle_delay_seconds > 0:
                time.sleep(throttle_delay_seconds)

        logger.info("Finished Google Places sync. Success: %d, Failed: %d, Total: %d",
                    success_count, failure_count, total_count)
        return {
            "total": total_count,
            "success": success_count,
            "failed": failure_count,
        }
```

---

## 5. Management Command & Cron Automation

### 5.1 Django Management Command
Create `apps/clinics/management/commands/sync_google_ratings.py`:

```python
"""
Django management command to synchronize Google Maps ratings.
Usage:
    python manage.py sync_google_ratings
    python manage.py sync_google_ratings --clinic-id=<UUID>
    python manage.py sync_google_ratings --dry-run
"""
import uuid
from django.core.management.base import BaseCommand, CommandError
from apps.clinics.models import Clinic
from apps.clinics.services.google_places import (
    GooglePlacesSyncService,
    GooglePlacesAPIException,
)


class Command(BaseCommand):
    help = "Synchronizes Google Maps ratings and review counts for active clinics."

    def add_arguments(self, parser):
        parser.add_argument(
            "--clinic-id",
            type=str,
            help="Specific Clinic UUID to sync instead of all clinics.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Simulate the sync without committing updates to the database.",
        )
        parser.add_argument(
            "--delay",
            type=float,
            default=0.1,
            help="Delay in seconds between API requests (default: 0.1s).",
        )

    def handle(self, *args, **options):
        clinic_id_raw = options.get("clinic_id")
        dry_run = options.get("dry_run", False)
        delay = options.get("delay", 0.1)

        service = GooglePlacesSyncService()

        if clinic_id_raw:
            try:
                clinic_uuid = uuid.UUID(clinic_id_raw)
                clinic = Clinic.objects.get(id=clinic_uuid)
            except (ValueError, Clinic.DoesNotExist) as exc:
                raise CommandError(f"Clinic with ID '{clinic_id_raw}' does not exist.") from exc

            self.stdout.write(f"Syncing Google ratings for clinic: {clinic.name_en} ({clinic.id})...")
            if dry_run:
                self.stdout.write(self.style.WARNING("DRY RUN: Fetching rating without saving..."))
                try:
                    result = service.fetch_place_rating(clinic.google_place_id)
                    self.stdout.write(
                        self.style.SUCCESS(
                            f"[DRY RUN OK] Place ID: {result.place_id} | "
                            f"Rating: {result.rating} | Reviews: {result.reviews_count}"
                        )
                    )
                except GooglePlacesAPIException as exc:
                    self.stdout.write(self.style.ERROR(f"[DRY RUN ERROR] {str(exc)}"))
                return

            success, msg = service.sync_clinic(clinic)
            if success:
                self.stdout.write(self.style.SUCCESS(f"Successfully synced {clinic.name_en}: {msg}"))
            else:
                self.stdout.write(self.style.ERROR(f"Failed to sync {clinic.name_en}: {msg}"))
            return

        self.stdout.write("Starting batch sync for all active clinics...")
        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN: Batch dry run is not allowed without --clinic-id."))
            return

        summary = service.sync_all_active_clinics(throttle_delay_seconds=delay)
        self.stdout.write(
            self.style.SUCCESS(
                f"Sync Completed!\n"
                f"Total Processed: {summary['total']}\n"
                f"Successful:      {summary['success']}\n"
                f"Failed:          {summary['failed']}"
            )
        )
```

### 5.2 Linux Crontab Automation
Schedule the job to run daily during off-peak hours (03:00 GST / 23:00 UTC):

```cron
# /etc/cron.d/aesthetic_way_sync
# Run daily at 03:00 Dubai Time (GST is UTC+4 -> 23:00 UTC)
0 23 * * * www-data cd /var/www/aesthetic_way_backend && /var/www/aesthetic_way_backend/venv/bin/python manage.py sync_google_ratings --delay=0.1 >> /var/log/aesthetic_way/google_ratings_sync.log 2>&1
```

### 5.3 Alternative: Celery Beat Periodic Task
If Celery and Celery-Beat are utilized in production:

```python
# apps/clinics/tasks.py
from celery import shared_task
from apps.clinics.services.google_places import GooglePlacesSyncService


@shared_task(name="apps.clinics.tasks.sync_all_google_ratings", bind=True, max_retries=1)
def task_sync_all_google_ratings(self):
    service = GooglePlacesSyncService()
    return service.sync_all_active_clinics(throttle_delay_seconds=0.1)
```

```python
# In settings.py / celery.py
CELERY_BEAT_SCHEDULE = {
    "sync-google-ratings-daily": {
        "task": "apps.clinics.tasks.sync_all_google_ratings",
        "schedule": crontab(hour=23, minute=0),  # 23:00 UTC = 03:00 GST
    },
}
```

---

## 6. Django Admin Action & UI Integration

In `apps/clinics/admin.py`, integrate an admin action for manual batch syncing and provide clear visual feedback in the clinic list and detail views:

```python
# apps/clinics/admin.py
from django.contrib import admin
from django.utils.html import format_html
from django.contrib import messages
from apps.clinics.models import Clinic, GoogleSyncStatus
from apps.clinics.services.google_places import GooglePlacesSyncService


@admin.register(Clinic)
class ClinicAdmin(admin.ModelAdmin):
    list_display = [
        "name_en",
        "city",
        "google_rating_badge",
        "google_reviews_count_display",
        "google_sync_status_badge",
        "google_last_synced_at",
        "status",
        "subscription_tier",
    ]
    list_filter = [
        "google_sync_status",
        "status",
        "subscription_tier",
        "emirate",
    ]
    search_fields = ["name_en", "name_ar", "google_place_id", "email", "phone"]
    actions = ["action_sync_google_ratings"]

    readonly_fields = [
        "id",
        "google_rating",
        "google_reviews_count",
        "google_last_synced_at",
        "google_sync_status",
        "google_sync_error",
        "created_at",
        "updated_at",
    ]

    fieldsets = (
        ("Basic Information", {
            "fields": ("id", "name_en", "name_ar", "slug", "description_en", "description_ar"),
        }),
        ("Contact & Location", {
            "fields": (
                "phone", "whatsapp", "email", "website",
                "address_en", "address_ar", "city", "emirate",
                "latitude", "longitude",
            ),
        }),
        ("Google Maps & Ratings (Synced Server-Side)", {
            "description": "Enter the Google Place ID once. The rating and review count are cached automatically.",
            "fields": (
                "google_place_id",
                "google_maps_url",
                "google_rating",
                "google_reviews_count",
                "google_sync_status",
                "google_last_synced_at",
                "google_sync_error",
            ),
        }),
        ("Media & Branding", {
            "fields": ("logo", "cover_image"),
        }),
        ("Moderation & Subscription (Internal)", {
            "fields": ("status", "subscription_tier", "license_number", "license_authority"),
        }),
    )

    @admin.display(description="Google Rating", ordering="google_rating")
    def google_rating_badge(self, obj):
        if obj.google_rating is None:
            return format_html('<span style="color: #9CA3AF;">--</span>')
        return format_html(
            '<strong style="color: #D97706;">★ {:.2f}</strong>',
            obj.google_rating
        )

    @admin.display(description="Reviews", ordering="google_reviews_count")
    def google_reviews_count_display(self, obj):
        if not obj.google_reviews_count:
            return "0"
        return f"{obj.google_reviews_count:,}"

    @admin.display(description="Sync Status", ordering="google_sync_status")
    def google_sync_status_badge(self, obj):
        colors = {
            GoogleSyncStatus.SYNCED: ("#10B981", "#ECFDF5", "Synced"),
            GoogleSyncStatus.PENDING: ("#F59E0B", "#FFFBEB", "Pending"),
            GoogleSyncStatus.FAILED: ("#EF4444", "#FEF2F2", "Failed"),
            GoogleSyncStatus.NOT_CONFIGURED: ("#6B7280", "#F3F4F6", "No Place ID"),
        }
        color, bg, label = colors.get(obj.google_sync_status, ("#6B7280", "#F3F4F6", obj.google_sync_status))
        return format_html(
            '<span style="background-color: {}; color: {}; padding: 3px 8px; '
            'border-radius: 6px; font-weight: 600; font-size: 11px;">{}</span>',
            bg, color, label
        )

    @admin.action(description="🔄 Sync Google Ratings from Places API")
    def action_sync_google_ratings(self, request, queryset):
        service = GooglePlacesSyncService()
        success_count = 0
        fail_count = 0

        for clinic in queryset:
            success, msg = service.sync_clinic(clinic)
            if success:
                success_count += 1
            else:
                fail_count += 1

        if fail_count == 0:
            self.message_user(
                request,
                f"Successfully synced {success_count} clinic(s) from Google Places API.",
                level=messages.SUCCESS
            )
        else:
            self.message_user(
                request,
                f"Synced {success_count} clinic(s). {fail_count} clinic(s) failed or lack place_id.",
                level=messages.WARNING
            )
```

---

## 7. DRF Serializer & API Contract Updates

### 7.1 Serializer Implementation
Update `apps/clinics/serializers.py` to expose both `google_rating` and `google_reviews_count`, along with backward-compatible aliases:

```python
# apps/clinics/serializers.py
from rest_framework import serializers
from apps.clinics.models import Clinic


class PublicClinicListSerializer(serializers.ModelSerializer):
    """
    Public listing serializer for discovery feed.
    """
    distance = serializers.FloatField(read_only=True, required=False)
    # Backward compatibility with Flutter model:
    review_count = serializers.IntegerField(source="google_reviews_count", read_only=True)

    class Meta:
        model = Clinic
        fields = [
            "id",
            "name_en",
            "name_ar",
            "slug",
            "description_en",
            "description_ar",
            "phone",
            "whatsapp",
            "email",
            "website",
            "address_en",
            "address_ar",
            "city",
            "emirate",
            "latitude",
            "longitude",
            "logo",
            "cover_image",
            "is_featured",
            "google_rating",
            "google_reviews_count",
            "review_count",
            "google_maps_url",
            "distance",
        ]
        read_only_fields = fields


class PublicClinicDetailSerializer(serializers.ModelSerializer):
    """
    Full public clinic profile serializer.
    """
    branches = serializers.SerializerMethodField()
    practitioners = serializers.SerializerMethodField()
    treatments = serializers.SerializerMethodField()
    review_count = serializers.IntegerField(source="google_reviews_count", read_only=True)

    class Meta:
        model = Clinic
        fields = [
            "id",
            "name_en",
            "name_ar",
            "slug",
            "description_en",
            "description_ar",
            "phone",
            "whatsapp",
            "email",
            "website",
            "address_en",
            "address_ar",
            "city",
            "emirate",
            "latitude",
            "longitude",
            "google_place_id",
            "google_maps_url",
            "logo",
            "cover_image",
            "is_featured",
            "google_rating",
            "google_reviews_count",
            "review_count",
            "google_last_synced_at",
            "branches",
            "practitioners",
            "treatments",
        ]
        read_only_fields = fields
```

### 7.2 API JSON Payload Contract

#### `GET /api/v1/clinics/` (Snippet)
```json
{
  "count": 45,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "c1f7b8e2-9d3a-4f5b-8c2d-1e4a5b6c7d8e",
      "name_en": "Beverly Hills Aesthetic Clinic",
      "name_ar": "عيادة بيفرلي هيلز للتجميل",
      "slug": "beverly-hills-aesthetic-clinic",
      "city": "Dubai",
      "emirate": "Dubai",
      "google_rating": 4.90,
      "google_reviews_count": 342,
      "review_count": 342,
      "google_maps_url": "https://maps.google.com/?cid=10293847561029384",
      "is_featured": true
    }
  ]
}
```

### 7.3 Flutter Consumption Mapping (`ClinicModel`)
In the Flutter codebase (`lib/features/clinics/models/clinic_model.dart`), the model deserialization automatically binds these cached fields:

```dart
// lib/features/clinics/models/clinic_model.dart
factory ClinicModel.fromJson(Map<String, dynamic> json) {
  return ClinicModel(
    // ...
    rating: double.tryParse(json['google_rating']?.toString() ?? '') ?? 0.0,
    reviewCount: (json['review_count'] is int)
        ? json['review_count'] as int
        : (int.tryParse(json['google_reviews_count']?.toString() ?? '') ?? 0),
    googlePlaceId: json['google_place_id']?.toString(),
    googleMapsUrl: json['google_maps_url']?.toString(),
    // ...
  );
}
```

---

## 8. Edge Case Handling & Resilience Matrix

| Scenario | System Behavior | Data Preservation Rule |
| :--- | :--- | :--- |
| **Missing `google_place_id`** | Clinic skipped during batch; status set to `not_configured`. No API call made. | `google_rating` stays `null` or untouched. |
| **Newly Opened Clinic (0 reviews)** | Google returns `OK` with no `rating` and `user_ratings_total: 0`. | `google_rating=null`, `google_reviews_count=0`, status set to `synced`. UI shows new clinic badge without broken stars. |
| **Invalid/Deleted `google_place_id`** | Google returns `NOT_FOUND` or `INVALID_REQUEST`. Logged as warning; status set to `failed`. | **DO NOT wipe previous values.** Existing cached rating and review count remain intact to prevent broken UI. |
| **Network Timeout / Connection Drop** | Request times out after 5.0 seconds. Recorded in `google_sync_error`; status set to `failed`. | Existing cached rating preserved. |
| **Google Quota Exceeded (`OVER_QUERY_LIMIT`)** | Immediate critical log; batch loop terminates immediately to avoid spamming the blocked endpoint. Alert dispatched to DevOps. | Database state unchanged; all existing cached ratings preserved. |
| **GCP API Key IP Mismatch** | Google returns `REQUEST_DENIED` with "IP address not allowed". Logged as critical error. | Database state unchanged. Alert triggers investigation of server egress IP. |

---

## 9. Verification & Acceptance Checklist

To verify this implementation during testing and staging:

- [ ] **GCP IP Restriction:** Verify that making a request with the production API key from a local developer machine returns `403 Forbidden` (`REQUEST_DENIED`), confirming IP whitelist enforcement.
- [ ] **Field Masking Audit:** Inspect outgoing HTTP requests in `google_places.py` to confirm the query string strictly includes `fields=rating,user_ratings_total`.
- [ ] **Management Command Dry Run:** Execute `python manage.py sync_google_ratings --dry-run --clinic-id=<UUID>` and verify stdout displays fetched data without altering the database.
- [ ] **Data Preservation on Error:** Artificially disconnect network or pass an invalid place ID; verify that existing `google_rating` and `google_reviews_count` are **not** wiped to `null` or `0`.
- [ ] **Admin Action:** Select 3 clinics in Django Admin, choose "Sync Google Ratings", and verify success toast notification and updated badges.
- [ ] **Flutter Parity:** Launch the Flutter app and verify that clinic cards display the star icon with the exact synced rating and review count formatted (e.g. `★ 4.9 (342)`).
- [ ] **Billing Monitoring:** After 24 hours of cron execution, inspect Google Cloud Billing Console to confirm daily costs remain under $0.50 (well inside the $200 free tier).
