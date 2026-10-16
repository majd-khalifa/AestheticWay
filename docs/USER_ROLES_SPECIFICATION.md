# AESTHETIC WAY — User Roles & Permissions Specification

**Document Version:** 2.0.0  
**Market:** United Arab Emirates (UAE) — Dubai, Abu Dhabi, Sharjah, Northern Emirates  
**Platforms:** Flutter Mobile (iOS / Android)  
**Last Updated:** October 2026  

---

## 1. Executive Summary & Platform Architecture

AESTHETIC WAY is the premier medical aesthetic, cosmetic dermatology, and plastic surgery discovery and lead-generation platform in the UAE.

The system is architected around **three distinct, non-overlapping user roles**:
1. **Normal User / Patient (`role: patient` / Public Visitor)**
2. **Clinic Partner (`role: clinic_admin` / `clinic_staff`)**
3. **Super Admin (`role: super_admin`)**

```
+-------------------------------------------------------------------------------+
|                             AESTHETIC WAY PLATFORM                            |
+-------------------------------------------------------------------------------+
         |                                     |                                |
         v                                     v                                v
+------------------+                 +-------------------+            +--------------------+
|  Patient/Public  |                 |   Clinic Portal   |            |    Super Admin     |
| (Discovery/Leads)|                 | (Partner Console) |            | (Platform Control) |
+------------------+                 +-------------------+            +--------------------+
| - Explore Clinics|                 | - Lead Management |            | - Global Metrics   |
| - Browse Doctors |                 | - Doctors CRUD    |            | - Provision Clinics|
| - Service Catalog|                 | - Treatments CRUD |            | - Tier Management  |
| - Brand Showcase |                 | - Offers Creation |            | - Suspend / Verify |
| - Send Lead Req  |                 | - Clinic Profile  |            | - Reset Passwords  |
| - Invite Friends |                 | - Media Uploads   |            | - Moderation       |
+------------------+                 +-------------------+            +--------------------+
```

### Strict Architectural Boundaries (All Roles)
- **Zero Patient Payments**: No credit card checkouts, payment gateways, Stripe, or in-app carts.
- **Zero In-App Booking Calendars**: No calendar slot pickers, no live doctor availability grids, no instant confirmation of medical dates inside the app.
- **Leads Only**: Appointment requests are pure high-intent lead submissions. The clinic contacts the patient directly via phone or WhatsApp.
- **No Home Services**: Only in-clinic licensed medical aesthetic procedures.
- **No Non-Medical Salons**: Strictly licensed medical aesthetic facilities.

---

## 2. Role 1: Normal User / Patient (`role: patient` & Public)

### 2.1 Persona & Objectives
The patient is an individual residing in or visiting the UAE seeking certified cosmetic dermatology, laser treatments, plastic surgery, or skincare products. They value luxury aesthetics, medical credibility, convenience, and direct contact.

### 2.2 Core Capabilities
1. **Comprehensive Discovery**:
   - Filter and search verified medical clinics by Emirate (Dubai, Abu Dhabi, Sharjah, etc.), category (Injectables, Laser, Skincare, Body Contouring, Surgery), and tier rating.
   - View clinic profiles with high-resolution cover photos, logo, bio, verified working hours, and direct Google Maps navigation.
   - Direct 1-tap contact via phone call (`tel:`) or WhatsApp (`https://wa.me/`).
2. **Medical Practitioner & Treatment Directory**:
   - Browse certified doctors, dermatologists, and plastic surgeons with their titles, specialties, and bios.
   - Explore detailed treatment descriptions, estimated durations, and expected results.
3. **Cosmetic Brand & Product Showcase (Architectural Pivot)**:
   - Dedicated **Products** (`المنتجات`) tab on the mobile bottom navigation bar.
   - Informational luxury showcase for international cosmetic skincare brands and clinic-sponsored products.
   - **No pricing tags**, **no carts**, **no checkout**, and **no purchase buttons** — purely educational brand advertising.
4. **Curated Offers & Medical Articles**:
   - Dedicated **Offers** (`العروض`) bottom tab displaying time-limited clinic promotional packages with discount percentages and validity dates.
   - Educational articles authored by certified practitioners covering patient safety and treatment guidelines.
5. **Pure Lead / Appointment Submission**:
   - Submits a consultation inquiry with strictly:
     - Patient Full Name
     - UAE Phone Number (+971)
     - Optional Treatment / Practitioner selection
     - Inquiry notes
     - Mandatory privacy & medical consent
   - **Zero date pickers, zero time slots, zero booking calendars**.
   - Mandatory success copy: `"تم إرسال طلبك وستتواصل العيادة معك"` ("Your request has been sent and the clinic will contact you").
6. **Lead Tracking ("My Requests" / `طلباتي`)**:
   - Accessible from the patient's Profile screen.
   - Displays real-time status of submitted consultation inquiries: `sent` (تم الإرسال), `contacted` (تم التواصل), `closed` (مكتمل).
   - Shows unique reference code (e.g. `#REQ-98241`).
7. **Unified Invite & Referral Program**:
   - Permanent personal invite link: `https://aestheticway.ae/invite/{referral_code}`.
   - 1-tap link copy with haptic feedback.
   - Direct 1-tap WhatsApp sharing with luxury Arabic RTL / English LTR pre-composed copy.
   - Counter tracking registered friends and referral perks.
8. **Profile & Personalization**:
   - Toggle language between Arabic RTL (primary) and English LTR.
   - Dark luxury navy/silver theme and clean light theme.
   - Manage favorites (saved clinics, treatments).

### 2.3 Restrictions
- Cannot view clinic lead dashboards or patient inquiries submitted to clinics.
- Cannot create or modify clinic catalog items (treatments, practitioners, offers).
- Cannot access Super Admin console or partner metrics.

---

## 3. Role 2: Clinic Partner (`role: clinic_admin` / `clinic_staff`)

### 3.1 Persona & Objectives
Licensed clinic managers, receptionists, and medical directors managing clinic presence on AESTHETIC WAY. Their primary objective is turning high-intent patient inquiries into consultation visits.

### 3.2 Core Capabilities
1. **Clinic Portal Dashboard**:
   - Overview of key metrics: Total Inquiries, New Leads Today, Contacted Rate, Total Doctors, Active Treatments, and Live Offers.
   - Quick-action buttons to add doctors, post offers, or edit profile.
2. **Real-Time Lead Management**:
   - Filter leads by status: `all`, `new` (sent), `contacted`, `closed`.
   - View complete patient inquiry: patient name, phone number, requested service/doctor, and notes.
   - Quick communication actions: 1-tap direct dial (`tel:`) and 1-tap WhatsApp chat with pre-filled greeting.
   - Update lead status directly from the app (e.g. mark as `contacted` after phone call, or add internal notes).
3. **Medical Practitioner Management (CRUD)**:
   - **Create**: Add new doctors with photo (camera/gallery upload via `multipart/form-data`), English & Arabic names, title (e.g., Consultant Dermatologist), specialty, bio, and active status.
   - **Edit**: Fully modify existing practitioner profiles, update photos, or change specialties via `_showAddPractitionerDialog(existing)`.
   - **Delete**: Soft-delete or remove practitioners who have left the clinic.
   - *Note*: Regulatory license numbers and DHA/DOH/MOHAP authority fields have been removed from the UI.
4. **Treatment & Service Catalog Management (CRUD)**:
   - **Create**: Add services with English & Arabic names, category selection (automatically mapped to backend UUID), duration (minutes), description, and price estimate.
   - **Edit**: Update service details, change categories, or adjust pricing estimates.
   - **Delete**: Remove discontinued treatments.
5. **Clinic Offers Creation & Management (CRUD)**:
   - **Create**: Publish promotional campaigns with banner image upload, discount percentage, valid-until date, and description.
   - **Clean Form UX**: Does NOT prompt staff for email or phone — the system automatically links the authenticated clinic's contact details.
   - **Delete**: Retire expired promotions.
6. **Clinic Profile & Branding Management**:
   - Upload official Clinic Logo and Cover Photo directly from device camera or photo library.
   - Edit clinic Arabic and English names, bio, address, emirate/city, direct phone number, WhatsApp number, and Google Maps location URL.
7. **Onboarding Checklist**:
   - Dynamic 4-step setup checklist (Logo & Cover, Add at least 1 Doctor, Add at least 1 Treatment, Create first Offer).

### 3.3 Restrictions
- Cannot change own subscription tier (VIP, Featured, Basic) — managed exclusively by Super Admin.
- Cannot verify or un-verify own clinic badge.
- Cannot access or view leads belonging to other clinics.
- Cannot access platform-wide Super Admin tools or user databases.

---

## 4. Role 3: Super Admin (`role: super_admin`)

### 4.1 Persona & Objectives
Platform executives and operations leads at AESTHETIC WAY responsible for clinic onboarding, tier monetisation, content moderation, and platform health.

### 4.2 Core Capabilities
1. **Global Platform Dashboard**:
   - Real-time aggregate statistics: Total Registered Clinics, Active vs Suspended Clinics, VIP/Featured/Basic breakdown, Total Platform Leads.
2. **Clinic Provisioning (`AdminCreateClinicDialog`)**:
   - Create and onboard new clinics:
     - Clinic Arabic & English Name
     - Unique URL slug
     - Subscription Tier selection: VIP (12 months), Featured (6 months), Basic (1 month)
     - City / Emirate selection (Dubai, Abu Dhabi, Sharjah, etc.)
     - Address and Google Maps URL
     - Phone and WhatsApp contact details
     - Native Clinic Logo & Cover Photo upload from device gallery/camera
   - **Instant Admin Account Generation**: Provisioning automatically creates the clinic's initial `clinic_admin` user credentials.
3. **Clinic Lifecycle & Moderation (`AdminClinicDetailSheet`)**:
   - **Direct Profile Editing**: Edit clinic name, bio, tier, city, address, phone, WhatsApp, and branding images.
   - **Activation & Suspension**: 1-tap toggle to immediately suspend a non-compliant or delinquent clinic, removing them from patient search.
   - **Verification Badge**: Toggle official verified checkmark on clinic profile.
   - **Password Reset**: Securely generate or reset credentials for clinic staff when requested.
4. **Content & Subscription Priority Enforcement**:
   - Enforce display hierarchy:
     1. **VIP**: Highest placement on Home carousel and top of Clinic search directory.
     2. **Featured**: Secondary carousel and priority directory listing.
     3. **Basic**: Standard alphabetized listing only.

### 4.3 Restrictions
- Super Admin does not impersonate patients to submit fake medical leads.
- Operates under strict UAE healthcare advertising compliance guidelines.

---

## 5. Security & Access Control Matrix

| Feature / Screen | Patient (`role: patient` / Public) | Clinic Partner (`role: clinic_admin` / `clinic_staff`) | Super Admin (`role: super_admin`) |
| :--- | :---: | :---: | :---: |
| **Browse Clinics & Search** | Full Access | Full Access | Full Access |
| **View Brand Products Showcase** | Full Access | Full Access | Full Access |
| **Submit Lead Request** | Full Access | Full Access | Full Access |
| **View Own Submitted Requests** | Full Access | N/A | N/A |
| **View Clinic Lead Inbox** | Denied (403) | Full Access (Own Clinic Only) | Read/Audit |
| **Edit Clinic Branding & Contact** | Denied (403) | Full Access (Own Clinic) | Full Access (All Clinics) |
| **CRUD Doctors & Treatments** | Denied (403) | Full Access (Own Clinic) | Full Access |
| **Create Promotional Offers** | Denied (403) | Full Access (Own Clinic) | Full Access |
| **Provision New Clinics** | Denied (403) | Denied (403) | Full Access |
| **Assign Subscription Tiers** | Denied (403) | Denied (403) | Full Access |
| **Suspend / Verify Clinic** | Denied (403) | Denied (403) | Full Access |
| **Reset Clinic Staff Password** | Denied (403) | Denied (403) | Full Access |
| **Personal Invite Link** | Full Access | Full Access | Full Access |

---

## 6. Language & Localization Rules Across Roles

1. **Arabic RTL is the Primary First-Class Language**:
   - All forms, dashboards, dialogs, and navigation default to natural, prestigious Gulf/Modern Standard Arabic.
   - English LTR is available via a 1-tap toggle across all screens.
2. **Numeric Fields & Phone Inputs**:
   - Phone numbers and emails are rendered in forced LTR (`TextDirection.ltr`) using `LtrTextFormField` to prevent UAE phone numbers (`+971 50 ...`) from scrambling in Arabic RTL mode.
3. **Success Messages**:
   - Lead submission must strictly output: `"تم إرسال طلبك وستتواصل العيادة معك"` ("Your request has been sent and the clinic will contact you").
