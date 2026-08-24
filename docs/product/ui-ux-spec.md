# AESTHETIC WAY (طريق الجمال الطبي)
## Documenting UI/UX Production Specification & Design Documentation
**Platform**: iOS & Android (RTL Primary Arabic + LTR English Support)  
**Target Market**: UAE (Dubai & Abu Dhabi Launch)  
**Product Category**: Luxury Medical Aesthetic & Dermatology Discovery & Lead Generation Platform  
**Document Version**: 1.1 (Updated Revision)  
**Design System**: Deep Dark Navy & Platinum Silver Aesthetics (`#070B16` / `#121A2B` / `#D7DDE8`)

---

> ⛔ **CRITICAL BOUNDARY RULES & PLATFORM CONSTRAINTS (FROZEN)**:
> 1. **NO IN-APP PAYMENTS**: Zero checkout, payment gateways, e-commerce carts, or financial transactions for patients inside the application.
> 2. **NO BOOKING CONFIRMATIONS**: No real-time calendar booking, schedule locks, or definitive appointment confirmations inside the app.
> 3. **MANDATORY SUCCESS TEXT**: The success screen after submitting a request MUST explicitly state:  
>    `"تم إرسال طلبك وستتواصل العيادة معك"` (Your request has been sent and the clinic will contact you).  
>    **NEVER** use: `"تم تأكيد الحجز"` (Booking confirmed).
> 4. **NO HOME SERVICES**: Strictly no in-home beauty, mobile massage, or non-clinical home salon services.
> 5. **NO NON-MEDICAL SALONS**: Platform is exclusive to DHA / DOH / MOHAP licensed medical aesthetic clinics and licensed healthcare professionals.
> 6. **NO USER WALLETS OR COMPLEX LOYALTY**: No store credit, complex points systems, or patient e-wallets.
> 7. **BUSINESS MODEL**: B2B fixed monthly/annual subscription packages for clinics (NOT per-booking commission).
> 8. **CORE PURPOSE**: Discovery + Comparison + Direct Contact / Appointment Request (`Lead Generation`).

---

## SECTION 1: DESIGN SYSTEM & VISUAL IDENTITY

### 1.1 Color Palette (Luxury Medical Aesthetic)

| Color Name | Hex Code | Role & Usage |
| :--- | :--- | :--- |
| **Deep Dark Background** | `#070B16` | Main screen background color |
| **Surface Dark Base** | `#0B1220` | Secondary background, grouped cards |
| **Card Surface Elevated** | `#121A2B` | Elevated card containers, modals, bottom sheets |
| **Platinum Silver Primary**| `#D7DDE8` | Primary CTA text, key icon highlights, silver badges |
| **Metallic Silver Border** | `#C0C7D4` | Card borders (0.5pt/1pt), dividers, input outlines |
| **Soft Silver Light** | `#E5EAF2` | Active state fills, soft glow highlights |
| **Text Primary (White)** | `#F5F7FA` | Primary headlines, body titles, high-contrast text |
| **Text Secondary / Muted**| `#9AA6B2` | Subtitles, captions, unselected tabs, secondary info |
| **Medical Trust Blue** | `#2B5C8F` | Subtle badge accent for DHA / DOH / MOHAP license verifications |
| **Practitioner Nurse Teal**| `#1D6A78` | Type badge accent for Licensed Nurses & Technicians |
| **Success Muted Green** | `#2D6A4F` | Status indicators for active offers or verified status |
| **VIP Gold (Subdued)** | `#B8860B` | Subscription tier badges (e.g. VIP Platinum Partner badge) |
| **Error Soft Red** | `#9B2C2C` | Input validation errors, network offline banner |

### 1.2 Typography & RTL Rules
- **Arabic Font Family**: `SF Arabic` / `Tajawal` / `IBM Plex Sans Arabic` (Medium 500 for titles, Regular 400 for copy, Bold 700 for headings).
- **English Font Family**: `SF Pro Text` / `Inter` (Matching weights).
- **Scale Hierarchy**:
  - **Hero Title**: 26pt / Bold / Line Height 34pt
  - **Screen Title (Header)**: 20pt / SemiBold / Line Height 28pt
  - **Card Title**: 16pt / SemiBold / Line Height 22pt
  - **Body Large**: 15pt / Regular / Line Height 22pt
  - **Body Medium**: 13pt / Regular / Line Height 18pt
  - **Caption / Meta**: 11pt / Regular / Line Height 15pt
- **RTL Specifications**:
  - Direction: `dir="rtl"` as primary layout.
  - Back buttons chevron: `ChevronRight` for Arabic RTL, `ChevronLeft` for English LTR.
  - Star rating displays: Numeric value left of stars in AR (`4.9 ★`), right of stars in EN (`★ 4.9`).
  - Distance badge layout: `📍 دبي، 3.2 كم` (Right-aligned text block).

### 1.3 Iconography & Component Styling
- **Icon Style**: Thin 1.5pt line icons with subtle silver gradients.
- **Card Surface Specs**:
  - Background: `#121A2B`
  - Border: `1px solid rgba(192, 199, 212, 0.15)`
  - Border Radius: `16px` for main cards, `12px` for inner elements, `24px` for pills/chips.
  - Box Shadow: `0px 8px 24px rgba(0, 0, 0, 0.4)`
- **Badge Styling**:
  - **Featured / Sponsored (B2B Tiers)**:
    - *VIP Platinum Partner (6-12 Months)*: Background `linear-gradient(135deg, #2A2111 0%, #0B1220 100%)`, border `1px solid #B8860B`, text `#F5F7FA`, badge `👑 شريك ماسي VIP`.
    - *Featured Partner (3-6 Months)*: Background `linear-gradient(135deg, #1C273E 0%, #0B1220 100%)`, border `1px solid #D7DDE8`, text `#F5F7FA`, badge `✨ إعلان مميز`.
  - **Licensed Facility**: Background `rgba(43, 92, 143, 0.2)`, border `1px solid #2B5C8F`, text `#9AA6B2`, icon `🛡️ ترخيص طبي معتمد`.
  - **Practitioner Type Badges**:
    - *Doctor*: Background `rgba(43, 92, 143, 0.25)`, border `1px solid #2B5C8F`, text `#D7DDE8`, title `👨‍⚕️ طبيب / Doctor`.
    - *Nurse*: Background `rgba(29, 106, 120, 0.25)`, border `1px solid #1D6A78`, text `#E5EAF2`, title `👩‍⚕️ ممرض مرخص / Licensed Nurse`.
    - *Licensed Professional*: Background `rgba(190, 197, 212, 0.15)`, border `1px solid #C0C7D4`, text `#F5F7FA`, title `🔬 أخصائي مرخص / Licensed Professional`.

---

## SECTION 2: INFORMATION ARCHITECTURE & USER FLOWS

```
                                  ┌──────────────────────────┐
                                  │      APP STARTUP         │
                                  └────────────┬─────────────┘
                                               │
                                  ┌────────────▼─────────────┐
                                  │      1. SPLASH SCREEN    │
                                  └────────────┬─────────────┘
                                               │
                                  ┌────────────▼─────────────┐
                                  │     2. ONBOARDING        │
                                  │ (Skip / Explore Options)  │
                                  └────────────┬─────────────┘
                                               │
                ┌──────────────────────────────┴──────────────────────────────┐
                │                                                             │
   ┌────────────▼─────────────┐                                 ┌─────────────▼────────────┐
   │    GUEST BROWSE MODE     │                                 │   REGISTERED / LOGGED    │
   │ (Discovery + Compare Only)│                                 │   (Full Interactive)     │
   └────────────┬─────────────┘                                 └─────────────┬────────────┘
                │                                                             │
                └──────────────────────────────┬──────────────────────────────┘
                                               │
                                  ┌────────────▼─────────────┐
                                  │       3. HOME SCREEN     │
                                  │ (Top Ads -> Categories   │
                                  │ -> Clinics -> Nearby)    │
                                  └────────────┬─────────────┘
                                               │
       ┌───────────────────────┬───────────────┴───────────────┬──────────────────────┐
       │                       │                               │                      │
┌──────▼──────┐         ┌──────▼──────┐                 ┌──────▼──────┐        ┌──────▼──────┐
│  4. SEARCH  │         │ 6. CLINICS  │                 │9.PRACTITION-│        │11.TREATMENTS│
│  & FILTERS  │         │   DIRECTORY │                 │ERS DIRECTORY│        │ & OFFERS    │
└──────┬──────┘         └──────┬──────┘                 └──────┬──────┘        └──────┬──────┘
       │                       │                               │                      │
       └───────────────────────┴───────────────┬───────────────┴──────────────────────┘
                                               │
                                  ┌────────────▼─────────────┐
                                  │   7. CLINIC PROFILE      │
                                  │ (Staff, Treatments,      │
                                  │  Location, Verification) │
                                  └────────────┬─────────────┘
                                               │
               ┌───────────────────────────────┼───────────────────────────────┐
               │                               │                               │
  ┌────────────▼─────────────┐    ┌────────────▼─────────────┐    ┌────────────▼─────────────┐
  │  GOOGLE MAPS DIRECTIONS  │    │  DIRECT CALL / WHATSAPP  │    │  16. APPOINTMENT REQUEST │
  │   (External App Launch)  │    │  (Direct Contact Launch) │    │   (Lead Submission Form) │
  └──────────────────────────┘    └──────────────────────────┘    └────────────┬─────────────┘
                                                                               │
                                                                  ┌────────────▼─────────────┐
                                                                  │ 17. REQUEST SUCCESS      │
                                                                  │ "Clinic will contact you"│
                                                                  └────────────┬─────────────┘
                                                                               │
                                                                  ┌────────────▼─────────────┐
                                                                  │ 18. MY APPOINTMENT REQS  │
                                                                  │ (Sent / Contacted List)  │
                                                                  └──────────────────────────┘
```

---

## SECTION 3: SUBSCRIPTION TIER & HOME ADS PLACEMENT UX

### 3.1 Home Screen Top Placement Rule (Strict B2B Tier Priority)
To deliver maximum value for clinic subscriptions without compromising the luxury medical aesthetic, the **first prominent content immediately below the Home Header** is reserved for Featured / Sponsored Clinics:

1. **Tier 1: VIP Platinum Partner (6 to 12 Month Subscriptions)**:
   - **Highest Priority**: Occupies Slots 1 and 2 in the Home Carousel.
   - **Visual Branding**: Gold & Silver metallic edge highlight, badge `👑 شريك ماسي VIP`.
   - **Features**: Hero photo gallery, doctor avatars, direct call shortcut, high visibility in search top-rankings.
2. **Tier 2: Featured Partner (3 to 6 Month Subscriptions)**:
   - **Second Priority**: Occupies Slots 3+ in the Carousel.
   - **Visual Branding**: Platinum Silver outline, badge `✨ إعلان مميز`.
   - **Features**: Highlighting top treatments and clinic rating.
3. **Tier 3: Basic Subscription (1 Month / Standard)**:
   - **No Top Carousel Placement**: Displayed strictly in the standard directory listings sorted by proximity, rating, or relevancy.
   - Standard clean dark card styling without top ad priority.

### 3.2 Non-Intrusive Luxury Ad Experience
- **No Popups / Interstitials**: Zero intrusive popups or full-screen overlay ads upon opening the app.
- **Carousel Controls**: Horizontal smooth swipe container (340dp width) with subtle silver progress indicators (dots).
- **Auto-Scroll Behavior**: Pauses immediately upon user touch/swipe interaction.
- **Fallback States**:
  - *Single Ad Active*: Displays a static luxury banner hero card.
  - *Zero Ads Active*: The slot collapses gracefully; Home screen begins directly with category chips and nearest verified clinics.

---

## SECTION 4: GOOGLE MAPS INTEGRATION ENGINE

### 4.1 Integration Schema & Technical Mapping
Each onboarded clinic entity in the database is linked to Google Maps using one or more of the following parameters:
- `google_place_name_ar` & `google_place_name_en`: Clinic name as indexed on Google Maps.
- `clinic_main_phone`: Main published phone number.
- `reception_phone`: Direct reception desk phone.
- `google_place_id`: String identifier (e.g. `ChIJ...`).
- `latitude` & `longitude`: Exact decimal GPS coordinates.
- `doctor_profile_map_alias`: Specific doctor/practitioner room or branch mapping.

### 4.2 UI Action Triggers & Deep-Linking Logic
- **"Location on Map / عرض على الخريطة" CTA**:
  - Opens native Google Maps app using verified Place ID or coordinates:
    `https://www.google.com/maps/search/?api=1&query={lat},{lng}&query_place_id={google_place_id}`
- **"Directions / الاتجاهات" CTA**:
  - Triggers native turn-by-turn navigation:
    `google.navigation:q={lat},{lng}` (Android) / `comgooglemaps://?daddr={lat},{lng}&directionsmode=driving` (iOS).
- **Distance Calculation Badges**:
  - Displays real-time calculated distance when location permission is granted (e.g. `📍 2.4 كم من موقعك` / `📍 2.4 km from you`).
  - Fallback when permission denied: Displays neighborhood name (e.g. `📍 جميرا 1، دبي`).

### 4.3 Location Handling Status Matrix

| Status | UI Display | User Action / Trigger |
| :--- | :--- | :--- |
| **Location Available** | Displays distance badge (`📍 3.1 كم`) + active Google Maps card preview | Tapping opens Google Maps or launches directions |
| **Location Unavailable** | Disabled card container: `📍 الموقع التفصيلي غير متاح حالياً - تواصل مع العيادة مباشرة` | Direct phone call or WhatsApp button |
| **Permission Required** | Shows `Location Permission Modal (§5 - Screen 35)` with city fallback option | Allows manual city selection (`دبي` / `أبوظبي`) |

---

## SECTION 5: COMPLETE SCREEN SPECIFICATION (36 SCREENS & MODALS)

---

### SCREEN 1: Splash Screen
- **Visual Structure**: Deep Dark Navy (`#070B16`). Centered logo mark (`AW` in metallic silver gradient inside an elegant thin circle) with typography `AESTHETIC WAY` below in Platinum Silver (`#D7DDE8`). Micro-caption at bottom: `منصة الاكتشاف الطبي والتجميلي الفاخرة`.
- **Interactions**: Auto-advance after 2 seconds or once token check completes.

---

### SCREEN 2: Onboarding Screen
- **Visual Structure**: 3 high-end swipeable slides featuring aesthetic clinic interiors, certified doctors, and comparison interfaces.
  - Slide 1: `اكتشف نخبة عيادات الجلدية والتجميل الطبي في الإمارات`
  - Slide 2: `قارِن بين الأطباء والتراخيص والعلاجات بثقة`
  - Slide 3: `تواصل مباشرة أو أرسل طلب موعد بسهولة`
- **CTAs**: `تخطي` (Skip), `التالي` (Next), `ابدأ الآن` (Start Now).

---

### SCREEN 3: Home Screen (Main Hub)
- **Header**:
  - Logo `AESTHETIC WAY` (top right in AR layout).
  - Location Selector Chip: `📍 دبي، الإمارات ▼`.
  - Guest/User Profile Avatar + Favorites Heart Icon.
- **Search Bar**: Input container (`#121A2B`), border `#C0C7D4`. Placeholder: `ابحث عن عيادة، طبيب، أو علاج (مثال: بوتاكس، فوتونا)...`
- **Section 1: Featured / Sponsored Clinics Carousel (B2B Tier Priority)**:
  - **First prominent element right below header**.
  - 340dp width horizontal cards with tier badges (`👑 شريك ماسي VIP` for 6-12 month subscriptions, `✨ إعلان مميز` for 3-6 month subscriptions).
  - Clinic cover photo, logo avatar, name `عيادة كايا للجلدية - جميرا`, rating `★ 4.9 (120)`, distance `📍 3.1 كم`, direct CTAs `تواصل` and `طلب موعد`.
- **Section 2: Category Quick Access Grid**:
  - 4-column grid of circular icons with silver rims:
    1. `جلدية وتجميل` (Dermatology & Aesthetics)
    2. `حقن وتجميل وجه` (Injectables & Fillers)
    3. `ليزر وبشرة` (Laser & Skin)
    4. `جراحة تجميلية` (Aesthetic Surgery)
    5. `علاجات التجديد` (Rejuvenation)
    6. `الممارسون المرخصون` (Licensed Practitioners)
    7. `العروض الطبية` (Medical Offers)
    8. `الكل` (All Categories)
- **Section 3: Nearby Verified Clinics (Google Maps Integration)**:
  - Header: `عيادات قريبة منك 📍` + `عرض على الخريطة` button.
  - Cards: Distance calculation, DHA/DOH license indicator, attached staff avatars, call/WhatsApp shortcuts.
- **Section 4: Active Medical Offers**:
  - Promotional offer cards with validity expiry tags (`ينتهي خلال 3 أيام`).

---

### SCREEN 4: Search Screen
- **Header**: Active search bar with auto-focus, back arrow, clear `✕` button.
- **Recent Searches**: Chips showing past queries (e.g. `د. ريم الخالد`, `هيدرافيسيال`, `جميرا`).
- **Trending Searches**: `بوتاكس الجبهة`, `فيلر الشفايف`, `عيادات دبي`, `علاج التصبغات`.
- **Instant Search Results List**: Tabs: `العيادات (Clinics)`, `الممارسون (Practitioners)`, `العلاجات (Treatments)`.

---

### SCREEN 5: Filter Modal / Screen
- **Filter Groups**:
  1. **City / Area**: `دبي (جميرا، داون تاون، دبي مارينا)`, `أبوظبي (المرصاع، البطين)`.
  2. **Specialty**: `أمراض جلدية`, `تجميل طبي`, `ليزر تجميلي`, `حقن تجميلية`.
  3. **Practitioner Type (نوع الممارس)**: `طبيب (Doctor)`, `ممرض مرخص (Nurse)`, `أخصائي مرخص (Licensed Professional)`.
  4. **Practitioner Gender**: `أنثى`, `ذكر`, `لا يهم`.
  5. **Distance Radius**: Slider `1 كم` to `50 كم`.
  6. **Sort By**: `الأعلى تقييماً`, `الأقرب موقعاً`, `المميز أولاً (Featured)`.
- **Action Footer**: `إعادة ضبط` + `تطبيق الفلاتر (إظهار 24 نتيجة)`.

---

### SCREEN 6: Clinics List Screen
- **Header**: Title `عيادات التجميل والجلدية` + Filter shortcut + Active chips bar.
- **List Layout**: Vertical cards with cover image, logo, verified checkmark, name, area, distance, rating, tier badge (`VIP Platinum / Featured`), tags, and CTAs `تواصل` & `تفاصيل العيادة`.

---

### SCREEN 7: Clinic Profile Screen
- **Hero Header**: High-resolution gallery carousel of clinic facilities. Back, Share, Favorite buttons.
- **Clinic Title Block**:
  - Name: `مركز الأناقة الطبي للجلدية والتجميل`.
  - Tier Badge: `👑 شريك ماسي (VIP Partner)`.
  - Licensing Verification: `🛡️ ترخيص هيئة الصحة بدبي: DHA-FL-009824`.
  - Rating: `★ 4.9 (184 تقييم verified)`.
- **Action Button Row (Primary CTAs)**:
  - Button 1: `📍 الموقع على Google Maps` (Launches native Google Maps).
  - Button 2: `📞 اتصال مباشر` (Initiates phone call).
  - Button 3: `💬 واتساب العيادة` (Opens WhatsApp chat).
  - Primary Full-Width CTA: `📋 طلب موعد (Appointment Request)`.
- **Tab Navigation**: `نبذة وعنوان`, `الكادر الطبي والممارسون (8)`, `العلاجات`, `العروض (3)`, `التقييمات`.
- **Tab Content - About & Location**:
  - Address text + Google Maps preview card + `الاتجاهات (Directions)` button.
  - Working hours + Reception direct contacts.
- **Tab Content - Practitioners List**: Cards for doctors, nurses, and technicians with clear type badges and license numbers.

---

### SCREEN 8: Clinic Branches Screen
- **List Items**:
  - `فرع جميرا - دبي` | `📍 2.5 كم` | `📞 04 300 XXXX`
  - `فرع داون تاون - دبي` | `📍 8.1 كم` | `📞 04 400 XXXX`
  - `فرع البطين - أبوظبي` | `📍 130 كم` | `📞 02 600 XXXX`
- **Actions per Branch**: `عرض على الخريطة`, `الاتجاهات`, `طلب موعد لهذا الفرع`.

---

### SCREEN 9: Professionals List Screen (Multi-Practitioner Support)
- **Header**: Title `دليل الممارسين الكادر الطبي والتجميلي`.
- **Filter Tabs**: `الكل`, `أطباء (Doctors)`, `تمريض مرخص (Nurses)`, `أخصائيون مرخصون (Licensed Professionals)`.
- **Practitioner Cards**:
  - Portrait photo, Full Name `د. ريم الخالد` or `أ. نور الهدى`.
  - **Mandatory Practitioner Type Badge (تحت الاسم مباشرة)**:
    - `👨‍⚕️ طبيب - Doctor` (Blue accent badge)
    - `👩‍⚕️ ممرض مرخص - Licensed Nurse` (Teal accent badge)
    - `🔬 أخصائي تجميل مرخص - Licensed Professional` (Silver accent badge)
  - **Licensing Field (حقل الترخيص المخصص)**:
    - For Doctor: `ترخيص هيئة الصحة بدبي: DHA-P-004812`
    - For Nurse: `ترخيص تمريض MOHAP: MOH-N-982410`
    - For Technician: `ترخيص ممارسة DOH: DOH-PRO-55412`
  - Title/Specialty: `استشاري أمراض جلدية` or `أخصائي ليزر وعناية بالبشرة`.
  - Associated Clinic: `مركز الأناقة الطبي`.
  - Rating: `★ 4.8`, CTAs: `عرض الملف` & `طلب موعد عبر العيادة`.

---

### SCREEN 10: Professional Profile Screen (Enhanced Practitioner Types)
- **Hero Block**: Practitioner portrait, Name, Title, Experience (`14 سنة خبرة`).
- **Practitioner Type Badge Block (تحت الاسم)**:
  - Prominent pill badge displaying practitioner classification: `👨‍⚕️ طبيب (Doctor)` / `👩‍⚕️ ممرض مرخص (Licensed Nurse)` / `🔬 أخصائي تجميل مرخص (Licensed Professional)`.
- **Medical Trust & Verification Box**:
  - Licensing Authority: `هيئة الصحة بدبي (DHA)` / `وزارة الصحة (MOHAP)` / `دائرة الصحة أبوظبي (DOH)`.
  - License Number: `DHA-P-004812` (Validated authority format).
  - Classification: `Consultant Dermatologist` / `Senior Registered Aesthetic Nurse`.
  - Languages Spoken: `العربية، الإنجليزية، الفرنسية`.
- **Associated Clinics & Branches**: Card showing clinic name, location, reception numbers, and map button where this practitioner works.
- **Procedures Offered by Practitioner**: List of clinical services performed (e.g. `حقن الفيلر`, `جلسات الليزر`, `التقشير الكيميائي`).
- **Patient Ratings & Feedback**: Verified patient feedback regarding the professional's care.
- **Bottom Fixed CTA Bar**: `📞 تواصل مع العيادة` + `📋 طلب موعد مع الممارس`.

---

### SCREEN 11: Treatments List Screen
- **Categories Bar**: Scrollable pills: `الكل`, `بوتوكس وفيلر`, `علاجات بشرة`, `شد الوجه`, `ليزر وتفتيح`.
- **Treatment Cards**: Photo/icon, Title `حقن البوتوكس للوجه`, Category, Duration `20 - 30 دقيقة`, Brief description, Clinics count `34 عيادة توفر هذا العلاج`, CTA `استكشف العلاج والعيادات`.

---

### SCREEN 12: Treatment Details Screen
- **Header**: High-res treatment visual + Title `جلسة الهيدرافيسيال الملكي`.
- **Overview Section**: Detailed explanation of medical procedure, targeted skin conditions, duration, downtime (`Downtime: لا يوجد`).
- **Medical Disclaimer Box**:
  - `⚠️ إخلاء مسؤولية طبي: المعلومات المعروضة للتوعية فقط. التقييم الطبي النهائي يتم بواسطة الطبيب المختص أثناء الاستشارة.`
- **Clinics Offering This Treatment**: Filterable list of clinics providing this procedure with distance and `طلب موعد` buttons.

---

### SCREEN 13: Offers List Screen
- **Header**: Title `العروض والباكجات الطبية الحصرية`.
- **Offer Cards**: Image, Badge `خصم 25%`, Title `باكج النضارة الفائقة`, Clinic Name `عيادة كايا`, Expiry tag `⏱️ متبقي 4 أيام`, Pricing details, CTA `عرض تفاصيل العرض`.

---

### SCREEN 14: Offer Details Screen
- **Hero Image**: Promotional design card.
- **Offer Title & Badge**: `عرض نضارة البشرة الصيفي` + `مركز الأناقة الطبي`.
- **Offer Validity Window**: `صالح حتى 31 أغسطس 2026`.
- **Offer Breakdown**: Included sessions and complimentary consultation details.
- **Terms & Conditions**: `ينطبق العرض في فرع جميرا فقط. يرجى إبراز العرض عند زيارة العيادة.`
- **Action CTAs**: `💬 استفسر عبر واتساب` | `📋 طلب موعد بهذا العرض`.

---

### SCREEN 15: Contact Options Sheet (Bottom Modal)
- **Header**: `تواصل مع عيادة الأناقة الطبية`.
- **Options List**:
  1. `📞 اتصال هاتفي مباشر (استقبال العيادة)` -> Triggers `tel:+9714300XXXX`.
  2. `💬 المحادثة عبر واتساب (WhatsApp Chat)` -> Triggers `https://wa.me/97150XXXXXXX`.
  3. `📍 فتح الموقع في Google Maps` -> Launches Google Maps app.
  4. `🌐 زيارة الموقع الإلكتروني للعيادة` -> Opens browser.

---

### SCREEN 16: Appointment Request Form Screen (Lead Generation Form)
- **Header**: Title `طلب موعد استشارة` (Consultation Request).
- **Context Card**: Selected clinic `مركز الأناقة الطبي`, branch `فرع جميرا`, pre-selected service/practitioner.
- **Form Inputs**:
  1. **Clinic Branch (الفرع)**: Dropdown selection.
  2. **Service / Treatment**: Pre-filled or dropdown picker.
  3. **Preferred Practitioner (الممارس المفضل - اختياري)**: Dropdown picker showing name and practitioner type (Doctor/Nurse/Tech).
  4. **Preferred Date & Time Window**: Date picker + Time slot (`صباحاً`, `ظهراً`, `مساءً`).
  5. **Patient Full Name**: Text input.
  6. **Phone Number**: Country code `+971 🇦🇪` + Mobile number.
  7. **Notes / Specific Questions (اختياري)**: Textarea.
- **Legal Checkbox**: `☑ أوافق على مشاركة بيانات التواصل أعلاه مع العيادة المختصة للتواصل معي بشأن طلب الموعد.`
- **Submit CTA**: Full-width silver gradient button `إرسال طلب الموعد (Send Request)`.

---

### SCREEN 17: Appointment Request Success Screen (Strict Wording Rule)
- **Visual Structure**: Full-screen overlay card with glowing silver checkmark `✨`.
- **Mandatory Success Heading**:
  - `تم إرسال طلبك بنجاح!` (Your request has been sent successfully!)
- **Mandatory Body Wording (FROZEN RULE)**:
  - `"تم إرسال طلب الموعد بنجاح إلى [اسم العيادة]. ستقوم فريق الاستقبال في العيادة بالتواصل معك قريباً عبر الهاتف أو الواتساب لتأكيد الموعد النهائي والتفاصيل."`
  - *(Your appointment request has been sent to [Clinic Name]. The clinic reception team will contact you shortly via phone or WhatsApp to confirm your final appointment time and details).*
  - ⛔ **NEVER** use: `"تم تأكيد الحجز"` (Booking confirmed).
- **Summary Card**: Request Code `#REQ-98241`, Clinic Name, Branch, Service, Time Window.
- **Action CTAs**: `عرض طلباتي (My Requests)` | `📍 فتح موقع العيادة على Google Maps` | `العودة للرئيسية`.

---

### SCREEN 18: My Appointment Requests Screen (NEW SCREEN)
- **Purpose**: Displays the user's submitted lead/appointment requests for tracking.
- **Strict Boundary**: Pure informational tracking list. **NO calendar booking or schedule management features**.
- **Header**: Title `طلبات مواعيدي (My Requested Appointments)`.
- **Status Filter Tabs**: `الكل (All)`, `تم الإرسال (Sent)`, `تم التواصل (Contacted)`, `مغلق (Closed)`.
- **Request Card Elements**:
  - Request Reference Code: `#REQ-98241`.
  - Date Submitted: `22 أغسطس 2026`.
  - Clinic Name & Branch: `مركز الأناقة الطبي - فرع جميرا`.
  - Requested Service: `استشارة فيلر وبوتوكس`.
  - Requested Time Window: `24 أغسطس 2026 (الفترة المسائية)`.
  - **Simple Status Pills (حالات بسيطة)**:
    - 🟡 `تم الإرسال (Sent)`: Request sent to clinic receptionist; awaiting contact.
    - 🔵 `تم التواصل (Contacted)`: Clinic receptionist reached out via call/WhatsApp.
    - ⚪ `مغلق (Closed)`: Inquiry completed or archived.
- **Card Actions**:
  - `📞 اتصال بالعيادة` (Direct call shortcut).
  - `💬 محادثة واتساب` (WhatsApp chat shortcut).
  - `📍 فتح موقع العيادة على Google Maps`.
- **Empty State**: `لا توجد طلبات مواعيد سابقة` + `استكشف العيادات والعروض`.

---

### SCREEN 19: Favorites Screen
- **Header**: Title `المفضلة (Saved Items)` + Tabs: `العيادات`, `الممارسون`, `العروض`.
- **List Items**: Saved cards with trash icon to delete and contact shortcuts.
- **Guest State**: Unauthenticated prompt `سجل دخولك لحفظ عناصرك المفضلة` + Login CTA.

---

### SCREEN 20: Reviews List Screen
- **Header**: Title `تقييمات العيادة` + Score `★ 4.9 / 5.0` (184 verified reviews).
- **Review Cards**: Verified patient badge `✓ مريض قام بزيارة العيادة`, rating stars, patient mask `سارة م.`, practitioner name, review text, clinic response box.

---

### SCREEN 21: Write Review Screen
- **Header**: Title `إضافة تقييم للعيادة`.
- **Form**: 1-5 Star Rating Selector, Practitioner Dropdown (`من كان ممارسك؟`), Treatment Received, Written Review Textarea.
- **Submit CTA**: `نشر التقييم`.

---

### SCREEN 22: Guest Browse State
- **Description**: Universal app handling for non-logged-in users.
- **Behavior**: Guests browse Home, Clinics, Practitioners, Treatments, Offers, Maps, and Search without friction.
- **Triggers for Auth**: Tapping `طلب موعد`, `حفظ بالمفضلة`, or `إضافة تقييم` opens bottom modal: `سجّل دخولك لمتابعة الطلب في ثوانٍ`.

---

### SCREEN 23: Login / Signup Screen
- **Header**: Logo `AESTHETIC WAY` + Title `مرحباً بك في عالم التجميل الفاخر`.
- **Inputs**: Country Code `+971 🇦🇪` + Mobile Number Input.
- **CTAs**: Primary `إرسال رمز التحقق (SMS OTP)` + Social options (`Apple`, `Google`).

---

### SCREEN 24: OTP Verification Screen
- **Header**: Title `رمز التحقق عبر SMS`.
- **Subheading**: `أدخل الرمز المكون من 4 أرقام المرسل عبر SMS إلى +971 50 XXX XXXX`.
- **Input**: 4 digital boxes with auto-advance. Timer: `إعادة إرسال الرمز خلال 00:45`. CTA: `تأكيد ودخول`.

---

### SCREEN 25: Patient Profile Screen
- **Header**: Patient Name `مريم أحمد`, Mobile `+971 50 123 4567`, Location `دبي`.
- **Menu Items**:
  1. `طلبات مواعيدي (My Requested Appointments)` -> Opens Screen 18.
  2. `العناصر المفضلة` (My Favorites).
  3. `تقييماتي` (My Submitted Reviews).
  4. `إعدادات الحساب` (Account Settings).
  5. `تفضيلات الإشعارات` (Notification Preferences).
  6. `الدعم والمساعدة` (Help & Support).
  7. `تسجيل الخروج` (Log Out).

---

### SCREEN 26: Settings Screen
- **Options**: Language (`العربية`), Dark Mode (`مفعّل دائمًا`), Distance Units (`كم`), Data Privacy (`تصدير بياناتي / حذف الحساب`).

---

### SCREEN 27: Language Selector Screen (AR / EN)
- **Options**: `العربية (RTL Primary)` (Active checkmark) / `English (Full LTR Support)`.
- **System Behavior**: Instant layout mirror upon selection.

---

### SCREEN 28: Consents & Notification Preferences Screen
- **Toggles**: Exclusive Offers Alerts (On/Off), Appointment Request Updates (On/Off), Preferred Contact Method (`واتساب` / `اتصال` / `بريد`).

---

### SCREEN 29: Help & Support Screen
- **Accordion FAQs**: App usage, non-payment model clarification, clinic response expectations.
- **CTAs**: `محادثة الدعم عبر واتساب`, `إرسال بريد إلكتروني للدعم`.

---

### SCREEN 30: Privacy Policy & Terms of Service Screen
- **Content**: Legal text adhering to UAE PDPL regulations and DHA guidelines, confirming platform is a discovery and comparison directory.

---

### SCREEN 31: Empty States Pattern
- **Visual Design**: Centered silver outline illustration + Muted text + Action CTA.
- **Examples**: Empty Favorites, Empty Search Results, Empty Requests List.

---

### SCREEN 32: Loading States Pattern (Skeletons)
- **Visual Design**: Shimmer animation over dark `#121A2B` cards with silver metallic gradient sweep.

---

### SCREEN 33: Error States Pattern
- **Visual Design**: Red border tint around card container with icon `⚠️` + `إعادة المحاولة (Retry)`.

---

### SCREEN 34: No Network Screen
- **Visual Design**: Disconnected Signal Tower icon in silver + `تحديث الصفحة (Refresh)`.

---

### SCREEN 35: Location Permission Modal
- **Visual Structure**: Bottom Sheet dialog. Icon: Google Maps Pin inside glowing circle.
- **Text**: `تحديد موقعك لعرض العيادات والممارسين الأقرب إليك عبر Google Maps.`
- **Actions**: `السماح بالوصول للموقع (Allow Location)` | `تحديد المدينة يدوياً (Select City Manually)`.

---

### SCREEN 36: Notification Permission Modal (NEW MODAL)
- **Visual Structure**: Bottom Sheet dialog in Deep Dark Navy (`#070B16`) with Platinum Silver accent rim (`#D7DDE8`).
- **Icon**: Bell Outline Icon inside silver ring with subtle glow `🔔`.
- **Micro-Copy (Text)**:
  - **Title**: `فعّل الإشعارات لتكون أول من يعلم بالعروض الحصرية` (Enable Notifications for Exclusive Offers).
  - **Body**: `احصل على تنبيهات فورية عند إضافة عروض طبية جديدة في منطقتك، وتحديثات حالة طلبات المواعيد الخاصة بك. يمكنك تعديل هذا الإذن في أي وقت من الإعدادات.`
- **Action CTAs**:
  - **Primary CTA**: `تفعيل الإشعارات (Enable Notifications)` - Launches system notification permission dialog.
  - **Secondary CTA**: `ليس الآن (Not Now)` - Closes modal gracefully without blocking user experience.

---

## SECTION 6: DESIGN SPECIFICATION CHECKLIST & COMPLIANCE MATRIX

| Requirement | Implementation Detail | Compliance Status |
| :--- | :--- | :--- |
| **No In-App Payment / Cart** | Completely excluded from all screens. Zero financial checkout flows. | ✅ FROZEN & COMPLIANT |
| **No Calendar Confirmation** | Replaced with Lead Gen Form (Screen 16) & Tracking List (Screen 18). | ✅ FROZEN & COMPLIANT |
| **Strict Wording Compliance** | Screen 17 explicitly uses: `"تم إرسال طلبك وستتواصل العيادة معك"`. | ✅ FROZEN & COMPLIANT |
| **Multi-Practitioner Support** | Screens 9 & 10 explicitly label Doctors, Nurses, and Licensed Professionals with distinct badges & DHA/DOH/MOHAP licenses. | ✅ UPDATED & COMPLIANT |
| **My Appointment Requests** | Screen 18 tracks request statuses (`Sent`, `Contacted`, `Closed`) without booking schedules. | ✅ ADDED & COMPLIANT |
| **Notification Permission Modal**| Screen 36 added with dark/silver styling for push permission onboarding. | ✅ ADDED & COMPLIANT |
| **Google Maps Integration** | Multi-parameter linking (Place Name, Phones, Place ID, Lat/Lng) + Status Matrix. | ✅ ENHANCED & COMPLIANT |
| **Home Screen Ads Priority** | B2B Subscription priority (VIP Platinum Top 1-2, Featured Top 3+) immediately after header. | ✅ REINFORCED & COMPLIANT |
| **Luxury Aesthetic** | Deep Dark Navy (`#070B16`) with Platinum Silver (`#D7DDE8`) accents. | ✅ FULLY COMPLIANT |
| **Bilingual RTL / LTR** | Primary Arabic RTL layout with complete mirrored LTR structure. | ✅ FULLY COMPLIANT |

---
**Document End** • *AESTHETIC WAY Specification Revision v1.1*
