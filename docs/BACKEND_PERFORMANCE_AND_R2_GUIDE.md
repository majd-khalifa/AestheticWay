# AESTHETIC WAY — Backend Performance, Cloudflare R2, & Scalability Guide
**Author:** Senior Architect, Mobile & Platform Engineering  
**Audience:** Ali (Lead Backend Engineer) & Backend Development Team  
**Status:** Canonical Reference & Implementation Blueprint  
**Target Market:** UAE (Dubai & Abu Dhabi)  
**Backend Framework:** Django 4.x / 5.x + Django REST Framework (DRF) + PostgreSQL + Redis  

---

## 🚨 URGENT SERIALIZER UPDATES FOR CLINIC & PROFILE SAVING (CRITICAL FIX)

> [!IMPORTANT]
> **Priority: Critical / Production Hotfix**  
> **Backend Repository:** `C:\Users\MVJD\Desktop\UAE_project\backend`  
> **Affected Endpoints:**  
> - `PATCH /api/v1/admin-portal/clinics/<id>/` (Super Admin Clinic Management)  
> - `PATCH /api/v1/clinic-portal/profile/` (Clinic Self-Management Profile)  

### 1. Overview & Rationale (Arabic & English)

#### **English**:
1. **Super Admin Clinic Management**:
   Previously, `AdminClinicUpdateSerializer` only included `subscription_tier`, `status`, `is_featured`, `display_order`, and moderation notes in its `Meta.fields`. When a Super Admin tried to update core clinic details (name, phone, whatsapp, email, website, addresses, city, emirate, logo, cover image) from the Admin Portal dialog/detail sheet, Django REST Framework silently dropped those fields, preventing edits from saving.
2. **Preventing 400 Bad Request on Existing Image URLs (`ImageField` Rejection)**:
   On the mobile application, when editing an existing clinic profile or super admin record, the form passes existing data back to the server. If the user does not change the logo or cover image, the existing remote image URL string (e.g. `https://media.aestheticway.ae/...`) is included. Because `logo` and `cover_image` are defined on the `Clinic` model as Django `ImageField` (not `URLField`), DRF rejects string inputs with a `400 Bad Request`:
   ```json
   {
     "logo": ["The submitted data was not a file. Check the encoding type on the form."]
   }
   ```
   **The Fix:** Overriding `to_internal_value(self, data)` in both serializers inspects the incoming payload for `logo` and `cover_image`. If either value is a `str` (an existing image URL), it is safely removed from the validation dictionary before hitting DRF's `ImageField`. This allows Django to keep the existing database image untouched while only processing binary file uploads (`UploadedFile`) when new media is selected.

#### **باللغة العربية (ملخص للمهندس علي)**:
1. **تحديث بيانات العيادة من لوحة الإدارة العليا (Super Admin)**:
   سابقاً، كان السريلايزر `AdminClinicUpdateSerializer` مقتصراً في قائمة `Meta.fields` على حقول الاشتراك والحالة والملاحظات فقط. عند قيام المشرف العام بتعديل بيانات العيادة الأساسية (الاسم، الهاتف، الواتساب، الإيميل، الموقع، العنوان، المدينة، الإمارة، الشعار، والغلاف)، كان دجانجو يتجاهل هذه الحقول تماماً ولا يتم حفظ أي تعديل في قاعدة البيانات.
2. **حل مشكلة خطأ 400 بسبب روابط الصور الحالية (The submitted data was not a file)**:
   عند قيام العيادة أو الأدمن بحفظ تعديلات على الملف التعريفي دون تغيير الشعار أو الغلاف، يقوم التطبيق بإرسال الرابط النصي الحالي للصورة (`https://...`). وبما أن حقلي `logo` و `cover_image` معرفان كـ `ImageField` في نموذج `Clinic`، فإن DRF يعتبر الرابط النصي غير صالح كملف ويرفض الطلب بخطأ 400: `"The submitted data was not a file"`.
   **الحل المنفذ:** تم تعريف دالة `to_internal_value(self, data)` في كلا السريلايزرين لفحص الحقلين؛ فإذا كانت القيمة نصية (`str`) يتم استبعادها من مصفوفة التحديث ليحتفظ دجانجو بالصورة المخزنة حالياً في قاعدة البيانات دون خطأ، وفي حال تم رفع ملف باينري جديد يتم تمريره وحفظه بصورة طبيعية.

### 2. File 1: `apps/admin_portal/serializers.py`

**Full File Path:** `apps/admin_portal/serializers.py`  
**Target Class:** `AdminClinicUpdateSerializer`

```python
class AdminClinicUpdateSerializer(serializers.ModelSerializer):
    name_en = serializers.CharField(required=False, max_length=200)
    name_ar = serializers.CharField(required=False, max_length=200, allow_blank=True)
    city = serializers.CharField(required=False, max_length=100)
    emirate = serializers.CharField(required=False, max_length=100)
    phone = serializers.CharField(required=False, max_length=20, allow_blank=True)
    whatsapp = serializers.CharField(required=False, max_length=20, allow_blank=True)
    email = serializers.EmailField(required=False, allow_blank=True)
    website = serializers.URLField(required=False, allow_blank=True)
    address_en = serializers.CharField(required=False, max_length=500, allow_blank=True)
    address_ar = serializers.CharField(required=False, max_length=500, allow_blank=True)
    subscription_tier = serializers.ChoiceField(
        choices=SubscriptionTier.choices, required=False
    )
    status = serializers.ChoiceField(choices=ClinicStatus.choices, required=False)
    is_featured = serializers.BooleanField(required=False)
    display_order = serializers.IntegerField(required=False)
    license_number = serializers.CharField(
        required=False, allow_blank=True, default=""
    )
    license_authority = serializers.CharField(
        required=False, allow_blank=True, default=""
    )
    moderation_notes = serializers.CharField(
        required=False, allow_blank=True, default=""
    )

    class Meta:
        model = Clinic
        fields = [
            "name_en", "name_ar", "city", "emirate", "phone", "whatsapp",
            "email", "website", "address_en", "address_ar",
            "subscription_tier", "status", "is_featured", "display_order",
            "license_number", "license_authority", "moderation_notes",
            "logo", "cover_image"
        ]

    def to_internal_value(self, data):
        # If logo or cover_image are passed as strings (e.g. existing remote URLs),
        # do not pass them to DRF's ImageField which expects an uploaded file.
        data_copy = data.copy() if hasattr(data, 'copy') else dict(data)
        for img_field in ['logo', 'cover_image']:
            val = data_copy.get(img_field)
            if isinstance(val, str):
                data_copy.pop(img_field, None)
        return super().to_internal_value(data_copy)
```

### 3. File 2: `apps/clinics/portal_serializers.py`

**Full File Path:** `apps/clinics/portal_serializers.py`  
**Target Class:** `ClinicProfilePortalSerializer`

```python
class ClinicProfilePortalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Clinic
        fields = [
            "id",
            "name_en",
            "name_ar",
            "city",
            "emirate",
            "address_en",
            "address_ar",
            "latitude",
            "longitude",
            "phone",
            "whatsapp",
            "email",
            "website",
            "description_en",
            "description_ar",
            "logo",
            "cover_image",
            "is_active",
            "created_at",
            "updated_at",
        ]

    def to_internal_value(self, data):
        # If logo or cover_image are passed as strings (e.g. existing remote URLs),
        # do not pass them to DRF's ImageField which expects an uploaded file.
        data_copy = data.copy() if hasattr(data, 'copy') else dict(data)
        for img_field in ['logo', 'cover_image']:
            val = data_copy.get(img_field)
            if isinstance(val, str):
                data_copy.pop(img_field, None)
        return super().to_internal_value(data_copy)
```

---

## 1. Executive Summary & Core Objectives

As AESTHETIC WAY scales across the UAE luxury medical aesthetic market, mobile responsiveness, instantaneous media rendering, and low cloud egress costs are paramount. This document defines the engineering standards and code recipes required to:

1. **Deploy Cloudflare R2 Object Storage** via S3-compatible APIs with **$0 egress fees**, replacing traditional costly object storage.
2. **Enforce the 15-Second Video Constraint** on the backend for VIP clinic hero banners.
3. **Standardize DRF Pagination** (`page` & `page_size=20`) across all resource discovery endpoints.
4. **Eliminate N+1 Database Queries** across Clinics, Practitioners, Offers, Products, Articles, and Treatments via strict `select_related` / `prefetch_related` queryset rules.
5. **Implement Cache Invalidation via Redis & Django Signals** for high-traffic read-heavy endpoints.
6. **Architect Referral Attribution & Deep Link Handshake** for the Unified Invite Link system.

---

## 2. Cloudflare R2 Object Storage Architecture (Zero-Egress)

### 2.1 Why Cloudflare R2 for Aesthetic Way
Medical aesthetic clinics upload high-resolution 4K clinic tour photos, treatment before/after galleries, product catalogs, and 15s showcase videos. AWS S3 charges ~$0.09/GB for data egress. Cloudflare R2 has **zero data egress fees**, resulting in up to 90% cloud cost savings while offering global edge delivery via Cloudflare CDN.

### 2.2 Dependencies & Installation
In `requirements.txt`:
```txt
django-storages>=1.14.2
boto3>=1.34.0
botocore>=1.34.0
pillow>=10.2.0
```

### 2.3 Django Settings Configuration (`settings.py`)
```python
import os

# ==============================================================================
# CLOUDFLARE R2 STORAGE CONFIGURATION
# ==============================================================================
USE_R2_STORAGE = os.getenv('USE_R2_STORAGE', 'False').lower() in ('true', '1', 'yes')

if USE_R2_STORAGE:
    CLOUDFLARE_ACCOUNT_ID = os.environ['CLOUDFLARE_R2_ACCOUNT_ID']
    AWS_ACCESS_KEY_ID = os.environ['CLOUDFLARE_R2_ACCESS_KEY_ID']
    AWS_SECRET_ACCESS_KEY = os.environ['CLOUDFLARE_R2_SECRET_ACCESS_KEY']
    AWS_STORAGE_BUCKET_NAME = os.environ['CLOUDFLARE_R2_BUCKET_NAME']

    # S3 Endpoint pointing to Cloudflare R2
    AWS_S3_ENDPOINT_URL = f"https://{CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com"
    AWS_S3_SIGNATURE_VERSION = 's3v4'
    AWS_S3_REGION_NAME = 'auto'
    AWS_S3_FILE_OVERWRITE = False
    AWS_DEFAULT_ACL = None  # R2 does not support S3 canned ACLs

    # Custom Domain / Cloudflare CDN Public URL (e.g., https://media.aestheticway.ae)
    CLOUDFLARE_R2_CUSTOM_DOMAIN = os.getenv('CLOUDFLARE_R2_CUSTOM_DOMAIN', '').rstrip('/')
    if CLOUDFLARE_R2_CUSTOM_DOMAIN:
        AWS_S3_CUSTOM_DOMAIN = CLOUDFLARE_R2_CUSTOM_DOMAIN.replace('https://', '').replace('http://', '')
    
    # Custom Storage Classes
    DEFAULT_FILE_STORAGE = 'config.storage_backends.MediaStorage'
    
    # Cache Control: 1 year for immutable media with aggressive CDN caching
    AWS_S3_OBJECT_PARAMETERS = {
        'CacheControl': 'public, max-age=31536000, immutable',
    }
else:
    # Local Development Fallback
    DEFAULT_FILE_STORAGE = 'django.core.files.storage.FileSystemStorage'
    MEDIA_URL = '/media/'
    MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
```

### 2.4 Custom Storage Class (`config/storage_backends.py`)
```python
from storages.backends.s3boto3 import S3Boto3Storage
from django.conf import settings

class MediaStorage(S3Boto3Storage):
    location = 'media'
    file_overwrite = False
    default_acl = None

    def url(self, name):
        """
        Ensures absolute URLs are formatted using HTTPS and the custom Cloudflare CDN domain.
        """
        url = super().url(name)
        if settings.CLOUDFLARE_R2_CUSTOM_DOMAIN and not url.startswith('http'):
            return f"{settings.CLOUDFLARE_R2_CUSTOM_DOMAIN}/{name.lstrip('/')}"
        return url
```

---

## 3. VIP Clinic 15-Second Video Constraint & Media Validation

### 3.1 Business Rule
- **VIP Platinum clinics only**: Video upload is an exclusive feature of the VIP tier.
- **Maximum Duration**: Exactly **15.0 seconds** (loops on mobile hero carousel).
- **Max File Size**: **25 MB** to prevent client bandwidth starvation.
- **Format**: `video/mp4`, `video/webm`, `video/quicktime`.

### 3.2 Backend Validation in Serializer (`apps/clinics/portal_serializers.py`)
```python
import tempfile
import os
from rest_framework import serializers
from apps.clinics.models import Clinic, SubscriptionTier

# Recommended lightweight video duration probe
# pip install pymediainfo OR use moviepy / ffprobe
from pymediainfo import MediaInfo

class ClinicProfileUpdateSerializer(serializers.ModelSerializer):
    video_ad_file = serializers.FileField(required=False, write_only=True)

    class Meta:
        model = Clinic
        fields = [
            'id', 'name_ar', 'name_en', 'description_ar', 'description_en',
            'phone', 'whatsapp', 'address_ar', 'address_en', 'city', 'area_ar',
            'logo', 'cover_image', 'video_url', 'video_ad_file',
        ]

    def validate_video_ad_file(self, file_obj):
        if not file_obj:
            return file_obj

        # 1. Check Subscription Tier
        clinic = self.instance
        if clinic and clinic.subscription_tier != SubscriptionTier.VIP_PLATINUM:
            raise serializers.ValidationError(
                "ميزة الإعلانات المرئية (فيديو 15 ثانية) مخصصة فقط لباقة VIP البلاتينية."
                if self.context.get('is_arabic') else
                "Video showcase feature is exclusively reserved for VIP Platinum subscription tier."
            )

        # 2. Check File Size (Max 25MB)
        max_bytes = 25 * 1024 * 1024
        if file_obj.size > max_bytes:
            raise serializers.ValidationError(
                "حجم ملف الفيديو يتجاوز الحد المسموح (25 ميغابايت)."
                if self.context.get('is_arabic') else
                "Video file size exceeds maximum allowed limit (25 MB)."
            )

        # 3. Check Duration (Max 15 seconds)
        # Write temporarily to probe metadata
        suffix = os.path.splitext(file_obj.name)[1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            for chunk in file_obj.chunks():
                temp_file.write(chunk)
            temp_path = temp_file.name

        try:
            media_info = MediaInfo.parse(temp_path)
            duration_sec = 0
            for track in media_info.tracks:
                if track.track_type == "Video" and track.duration:
                    duration_sec = float(track.duration) / 1000.0
                    break

            if duration_sec > 15.5:  # Allow 500ms safety buffer
                raise serializers.ValidationError(
                    f"مدة الفيديو ({duration_sec:.1f} ثانية) تتجاوز الحد الأقصى المسموح (15 ثانية)."
                    if self.context.get('is_arabic') else
                    f"Video duration ({duration_sec:.1f}s) exceeds the 15-second maximum constraint."
                )
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

        return file_obj
```

---

## 4. Standardized DRF Pagination (`page` & `page_size=20`)

The Flutter client has been updated with infinite scroll using standard pagination query parameters: `?page=1&page_size=20`.

### 4.1 Global Pagination Class (`apps/core/pagination.py`)
```python
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
    page_query_param = 'page'

    def get_paginated_response(self, data):
        return Response({
            'count': self.page.paginator.count,
            'total_pages': self.page.paginator.num_pages,
            'current_page': self.page.number,
            'page_size': self.get_page_size(self.request),
            'next': self.get_next_link(),
            'previous': self.get_previous_link(),
            'results': data
        })
```

### 4.2 Register in `settings.py`
```python
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'apps.core.pagination.StandardResultsSetPagination',
    'PAGE_SIZE': 20,
    # ... other DRF settings
}
```

### 4.3 Applying to ViewSets
Ensure all ViewSets inherit from or specify `pagination_class = StandardResultsSetPagination`:
- `ClinicViewSet` (`/api/v1/clinics/`)
- `OfferViewSet` (`/api/v1/offers/`)
- `ProductViewSet` (`/api/v1/products/`)
- `ArticleViewSet` (`/api/v1/articles/`)
- `TreatmentViewSet` (`/api/v1/treatments/`)
- `PractitionerViewSet` (`/api/v1/practitioners/`)

---

## 5. Database Query Optimization & N+1 Elimination

When fetching 20 clinics, DRF serializers often query doctors, treatments, and offers for each clinic, creating a 1 + 20*N query explosion.

### 5.1 Strict Rules for Querysets

| Model ViewSet | Required `select_related` (1-to-1 / ForeignKeys) | Required `prefetch_related` (Reverse FKs / Many-to-Many) |
| :--- | :--- | :--- |
| **`ClinicViewSet`** | `owner` | `gallery_images`, `treatments`, `practitioners`, `offers` |
| **`OfferViewSet`** | `clinic` | None |
| **`ProductViewSet`** | `clinic` | None |
| **`ArticleViewSet`** | `clinic`, `author_practitioner` | None |
| **`TreatmentViewSet`** | `clinic`, `category` | None |
| **`PractitionerViewSet`** | `clinic` | None |

### 5.2 Implementation Example (`apps/clinics/views.py`)
```python
from rest_framework import viewsets
from django.db.models import Prefetch
from apps.clinics.models import Clinic, ClinicGalleryImage
from apps.treatments.models import Treatment
from apps.offers.models import Offer
from .serializers import ClinicListSerializer, ClinicDetailSerializer

class ClinicViewSet(viewsets.ReadOnlyModelViewSet):
    lookup_field = 'id'

    def get_queryset(self):
        qs = Clinic.objects.filter(is_active=True).select_related('owner')

        # Optimize gallery images
        qs = qs.prefetch_related(
            Prefetch(
                'gallery_images',
                queryset=ClinicGalleryImage.objects.order_by('order', 'id')
            )
        )

        # Optimize active offers
        qs = qs.prefetch_related(
            Prefetch(
                'offers',
                queryset=Offer.objects.filter(is_active=True).order_by('-discount_percentage')
            )
        )

        # VIP Platinum clinics always appear first in discovery, followed by Featured, then Basic
        return qs.order_by(
            '-subscription_tier',  # VIP Platinum (3) > Featured (2) > Basic (1)
            '-rating',
            '-review_count',
            'id'
        )
```

### 5.3 Essential Database Indexes (`models.py`)
Add composite indexes in models to support mobile search and filtering without full table scans:

```python
class Clinic(models.Model):
    # ... fields
    class Meta:
        indexes = [
            models.Index(fields=['is_active', 'subscription_tier', '-rating'], name='clinic_tier_rating_idx'),
            models.Index(fields=['city', 'is_active'], name='clinic_city_active_idx'),
            models.Index(fields=['google_place_id'], name='clinic_place_id_idx'),
        ]

class Offer(models.Model):
    # ... fields
    class Meta:
        indexes = [
            models.Index(fields=['is_active', 'start_date', 'end_date'], name='offer_active_window_idx'),
            models.Index(fields=['clinic', 'is_active'], name='offer_clinic_idx'),
        ]

class Product(models.Model):
    # ... fields
    class Meta:
        indexes = [
            models.Index(fields=['clinic', 'is_active'], name='product_clinic_idx'),
            models.Index(fields=['category_en', 'is_active'], name='product_cat_idx'),
        ]
```

---

## 6. Redis Caching & Smart Invalidation Architecture

Read queries outnumber write queries 100:1 in the mobile discovery experience.

### 6.1 Caching High-Traffic Discovery Endpoints
Cache public listing endpoints for 10-15 minutes using Redis:

```python
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from django.views.decorators.vary import vary_on_headers

class ClinicViewSet(viewsets.ReadOnlyModelViewSet):
    # Cache list for 10 minutes, vary by Accept-Language (ar vs en) and query params
    @method_decorator(cache_page(60 * 10, key_prefix="clinics_list"))
    @method_decorator(vary_on_headers('Accept-Language'))
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)
```

### 6.2 Instant Cache Invalidation on Clinic Portal Updates
Clinics must see their updates immediately after editing their profile or adding treatments. Use Django signals to bust cache keys:

```python
# apps/clinics/signals.py
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.core.cache import cache
from apps.clinics.models import Clinic
from apps.treatments.models import Treatment
from apps.offers.models import Offer

def invalidate_discovery_caches(clinic_id=None):
    # Delete specific cache prefixes or pattern in Redis
    try:
        from django_redis import get_redis_connection
        con = get_redis_connection("default")
        # Invalidate all clinics_list and clinic_profile caches
        keys = con.keys(":1:clinics_list*") + con.keys(f":1:clinic_profile_{clinic_id}*")
        if keys:
            con.delete(*keys)
    except Exception:
        # Fallback to general cache clear if redis connection unavailable
        cache.clear()

@receiver([post_save, post_delete], sender=Clinic)
def on_clinic_changed(sender, instance, **kwargs):
    invalidate_discovery_caches(clinic_id=instance.id)

@receiver([post_save, post_delete], sender=Offer)
def on_offer_changed(sender, instance, **kwargs):
    invalidate_discovery_caches(clinic_id=instance.clinic_id)

@receiver([post_save, post_delete], sender=Treatment)
def on_treatment_changed(sender, instance, **kwargs):
    invalidate_discovery_caches(clinic_id=instance.clinic_id)
```

---

## 7. Unified Referral Link Attribution Architecture

### 7.1 Architecture & Flow
```
User A Shares: https://aestheticway.ae/invite/AW-98721
       │
       ▼
Universal Link opens Flutter App on Referee's phone
       │
       ▼
App stores referral_code in Secure Storage
       │
       ▼
Referee signs in via Phone OTP -> POST /api/v1/auth/verify-otp/ (passes referral_code)
       │
       ▼
Backend creates Referral record & grants Points to User A
```

### 7.2 Database Schema (`apps/referrals/models.py`)
```python
import uuid
from django.db import models
from django.conf import settings

class ReferralRecord(models.Model):
    STATUS_PENDING = 'pending'
    STATUS_VERIFIED = 'verified'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_VERIFIED, 'Verified Lead/User'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    referrer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_referrals'
    )
    referral_code = models.CharField(max_length=20, db_index=True)
    referee_phone = models.CharField(max_length=20, db_index=True)
    referee_user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='received_referral'
    )
    points_awarded = models.PositiveIntegerField(default=50)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('referrer', 'referee_phone')
        indexes = [
            models.Index(fields=['referral_code', 'status']),
        ]
```

### 7.3 Verification Hook in Auth View (`apps/auth/views.py`)
```python
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from apps.referrals.models import ReferralRecord
from apps.users.models import UserProfile

def handle_referral_on_verification(user, referral_code):
    if not referral_code or not user.phone:
        return

    # Check if referral code belongs to a valid user and not self
    try:
        referrer_profile = UserProfile.objects.select_related('user').get(referral_code=referral_code)
        if referrer_profile.user == user:
            return  # Prevent self-referrals

        # Create or update referral record
        record, created = ReferralRecord.objects.get_or_create(
            referrer=referrer_profile.user,
            referee_phone=user.phone,
            defaults={
                'referral_code': referral_code,
                'referee_user': user,
                'status': ReferralRecord.STATUS_VERIFIED,
                'points_awarded': 50,
                'verified_at': timezone.now()
            }
        )

        if created:
            # Credit points to referrer
            referrer_profile.points += 50
            referrer_profile.referral_count += 1
            referrer_profile.save(update_fields=['points', 'referral_count'])
    except UserProfile.DoesNotExist:
        pass
```

---

## 8. Summary Checklist for Ali

- [ ] **Cloudflare R2**: Install `django-storages` & `boto3`, set up `MediaStorage` in `config/storage_backends.py`.
- [ ] **15s Video Constraint**: Add video duration probe in `validate_video_ad_file` (VIP tier only, <= 15s).
- [ ] **Pagination**: Configure `StandardResultsSetPagination` (page & page_size=20) on all discovery endpoints.
- [ ] **N+1 Elimination**: Add `select_related` and `prefetch_related` across Clinics, Offers, Products, Treatments, and Articles.
- [ ] **Redis Caching**: Add `@cache_page` on discovery endpoints + signal-based invalidation on clinic portal edits.
- [ ] **Referrals**: Implement `ReferralRecord` model and award points upon referee phone OTP verification.
