# AESTHETIC WAY — Current Production & Project Status

*Last Updated: September 2026*

---

## 1. Completed & Verified (`DONE`)

### Mobile App (`AestheticWay` Flutter)
- **Production Base URL Wired**: `ApiConfig.defaultProductionBaseUrl` points directly to `https://aestheticway.ae/api/v1/` with zero hardcoded LAN/localhost IPs.
- **Client UI Requirements Completed**:
  - **Default Language = English (`en`, LTR)** on first launch when unset (`LocaleService`), persisted via `FlutterSecureStorage` (`aw_pref_locale`). Arabic (`ar`, RTL) supported and switchable in Profile.
  - **Default Theme = Light (`Soft Light Luxury`)** on first launch when unset (`ThemeService`), persisted via `FlutterSecureStorage` (`aw_pref_theme_mode`). Dark Mode (`Luxury Dark Navy`) supported via toggle.
  - **Home Header Heart Removed**: Top-corner favorites heart icon removed from `HomeHeader` and `HomeScreen` (`ClinicProfileScreen` favorite toggle preserved).
  - **Splash & Brand Logo Prominence**: `SplashScreen` renders `300×300` official `assets/images/aesthetic_way_logo.png` on `#070C1A` navy canvas; `AppBrandLogo.header` renders `46×104` proportionally framed logo with high contrast in both Light and Dark themes.
  - **Android & iOS App Launcher Icons**: Regenerated via `flutter_launcher_icons` from `assets/images/aesthetic_way_logo.png` with edge-to-edge emblem framing on `#070C1A`.
  - **VIP / Featured Carousel Video Readiness**: `FeaturedAdsCarousel` (`FeaturedAdSlideMedia`) supports 15-second muted looping video (`video_url` + `media_type: "video"`) with automatic fallback to `LuxuryImage`.
  - **Mandatory Authentication Wall (Guest Mode Deprecated)**: In compliance with client directives, guest browsing is completely eliminated. App startup strictly checks session state and enforces mandatory Login/Registration before accessing the app shell. All "Continue as Guest", "Skip", and dismiss buttons have been decommissioned.
- **Role-Based Portals Fully Integrated with Live API**:
  - **Patient App**: Home feed, Clinics directory & profile, Google Maps & WhatsApp/Call actions, Practitioners, Treatments & Categories, Offers, Products (inquiry-only), Articles, Lead submission (`POST /api/v1/leads/`) with exact Arabic confirmation `"تم إرسال طلبك وستتواصل العيادة معك"`, My Requests (`GET /api/v1/leads/my/`), Referral & Rewards (`GET /api/v1/referral/my-status/`, `POST /api/v1/referral/collect-code/`), and Live Profile (`GET`/`PATCH /api/v1/auth/me/`).
  - **Clinic Portal**: Dashboard KPIs, Lead status workflow & internal notes, Clinic Profile `GET`/`PATCH`, Catalog CRUD (practitioners, treatments, offers, products, articles), and 15% Discount Code verify/redeem.
  - **Super Admin Portal**: Truth metrics dashboard, Analytics, Clinic activate/suspend/verify, Read-Only Lead supervision, and Offer/Product/Article moderation.
  - **Backend Enhancements Parity (Ali's Deployment)**:
    - **Google Places Ratings**: `ClinicModel` seamlessly deserializes `google_rating` and `google_reviews_count` from both public and home feed endpoints.
    - **Clinic Leads Pagination**: `ClinicLeadsRepository.getLeads()` handles both paginated DRF envelopes (`{'results': [...], 'count': N}`) and unpaginated lists without `TypeError`.
    - **Live Badge Counters**: `ClinicBadgesAPIView` (`/api/v1/clinic-portal/badges/`) integrated via `ClinicBadgeCountsModel` and `ClinicPortalService`, displaying instant unread lead badges on the bottom nav and dashboard.
    - **FCM Device Push Token Management**: `DeviceTokenService` registered to `/api/v1/notifications/devices/` with auto platform resolution (`ios`/`android`/`web`) and automatic deactivation on logout.
    - **OTP-based Phone & Email Change**: `AuthRepository` wired to `/api/v1/auth/me/phone/change/request/`, `/confirm/`, `/api/v1/auth/me/email/change/request/`, and `/confirm/`.
- **Automated Quality Gates**:
  - `flutter analyze`: **0 issues**
  - `flutter test`: **148 / 148 tests passing**

---

## 2. Blocked / External Infrastructure Wait (`BLOCKED`)

### Transactional OTP Email Delivery (~72h Propagation Window)
- **Symptom**: Registering a brand-new patient (`POST /api/v1/auth/register/`), requesting OTP resend (`POST /api/v1/auth/resend-otp/`), or triggering Forgot Password (`POST /api/v1/auth/forgot-password/`) relies on production SMTP/DNS email delivery at `aestheticway.ae`, which is currently experiencing an ~72-hour propagation/provider activation delay.
- **Workaround for QA & Demo**:
  - Use pre-verified seeded accounts (`is_verified = True` in `seed_data.py`), which log in immediately via `POST /api/v1/auth/login/` without requiring an OTP email:
    - **Patient**: `patient1@aestheticway.ae` (or `+971501111111`) / `StagingPassword123!`
    - **Clinic Admin (VIP)**: `admin.downtown@aestheticway.ae` (or `+971500000002`) / `StagingPassword123!`
    - **Super Admin**: `super_admin@aestheticway.ae` (or `+971500000001`) / `StagingPassword123!`
  - Alternatively, a Super Admin can mark a newly registered user as `is_verified = True` in Django Admin (`https://aestheticway.ae/django-admin/`).

---

## 3. Known Production Data Behavior (Seed Catalog)
The production database at `https://aestheticway.ae` is currently populated with the staging/production seed dataset (`apps/clinics/management/commands/seed_data.py`):
1. **Aesthetic Way Clinic Downtown** (`عيادة إستيتك واي داون تاون`)
   - **City**: Dubai (`Downtown Dubai`)
   - **Tier**: `VIP` (`SubscriptionTier.vipPlatinum` — appears first in Home top carousel)
2. **Luxe Dermatology Jumeirah** (`لوكس للجلدية والتجميل جميرا`)
   - **City**: Dubai (`Jumeirah 1`)
   - **Tier**: `Featured` (`SubscriptionTier.featured` — appears second in Home top carousel)
3. **Capital Aesthetics Corniche** (`كابيتال للتجميل الكورنيش`)
   - **City**: Abu Dhabi (`Al Bateen / Corniche`)
   - **Tier**: `Basic` (`SubscriptionTier.basic` — appears in normal clinic listings, excluded from VIP/Featured top carousel)

---

## 4. Open Backend Follow-Ups
1. **SMTP / Transactional OTP Email Delivery**: Complete DNS (`SPF`/`DKIM`/`DMARC`) and SMTP relay verification on `aestheticway.ae` so live OTP emails arrive within seconds for new patient signups and password resets.
2. **Phone & Email Change OTP Flow (Future Phase)**: Currently `PATCH /api/v1/auth/me/` updates `full_name`, while `phone` and `email` are kept read-only in Flutter (`ProfileScreen`) until a dedicated two-step OTP verification endpoint for changing contact identifiers is enabled on the backend.
3. **Production VIP Video Ad Assets**: When clinics upload 15-second promo videos in Django Admin / Clinic Portal (`media_type: "video"`, `video_url: "https://.../ad.mp4"`), the Flutter `FeaturedAdsCarousel` will play them muted and looped automatically without requiring an app update.
