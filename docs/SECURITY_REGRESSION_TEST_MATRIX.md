# Security regression test matrix

Verified on Linux, 2026-10-20, from security branch `codex/application-security-privacy-hardening`, based on visual recovery `a535ac703b9538f0ede2a139b9879f92be750edd`. Tests use synthetic data and local/mock APIs. A file named `*_live_test.dart` in this suite does not imply production security testing. No production API, patient-record enumeration or attack load was used.

## Executed quality gates

| Gate | Result | Scope / limits |
|---|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | PASS: 196 files checked, 0 changed | Changed Dart files had been formatted before this gate. |
| `flutter analyze` | PASS: 0 issues | Flutter/Dart analysis, not a native Gradle/iOS build. |
| `flutter test` | PASS: **410 passed, 0 failed** | Full suite, including existing visual, Clinic/Admin, decoder and refresh tests. Baseline 392 + 18 new security tests. No skips, deleted tests or timeout-only fixes. |
| `flutter test test/security_hardening_test.dart` | PASS: **18 passed** | New transport/session/privacy/media/startup/credential fixtures. |
| `flutter pub get --offline --enforce-lockfile` | PASS, lockfile SHA-256 unchanged | Verifies resolution consistency; does not scan native libraries. |
| `dart pub outdated --json --show-all` | 117 resolved packages; 0 current advisory flags, 0 retracted; 2 discontinued | Metadata check, not proof of safety. Discontinued: flutter_secure_storage_macos and js. |
| Read-only history heuristic | 915 pre-security-commit reachable UTF-8 Git blobs scanned, 0 shape findings | <=4 MiB per text blob; excludes binary/unreachable objects and nonmatching secret formats. Use `python tool/security_history_scan.py` to repeat after commit. Never prints matched values. |
| Backend exact dependency pins | 26 queried; 5 packages with advisory metadata | Public PyPI only. See Ali handoff and advisory snapshot; live installed versions unverified. |
| Android XML / source signing policy | XML parsed; release/debug signing separated; explicit backup/cleartext policy | No signed Android build, backup/transfer exercise or device test performed. |
| Read-only backend preservation | **1,258 reference files unchanged** against the saved SHA-256 baseline | Both supplied backend reference trees; no Django edits. |

Commands were run using `/workspace/work/scale-ui/sdk/flutter/bin/{dart,flutter}` with `PUB_CACHE=/workspace/work/scale-ui/pub-cache`. Detailed command logs are local execution artifacts under `/workspace/work/security-hardening/`; the summary here is portable. Analyzer and full test output contained no genuine patient records or credentials.

The red/green process retained assertions: the new startup test exposed the stale-validation logout path and passed after its session check; two existing Admin tests were updated to assert hidden-by-default credentials, then explicitly reveal and validate the actual server-returned temporary password. Image provider/real decoding/fallback assertions remain intact. Full-suite visual goldens were not regenerated.

## Executed frontend security cases

All cases below passed. OWASP mappings are review topics, not an automated compliance score.

| Case | Test evidence | Expected invariant | Mapping |
|---|---|---|---|
| HTTPS API destination | `security_hardening_test.dart`: configured HTTPS origin/normalized prefix | Reject HTTP, another host/port, userinfo, fragment and prefix traversal. | MASVS-NETWORK; API8 |
| Token exfiltration boundary | Cross-origin adapter test | Rejected before adapter; 0 calls and no token transmitted. | MASVS-NETWORK/AUTH |
| Public auth isolation | Exact auth paths/header/redirect test | Login receives no stale bearer; private `.../auth/login/` remains private; redirects disabled. | MASVS-AUTH/NETWORK |
| Successful late A response | Mock delayed private response after token/session switch | Cancellation; B token retained; A body not delivered. | MASVS-AUTH/PRIVACY; API2 |
| Late profile A | Delayed getMe fixture | Neither AuthState nor TokenStorage can be overwritten by A after B login. | MASVS-AUTH/STORAGE |
| Logout while login waits | Delayed login fixture | No session resurrection or token installation. | MASVS-AUTH |
| Overlapping login | Two completion-order fixtures | Only latest authentication attempt installs identity. | MASVS-AUTH |
| Unknown/missing identity | Unknown-role response | Auth rejected; no unauthorized portal identity installed. | MASVS-AUTH; API5 |
| Role/account transition | Favorites/epoch/user map fixture | Role change increments epoch, clears favorites; cached user map is unmodifiable. | MASVS-STORAGE/AUTH |
| Error privacy | EN/AR 400/500 fixtures | No raw PII/token/traceback retained or displayed; unknown code becomes safe code. | MASVS-PRIVACY; API8 |
| Useful validation | Known/unknown field fixture | Known actionable validation remains; arbitrary backend keys/values do not echo. | MASVS-PRIVACY/CODE |
| External maps | Host spoof and encoded place query fixture | Reject spoofed host; attacker-shaped place value remains a query value. | MASVS-PLATFORM; API7 review |
| Media preflight | Genuine bundled PNG copied to a synthetic filename; disguised/oversize file | Correct MIME/provider payload; non-image rejected; oversize rejected; original private filename not sent. | MASVS-CODE/PRIVACY; API4 |
| Async media write | Session switch during mocked upload | Old catalog POST never sent; SessionChangedException. | MASVS-AUTH; API1 |
| Cached startup | Splash with pending then failed live validation | No portal before verified live session; invalid session cleared. | MASVS-AUTH |
| Startup failure after switch | Old request rejected after installing B | B stays authenticated; old failure cannot log it out. | MASVS-AUTH |
| Navigation cleanup | Real AestheticWayApp root with private route | Logout destroys old route/private snapshot. Same epoch cleanup covers dialogs. | MASVS-AUTH/PRIVACY |
| Privileged credential display | Real Admin credentials dialog | Temporary password absent until explicit reveal. | MASVS-PRIVACY |
| Shared refresh and expiry | Existing `scale_runtime_test.dart` | 500 mock callers share one refresh; stale rotation cannot overwrite new session; retry behavior preserved. | MASVS-AUTH; API2 |
| Portal isolation/readonly supervision | Existing Admin/Clinic/patient integrity suites | Wrong-role presentation blocked, no Super Admin lead mutation buttons, no fabricated CRUD success. | MASVS-AUTH; API1/API5 |
| Account contact verification | `patient_profile_live_test.dart` | Backend-confirmed phone/email change; verified identity retained; profile state not fabricated. | MASVS-AUTH/PRIVACY |
| Image/runtime design preservation | Image display, Clinic completion, visual recovery, layout and video suites | Native files/file URIs/assets actually decode; signed URL/provider/fallback and VIP/Featured/layout behavior retained. | Functional preservation |
| Business boundaries | Existing referral, lead, product, phone and audit suites | Exact Arabic lead confirmation; no prices/cart/calendar/manual coupons/regulatory UI. | Product preservation |

## Required staging authorization matrix — NOT EXECUTED

Owner: Ali/backend QA with explicit staging permission. Use separate synthetic Patient A/B, Clinic A/B and Super Admin, plus disabled-account, suspended-clinic and staff variants. Never paste credentials into this document. Obtain object IDs from fixtures, not enumeration. Paths below are relative to the configured `/api/v1/` staging base and the source URLs; verify route deployment before requests.

For hidden foreign objects prefer 404; for an authenticated wrong role 403; unauthenticated private APIs 401. A route that legitimately uses a different denial status must still return **no foreign data and no mutation**. Assert database state, response body and side effects, not merely status. Public approved showcase reads are distinct from private portal writes.

| # | Request / fixture | Positive expectation | Negative expectation | Source / gap |
|---|---|---|---|---|
| S01 | GET `leads/my/`, `leads/my/count/` | A sees only A's records/count | B never receives A's records/count; clinic/Super Admin denied personal scope | patient_views; B01 role change |
| S02 | GET `leads/my/{A-lead}/`, `leads/{A-lead}/` | A 200 | B 404; all other roles/guest denied | Existing owner filter; live BOLA unverified |
| S03 | POST `leads/` | Patient consented valid inquiry 201 | Guest 401; clinic/Super Admin 403; forged patient ignored/rejected | B01 currently AllowAny in snapshot |
| S04 | POST `leads/` with clinic A + branch/practitioner/treatment/offer B | A-consistent relationships accepted | Cross-clinic relation rejected, no write | PatientLeadCreateSerializer |
| S05 | Duplicate consultation/offer/product inquiry | One permitted submission and stable result | Repeated concurrent request creates no unintended duplicates | Consultation lock exists; all-type durable idempotency pending |
| S06 | GET `clinic-portal/leads/` with clinic query override | Clinic A sees A only | A never widens to B by query/status/ID tampering | ClinicLeadViewSet |
| S07 | GET/PATCH `clinic-portal/leads/{B-lead}/` and nested notes/history | B accesses allowed B data | A cannot read/write B, no side effects | Scoped get_object |
| S08 | GET `admin/leads/`, `admin/leads/{id}/` | Super Admin readonly supervision | Patient/clinic denied; POST/PATCH/DELETE supervision denied | AdminLeadAPIView/Detail |
| S09 | Super Admin PATCH clinic lead status / POST notes | No allowed mutation | 403 and unchanged lead/notes | Existing explicit denial |
| S10 | PATCH `clinic-portal/profile/` including coordinates | Clinic A updates A | Forged clinic B/owner/subscription/moderation fields do not mutate B/protected data | ClinicProfileAPIView + serializer |
| S11 | Clinic practitioner/treatment/offer/product/article CRUD | A manages A under contract | A cannot GET/PATCH/DELETE B or POST with B ownership | Scope derived from membership |
| S12 | Media upload/list/detail/delete | Active A accesses permitted A assets; patient own avatar | A cannot use B clinic_id or asset UUID; patient cannot upload clinic media | Media permissions/serializer/queryset |
| S13 | Same media operations after suspension/deletion | Explicit permitted setup policy only | Suspended/deleted clinic/account denied immediately using existing token | B02 |
| S14 | Attach avatar/banner/product/article/profile assets | Correct type/owner accepted | Foreign asset/wrong type fails, including raw URL/path strings | Scoped mixins; B03 |
| S15 | Basic/staff VIP video by file/string/UUID | VIP admin with own valid video works | Basic/staff bypasses rejected via every input form | B02/B03 |
| S16 | GET/PATCH `auth/me/` | Current user's permitted fields | Supplied other ID/role/clinic/is_active cannot mutate identity/authority | MeView/UserProfileSerializer |
| S17 | Phone/email change request/confirm | Valid owned verification updates contact | Wrong/expired/reused code, taken number and foreign session denied | Account change views; token policy |
| S18 | POST `notifications/devices/`, DELETE encoded token | Current account registration/deactivation | Foreign token deletion denied; old logout cannot deactivate new account binding | user AND token scope |
| S19 | GET `referral/my-status/` | Patient sees own link/points | Clinic/Super Admin denied; no extra PatientProfile created | B01 |
| S20 | POST `referral/collect-code/` | Retired route returns 410 | No voucher/points mutation by any role | B01 retirement |
| S21 | Unified public invite resolution | Valid fixture gets minimal state | Invalid token generic failure; no inviter phone/name/email/JWT | ReferralInviteResolveAPIView |
| S22 | Admin provisioning/activate/suspend/reset | Super Admin authorized, audited response | Patient/clinic rejected; duplicate writes do not create duplicate clinics/credentials | Admin permissions and idempotency review |
| S23 | Admin moderation/category/global brand product | Supported dedicated Admin contract works | Other roles denied; global products not assigned silently to first clinic; absent API not treated as success | Existing backend gaps handoff |
| S24 | OTP issue/verify/reset, expiry/concurrency | Valid code lifecycle works once | Lost increments, replay and multiple resend winners impossible; Redis failure closed | B04 |
| S25 | Issue/refresh for inactive/deleted/role-changed users | Active current account only | No new token after disable/delete; old refresh reuse fails; account policy enforced | B05/B08 |
| S26 | Logout/password reset revocation | Refresh blacklisted; offline mobile clears locally | Stolen old refresh cannot rotate; document old access token behavior explicitly | B05; access revocation policy pending |
| S27 | Controlled image/video validator fixtures | Permitted real formats decode/process | Oversize, mismatch, huge pixel, unprobeable/long video, unwanted EXIF rejected/removed | B07; no production hostile uploads |
| S28 | Private media URL/storage | Authorized fetch, short bounded expiry | Expired/unowned URL does not expose patient media; public showcase policy explicit | Bucket/CDN deployment verification |
| S29 | Logs, analytics, notification preview | Generic operational counts/events | Synthetic PII/JWT/invite/credential strings absent from sinks and lockscreen | B06 |
| S30 | TLS/proxy/body size/redirect behavior | HTTPS exact routes work without redirects | Cleartext, spoofed forwarded identities and oversized local staging bodies denied | Edge configuration, B04/B08 |

Record each execution with backend deployment SHA, fixture label, method + route template, status and safe assertion summary. A successful frontend mock is not a substitute for any S-row. Run these cases on dedicated fixtures and tear down only their own data.

## Native and independent checks still pending

- Android release APK/AAB with CI keystore, no debug certificate; missing-signing-variable failure; min/target SDK manifest merge and backup/device-transfer exclusions on devices.
- iOS archive, unlocked-this-device keychain behavior, device migration/backup and locked-device access; Android keystore failure/relaunch and encrypted-store behavior.
- Windows execution of the preserved image regression. Linux provider/decoding tests pass; this security environment cannot claim Windows runtime verification.
- Safe account-switch/slow-network/device token and offline logout on real iOS/Android; private-route/background/screenshot/clipboard policy with product owner.
- Native dependency/SBOM and CI secret-store review, web invite attribution/domain associations, storage ACL/signed expiry and deployed backend five-role tests.
- Independent authorized penetration test after Ali's changes. No certification or claim that all vulnerabilities are eliminated is made.
