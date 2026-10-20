# Super Admin Portal — implementation audit and delivery report

Date: 20 October 2026. Repository: `majd-khalifa/AestheticWay`.
Integration branch: `codex/frontend-audit-scale-ui-20261019`; PR #4 is mirrored on `codex/super-admin-production-hardening`.
Implementation baseline: `c6fe01dfc16c0409c0766769cf51505b579cd85f`.

## Outcome and evidence boundaries

The frontend now waits for verified server mutation results, distinguishes unknown moderation state from Active, uses genuine locations without Dubai coordinate fallbacks, keeps lead supervision read-only, and presents products as brand showcases. The ten original Admin screens and a new read-only treatment-category directory have been refined using shared, responsive components and the existing repositories, navigation, paging and authentication architecture.

This is a frontend implementation, not a claim of production deployment. Django sources, migrations, permissions and storage configuration were not modified. The inspected latest backend reference proves several server contract gaps. Their safe frontend behavior and exact bilingual implementation handoff are in [SUPER_ADMIN_BACKEND_GAPS_FOR_ALI.md](SUPER_ADMIN_BACKEND_GAPS_FOR_ALI.md). Interactive Admin map writes, complete offer/article server search and reliable status on fresh unfiltered moderation reads remain dependent on that handoff.

The working tree was clean before this task. The baseline was actually run: **262 Flutter tests passed; analysis reported zero issues**. Every Admin source file, the relevant shared infrastructure, tests, repository documentation and both read-only backend references were inspected before implementation. Supplied documents were treated as evidence except the pasted execution request explicitly identified by the user as instructions.

## Verified defects and implemented behavior

| Priority | Root cause / previous behavior | Implemented correction and principal source |
| --- | --- | --- |
| P0 | Clinic/content mutations changed local records optimistically, caught network failures and could return success anyway. | `admin_portal_service.dart`: confirmed writes only, per-entity pending guards, matching `new_status` and entity-ID verification, error preservation and no production mock-success fallback. Failure retains accurate records. |
| P0 | Missing coordinates were converted to `25.2048,55.2708`, potentially navigating to an unrelated Dubai location. | `admin_clinic_model.dart`, `clinic_location.dart`, `maps_launcher.dart`: validate actual coordinate pairs/ranges/finite values; reject `(0,0)`; use real clinic/active branch data or recognized stored Google Maps links; disable navigation when unavailable. |
| P0 | Public content serializers omit status; unfiltered Admin rows could appear Active by default. | `admin_repository.dart`: explicit Unknown state; infer state only from an exact server status filter. Moderation cards offer explicit confirmed actions for Unknown. The missing private response field is handed to Ali. |
| P0 | Password reset invented `AW#TempPass123!` if the server omitted its secret. | `admin_password_reset_dialog.dart`, `admin_clinic_editor.dart`: show only returned credentials; an absent secret gets an honest warning. Clear/dispose password controllers, avoid logs/analytics, stop the saving spinner before credential handoff. |
| P0 | Nested Admin routes could remain visible after changing account/role. | `guest_auth_guard.dart`, `admin_main_nav_screen.dart`: clear account caches on identity/role change, invalidate late writes, guard manager operations and remove nested Admin routes when the authenticated role changes. Server permissions remain authoritative. |
| P1 | Clinic detail was stale/stateless and activation could default to true from absent analytics information. | Canonical detail GET/cache, loading/retry, real clinic status, stateful detail screen and cache refresh after successful edits. Consequential suspension requires confirmation. |
| P1 | `areaEn/areaAr` aliased city; cards concatenated identical labels. | A shared locale-aware formatter deduplicates case/space/Arabic city aliases, retains distinct real areas and shows an honest empty location. Admin and the shared Clinic Portal location summary use it. |
| P1 | Dashboard captions mixed unrelated patients/events and featured clinics/offers; the active clinic label was misleading. | Six independent metrics with real labels, including Active Clinics and Total Offers. Contacted uses `leads_by_status['contacted']`, never an inferred appointment count. Safe zero-denominator closure rate. |
| P1 | Shared Leads collection could make dashboard recent activity inherit a clinic/status/search filter. | Independent global recent snapshot; reuse the unfiltered page request when possible, otherwise fetch a separate unfiltered snapshot without resetting the Leads tab. |
| P1 | Redeemed Codes metrics surfaced the retired coupon architecture. | Removed rendered redemption metrics and their Admin localization keys; integrated existing `GET admin/analytics/referrals/` for successful invites and positive awarded points. No fabricated milestones or coupon workflow. |
| P1 | Tier filtering operated on already loaded clinics. | Server-side `tier/status/search` where supported, 20-item pages, shared 350 ms debounce, query invalidation, deduplication and retained filter state on refresh. |
| P1 | Backend moderation search applies `name_en/name_ar` to Offer and Article, which only have title fields. | Avoid the proven failing search request. Offer/article search explicitly searches loaded content, with further pages still reachable. Product server search covers real product/brand/sponsor fields. Full search repair is specified for Ali. |
| P1 | Changing subscription tier silently toggled independent home-page featuring. | Shared clinic editor has separate subscription and home-placement controls. Neither activation nor home placement is derived from the tier. |
| P1 | International phone prefixes could be reinterpreted, and national zero handling was UAE-centric. | Shared phone component preserves explicit `+44` and other international prefixes, accepts `00` international notation, applies relevant trunk-zero rules and preserves meaningful Italian/San Marino zeros. UAE default, all 22 Arab countries and European selections, LTR, digits only and max 10 national digits. |
| P1 | Lazy form fields could unmount before `Form.validate()`, allowing missing offscreen required data. | Whole-controller validation before writes, plus ordinary field validation. Provisioning requires real clinic name, official phone, administrator identity/phone and a valid temporary password. Optional email/WhatsApp validate when present. |
| P1 | Replacing/clearing media could lose existing image selection or update cache before persistence. | Explicit omission vs null, native Camera/Gallery at 1200 / quality 78, immediate local preview, contain-fit logos, clear removal menu and session-local media cache updates only after acknowledged saves. Existing shared media builder remains authoritative. |
| P1 | Fixed form heading could overflow above a keyboard on a narrow phone. | Heading and fields scroll together, Save remains pinned above keyboard/safe area. Modal stays open with inline errors and disables duplicate writes/dismissal during saving. |
| P1 | Leads used Arabic names in English mode and missing dates could become the current time. | Locale-aware actual clinic/relation names, honest fallback to available source text, nullable historical dates, LTR international phone and retained notes. No lead status/contact/scheduling actions. |
| P1 | Analytics single-line KPI labels clipped; partial clinic directory counters were mixed with period analytics. | Adaptive, variable-height metric cards without KPI ellipsis. Display real period totals and actual top-10 event ranking; optional verified Arabic/tier metadata only. Zero remains zero. |
| P1 | Product cards looked like shopping inventory; legacy positive prices could re-enter mutation serialization. | Brand/sponsor/image-first showcase cards, secondary clinic attribution, no product prices/contact/buy controls; `toPortalJson()` omits legacy price. Shopping-bag iconography removed at all affected product entry points. |
| P1 | Bottom navigation/FAB could obscure the final content; rapid back handling relied on wall-clock time. | Reserved scroll padding, safe bottom navigation, lazy retained tabs, accessible semantic labels, back-to-Dashboard first and a cancellable two-second timer for exit. |
| P2 | Dense cards, heavy VIP shadows, weak theme contrast, large blank media areas and inconsistent labels. | Shared status/notice/metric/directory components, compact media panels, readable Edit actions, consistent Basic/Featured/VIP Platinum terminology, localized moderation copy and native 48-pixel image replacement controls. |

The apparent historical alias `scheduled_leads` was checked against `AdminDashboardAPIView`: the source explicitly populates it from contacted status. The frontend still reads the canonical `leads_by_status['contacted']` so a divergent legacy alias cannot mislabel the metric. `total_offers` counts all nondeleted offers, while `featured_clinics` counts Featured/VIP subscription tiers rather than independent homepage placement. Neither is mislabeled.

## Screen and interaction coverage

- **Dashboard:** accurate independent metrics, real recent requests, reachable supervision notice and working quick actions.
- **Clinics:** searchable/paged server-tier directory, nonduplicated location, image/brand fallback, explicit status/tier, compact counters, reachable Add Clinic and confirmed activation/suspension.
- **Clinic detail:** canonical refresh/retry, clear management controls, safe maps, actual metrics/branches and paged associated offers. No regulatory UI.
- **Create/edit:** one stateful editor owns/disposes controllers; native logo/cover selection, contact validation, city/address fields, independent subscription/home flag, safe keyboard layout, inline errors, server-confirmed close and secure credentials. Existing empty city is retained rather than replaced by Dubai during editing; changing city does not overwrite a distinct stored emirate unless the city selection changes.
- **Leads/detail:** compact server filters, real localized names, references/submission times/notes and supervision notices. No status mutation, calling, WhatsApp or follow-up tools.
- **Moderation:** coherent Offers/Products/Articles layout, real media, accurate state, pending/error feedback and read-only content inspection inside Admin. Offer pricing remains offer-only and localized. Product brand/sponsor values are never invented. CMS spelling and unusual names are preserved.
- **Analytics:** wrapped labels, actual reporting period, genuine event ranking and invite/points statistics. Unknown per-clinic metadata is not manufactured from partially loaded lists.
- **Navigation/settings:** five existing tabs retained, lazy mounting/state retention, safe back behavior, no cross-role preview, actual signed-in account details, theme/language controls and logout.

## Architecture and design decisions

1. **Reuse existing contracts.** Kept Dio, shared 401 refresh protection, `PagedCollection`, `LazyTabStack`, shared image components, token-based roles, repositories and services. No new dependency or invented endpoint was added.
2. **Confirmed state is authoritative.** Entity-level guards allow unrelated operations without duplicate writes to one entity. Session epochs reject late results. Known moderation responses are kept in the current view instead of immediately replacing them with an unfiltered GET that omits status. A later fresh unfiltered read honestly shows Unknown until Ali adds that field.
3. **API capability limits are visible.** Read support does not prove write support. The Admin editor saves address text but does not send coordinates ignored by the current write serializers. Existing interactive location selection will be wired after a verified server deployment. The user is not shown a fake successful pin save.
4. **Media ownership is unchanged.** Native uploads use the existing `MediaPayloadBuilder` multipart/pre-upload policy. Omission keeps an image; explicit null removes it. A cache is session-local rendering continuity, not proof of durable storage. Ali must repair custom-CDN URL stripping and validate fresh-client persistence; private signed URLs require durable storage identity and fresh read URLs.
5. **Responsive layout uses content height.** Metrics wrap without truncation, form sections scroll and actions have safe-area spacing. Four widths, both languages/themes and increased text scale are exercised. Navigation labels inherit theme typography.
6. **Accessible luxury tokens.** Navy uses `#070C1A`; selected dark-theme gold uses `#D4AF37`. Existing darker light-theme gold text (`#806615`) is used where the requested `#9A7B1C` would not consistently reach 4.5:1 on all pale surfaces. Status foreground/background contrast is tested after theme animation settles. Tier badges avoid heavy shadows.
7. **Global boundary changes stay small.** Shared phone/media/location fixes support Admin and existing callers. Product entry-point icon changes across Patient/Clinic screens are narrowly scoped to showcase semantics. No unrelated application rewrite was performed.

First-install defaults remain the existing English LTR and Soft Light Luxury; Arabic RTL and dark navy are supported. No payment, cart, checkout, scheduling, home-service, license-authority, raw-image-URL, manual referral-code, voucher-redemption or patient-preview flow was introduced. The mandatory lead confirmation remains exactly `تم إرسال طلبك وستتواصل العيادة معك`.

## Verified backend dependencies and remaining limits

| Capability | Current frontend | Ali / later integration requirement |
| --- | --- | --- |
| Admin coordinate writes / branch map representation | Save supported text addresses; read real coordinates/Google Maps links; disable unavailable map actions. | Add validated paired location writes to provisioning/update serializers, persist clinic/main-branch location and expose branch coordinates. Then wire interactive Admin selector after staging verification. |
| Moderation state on fresh GET | Unknown when absent; exact filtered state or matching POST acknowledgement only. | Private Admin serializers must return real status; keep public serializers separate. |
| Complete Offer/Article search | Explicit loaded-content search; Load More remains available. | Repair title-aware model search, clinic attribution and stable unique ordering. Then enable server search in Flutter. |
| Full bilingual lead entities | Genuine available name/title with source fallback. | Add Arabic relation fields to the existing read serializers; no lead workflow write permission. |
| Analytics ranking metadata | Actual top-10 event counts; optional returned name/tier only. | Optional additive bilingual name/tier metadata. This is not a full paginated per-clinic engagement report. |
| Custom CDN / mixed replace-remove media persistence | Native multipart and existing shared pre-upload flow, acknowledged local cache only. | Preserve absolute media URLs and signed query bytes; validate durable storage identity and returned URL from a fresh authenticated client. |

These findings are source-verified, not live-server failures reproduced with production credentials. No authenticated Super Admin JWT was supplied, no production data was altered and no backend deployment occurred. Physical-device camera behavior, external map launch, platform font rendering, real storage/CDN lifecycle, release APK/IPA performance and screen-reader interaction still require device/staging acceptance. Headless widget renders are not production screenshots.

## Additional requirements — preserved history and supported catalog scope

The full Clinic Portal commit `c6fe01dfc16c0409c0766769cf51505b579cd85f` is an ancestor of both the previous Admin commit `15f6709` and the final integration history. The requested status/branch/log/ancestor checks passed before this addendum. The local Clinic Portal branch was fast-forwarded from `c6fe01d` to the existing tested Admin commit, preserving all earlier files without conflict or reset. No previous audit or implementation was restarted. The final normal push updates the preferred Clinic Portal branch and mirrors the same commit to the existing PR #4 head; `main` is never updated.

- **Independent brand products:** inspected Django has global read/moderation only. Its product model can already represent `clinic=None` with an English brand or sponsor, but no Admin POST/PATCH/DELETE mappings exist. Clinic portal writes select a clinic, including a first-clinic fallback for Super Admin; they are not used. Add/Edit/Archive controls are explicitly unavailable; inspection and real confirmed publication moderation remain usable. There is no unsupported write or pretend native editor. The exact proposed private serializer, multipart/platform media UUID handling, ownership restrictions, soft archive, audit and routes are in Ali's sections 7–8. After deployment the editor must use `LuxuryImagePickerField` and the specified bilingual/brand/sponsor fields, without prices or clinic assignment.
- **Categories:** the new `AdminCategoriesScreen` reuses `CategoryRepository`, `CategoryModel`, `PagedCollection` and Admin shared components for verified active treatment-category GET/search/paging. It never instantiates ClinicPortalService or calls clinic category write fallbacks. It exposes readable scope/unavailable states with disabled create/edit/delete controls, failure/retry and role/session invalidation. No public response proves write capability. Cosmetic brand categories have no model/API in the archive and are clearly separate; Ali has an explicit proposed schema/migration and private CRUD pattern, with protective deletion semantics.
- **Contextual AppBar:** Dashboard / Partner Clinics / Leads Supervision / Catalog & Moderation / Platform Analytics, localized in Arabic and English. Titles wrap within a text-scale-aware toolbar rather than inheriting the generic portal title or clipping at large text.
- **Clinic Offers section:** a pinned heading/close control and View clinic offers shortcut lead to a fully reachable Offers heading. One bounded scroll viewport, a shared controller/scrollbar, bottom spacing and a genuine empty state replace the orphaned heading at the bottom. Embedded offers still build at most six previews and retain paged View All behavior.

Nine additional automated cases cover both localized contextual title sequences, category read payloads, server search/debounce/paging, unavailable writes, load retry, late role-change completion, unsupported product authoring and reachable loaded/empty Offers sections. The 16 existing responsive cases now include the eleventh screen. Current full CRUD is **not claimed**: Ali must deploy the new write contracts, after which a Flutter editor integration is still required. No automatic capability probing or speculative endpoint call is shipped.

## Regression protection and validation

Added `test/admin_hardening_test.dart`: **59 focused unit/widget tests**, including 16 width/theme/language matrix cases. Each matrix case renders all eleven Admin screens at 1.4 text scale, for 176 screen-layout checks in addition to interaction tests.

Coverage includes safe coordinates/maps/location deduplication; missing dates; canonical KPI/zero mapping; brand and sponsor display; no rendered redemption/product pricing; query mappings; genuine server filtering across unloaded records; 350 ms debounce/page size; confirmed clinic/content mutation success/failure/duplicates; incorrect acknowledgement rejection; role/session invalidation; media cache success/null/omission; native camera/gallery settings and local preview; international phone zeros/prefixes; tier/home independence; failed edit modal retention; offscreen form validation; provisioning wait/credentials; password reset; reachable FAB/footer; role changes through nested routes; double-back timeout; keyboard/safe area; and global dashboard activity independent of Leads filters.

Existing tests were retained. Changed expectations reflect corrected semantics: Total Offers instead of falsely Active Offers; Active Clinics instead of Partner Clinics for the active count; no regulatory section; the actual existing moderation fixture ID; no fallback Dubai text; consistent VIP naming; nullable timestamps; international phone labels rather than UAE-only wording; and omission of legacy product price from mutation serialization. No valid business assertion was removed to conceal a failure.

Final quality gates actually executed:

| Gate | Result |
| --- | --- |
| Baseline `flutter analyze` / `flutter test` | Zero issues / 262 passing tests. |
| `dart format .` | Completed successfully; 178 Dart files checked. Unrelated formatting-only diffs restored. |
| Final `flutter analyze` | **No issues found**. |
| Final `flutter test` | **321 passed, 0 failed, 0 skipped** (262 baseline + 59 Admin tests). |
| `git diff --check` | Passed. |
| Read-only backend SHA-256 comparison | Original **622/622** and latest **636/636** files identical to the pre-edit snapshot. |
| Django handoff probe | Passed the serializer/query/media checks described below; zero DB writes. |

The final full suite includes Patient Portal, Clinic Portal, Admin, media/network/session, paging and layout regressions. No new code changes were made after these passing gates.

Additional evidence:

- Read-only Django probe parses 17 Python blocks and validates 9 location cases, 3 private inspection serializers, 3 search query compilations and 4 media input cases, including signed URL round-trip. The catalog addendum also validates 15 independent-product input cases, native ImageField and platform MediaUploadSerializer inputs, platform asset queryset scope and 3 treatment-category serializer cases. **Zero database writes.** This checks serializer/query examples against the actual latest source; it is not a full DRF/deployment integration test.
- 36 headless preview PNGs rendered from synthetic test fixtures: nine views × English/Arabic × light/dark. Fonts were supplied for inspection; fixtures deliberately include zeros and absent maps. Four preview-render cases passed. The scratch renderer is not shipped as an application/test dependency.
- `dart format .` was run. Formatting-only changes to 42 previously untouched files were restored, preserving unrelated project files; touched implementation/test files remain formatted.
- Backend integrity was verified against the original file-by-file SHA-256 snapshot: all 1,258 reference files are unchanged. Git delivery is described below.

## File manifest

The following paths are the complete task diff from the clean implementation baseline. Prior Clinic Portal work already present in baseline `c6fe01d` is preserved. Shared changes outside Admin are listed explicitly.

- `docs/SUPER_ADMIN_BACKEND_GAPS_FOR_ALI.md`
- `docs/SUPER_ADMIN_PORTAL_AUDIT_REPORT.md`
- `lib/core/auth/guest_auth_guard.dart`
- `lib/core/localization/app_locale.dart`
- `lib/core/network/api_config.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/utils/clinic_location.dart`
- `lib/core/utils/maps_launcher.dart`
- `lib/core/widgets/luxury_image_picker_field.dart`
- `lib/core/widgets/luxury_phone_input_field.dart`
- `lib/core/widgets/remote_catalog_preview.dart`
- `lib/core/widgets/tier_badge.dart`
- `lib/features/admin/data/admin_repository.dart`
- `lib/features/admin/models/admin_analytics_model.dart`
- `lib/features/admin/models/admin_clinic_model.dart`
- `lib/features/admin/models/admin_dashboard_model.dart`
- `lib/features/admin/models/admin_lead_model.dart`
- `lib/features/admin/presentation/screens/admin_analytics_screen.dart`
- `lib/features/admin/presentation/screens/admin_categories_screen.dart`
- `lib/features/admin/presentation/screens/admin_clinic_detail_sheet.dart`
- `lib/features/admin/presentation/screens/admin_clinics_screen.dart`
- `lib/features/admin/presentation/screens/admin_create_clinic_dialog.dart`
- `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`
- `lib/features/admin/presentation/screens/admin_lead_detail_screen.dart`
- `lib/features/admin/presentation/screens/admin_leads_screen.dart`
- `lib/features/admin/presentation/screens/admin_main_nav_screen.dart`
- `lib/features/admin/presentation/screens/admin_offers_screen.dart`
- `lib/features/admin/presentation/screens/admin_settings_screen.dart`
- `lib/features/admin/presentation/widgets/admin_clinic_editor.dart`
- `lib/features/admin/presentation/widgets/admin_components.dart`
- `lib/features/admin/presentation/widgets/admin_password_reset_dialog.dart`
- `lib/features/admin/services/admin_portal_service.dart`
- `lib/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart`
- `lib/features/clinic_portal/presentation/screens/clinic_profile_screen.dart`
- `lib/features/clinic_portal/presentation/widgets/clinic_location_selector.dart`
- `lib/features/home/presentation/widgets/category_grid.dart`
- `lib/features/navigation/main_nav_screen.dart`
- `lib/features/products/models/product_model.dart`
- `lib/features/products/presentation/screens/products_screen.dart`
- `lib/features/products/presentation/widgets/product_inquiry_bottom_sheet.dart`
- `lib/features/treatments/data/category_repository.dart`
- `test/admin_hardening_test.dart`
- `test/admin_portal_api_test.dart`
- `test/admin_portal_test.dart`
- `test/aesthetic_way_test.dart`
- `test/clinic_onboarding_and_provisioning_test.dart`
- `test/clinic_portal_polish_test.dart`
- `test/products_articles_live_test.dart`

## Delivery and review risks

The final preferred branch is `codex/frontend-audit-scale-ui-20261019`. It contains the exact Clinic Portal commit `c6fe01d`, all completed Admin work in `15f6709` and this addendum. The same final commit is mirrored to `codex/super-admin-production-hardening`, updating [PR #4](https://github.com/majd-khalifa/AestheticWay/pull/4) against `main`. Both pushes must be fast-forward-safe; no force flag, main update or PR merge is authorized/performed.

`origin/main` was fetched and remains `ce4442d`. The cumulative PR includes earlier Clinic Portal work plus the Admin task. Review this complete task against `c6fe01d` for the manifest above and the PR against `origin/main` for the cumulative preserved work. Final commit SHA, matching remote tips, test results and clean Git status are reported in the delivery message.

Review the shared phone parser against any additional country-specific numbering plans supported by the product; the mandated 10-national-digit limit is enforced even where a real country can issue longer numbers. Review production storage and permissions in Ali's staging environment, not through Flutter mock fixtures. Offset paging over concurrently changing datasets retains normal offset movement limitations; the handoff adds unique sort tie-breakers and does not pretend to supply snapshot isolation.

No backend source, migration or deployment configuration was edited. No force push or merge is part of this delivery. The exact implementation commit title is `fix(admin): harden super admin portal and refine luxury UX`.
