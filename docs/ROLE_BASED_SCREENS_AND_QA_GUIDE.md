# AESTHETIC WAY — Role-Based Screens & Exhaustive QA Guide

**Document Version:** 2.0.0  
**Target Market:** United Arab Emirates (UAE)  
**Framework:** Flutter (iOS & Android)  
**Last Updated:** October 2026  

---

## Table of Contents
1. [Overview & Role Separation](#1-overview--role-separation)
2. [Patient / Public Screens & QA Checklists](#2-patient--public-screens--qa-checklists)
   - 2.1 MainNavScreen (5-Tab Structure)
   - 2.2 HomeScreen
   - 2.3 ClinicsScreen & ClinicDetailScreen
   - 2.4 AppointmentRequestScreen & AppointmentSuccessScreen
   - 2.5 ProductsScreen & ProductDetailScreen (Brand Showcase)
   - 2.6 OffersScreen & OfferDetailScreen
   - 2.7 ArticlesScreen & ArticleDetailScreen
   - 2.8 MyRequestsScreen & AppointmentDetailScreen
   - 2.9 ReferralScreen (Unified Invite Link)
   - 2.10 ProfileScreen & Auth Screens
3. [Clinic Partner Screens & QA Checklists](#3-clinic-partner-screens--qa-checklists)
   - 3.1 ClinicDashboardScreen
   - 3.2 ClinicLeadsScreen & ClinicLeadDetailScreen
   - 3.3 ClinicProfileScreen
   - 3.4 ClinicPractitionersScreen (CRUD with Photo Upload)
   - 3.5 ClinicTreatmentsScreen (CRUD with Category Binding)
   - 3.6 ClinicOffersScreen (CRUD with Clean Form)
4. [Super Admin Screens & QA Checklists](#4-super-admin-screens--qa-checklists)
   - 4.1 AdminDashboardScreen
   - 4.2 AdminClinicsScreen
   - 4.3 AdminCreateClinicDialog
   - 4.4 AdminClinicDetailSheet
5. [Automated QA Test Suite Verification](#5-automated-qa-test-suite-verification)

---

## 1. Overview & Role Separation

AESTHETIC WAY routes and user interfaces are strictly partitioned by role:
- **Patient / Public**: Focused entirely on discovery, luxury aesthetic presentation, direct phone/WhatsApp contact, cosmetic brand awareness, and submitting consultation leads.
- **Clinic Partner (`role: clinic_admin` / `clinic_staff`)**: Accessible via Clinic Portal mode in profile; provides a full CRM and catalog management suite for clinic operations.
- **Super Admin (`role: super_admin`)**: Accessible via Admin Portal mode in profile; provides comprehensive clinic provisioning, tier allocation, and platform moderation.

---

## 2. Patient / Public Screens & QA Checklists

### 2.1 `MainNavScreen`
- **Route / Widget**: `MainNavScreen` (`lib/features/navigation/main_nav_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **Bottom Navigation Structure (5 Tabs)**:
  1. Tab 0: **Home (`الرئيسية`)** — `HomeScreen`
  2. Tab 1: **Clinics (`العيادات`)** — `ClinicsScreen`
  3. Tab 2: **Products (`المنتجات`)** — `ProductsScreen` (Cosmetic Brand Showcase)
  4. Tab 3: **Offers (`العروض`)** — `OffersScreen` (Promotional Packages)
  5. Tab 4: **Profile (`حسابي`)** — `ProfileScreen` (Settings, Requests, Auth)
- **QA Checklist**:
  - [ ] App launches with 5 distinct bottom navigation items with correct Arabic and English translations.
  - [ ] Active tab icon is highlighted in silver/platinum (`AppColors.silverPrimary` / `accentChampagne`).
  - [ ] Tapping each tab switches screens instantly without frame drops or re-creating state.
  - [ ] App brand logo (`AppBrandLogo`) renders crisply at the top app bar on relevant tabs.

---

### 2.2 `HomeScreen`
- **Route / Widget**: `HomeScreen` (`lib/features/home/presentation/screens/home_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **UI Elements & Gestures**:
  - Search bar with instant clinic filter.
  - City / Emirate filter chips (Dubai, Abu Dhabi, Sharjah, etc.).
  - Featured Ads Hero Carousel (`FeaturedAdsCarousel`) prioritizing VIP and Featured clinics.
  - Quick Category Grid (Injectables, Laser, Skincare, Surgery).
  - Top Clinics horizontal scroll.
  - Latest Cosmetic Offers showcase.
  - Latest Dermatologist Articles carousel.
- **QA Checklist**:
  - [ ] VIP ads display first in the hero carousel, followed by Featured ads.
  - [ ] Tapping a hero banner navigates directly to the associated clinic profile or offer.
  - [ ] Selecting "Dubai" or "Abu Dhabi" filters the displayed clinics accordingly.
  - [ ] Tapping category chips routes to `ClinicsScreen` with the category pre-filtered.
  - [ ] Pull-to-refresh re-fetches latest carousel items and clinics.

---

### 2.3 `ClinicsScreen` & `ClinicDetailScreen`
- **Route / Widgets**: `ClinicsScreen` (`lib/features/clinics/presentation/screens/clinics_screen.dart`), `ClinicDetailScreen` (`lib/features/clinics/presentation/screens/clinic_detail_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **UI Elements & Gestures**:
  - Clinic list cards displaying cover photo, logo, Arabic/English name, area, verified badge, rating, and tier indicator.
  - In `ClinicDetailScreen`:
    - Full-bleed header image and clinic logo.
    - 1-tap **Call** button (`tel:+971...`).
    - 1-tap **WhatsApp** button (`https://wa.me/971...`).
    - 1-tap **Google Maps** button opening native Google Maps or web directions.
    - Clinic bio, working hours, and address.
    - Doctors tab listing certified practitioners.
    - Treatments tab listing services with durations and estimated prices.
    - Offers tab showing active packages.
    - Floating action button: **Request Consultation (`طلب استشارة`)**.
- **QA Checklist**:
  - [ ] Regulatory license numbers and DHA/DOH/MOHAP authority tags DO NOT appear anywhere on the screen.
  - [ ] Tapping "Call" prompts device dialer with the clinic's phone number.
  - [ ] Tapping "WhatsApp" launches WhatsApp with a pre-filled Arabic/English greeting.
  - [ ] Tapping "Google Maps" opens the exact clinic coordinates/link.
  - [ ] Tapping "Request Consultation" opens `AppointmentRequestScreen`.

---

### 2.4 `AppointmentRequestScreen` & `AppointmentSuccessScreen`
- **Route / Widgets**: `AppointmentRequestScreen` (`lib/features/appointment_lead/presentation/screens/appointment_request_screen.dart`), `AppointmentSuccessScreen` (`lib/features/appointment_lead/presentation/screens/appointment_success_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **UI Elements & Inputs**:
  - Selected Clinic banner.
  - Optional Service dropdown & Practitioner dropdown.
  - Patient Full Name input.
  - UAE Phone Number input with forced LTR formatting (`+971 50 ...`).
  - Inquiry Notes text field (optional).
  - Medical / Privacy Consent checkbox.
  - Submit Lead button (`إرسال طلب الاستشارة`).
  - **PURITY CHECK**: ZERO date pickers, ZERO time slot chips, ZERO calendar widgets.
- **QA Checklist**:
  - [ ] Verify there is NO date picker, NO calendar button, and NO time slot selection (morning/evening) on the screen.
  - [ ] Submitting without phone or name shows clear, localized validation errors.
  - [ ] Entering valid UAE phone (+971 50 123 4567) and accepting consent enables submission.
  - [ ] On submit: Navigates to `AppointmentSuccessScreen`.
  - [ ] Success screen MUST display the exact legally approved copy:
    `"تم إرسال طلبك وستتواصل العيادة معك"` ("Your request has been sent and the clinic will contact you").
  - [ ] Displays unique reference code (e.g. `#REQ-98241`).
  - [ ] "Go to My Requests" button navigates to `MyRequestsScreen`.

---

### 2.5 `ProductsScreen` & `ProductDetailScreen` (Brand Showcase Pivot)
- **Route / Widgets**: `ProductsScreen` (`lib/features/products/presentation/screens/products_screen.dart`), `ProductDetailScreen` (`lib/features/products/presentation/screens/product_detail_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **UI Elements & Architectural Rules**:
  - Grid of cosmetic brand products showcasing product image, brand/sponsor name, product title, and category.
  - In `ProductDetailScreen`:
    - High-resolution hero image.
    - Brand / Sponsor clinic card with verified badge.
    - Product title and category badge.
    - Comprehensive product description and dermatological benefits.
    - Availability badge (`متوفر` / `غير متوفر`).
  - **STRICT PIVOT RULES**:
    - **NO price displays** (no AED tags, no strikethrough prices).
    - **NO Cart button** or bag icon.
    - **NO Checkout** or payment options.
    - **NO WhatsApp / Call / Inquire action buttons** — strictly an informational luxury brand showcase.
- **QA Checklist**:
  - [ ] Product cards in `ProductsScreen` display image, title, and brand name WITHOUT any price text.
  - [ ] `ProductDetailScreen` renders hero image, title, and description cleanly.
  - [ ] Verify that `Icons.shopping_cart` and `Icons.send_rounded` (inquiry button) DO NOT exist on the screen.
  - [ ] Tapping "Brand / Sponsor" opens the sponsoring clinic's profile.

---

### 2.6 `OffersScreen` & `OfferDetailScreen`
- **Route / Widgets**: `OffersScreen` (`lib/features/offers/presentation/screens/offers_screen.dart`), `OfferDetailScreen` (`lib/features/offers/presentation/screens/offer_detail_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **UI Elements**:
  - List/Grid of promotional clinic packages with cover image, clinic logo, title, discount badge (`25% OFF`), and validity date (`ينتهي في 30 نوفمبر`).
  - In `OfferDetailScreen`: full package details, terms, providing clinic info, and direct "Request Offer / Consultation" button.
- **QA Checklist**:
  - [ ] Offers display promotional discount percentage and expiration date clearly.
  - [ ] Tapping an offer opens `OfferDetailScreen`.
  - [ ] Tapping "Request Consultation for Offer" opens the lead request form with the offer pre-selected.

---

### 2.7 `ArticlesScreen` & `ArticleDetailScreen`
- **Route / Widgets**: `ArticlesScreen` (`lib/features/articles/presentation/screens/articles_screen.dart`), `ArticleDetailScreen` (`lib/features/articles/presentation/screens/article_detail_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **UI Elements**:
  - Educational medical aesthetic articles authored by licensed doctors.
  - Author practitioner card, reading time, publication date, and medical disclaimers.
- **QA Checklist**:
  - [ ] Articles display author practitioner name and thumbnail.
  - [ ] Tapping an article opens the full reader with high-contrast luxury typography.
  - [ ] Share button triggers native share sheet.

---

### 2.8 `MyRequestsScreen` & `AppointmentDetailScreen`
- **Route / Widgets**: `MyRequestsScreen` (`lib/features/appointment_lead/presentation/screens/my_requests_screen.dart`), `AppointmentDetailScreen` (`lib/features/appointment_lead/presentation/screens/appointment_detail_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **UI Elements**:
  - Accessible via **ProfileScreen -> My Requests (`طلباتي`)**.
  - List of patient's submitted consultation requests with reference codes (`#REQ-98241`), clinic names, submission dates, and status pills:
    - `sent` (تم الإرسال - Silver/Blue)
    - `contacted` (تم التواصل - Champagne Gold)
    - `closed` (مكتمل - Emerald Green)
  - In detail view: full inquiry details, requested service, and direct call/WhatsApp buttons to reach the clinic.
- **QA Checklist**:
  - [ ] Tapping "My Requests" in `ProfileScreen` navigates to `MyRequestsScreen`.
  - [ ] Leads display correct statuses and reference numbers.
  - [ ] Empty state renders a helpful message with a button to browse clinics when no leads exist.

---

### 2.9 `ReferralScreen` (Unified Invite Link Overhaul)
- **Route / Widget**: `ReferralScreen` (`lib/features/referral/presentation/screens/referral_screen.dart`)
- **Owning Role**: Patient / Public Visitor
- **UI Elements & Actions**:
  - Hero card: **Invite Friends to Aesthetic Way (`دعوة الأصدقاء`)**.
  - Personal Referral Link container: `https://aestheticway.ae/invite/{code}`.
  - **Copy Link** button: Copies URL to device clipboard, triggers haptic feedback, and displays a success toast.
  - **Share via WhatsApp** button: Launches WhatsApp with pre-composed luxury invitation copy:
    - *Arabic*: `"انضم معي إلى إستيتك واي واكتشف أفضل العيادات والمراكز الطبية المعتمدة في الإمارات. استخدم الرابط للحصول على مزايا حصرية: https://aestheticway.ae/invite/{code}"`
    - *English*: `"Join me on Aesthetic Way and explore premier medical aesthetic clinics in the UAE. Use my link: https://aestheticway.ae/invite/{code}"`
  - Stats counter showing Invited Friends count and Active Perks.
  - **DECOMMISSIONED**: Legacy 500-point coupon redemption and complex point-earning tiers are removed.
- **QA Checklist**:
  - [ ] Tapping "Copy Link" copies `https://aestheticway.ae/invite/...` to clipboard and shows toast.
  - [ ] Tapping "Share via WhatsApp" launches WhatsApp with localized invitation text and link.
  - [ ] Referral code displays cleanly with high visual contrast in dark and light modes.

---

### 2.10 `ProfileScreen` & Auth Screens
- **Route / Widgets**: `ProfileScreen` (`lib/features/profile/presentation/screens/profile_screen.dart`), `AuthScreen`, `PhoneAuthScreen`, `VerifyOtpScreen`, `SetNewPasswordScreen`
- **Owning Role**: Patient / Public Visitor & Portal Switcher
- **UI Elements**:
  - User name, phone number, and avatar.
  - Quick tiles: My Requests (`طلباتي`), Saved Favorites (`المفضلة`), Language Switcher (AR/EN), Theme Switcher (Dark/Light).
  - Portal Switcher (for staff/admin): Switch to Clinic Portal, Switch to Super Admin Portal.
  - Logout and Account deletion actions.
- **QA Checklist**:
  - [ ] Toggling language switches between Arabic RTL and English LTR immediately.
  - [ ] Toggling theme switches between Luxury Dark Navy and Clean Light mode.
  - [ ] Phone authentication uses `LtrTextFormField` and validates UAE phone format.

---

## 3. Clinic Partner Screens & QA Checklists

### 3.1 `ClinicDashboardScreen`
- **Route / Widget**: `ClinicDashboardScreen` (`lib/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart`)
- **Owning Role**: Clinic Partner (`role: clinic_admin` / `clinic_staff`)
- **UI Elements**:
  - Clinic branding banner (Logo, Cover Photo, Clinic Name, Tier badge).
  - Metrics Grid: Total Leads, New Inquiries Today, Contacted Rate, Doctors Count, Active Services.
  - Onboarding Checklist: Setup progress bar (Logo/Cover, First Doctor, First Treatment, First Offer).
  - Quick Action Buttons: Manage Leads, Add Doctor, Add Service, Add Offer, Edit Profile.
- **QA Checklist**:
  - [ ] Displays only data and metrics belonging to the authenticated clinic.
  - [ ] Tapping any metric or quick action routes to the corresponding management screen.
  - [ ] Setup checklist dynamically marks completed steps as checked.

---

### 3.2 `ClinicLeadsScreen` & `ClinicLeadDetailScreen`
- **Route / Widgets**: `ClinicLeadsScreen` (`lib/features/clinic_portal/presentation/screens/clinic_leads_screen.dart`), `ClinicLeadDetailScreen` (`lib/features/clinic_portal/presentation/screens/clinic_lead_detail_screen.dart`)
- **Owning Role**: Clinic Partner (`role: clinic_admin` / `clinic_staff`)
- **UI Elements**:
  - Status filter tabs: All (`الكل`), New (`جديدة`), Contacted (`تم التواصل`), Closed (`مكتملة`).
  - Lead Cards: Patient name, phone number, inquiry date/time, requested service, requested practitioner.
  - Quick Action Buttons on cards: 1-tap Phone Call, 1-tap WhatsApp.
  - In `ClinicLeadDetailScreen`:
    - Full patient notes.
    - Status changer dropdown (`sent` -> `contacted` -> `closed`).
    - Internal clinic notes input.
- **QA Checklist**:
  - [ ] Incoming leads appear in real-time under the "New" filter.
  - [ ] Tapping Call button opens device dialer with the patient's phone number.
  - [ ] Tapping WhatsApp button opens WhatsApp with patient's number and clinic greeting.
  - [ ] Updating lead status from "New" to "Contacted" immediately updates the lead pill and badge counter.

---

### 3.3 `ClinicProfileScreen`
- **Route / Widget**: `ClinicProfileScreen` (`lib/features/clinic_portal/presentation/screens/clinic_profile_screen.dart`)
- **Owning Role**: Clinic Partner (`role: clinic_admin`)
- **UI Elements**:
  - Native Image Pickers (`LuxuryImagePickerField`):
    - Clinic Logo (Gallery / Camera pick, instant preview).
    - Clinic Cover Photo (Gallery / Camera pick, instant preview).
  - Clinic Name (Arabic & English).
  - Bio / About Clinic (Arabic & English).
  - City / Emirate dropdown.
  - Physical Address and Google Maps URL.
  - Direct Phone and WhatsApp numbers.
  - **PURITY CHECK**: ZERO license number fields, ZERO DHA/DOH/MOHAP authority dropdowns.
- **QA Checklist**:
  - [ ] Verify license number and authority fields DO NOT appear anywhere on the profile screen.
  - [ ] Tapping Clinic Logo opens bottom sheet allowing Camera or Gallery selection.
  - [ ] Selecting an image shows instant preview with replace/remove action buttons.
  - [ ] Saving profile sends `dio.FormData` with `MultipartFile` and successfully updates clinic branding.

---

### 3.4 `ClinicPractitionersScreen` (Full CRUD + Native Image Picker)
- **Route / Widget**: `ClinicPractitionersScreen` (`lib/features/clinic_portal/presentation/screens/clinic_practitioners_screen.dart`)
- **Owning Role**: Clinic Partner (`role: clinic_admin`)
- **UI Elements**:
  - List of clinic doctors with avatar, Arabic & English names, title, specialty, and active badge.
  - Add Doctor floating action button.
  - Card Action Buttons: **Edit Doctor** (`Icons.edit_outlined`) and **Delete Doctor** (`Icons.delete_outline`).
  - Add / Edit Dialog:
    - Native Avatar Picker (`LuxuryImagePickerField`).
    - Doctor Name (Arabic & English).
    - Title (e.g. Consultant Dermatologist / استشاري أمراض جلدية).
    - Specialty (e.g. Botox & Fillers / حقن تجميلي).
    - Bio / Experience notes.
    - Active toggle.
- **QA Checklist**:
  - [ ] Tapping "+ Add Doctor" opens dialog with blank fields.
  - [ ] Tapping Edit icon on an existing doctor opens dialog pre-populated with doctor's current details.
  - [ ] Doctor photo can be picked from Camera or Gallery with instant preview.
  - [ ] Saving creates or updates the doctor without requiring license authority.
  - [ ] Deleting prompts confirmation and removes doctor from the list.

---

### 3.5 `ClinicTreatmentsScreen` (Full CRUD + Category Binding)
- **Route / Widget**: `ClinicTreatmentsScreen` (`lib/features/clinic_portal/presentation/screens/clinic_treatments_screen.dart`)
- **Owning Role**: Clinic Partner (`role: clinic_admin`)
- **UI Elements**:
  - List of services grouped by category with duration (min) and estimated price (AED).
  - Add Service button.
  - Edit & Delete actions on service cards.
  - Add / Edit Treatment Sheet:
    - Service Name (Arabic & English).
    - Category selection dropdown (maps to backend UUID, fallback to first active category).
    - Duration in minutes (e.g. 30, 45, 60).
    - Estimated Price in AED.
    - Description (Arabic & English).
- **QA Checklist**:
  - [ ] Adding a treatment sends valid category UUID and avoids 400 Bad Request error.
  - [ ] If category list is slow to load, automatic category fallback prevents creation failure.
  - [ ] Editing updates the service details cleanly.
  - [ ] Deleting removes the service from the clinic catalog.

---

### 3.6 `ClinicOffersScreen` (Clean Form CRUD)
- **Route / Widget**: `ClinicOffersScreen` (`lib/features/clinic_portal/presentation/screens/clinic_offers_screen.dart`)
- **Owning Role**: Clinic Partner (`role: clinic_admin`)
- **UI Elements**:
  - List of active and expired clinic offers.
  - Add Offer button.
  - Add Offer Sheet:
    - Offer Banner Image native picker (`LuxuryImagePickerField`).
    - Offer Title (Arabic & English).
    - Discount Percentage (e.g. 20%).
    - Valid Until date picker.
    - Offer Description / Package inclusions.
    - **CLEAN FORM CHECK**: NO manual email field, NO manual phone field (system automatically links authenticated clinic credentials).
- **QA Checklist**:
  - [ ] Form does NOT prompt clinic staff to re-enter email or phone.
  - [ ] Banner image can be selected from Camera or Gallery with instant preview.
  - [ ] Creating an offer sends `dio.FormData` and publishes the offer to the platform.
  - [ ] Offers display in patient discovery under `OffersScreen`.

---

## 4. Super Admin Screens & QA Checklists

### 4.1 `AdminDashboardScreen`
- **Route / Widget**: `AdminDashboardScreen` (`lib/features/admin/presentation/screens/admin_dashboard_screen.dart`)
- **Owning Role**: Super Admin (`role: super_admin`)
- **UI Elements**:
  - Platform Overview: Total Clinics, Active Clinics, Suspended Clinics, VIP/Featured/Basic breakdown, Total Platform Leads.
  - Navigation button to Clinics Management (`AdminClinicsScreen`).
- **QA Checklist**:
  - [ ] Metric counters reflect accurate database counts across all clinics.
  - [ ] Tapping "Manage Clinics" opens `AdminClinicsScreen`.

---

### 4.2 `AdminClinicsScreen`
- **Route / Widget**: `AdminClinicsScreen` (`lib/features/admin/presentation/screens/admin_clinics_screen.dart`)
- **Owning Role**: Super Admin (`role: super_admin`)
- **UI Elements**:
  - Search bar to search clinics by name, city, or slug.
  - Filter chips: All, Active, Suspended, VIP, Featured, Basic.
  - Clinic list tiles with Logo, Name, City, Tier badge, Status pill.
  - Floating action button: **+ Provision New Clinic**.
  - Tapping a clinic tile opens `AdminClinicDetailSheet`.
- **QA Checklist**:
  - [ ] Search dynamically filters clinic list in real-time.
  - [ ] Tier badges (VIP = Gold, Featured = Silver, Basic = Neutral) are clearly distinguishable.
  - [ ] Tapping "+ Provision New Clinic" opens `AdminCreateClinicDialog`.

---

### 4.3 `AdminCreateClinicDialog`
- **Route / Widget**: `AdminCreateClinicDialog` (`lib/features/admin/presentation/screens/admin_create_clinic_dialog.dart`)
- **Owning Role**: Super Admin (`role: super_admin`)
- **UI Elements & Inputs**:
  - Native Image Pickers (`LuxuryImagePickerField`):
    - Clinic Logo (Camera / Gallery).
    - Clinic Cover Photo (Camera / Gallery).
  - Clinic Arabic & English Name.
  - Unique URL slug (auto-suggested from English name).
  - Subscription Tier dropdown: `VIP (12 months)`, `Featured (6 months)`, `Basic (1 month)`.
  - City / Emirate dropdown (Dubai, Abu Dhabi, Sharjah, etc.).
  - Physical Address and Google Maps URL.
  - Direct Phone and WhatsApp numbers.
  - **PURITY CHECK**: ZERO license number fields, ZERO license authority dropdowns.
  - Submit Button: **Create Clinic & Admin Account (`إنشاء العيادة والحساب`)**.
- **QA Checklist**:
  - [ ] Verify license number and authority inputs are completely absent.
  - [ ] Native logo and cover photos can be picked with instant previews.
  - [ ] Submitting provisions the clinic in the database and creates an initial clinic admin account.
  - [ ] Success message is displayed and the clinic appears immediately in `AdminClinicsScreen`.

---

### 4.4 `AdminClinicDetailSheet`
- **Route / Widget**: `AdminClinicDetailSheet` (`lib/features/admin/presentation/screens/admin_clinic_detail_sheet.dart`)
- **Owning Role**: Super Admin (`role: super_admin`)
- **UI Elements & Actions**:
  - Clinic Header: Cover photo, Logo, Name, Tier badge, Verification badge.
  - **Edit Details**: Allows Super Admin to modify clinic name, tier, city, address, phone, WhatsApp, and re-upload logo/cover.
  - **Toggle Activation / Suspension**: 1-tap action to activate or suspend the clinic.
  - **Toggle Verified Badge**: 1-tap action to grant or revoke the official verification checkmark.
  - **Reset Admin Password**: Opens a dialog to generate or set a new password for the clinic's admin user.
  - **PURITY CHECK**: ZERO license display or edit fields.
- **QA Checklist**:
  - [ ] Verify license fields do not appear anywhere in the sheet.
  - [ ] Tapping "Suspend" immediately flags clinic as suspended and removes it from public patient discovery.
  - [ ] Tapping "Activate" restores clinic to active directory.
  - [ ] Tapping "Reset Password" successfully updates credentials without exposing plaintext tokens.
  - [ ] Editing clinic tier (e.g. from Basic to VIP) immediately updates its placement priority.

---

## 5. Automated QA Test Suite Verification

The Flutter automated test suite contains **157 comprehensive unit and widget tests** validating all architectural boundaries, UI widgets, and API integrations.

### Running the Suite:
```bash
# 1. Run static analysis (must report: No issues found!)
flutter analyze

# 2. Run the complete test suite (must report: All 157 tests passed!)
flutter test
```

### Key Test Suites & Coverage:
- `test/widget_test.dart`: App launch, brand logo, English LTR default, light/dark themes, and hero carousel fallback.
- `test/aesthetic_way_test.dart`: Lead request validation, removal of time slot chips, pure contact collection, and 5-tab bottom navigation (`MainNavScreen`).
- `test/products_articles_live_test.dart`: Products screen brand showcase validation (ensuring NO price tags, NO cart, and NO inquiry button on `ProductDetailScreen`).
- `test/referral_and_client_feedback_test.dart`: Unified referral invite link generation, copy to clipboard, and WhatsApp share copy.
- `test/offer_lead_and_dropdown_safety_test.dart`: Safe practitioner dropdown rendering without duplicates or assertion errors.
- `test/patient_profile_live_test.dart`: Profile loading, LTR phone/email fields, and live PATCH requests.
- `test/production_refinements_test.dart`: Product inquiry safety and lead type classification.
- `test/snackbar_contrast_test.dart`: Unified high-contrast `AppSnackBar` visibility in luxury dark theme.
