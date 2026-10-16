# AESTHETIC WAY — Flutter Architecture (`lib/`)

## 1. High-Level Directory Layout

```text
lib/
├── main.dart                          # App entrypoint, LocaleService & ThemeService init, role-based startup routing
├── core/
│   ├── auth/
│   │   ├── guest_auth_guard.dart      # AuthState singleton (ChangeNotifier), UserRole enum, session & favorite clinic state
│   │   └── token_storage.dart         # FlutterSecureStorage wrapper for JWT access/refresh tokens & cached user profile
│   ├── localization/
│   │   └── app_locale.dart            # LocaleService (default: English LTR; Arabic RTL supported; persisted via aw_pref_locale)
│   ├── network/
│   │   ├── api_config.dart            # Production base URL (https://aestheticway.ae/api/v1/) & relative endpoint path constants
│   │   ├── api_client.dart            # Dio singleton with Bearer token injection & 401 token refresh interceptor
│   │   └── api_exception.dart         # Standardized DRF error envelope & field-error parser
│   ├── services/
│   │   └── support_service.dart       # Fetches live customer support phone/WhatsApp/hours from /api/v1/app/support-info/
│   ├── theme/
│   │   ├── app_colors.dart            # Dark Navy (#0A0E17 / #070C1A), Soft Light Luxury (#F7F8FA), and Platinum Silver tokens
│   │   ├── app_theme.dart             # Material 3 ThemeData for Light (default) and Dark modes
│   │   ├── app_typography.dart        # Bilingual typography scale
│   │   └── theme_service.dart         # ThemeService (default: ThemeMode.light; persisted via aw_pref_theme_mode)
│   ├── utils/
│   │   ├── contact_launcher.dart      # Launches tel:, https://wa.me/, and Google Maps URLs via url_launcher
│   │   └── ltr_input_formatter.dart   # Formatter helpers for phone/email/code fields
│   └── widgets/
│       ├── app_brand_logo.dart        # Official assets/images/aesthetic_way_logo.png renderer (header, splash, hero)
│       ├── app_snackbar.dart          # High-contrast snackbar notifications
│       ├── license_badge.dart         # Verified practitioner badge (compliant — no regulator acronyms)
│       ├── ltr_text_field.dart        # LtrTextFormField enforcing LTR directionality inside RTL layouts
│       ├── luxury_image.dart          # Cached/network image loader with branded fallback placeholder
│       ├── practitioner_badge.dart    # Doctor / Licensed Nurse / Licensed Specialist role badge
│       └── tier_badge.dart            # VIP Platinum & Featured sponsor badges
├── data/
│   └── mock_data.dart                 # Isolated mock dataset used ONLY when enableMockMode() is called in unit/widget tests
└── features/
    ├── auth/                          # Login, Register, OTP Verification, Forgot/Reset Password, AuthRepository
    ├── onboarding/                    # 3-slide bilingual luxury onboarding flow
    ├── splash/                        # Full-screen #070C1A navy splash with 300×300 centered brand emblem
    ├── navigation/                    # Patient bottom navigation bar (Home, Clinics, Offers, My Requests, Profile)
    ├── home/                          # HomeScreen, HomeHeader (no heart icon), FeaturedAdsCarousel (image + 15s muted video)
    ├── clinics/                       # ClinicsRepository, ClinicModel, ClinicsDirectoryScreen, ClinicProfileScreen
    ├── practitioners/                 # PractitionersRepository, PractitionerModel, PractitionerProfileScreen
    ├── treatments/                    # TreatmentsRepository, TreatmentModel, CategoryModel, TreatmentsScreen
    ├── offers/                        # OffersRepository, OfferModel, OffersScreen
    ├── products/                      # ProductsRepository, ProductModel, ProductsScreen, ProductDetailScreen (inquiry-only)
    ├── articles/                      # ArticlesRepository, ArticleModel, ArticlesScreen, ArticleDetailScreen
    ├── appointment_lead/              # LeadsRepository, AppointmentRequestModel, AppointmentRequestScreen, MyRequestsScreen
    ├── referral/                      # ReferralRepository, ReferralService, ReferralScreen (code, milestones, 15% discount codes)
    ├── profile/                       # ProfileScreen (GET/PATCH /auth/me/, Language & Theme toggles, Customer Support sheet)
    ├── clinic_portal/                 # ClinicMainNavScreen, ClinicPortalService/Repository, Leads management, Catalog CRUD, Code Verify/Redeem
    └── admin/                         # AdminMainNavScreen, AdminPortalService/Repository, Dashboard, Clinics, Read-Only Leads, Moderation
```

---

## 2. Networking & Repository Mapping (`/api/v1/...`)

### `ApiConfig` & `ApiClient`
- [`ApiConfig`](file:///c:/Users/MVJD/Desktop/UAE_project/AestheticWay/lib/core/network/api_config.dart) resolves `baseUrl` in priority order:
  1. Runtime override via `ApiConfig.setBaseUrl(url)`
  2. Compile-time `--dart-define=API_BASE_URL=...`
  3. Default production endpoint: `https://aestheticway.ae/api/v1/`
- All endpoint constants in `ApiConfig` are **relative paths without a leading slash and with a trailing slash** (e.g., `'auth/login/'`, `'home/feed/'`, `'leads/'`), ensuring Dio resolves them cleanly against `baseUrl`.
- [`ApiClient`](file:///c:/Users/MVJD/Desktop/UAE_project/AestheticWay/lib/core/network/api_client.dart) attaches `Authorization: Bearer <accessToken>` from `TokenStorage` and automatically attempts a token refresh via `POST auth/refresh/` on HTTP `401` responses before clearing session state if refresh fails.

### Repository-to-Endpoint Mapping
| Feature / Repository | File | Primary `/api/v1/` Endpoints Called |
| :--- | :--- | :--- |
| `AuthRepository` | `lib/features/auth/data/auth_repository.dart` | `auth/register/`, `auth/login/`, `auth/verify-otp/`, `auth/resend-otp/`, `auth/forgot-password/`, `auth/reset-password/`, `auth/refresh/`, `auth/logout/`, `auth/me/` (`GET` & `PATCH`) |
| `SupportService` | `lib/core/services/support_service.dart` | `app/support-info/` |
| `HomeRepository` | `lib/features/home/data/home_repository.dart` | `home/feed/` |
| `ClinicsRepository` | `lib/features/clinics/data/clinics_repository.dart` | `clinics/`, `clinics/{id}/` |
| `PractitionersRepository` | `lib/features/practitioners/data/practitioners_repository.dart` | `practitioners/`, `practitioners/{id}/` |
| `TreatmentsRepository` | `lib/features/treatments/data/treatments_repository.dart` | `treatments/`, `treatments/{id}/`, `categories/` |
| `OffersRepository` | `lib/features/offers/data/offers_repository.dart` | `offers/`, `offers/{id}/` |
| `ProductsRepository` | `lib/features/products/data/products_repository.dart` | `products/`, `products/{id}/` |
| `ArticlesRepository` | `lib/features/articles/data/articles_repository.dart` | `articles/`, `articles/{id}/` |
| `LeadsRepository` | `lib/features/appointment_lead/data/leads_repository.dart` | `leads/` (`POST`), `leads/my/`, `leads/my/count/`, `leads/{id}/` |
| `ReferralRepository` | `lib/features/referral/data/referral_repository.dart` | `referral/my-status/`, `referral/collect-code/` (`POST`) |
| `ClinicPortalRepository` | `lib/features/clinic_portal/data/clinic_portal_repository.dart` | `clinic-portal/dashboard/`, `clinic-portal/profile/` (`GET`/`PATCH`), `clinic-portal/leads/`, `clinic-portal/leads/{id}/`, `clinic-portal/leads/{id}/notes/`, `clinic-portal/practitioners/`, `clinic-portal/treatments/`, `clinic-portal/offers/`, `clinic-portal/products/`, `clinic-portal/articles/`, `clinic-portal/discount-codes/verify/`, `clinic-portal/discount-codes/redeem/` |
| `AdminPortalRepository` | `lib/features/admin/data/admin_portal_repository.dart` | `admin/dashboard/`, `admin/analytics/`, `admin/clinics/`, `admin/clinics/{id}/{suspend\|activate\|verify}/`, `admin/leads/` (read-only), `admin/offers/{id}/{approve\|reject\|suspend\|restore}/`, `admin/products/{id}/{approve\|reject\|suspend\|restore}/`, `admin/articles/{id}/{approve\|reject\|suspend\|restore}/` |

---

## 3. Theme & Locale Services (Defaults: English + Light)

### `LocaleService` (`lib/core/localization/app_locale.dart`)
- **First-Launch Default**: `AppLanguage.english` (`Locale('en', 'US')`, `TextDirection.ltr`).
- **Persistence**: Uses `FlutterSecureStorage` key `'aw_pref_locale'` (`'en'` | `'ar'`).
- **Startup Initialization**: `await LocaleService().init()` runs in `main()` prior to `runApp(...)`. If `'aw_pref_locale'` has never been set on the device, `LocaleService` remains in English (`LTR`). When the user switches language in `ProfileScreen`, `setLanguage(...)` / `toggleLanguage()` updates the UI immediately via `ChangeNotifier` and writes the selection to `'aw_pref_locale'`.

### `ThemeService` (`lib/core/theme/theme_service.dart`)
- **First-Launch Default**: `ThemeMode.light` (`Soft Light Luxury` palette defined in `AppTheme.lightTheme`).
- **Persistence**: Uses `FlutterSecureStorage` key `'aw_pref_theme_mode'` (`'light'` | `'dark'` | `'system'`).
- **Startup Initialization**: `await ThemeService().init()` runs in `main()` prior to `runApp(...)`. If `'aw_pref_theme_mode'` is unset, `ThemeService` defaults to `ThemeMode.light`. Users can toggle Dark Mode (`AppTheme.darkTheme`) from `ProfileScreen`, which persists across app restarts.

---

## 4. Mandatory Authentication Architecture (Guest Mode Deprecated)

### Client Directive & Architectural Boundary
In compliance with the client mandate, **Guest Mode is completely deprecated and removed**. Unauthenticated browsing is prohibited across all screens. Every user must authenticate (Login or Register) before accessing the application shell.

### Wall Enforcement & Startup Routing
1. **App Boot (`main.dart` & `SplashScreen`)**:
   - `main()` initializes `TokenStorage` and restores cached credentials via `AuthState().restoreSession()`.
   - `SplashScreen` inspects `AuthState().isLoggedIn`:
     - If authenticated: routes immediately to the role-specific portal (`patient` -> `MainNavScreen`, `clinic_admin`/`staff` -> `ClinicMainNavScreen`, `super_admin` -> `AdminMainNavScreen`).
     - If unauthenticated: first-time users view `OnboardingScreen` (3 slides, no skip button) which finishes into `LoginScreen`. Subsequent launches route directly to `LoginScreen`.
2. **Zero Guest Bypass**:
   - `OnboardingScreen`: "Skip" button removed; users complete the introduction slides and tap "Start Now" to enter `LoginScreen`.
   - `LoginScreen`: Close button (`close_rounded`) removed; users cannot dismiss or pop back into an unauthenticated state.
   - `RegisterScreen`: Links cleanly back to `LoginScreen` or proceeds to `OtpScreen`.
3. **Fail-Safe Session Eviction**:
   - `GuestAuthGuard.requireAuth` immediately returns `true` when a valid session exists.
   - If an access token expires and refresh fails (`401` in `auth_interceptor.dart`), `TokenStorage` and `AuthState` are cleared, and navigation is redirected to `LoginScreen` via `pushAndRemoveUntil(..., (route) => false)`.

