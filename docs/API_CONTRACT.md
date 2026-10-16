# AESTHETIC WAY — API Contract (`/api/v1/`)

- **Production Base URL**: `https://aestheticway.ae/api/v1/`
- **Interactive OpenAPI / Swagger UI**: `https://aestheticway.ae/api/docs/`
- **Authentication**: Bearer JWT (`Authorization: Bearer <access_token>`) via SimpleJWT.

---

## 1. Authentication & User Profile (`auth/`)

| Method | Relative Path | Auth | Used By | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `auth/register/` | Public | `AuthRepository.register` | Register new patient account (`full_name`, `phone`, `email`, `password`, optional `referral_code`). Triggers OTP verification email. |
| `POST` | `auth/login/` | Public | `AuthRepository.login` | Authenticate via `identifier` (email or phone) + `password`. Returns `access`, `refresh`, and `user` object (including `role`). |
| `POST` | `auth/verify-otp/` | Public | `AuthRepository.verifyOtp` | Verify 6-digit OTP (`email`, `otp_code`, `purpose`). Returns JWT tokens upon activation. |
| `POST` | `auth/resend-otp/` | Public | `AuthRepository.resendOtp` | Resend OTP email (`email`, `purpose`). |
| `POST` | `auth/forgot-password/` | Public | `AuthRepository.forgotPassword` | Request password reset OTP (`email`). |
| `POST` | `auth/reset-password/` | Public | `AuthRepository.resetPassword` | Reset password using `email`, `otp_code`, and `new_password`. |
| `POST` | `auth/refresh/` | Public | `ApiClient` (Interceptor) | Exchange `refresh` token for a new `access` token on HTTP `401`. |
| `POST` | `auth/logout/` | Authenticated | `AuthRepository.logout` | Blacklist `refresh` token and clear local `TokenStorage`. |
| `GET` | `auth/me/` | Authenticated | `AuthRepository.getMe` | Fetch current authenticated user profile (`id`, `full_name`, `phone`, `email`, `role`, `is_verified`). |
| `PATCH` | `auth/me/` | Authenticated | `AuthRepository.updateMe` | Update editable user profile fields (`full_name`). |
| `POST` | `auth/me/phone/change/request/` | Authenticated | `AuthRepository.requestPhoneChange` | Request phone change OTP sent to `new_phone` (throttled 5/hr). |
| `POST` | `auth/me/phone/change/confirm/` | Authenticated | `AuthRepository.confirmPhoneChange` | Confirm phone change using `new_phone` and 6-digit `code`. |
| `POST` | `auth/me/email/change/request/` | Authenticated | `AuthRepository.requestEmailChange` | Request email change OTP sent to `new_email` (throttled 5/hr). |
| `POST` | `auth/me/email/change/confirm/` | Authenticated | `AuthRepository.confirmEmailChange` | Confirm email change using `new_email` and 6-digit `code`. |

---

## 2. App Config, Home Feed & Discovery Catalog

| Method | Relative Path | Auth | Used By | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `app/support-info/` | Public / Auth | `SupportService` | Customer support phone, WhatsApp, email, and working hours. |
| `GET` | `home/feed/` | Public / Auth | `HomeRepository.fetchHomeFeed` | Aggregated Home screen payload (`featured_ads`, `top_clinics`, `featured_offers`, `categories`, `featured_products`, `latest_articles`). Optional `?city=` filter. |
| `GET` | `clinics/` | Public / Auth | `ClinicsRepository.getClinics` | Paginated list of active clinics (`?city=`, `?search=`, `?subscription_tier=`). |
| `GET` | `clinics/{id}/` | Public / Auth | `ClinicsRepository.getClinicById` | Full clinic profile including branches, Google Maps links, practitioners, treatments, offers, products, and articles. |
| `GET` | `practitioners/` | Public / Auth | `PractitionersRepository` | List licensed doctors, nurses, and specialists (`?clinic=`, `?type=`). |
| `GET` | `practitioners/{id}/` | Public / Auth | `PractitionersRepository` | Practitioner detail (bio, specialties, before/after gallery, linked treatments). |
| `GET` | `categories/` | Public / Auth | `TreatmentsRepository` | Treatment categories (`name_en`, `name_ar`, `icon`). |
| `GET` | `treatments/` | Public / Auth | `TreatmentsRepository` | List treatments (`?category=`, `?clinic=`, `?search=`). |
| `GET` | `treatments/{id}/` | Public / Auth | `TreatmentsRepository` | Treatment detail. |
| `GET` | `offers/` | Public / Auth | `OffersRepository` | Active clinic promotional offers (`?clinic=`, `?city=`). |
| `GET` | `products/` | Public / Auth | `ProductsRepository` | Clinic skincare/aesthetic products (**inquiry-only**, no cart). |
| `GET` | `products/{id}/` | Public / Auth | `ProductsRepository` | Product detail (`ProductDetailScreen` -> "Inquire About Product" lead). |
| `GET` | `articles/` | Public / Auth | `ArticlesRepository` | Bilingual medical & educational articles. |
| `GET` | `articles/{id}/` | Public / Auth | `ArticlesRepository` | Full article content (`ArticleDetailScreen`). |

### `featured_ads` Schema & Video Ad Contract
In `GET /api/v1/home/feed/` (and `ClinicModel.fromJson`), each item in `featured_ads` (or top-tier clinics) supports both static image banners and short muted video reels (up to 15 seconds):
- `subscription_tier`: `"vip"` (`SubscriptionTier.vipPlatinum` — priority 1) | `"featured"` (`SubscriptionTier.featured` — priority 2) | `"basic"`
- `media_type` (or `ad_media_type`): `"image"` | `"video"`
- `image_url` (or `cover_image` / `banner_image`): HTTPS URL to cover/banner image
- `video_url` (or `ad_video_url` / `featured_video_url` / `promo_video_url`): Optional HTTPS URL to a short `.mp4` video (up to 15s)
- **Flutter Behavior (`FeaturedAdSlideMedia`)**:
  - When `video_url` is non-empty and `media_type == "video"`, `FeaturedAdSlideMedia` initializes `VideoPlayerController` with `volume: 0.0` (muted) and loops playback capped at `Duration(seconds: 15)`.
  - If `video_url` is null/empty or network video playback fails, the widget automatically falls back to `LuxuryImage` (`image_url` / `cover_image`).

---

## 3. Patient Appointment Requests / Leads (`leads/`)

| Method | Relative Path | Auth | Used By | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `leads/` | Patient | `LeadsRepository.createLead` | Submit a Lead (`clinic`, optional `branch`, `practitioner`, `treatment`, `offer`, `product`, `lead_type`, `service_name`, `patient_name`, `patient_phone`, `preferred_time_window`, `notes`). Returns HTTP `201` (or `429` on rapid duplicate submission). |
| `GET` | `leads/my/` | Patient | `LeadsRepository.getMyLeads` | List authenticated patient's submitted requests (`?status=`). |
| `GET` | `leads/my/count/` | Patient | `LeadsRepository.getMyLeadsCount` | Count of patient leads. |
| `GET` | `leads/{id}/` | Patient | `LeadsRepository.getLeadDetail` | Single lead detail. |

> **Mandatory Lead Rule**: Submitting a lead displays the exact Arabic message `"تم إرسال طلبك وستتواصل العيادة معك"` (`AppointmentSuccessScreen`). There is no slot reservation or payment step.

---

## 4. Referral & Rewards (`referral/`)

| Method | Relative Path | Auth | Used By | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `referral/my-status/` | Patient | `ReferralRepository.getMyStatus` | Returns `referral_code`, `successful_invites_count`, `current_points`, `points_to_collect` (`500`), `can_collect_code`, `milestones` (`20`, `35`, `50`), and issued `discount_codes`. |
| `POST` | `referral/collect-code/` | Patient | `ReferralRepository.collectCode` | Deducts 500 points and generates a 15% discount code (`AW-15-...`) valid for 3 months. |

---

## 5. Clinic Portal (`clinic-portal/`)

Requires `clinic_admin` or `clinic_staff` role associated with an active clinic:

| Method | Relative Path | Purpose |
| :--- | :--- | :--- |
| `GET` | `clinic-portal/dashboard/` | Clinic KPI counts (total leads, new leads, contacted, booked, conversion rate). |
| `GET`, `PATCH` | `clinic-portal/profile/` | View and update clinic details, contact numbers, address, and Google Maps link. |
| `GET` | `clinic-portal/badges/` | Lightweight unread requests and lead status badge counts (`new_requests`, `unread_requests`, `contacted_requests`, `closed_requests`, `total_requests`). |
| `GET`, `PATCH` | `clinic-portal/leads/`, `clinic-portal/leads/{id}/` | Filter clinic leads (`status`, `search`, `page`, `page_size`). Supports both paginated envelope (`results`) and direct list. |
| `GET`, `POST` | `clinic-portal/leads/{id}/notes/` | List and append internal staff notes on a lead. |
| `GET`, `POST`, `PATCH`, `DELETE` | `clinic-portal/practitioners/` & `{id}/` | Manage clinic doctors, nurses, and licensed professionals. |
| `GET`, `POST`, `PATCH`, `DELETE` | `clinic-portal/treatments/` & `{id}/` | Manage clinic treatments. |
| `GET`, `POST`, `PATCH`, `DELETE` | `clinic-portal/offers/` & `{id}/` | Manage promotional offers. |
| `GET`, `POST`, `PATCH`, `DELETE` | `clinic-portal/products/` & `{id}/` | Manage inquiry-only skincare products. |
| `GET`, `POST`, `PATCH`, `DELETE` | `clinic-portal/articles/` & `{id}/` | Manage educational articles. |
| `POST` | `clinic-portal/discount-codes/verify/` | Verify a patient's 15% referral discount code (`code`) without consuming it. |
| `POST` | `clinic-portal/discount-codes/redeem/` | Mark a verified 15% referral discount code (`code`) as redeemed (`used`). |

---

## 6. Super Admin Portal (`admin/`)

Requires `super_admin` role:

| Method | Relative Path | Purpose |
| :--- | :--- | :--- |
| `GET` | `admin/dashboard/` | Global platform metrics (active/suspended clinics, total leads, pending moderation counts). |
| `GET` | `admin/analytics/` | Aggregated lead & engagement metrics per clinic. |
| `GET` | `admin/clinics/` & `admin/clinics/{id}/` | List and inspect all clinics across tiers and statuses. |
| `POST` | `admin/clinics/{id}/{activate\|suspend\|verify}/` | Activate, suspend, or verify a clinic. |
| `GET` | `admin/leads/` & `admin/leads/{id}/` | **Strictly READ-ONLY** supervision of all platform leads (`AdminPortalRepository` has no mutation methods for leads). |
| `GET`, `POST` | `admin/offers/{id}/{approve\|reject\|suspend\|restore}/` | Moderate clinic offers. |
| `GET`, `POST` | `admin/products/{id}/{approve\|reject\|suspend\|restore}/` | Moderate clinic products. |
| `GET`, `POST` | `admin/articles/{id}/{approve\|reject\|suspend\|restore}/` | Moderate clinic articles. |
| `GET`, `PATCH` | `admin/settings/` | Platform-level configuration settings. |

---

## 7. Push Notifications & Device Tokens (`notifications/`)

| Method | Relative Path | Auth | Used By | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `notifications/devices/` | Authenticated | `DeviceTokenService.registerDeviceToken` | Upsert FCM device push token (`token`, `platform`: `android`\|`ios`\|`web`, optional `app_version`). |
| `DELETE` | `notifications/devices/{token}/` | Authenticated | `DeviceTokenService.deactivateCurrentDevice` | Deactivate FCM push token on user logout. |

---

## 8. Explicitly Out-of-Scope Endpoints (DO NOT BUILD / DO NOT CALL)
Per AESTHETIC WAY product boundaries (`AGENTS.md`):
- **No payment or checkout endpoints** (`/payments/`, `/checkout/`, `/stripe/`, `/tabby/`).
- **No shopping cart or order endpoints** (`/cart/`, `/orders/`).
- **No real-time booking slot / calendar reservation endpoints** (`/slots/`, `/calendar/book/`).
