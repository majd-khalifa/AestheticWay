# AESTHETIC WAY — Native Media Upload & Unified Referral Architecture Report

**Document Version:** 1.0.0  
**Target Platform:** iOS & Android (Customer Mobile App & Clinic/Admin Portals)  
**Target API:** `https://aestheticway.ae/api/v1/`  
**Date:** October 2026  
**Status:** Implemented & Verified (157/157 Tests Passing, 0 Analyzer Issues)

---

## 1. Executive Summary

This architecture document details the implementation of two major UX and platform enhancements across the **AESTHETIC WAY** mobile application:

1. **Native Mobile Media Upload Pipeline**:
   - Decommissioned raw URL text fields (`https://...`) across all creation/edit forms.
   - Engineered `LuxuryImagePickerField` supporting native Camera and Gallery pickers with instant preview, dark navy & silver luxury styling, and circular/banner modes.
   - Integrated `MediaUploadService` communicating with the backend media ingestion endpoint (`POST /api/v1/media/upload/`).
   - Upgraded Super Admin clinic creation (`AdminCreateClinicDialog`) and clinic profile editing (`AdminClinicDetailSheet`), Clinic Portal Profile management (`ClinicProfileScreen`), Practitioners avatar upload (`ClinicPractitionersScreen`), Offers banner upload (`ClinicOffersScreen`), and Products catalog (`ClinicProfileScreen`).

2. **Unified Referral & Invite Architecture**:
   - Modernized the referral hub (`ReferralScreen`) from a rigid 500-point gate to a modern **Unified Referral Link** (`https://aestheticway.ae/invite/<code_or_user>`).
   - Added 1-tap Copy with haptic feedback, direct WhatsApp sharing with pre-composed luxury bilingual invitation copy, and a 3-step luxury guide.
   - Retained network metrics (Registered Friends, Points, Next Milestone) and preserved all issued 15% discount codes.

3. **Strict Product Boundaries Maintained**:
   - **NO** in-app payments or checkout.
   - **NO** appointment booking calendar or time slots (lead generation only).
   - **NO** home services.

---

## 2. Native Mobile Media Upload Architecture

### 2.1 Backend Contract Inspection (`/api/v1/media/upload/`)
- **Endpoint**: `POST /api/v1/media/upload/`
- **Content-Type**: `multipart/form-data`
- **Request Form Fields**:
  - `file`: Binary image file (JPEG, PNG, WEBP).
  - `media_type`: Enum string representing context (e.g., `clinic_logo`, `clinic_cover`, `practitioner_avatar`, `offer_image`, `product_image`, `article_cover`).
- **Response Payload Envelope**:
  ```json
  {
    "id": "e67417e3-0d56-4c48-8df0-7389aa3ec763",
    "file": "https://aestheticway.ae/media/uploads/2026/10/uuid.jpg",
    "thumbnail": "https://aestheticway.ae/media/uploads/2026/10/uuid_thumb.jpg",
    "file_size": 245120,
    "mime_type": "image/jpeg",
    "media_type": "practitioner_avatar",
    "created_at": "2026-10-05T19:30:00Z"
  }
  ```

### 2.2 Core Media Service (`MediaUploadService`)
Located in `lib/core/services/media_upload_service.dart`:
- Handles Dio `FormData` assembly using `MultipartFile.fromFile(filePath, filename: ...)`.
- Automatically tracks upload progress and parses the response into a structured `MediaUploadResult` model (`id`, `url`, `thumbnailUrl`, `fileSize`, `mimeType`).
- Provides safe error mapping and fallback.

### 2.3 Luxury UI Component (`LuxuryImagePickerField`)
Located in `lib/core/widgets/luxury_image_picker_field.dart`:
- **Modal Picker**: Triggers a luxury bottom sheet giving users the choice between **Camera** (`ImageSource.camera`) and **Photo Library** (`ImageSource.gallery`).
- **Shape Adaptability**:
  - `isCircular: true`: Circular avatar mode with centered camera badge (used for Doctor/Practitioner avatars).
  - `isCircular: false`: Aspect-ratio banner mode with rounded corners (used for Clinic Covers, Offer Banners, Clinic Logos, and Products).
- **Preview Support**: Instantly renders either the newly selected local file (`Image.file`) or existing network image (`CachedNetworkImage` / `Image.network`).
- **Luxury Aesthetic**: Dark navy / slate container, champagne accent borders (`AppColors.accentChampagne`), subtle remove/replace action pills.
- **Platform Permissions**: Configured in `ios/Runner/Info.plist`:
  - `NSCameraUsageDescription`: *"Aesthetic Way needs camera access to capture clinic, doctor, and treatment photos."*
  - `NSPhotoLibraryUsageDescription`: *"Aesthetic Way needs photo library access to upload clinic branding, doctor avatars, and offer banners."*

### 2.4 Repositories & Data Layer Orchestration
- **`ClinicCatalogRepository`** (`lib/features/clinic_portal/data/clinic_catalog_repository.dart`):
  - Helper `_resolveMediaPayload`: Inspects the payload before calling DRF APIs. If a local file path is detected in the image field (`avatar`, `image`, `cover_image`), it invokes `MediaUploadService().uploadImage()`, replaces the local path with the public CDN URL, and populates `media_asset` with the upload UUID.
  - Applied across: `createPractitioner`, `updatePractitioner`, `createOffer`, `updateOffer`, `createProduct`, `updateProduct`, `createArticle`, `updateArticle`.
  - `updateClinicProfile`: Supports both `dio.FormData` multipart payload and JSON payload.
- **`AdminRepository`** (`lib/features/admin/data/admin_repository.dart`):
  - Added `updateClinic(String id, Map<String, dynamic> data)` targeting `PATCH /api/v1/admin/clinics/{id}/`.
- **`AdminPortalService` & `ClinicPortalService`**:
  - Updated signatures and service methods to accept `logo` and `coverImage` parameters.

---

## 3. Screen Integrations & User Experience

| Screen | Target Entity | Picker Mode | Upload Trigger / Payload |
|---|---|---|---|
| `AdminCreateClinicDialog` | Clinic Logo & Cover Photo | Banner / Rectangular | Automatically uploads via `MediaUploadService` during dialog submission; sends `logo` & `cover_image` URLs in provision payload. |
| `AdminClinicDetailSheet` | Clinic Logo & Cover Photo | Banner / Rectangular | "Edit Clinic Details & Branding" action button opens `_handleEditClinic` modal; saves changes via `AdminRepository.updateClinic`. |
| `ClinicProfileScreen` | Clinic Logo & Cover Photo | Banner / Rectangular | `_showEditClinicProfileDialog` allows clinic admins to pick new logo & cover; updates via `ClinicPortalService.updateClinicProfile`. |
| `ClinicProfileScreen` | Product Catalog Image | Rectangular | `_showAddProductDialog` replaces URL text field with `LuxuryImagePickerField`; resolves media asset during product creation. |
| `ClinicPractitionersScreen` | Doctor Avatar | Circular (110x110) | Allows picking avatar from camera/gallery; uploads and associates `media_asset` with practitioner profile. |
| `ClinicOffersScreen` | Offer Banner Image | Banner / Rectangular (140h) | Replaces URL text field with `LuxuryImagePickerField`; uploads and associates `media_asset` with promotional offer. |

---

## 4. Modern Unified Referral Link Architecture

### 4.1 Referral Specification
- **Unified Referral Link Format**: `https://aestheticway.ae/invite/<referral_code>`
- **Deep-Link / Universal Link Route**: Handled seamlessly by the app router or web landing page to route the invitee directly to registration while attributing the inviter's referral code.

### 4.2 User Experience on `ReferralScreen`
Located in `lib/features/referral/presentation/screens/referral_screen.dart`:
1. **Hero Invite Link Card**:
   - Prominently displays the unified link: `https://aestheticway.ae/invite/$referralCode`.
   - 1-Tap **Copy Link** button with haptic feedback (`HapticFeedback.lightImpact()`) and luxury snackbar confirmation.
   - Full-width **Share via WhatsApp** button (`SilverButton` with `Icons.send_rounded`) executing pre-composed luxury bilingual copy:
     > *"انضم إلى تطبيق AESTHETIC WAY — المنصة الفاخرة لاكتشاف أفضل عيادات وأطباء التجميل المعتمدين في الإمارات! 🌟\n\nسجل عبر رابط دعوتي الحصري:\nhttps://aestheticway.ae/invite/AW-DUBAI-88"*
   - Discrete **Direct Referral Code** container with copy button for manual entry if needed.
2. **How It Works (Luxury 3-Step Guide)**:
   - Uses iconography (`Icons.send_rounded`, `Icons.person_add_alt_1_rounded`, `Icons.card_giftcard_rounded`) instead of hardcoded numbers to preserve visual elegance and prevent test selector collisions.
   - Clearly explains:
     1. Share link with friends.
     2. Friend signs up and submits their first clinic inquiry.
     3. Both parties earn exclusive reward points.
3. **Member Network & Milestones Card**:
   - 3 Clean KPI Columns:
     - **Registered Friends** (`$invitesCount`)
     - **Current Points** (`$currentPoints pts`)
     - **Next Milestone** (`${referralService.nextMilestoneThreshold}`)
   - Dynamic explanatory milestone banner (`referralService.getMilestoneDynamicMessage()`).
   - Milestone progress bar and 20 / 35 / 50 invite tier checklist.
   - Non-blocking points redemption button (`SilverButton`) active when points $\ge 500$, with friendly guidance when points are building up.
4. **Preserved 15% Discount Vouchers Section**:
   - Retains all previously generated discount codes (`AW-15-XXXX`) with status badges (Available, Used, Expired) and 1-tap copy.

---

## 5. Backend Alignment Checklist for Backend Engineer (Ali)

The Flutter mobile application is already sending and expecting the required fields. Please ensure the backend in `apps/admin_portal/` and `apps/clinics/` aligns with the following checklist:

- [ ] **1. `AdminClinicProvisionSerializer` (`apps/admin_portal/serializers.py`)**:
  - Add optional fields `logo` (`serializers.CharField(required=False, allow_null=True)`) and `cover_image` (`serializers.CharField(required=False, allow_null=True)`).
  - In `clinic_provisioning.py`, assign `clinic.logo = validated_data.get('logo')` and `clinic.cover_image = validated_data.get('cover_image')` when provided.

- [ ] **2. `AdminClinicUpdateSerializer` (`apps/admin_portal/serializers.py`)**:
  - Add `logo`, `cover_image`, `city`, `emirate`, `phone`, `whatsapp`, `license_number`, `subscription_tier`, and `is_active` to `fields` in `AdminClinicUpdateSerializer`.

- [ ] **3. Media Asset File Storage & Permissions**:
  - Verify that media assets uploaded via `/api/v1/media/upload/` return fully-qualified HTTPS URLs (`https://aestheticway.ae/media/...` or S3/Cloud storage URLs) with public read permissions.
  - Verify that maximum file upload size is set to at least 10MB in Nginx/Django `DATA_UPLOAD_MAX_MEMORY_SIZE` and `FILE_UPLOAD_MAX_MEMORY_SIZE`.

- [ ] **4. Referral Invite Link Redirection**:
  - Ensure the web server or frontend responds to `GET /invite/<code_or_user>` by redirecting mobile users via deep link / universal link (`aestheticway://invite/<code_or_user>`) or directing to app store download links with referral code tracking.

---

## 6. Verification & Quality Assurance

- **Static Analysis**:
  ```bash
  flutter analyze
  # Result: No issues found! (ran in 6.7s, 0 errors, 0 warnings, 0 infos)
  ```
- **Test Suite Execution**:
  ```bash
  flutter test
  # Result: 00:15 +157: All tests passed! (157 of 157 passed, 100% pass rate)
  ```
- **Key Tests Verified**:
  - `test/referral_and_client_feedback_test.dart`: Verified exact referral strings, copyable code, dynamic milestone banners, and 15% discount note.
  - `test/admin_clinic_lifecycle_test.dart`: Verified clinic provisioning, credential handoff, and password reset.
  - `test/admin_clinics_management_test.dart`: Verified Super Admin clinic search, filter, and detail management.
  - `test/clinic_portal_repository_test.dart`: Verified catalog operations and image payload resolution.
  - `test/patient_profile_live_test.dart`: Verified patient phone/email change via OTP and profile PATCH.
