# AESTHETIC WAY — Backend Modifications & Technical Requirements for Ali

**Document Version:** 2.0.0  
**Author:** Senior Architecture Team  
**Addressed To:** Ali Mohamed (Backend Lead)  
**Target Environment:** Django 5 / Django REST Framework (DRF) — `backend/`  
**Date:** October 2026  

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

## 1. Executive Summary & Purpose

Following the client's hands-on review of the initial APK and updated commercial strategy in the UAE, the product team has enacted several critical UX and architectural adjustments on the mobile frontend (`AestheticWay`).

To ensure full end-to-end synchronization between the Flutter mobile application and the DRF backend, this document outlines the exact modifications required in the Django backend (`C:\Users\MVJD\Desktop\UAE_project\backend`).

### Key Summary of Changes:
1. **Regulatory License Deprecation**: Remove mandatory validation on `license_number` and `license_authority` across Clinic, Practitioner, and Admin serializers.
2. **Products Architectural Pivot**: Transition products from "clinic inventory" to a "cosmetic brand showcase" — remove price requirement, support brand metadata, ensure zero cart/checkout logic.
3. **Treatment Category Binding (Fix 400 Bad Request)**: Ensure `ClinicTreatmentPortalSerializer` handles category UUID binding and empty practitioner lists gracefully.
4. **Offer Creation Contact Autowiring**: Ensure `ClinicOfferPortalSerializer` automatically inherits clinic identity and contact info without expecting manual phone/email in the payload.
5. **Lead Creation Purity**: Confirm lead endpoints strictly receive contact info, notes, and optional service/doctor, with zero dependency on appointment date/calendar slots.
6. **Native Multipart Form-Data Media Uploads**: Ensure `MultiPartParser` and `FormParser` are active on all portal viewsets to receive mobile camera/gallery uploads.
7. **Unified Referral Link Architecture**: Expose/confirm endpoints supporting the permanent personal invite link (`https://aestheticway.ae/invite/<code_or_user>`).

---

## 2. Item 1: Complete Deprecation of Regulatory License Fields

### Background:
The client requested complete removal of the "License Number" and "DHA / DOH / MOHAP" fields from all user-facing interfaces (Admin Create Clinic, Admin Clinic Detail Sheet, Clinic Profile, Doctor Profiles). These fields must not block clinic or practitioner onboarding.

### Target Files:
- `apps/clinics/models.py`
- `apps/clinics/serializers.py`
- `apps/clinics/portal_serializers.py`
- `apps/admin_portal/serializers.py` (or clinic admin serializers)
- `apps/practitioners/models.py`
- `apps/practitioners/serializers.py`
- `apps/practitioners/portal_serializers.py`

### Backend Actions Required:
1. **Model Fields**:
   In `apps/clinics/models.py`, `license_number` and `license_authority` are already defined with `blank=True, default=""`. Maintain them as optional/internal fields in the DB:
   ```python
   # apps/clinics/models.py
   license_number = models.CharField(max_length=100, blank=True, default="")
   license_authority = models.CharField(max_length=200, blank=True, default="")
   ```
2. **Serializers**:
   Ensure `ClinicSerializer`, `ClinicPortalSerializer`, and `AdminClinicSerializer` do **NOT** mark `license_number` or `license_authority` as `required=True`:
   ```python
   # In portal and admin serializers:
   license_number = serializers.CharField(required=False, allow_blank=True, default="")
   license_authority = serializers.CharField(required=False, allow_blank=True, default="")
   ```
   *Note*: When the mobile app creates or updates a clinic without providing license fields, the serializer must validate successfully without returning 400 Bad Request.

---

## 3. Item 2: Products Architectural Pivot (Cosmetic Brand Showcase)

### Background:
Products on AESTHETIC WAY are **NOT** clinic-specific inventory items; they are a separate advertising showcase for cosmetic skincare brands and pharmaceutical companies (e.g., La Roche-Posay, SkinCeuticals, Obagi).
- Products are displayed **WITHOUT** prices (no price fields or AED tags in the mobile app).
- Products have **NO checkout**, **NO cart**, and **NO direct purchase action buttons**.
- Products now occupy a permanent top-level tab in the mobile bottom navigation bar (`المنتجات`).

### Target Files:
- `apps/products/models.py`
- `apps/products/serializers.py`
- `apps/products/views.py` (or viewsets)

### Backend Actions Required:
1. **Price Nullability & Optionality**:
   In `apps/products/models.py`:
   ```python
   price = models.DecimalField(
       max_digits=10, decimal_places=2, null=True, blank=True
   )
   ```
   In `apps/products/serializers.py` (`PublicProductSerializer` and portal serializers):
   ```python
   # Allow price to be null/omitted without serializer errors
   price = serializers.DecimalField(
       max_digits=10, decimal_places=2, required=False, allow_null=True
   )
   ```
2. **Brand Metadata (Optional Enhancement)**:
   Add optional brand showcase fields if desired:
   ```python
   brand_name_en = models.CharField(max_length=200, blank=True, default="")
   brand_name_ar = models.CharField(max_length=200, blank=True, default="")
   sponsor_company = models.CharField(max_length=200, blank=True, default="")
   ```
3. **Clinic Relationship**:
   Ensure `clinic` ForeignKey on `Product` remains `null=True, blank=True` so that platform-wide brand showcase products not tied to a single clinic can be displayed.

---

## 4. Item 3: Treatments Creation 400 Fix (`apps/treatments/`)

### Background:
When clinic partners submitted new treatments via the Clinic Portal (`/api/v1/clinic-portal/treatments/`), requests previously returned `400 Bad Request` due to strict foreign key validation on `category` and practitioner lists.

### Target Files:
- `apps/treatments/portal_serializers.py`
- `apps/treatments/views.py`

### Backend Actions Required:
1. **Category Handling**:
   In `apps/treatments/portal_serializers.py`:
   ```python
   class ClinicTreatmentPortalSerializer(serializers.ModelSerializer):
       category = serializers.PrimaryKeyRelatedField(
           queryset=Category.objects.filter(is_active=True),
           required=True, # Must accept UUID
       )
   ```
   *Recommendation*: Support both `category` and `category_id` in `to_internal_value`:
   ```python
   def to_internal_value(self, data):
       if "category_id" in data and "category" not in data:
           data = data.copy()
           data["category"] = data["category_id"]
       return super().to_internal_value(data)
   ```
2. **Empty Practitioners Array**:
   Ensure `practitioners` accepts an empty list `[]` without error:
   ```python
   practitioners = serializers.PrimaryKeyRelatedField(
       many=True,
       queryset=Practitioner.objects.filter(deleted_at__isnull=True),
       required=False,
       allow_empty=True,
   )
   ```
   *Note*: The Flutter mobile app has been updated to automatically provide category fallback and send sanitized payloads. Implementing the above ensures bulletproof compatibility.

---

## 5. Item 4: Clinic Offers Creation Form Cleanup (`apps/offers/`)

### Background:
In the mobile app, when clinic staff creates a promotional offer in `ClinicOffersScreen`, manual input fields for email and phone have been removed. The system already knows the authenticated clinic's identity and contact details.

### Target Files:
- `apps/offers/portal_serializers.py`
- `apps/offers/views.py`

### Backend Actions Required:
Verify that `ClinicOfferPortalSerializer` does **NOT** expect `email` or `phone` in the request body. In `perform_create` of `ClinicOfferViewSet`:
```python
def perform_create(self, serializer):
    clinic = get_user_clinic(self.request.user)
    serializer.save(clinic=clinic)
```
*Status*: Backend inspection confirmed that `ClinicOfferPortalSerializer` already models `starts_at`, `ends_at`, `title`, and `description` cleanly without requiring phone/email. No schema breakage expected.

---

## 6. Item 5: Lead Submission Purity (`apps/leads/`)

### Background:
In accordance with AESTHETIC WAY core product boundaries:
- **No patient booking calendar**: No live doctor availability slots, no calendar day pickers.
- **Pure Lead / Contact Request**: Collects only patient name, UAE phone number, optional service/practitioner, and inquiry notes.
- **Success Copy**: `"تم إرسال طلبك وستتواصل العيادة معك"` ("Your request has been sent and the clinic will contact you").

### Target Files:
- `apps/leads/models.py`
- `apps/leads/serializers.py`
- `apps/leads/views.py`

### Backend Actions Required:
1. **Ensure Calendar Fields are Optional**:
   In `apps/leads/models.py`, `preferred_time_window` is already `blank=True, default=""`.
   Ensure no required `appointment_date`, `time_slot`, or `scheduled_at` fields exist on `LeadSerializer`:
   ```python
   # apps/leads/serializers.py
   class LeadCreateSerializer(serializers.ModelSerializer):
       class Meta:
           model = Lead
           fields = [
               "clinic",
               "branch",
               "practitioner",
               "treatment",
               "offer",
               "product",
               "lead_type",
               "patient_name",
               "patient_phone",
               "patient_email",
               "notes",
               "consent_accepted",
           ]
   ```

---

## 7. Item 6: Native Multipart Form-Data Media Uploads

### Background:
The mobile application now features `LuxuryImagePickerField`, allowing users, clinic admins, and super admins to pick photos directly from device camera or photo gallery. The mobile app sends requests via `dio.FormData` containing `MultipartFile`.

### Target Viewsets:
- `apps/clinics/views.py` (`ClinicViewSet`, `ClinicPortalViewSet`, `AdminClinicViewSet`)
- `apps/practitioners/views.py` (`PractitionerPortalViewSet`)
- `apps/products/views.py` (`ProductPortalViewSet`)
- `apps/offers/views.py` (`OfferPortalViewSet`)

### Backend Actions Required:
Ensure all viewsets handling image uploads explicitly include `MultiPartParser` and `FormParser`:
```python
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

class ClinicPortalViewSet(viewsets.ModelViewSet):
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    # ...
```
This enables Django to parse `request.FILES['logo']`, `request.FILES['cover_image']`, `request.FILES['avatar']`, etc., and save them to `media/` or S3 storage automatically via the standard `models.ImageField`.

---

## 8. Item 7: Modern Unified Referral Link Architecture

### Background:
The platform has transitioned from the legacy 500-point coupon redemption mechanism to a prestigious **Unified Referral Link** program:
- Each user possesses a permanent invite link: `https://aestheticway.ae/invite/{referral_code}`.
- When an invitee installs the app or registers via this link, the referral is credited to the referrer.

### Target Files:
- `apps/referrals/serializers.py`
- `apps/referrals/views/`
- `apps/accounts/serializers.py`

### Backend Actions Required:
1. **User Profile Serializer**:
   Ensure `UserProfileSerializer` or `/api/v1/referrals/my-code/` returns:
   ```json
   {
       "referral_code": "AW-78219",
       "invite_link": "https://aestheticway.ae/invite/AW-78219",
       "total_invited_friends": 12,
       "active_perks_count": 3
   }
   ```
2. **Registration Attribution**:
   During user registration (`POST /api/v1/auth/register/` or OTP verification), accept optional `referral_code`:
   ```python
   referral_code = validated_data.get("referral_code")
   if referral_code:
       ReferralService.record_referral(referrer_code=referral_code, new_user=user)
   ```

---

## 9. Verification & Testing Checklist for Ali

Ali can verify the above changes using the following Django test commands:
```bash
# In C:\Users\MVJD\Desktop\UAE_project\backend:
python manage.py test apps.clinics
python manage.py test apps.treatments
python manage.py test apps.products
python manage.py test apps.offers
python manage.py test apps.leads
python manage.py test apps.referrals
```

### Verification Criteria:
- [ ] `POST /api/v1/clinic-portal/treatments/` succeeds with category UUID and empty practitioners list.
- [ ] `POST /api/v1/clinic-portal/offers/` succeeds without `phone` or `email` in payload.
- [ ] `POST /api/v1/admin-portal/clinics/` succeeds with multipart `logo` and `cover_image` and without license fields.
- [ ] `POST /api/v1/leads/` creates a new consultation lead without appointment date or time slot.
- [ ] `GET /api/v1/products/` returns live products with null or omitted prices without error.

---
*For any questions or clarification regarding the mobile contract, please consult `docs/API_CONTRACT.md` and `docs/USER_ROLES_SPECIFICATION.md` in the Flutter repository.*
