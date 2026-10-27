# Gallery regression and Google ratings — PR #13

2026-10-27 · `codex/final-backend-integration-client-preview` · baseline
`cf52892cf56492179aad85b32c78c3315fec09fe`. Existing PR #13 remains open/unmerged.

The supplied archive is identified by the owner as production backend
`c25e901ec10c7c3f751462b414d90d5ab88d3c85`. Archive SHA-256:
`0db1da5c354c0835ef9c92d3ea193b539862e42865ee8474515d11d55f01e28f`.
The archive contains no Git metadata proving deployment. AWS deployment,
migrations and running workers are owner/backend-engineer reports. All 413
backend source files remain byte-identical. No Django or signing changes.

## Gallery root cause and corrected pipeline

The owner clarified the physical failure: **selection disappeared before Save**.
This matches an independently reproduced Flutter lifecycle race:

1. `LuxuryImagePickerField._pickImage` awaits the native Android photo picker.
2. Returning to Flutter emits `AppLifecycleState.resumed`.
3. `ClinicMediaScreen.didChangeAppLifecycleState` starts `_loadOwnedProfile`,
   setting `_profileLoading=true`. `_locked` disables the picker.
4. The native picker returns files, but `_pickImage` checks `widget.enabled`
   and discards them. `_selected` also rejects input while `_locked`.
5. No queue, explicit Save, multipart upload or asset acknowledgment occurs.
   Successful local video preview or Django contract tests cannot repair this.

The regression test failed on the original code with zero queued images, and
passes after deferring that resume refresh while native gallery/camera selection
is in flight. The optional picker-state callback is used by this editor only.
Regular foreground profile refresh, role/session checks and server permissions
remain enforced. This explains the reported failure stage; the corrected build
has **not** yet been verified on the physical Android device.

| Stage | Source contract / final behavior |
|---|---|
| Select and queue | Native Camera/Gallery through `LuxuryImagePickerField`; genuine local image previews; no URL input. Cancellation stays empty; selection is not a save. |
| Explicit Save | Existing persistent CTA, duplicate-tap guard, per-file progress/cancellation. Read-back review now locks mutations until complete, so an older optimistic list cannot certify a later POST. |
| Multipart | `POST /api/v1/media/upload/`, binary `file`, `media_type=clinic_gallery`, explicit clinic UUID as `clinic_id`. Neutral filename `image.png/jpg/webp`; detected MIME. Dio owns boundary generation; JWT stays in the authenticated header. No gallery-array PATCH or new endpoint. |
| Validation/ownership | Client extension/signature and 5 MiB checks retained. Django independently verifies JPG/PNG/WebP, MIME, decoded integrity, dimensions ≤25 MP and active membership. New source allows active/pending clinics, while suspension/deletion and foreign-tenant guards remain. |
| Acknowledgment | Require actual HTTP **201** and a valid matching clinic/gallery/image asset UUID and URL. Malformed/202/wrong-tenant/video acknowledgments remain unconfirmed, retain the actual status, and cannot be treated as a successful save. |
| Association | Django creates `MediaAsset(clinic=..., media_type=clinic_gallery)` during upload. Public/private gallery serializers derive images from that relation; there is no separate association write. |
| Fresh gallery/profile | Preserve asset receipts until a fresh gallery read returns them; independently check the fresh private profile's `gallery_images`. A missing profile image or read failure stays explicitly unconfirmed. Matching preserves meaningful URL query data and permits re-signing of the same R2 object. |
| Display | Saved gallery frames resolve their remote URL without substituting a remembered local file. Genuine HTTP/decode failure displays a bounded retry panel with safe image-load details. Patient/shared defaults keep existing local previews/cache behavior. A decoded cached network frame is not proof of a new CDN fetch. |
| Recovery/delete | Preserve queued failures, acknowledged receipts, partial-success profile refresh and explicit review before uncertain retry. No automatic ambiguous POST replay. Existing authenticated asset delete is unchanged and tested; cover/video are separate. |

The expandable support panel contains only operation stage, observed HTTP status,
upload HTTP status, an allowlisted API code/validation field names, asset ACK,
gallery/profile verification flags and UTC start time. `HTTP=none` means no status
was observed/retained for that stage; it is not a fabricated network result.
Image errors separately identify `stage=imageLoad`, actual HTTP status when
Flutter supplies it, and a coarse error kind. No body, token, OTP, personal
filename, phone, patient data, private media URL or credential is displayed.

## Google ratings pipeline and evidence boundary

The source-confirmed flow is:

1. Admin autocomplete/details obtains an expiring, one-use selection proof.
   Link verifies that proof and clinic/admin scope, writes Place ID/Maps URL,
   clears prior rating/count/time and sets `google_sync_status=pending`.
2. Link does **not** queue/fetch ratings. `clinics.sync_google_places` is scheduled
   daily at 03:00 Asia/Dubai, using active/nondeleted clinics. Account status
   `pending` is excluded even if it has a permitted association.
3. Sync calls Places API (New) with `rating,userRatingCount`, using the server key,
   enabled setting, billing/quota and network. Success persists rating/count/time;
   failure marks `failed` and preserves any prior cached values.
4. Public serializers read persisted values, never Google directly, and suppress
   ratings when Place ID is empty. The public response does not expose an
   association/identity review verdict.
5. Flutter already parses decimal strings such as `"4.60"` and integer counts.
   `ClinicModel.hasGoogleRating` and `GoogleClinicRating` display valid fields and
   suppress missing/nonfinite/out-of-range values or absent Place IDs. This was
   verified in EN/AR and Light/Dark. **No parser/rendering defect was reproduced.**

The Clinic Portal now explains that refreshing reads server status rather than
starting synchronization, and asks owners to unlink unrelated businesses.
There is no fake rating, synthetic sync success or invented sync endpoint.

**Live public rating values are unverified.** This environment's enforced network
policy does not permit `aestheticway.ae`, and no authenticated production access
was supplied. Controlled source tests prove that successful synchronization can
produce non-null fields and Flutter can render them; they do not prove current
production delivery, provider health or the affected clinic's eligibility.

**P0 integrity dependency:** a valid Google selection proof establishes a real
place, not affiliation with the clinic. The source accepts a disposable clinic
linked to an unrelated salon and exposes its stubbed rating after sync. Public
fields do not let Flutter distinguish it from an authorized association. Do not
enable/synchronize a knowingly wrong production association to make a badge
appear. Ali must correct the association and enforce identity/moderation before
publishing its ratings. Frontend name guessing would not establish authorization.

Other reproduced source risks are ambiguous gallery lists for multiple clinic
memberships and stale background rating writes restoring an old association.
See the [single current bilingual handoff](GALLERY_RATINGS_C25E901_HANDOFF_FOR_ALI.md)
for exact contracts, reproductions, expected fixes and production evidence needs.

## Verification, changes and retest

- New focused regressions cover lifecycle selection/normal foreground refresh,
  real multipart bytes/boundaries, strict acknowledgments, safe diagnostics,
  400/403/500/503 errors, gallery/profile read separation, refresh locking,
  remote HTTP403 versus local cache, real decoded-image retry, and rating
  parsing/pending UI in all four theme/language combinations.
- [24 independent source observations](gallery-ratings-c25e901/source-evidence.json),
  [25 previous-finding rechecks](gallery-ratings-c25e901/previous-findings-recheck.json)
  and **59 supplied backend media/rating tests passed**, using isolated SQLite,
  local temporary storage and explicit Google stubs. No live/R2/device claim.
- The old source geography cases now reject contradictory data with 400, exclude
  inactive/deleted branches and resolve the nearest branch's Dubai emirate.
  The conditional pending-clinic upload 403 is resolved. Historical reports
  describe their older snapshots; these are not repeated as current blockers.
- Final formatting/analyzer/full-suite and exact-head Windows/Ubuntu plus
  Android/iOS CI evidence are recorded in PR #13 and linked from the
  [verification manifest](gallery-ratings-c25e901/verification.json).
- [Changed-file manifest](gallery-ratings-c25e901/CHANGED_FILES.txt) and
  [actual Flutter renders](gallery-ratings-c25e901/README.md).
- [Concise physical Android retest checklist](GALLERY_RATINGS_C25E901_ANDROID_RETEST.md).

Owner-reported physical PASS: Nurse without photo, emirate filtering, clinic
location saving, Google association, and VIP upload/persistence/playback. GPS
distance and verified-email deletion remain owner-unverified. New gallery
selection → save → reopen/restart → patient display and actual CDN delivery still
need physical testing. Patient luxury UI, consultation/My Requests, all portals,
role isolation, JWT, pagination, first-launch English/Light, saved preferences,
VIP/cover behavior and production signing protections are preserved.
