# Flutter action plan — implemented work and explicit remaining gates

Date: 2026-10-31 (Asia/Damascus). Frontend base: **8f48a80c311080299591f4f51dc3141914d6fb5b**, verified current origin/main and PR #13 merge. Feature branch: **codex/super-admin-analytics-forensic-audit**. Backend archive commit stamp: **52666c1711469ec8a3689cf54f93c1c5fa963e6e**; provided source, **deployment unverified**. Django is read-only. Test fixtures and screenshots are not production evidence.

## Implemented in this branch

| Change | Actual implementation |
| --- | --- |
| Honest metric availability | `Flutter lib/features/admin/models/admin_analytics_model.dart:119` recordedCount preserves missing/null/invalid versus explicit 0; no total inferred from top 10. Dashboard and clinic lifetime Lead count availability also tracked. |
| Scope/definition copy | `Flutter lib/features/admin/presentation/screens/admin_analytics_screen.dart:17` says raw recorded activity, incomplete coverage, handoff attempts and non-unique totals. Saved Lead records, lifetime referral totals and selected-clinic lifetime count are distinctly labelled. Active patient accounts replace the misleading registered/active-usage implication. |
| Reporting period | `Flutter lib/features/admin/models/admin_reporting_period.dart:2` validates calendar dates/range and formats Dubai calendar dates. `Flutter lib/features/admin/data/admin_repository.dart:598` sends only supported date_from/date_to and rejects a mismatched or missing filter acknowledgment. No patient scheduling UI added. |
| Genuine daily series | Parses current daily_trends, bounded preview over actual returned dates only; no interpolation, invented unique users or growth percentages. |
| Race/session fixes | `Flutter lib/features/admin/services/admin_portal_service.dart:789` uses current-request generation, same-query in-flight dedupe and session epoch; stale data/errors cannot win. `Flutter lib/features/admin/services/admin_portal_service.dart:668` no longer fetches or resets the analytics period and cannot fail solely because analytics failed. |
| All-directory clinic inspection | Reuses the source-confirmed paginated/searchable non-archived admin directory, fresh verified detail, correct all-time count and record inspection. No new analytics route or clinic-owned impersonation is used. |
| True operational drill | `Flutter lib/features/admin/presentation/screens/admin_leads_screen.dart:15` carries clinic/date filters to existing admin/leads and owns its PagedCollection. Main Leads tab query is preserved; authorization/session changes clear pending private state. No patient data is put into analytics metadata. |
| Complete catalog searches | `Flutter lib/features/admin/presentation/screens/admin_offers_screen.dart:52` and AdminRepository forward Offer/Article as well as Product queries to supported server search across pages. Removed the stale repository suppression and live local filter that could hide opposite-language/clinic/author matches. Existing status filters and publication behavior remain. |
| Regression/render verification | `Flutter test/super_admin_analytics_forensic_test.dart:160` covers omissions, dates, response mismatch, top 10/global distinction, sparse trends, period races, in-flight/session behavior, independent overview, page 2 clinic selection, role denial, scoped drill and EN/AR Light/Dark layouts. |

## Not implemented or falsely claimed

- No client events are sent to the legacy unsafe ingestion contract. No undocumented POST, fake event ID ACK, retry loop or forged lead event was introduced.
- Complete per-clinic event metrics, unique users, date-filtered clinic summaries and comparable trend series require the PROPOSED server contracts. Current unavailable values are not displayed as 0.
- The selector covers the default non-archived directory, not an archived historical analytics backend that does not yet exist. Existing include_deleted is a known frontend follow-up requiring consistent list/detail semantics.
- Global brand-product authoring/archive and brand category management remain missing frontend tools despite actual backend support. Do not tell Ali these endpoints are absent. Use LuxuryImagePickerField, localized fields/brand/sponsor and genuine authenticated media, no prices/cart. Treat clinic-owned products separately.
- Platform settings editor and audit log browser are still missing; current Settings is account preferences. Keep the server allowlist and typed forms when implementing, not arbitrary JSON or secret editing.

## Next sequence after Ali's contract is supplied

1. Diff the new authoritative snapshot; run safe source/schema/permission/idempotency probes first. Do not assume deploy success.
2. Add a typed AnalyticsEventRepository and ephemeral queue with UUIDs, privacy allowlist, TTL/capacity and SessionSnapshot. Implement duplicate ACK and payload-conflict semantics before any retry.
3. Attach one authenticated app-open lifecycle hook; one genuine visible profile hook; shared clinic-context call/WhatsApp/Maps actions. Audit Home/Featured/Nearby/directory/offers/My Requests call sites together. Exclude support/share/internal admin actions and unsupported ad/video events.
4. Add versioned platform/per-clinic DTOs, server pagination/search and coverage states. Preserve the existing lifetime/current-report distinction and do not build a client-side sum across all clinics.
5. Validate raw event → canonical count → server daily aggregation → response → UI, including rejected leads, duplication/retries, session switch and archived clinics. Fetch no patient rows solely for aggregate metrics.
6. Stage/release QA on real Android/iOS after source tests, including existing English/Light defaults, persisted preferences, Arabic RTL and all three role portals. Leave the client's current APK alone.

## Guardrails and delivery

This branch starts at merged PR #13's current main, not its old feature head. Signing, application identifiers, native minimum versions, Django and the delivered GPS-test APK are unchanged. No store publication or merge is performed. The audit does not represent draft backend proposals as installed APIs, and no live analytics/deletion success is claimed.
