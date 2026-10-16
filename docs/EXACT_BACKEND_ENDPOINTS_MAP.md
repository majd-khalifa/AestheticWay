# AESTHETIC WAY — Exact Backend Endpoints Map

**Document Version:** 1.0.0  
**Backend Source of Truth:** `C:\Users\MVJD\Desktop\UAE_project\backend`  
**API Version:** `v1` (`/api/v1/`)  
**Authentication Scheme:** Bearer JWT (`Authorization: Bearer <token>`)  
**Standard Pagination Structure:**
```json
{
  "count": 12,
  "next": null,
  "previous": null,
  "results": [ ... ]
}
```

---

## Table of Contents
1. [Overview & Base Paths](#1-overview--base-paths)
2. [Treatments & Categories (`apps/treatments/`)](#2-treatments--categories-appstreatments)
3. [Clinics & Branches (`apps/clinics/`)](#3-clinics--branches-appsclinics)
4. [Practitioners (`apps/practitioners/`)](#4-practitioners-appspractitioners)
5. [Products (`apps/products/`)](#5-products-appsproducts)
6. [Offers (`apps/offers/`)](#6-offers-appsoffers)
7. [Leads (`apps/leads/`)](#7-leads-appsleads)
8. [Admin Portal (`apps/admin_portal/`)](#8-admin-portal-appsadmin_portal)

---

## 1. Overview & Base Paths

| Namespace | Base URL | Scope / Permissions | Parsers |
| :--- | :--- | :--- | :--- |
| **Categories** | `/api/v1/categories/` | Public (`AllowAny`) | `JSONParser`, `FormParser` |
| **Treatments Public** | `/api/v1/treatments/` | Public (`AllowAny`) | `JSONParser`, `FormParser` |
| **Treatments Portal** | `/api/v1/clinic-portal/treatments/` | Clinic Partner (`IsClinicPortalAccess`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Clinics Public** | `/api/v1/clinics/` | Public (`AllowAny`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Clinic Portal Profile** | `/api/v1/clinic-portal/profile/` | Clinic Partner (`IsClinicPortalAccess`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Clinic Portal Branches**| `/api/v1/clinic-portal/branches/` | Clinic Partner (`IsClinicPortalAccess`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Clinic Dashboard** | `/api/v1/clinic-portal/dashboard/`| Clinic Partner (`IsClinicPortalAccess`) | `JSONParser` |
| **Practitioners Public**| `/api/v1/practitioners/` | Public (`AllowAny`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Practitioners Portal** | `/api/v1/clinic-portal/practitioners/` | Clinic Partner (`IsClinicPortalAccess`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Products Public** | `/api/v1/products/` | Public (`AllowAny`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Products Portal** | `/api/v1/clinic-portal/products/` | Clinic Partner (`IsClinicPortalAccess`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Offers Public** | `/api/v1/offers/` | Public (`AllowAny`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Offers Portal** | `/api/v1/clinic-portal/offers/` | Clinic Partner (`IsClinicPortalAccess`) | `MultiPartParser`, `FormParser`, `JSONParser` |
| **Leads Patient** | `/api/v1/leads/` / `patient/leads/` | Public / Patient | `JSONParser`, `FormParser` |
| **Leads Clinic Portal**| `/api/v1/clinic-portal/leads/` | Clinic Partner (`IsClinicPortalAccess`) | `JSONParser`, `FormParser` |
| **Super Admin Portal** | `/api/v1/admin/` | Super Admin (`IsSuperAdmin`) | `MultiPartParser`, `FormParser`, `JSONParser` |

---

## 2. Treatments & Categories (`apps/treatments/`)

### 2.1 Public Categories List
- **URL**: `GET /api/v1/categories/`
- **Permissions**: `AllowAny`
- **Query Params**: `search` (optional)
- **Response**: Array of Category objects
  ```json
  [
    {
      "id": "e9b2512a-3677-4b10-8671-55172eaae001",
      "name_en": "Dermatology & Skin Care",
      "name_ar": "الجلدية والعناية بالبشرة",
      "slug": "dermatology-skin-care",
      "icon": "https://.../icon.png",
      "display_order": 1
    }
  ]
  ```

### 2.2 Public Treatments Discovery
- **URL**: `GET /api/v1/treatments/`
- **Permissions**: `AllowAny`
- **Query Params**: `search`, `category`, `clinic`, `ordering` (`name_en`, `price`, `created_at`)
- **Response**: Paginated `PublicTreatmentListSerializer`
  ```json
  {
    "count": 45,
    "results": [
      {
        "id": "uuid",
        "name_en": "Botox Forehead",
        "name_ar": "بوتوكس الجبهة",
        "description_en": "Smoothing frown lines",
        "description_ar": "تنعيم خطوط التعبير",
        "price": "1200.00",
        "clinic": {
          "id": "uuid",
          "name_en": "Beverly Hills Clinic",
          "name_ar": "عيادة بيفرلي هيلز",
          "slug": "beverly-hills-clinic",
          "city": "Dubai",
          "logo": "https://.../logo.png"
        },
        "category": {
          "id": "uuid",
          "name_en": "Injectables",
          "name_ar": "الحقن التجميلي",
          "slug": "injectables",
          "icon": null,
          "display_order": 2
        }
      }
    ]
  }
  ```

### 2.3 Public Treatment Detail
- **URL**: `GET /api/v1/treatments/<id:uuid>/`
- **Permissions**: `AllowAny`
- **Response**: `PublicTreatmentDetailSerializer` (includes `practitioners` array)

### 2.4 Clinic Portal Treatments CRUD
- **Base URL**: `/api/v1/clinic-portal/treatments/`
- **Permissions**: `IsClinicPortalAccess` (scoped strictly to authenticated user's clinic)
- **Parser Classes**: `MultiPartParser`, `FormParser`, `JSONParser`
- **Endpoints**:
  - `GET /api/v1/clinic-portal/treatments/` &rarr; List clinic treatments (supports `?search=...`)
  - `POST /api/v1/clinic-portal/treatments/` &rarr; Create clinic treatment
  - `GET /api/v1/clinic-portal/treatments/<id:uuid>/` &rarr; Retrieve treatment
  - `PUT /api/v1/clinic-portal/treatments/<id:uuid>/` &rarr; Full update
  - `PATCH /api/v1/clinic-portal/treatments/<id:uuid>/` &rarr; Partial update
  - `DELETE /api/v1/clinic-portal/treatments/<id:uuid>/` &rarr; Soft-delete treatment
- **Request Payload (`ClinicTreatmentPortalSerializer`)**:
  | Field | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `category` | UUID | **YES** | PrimaryKey of active `Category` (also accepts `category_id`) |
  | `name_en` | String (200) | **YES** | English treatment name |
  | `name_ar` | String (200) | No | Arabic treatment name (defaults to `""`) |
  | `description_en` | Text | No | English description |
  | `description_ar` | Text | No | Arabic description |
  | `price` | Decimal (10,2)| No | Estimated price in AED (can be null) |
  | `status` | String | No | Choice: `"active"`, `"inactive"` (default: `"active"`) |
  | `is_active` | Boolean | No | Active toggle (default: `true`) |
  | `practitioners` | List[UUID] | No | Array of doctor UUIDs belonging to this clinic (`allow_empty=True`) |

---

## 3. Clinics & Branches (`apps/clinics/`)

### 3.1 Public Clinic Directory
- **URL**: `GET /api/v1/clinics/`
- **Permissions**: `AllowAny`
- **Query Params**: `search`, `city`, `emirate`, `latitude`, `longitude`, `is_featured`
- **Ordering**: Internal Subscription Tier (`VIP` &gt; `Featured` &gt; `Basic`) &rarr; Distance (if lat/lng) &rarr; Google Rating &rarr; `display_order` &rarr; `name_en`
- **Response**: Paginated `PublicClinicListSerializer` (internal tier/moderation strictly hidden).

### 3.2 Public Clinic Detail
- **URL**: `GET /api/v1/clinics/<id_or_slug>/`
- **Permissions**: `AllowAny`
- **Response**: `PublicClinicDetailSerializer` (includes `branches`, `practitioners`, `treatments`).

### 3.3 Clinic Portal Dashboard KPI
- **URL**: `GET /api/v1/clinic-portal/dashboard/`
- **Permissions**: `IsClinicPortalAccess`
- **Response**:
  ```json
  {
    "clinic_id": "uuid",
    "clinic_name": "Clinic Name",
    "interactions": {
      "whatsapp_taps": 140,
      "call_taps": 85,
      "maps_taps": 110,
      "profile_views": 1250
    },
    "leads": {
      "total": 52,
      "new": 8,
      "contacted": 30,
      "closed": 14,
      "conversion_rate_percentage": 84.6
    },
    "catalog": {
      "active_practitioners_count": 4,
      "active_treatments_count": 16,
      "active_offers_count": 2,
      "active_products_count": 8,
      "published_articles_count": 3
    }
  }
  ```

### 3.4 Clinic Portal Profile
- **URL**: `GET /api/v1/clinic-portal/profile/` & `PATCH / PUT /api/v1/clinic-portal/profile/`
- **Permissions**: `IsClinicPortalAccess`
- **Parser Classes**: `MultiPartParser`, `FormParser`, `JSONParser`
- **Editable Fields (`ClinicProfilePortalSerializer`)**:
  - `name_en`, `name_ar`, `description_en`, `description_ar`
  - `phone`, `whatsapp`, `email`, `website`
  - `address_en`, `address_ar`, `city`, `emirate`
  - `latitude`, `longitude`, `google_place_id`, `google_maps_url`
  - `logo` (Image file via multipart), `cover_image` (Image file via multipart)
- **Forbidden / Read-Only Fields**: `subscription_tier`, `status`, `license_number`, `license_authority`, `is_featured`, `google_rating`.

### 3.5 Clinic Portal Setup Checklist & Submission
- `GET /api/v1/clinic-portal/profile/setup-checklist/` &rarr; Returns progress percentage, items (`branding`, `details`, `branch`, `practitioners`, `treatments`), and `is_ready_for_review`.
- `POST /api/v1/clinic-portal/profile/submit-for-review/` &rarr; Submits profile for super admin review when all checklist items are complete.

### 3.6 Clinic Portal Branches
- **Base URL**: `/api/v1/clinic-portal/branches/`
- **Permissions**: `IsClinicPortalAccess`
- **CRUD**: Full CRUD for physical branches (`name_en`, `name_ar`, `address_en`, `city`, `phone`, `latitude`, `longitude`, `google_maps_url`, `is_main_branch`).

---

## 4. Practitioners (`apps/practitioners/`)

### 4.1 Public Practitioners
- `GET /api/v1/practitioners/` &rarr; Public directory of active doctors.
- `GET /api/v1/practitioners/<id:uuid>/` &rarr; Detail profile with bios, treatments performed, and clinic affiliation.

### 4.2 Clinic Portal Practitioners CRUD
- **Base URL**: `/api/v1/clinic-portal/practitioners/`
- **Permissions**: `IsClinicPortalAccess`
- **Parser Classes**: `MultiPartParser`, `FormParser`, `JSONParser`
- **Payload (`ClinicPractitionerPortalSerializer`)**:
  | Field | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `name_en` | String (200) | **YES** | English name (e.g. Dr. Jane Doe) |
  | `name_ar` | String (200) | No | Arabic name |
  | `title_en` | String (100) | No | Professional title (e.g. Dermatologist) |
  | `title_ar` | String (100) | No | Professional title in Arabic |
  | `speciality_en`| String (200) | No | Specialty in English |
  | `speciality_ar`| String (200) | No | Specialty in Arabic |
  | `type` | String | No | Choice: `"doctor"`, `"nurse"`, `"technician"`, `"specialist"` |
  | `bio_en`, `bio_ar` | Text | No | Medical biography |
  | `avatar` | File / Image | No | Photo upload via multipart form-data |
  | `license_number`| String | No | Optional / Non-blocking |
  | `license_authority`| String| No | Optional / Non-blocking |
  | `status` | String | No | Choice: `"active"`, `"inactive"` (default: `"active"`) |
  | `display_order`| Integer | No | Ordering sequence |

---

## 5. Products (`apps/products/`)

### 5.1 Public Brand Products Showcase
- **URL**: `GET /api/v1/products/` & `GET /api/v1/products/<id:uuid>/`
- **Permissions**: `AllowAny`
- **Rules**: Inquiry-only luxury brand showcase. Price is optional/omitted. No carts or checkout.
- **Fields (`PublicProductSerializer`)**:
  - `id`, `name_en`, `name_ar`, `description_en`, `description_ar`
  - `brand_name_en`, `brand_name_ar`, `sponsor_company`
  - `price` (optional / nullable)
  - `image_url`
  - `clinic` (Summary of sponsoring clinic/distributor)

### 5.2 Clinic Portal Products CRUD
- **Base URL**: `/api/v1/clinic-portal/products/`
- **Permissions**: `IsClinicPortalAccess`
- **Parser Classes**: `MultiPartParser`, `FormParser`, `JSONParser`
- **Payload (`ClinicProductPortalSerializer`)**:
  | Field | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `name_en` | String (200) | **YES** | Product Name |
  | `name_ar` | String (200) | No | Arabic Product Name |
  | `description_en` | Text | No | Product Description |
  | `description_ar` | Text | No | Arabic Description |
  | `brand_name_en` | String | No | Cosmetic Brand (e.g. SkinCeuticals) |
  | `brand_name_ar` | String | No | Brand Name in Arabic |
  | `sponsor_company`| String | No | Sponsoring Agency |
  | `price` | Decimal | No | Optional price (allows null) |
  | `image` | URL / File | No | Product photo |
  | `is_active` | Boolean | No | Active toggle |

---

## 6. Offers (`apps/offers/`)

### 6.1 Public Promotional Offers
- **URL**: `GET /api/v1/offers/` & `GET /api/v1/offers/<id:uuid>/`
- **Permissions**: `AllowAny`
- **Filter**: Active dates (`starts_at <= now <= ends_at`), `status="active"`.

### 6.2 Clinic Portal Offers CRUD
- **Base URL**: `/api/v1/clinic-portal/offers/`
- **Permissions**: `IsClinicPortalAccess`
- **Parser Classes**: `MultiPartParser`, `FormParser`, `JSONParser`
- **Payload (`ClinicOfferPortalSerializer`)**:
  | Field | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `title_en` | String (200) | **YES** | Offer Title |
  | `title_ar` | String (200) | No | Arabic Title |
  | `description_en` | Text | No | Inclusions / Terms |
  | `description_ar` | Text | No | Arabic Description |
  | `original_price` | Decimal | No | Original AED price before discount |
  | `offer_price` | Decimal | No | Discounted AED price |
  | `starts_at` | DateTime | No | Start date/time |
  | `ends_at` | DateTime | No | Expiration date/time |
  | `treatment` | UUID | No | Associated treatment UUID |
  | `image` | URL / File | No | Banner image upload |
  | *Contact Info* | *None* | *N/A* | **No email/phone required** (derived from clinic user) |

---

## 7. Leads (`apps/leads/`)

### 7.1 Patient Lead Submission
- **URL**: `POST /api/v1/leads/` (or `POST /api/v1/patient/leads/submit/`)
- **Permissions**: `AllowAny` (patient user linked if logged in, guest allowed)
- **Parser Classes**: `JSONParser`, `FormParser`
- **Payload (`PatientLeadCreateSerializer`)**:
  | Field | Type | Required | Description |
  | :--- | :--- | :---: | :--- |
  | `clinic` | UUID | **YES** | Target clinic UUID |
  | `patient_name` | String (200) | **YES\*** | Required if not authenticated |
  | `patient_phone`| String (20) | **YES\*** | Required UAE phone number |
  | `consent_accepted`| Boolean | **YES** | Must be `true` |
  | `branch` | UUID | No | Optional clinic branch UUID |
  | `treatment` | UUID | No | Optional treatment UUID |
  | `practitioner` | UUID | No | Optional doctor UUID |
  | `offer` | UUID | No | Optional offer UUID |
  | `product` | UUID | No | Optional product inquiry UUID |
  | `lead_type` | String | No | `"consultation"`, `"offer"`, `"product_inquiry"` |
  | `service_name` | String | No | Custom service name string |
  | `preferred_time_window`| String | No | `"morning"`, `"afternoon"`, `"evening"`, or `""` |
  | `notes` | Text | No | Patient inquiry details |
- **Calendar Boundaries**: Zero booking dates or calendar slots expected.
- **Success Response**: Returns created Lead with `reference_code` (e.g. `"#REQ-98241"`).

### 7.2 Patient My Requests Tracking
- `GET /api/v1/leads/my/` &rarr; Paginated consultation requests submitted by current patient.
- `GET /api/v1/leads/my/<id:uuid>/` &rarr; Detailed status (`sent`, `contacted`, `closed`).
- `GET /api/v1/leads/my/count/` &rarr; Count of active inquiries.

### 7.3 Clinic Portal Leads CRM
- **Base URL**: `/api/v1/clinic-portal/leads/`
- **Permissions**: `IsClinicPortalAccess`
- **Endpoints**:
  - `GET /api/v1/clinic-portal/leads/` &rarr; Filter leads by `?status=new`, `contacted`, `closed`.
  - `GET /api/v1/clinic-portal/leads/<id:uuid>/` &rarr; View lead details, internal notes, history.
  - `PATCH /api/v1/clinic-portal/leads/<id:uuid>/` &rarr; Update status: `{"status": "contacted"}`.
  - `POST /api/v1/clinic-portal/leads/<id:uuid>/notes/` &rarr; Add clinic internal note (`{"note": "..."}`).

---

## 8. Admin Portal (`apps/admin_portal/`)

### 8.1 Admin Dashboard
- **URL**: `GET /api/v1/admin/dashboard/`
- **Permissions**: `IsSuperAdmin`
- **Response**: Platform-wide metrics (total clinics, breakdown by tier, lead counts, conversion rate).

### 8.2 Clinic Provisioning & Lifecycle
- `GET /api/v1/admin/clinics/` &rarr; List all platform clinics with status & subscription tiers.
- `POST /api/v1/admin/clinics/` &rarr; **Provision New Clinic & Admin Account** (`AdminClinicProvisionSerializer`):
  ```json
  {
    "name_en": "Elite Dermatology Clinic",
    "name_ar": "عيادة النخبة للجلدية",
    "city": "Dubai",
    "emirate": "Dubai",
    "address_en": "Al Wasl Road, Jumeirah 2",
    "phone": "+97143456789",
    "whatsapp": "+971501234567",
    "subscription_tier": "vip",
    "is_featured": true,
    "admin_user": {
      "full_name": "Clinic Admin Name",
      "phone": "+971509876543",
      "email": "admin@eliteclinic.ae",
      "temporary_password": "SecurePassword123!"
    }
  }
  ```
- `GET /api/v1/admin/clinics/<id:uuid>/` &rarr; Deep clinic inspection.
- `PATCH /api/v1/admin/clinics/<id:uuid>/` &rarr; Update clinic tier, status, or contact info.
- `POST /api/v1/admin/clinics/<id:uuid>/suspend/` &rarr; 1-tap clinic suspension.
- `POST /api/v1/admin/clinics/<id:uuid>/activate/` &rarr; 1-tap clinic activation.
- `POST /api/v1/admin/clinics/<id:uuid>/verify/` &rarr; Toggle verified badge.
- `POST /api/v1/admin/clinics/<id:uuid>/reset-admin-password/` &rarr; Reset clinic admin password.
