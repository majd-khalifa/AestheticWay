---
name: strict_project_rules
description: Strict architectural and UI/UX boundaries for AESTHETIC WAY.
---

# Strict Architectural & UI/UX Verification Rules

All agents and developers working on the AESTHETIC WAY project must enforce these 7 inviolable rules:

1. **Global Codebase Audit Mandate**:
   - Never modify only a single screen when a global architectural or UI rule is requested.
   - Always run exhaustive `git grep` searches across `lib/` to locate, audit, and update every occurrence across Customer App, Clinic Portal, and Super Admin modules.

2. **Zero Raw Image URL Inputs**:
   - Zero raw image URL text fields (`https://...`, `Image URL`, `URL الصورة`) anywhere in the UI.
   - All image selections (avatars, clinic logos, clinic covers, treatment photos, product photos, article covers, offer banners) must use `LuxuryImagePickerField` (Camera & Gallery upload).

3. **Zero Regulatory License Fields in UI**:
   - Completely remove and prohibit regulatory license inputs and display badges (`license_number`, `DHA`, `DOH`, `MOHAP`, `ترخيص معتمد: ...`) from all user-facing interfaces (Customer App, Clinic Portal, and Super Admin).
   - Medical professionals are presented cleanly as Doctor / Nurse / Licensed Professional without regulatory license registry numbers.

4. **Products Architectural Pivot (Cosmetic Brand Showcase Only)**:
   - Products are brand advertisements/showcases, NOT clinic e-commerce inventory.
   - Zero prices (`AED`, `price`), zero cart, zero checkout, zero purchase buttons, and zero direct booking buttons on products.
   - Allowed interactions: Brand/product details showcase and general lead inquiry.

5. **Appointment/Lead Requests Are Inquiry-Only (Zero Scheduling Clutter)**:
   - Leads collect ONLY patient name, phone number, optional service/practitioner, and inquiry notes.
   - Zero calendar pickers, zero date selectors, and zero time-slot grids in lead submission forms.
   - Final appointment scheduling is handled directly by clinic reception via phone/WhatsApp after lead submission.
   - Mandatory success confirmation text: `"تم إرسال طلبك وستتواصل العيادة معك"`.

6. **Referral System is Strictly Link-Based & Points-Driven**:
   - Zero manual referral code text inputs (`كود الدعوة`) in registration/login forms.
   - Zero legacy coupon code chips or manual voucher entry strings (`AW-15-...`).
   - The referral mechanism operates exclusively through the Unified Invite Link (`https://aestheticway.ae/invite/...`) and the Member Network Points & Milestones tiers.

7. **Unified Phone Input Across All Screens**:
   - Every phone input must use `LuxuryPhoneInputField`.
   - Defaults to UAE (`🇦🇪 +971`) with GCC/international country code selector.
   - Forces LTR text direction (`TextDirection.ltr`) to eliminate number inversion in RTL mode.
   - Restricts local input to digits only with a maximum of 10 digits (`maxLength: 10`).
   - Automatically sanitizes leading zeros upon submission (e.g., `0501234567` becomes `+971501234567`).
