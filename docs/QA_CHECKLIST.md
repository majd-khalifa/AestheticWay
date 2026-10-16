# AESTHETIC WAY — Production Manual QA Checklist

Target Backend: `https://aestheticway.ae/api/v1/`

---

## 1. First Launch, Branding & Global UI Standards
- [ ] **Fresh Install / Cleared Storage**:
  - App launches in **English (`LTR`)** by default (`Home`, `Clinics`, `Offers`, `My Requests`, `Profile`).
  - App launches in **Light Mode (`Soft Light Luxury`)** by default.
- [ ] **Splash & App Icon**:
  - Device home screen shows the `AW / AESTHETIC WAY` silver emblem centered and prominent on the `#070C1A` dark navy launcher icon.
  - `SplashScreen` displays the `300×300` centered brand logo clearly on `#070C1A` without cropping or aspect-ratio distortion.
- [ ] **Language & Theme Persistence**:
  - Navigate to **Profile** → switch Language to **العربية (`RTL`)** and Theme to **Dark Mode**.
  - Force-close and relaunch the app: verify **Arabic (`RTL`)** and **Dark Mode** are preserved.
  - Switch back to **English (`LTR`)** and **Light Mode** for default testing.

---

## 2. Patient Role QA (`patient1@aestheticway.ae` / `StagingPassword123!`)

### A) Home & Discovery
- [ ] **Home Header**:
  - Brand logo is crisp on the left (`LTR`) / right (`RTL`).
  - City filter pill (`All UAE` / `Dubai` / `Abu Dhabi`) filters clinics and feed content.
  - **No heart / favorites icon** appears in the top header corner.
- [ ] **VIP / Featured Ads Carousel**:
  - `Aesthetic Way Clinic Downtown` (`VIP`) appears first, followed by `Luxe Dermatology Jumeirah` (`Featured`).
  - `Capital Aesthetics Corniche` (`Basic`) does **not** appear in the top sponsored carousel.
  - If a slide includes `video_url` (`media_type: "video"`), video plays **muted**, loops within **15 seconds**, and shows the `15s Video` badge; otherwise cover image (`LuxuryImage`) displays cleanly.
- [ ] **Clinics & Practitioners**:
  - Open `Aesthetic Way Clinic Downtown` profile → verify branches, treatments, offers, products, and articles load from production.
  - Tap **Google Maps** button → opens clinic coordinates in Google Maps.
  - Tap **Call** / **WhatsApp** buttons → launches phone dialer / WhatsApp with clinic number.
  - Open a Practitioner profile → verify role badge (`Doctor` / `Licensed Nurse` / `Licensed Specialist`) and verify **no raw license numbers or `DHA`/`DOH`/`MOHAP` text** appear in UI.
- [ ] **Products & Articles**:
  - Open **Products** → select a product → verify screen has **"Inquire About Product"** lead CTA and **NO shopping cart, quantity selector, or price checkout**.
  - Open **Articles** → select an article → verify full bilingual article body renders cleanly.

### B) Lead Submission & My Requests
- [ ] **Submit Appointment Request (Lead)**:
  - From a Clinic, Offer, Treatment, or Product, tap **Request Appointment / Inquire**.
  - Select branch, optional practitioner, preferred time window (`Morning` / `Afternoon` / `Evening`), and submit.
  - Verify **no calendar time-slot grid** and **no payment step** exist.
  - In Arabic mode (`العربية`), verify the success screen displays the exact required text:
    `تم إرسال طلبك وستتواصل العيادة معك`
- [ ] **My Requests Tab**:
  - Open **My Requests** → verify the newly created lead appears with its reference code (`#REQ-...`) and status (`New`).

### C) Referral & Profile
- [ ] **Referral & Rewards (`ReferralScreen`)**:
  - Open **Profile** → **Referrals & Rewards**.
  - Verify personal referral code (`AW-...`) copies to clipboard, milestones (`20`, `35`, `50`) and points progress bar render accurately, and available 15% discount codes (`AW-15-...`) are listed.
- [ ] **Live Profile (`ProfileScreen`)**:
  - Tap **Edit Profile** → verify `Phone` and `Email` fields are **read-only** and rendered left-to-right (`LtrTextFormField`).
  - Update `Full Name` and tap **Save Changes** → verify `PATCH /api/v1/auth/me/` succeeds and persists on reload.

---

## 3. Clinic Portal QA (`admin.downtown@aestheticway.ae` / `StagingPassword123!`)
- [ ] **Role Routing**: Log in with `admin.downtown@aestheticway.ae` → app routes automatically to `ClinicMainNavScreen`.
- [ ] **Dashboard & Leads Management**:
  - Verify KPI cards load live counts from `GET /api/v1/clinic-portal/dashboard/`.
  - Open **Leads** tab → locate the patient lead submitted earlier → update status from `New` → `Contacted` → `Booked` and add an internal staff note.
- [ ] **Catalog CRUD**:
  - Open **Catalog** tab → verify live lists of Practitioners, Treatments, Offers, Products, and Articles.
  - Create or edit an Offer / Treatment and verify changes reflect in the Patient App.
- [ ] **Clinic Profile & 15% Discount Code Verification**:
  - Open **Clinic Profile** → edit clinic description/phone and save (`PATCH /api/v1/clinic-portal/profile/`).
  - Open **Verify Discount Code** (`ClinicVerifyCodeScreen`) → enter a valid patient referral discount code (`AW-15-...`) → verify 15% discount validation and redemption (`POST /api/v1/clinic-portal/discount-codes/verify/` & `redeem/`).

---

## 4. Super Admin Portal QA (`super_admin@aestheticway.ae` / `StagingPassword123!`)
- [ ] **Role Routing**: Log in with `super_admin@aestheticway.ae` → app routes automatically to `AdminMainNavScreen`.
- [ ] **Global Dashboard & Analytics**:
  - Verify platform-wide metrics load from `GET /api/v1/admin/dashboard/` and `GET /api/v1/admin/analytics/`.
- [ ] **Clinic Governance**:
  - Open **Clinics** tab → test suspending and reactivating a clinic (`POST /api/v1/admin/clinics/{id}/suspend/` & `activate/`).
- [ ] **Read-Only Lead Supervision**:
  - Open **Leads** tab → filter by clinic or status → verify leads are **strictly read-only** (no status mutation buttons for Super Admin).
- [ ] **Content Moderation**:
  - Open **Moderation** tab → approve, reject, suspend, or restore clinic Offers, Products, and Articles.
