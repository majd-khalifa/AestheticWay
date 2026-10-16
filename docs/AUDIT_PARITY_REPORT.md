# AESTHETIC WAY — Backend API vs. Flutter Integration Parity Audit Report

- **Production Base URL:** `https://aestheticway.ae/api/v1/`
- **Swagger / OpenAPI Documentation:** `https://aestheticway.ae/api/docs/`
- **Audit Scope:** Full cross-reference of the live Django REST Framework (`/api/v1/`) backend contract against all Flutter data repositories (`lib/features/*/data/`) and presentation screens (`lib/features/*/presentation/`).

---

## 1. Executive Summary

| Audit Dimension | Status | Notes |
| :--- | :--- | :--- |
| **Core Patient Discovery & Lead Flow** | **100% Linked** | Home (`GET /home/`), Clinics, Practitioners, Treatments, Offers, Products, Articles, and Lead Submission (`POST /leads/`) are live. |
| **Role-Based Authentication & JWT** | **100% Linked** | Register, Login, OTP Verify/Resend, Forgot/Reset Password, Token Refresh, Logout, and `/auth/me/` (`GET`/`PATCH`). |
| **Clinic Partner Portal (`/clinics/portal/*`)** | **100% Linked** | Clinic Profile, Leads Inbox, Practitioners CRUD, Treatments CRUD, Offers CRUD, Products CRUD, Articles CRUD, and Referral Discount Verify/Redeem. |
| **Super Admin Portal (`/admin/*`)** | **100% Linked** | Dashboard Metrics, Clinics Status (`suspend`/`activate`), Read-Only Leads, and Moderation (`approve`/`reject`) for Offers, Products, and Articles. |
| **Product Boundary Compliance** | **100% Compliant** | Zero payments, zero cart/checkout, zero booking calendar slots, zero home services, and zero medical license numbers (`DHA`/`DOH`/`MOHAP`) in UI. |

---

## 2. Active & Linked Endpoints (`Django DRF` ↔ `Flutter`)

### 2.1 Authentication & User Profile (`/api/v1/auth/*`)

| Method | Endpoint | Auth | Flutter Repository & Method | Flutter Screen(s) |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/register/` | Public | `AuthRepository.register()` | `RegisterScreen` |
| `POST` | `/api/v1/auth/login/` | Public | `AuthRepository.login()` | `LoginScreen` |
| `POST` | `/api/v1/auth/otp/verify/` | Public | `AuthRepository.verifyOtp()` | `OtpScreen` |
| `POST` | `/api/v1/auth/otp/resend/` | Public | `AuthRepository.resendOtp()` | `OtpScreen` |
| `POST` | `/api/v1/auth/password/forgot/` | Public | `AuthRepository.forgotPassword()` | `ForgotPasswordScreen` |
| `POST` | `/api/v1/auth/password/reset/` | Public | `AuthRepository.resetPassword()` | `OtpScreen` |
| `POST` | `/api/v1/auth/token/refresh/` | Public | `ApiClient._tryRefreshToken()` | Automatic 401 Interceptor |
| `POST` | `/api/v1/auth/logout/` | Bearer JWT | `AuthRepository.logout()` | `ProfileScreen`, `ClinicSettingsScreen`, `AdminSettingsScreen` |
| `GET` | `/api/v1/auth/me/` | Bearer JWT | `AuthRepository.getMe()` | `SplashScreen`, `ProfileScreen`, `ClinicSettingsScreen`, `AdminSettingsScreen` |
| `PATCH` | `/api/v1/auth/me/` | Bearer JWT | `AuthRepository.updateProfile()` | `ProfileScreen` (`full_name`) |

### 2.2 Public Discovery & Catalog (`/api/v1/*`)

| Method | Endpoint | Auth | Flutter Repository & Method | Flutter Screen(s) |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/home/` | Public | `HomeRepository.getHomeData()` | `HomeScreen` (`FeaturedAdsCarousel`, VIP/Featured Clinics, Offers, Articles) |
| `GET` | `/api/v1/clinics/` | Public | `ClinicsRepository.getClinics()` | `ClinicsListScreen`, `HomeScreen`, `TreatmentDetailScreen` |
| `GET` | `/api/v1/clinics/{id}/` | Public | `ClinicsRepository.getClinicDetail(id)` | `ClinicProfileScreen`, `PractitionerProfileScreen`, `ProductDetailScreen` |
| `GET` | `/api/v1/practitioners/` | Public | `PractitionersRepository.getPractitioners()` | `PractitionersScreen`, `ClinicProfileScreen` (`_StaffTab` fallback) |
| `GET` | `/api/v1/practitioners/{id}/` | Public | `PractitionersRepository.getPractitionerDetail(id)` | `PractitionerProfileScreen` (Live fetch on navigation from `ClinicProfileScreen`) |
| `GET` | `/api/v1/treatments/` | Public | `TreatmentsRepository.getTreatments()` | `TreatmentsScreen`, `ClinicProfileScreen` (`_TreatmentsTab` fallback) |
| `GET` | `/api/v1/treatments/categories/` | Public | `TreatmentsRepository.getCategories()` | `TreatmentsScreen` |
| `GET` | `/api/v1/treatments/{id}/` | Public | `TreatmentsRepository.getTreatmentDetail(id)` | `TreatmentDetailScreen` |
| `GET` | `/api/v1/offers/` | Public | `OffersRepository.getOffers()` | `OffersScreen`, `ClinicProfileScreen` (`_OffersTab`) |
| `GET` | `/api/v1/offers/{id}/` | Public | `OffersRepository.getOfferDetail(id)` | `OffersScreen` |
| `GET` | `/api/v1/products/` | Public | `ProductsRepository.getProducts()` | `ProductsScreen`, `ClinicProfileScreen` (`_ProductsTab`) |
| `GET` | `/api/v1/products/{id}/` | Public | `ProductsRepository.getProductDetail(id)` | `ProductDetailScreen` |
| `GET` | `/api/v1/articles/` | Public | `ArticlesRepository.getArticles()` | `ArticlesScreen`, `HomeScreen` |
| `GET` | `/api/v1/articles/{id}/` | Public | `ArticlesRepository.getArticleDetail(id)` | `ArticleDetailScreen` |

### 2.3 Patient Leads, Reviews & Referrals (`/api/v1/*`)

| Method | Endpoint | Auth | Flutter Repository & Method | Flutter Screen(s) |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/leads/` | Bearer JWT | `LeadsRepository.submitLead()` | `AppointmentRequestScreen` |
| `GET` | `/api/v1/leads/my/` | Bearer JWT | `LeadsRepository.getMyLeads()` | `MyRequestsScreen` |
| `GET` | `/api/v1/clinics/{id}/reviews/` | Public | `ReviewsRepository.getClinicReviews()` | `ClinicProfileScreen` (`_ReviewsTab`) |
| `POST` | `/api/v1/clinics/{id}/reviews/submit/` | Bearer JWT | `ReviewsRepository.submitReview()` | `ClinicProfileScreen` (`_ReviewsTab`) |
| `GET` | `/api/v1/referral/summary/` | Bearer JWT | `ReferralRepository.getSummary()` | `ReferralScreen` |
| `POST` | `/api/v1/referral/register-invite/` | Bearer JWT | `ReferralRepository.registerInvite()` | `RegisterScreen`, `ReferralScreen` |

### 2.4 Clinic Partner Portal (`/api/v1/clinics/portal/*`)

| Method | Endpoint | Auth | Flutter Repository & Method | Flutter Screen(s) |
| :--- | :--- | :--- | :--- | :--- |
| `GET` / `PATCH` | `/api/v1/clinics/portal/profile/` | Clinic JWT | `ClinicPortalRepository.getClinicProfile()` / `updateClinicProfile()` | `ClinicSettingsScreen` |
| `GET` / `PATCH` | `/api/v1/clinics/portal/leads/` (`/{id}/`) | Clinic JWT | `ClinicPortalRepository.getPortalLeads()` / `updateLeadStatus()` | `ClinicLeadsInboxScreen` |
| `GET` / `POST` / `PATCH` / `DELETE` | `/api/v1/clinics/portal/practitioners/` (`/{id}/`) | Clinic JWT | `ClinicPortalRepository.*Practitioner()` | `ClinicCatalogManageScreen` |
| `GET` / `POST` / `PATCH` / `DELETE` | `/api/v1/clinics/portal/treatments/` (`/{id}/`) | Clinic JWT | `ClinicPortalRepository.*Treatment()` | `ClinicCatalogManageScreen` |
| `GET` / `POST` / `PATCH` / `DELETE` | `/api/v1/clinics/portal/offers/` (`/{id}/`) | Clinic JWT | `ClinicPortalRepository.*Offer()` | `ClinicCatalogManageScreen` |
| `GET` / `POST` / `PATCH` / `DELETE` | `/api/v1/clinics/portal/products/` (`/{id}/`) | Clinic JWT | `ClinicPortalRepository.*Product()` | `ClinicCatalogManageScreen` |
| `GET` / `POST` / `PATCH` / `DELETE` | `/api/v1/clinics/portal/articles/` (`/{id}/`) | Clinic JWT | `ClinicPortalRepository.*Article()` | `ClinicCatalogManageScreen` |
| `POST` | `/api/v1/referral/verify-code/` | Clinic JWT | `ReferralRepository.verifyCode()` | `ClinicDiscountVerifyScreen` |
| `POST` | `/api/v1/referral/redeem-code/` | Clinic JWT | `ReferralRepository.redeemCode()` | `ClinicDiscountVerifyScreen` |

### 2.5 Super Admin Portal (`/api/v1/admin/*`)

| Method | Endpoint | Auth | Flutter Repository & Method | Flutter Screen(s) |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/admin/dashboard/` | Super Admin | `AdminRepository.getDashboardMetrics()` | `AdminDashboardScreen` |
| `GET` / `PATCH` | `/api/v1/admin/clinics/` (`/{id}/`) | Super Admin | `AdminRepository.getClinics()` / `updateClinicStatus()` | `AdminClinicsScreen` |
| `GET` | `/api/v1/admin/leads/` | Super Admin | `AdminRepository.getLeads()` | `AdminLeadsScreen` (Read-Only) |
| `GET` / `PATCH` | `/api/v1/admin/offers/` (`/{id}/`) | Super Admin | `AdminRepository.getOffers()` / `moderateOffer()` | `AdminContentModerationScreen` |
| `GET` / `PATCH` | `/api/v1/admin/products/` (`/{id}/`) | Super Admin | `AdminRepository.getProducts()` / `moderateProduct()` | `AdminContentModerationScreen` |
| `GET` | `/api/v1/articles/?moderation_status=pending` | Super Admin | `AdminRepository.getArticles()` | `AdminContentModerationScreen` |
| `PATCH` | `/api/v1/articles/{id}/moderation/` | Super Admin | `AdminRepository.moderateArticle()` | `AdminContentModerationScreen` |

---

## 3. Backend Endpoints / Fields Not Consumed by Flutter UI

| Endpoint / Field | Backend Behavior | Current Flutter Disposition | Recommendation |
| :--- | :--- | :--- | :--- |
| `GET /api/v1/auth/otp/debug/` | Returns recent OTP codes in staging/dev when `OTP_DEBUG_ENDPOINT_ENABLED=True`. | Intentionally **not** called in production Flutter app. | Keep excluded from production mobile builds for security. |
| `DELETE /api/v1/clinics/portal/leads/{id}/` | Allows deleting a lead record in DRF `ModelViewSet`. | Clinic Portal only allows status updates (`new`, `contacted`, `closed`). | Keep excluded so clinics cannot delete patient lead audit history. |
| `license_authority` & `license_number` on `Clinic` / `Practitioner` | Returned in JSON payloads by `/api/v1/clinics/` and `/api/v1/practitioners/`. | Parsed in models for internal compatibility, **strictly hidden** from all Patient & Clinic UI per client rule. | Maintain strict UI suppression (`DHA`/`DOH`/`MOHAP` and license numbers must never render in UI). |
| `ClinicBranch` (`branches` array on `ClinicDetailSerializer`) | Returns secondary clinic branch locations and coordinates. | Parsed into `ClinicModel.branches`; primary clinic coordinates and Google Maps deep-linking are rendered in `_BranchesTab`. | Fully supported when clinics add multiple branches. |

---

## 4. Media & Image Fields Audit (Null / Empty Seed Data & UI Fallbacks)

In production (`https://aestheticway.ae/api/v1/`), several initial database seed records have `null` or `""` (empty string) for their `ImageField` / `URLField` attributes until uploaded via Django Admin or the Clinic Portal.

| Model / Feature | Backend JSON Field(s) | Production Seed Status | Flutter Fallback & Handling |
| :--- | :--- | :--- | :--- |
| **Clinic (`ClinicModel`)** | `cover_image`, `logo`, `gallery` | Partially populated; some seed clinics return `""` or `null` for `cover_image` / `logo`. | Handled via `LuxuryImage` (`placeholderIcon: Icons.apartment_rounded`) with luxury dark-navy/champagne vector placeholder and relative-path resolution (`https://aestheticway.ae/media/...`). |
| **VIP Featured Ads (`FeaturedAdsCarousel`)** | `cover_image`, `video_url`, `media_type` | `video_url` is optional (`null` or `""` when a VIP clinic only has a static banner or placeholder). | `FeaturedAdSlideMedia` checks `clinic.hasVideoAd`; if `video_url` is absent or fails to load, it seamlessly falls back to `LuxuryImage` without crashing or showing blank frames. |
| **Practitioner (`PractitionerModel`)** | `avatar` | Many seeded practitioners have `avatar: ""` or `null`. | `LuxuryImage` renders a refined medical portrait placeholder (`Icons.person_rounded`) inside `PractitionerProfileScreen` and `_StaffTab`. |
| **Treatment (`TreatmentModel`)** | `image` | Often `""` or `null` in seeded catalog entries. | `LuxuryImage` renders `Icons.medical_services_rounded` / `Icons.auto_Fix_high_rounded` placeholder. |
| **Offer (`OfferModel`)** | `image` | Optional on clinic promotional offers. | `OffersScreen` and `_OffersTab` render luxury champagne discount badges and typography cards without requiring a bitmap image. |
| **Product (`ProductModel`)** | `image` | Some skincare products have `image: ""`. | `LuxuryImage` renders `Icons.shopping_bag_outlined` luxury placeholder on both `ProductsScreen` and `ProductDetailScreen`. |
| **Article (`ArticleModel`)** | `featured_image` | Optional on medical educational articles. | `LuxuryImage` renders `Icons.article_outlined` placeholder when `featured_image` is empty. |
