# Store publication worksheet — owner review required

> Update: self-service deletion and category contracts now exist in supplied backend 1f1e4bf. Use [the consolidated report](FINAL_BACKEND_INTEGRATION_REPORT.md) and [current handoff](FINAL_INTEGRATION_BACKEND_HANDOFF_FOR_ALI.md) for current availability and remaining gates; original release/declaration evidence below remains historical.

This is a preparation worksheet, not a submitted declaration. Audit date: 23 October 2026. No console access, legal/operator approval or production data inventory was supplied. Fill the remaining items from actual operations; never invent contact details, legal entities, ratings, reviews, credentials or medical outcomes.

## Listing drafts

| Field | Draft / owner action |
|---|---|
| App name | Aesthetic Way (confirm registered branding and exact legal developer display name). |
| Play short description | Discover UAE aesthetic clinics and send consultation requests. |
| Apple subtitle | Clinics and consultation |
| Main category | Evaluate Medical against actual discovery/lead features; select the matching console category, not a medical-device classification without evidence. |
| English description draft | Discover aesthetic and dermatology clinics in the UAE. Explore clinic information, medical staff, treatments, offers, cosmetic brand showcases and articles. Send a consultation inquiry and follow its status. The clinic contacts you directly to coordinate your consultation. Browse in English or Arabic with Light and Dark appearance options. |
| Arabic description draft | اكتشف عيادات التجميل والجلدية في دولة الإمارات. تعرّف على معلومات العيادة والكادر الطبي والعلاجات والعروض والعلامات التجميلية والمقالات. أرسل طلب استشارة وتابع حالته، وستتواصل العيادة معك لتنسيق الاستشارة. تصفّح بالعربية أو الإنجليزية مع المظهر الفاتح أو الداكن. |
| Privacy URL | `https://aestheticway.ae/privacy/` exists in source; verify live unauthenticated HTTPS HTML before using in consoles. |
| Support / Terms | `/contact/` and `/terms/` exist in source; confirm public deployment and monitored support email. Never publish an unverified placeholder address/entity. |
| Account deletion URL | Dedicated verified resource pending; the current privacy page's support-request instructions may qualify as a web resource only if prominent, accessible, accurate and operational. Do not mark completed until tested and entered in Play Console. |
| Screenshots / feature graphics | Capture genuine release UI on the required phone/tablet sizes, both languages where appropriate; use only rights-cleared real media or the approved neutral artwork. Test fixtures, generated reference photos and fictional Google aggregates are not production store assets. |
| Ratings / audience | Complete current Play content rating, target audience and Apple's current age-rating questionnaire. Determine audience and cosmetic/medical content restrictions from the actual product; no final numeric age rating is fabricated here. |

Keep claims limited to discovery and inquiry coordination. No guaranteed clinical result, appointment confirmation, medical-device function, purchase, product price, cart or checkout is advertised. Public Featured Clinics may remain; no VIP/subscription-plan labels or regulatory registry fields are introduced to patients.

## Data inventory and declarations

Cover **all three roles**; the patient experience alone is not the whole application. Server-side behavior and third-party processors matter even when no advertising SDK is installed.

| Data / observable flow | Use / collection considerations | Owner must confirm |
|---|---|---|
| Account UUID, role, name, phone, optional email | Authentication, profile, OTP/account support. JWT/profile cached in protected device storage. Identifiers are linked to account. | Actual retention, deletion, SMS/email processors, server/IP logs and every purpose. |
| Consultation destination, selected service/practitioner, contact details, optional notes | Sent over HTTPS to API; selected clinic receives inquiry/contact information. Notes/service selections may reveal health information. | Clinic sharing/consent, health-data classification, retention and legal exceptions; backend analytics stores linked lead/service metadata. |
| Clinic/staff/catalog photos and selected video | User-selected Camera/Gallery uploads; associated role/entity and public catalog use. | Object-store/CDN processors, image rights/consent, publication review, deletion/backups. No random/generated record photos. |
| User content / profile/catalog text | Clinic/Super Admin content management; inquiry notes. | Which text is public versus private, moderation and erasure/anonymization. |
| App interactions / referrals / lead analytics | API endpoints and backend events record interaction/object/user linkage; referral link/points support. | Exact event fields, whether identifiers/health metadata are used for analytics, retention, processors; do not declare “no analytics” from lack of an analytics SDK. |
| Device/security/network metadata | HTTPS API/CDN, OSM tile requests and external Maps/WhatsApp/email services. | Server logs/IP/device tokens/diagnostics actually retained; notification device endpoints alone do not prove a client push implementation. |
| Location | Maps display **clinic** coordinates; no patient location permission/request found. | Do not declare precise patient location collected merely because clinics appear on a map; verify any server-side geolocation separately. |
| Payments / advertising IDs / tracking | No payment, IDFA/AD_ID, HealthKit/Health Connect, cross-app tracking or device-health measurement integration found in this Flutter dependency/source audit. | Commercial brand/clinic placements still mean advertising may be present. Confirm all external SDK/server behavior before selecting “No” in a store form. |

Google Data safety: map these to Personal info, Health info where applicable, Photos/Videos, App activity and relevant identifiers; distinguish required fields for a chosen feature from optional fields. Evaluate documented exceptions for user-initiated transfers/service providers before marking “shared.” The privacy policy must still explain delivery to the selected clinic. HTTPS in app is implemented; server encryption-at-rest, retention and verified deletion cannot be inferred from Flutter. Do not claim deletion is available simply because the app can open email.

Apple App Privacy: declare linked data and real purposes for authentication/app functionality, consultation and analytics, including server processing. The new `PrivacyInfo.xcprivacy` records observed app data categories and no tracking; it does not replace the console questionnaire or the aggregate privacy report from a signed archive. Verify collection/purposes against deployed backend and vendor policies before submission. Required-reason API declarations belong to code/SDKs that actually access them; no reason code is invented merely to silence validation.

### Health Apps Declaration

Complete the Health apps declaration in Play Console using the actual medical-clinic discovery and consultation-lead features. The app does not become exempt merely because it does not measure health with sensors. Policy requires a public, active, non-geofenced HTML privacy policy and accurate sensitive-data disclosure. Review any required non-device disclaimer and actual medical claims/content. Do not claim medical-device approval or add regulatory license/authority UI fields. Clinical advice/diagnosis/appointment coordination remains with clinic professionals.

### Ads, content and SDK obligations

Paid clinic/brand advertising placement exists internally even without an ad-network SDK. Evaluate the Play “contains ads” declaration accordingly; keep internal entitlements out of patient labels. Review commercial placement transparency with the owner without redesigning the approved interface.

All four resolved iOS plugins (`image_picker_ios 0.8.13+9`, `video_player_avfoundation 2.12.0`, `flutter_secure_storage 9.2.4`, `url_launcher_ios 6.4.1`) have source privacy manifests and support iOS 13 or lower. CI must verify those resources are actually packaged along with Flutter's framework manifest. Source-built plugins and binary frameworks have different SDK-signature responsibilities; inspect the final signed archive/Organizer privacy report, not just source files. No ATT prompt is added without an actual tracking use case.

## Restricted-area review access

Create privately managed, verified review accounts for **patient**, **clinic_admin** and **super_admin**; give the reviewer exact steps and expected role-specific destinations. Never put credentials in Git, screenshots, issues, logs, Dart constants or this document. Supply them only through the stores' private App Access/App Review Information fields. Ensure they remain valid throughout review, OTP challenges have an approved accessible process and no geographic/network restriction prevents review.

Suggested review notes (replace bracketed instructions privately):

1. Choose English/Arabic if needed. Guest browsing is available; use the privately supplied patient login for inquiry/history. Registration/OTP stays real; a verified review account avoids dependence on an inaccessible reviewer's phone.
2. Patient: inspect Home/Featured Clinics, Clinics, Products, Offers, Profile. Send a consultation only to the explicitly designated authorized QA destination; verify My Requests. No calendar or purchase is offered. Account settings expose policies and the currently support-assisted deletion request; full deletion remains a release blocker until backend completion.
3. Clinic Admin: sign out first, then use the privately supplied clinic-admin account. Confirm clinic dashboard, requests, authorized status transitions and role-scoped catalog/image upload. Provide rights-cleared approved records or an explicitly disclosed isolated QA dataset; never use unrelated patient data.
4. Super Admin: sign out, then use the privately supplied admin account. Describe Partner Clinics, Leads Supervision, Catalog/Moderation, Analytics and Settings. **Do not grant a reviewer global access to real patient PII.** A safe, explicitly disclosed review data scope/environment must be designed by the owner/backend team before sharing this role. Do not silently bypass auth, fake data or conceal/reconfigure features for review.
5. Explain upload/media permissions only when the reviewer invokes them; include reliable steps to reach camera/gallery, cancel and retry. No password/OTP should be sent to support or encoded into a URL.

Record account validity/allowed mutations, testing schedule, contact person, backend version and any necessary review-environment instructions privately. The backend currently grants broad super_admin authority; safe privileged review access is an owner/backend task, not solved by hidden reference labels.

## Publication owner checklist

- [ ] Signed AAB/IPA matches approved commit, identity, version and certificate; API 36/16 KB and Xcode 26 evidence reviewed.
- [ ] All P0 blockers in the release report are closed, including real deletion and public policy availability.
- [ ] Play App Signing/upload key and Apple team/provisioning are verified outside Git; no debug certificate or verification-only AAB is uploaded.
- [ ] Data safety, App Privacy, Health Apps, Ads, age/audience, support, export compliance and app-access declarations match deployed behavior.
- [ ] Real release-device matrix passes; genuine media/ratings and all three roles are checked with safe data.
- [ ] Closed testing account eligibility/tester requirements verified in the actual Play Console; TestFlight steps separately approved by owner.
- [ ] Store screenshots/graphics/media are real, current, rights-cleared and contain no real patient PII or fictional records.
- [ ] Owner gives a separate explicit publication instruction. This task neither publishes nor merges automatically.
