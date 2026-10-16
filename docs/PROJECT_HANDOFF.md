# AESTHETIC WAY — Project Handoff

## 1. Product Overview
- **Product Name**: AESTHETIC WAY
- **Target Market**: UAE (Dubai & Abu Dhabi primary focus)
- **Domain**: Luxury medical aesthetic & dermatology clinic discovery + lead generation
- **What This Product Is NOT (Strict Boundaries)**:
  - **NOT a booking calendar**: No real-time slot picker, schedule availability grid, or final appointment confirmation inside the app.
  - **NOT a payment or checkout platform**: No in-app patient payments, Apple Pay/Google Pay, credit card forms, or financial transactions.
  - **NOT an e-commerce store**: Products displayed by clinics are strictly **inquiry-only** (no shopping cart, no quantity selector, no "Buy Now").
  - **No home services** and **no non-medical beauty salons**.

---

## 2. Platforms & Role-Based Portals
All three portals live inside the **same Flutter application** (`AestheticWay`) and route automatically based on the authenticated user's JWT role (`UserRole`):
1. **Patient App** (`role: patient`):
   - Discover VIP/Featured clinics, licensed doctors/nurses/specialists, treatments, promotional offers, skincare products (inquiry-only), and medical articles.
   - Open clinic locations in Google Maps and initiate direct phone calls or WhatsApp chats.
   - Submit **Appointment Requests (Leads)** and track status in **My Requests**.
   - **Referral & Rewards**: Share personal referral code (`AW-...`), earn points on verified invites, and collect 15% discount codes at 500 points (3-month code validity; points never expire).
2. **Clinic Portal** (`role: clinic_admin` | `clinic_staff` | `clinic`):
   - View clinic KPI dashboard (`clinic-portal/dashboard/`) and manage incoming patient leads (`new` → `contacted` → `booked` / `closed_not_booked`) plus internal notes.
   - Manage clinic profile (`clinic-portal/profile/`) and full catalog CRUD (practitioners, treatments, offers, products, articles).
   - Verify and redeem patient 15% referral discount codes (`clinic-portal/discount-codes/verify/` & `redeem/`).
3. **Super Admin Portal** (`role: super_admin`):
   - Platform-wide truth metrics (`admin/dashboard/` & `admin/analytics/`).
   - Clinic lifecycle governance (`activate`, `suspend`, `verify`).
   - **Read-only lead supervision** (`admin/leads/` — Super Admin cannot mutate clinic lead statuses).
   - Content moderation (`approve`, `reject`, `suspend`, `restore` for offers, products, and articles).

---

## 3. Technology Stack & Production Environment
- **Mobile Frontend**: Flutter (Dart SDK `^3.11.1`), `dio` HTTP client with JWT Bearer + automatic token refresh interceptor, `flutter_secure_storage` for tokens and user preferences, `video_player` for 15s muted VIP video ads.
- **Backend**: Django + Django REST Framework (SimpleJWT, PostgreSQL, Swagger/OpenAPI).
- **Production Base URL**: `https://aestheticway.ae/api/v1/`
- **Production API Docs (Swagger)**: `https://aestheticway.ae/api/docs/`
- **Production Django Admin**: `https://aestheticway.ae/django-admin/`
- **Flutter Build / Run Configuration**:
  - `ApiConfig.defaultProductionBaseUrl` defaults to `https://aestheticway.ae/api/v1/`.
  - Can also be explicitly passed via `--dart-define=API_BASE_URL=https://aestheticway.ae/api/v1/` or overridden at runtime via `ApiConfig.setBaseUrl(...)`.

---

## 4. Hard Product & Compliance Rules
1. **No In-App Payments / Cart / Booking Calendar**: Every CTA that connects a patient to a clinic creates a **Lead** (`POST /api/v1/leads/`) or opens direct phone/WhatsApp/Google Maps.
2. **Mandatory Arabic Lead Success Wording**:
   - Exact Arabic confirmation string required by client & product spec:
     ```text
     تم إرسال طلبك وستتواصل العيادة معك
     ```
3. **No Regulator Names or License Numbers in Patient/Clinic UI**:
   - Do **not** display raw license numbers or regulator acronyms (`DHA`, `DOH`, `MOHAP`) in patient-facing or clinic-portal UI copy.
4. **Profile Contact Fields Read-Only Until Backend OTP Change Flow**:
   - On `ProfileScreen` (`GET`/`PATCH /api/v1/auth/me/`), `full_name` is editable, while `phone` and `email` are rendered **read-only** inside `LtrTextFormField` widgets until a dedicated backend OTP verification flow for changing phone/email is added.

---

## 5. Seeded Roles & Test Accounts (`seed_data.py`)
When the backend is seeded via `python manage.py seed_data` (default staging/seed password: `StagingPassword123!`), the following verified accounts and clinics exist:

| Role | Full Name | Email | Phone | Assigned Clinic |
| :--- | :--- | :--- | :--- | :--- |
| `super_admin` | Super Admin | `super_admin@aestheticway.ae` | `+971500000001` | Platform Global |
| `clinic_admin` | Dr. Sarah Al-Nuaimi | `admin.downtown@aestheticway.ae` | `+971500000002` | Aesthetic Way Clinic Downtown (`VIP`) |
| `clinic_admin` | Khaled Al-Qasimi | `admin.capital@aestheticway.ae` | `+971500000003` | Capital Aesthetics Corniche (`Basic`) |
| `clinic_staff` | Nour Hisham | `staff.downtown@aestheticway.ae` | `+971500000004` | Aesthetic Way Clinic Downtown (`VIP`) |
| `patient` | Layla Mansoor | `patient1@aestheticway.ae` | `+971501111111` | Patient App |
| `patient` | Mariam Saleh | `patient2@aestheticway.ae` | `+971502222222` | Patient App |

---

## 6. Client UI Standards (Implemented in Flutter)
- **Default Language = English (`en`, LTR)**: First launch defaults to English (`AppLanguage.english`). Arabic (`ar`, RTL) remains selectable in Profile and persists in `FlutterSecureStorage` (`key: 'aw_pref_locale'`).
- **Default Theme = Light (`Soft Light Luxury`)**: First launch defaults to `ThemeMode.light`. Dark mode (`Luxury Dark Navy`) remains selectable via toggle and persists in `FlutterSecureStorage` (`key: 'aw_pref_theme_mode'`).
- **Prominent Splash & Header Brand Logo**: Uses official `assets/images/aesthetic_way_logo.png` (`300×300` on `SplashScreen` over `#070C1A` navy canvas; `46×104` in `AppBrandLogo.header` without aspect-ratio distortion).
- **Android & iOS Launcher Icons**: Generated from `assets/images/aesthetic_way_logo.png` via `flutter_launcher_icons` with full-bleed `#070C1A` background (`app_launcher_icon.png` and `app_launcher_foreground.png`).
- **No Heart / Favorites Icon on Home Header**: `HomeHeader` displays the brand logo and UAE city selector (`All UAE` / `Dubai` / `Abu Dhabi`) without a top-corner heart button; clinic favorite toggling remains on `ClinicProfileScreen`.
- **VIP / Featured Carousel Image + 15s Muted Video Support**: `FeaturedAdsCarousel` (`FeaturedAdSlideMedia`) supports both static cover images and muted 15-second looping video ads (`video_url` + `media_type: "video"`), falling back cleanly to `LuxuryImage` if `video_url` is absent or fails to load.

---

## 7. Current Production Status Summary
- **Production Backend**: Live at `https://aestheticway.ae` (`https://aestheticway.ae/api/v1/`).
- **Patient Login & Pre-Verified Accounts**: Working end-to-end against production.
- **Catalog Data**: Served live from production database (currently populated with the staging/production seed clinics and catalog items).
- **Known Infrastructure Blocker (OTP Email Delivery)**: Transactional OTP emails for new user signups / password resets are currently delayed (~72h DNS/SMTP propagation window on production mail provider). Pre-verified accounts (`is_verified=True`) log in immediately via `POST /api/v1/auth/login/`.
