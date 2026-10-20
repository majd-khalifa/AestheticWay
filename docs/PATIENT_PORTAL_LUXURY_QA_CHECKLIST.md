# Patient Portal release acceptance checklist

2026-10-20. Automated Linux widget tests and synthetic previews support this checklist. **Android release APK and Windows device verification have not been performed.** Use staging fixtures and separate patient/clinic/admin accounts; never attach patient contact details or signed media tokens to bug reports.

## Preparation

- [ ] Install the release APK on a small Android phone and a larger phone. Test 320/360/390/430 dp equivalent widths, plus landscape and the largest supported system text setting.
- [ ] Fresh install opens English/LTR + Light. Saved Arabic/RTL, Dark and System preferences survive restart.
- [ ] Repeat the critical flows in English Light, English Dark, Arabic Light and Arabic Dark.
- [ ] Confirm backend build/version with Ali. Reference source is not proof of live deployment. Review `PATIENT_PORTAL_BACKEND_GAPS_FOR_ALI.md` before marking server-dependent acceptance complete.

## Screen inventory from the 19 supplied visual states

| State | Device acceptance |
| --- | --- |
| 01 Home featured | Actual eligible sponsored records in server order; no Basic filler. Ad tier does not overwrite clinic tier. Real media first; no giant decorative logo banner. Swipe, pause/resume and accessible indicator selection work. |
| 02 Clinics directory | Compact readable clinic identity, nonduplicated known location, genuine Google fields only. Long names wrap in the card. View, inquiry and valid contact actions remain visible. |
| 03 Products | One product is balanced; two/many products use responsive rows. Actual brand/sponsor is distinct from advertising clinic. Studio media uses contain. No price, AED, buy/cart or direct contact. |
| 04 Offers | Real banner when supplied, actual clinic and offer terms/prices, genuine expiry only. Inquiry preserves actual offer UUID and title. No coupon operation. |
| 05 Profile | Actual identity and verification basis only; readable contact text; requests/referrals/theme/language/support/privacy/sign-out usable without repetitive oversized sections. |
| 06 Referral | Authentic full LTR personal link, copy and WhatsApp share. Actual ledger balance, confirmed invitations and milestone flags. No code issuance, collection, redemption, voucher or 15% claims. |
| 07 Treatments empty | Published-empty state distinct from loading/error. Compact explanation and useful reload. Category shortcut never guesses a random category. |
| 08 Practitioners | Real photo/fallback, correct Doctor/Nurse/Professional type, actual specialty and clinic. Unknown types use neutral Practitioner. No invented rating/experience/qualification. |
| 09 Consultation with branches | More than one real branch offers a paged choice. Selected branch persists, including records outside initial summary. No duplicated picker borders/labels. |
| 10 Practitioner detail | Actual biography/procedures; clinic association verified through detail API. Failure disables inquiry and offers recovery. No synthetic clinic/phone/hours. |
| 11 Consultation without branches | Zero/single-branch workflows do not force a meaningless branch choice. Name, international phone, optional service/practitioner/notes and explicit consent remain usable above keyboard. |
| 12 Articles | Compact editorial cover, actual author/date/content. Missing media remains intentional; no fake author status. |
| 13 Article detail | Long Arabic/English text reads comfortably; no rewritten CMS content. Author navigation and consultation require actual matching practitioner/clinic. |
| 14 Directory from Home | Correct city/category context. Home search queries the full directory on submission. Ordinary category shortcuts switch existing tabs rather than stacking duplicates. |
| 15 Home clinic discovery | No “near you” or distance claim from city-only data. Same clinic card as directory; bottom navigation reserves content space. |
| 16 Filters | Content-aware height, keyboard avoidance, localized city and real searchable category. Reset/Apply work. No unsupported gender/distance/sort fields. |
| 17 Clinic About/Map | Actual cover/logo and description; hours omitted if unavailable. Google rating and map availability handled separately. No default Dubai destination or unsupported new-listing badge. |
| 18 Clinic Staff | Content height follows rows; published-empty is compact, failed fetch is retryable. Correct practitioner type. Further pages reachable. |
| 19 Clinic Offers | Natural content height; empty/error distinguished; offer inquiry retains actual offer context. Tabs horizontally scroll at larger text. |

## Connected flows outside the screenshots

- [ ] Product Detail: actual brand and sponsor only; advertising clinic secondary; optional general inquiry has no price/direct call/WhatsApp. Independent product inquiry sends product UUID without a fabricated clinic.
- [ ] Treatment Detail: retrieves the associated clinic directly, never the first clinic on a loaded page. Missing/failed association disables inquiry; retry recovers.
- [ ] My Requests: real personal records, pagination and status filters; error never becomes a fake empty history. Details, contact when supplied and return navigation work. Historical dates do not act as scheduling controls.
- [ ] Request success: only after confirmed save. Exact frozen Arabic text is **تم إرسال طلبك وستتواصل العيادة معك**. No slot/appointment confirmation promise. Genuine reference and timestamp; no random reference.
- [ ] Sign-in, registration, OTP, reset, profile edit: no guest or manual referral input; UAE default, country search, forced LTR, digits-only and maximum ten national digits. Existing `+44`, `+49`, etc. remain international after edit/submission.
- [ ] Patient login opens Patient; Clinic login opens Clinic; Super Admin opens Admin. No cross-role patient preview. Logout/session expiry clears account-specific caches and prevents late saves from showing another account's result.
- [ ] Bottom tabs remain exactly Home, Clinics, Products, Offers, Profile. Targets are at least 48 dp; OS back returns to Home then exits using the established behavior. Lazy mounting/state retention remain intact.
- [ ] General clinic contact sheet omits unavailable numbers/maps and does not show a fabricated distance. Phone dialer, WhatsApp and actual Maps app destinations work on device; no unsupported-OS failure traps navigation.

## Media and persistence acceptance with Ali

- [ ] Upload a clearly distinguishable logo/cover/photo through the native picker (camera/gallery, max width 1200, quality 78). Valid primary media takes precedence immediately.
- [ ] Save, close/reopen the screen, sign out/in, restart APK, then verify from a second device. Local optimistic cache alone is not proof of server persistence.
- [ ] Verify clinic logo uses contain, clinic/article cover uses cover, product uses contain; no stretching.
- [ ] Test relative Django path, first-party HTTPS, actual public CDN and valid signed CDN URL. Inspect via redacted staging diagnostics only.
- [ ] Expired signature, 403/404/500, HTML/empty/corrupt bytes show the appropriate fallback; a corrected URL recovers. A valid PNG still decodes even if the server MIME header is wrong, but Ali should correct the header.
- [ ] Changing a saved URL or replacing an uploaded image does not leave an older image from entity cache. Missing/deleted local files fall back to remote delivery.
- [ ] Test VIP video on Android release: muted playback, 15-second cap, lifecycle/tab/viewport pause, fallback on decoder/network error. No playback from offscreen/disposed slides.
- [ ] Re-run native Windows path/file-URI/asset decoding tests on Windows Flutter. Linux results do not certify Windows codecs/filesystem behavior.

## Reliability, accessibility and release sign-off

- [ ] Offline → error → retry recovers without an empty-content lie. Pull-to-refresh and keyboard dismissal work. Modal submission errors stay inline without covering actions.
- [ ] Fast typing/filter changes reset pagination and cannot display an old city's/search's records. Scroll through >40 records; 20 per page, no missing/duplicated IDs.
- [ ] Rapid double tap submits one lead. Reject consent/missing fields locally; 400/403/404/429 do not navigate to success. Signed-out/wrong-role/late-session submissions cannot proceed.
- [ ] TalkBack reads controls, Google source, selected navigation and ad indicators. Verify focus order, target size and Arabic/English number direction.
- [ ] No RenderFlex warning stripes, clipped card titles, hidden submit actions, low-contrast text or navigation overlap. Compare synthetic previews in `test/goldens/`, while allowing native font/OS rendering differences.
- [ ] Run `dart format .`, `flutter analyze` (zero issues), and the full `flutter test` suite including Clinic/Admin/core/Windows-path regressions.
- [ ] Record tested APK build/backend version, Android versions and unresolved dependencies. Keep private screenshots outside Git.
