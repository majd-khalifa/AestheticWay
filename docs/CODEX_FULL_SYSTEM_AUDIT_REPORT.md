# AESTHETIC WAY — Full System Forensic Audit Report

**Audit date:** 19 October 2026. **Mode:** read-only source audit; proposed code below is unapplied. **Verdict:** the reviewed version has reproducible broken core flows and isolation defects. It should not be declared production-ready from its existing test results.

## 1. Evidence, authority, and coverage

- Frontend: `https://github.com/majd-khalifa/AestheticWay.git`, workspace `/workspace/AestheticWay`, commit `9c6d211d618ba33bdca2413d0b3bcf109ab9873a`. The working tree was clean at intake.
- Backend: the supplied `backend.zip`, extracted to `/workspace/work/audit/backend`. Archive SHA-256: `6cf2d3ef00e54b1c6b62b8fb184436c3f2a5acda3b576ced810f4a38cbae6c1c`. This is the audited backend snapshot; no claim is made that the current GitHub HEAD or deployed server is identical. No backend Git metadata was supplied.
- The user's current seven business rules are the acceptance benchmark. Backend executable models, serializers, views, and routes determine the **current API contract**, including where that contract violates the requested product behavior. Existing reports, comments, attached guides, and historical “fixed” claims are evidence to verify, not instructions to execute or authorization to alter source.
- Repository `AGENTS.md` and `.agents/skills/strict_project_rules/SKILL.md` were consulted. The user's current points/milestones requirement supersedes older scope wording against complex loyalty. No source fixes were applied.
- Inventory: **966 supplied files**: frontend 344 (291 UTF-8 text, 53 binary); backend 622 (357 text, 265 binary/cache). Text inventory totals **99,701 lines**, including documentation, tests, migrations, platform scaffolding, and dependency locks. Every file was read for inventory/fingerprinting; text was scanned in full. All 347 backend Python files parsed successfully. All 98 identified frontend HTTP callsites were compared with the resolved Django router. The evidence contains 89 serializer field contracts and 542 UI input/action contexts.
- Coverage is not overstated: inventory/full-text scanning is not a claim of independent manual semantic review of every line. Detailed line-by-line cross-reference and runtime reproductions concentrate on the flows documented below. Binary/cache files were fingerprinted, not treated as source. A mathematically exhaustive absence-of-bugs guarantee is impossible; findings distinguish reproduction, static proof, and deployment-dependent conditions.
- Flutter/Dart SDKs are absent. No Flutter analyzer, widget tests, device builds, screenshots, actual camera permissions, or rendered overflow checks were executed. Visual findings below are source/color calculations or clearly labeled risks. Backend checks ran in an isolated virtual environment, SQLite, local storage, mock delivery, and synthetic users. No production records, credentials, storage buckets, email recipients, or GitHub content were modified.

**Path notation:** `F:` means frontend repository root; `B:` means extracted backend root. Line numbers refer to the snapshots above. The report's companion evidence archive includes a SHA-256 file manifest, all HTTP callsites, resolved routes, serializer fields, reproduction outputs, and the audit scripts.

## 2. Executive findings and priority

| ID | Priority | Finding | Evidence level |
|---|---|---|---|
| A01 | P0 | Failed catalog-media uploads are swallowed; text saves can report success without the chosen image | Static, backend rejection reproduced |
| A02 | P0 | Practitioner replacement asset persists but old avatar URL continues to win | Reproduced HTTP 200 + stale URL |
| A03 | P0 | Clinic image cache-buster invalidates signed S3/R2 URLs; product/article uploads also copy temporary signed URLs into short persistent URL fields | Signature and validation reproduced offline |
| A04 | P1 | Image removal cannot be distinguished from “unchanged”; missing local files silently disappear from payloads | Static; backend null clearing reproduced |
| A05 | P0 | Practitioner, product, article endpoints accept another clinic's media asset UUID | Reproduced HTTP 200 for each |
| A06 | P0 | Singleton clinic/referral state survives logout; a second account can receive the previous account's cached state | Static call-path proof |
| A07 | P1 | Clinic provisioning images either disappear or switch request to incompatible nested multipart | Reproduced 201 with no image; multipart 400 |
| A08 | P1 | Lead-status PATCH returns only status; Flutter replaces a complete lead with an empty/default record | Reproduced response + static consumer |
| A09 | P1 | Password recovery consumes OTP before the password-reset endpoint verifies it again | Reproduced 200 then 422 |
| A10 | P1 | Auth normalizer rewrites non-UAE numbers to +971; country search is incomplete | Static proof |
| A11 | P1 | Clinic onboarding cannot enter the English bio; local readiness rules disagree with Django | Static proof |
| A12 | P1 | VIP clinic editor uses `vipPlatinum` against dropdown/API value `vip` | Static deterministic mismatch |
| A13 | P1 | Requests show invented appointment dates and silently send an evening preference | Static, backend has no preferred-date field |
| A14 | P1 | Unified invite URL has no Django root route; Flutter does not capture/pass referral attribution | Route resolution + static trace |
| A15 | P1 | Super Admin product moderation still displays prices | Direct UI source |
| A16 | P1 | Unverified patient can log in and receive JWTs; endpoint-scoped throttle settings are not attached | Login reproduced; throttle static |
| A17 | P1 | Suspended clinic can still read/manage leads; super admin can enter a clinic portal using an arbitrary-clinic fallback | Lead read reproduced; permissions static |
| A18 | P1 | Clinic specialty filters are inert; several catalogs/admin lists stop at the first page | Static contract/consumer trace |
| A19 | P1 | Dead product-inquiry widget uses invalid `lead_type: product`; backend expects `product_inquiry` | Reproduced 400; import graph |
| A20 | P1 | Client fabricates operational/medical facts: working hours, location, fallback phone, clinician role/experience | Direct source |
| A21 | P2 | Home media contracts are dropped/unused; updated images can lag behind a cached home feed | Static serializer/parser/cache trace |
| A22 | P2 | Local catalog counts and dashboard labels misrepresent server meaning | Static trace |
| A23 | P2 | Offer editing/treatment linking and branch editing exist in services but have no working UI entry | Call/reference inspection |
| A24 | P2 | Media validation, file-name length, video type/tier enforcement, and storage cleanup are inconsistent | Static + filename behavior |
| A25 | P2 | Four missing translation keys; widespread low-contrast hints and selected chips | Exhaustive literal-key scan + color calculation |
| A26 | P2 | Request errors, refresh retries, async state updates, and loading aggregation can conceal failures or leave stale state | Static trace |

P0 means repair before release of the affected flow; it is not a claim that every P0 is an authentication bypass. P1 means a broken primary task or mandatory-rule breach. P2 means substantial correctness, maintainability, or UX work.

## 3. Highest-priority investigation: clinic media pipeline

### 3.1 What each entity actually sends and accepts

| Entity | Flutter transport | Django persistence | Returned image key | Material behavior |
|---|---|---|---|---|
| Clinic logo/cover | Direct multipart PATCH, binary parts `logo`, `cover_image` | `Clinic.logo`/`cover_image`: `ImageField` | `logo`, `cover_image` | Correct basic binary contract; strings deliberately stripped; URL mutation breaks signed rendering |
| Practitioner | Multipart POST `/media/upload/`, then JSON POST/PATCH with `media_asset` **and** `avatar` URL | `avatar`: `URLField`; nullable `media_asset` FK | `avatar_url` | Serializer strips string `avatar`; existing model URL masks replacement FK |
| Offer | Same two-stage flow, key `image` | `image`: `URLField`; nullable `media_asset` FK | `image_url` | String image stripped; preexisting legacy URL masks new FK |
| Product | Same two-stage flow, key `image` | `URLField` + FK | `image_url` | Both submitted fields accepted; temporary signed URL can be persisted or rejected for length |
| Article | Same two-stage flow, key `cover_image` | `URLField` + FK | `cover_image_url` | Same URL persistence/length issue; repository maps old `image` alias to `cover_image` |

**Do not “fix” all entities by forcing multipart files into their existing entity serializers.** Practitioner/offer/product/article legacy fields are URL fields, not binary ImageFields. Use the existing media endpoint and attach a scoped asset UUID. Clinic branding currently has a separate valid direct-file contract.

### 3.2 UI → service → repository → HTTP → Django

1. `F:lib/core/widgets/luxury_image_picker_field.dart:70–104` obtains an `XFile.path`; `onImageSelected` returns that local path. Camera/Gallery and preview are real. Picker exceptions are only logged; a selection error is not surfaced to the user. There is no mounted check after the awaited native picker.
2. Clinic dialog: `F:lib/features/clinic_portal/presentation/screens/clinic_profile_screen.dart:1441–1656`; `logoPath` and `coverPath` start null, callbacks at 1539/1548 set them, and Save forwards them at 1648/1649. Catalog dialogs forward `avatar`, `image`, or `cover_image`; relevant saves are profile screen 354–390, 1050–1069, 1387–1403; dedicated practitioners screen 427–452; offers screen 391–421.
3. `ClinicPortalService.updateClinicProfile`, `F:.../services/clinic_portal_service.dart:1053–1133`, reconstructs and publishes `_activeClinic` **before** awaiting the network. Local file paths intentionally do not replace image URLs in that optimistic object. Failure leaves optimistic text and resets some omitted model fields. The successful result then has `?v=`/`&v=` appended at 1123–1130. Catalog CRUD generally waits for the API and replaces/inserts the returned model; successful POST/PATCH does not prove that a prior media upload succeeded.
4. Clinic `_buildPayload`, `F:.../data/clinic_catalog_repository.dart:78–127`, converts real local files to `MultipartFile` and `FormData`; missing paths, nulls, empty values, and remote URLs are omitted. `updateClinicProfile:517–529` sends PATCH and parses a flat result or `data` wrapper. This is already a binary upload, not a JSON string upload for valid native paths.
5. Catalog `_resolveMediaAssetPayload`, same file 39–75, uploads first. A catch-all at 67–70 deletes the image from the entity payload and continues. Missing IDs/URLs also do not fail the save. The UI's success snackbar therefore describes text persistence even when selected media never reached storage.
6. `F:lib/core/services/media_upload_service.dart:35–55` sends `{file, media_type, optional clinic_id}` as multipart. Response is a flat media object containing `id` and `url`, exactly as `B:apps/media/views.py:29–42` returns. There is no `data.asset` wrapper mismatch in this snapshot.
7. `F:lib/core/network/api_client.dart:14–26,71–87` does **not** globally force JSON. `AuthInterceptor:43–50` removes a content-type for FormData, allowing Dio to generate the boundary. Bearer token and Accept-Language are attached. Django profile view explicitly includes MultiPartParser/FormParser/JSONParser (`B:apps/clinics/portal_views.py:126–136`); the catalog views similarly accept the needed formats. PATCH is supported. Changing PATCH to PUT would not fix this defect.
8. **Version-sensitive MIME conclusion:** `F:pubspec.lock:116–123` locks **Dio 5.11.1**, whose downloaded implementation calls `lookupMediaType(filename)` before falling back to `application/octet-stream`. Consequently `.png/.jpg` normally get a correct inferred MIME type, despite stale comments in that package. Explicit MIME is useful for unknown extensions, older installed builds, or canonicalized filenames; “Dio always sends octet-stream” is **not** an accurate universal root cause for this checkout. The backend really does reject octet-stream at `B:apps/media/validators.py:187–192`; that rejection was reproduced. MIME failure is conditional, not evidence that every JPEG upload fails.
9. `B:apps/clinics/portal_serializers.py:21–33` accepts binary images and drops all string values for branding. Practitioner serializer 51–58 and offer serializer 48–55 also discard string values even though their model columns are URLFields. This permits silent no-op image updates rather than a useful validation error.
10. `B:apps/media/serializers.py:165–189` writes a MediaAsset FileField and metadata. `MediaAssetSerializer:48–54` uses `request.build_absolute_uri(file.url)` when request context exists. FileSystemStorage yields a relative `/media/...` URL internally and an absolute upload-response URL. R2/S3 yields a storage URL: signed when no public custom domain is configured under normal django-storages defaults, or a custom-domain URL when configured.
11. Backend image properties prefer legacy URLs: practitioner models 96–102, offers 78–84, products 85–91, articles 94–100. A new FK alone cannot win over an existing string. Products/articles currently copy the uploaded URL into that string, which makes temporary URL expiry persistent data corruption.
12. Frontend models generally read the correct returned key (`ClinicModel:183–184`, `PractitionerModel:243`, `OfferModel:147`, `ProductModel:135`, `ArticleModel:147–150`). `LuxuryImage` resolves relative `/media` URLs. Many portal cards still call Image.network directly, but their model URLs are resolved first. `ApiConfig.siteOrigin` is hardcoded production even when `baseUrl` is overridden; local/staging relative media consequently points at production.

### 3.3 Exact demonstrated causes and the limits of the symptom report

- **Text saves while image fails:** any media upload exception is swallowed; existing text POST/PATCH can then succeed. This is a certain code defect regardless of the reason the upload failed.
- **Old practitioner image after successful replacement:** a reproduction attached a new valid asset to a practitioner whose `avatar` was `https://example.org/old.png`. PATCH returned 200, FK changed in the database, and `avatar_url` still returned the old URL. Offers have the same property/stripping combination, although their current UI exposes add/toggle/delete rather than image editing.
- **Clinic image saves but renders fallback:** a direct multipart clinic-logo PATCH with a valid PNG and even an octet-stream header returned 200, wrote the file, and returned a new logo URL in isolated FileSystemStorage. Therefore this snapshot does **not** substantiate universal clinic-logo persistence failure. A separate offline SigV4 check proved that appending Flutter's `v` parameter turns a valid signed GET URL into an invalid signature. That explains the rendering failure when the deployed storage returns signed URLs. It does not prove the deployed R2 configuration.
- **Product/article storage URLs:** a synthetic signed storage URL was 392 characters. Both entity URL fields rejected it with `max_length=200`. With shorter temporary URLs, saving them still creates later expiry failure; use the FK and compute a fresh URL at serialization time.
- **Remove image:** the picker emits null, but caller/service/repository omission semantics keep the old file. Direct JSON `{"logo": null}` successfully cleared the backend field; the app currently fails to send it.
- **Missing path:** `_buildPayload` silently removes a nonexistent file path, producing a text-only successful PATCH.
- **Infrastructure condition:** `B:config/urls.py` contains no `/media/` development-serving route; production serving by nginx/CDN is outside the archive. No evidence was supplied to establish the deployed media route, public R2 access, bucket configuration, cache rules, or deployed app version. A 200 PATCH plus an inaccessible GET URL is rendering/delivery failure, not proof of missing database persistence.

**Required production evidence to finish attribution for a specific failing clinic save:** sanitized request field names and file-part metadata; PATCH response image URL shape (redact signatures); subsequent GET profile result; image GET HTTP status; active storage backend/public-domain configuration; installed app commit/lock version. No production access was attempted during this audit.

## 4. Part A — critical bug fixes, with replacement code

All snippets are proposed changes, not applied patches. Integrate the related Flutter and Django changes together; otherwise changing only the client can expose the existing server precedence bug.

### A01–A04: fail closed for media, attach IDs, preserve signed URLs, support removal

Replace `_resolveMediaAssetPayload` (`F:lib/features/clinic_portal/data/clinic_catalog_repository.dart:39–76`) with:

```dart
Future<Map<String, dynamic>> _resolveMediaAssetPayload(
  Map<String, dynamic> data, {
  required String imageKey,
  required String mediaType,
}) async {
  final payload = Map<String, dynamic>.from(data);
  if (!payload.containsKey(imageKey)) return payload; // unchanged
  final selected = payload.remove(imageKey);
  if (selected == null) {
    payload['media_asset'] = null; // explicit remove; server clears legacy URL
    return payload;
  }
  final path = selected.toString().trim();
  if (path.startsWith('https://') || path.startsWith('http://')) {
    return payload; // existing preview URL is not a new selection
  }
  if (path.isEmpty || !await File(path).exists()) {
    throw ApiException(message: 'The selected image is no longer available.');
  }
  final uploaded = await _mediaUpload.uploadImage(
    filePath: path,
    mediaType: mediaType,
  ); // never swallow this error
  final id = uploaded['id']?.toString();
  if (id == null || id.isEmpty) {
    throw ApiException(message: 'The server did not return an uploaded image ID.');
  }
  payload['media_asset'] = id;
  return payload;
}
```

Add the existing `ApiException` import. This deliberately never persists an uploaded public/signed URL into a catalog entity. For every catalog dialog, track whether selection changed, and emit the key even when the selected value is null:

```dart
String? selectedProductImagePath;
bool productImageChanged = false;
// In LuxuryImagePickerField:
onImageSelected: (path) {
  selectedProductImagePath = path;
  productImageChanged = true;
},
// In the entity payload:
if (productImageChanged) 'image': selectedProductImagePath,
```

Apply the same pattern for `avatar` and `cover_image` in both practitioner dialogs and article dialog. Do not initialize a “new selection” to a remote URL. Preserve `initialUrl` solely for preview. Ensure save errors remain visible and keep the dialog open. Local file disappearance must throw rather than delete a field from `_buildPayload` (lines 93–95).

For clinic branding, remove `addCacheBuster` and the entire `ts` block at service lines 1123–1130. Commit the authoritative result:

```dart
final updated = await _catalogRepository.updateClinicProfile(payload);
_activeClinic = updated;
await loadSetupChecklist();
notifyListeners();
```

Move the existing pre-request `_activeClinic` reconstruction out of the live path; the minimal safe implementation commits only after the awaited request. Keep test/mock behavior separate. Introduce explicit `clearLogo`/`clearCoverImage` flags in the service and forward them from dialog “changed + null” state:

```dart
if (clearLogo) {
  payload['logo'] = null;
} else if (logo != null && logo.isNotEmpty) {
  payload['logo'] = logo;
}
if (clearCoverImage) {
  payload['cover_image'] = null;
} else if (coverImage != null && coverImage.isNotEmpty) {
  payload['cover_image'] = coverImage;
}
```

Update `_buildPayload`: preserve explicit null keys for JSON clearing; omit remote preview URLs; throw on a selected file that no longer exists. For mixed replacement+removal multipart, send an explicit `clear_logo`/`clear_cover_image` boolean accepted by Django, or issue the explicit JSON clear after the binary PATCH and report partial failure. Multipart empty strings are not a reliable JSON-null equivalent: the current server strips them. A robust single-request server addition is a write-only clear boolean that sets the corresponding ImageField to `None` during update, while rejecting simultaneous clear and replace.

The following exact replacement makes `_buildPayload` fail visibly and handles mixed replace/remove using the clear flags described above:

```dart
Future<dynamic> _buildPayload(
  Map<String, dynamic> data, {
  required List<String> fileKeys,
}) async {
  final payload = Map<String, dynamic>.from(data);
  final files = <String, MultipartFile>{};
  for (final key in fileKeys) {
    if (!payload.containsKey(key)) continue;
    final value = payload.remove(key);
    if (value == null) {
      payload['clear_$key'] = true;
      continue;
    }
    final path = value.toString().trim();
    if (path.startsWith('http://') || path.startsWith('https://')) continue;
    if (path.isEmpty || !await File(path).exists()) {
      throw ApiException(message: 'The selected file is no longer available.');
    }
    files[key] = await MultipartFile.fromFile(
      path,
      filename: path.split(RegExp(r'[\\/]')).last,
    );
  }
  if (files.isEmpty) return payload;
  return FormData.fromMap({...payload, ...files});
}
```

Add these attributes and `validate` method to both `ClinicProfilePortalSerializer` and `AdminClinicUpdateSerializer`, and add all three clear names to their `Meta.fields`. The flags are write-only and popped before model persistence:

```python
clear_logo = serializers.BooleanField(required=False, write_only=True)
clear_cover_image = serializers.BooleanField(required=False, write_only=True)
clear_video_ad_file = serializers.BooleanField(required=False, write_only=True)

def validate(self, attrs):
    attrs = super().validate(attrs)
    for field in ('logo', 'cover_image', 'video_ad_file'):
        clear = attrs.pop(f'clear_{field}', False)
        if clear:
            if attrs.get(field) is not None:
                raise serializers.ValidationError({
                    field: 'Choose either replacement or removal.'
                })
            attrs[field] = None
    return attrs
```

Use the same payload-builder semantics for admin clinic editing, retaining the dotted `admin_user` flattening for provisioning. The admin edit dialog must also track explicit picker changes and send null rather than omit a removed file. Both replacement and removal can then be validated and persisted in one request.

For canonical MIME handling in `MediaUploadService`, optional hardening without a new dependency:

```dart
final header = await file.openRead(0, 12).fold<List<int>>(
  <int>[], (bytes, chunk) => bytes..addAll(chunk),
);
bool starts(List<int> sig) => header.length >= sig.length &&
    List.generate(sig.length, (i) => header[i] == sig[i]).every((v) => v);
final String mime;
final String extension;
if (starts([0xFF, 0xD8, 0xFF])) {
  mime = 'image/jpeg'; extension = 'jpg';
} else if (starts([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
  mime = 'image/png'; extension = 'png';
} else if (header.length >= 12 &&
    String.fromCharCodes(header.sublist(0, 4)) == 'RIFF' &&
    String.fromCharCodes(header.sublist(8, 12)) == 'WEBP') {
  mime = 'image/webp'; extension = 'webp';
} else {
  throw ApiException(message: 'Choose a JPEG, PNG, or WebP image.');
}
final part = await MultipartFile.fromFile(
  filePath,
  filename: 'upload.$extension',
  contentType: DioMediaType.parse(mime),
);
// Use part as FormData['file']; retain media_type and clinic_id.
```

This identifies MIME from content and canonicalizes the extension. It is not a substitute for Django's deep validation. Offer a visible conversion/reselection error for unsupported native formats; do not silently drop the photo.

### A02/A05: Django asset ownership and URL precedence

Add a shared serializer mixin, used before `ModelSerializer` by practitioner, offer, product, and article portal serializers:

```python
from rest_framework import serializers
from apps.clinics.portal_permissions import get_user_clinic

class ScopedImageAssetMixin:
    asset_media_type = None
    legacy_image_field = None

    def validate_media_asset(self, asset):
        if asset is None:
            return None
        clinic = get_user_clinic(self.context['request'].user)
        if (asset.clinic_id != clinic.id
                or asset.media_type != self.asset_media_type
                or not asset.mime_type.startswith('image/')):
            raise serializers.ValidationError(
                'Choose an image uploaded for this clinic and field.'
            )
        return asset

    def create(self, validated_data):
        if 'media_asset' in validated_data:
            validated_data[self.legacy_image_field] = ''
        return super().create(validated_data)

    def update(self, instance, validated_data):
        if 'media_asset' in validated_data:
            validated_data[self.legacy_image_field] = ''
        return super().update(instance, validated_data)
```

Configure:

| Serializer | `asset_media_type` | `legacy_image_field` |
|---|---|---|
| ClinicPractitionerPortalSerializer | `practitioner_avatar` | `avatar` |
| ClinicOfferPortalSerializer | `offer_image` | `image` |
| ClinicProductPortalSerializer | `product_image` | `image` |
| ClinicArticlePortalSerializer | `article_cover` | `cover_image` |

Retain existing offer price/date/treatment validation and article author validation. Article create/update must call through the mixin via `super()`; their current methods already do. The offer's current own-clinic check permits an unscoped asset (`clinic_id=None`) and checks no media type; replace that asset check with the exact equality rule above.

Change all four image properties to asset-first, using the relevant legacy field:

```python
@property
def avatar_url(self):
    if self.media_asset_id:
        return self.media_asset.url
    return self.avatar or ''
```

For offer/product use `image_url` and `self.image`; for article use `image_url` and `self.cover_image`. Serialize a fresh storage URL, and use request context consistently when converting local relative URLs to absolute ones. Make legacy URL fields read-only in portal writes once migrated. Migrate/backfill existing signed-URL strings to valid owned media assets when a reliable association exists; do not blindly erase legacy-only imagery. Do not make patient images publicly readable as a shortcut to solve clinic showcase delivery.

### A06/A17: session and portal isolation

`AuthRepository.logout` clears tokens/AuthState only (`F:.../auth_repository.dart:221–240`). It never resets ClinicPortalService, ReferralService, AdminPortalService, or favorites. Clinic service's `_hasLoadedFromApi` and `_hasLoadedCatalogFromApi` at 235/295 cause the next login's initial loads to return cached records; dashboard `initState:39–40` invokes those non-refresh loads. Add production `clearSession()` methods (reuse the state-clearing bodies currently reserved for testing) and call them on logout, expired-session handling, account changes, and failed restore. Include the active clinic, lists, notes, load flags, referral balances/link, admin records, favorites, and pending requests.

Add a session generation to prevent in-flight requests from repopulating cleared state:

```dart
int _sessionEpoch = 0;
void clearSession() {
  _sessionEpoch++;
  // Clear all user/clinic data and load flags; publish empty state.
}
// In each loading method, before awaiting:
final epoch = _sessionEpoch;
final results = await Future.wait(/* existing requests */);
if (epoch != _sessionEpoch) return;
// Commit results only for this epoch; guard finally updates too.
```

`B:apps/clinics/portal_permissions.py:18–31,57–58,82` explicitly admits super admins and, with no membership, chooses the first active clinic. For the requested isolation, clinic-portal permission must require an actual clinic role and verified membership; remove the super-admin fallback and use the explicit admin endpoints for admin actions. Resolve one tenant consistently from validated `_jwt_clinic_id` plus membership; current `get_user_clinic` ignores that hint and chooses `.first()`, while media upload honors the hint. With multi-membership data, the upload and entity write can therefore target different clinics.

`B:apps/leads/views/clinic_views.py:30–62` only checks authentication and membership IDs, not clinic suspension. Reuse a tenant/access permission that denies suspended/deleted clinics and scope lead queries to that resolved clinic. A synthetic suspended clinic retained HTTP 200 access to its lead list. Apply the same active-clinic rule to media management and referral clinic endpoints rather than maintaining incompatible permission systems.

### A07: clinic provisioning must support its image UI

`F:.../admin_create_clinic_dialog.dart:141–166` preuploads branding without a target clinic; on success it passes URLs that AdminRepository `_buildPayload:35–47` removes. On failure it passes local files, causing nested `admin_user` to become bracket-form multipart. `B:AdminClinicProvisionSerializer:92–111` declares no branding fields, and provisioning service 45–63 never saves images. Reproductions: JSON with logo returned 201 but `clinic.logo` was empty; bracket multipart returned 400 `admin_user: required`.

A coherent single-request fix:

1. Remove both preupload try/catch blocks. Put selected native paths directly into `payload['logo']`/`['cover_image']`.
2. When AdminRepository builds multipart, flatten nested administrator data to DRF's dotted HTML keys:

```dart
final admin = formDataMap.remove('admin_user');
if (admin is Map) {
  for (final entry in admin.entries) {
    formDataMap['admin_user.${entry.key}'] = entry.value;
  }
}
return FormData.fromMap(formDataMap);
```

3. Add to `AdminClinicProvisionSerializer`:

```python
logo = serializers.ImageField(required=False, allow_null=True)
cover_image = serializers.ImageField(required=False, allow_null=True)
```

4. Add `logo=data.get('logo')` and `cover_image=data.get('cover_image')` to `Clinic.objects.create(...)` inside the existing transaction. Validate files as branding images. Add cleanup for a database rollback after storage writes; DB transactions do not roll back object storage.

Provisioning cannot use a future clinic UUID for a prior clinic-scoped media upload. A two-stage create-then-PATCH alternative is viable, but must explicitly distinguish “clinic created, branding failed” so retries do not create duplicate clinics/users.

### A08: lead-status response is not a complete lead

Backend `ClinicLeadViewSet.partial_update:115–117` returns `LeadStatusUpdateSerializer.data`, only `{"status":"closed"}`. Frontend `ClinicLeadsRepository:103–108` parses that as a full AppointmentRequestModel, then service 600–601 replaces the existing lead. IDs, patient/contact data, reference, and notes become defaults.

Replace the successful response(s) in the backend with:

```python
return Response(self.get_serializer(lead).data)
```

Alternatively, keep the current API contract and change the Flutter repository to return the status value only, then merge it into `old.copyWith(status: ...)`. Do not parse a status-only object as a full entity. Refetch badge counts after status changes; the service currently refreshes dashboard but cached `_badgeCounts` take precedence.

### A09: one-time password-reset codes must be consumed once

`F:otp_screen.dart:117–139` calls verify-otp then forwards the same code to ResetPasswordScreen. `B:OtpService.verify_otp:289–292` deletes it. `ResetPasswordView:432–434` verifies it again. Reproduction: verify 200, reset 422 `OTP_EXPIRED`.

The smallest compatible fix is to replace the password-reset branch in `_verifyOtp` with navigation only and perform the sole verification when the new password is submitted:

```dart
if (widget.purpose == OtpPurpose.passwordReset) {
  setState(() => _isLoading = false);
  Navigator.push(context, LuxuryPageRoute(
    page: ResetPasswordScreen(
      phone: widget.targetContact,
      otpCode: code,
    ),
  ));
  return;
}
```

Label that step “Continue” for password recovery. Keep `otp_code` required in `AuthRepository.resetPassword`, matching `B:ResetPasswordSerializer:333–335`. If early server verification is a product requirement, implement a purpose-bound, expiring, single-use reset token and consume that token at final reset; the current backend issues no such token. Simply deleting final OTP verification would be a security defect.

### A10: international auth phone corruption

`F:AuthRepository.normalizePhone:41–57` converts `+447700900123` to `+971447700900123`. It affects registration, login, verify/resend OTP, recovery, and phone change. Widget country selection therefore creates numbers that authentication subsequently corrupts. Replace this method with preservation of explicit E.164 prefixes:

```dart
static String normalizePhone(String phone) {
  final value = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (value.isEmpty) return '';
  if (value.startsWith('+')) return value;
  if (value.startsWith('00')) return '+${value.substring(2)}';
  if (value.startsWith('971')) return '+$value';
  return '+971${value.replaceFirst(RegExp(r'^0+'), '')}';
}
```

Move normalization into a shared utility rather than maintaining competing widget/repository implementations. Preserve full `auth.userPhone` when prefilling inquiry forms: appointment screen 100–112 and dead product inquiry 74–78 strip country information before the widget infers the country. The phone widget also only resynchronizes when the **controller object** changes (475–482), not when its value changes; update from an explicit value/listener, guarding feedback loops and tracking the selected country.

### A11/A12: unblock clinic/admin edits

- English clinic bio: `clinic_profile_screen.dart:1447–1448` creates both controllers, but only `descArCtrl` renders at 1610. Save nevertheless posts unchanged English text at 1643. Add a visible `LtrTextFormField(controller: descEnCtrl, maxLines: 3, decoration: InputDecoration(labelText: 'Description (English)'))` with bilingual surrounding label/help. Backend readiness requires **both** descriptions plus contact (`B:portal_views.py:181–185`).
- Remove local authority over readiness: `ClinicPortalService:1198–1218` uses logo **or** cover and English **or** Arabic **or** name; backend requires logo **and** cover and both bios. `loadCatalogData:334` overwrites server checklist with those weaker local rules. Keep backend checklist authoritative after mutations; show unavailable/retry if it cannot be refreshed.
- VIP dropdown: replace `F:admin_clinic_detail_sheet.dart:532` with `String selectedTier = clinic.subscriptionTier == SubscriptionTier.vipPlatinum ? 'vip' : clinic.subscriptionTier.name;`. Options at 736–739 are `vip/featured/basic`. The old `vipPlatinum` initial value violates the dropdown invariant and is not a valid Django choice. Set `isSubmitting=true` before admin edit network save; current handler never enables its loading flag, permitting duplicate requests.

### A13/A15/A19: enforce inquiry and showcase semantics globally

- Remove `preferredDate` from the lead presentation model and **all** success/history/portal/admin renderers. Django Lead has no such field. `AppointmentRequestModel:251` defaults it to now + 2 days; new success requests use today. A refreshed request can consequently “move” its invented date. Replace date labels with `created_at` explicitly labeled “Request sent”, where useful. Remove success date/period rows at 210–219 and history detail's appointment period. Stop posting `_timeWindow = evening` at appointment_request_screen 54/195 when no preference was collected. Backend may retain legacy `preferred_time_window` for compatibility but must not manufacture/display an appointment agreement.
- Delete product-price interpolation in `F:admin_offers_screen.dart:294–295`; use brand and sponsor labels. Remove ProductModel `price`, its `toPortalJson` write at 169–170, and product-price serialization from public/portal APIs when migrating the showcase contract. Treatment and offer display prices are distinct backend fields; the user did not globally prohibit informational offer/treatment pricing.
- ProductInquiryBottomSheet is unreachable from main.dart's import graph and sends `lead_type: 'product'` at 120. Actual backend choice is `product_inquiry` (`B:apps/leads/models.py:16`), and `POST /leads/` returned 400 for `product`. Delete this dead widget under the pure-showcase design, or explicitly wire a permitted general inquiry with the correct enum and platform/product routing; do not silently invent a clinic for an unowned sponsored product. Update any surviving `leadType == 'product'` classification to the actual contract.

### A14: referral attribution is incomplete despite the right displayed URL

`B:PatientProfile.invite_link:207–209` returns `https://aestheticway.ae/invite/<referral_code>`. Root URLs expose `/r/<code_or_token>/`, not `/invite/`; `/invite/token/` failed route resolution. The API resolver route `/api/v1/referral/invite/<token>/` accepts **tokens only** (`patient_views.py:178–183`), while the published invite uses the code. Android has no invite intent filter; iOS has no associated-domain configuration; Flutter has no referral URI/install-referrer ingestion and registration never supplies attribution (`register_screen:74–79`, AuthRepository lacks `referralToken`). Displaying/copying a link alone cannot award referrals.

A coordinated fix must:

1. Publish a real root `/invite/<str:code_or_token>/` route (the existing ReferralRedirectView handles both) and test it as the shared URL.
2. Choose token or code consistently for the resolve API and registration payload. Prefer an opaque token in new links; preserve old code links server-side during migration.
3. Add verified Android app links and iOS universal links plus deferred-attribution handling; persist only the resolved pending invite token and submit it through `referral_token` automatically. Clear it after successful attribution. No manual registration field.
4. Use server balance/milestone configuration in the UI. Backend awards 10 points per qualified referral and also calls legacy milestone logic; frontend hardcodes 100/175/250 at 20/35/50 and fixed 500-point language. These are not the same accounting explanation. Define and expose the actual policy, preserving existing ledger history.
5. Retire coupon collection/verification/redemption code and stale AW-15 hints from the client under the user's current points/milestones-only requirement; handle historical rewards explicitly in backend migration rather than deleting financial/reward history blindly.

### A16: verification and throttles

A synthetic patient with `is_verified=False` received login HTTP 200 and JWTs. Login serializers 94–118 reject inactive/deleted users, not unverified users; Flutter login routes directly to the portal (74–95). Add a server-side unverified-account response and route that state to resend/verification UI. Do not rely on a client flag for permission enforcement.

Auth views set `throttle_scope`, but base settings only use AnonRateThrottle/UserRateThrottle, which do not enforce named endpoint scopes. Attach ScopedRateThrottle (plus the desired global throttles), or dedicated subclasses, to login/register/reset endpoints; attach the existing `media_upload` scope to MediaUploadView as well. Configure rates centrally and test repeated requests. Keep the OTP service's own attempt/cooldown guards; this audit is not recommending weakening them.

### A18/A20–A24/A26: remaining critical-flow repairs

| Finding | Exact location | Root cause and repair |
|---|---|---|
| Inert clinic service filter | `F:clinics_list_screen.dart:90–95,124–129,199–221`; `filter_bottom_sheet.dart:99–108` | Selected specialty/type only alter selected state/chips. Neither API request nor local predicate uses them. IDs `doctors/products/surgery` are navigation modules, not Django Category UUIDs. Remove misleading filters or bind a real fetched category UUID and supported practitioner semantics. |
| Truncated catalogs | `F:clinic_catalog_repository.dart:134–156,193–215,272–294,342–364,411–433,480–503`; `admin_repository.dart:90–122,197–229,241–269,292–320,343–371`; patient practitioners/treatments loaders | Pagination envelopes are reduced to a list, dropping `next/count`. Portal/admin/these patient screens never request the remaining pages. Fetch/page explicitly. Clinic leads are an exception: Django intentionally returns unpaginated results when page/page_size is absent; do not falsely apply a 20-row truncation finding to that endpoint. |
| Fake profile facts | `F:clinic_model.dart:255–256`; `practitioner_profile_screen.dart:91–120`; `article_detail_screen.dart:29–59,73–106`; `home_screen.dart:136–163` | Missing hours become Mon–Sat 9–9; fallback contact is +971500000000; Dubai coordinates/rating are invented; article authors are forced to doctor with 10 years. Show unavailable data, preserve actual author type, and disable contact/map actions without authoritative values. |
| VIP/featured ranking drift | `F:clinic_model.dart:177,240`; `B:clinics/serializers.py:34–38`; `F:clinics_list_screen.dart:225–230` | `is_featured` is mapped to VIP. Backend intentionally hides subscription tier and sorts internally. Client re-sorting/badging invents a tier and can disturb paid placement. Preserve server order; use an explicit approved public placement/badge field if required. |
| Metrics mismatch | `F:admin_portal_service.dart:73,78`; `B:admin_portal/views.py:95,116,140–148`; `F:clinic_portal_service.dart:194–196` | “Active users” is total active patient accounts; “today leads” is lifetime contacted leads; local “active products/articles” counts all loaded entries. Relabel accurately or add actual period/activity aggregates; do not present calculated fiction. |
| Home media drift | `F:home_feed_model.dart:30–46`; `B:home/serializers.py:47–65,69–106`; `F:home_screen.dart:305–357` | FeaturedAd parser drops `image_url`, video, clinic, tier; home carousel is built from nearby clinics instead of returned ads. Home offer serializer omits image_url, so feed offer image falls back to clinic logo even after offer image upload. Align one actual feed/render model; include intended image field. |
| Stale home feed | `B:home/views.py:26,188–218` | Cache TTL is 300 seconds and write paths do not invalidate it. Branding/offer changes may appear old on patient Home after the portal reflects them. Invalidate affected keys/versioned feed data on relevant writes or publish/document bounded freshness. |
| Lost clinic video in list flow | `B:clinics/portal_serializers.py:23,35–46`; `F:clinic_profile_screen.dart:1441–1678` | Backend supports a VIP showcase file; clinic profile dialog exposes no video picker/save argument. This is missing management UI, not a raw image-URL input. Either supply permitted native video management or remove the promise from completion claims. |
| Retry corruption | `F:auth_interceptor.dart:110–120` | Fetch reuses original finalized FormData; a 401 retry needs `FormData.clone()`. Retried 401 can also re-enter the queued error interceptor without a retry limit. Bound retries, coordinate token refresh, and use a clean retry client/error path; do not log out because a successfully refreshed request later returns a business 400. |
| Broad load coupling | `F:clinic_portal_service.dart:244–277,303–339`; `admin_portal_service.dart:253–299` | One failed request in Future.wait prevents every successful pane from committing. Track independent errors and fetch necessary pages; do not show old/empty data as “no records”. |
| Error erasure | `F:clinic_portal_service.dart:255–269`; `clinics_repository.dart:92–108`; support and badge methods | Failed profile fetch is swallowed, leaving a fabricated default active clinic; review 404 becomes empty reviews; failed counters become zero. Distinguish unavailable, unauthorized, stale, and genuinely empty. |
| Picker/dialog lifecycle | `F:luxury_image_picker_field.dart:70–91`; modal StatefulBuilder async callbacks | Native picker/save can finish after dismissal and call setState on a disposed context. Guard mounted state, dispose dialog controllers, and close picker/save ownership cleanly. |

## 5. Complete HTTP and serializer contract comparison

### 5.1 Overall result

**98 frontend HTTP callsites:** 97 resolve to a backend view supporting their requested method; one review-list call has no backend route. Method/path matching does not imply field, ownership, lifecycle, or response compatibility. No evidence supports changing the working catalog PATCH methods globally to PUT. List responses generally use `results` with pagination metadata; detail responses are flat objects. Flutter's extra support for a `data` wrapper is not harmful, but silently returning an empty list for an unexpected shape can conceal server regressions.

The generated Appendix A records every callsite, request method/path, and backend target. Some are repository methods with no active UI caller; they are identified below rather than counted as working product flows.

### 5.2 Write contracts and ignored/missing fields

| Flow | Actual backend contract | Frontend comparison and required correction |
|---|---|---|
| Register | POST `auth/register/`; full_name, phone, **required email**, password; optional referral_code/token, device_platform | Current UI requires email, so ordinary registration satisfies it. Repository's email remains optional, permitting invalid programmatic callers. Make it required. No manual referral input exists; automatic token capture is missing. No accepted terms/version is persisted by this serializer; local checkbox alone is not consent evidence. |
| Login | POST identifier/password; flat access_token/refresh_token/user | Field/key contract matches. International number rewriting and missing verification enforcement are A10/A16. |
| Verify/resend OTP | POST phone, otp_code, purpose / phone,purpose | Correct names. Email delivery is implemented, despite older phone/SMS wording. Password recovery lifecycle is A09. |
| Forgot/reset | POST phone / phone, **required otp_code**, new_password | Correct method. Optional repository OTP does not match required serializer; two-step consumption breaks normal recovery. |
| Refresh/logout | POST `refresh` / POST `refresh_token` | These deliberately different request keys are correct. Refresh response aliases are accepted correctly. Retry-body handling is defective, not request-key naming. |
| Me PATCH | Writable full_name and device_platform; phone/email read-only | Current profile UI saves full_name only, which is correct. Repository updateMe still offers phone/email; Django silently ignores them (reproduced 200). Remove these arguments; use the dedicated verified change endpoints. |
| Phone/email changes | POST new_phone/code and new_email/code | API names match. Phone changes are broken for non-UAE numbers; no UI calls these repository methods. Profile intentionally displays locked contacts but does not offer the backing change flow. |
| Media upload | Multipart **file + media_type**, optional clinic_id; flat id/url | Matches response keys. Errors swallowed by catalog resolver; invalid filenames/MIME, ownership ambiguity and temporary URLs need A01–A05 fixes. |
| Clinic profile | GET/PATCH profile; binary logo/cover/video; editable identity/bio/contact/maps/coordinates | Names/method match. Image strings removed, remove never sent, English bio invisible, phone/WhatsApp not editable in clinic dialog. Subscription/status intentionally not writable through this serializer. |
| Practitioner CRUD | name_en required; optional name_ar/title/bio/**speciality**/type/avatar/media_asset/status/order; clinic derived | Flutter correctly uses `speciality_en/ar`, not a spelling mismatch. It sends full fields without unsupported biography/phone inputs. Image string ignored; asset acceptance lacks ownership/type validation; entity response omits clinic identity, so portal model clinic fields default empty unless enriched. |
| Treatment CRUD | name_en and **category active UUID**; optional name_ar/descriptions/price/status/is_active/practitioners UUID list | Both category and category_id currently sent; backend aliases category_id only when category absent, so duplicate is unnecessary, not fatal. No duration/image/target-area fields exist. Repository removes duration_minutes. Missing category triggers 400. Create fallback to first category silently misclassifies; update injects `practitioners: []` when absent, erasing existing assignments. Preserve omitted fields on PATCH. |
| Offer create/update | title_en, original_price, offer_price, starts_at, ends_at required on create; optional descriptions/image/media_asset/treatment/status/is_active | Current add form supplies required fields. `starts_at/ends_at` campaign dates are real fields and allowed; they are not appointment booking selectors. Image strings ignored; treatment link never offered; no edit dialog invokes updateOffer. Numeric parse failure silently substitutes 1500/999 rather than validates. Negative values fail server validation; offer_price greater than original is currently allowed server-side. |
| Product create/update | name_en required; optional bilingual description/brand/sponsor; **price optional nullable**; image URL/FK; status/is_active | Product dialog correctly has no price input and supplies brand/sponsor fields backed by DB. Legacy price helper/super-admin display remains. URL+asset duplication and scoping are defective. Global brand products can have null clinic, but clinic portal always assigns its own clinic and no super-admin brand creation endpoint/UI exists. |
| Article create/update | title_en required; optional content/bilingual/title_ar, author_practitioner, URL/FK, is_published/published_at/status; slug read-only | Correct author key and image alias normalization. Author ownership check exists. Media ownership check absent. Content-en marked required in UI though backend allows blank; this is a deliberate stronger UX constraint, not an ignored field. |
| Clinic provisioning | name_en + nested admin_user(full_name,phone) required; other contact/address/tier fields optional; **no image fields** | Images are ghost inputs in the current create contract. Administrator dotted/bracket multipart mismatch explained in A07. Address controllers are serialized but never rendered, so both addresses always start empty. No maps/description provisioning fields exist. |
| Admin clinic edit | PATCH explicit contact/address/tier/status/is_featured/order/license/moderation/logo/cover/video fields | Current UI fields are backed. VIP enum mismatch; no clear-image event. Backend does **not** expose description_en/ar/google_maps_url/coordinates in update serializer; do not claim these are editable from this UI merely because they exist in Clinic. |
| Lead create | clinic, optional branch/practitioner/treatment/offer/product; patient fields; consent_accepted; lead_type choices consultation/offer/product_inquiry | Consultation/offer fields match. Hidden evening preference is misleading. Product dead widget sends invalid enum. No preferred_date exists. Backend accepts pending clinics, ignores moderation status for some referenced entities, and allows any authenticated role/guests. Derive/validate type from relations and enforce intended role/visibility rules. |
| Lead history/detail | Patient-safe summaries, IDs, reference_code, status, created_at | No preferred date; patient serialization omits internal notes correctly. Summary `logo_url` and `profile_image_url` read-only fields point at missing Clinic/Practitioner attributes, so those keys are skipped. Use logo ImageField with request context and source avatar_url. |
| Clinic lead status/note | PATCH returns **status only**; POST notes returns note object | Note contract matches. Status response misparsed as full entity. ClinicLeadSerializer has raw relation UUIDs, not the patient summaries the shared frontend parser expects; show resolved clinic/branch/practitioner names from a proper portal DTO/serializer. |
| Admin moderate | POST approve/suspend; moderation_notes accepted into audit details | Paths/methods and notes match. Product/offer/article list responses use their respective models/serializers. UI has only approve/suspend-style toggles; reject/restore constants are not equivalent to implemented controls. |
| Referral status/collect/verify/redeem | Existing backend supports points **and coupons**, status keys match frontend | Fields are largely compatible, but client model ignores points_per_referral/configuration; policy displayed differs. Collection/clinic code entry paths are legacy and have no current screen callers. Current business rule requires removing their remaining client surface/residue. |
| Push devices | POST token/platform/app_version, DELETE token path | Contract matches. Registration method has no callsite and pubspec has no Firebase Messaging client dependency/bootstrap. Backend push implementation does not mean the mobile app is actually registering real tokens. |
| Analytics | Backend POST analytics/events exists | No Flutter event-ingestion calls. ContactLauncher/MapsLauncher launch links but do not emit analytics. Dashboard tap/view counters cannot be asserted to represent this mobile client's activity. |

### 5.3 Read/query/response mismatches

- **Missing route:** GET `clinics/{id}/reviews/` (`F:clinics_repository.dart:93`); only clinic list/detail routes exist in `B:apps/clinics/urls.py:7–10`. Its catch-all converts 404 into “no reviews”. `clinicReviewSubmit` is also an unused constant without a backend route. No Review model exists in this snapshot. Keep Google rating/review count if that is the actual supported feature; remove unsupported in-app-review claims/controls.
- **Ignored practitioner city:** `PractitionersRepository:41–42` sends `city`; PractitionerFilter does not define it and the view does not read it. Add `city = CharFilter(field_name='clinic__city', lookup_expr='iexact')` if the filter is intended, or remove the parameter.
- **Ignored clinic lead search:** repository sends search, but ClinicLeadViewSet has no search_fields/SearchFilter configuration and only applies status/type/branch. The current screen locally searches fetched leads, masking this API mismatch.
- **Home ad contract:** parser reads only image rather than authoritative image_url and discards video/tier/clinic. The current home rendering ignores the returned featuredAds list. Home offer serializer omits image_url although the standalone offers serializer includes it.
- **Pagination:** `page_size` is supported by this backend; claiming it needs to be renamed per_page would be wrong. Both aliases exist. The defect is clients discarding next/count or failing to request additional pages.
- **Admin search hints:** admin clinic server search matches name/slug/license, not city (`B:admin_portal/views.py:207–214`); UI says name or city. Either include `Q(city__icontains=...)` or change the hint. Client-only search/moderation filters operate only on loaded records.
- **Detail freshness:** ProductDetailScreen and ArticleDetailScreen display passed list models; getProductDetail/getArticleDetail methods have no UI caller. Treatment and practitioner detail screens do refetch. Changed/withdrawn products/articles can remain visible from an old list until refreshed; use detail endpoints and respect 404/withdrawal.
- **Relative media origin:** backend nested serializers often instantiate children without request context; local media remains relative. Frontend resolves against fixed production origin, not an overridden API origin. Normalize on one boundary and verify local/staging paths.
- **Unsupported informational model fields:** treatment duration/downtime/target area/image; product/article category; practitioner years_of_experience/languages/ratings are not exposed by their backend models/serializers. Hiding empty optional presentation is safer than inventing defaults. Do not add unrelated Django columns merely to justify unused UI.

## 6. Mandatory business-rule scorecard

| Rule | Result against current code |
|---|---|
| No in-app payments/cart/checkout | No implemented purchase, cart, payment SDK, or checkout flow found. Product shopping-bag icons are not payment flows. |
| No appointment date/time selection | Current request form has no date picker/time grid. Offer campaign date pickers are legitimate. **Fail in semantics/data display:** evening is silently submitted and fabricated dates appear as request/appointment preferences. |
| No home services | No home-service flow found in scanned UI. Physical branch/map fields are not home-service features. |
| No regulatory numbers/authorities in UI | No reachable license input or LicenseBadge usage found. Dead `license_badge.dart` can render a license number/placeholder and should be deleted. DHA defaults in models/fixtures are residue, not evidence of currently rendered authority labels. Public backend serializers generally exclude these fields. |
| Mandatory lead confirmation | Exact Arabic text **is present**, at AppointmentSuccessScreen:122, including in English mode. Extra explanatory text is also present. Backend confirmation_message/fallbacks use English; align all channels to the frozen Arabic value if the requirement applies to API copy too. Do not report the required Arabic UI sentence as missing. |
| Top-level pure product showcase | Products is bottom-nav tab index 2 (`main_nav_screen:68–85`). Patient products have no price/cart/direct phone/WhatsApp buttons; creation dialog has no price input. **Fail:** super-admin product card still displays AED/price; API/model retain writable price/coupon-era assumptions; dead inquiry has invalid type. |
| Native images only | Reachable photo inputs use LuxuryImagePickerField. No raw image URL text input found. Google Maps URL input is a map field, not a prohibited image input. Persistence/error/removal defects remain. |
| Unified phone | Reachable phone fields use LuxuryPhoneInputField; +971 default, forced LTR, digits-only and maxLength 10 are implemented at 334–349 and 722–736. **Fail:** non-UAE auth normalization, prefill/controller-sync defects, incomplete Europe coverage. The 47-country list covers all 22 Arab League countries but omits many European countries (e.g. Luxembourg, Iceland, Malta, Baltic states, several Balkans, Ukraine). |
| Unified referral link + points/milestones | Link display/copy uses required `/invite/`; no manual registration referral input. **Fail:** route/attribution not functional, static milestone explanation differs from backend, coupon APIs/models/strings persist as legacy residue. |
| Role isolation | Login/OTP/splash route roles to separate shells; no “Preview Patient App” button found. **Fail:** cached prior-session data, arbitrary super-admin clinic fallback, inconsistent active-clinic checks, and unverified login. |

## 7. Part B — ghost fields, unnecessary UI, and dead code

Distinguish a nonexistent backing field from an existing field that is not writable in a particular endpoint. Brand/sponsor text fields are real DB-backed fields and must not be deleted as “ghosts”. Client-only theme/language/search state is also valid UI state; it does not need its own database column.

| Item | Evidence | Action |
|---|---|---|
| Admin-create clinic logo/cover | F:admin_create_clinic_dialog 434/442; B:provision serializer 92–111 | Broken contract-backed ghost inputs today. Repair A07; do not leave success UI attached to discarded values. |
| Preferred appointment date | F:appointment_request_model 251–255; success 210–219; my_requests 481/681; clinic lead detail 318; admin detail 221 | No database or serializer field. Delete fabricated preference across all roles; show actual created_at with correct label. |
| Uncollected time preference | F:appointment_request_screen 54/195 | Existing backend column, but no user input backs this value. Stop synthesizing a preference. |
| Clinic service/type filters | F:filter_bottom_sheet 99–108; clinics_list 199–221 | Selection affects decoration but not results. Remove/rebind; these are functional ghosts. |
| Product/article category labels | F:product_model 136–137; article_model 179–180; admin product subtitle 295 | No corresponding model/serializer category. Remove blank separators/category cards unless a coherent backend contract is deliberately introduced. |
| Fake hours/doctor facts/contact/map fallback | F:clinic_model 255; article_detail 39–58,96–100; practitioner_profile 103–120 | Delete invented values. Disable actions without source data. |
| Patient profile contact editing APIs | F:auth_repository 262–278; profile_screen 465–497 | Actual profile fields are intentionally read-only. Remove obsolete updateMe arguments, preserve locked display, and wire dedicated verified-change UI if offered. |
| Clinic English description controller | F:clinic_profile_screen 1448/1643, no rendered English input | Invisible controller is not an input. Render required English bio or stop claiming bilingual completion. |
| Admin address controllers | F:admin_create_clinic_dialog 50–51,127–128 | Never rendered, always initially empty. Add actual address fields if provisioning should collect them; otherwise remove controllers/empty payloads. |
| Review UI/repository | F:clinics_repository 87–108; B:clinics URLs | Unsupported endpoint is not an empty database. Delete unsupported in-app-review contract/UI or explicitly implement a review feature later. Do not fabricate reviews. |
| `LicenseBadge` | F:core/widgets/license_badge.dart, unreachable | Delete. It renders `ترخيص معتمد: ...` or LICENSE_PLACEHOLDER; violates current rule if reintroduced. No active caller found. |
| ProductInquiryBottomSheet | F:features/products/presentation/widgets/product_inquiry_bottom_sheet.dart | Unreachable by imports; invalid enum; fails unowned-brand clinic semantics. Delete under current pure-showcase flow or explicitly redesign/wire permitted general inquiry. |
| Section/distance widgets | F:core/widgets/distance_chip.dart, luxury_section_header.dart, section_header.dart | Unreachable from main.dart import graph. Candidate deletion after checking external consumers/tests; import-graph evidence is not a dynamic symbol-use guarantee. |
| Duplicate clinic practitioner forms | F:clinic_profile_screen 63–405; clinic_practitioners_screen 41–499 | Both reachable. Consolidate into one form to prevent validation/media drift. Neither file is wholly dead. |
| Duplicate treatment creation | F:clinic_profile_screen 408–755; clinic_treatments_screen 40–480 | Profile shortcut always sends empty practitioners; dedicated screen has assignment selection. Consolidate around the real category UUID contract. |
| Offer update method with no edit action | F:clinic_catalog_repository 310; service 664; clinic_offers_screen 31,452 | Only create/status/delete UI found. Implement edit if required, or remove unused method/promise. |
| Branch CRUD with no form | F:clinic_portal_service 1160–1182; setup_checklist 234 | Checklist “branch” navigates to general profile; no create/edit/delete branch screen invokes service methods. Add scoped branch editor or remove the dead navigation promise. |
| Unwired device registration | F:device_token_service 35; pubspec dependencies | No FCM token acquisition/register caller. Either integrate actual mobile push lifecycle or document it as unavailable; backend push tests alone do not establish a mobile feature. |
| Legacy referral coupon paths | F:referral_repository 21–49; referral_service 194–228,254–479; locale 624/631–632 | Remove AW-15 demo/code helpers and unused coupon strings from client. Keep historical backend records until a migration is specified. Current referral screen does not render an AW-15 code chip, so do not mislabel dead constants as live inputs. |
| Test shortcuts in production lead repository | F:leads_repository 55–66,79–88,114–115 | Move FLUTTER_TEST fake-success/empty-history paths into injected test doubles. These make “live” test names misleading and can conceal request-contract failures. |

Reachability is based on static Dart imports starting at main.dart and constructor/caller references. `AdminCreateClinicDialog.show`, `ContactOptionsSheet.show`, and `FilterBottomSheet.show` are valid static entry points even though a naive constructor search finds no external `new` call; they were **not** classified as dead.

## 8. Part C — hints, labels, visual polish, and UX

### 8.1 Concrete wording/localization defects

| Location | Current problem | Replacement/action |
|---|---|---|
| F:admin_clinics_screen:69 | Says “name or city”; server search does not search city | “Search clinic by name…” / “ابحث باسم العيادة…” until city search is implemented. |
| F:clinic_leads_screen:94 | Search looks global but is local/unpaginated; repository search ignored | Attach supported search_fields or state the loaded-result scope and implement pagination deliberately. |
| F:clinic_profile_screen:1614 | English mode says Description (Arabic), with English hint “Highlight your medical expertise…” | Keep Arabic-language field label explicit and show an Arabic example; add distinct English field. |
| F:clinic_profile_screen:1601 | Maps hint is raw `https://maps.google.com/...` without copying guidance/validation | “Paste the clinic's Google Maps share link” / “الصق رابط مشاركة موقع العيادة من خرائط جوجل”. URL field is allowed for maps. |
| F:clinic_profile_screen:644/669 | Generic treatment description text “وصف للمزايا وشروط الجلسة...” | Use “اذكر هدف الإجراء وما يحتاج المراجع معرفته قبل الاستفسار” and an equivalent language-specific example. Do not present unbacked duration/downtime inputs. |
| F:clinic_offers_screen:198/222; clinic_treatments:271 | `e.g. 1500/999/750` mixed with seeded real field values | Start numeric values empty, show `1500.00` as hint only, validate invalid/negative input rather than substituting prices. Keep prices only for offers/treatments. |
| F:admin_create_clinic_dialog:504/559 | UI marks clinic/admin phones required; optional creation contact semantics not explained | Clearly distinguish public clinic contact from admin login identity; backend validation must normalize both. |
| F:admin_create_clinic_dialog:510; admin_clinic_detail_sheet:704 | WhatsApp only English label | “واتساب العيادة (اختياري)” / “Clinic WhatsApp (optional)”; number remains LTR. |
| F:luxury_phone_input_field:597,749 | Default local-number hint not country-specific | Country-aware national-number example without replacing the selected international prefix. Keep maxLength 10 per user requirement. |
| F:clinic_practitioners_screen:203/249 and clinic profile copies | English `e.g.` inside English-language fields in Arabic UI | Lower severity: input-language-specific examples can be intentional. Localize surrounding guidance, not the required English sample itself; do not blanket-delete all bilingual examples. |
| F:admin_lead_detail_screen:221/227 | Missing keys select_date, preferred_time display raw key strings | Delete misleading preference rows under A13, or use existing localized request-created label. |
| F:practitioner_profile_screen:293/323 | Missing about_doctor_title and performed_procedures_title keys | Add bilingual “About the practitioner” / “نبذة عن الممارس”, “Treatments” / “العلاجات”; avoid forcing every author/practitioner to doctor. |
| F:referral_service:129–144,167–188; referral_screen:387 | “used your code”/fixed milestone and voucher explanation | Explain actual server points policy and automatic invite-link attribution; remove legacy coupon-entry wording. |
| F:admin_portal_service:73/78 | Misleading active-users/today-leads labels | “Patient accounts”/“Contacted requests”, or add actual activity/date aggregates. |

The evidence includes the complete 282-line input/label/picker match inventory and 542 input/action contexts. Many conventional labels (name, email, notes, password) are adequate; genericity alone is not evidence of a broken field.

### 8.2 Contrast defects measured from source

Alpha-composited sRGB contrast calculations, not screenshot guesses:

| Foreground/background | Contrast |
|---|---:|
| Champagne `#C8A97E` on white | **2.23:1** |
| Light hint `#334155` at alpha .45 on `#EEF2F6` | **2.28:1** |
| Dark hint `#64748B` at alpha .45 on `#192542` | **1.66:1** |
| Theme dark hint `#818E9E` at alpha .45 on `#111A2E` | **2.07:1** |

These are below 4.5:1 for normal body text; champagne-on-white is also below the usual 3:1 nontext/large-text target. Source sites include phone hints 751, country-picker search 601, practitioner field hints 205/228, profile dialog 1603/1619, and AppTheme dark hint 105–107. `filter_bottom_sheet.dart:303–305` uses champagne for selected chip text on a light surface; country picker 671–685 does likewise. Use a darker semantic accent such as primarySoftNavy for selected light-mode text and fully opaque/much stronger hint text, then verify actual composites. Do not globally darken image-overlay white text that correctly sits over a dark scrim.

### 8.3 Layout, lifecycle, and accessibility risks requiring Flutter/device verification

- SilverButton (`F:core/widgets/silver_button.dart:114–130,135–145`) uses a fixed-height Row and unconstrained Text. Long Arabic translations or large text scale can overflow; add Flexible text with wrapping/appropriate height, and test narrow widths. Use a semantic/focusable button primitive rather than only GestureDetector for keyboard/accessibility states.
- CategoryGrid fixes four columns and childAspectRatio .82 (`:104–108`); long Arabic labels and 200% text scale need real layout checks. This is a risk, not a reproduced RenderFlex failure.
- Clinic/admin sheets use 88–92% fixed screen heights plus keyboard padding; verify small displays, keyboard-open save controls, safe areas, and screen-reader order.
- Several status/error labels use small light accent colors on white; dark/light screenshots are still required. Existing contrast tests cover specific snackbars, not every screen.
- Numerous screens compute `isDark` before a nested ListenableBuilder; ensure theme/language changes rebuild the values used by the visible subtree. Locale changes should update both text and direction consistently.
- Image fallback deliberately conceals network failures with a brand emblem. It is a good patient fallback but poor editing feedback: a saved field should show upload/attachment failure or an accessible-image warning without exposing signed URLs in logs.
- Do not keep a modal editable while a save is in flight; provide a visible progress/error state and prevent double submission. Mounted/context/controller lifetime checks are necessary around native pickers and dismissible dialogs.

## 9. Part D — backend changes required

| Priority | Backend files | Required change |
|---|---|---|
| P0 | practitioners/products/articles/offer portal serializers; their model image properties | Scope FK ownership/type, asset-first URL resolution, clear legacy URL on new asset or removal; A02/A05. |
| P0/P1 | clinics/portal_permissions.py; core/authentication.py; leads/views/clinic_views.py; media permissions | One consistent resolved tenant, deny suspended/deleted clinics, remove arbitrary super-admin tenant fallback; A17. |
| P1 | admin_portal/serializers.py, services/clinic_provisioning.py | Accept/persist branding files on provisioning with coherent nested multipart input; protect storage cleanup on DB failure. |
| P1 | leads/views/clinic_views.py | Return full lead after status update, or coordinate documented status-only client merging. |
| P1 | accounts/serializers.py, views.py, throttle classes | Enforce verification state, endpoint-specific rates; preserve required email/OTP contract; avoid user enumeration in forgot-password's current validation error. |
| P1 | config/urls.py; referrals/views/patient_views.py; accounts/models.py | Implement unified invite route, code/token compatibility, defined server policy and automatic registration attribution contract. |
| P1 | products/serializers.py, portal_serializers.py; leads/serializers.py | Remove price from showcase read/write contracts and patient product summaries; preserve historical DB values until safe migration. Brand-owned product inquiries require a real platform routing policy if enabled. |
| P1 | leads/serializers.py | Validate moderation status and publication for requested entities; enforce clinic active/approved visibility and relation/lead-type consistency. Current pending clinic acceptance is broader than public discovery. |
| P1/P2 | clinics/portal_serializers.py; admin_portal/serializers.py | Make clear/replace semantics explicit; reject a submitted malformed media string rather than pretending it changed. Keep request-specific read-only fields deliberate. |
| P2 | leads/serializers.py:34/51 | Fix nonexistent summary sources: actual clinic logo and practitioner avatar_url with consistent URL formatting. |
| P2 | home/serializers.py, home/views.py | Expose intended offer image and usable ad schema, invalidate cached affected home data. |
| P2 | practitioners/filters.py; leads/views/clinic_views.py; admin_portal/views.py | Add intended city/search behavior or remove unsupported parameters/hints. |
| P2 | media/models.py:147 and migration | Set FileField max_length e.g. 512; UUID-structured paths currently exceed default 100 and storage shortens random filenames. A long clinic/type path can become unsavable. Keep randomized object keys intact. |
| P2 | media/serializers.py, validators.py | Bind each media_type to raster-image/video type and tier, use uniform size/signature/deep checks, reject unsupported files clearly. Generic upload currently permits a video labeled as an image type. |
| P2 | admin_portal/serializers.py:206 | video_ad_file lacks clinic serializer's VIP/type/duration validation. Share validation across admin/clinic endpoints and clarify authorized tier override. |
| P2 | clinics model ImageFields, media model cleanup | Replacements leave old files/orphan upload assets; add transaction-aware garbage collection and referenced-asset deletion rules. Do not delete a referenced image on replace failure. |
| P2 | config/urls.py, deployment media config | Supply local development media serving when DEBUG, and document/test production CDN/media delivery. Do not expose arbitrary local files or weaken storage privacy. |
| P2 | clinics/views.py geo distance; home/views.py:138–154 | PostgreSQL branch assumes ST_DistanceSphere/ST_MakePoint; no PostGIS enablement migration is supplied. Verify actual database extension before enabling geo queries; standard PostgreSQL can fail. Units differ too: PostgreSQL distance is metres, SQLite uses squared degrees, frontend calls it kilometres. Normalize real distance to kilometres or hide distance. |
| P2 | admin_portal/provisioning service, accounts uniqueness | Normalize admin identity before duplicate checks; enforce case-insensitive email uniqueness consistently. User.email is not DB-unique although login uses get(email__iexact), so duplicates can create ambiguous login. |
| P2 | leads/models.py:23–24,59 | Five-digit random unique reference can collide without retry. Replace with a sufficiently large reference namespace or database-backed sequence plus retry/constraint handling. |
| P2 | tests/test_auth.py + shared test setup | Missing role fixtures and non-isolated OTP cache state; repair test infrastructure without weakening production OTP limits. |

Minimal optional DEBUG-only media URL addition is Django's `static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)` guarded by settings.DEBUG and local filesystem storage. Production nginx/CDN serving is separate; the audit does not assert that production lacks such a route.

## 10. Verification results and engineering release gates

### 10.1 Executed checks

- Backend full suite, unchanged source: **561 passed, 2 failed, 3 errors**, 566 collected tests, approximately 10.8 seconds under Python 3.12 / pinned Django 5.2.4 / DRF 3.15.2. Errors are missing `clinic_staff_user`, `patient_user`, and `clinic_admin_user` fixtures in accounts role tests. Failures are OTP tests receiving a lockout instead of the expected invalid/not-found response. Running the not-sent test alone passed; running it after lockout failed, establishing cache-order dependence. This is **not** evidence that production OTP should be weakened.
- `manage.py makemigrations --check --dry-run`: **No changes detected** against attached model/migration files.
- Python AST parsing: **347/347** files parsed, no syntax errors.
- Router comparison: **97/98** frontend callsites have a matching method+route; missing reviews endpoint reproduced with Django URL resolution.
- Isolated probes: octet-stream upload 400; image/png upload 201; clinic binary PATCH persisted; string branding PATCH ignored image but saved text; explicit JSON-null logo removal worked; stale practitioner avatar reproduced; foreign media attachments accepted for practitioner/product/article and rejected for offer with a foreign clinic ID; treatment required category and empty assignment clearing reproduced; status-only PATCH reproduced; Me phone/email ignored; branding provisioning dropped; nested multipart rejected; invite root missing; suspended clinic lead access accepted; unverified login issued JWT; password verify/reset failed second consumption; invalid product enum rejected.
- Offline storage-signature check: unmodified signed URL validated under synthetic keys, same URL plus Flutter `v` failed signature calculation. 392-character signed URL rejected by both product/article URL fields. No storage service was contacted.
- Source import graph: five Dart files unreachable from main.dart; missing literal translations: four; supported dial-code entries: 47; contrast figures are in evidence.
- Flutter runtime/analyzer/tests were **not run** because the SDK is unavailable. The proposed Dart/Django replacement snippets were not installed into the repos or integration-tested as a combined patch. Local backend probes verify the current defects, not the future patched system.

### 10.2 Prioritized execution plan

1. **P0 — media and isolation:** implement atomic/fail-visible client upload handling, scoped asset association, URL precedence/signed-URL preservation, explicit removal, session cache cleanup with in-flight guards. Regression-test old URL + new FK and clinic A → logout → clinic B on one process.
2. **P1 — unblock core tasks:** fix provisioning file contract, password-reset OTP lifecycle, full-lead status handling, international auth, VIP dropdown, English clinic bio, authoritative checklist. Verify save → GET → restart/reload, not only snackbar.
3. **P1 — enforce product rules:** remove product prices in Super Admin/API, fake dates/preferences, license dead widget, and coupon residue; finish real invite attribution. Preserve the exact Arabic success sentence. Retain real offer campaign validity dates.
4. **P1/P2 — discovery and management correctness:** actual category UUID selection, preserve omitted PATCH relationships, pagination, working filters, missing offer/branch editing, accurate metrics, real rather than invented facts, mobile push/event integration where promised.
5. **P2 — polish and operations:** localization, semantic contrast tokens, responsive text/keyboard states, native picker error handling, storage cleanup/path length, production media/database/geo validation, test-fixture/cache repairs.

### 10.3 Acceptance matrix for the repair phase

| Flow | Minimum evidence to call it fixed |
|---|---|
| Each image field | Select native file → upload/attach → correct response URL → successful image GET → GET entity after restart preserves it; failure leaves form open; explicit remove survives restart |
| Old media replacement | Existing legacy URL + new asset returns new image, including offer/practitioner; no persisted expiring URL dependency |
| Auth retry | Expired access token during multipart saves retries once with a replayable body; no queued-error loop or false logout on ordinary 400 |
| Ownership | Patient/foreign-clinic/wrong-type asset rejected on every entity endpoint; no first-clinic super-admin fallback |
| Two-account session | Prior user's clinic/leads/referral/favorites absent before and after in-flight old requests finish |
| Password recovery | One code, one successful reset; expired/used/wrong code rejected; old refresh token invalidated as designed |
| Provisioning | Clinic + admin created once with branding; validation failure leaves no partial DB identity; storage cleanup tested |
| Lead status | Same ID/reference/contact/notes after status update and reload; badges reflect new counts |
| Inquiry-only rules | No date/time selectors or fabricated date/time agreement; exact Arabic confirmation; no final appointment state |
| Product showcase | All three portals free of product price/cart/buy/direct contact controls and price creation inputs |
| Referral | Actual `/invite/` URL opens on installed Android/iOS, deferred attribution survives installation where supported, registration sends token automatically, points/ledger awarded once |
| Search/paging | More than 20 records, second-page matches, category UUID filtering, country search, and server search all tested with real contract fixtures |
| Visual | Arabic/English × dark/light × narrow/wide × keyboard × large text scale screenshots/widget checks; readable hints and no overflow |

A release assertion must identify the exact frontend/backend revisions and storage mode tested. Passing only mocked Flutter “live” tests or string-stripping Django tests is insufficient to establish end-to-end image persistence.

## Appendix A — every identified Flutter HTTP callsite

This table checks actual Django URL resolution and allowed method. `OK` refers only to method/path, not a claim that the surrounding flow is correct. Detailed field/response/lifecycle mismatches are in sections 3–5. IDs below are represented by `{id}`.

| Frontend callsite | Method + path under `/api/v1/` | Backend view/action | Route check |
|---|---|---|---|
| `core/network/auth_interceptor.dart:94` | POST `auth/refresh/` | `accounts.views.RefreshView` | OK |
| `core/services/device_token_service.dart:52` | POST `notifications/devices/` | `notifications.views.DeviceTokenListCreateAPIView` | OK |
| `core/services/device_token_service.dart:77` | DELETE `notifications/devices/{id}/` | `notifications.views.DeviceTokenDestroyAPIView` | OK |
| `core/services/media_upload_service.dart:52` | POST `media/upload/` | `media.views.MediaUploadView` | OK |
| `core/services/support_service.dart:69` | GET `app/support-info/` | `app_config.views.SupportInfoView` | OK |
| `features/admin/data/admin_repository.dart:82` | GET `admin/dashboard/` | `admin_portal.views.AdminDashboardAPIView` | OK |
| `features/admin/data/admin_repository.dart:106` | GET `admin/clinics/` | `admin_portal.views.AdminClinicViewSet.list` | OK |
| `features/admin/data/admin_repository.dart:126` | GET `admin/clinics/{id}/` | `admin_portal.views.AdminClinicViewSet.retrieve` | OK |
| `features/admin/data/admin_repository.dart:131` | POST `admin/clinics/{id}/suspend/` | `admin_portal.views.AdminClinicViewSet.suspend` | OK |
| `features/admin/data/admin_repository.dart:139` | POST `admin/clinics/{id}/activate/` | `admin_portal.views.AdminClinicViewSet.activate` | OK |
| `features/admin/data/admin_repository.dart:152` | POST `admin/clinics/` | `admin_portal.views.AdminClinicViewSet.create` | OK |
| `features/admin/data/admin_repository.dart:168` | POST `admin/clinics/{id}/reset-admin-password/` | `admin_portal.views.AdminClinicViewSet.reset_admin_password` | OK |
| `features/admin/data/admin_repository.dart:177` | DELETE `admin/clinics/{id}/` | `admin_portal.views.AdminClinicViewSet.destroy` | OK |
| `features/admin/data/admin_repository.dart:186` | PATCH `admin/clinics/{id}/` | `admin_portal.views.AdminClinicViewSet.partial_update` | OK |
| `features/admin/data/admin_repository.dart:213` | GET `admin/leads/` | `admin_portal.views.AdminLeadAPIView` | OK |
| `features/admin/data/admin_repository.dart:233` | GET `admin/leads/{id}/` | `admin_portal.views.AdminLeadDetailAPIView` | OK |
| `features/admin/data/admin_repository.dart:253` | GET `admin/offers/` | `admin_portal.views.AdminOfferModerationViewSet.list` | OK |
| `features/admin/data/admin_repository.dart:273` | POST `admin/offers/{id}/approve/` | `admin_portal.views.AdminOfferModerationViewSet.approve` | OK |
| `features/admin/data/admin_repository.dart:281` | POST `admin/offers/{id}/suspend/` | `admin_portal.views.AdminOfferModerationViewSet.suspend` | OK |
| `features/admin/data/admin_repository.dart:304` | GET `admin/products/` | `admin_portal.views.AdminProductModerationViewSet.list` | OK |
| `features/admin/data/admin_repository.dart:324` | POST `admin/products/{id}/approve/` | `admin_portal.views.AdminProductModerationViewSet.approve` | OK |
| `features/admin/data/admin_repository.dart:332` | POST `admin/products/{id}/suspend/` | `admin_portal.views.AdminProductModerationViewSet.suspend` | OK |
| `features/admin/data/admin_repository.dart:355` | GET `admin/articles/` | `admin_portal.views.AdminArticleModerationViewSet.list` | OK |
| `features/admin/data/admin_repository.dart:375` | POST `admin/articles/{id}/approve/` | `admin_portal.views.AdminArticleModerationViewSet.approve` | OK |
| `features/admin/data/admin_repository.dart:383` | POST `admin/articles/{id}/suspend/` | `admin_portal.views.AdminArticleModerationViewSet.suspend` | OK |
| `features/admin/data/admin_repository.dart:402` | GET `admin/analytics/` | `admin_portal.views.AdminPlatformAnalyticsAPIView` | OK |
| `features/appointment_lead/data/leads_repository.dart:70` | POST `leads/` | `leads.views.patient_views.LeadCreateAPIView` | OK |
| `features/appointment_lead/data/leads_repository.dart:127` | GET `leads/my/` | `leads.views.patient_views.MyLeadsAPIView` | OK |
| `features/appointment_lead/data/leads_repository.dart:159` | GET `leads/{id}/` | `leads.views.patient_views.MyLeadDetailAPIView` | OK |
| `features/appointment_lead/data/leads_repository.dart:166` | GET `leads/my/count/` | `leads.views.patient_views.MyLeadsCountAPIView` | OK |
| `features/articles/data/articles_repository.dart:41` | GET `articles/` | `articles.views.ArticleListAPIView` | OK |
| `features/articles/data/articles_repository.dart:65` | GET `articles/{id}/` | `articles.views.ArticleDetailAPIView` | OK |
| `features/auth/data/auth_repository.dart:91` | POST `auth/register/` | `accounts.views.RegisterView` | OK |
| `features/auth/data/auth_repository.dart:103` | POST `auth/verify-otp/` | `accounts.views.VerifyOtpView` | OK |
| `features/auth/data/auth_repository.dart:145` | POST `auth/login/` | `accounts.views.LoginView` | OK |
| `features/auth/data/auth_repository.dart:178` | POST `auth/resend-otp/` | `accounts.views.ResendOtpView` | OK |
| `features/auth/data/auth_repository.dart:193` | POST `auth/forgot-password/` | `accounts.views.ForgotPasswordView` | OK |
| `features/auth/data/auth_repository.dart:214` | POST `auth/reset-password/` | `accounts.views.ResetPasswordView` | OK |
| `features/auth/data/auth_repository.dart:231` | POST `auth/logout/` | `accounts.views.LogoutView` | OK |
| `features/auth/data/auth_repository.dart:245` | GET `auth/me/` | `accounts.views.MeView` | OK |
| `features/auth/data/auth_repository.dart:280` | PATCH `auth/me/` | `accounts.views.MeView` | OK |
| `features/auth/data/auth_repository.dart:296` | POST `auth/me/phone/change/request/` | `accounts.views_profile_change.PhoneChangeRequestAPIView` | OK |
| `features/auth/data/auth_repository.dart:308` | POST `auth/me/phone/change/confirm/` | `accounts.views_profile_change.PhoneChangeConfirmAPIView` | OK |
| `features/auth/data/auth_repository.dart:324` | POST `auth/me/email/change/request/` | `accounts.views_profile_change.EmailChangeRequestAPIView` | OK |
| `features/auth/data/auth_repository.dart:336` | POST `auth/me/email/change/confirm/` | `accounts.views_profile_change.EmailChangeConfirmAPIView` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:140` | GET `clinic-portal/practitioners/` | `practitioners.portal_views.ClinicPractitionerPortalViewSet.list` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:165` | POST `clinic-portal/practitioners/` | `practitioners.portal_views.ClinicPractitionerPortalViewSet.create` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:178` | PATCH `clinic-portal/practitioners/{id}/` | `practitioners.portal_views.ClinicPractitionerPortalViewSet.partial_update` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:186` | DELETE `clinic-portal/practitioners/{id}/` | `practitioners.portal_views.ClinicPractitionerPortalViewSet.destroy` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:199` | GET `clinic-portal/treatments/` | `treatments.portal_views.ClinicTreatmentPortalViewSet.list` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:240` | POST `clinic-portal/treatments/` | `treatments.portal_views.ClinicTreatmentPortalViewSet.create` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:257` | PATCH `clinic-portal/treatments/{id}/` | `treatments.portal_views.ClinicTreatmentPortalViewSet.partial_update` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:265` | DELETE `clinic-portal/treatments/{id}/` | `treatments.portal_views.ClinicTreatmentPortalViewSet.destroy` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:278` | GET `clinic-portal/offers/` | `offers.portal_views.ClinicOfferPortalViewSet.list` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:303` | POST `clinic-portal/offers/` | `offers.portal_views.ClinicOfferPortalViewSet.create` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:316` | PATCH `clinic-portal/offers/{id}/` | `offers.portal_views.ClinicOfferPortalViewSet.partial_update` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:324` | PATCH `clinic-portal/offers/{id}/` | `offers.portal_views.ClinicOfferPortalViewSet.partial_update` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:335` | DELETE `clinic-portal/offers/{id}/` | `offers.portal_views.ClinicOfferPortalViewSet.destroy` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:348` | GET `clinic-portal/products/` | `products.portal_views.ClinicProductPortalViewSet.list` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:378` | POST `clinic-portal/products/` | `products.portal_views.ClinicProductPortalViewSet.create` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:396` | PATCH `clinic-portal/products/{id}/` | `products.portal_views.ClinicProductPortalViewSet.partial_update` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:404` | DELETE `clinic-portal/products/{id}/` | `products.portal_views.ClinicProductPortalViewSet.destroy` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:417` | GET `clinic-portal/articles/` | `articles.portal_views.ClinicArticlePortalViewSet.list` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:447` | POST `clinic-portal/articles/` | `articles.portal_views.ClinicArticlePortalViewSet.create` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:465` | PATCH `clinic-portal/articles/{id}/` | `articles.portal_views.ClinicArticlePortalViewSet.partial_update` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:473` | DELETE `clinic-portal/articles/{id}/` | `articles.portal_views.ClinicArticlePortalViewSet.destroy` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:481` | GET `categories/` | `treatments.views.CategoryListAPIView` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:511` | GET `clinic-portal/profile/` | `clinics.portal_views.ClinicProfileAPIView` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:523` | PATCH `clinic-portal/profile/` | `clinics.portal_views.ClinicProfileAPIView` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:537` | GET `clinic-portal/branches/` | `clinics.portal_views.ClinicBranchPortalViewSet.list` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:553` | POST `clinic-portal/branches/` | `clinics.portal_views.ClinicBranchPortalViewSet.create` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:563` | PATCH `clinic-portal/branches/{id}/` | `clinics.portal_views.ClinicBranchPortalViewSet.partial_update` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:573` | DELETE `clinic-portal/branches/{id}/` | `clinics.portal_views.ClinicBranchPortalViewSet.destroy` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:581` | GET `clinic-portal/profile/setup-checklist/` | `clinics.portal_views.ClinicSetupChecklistAPIView` | OK |
| `features/clinic_portal/data/clinic_catalog_repository.dart:588` | POST `clinic-portal/profile/submit-for-review/` | `clinics.portal_views.ClinicSubmitForReviewAPIView` | OK |
| `features/clinic_portal/data/clinic_leads_repository.dart:17` | GET `clinic-portal/dashboard/` | `clinics.portal_views.ClinicDashboardAPIView` | OK |
| `features/clinic_portal/data/clinic_leads_repository.dart:24` | GET `clinic-portal/badges/` | `clinics.badge_views.ClinicBadgesAPIView` | OK |
| `features/clinic_portal/data/clinic_leads_repository.dart:59` | GET `clinic-portal/leads/` | `leads.views.clinic_views.ClinicLeadViewSet.list` | OK |
| `features/clinic_portal/data/clinic_leads_repository.dart:80` | GET `clinic-portal/leads/{id}/` | `leads.views.clinic_views.ClinicLeadViewSet.retrieve` | OK |
| `features/clinic_portal/data/clinic_leads_repository.dart:103` | PATCH `clinic-portal/leads/{id}/` | `leads.views.clinic_views.ClinicLeadViewSet.partial_update` | OK |
| `features/clinic_portal/data/clinic_leads_repository.dart:113` | POST `clinic-portal/leads/{id}/notes/` | `leads.views.clinic_views.ClinicLeadViewSet.notes` | OK |
| `features/clinics/data/clinics_repository.dart:57` | GET `clinics/` | `clinics.views.ClinicListAPIView` | OK |
| `features/clinics/data/clinics_repository.dart:83` | GET `clinics/{id}/` | `clinics.views.ClinicDetailAPIView` | OK |
| `features/clinics/data/clinics_repository.dart:93` | GET `clinics/{id}/reviews/` | `—` | **NO ROUTE** |
| `features/home/data/home_repository.dart:35` | GET `home/feed/` | `home.views.HomeFeedAPIView` | OK |
| `features/offers/data/offers_repository.dart:35` | GET `offers/` | `offers.views.OfferListAPIView` | OK |
| `features/offers/data/offers_repository.dart:61` | GET `offers/{id}/` | `offers.views.OfferDetailAPIView` | OK |
| `features/practitioners/data/practitioners_repository.dart:48` | GET `practitioners/` | `practitioners.views.PractitionerListAPIView` | OK |
| `features/practitioners/data/practitioners_repository.dart:59` | GET `practitioners/{id}/` | `practitioners.views.PractitionerDetailAPIView` | OK |
| `features/products/data/products_repository.dart:36` | GET `products/` | `products.views.ProductListAPIView` | OK |
| `features/products/data/products_repository.dart:60` | GET `products/{id}/` | `products.views.ProductDetailAPIView` | OK |
| `features/referral/data/referral_repository.dart:15` | GET `referral/my-status/` | `referrals.views.patient_views.ReferralStatusAPIView` | OK |
| `features/referral/data/referral_repository.dart:23` | POST `referral/collect-code/` | `referrals.views.patient_views.CollectCodeAPIView` | OK |
| `features/referral/data/referral_repository.dart:32` | POST `clinic-portal/discount-codes/verify/` | `referrals.views.clinic_views.VerifyDiscountCodeAPIView` | OK |
| `features/referral/data/referral_repository.dart:44` | POST `clinic-portal/discount-codes/redeem/` | `referrals.views.clinic_views.RedeemDiscountCodeAPIView` | OK |
| `features/treatments/data/treatments_repository.dart:42` | GET `treatments/` | `treatments.views.TreatmentListAPIView` | OK |
| `features/treatments/data/treatments_repository.dart:62` | GET `treatments/{id}/` | `treatments.views.TreatmentDetailAPIView` | OK |
| `features/treatments/data/treatments_repository.dart:76` | GET `categories/` | `treatments.views.CategoryListAPIView` | OK |

## Appendix B — evidence and reproduction notes

The companion `CODEX_AUDIT_EVIDENCE.zip` contains:

- `file_manifest.json` / `.csv`: all 966 supplied files, text/binary classification, line count, SHA-256, and honest inspection type.
- `frontend_network_calls.json`, `endpoint_comparison.json`, `routes.json`: all 98 frontend callsites and 187 resolved Django API/view routes, including DRF format/router variants.
- `serializer_contracts.json`: 89 serializer classes and writable/required/nullability/source attributes.
- `ui-input-action-contexts.json`, `inputs.txt`, `rules.txt`, `api_calls.txt`: reproducible full-source scans and UI action/input contexts. A search match alone is not classified as a defect.
- `probes.json` / `.txt`: current-code isolated endpoint reproductions, using synthetic users and temporary storage.
- `signed-url.json`, `contrast.json`, `localization.json`, `import_graph.json`, `python-syntax.json`: supporting static/offline checks.
- `backend-tests.txt`, `otp-isolated.txt`, `otp-single.txt`, `migrations-check.txt`: exact test/check outcomes.
- Audit scripts used to generate those results. `probe.py` migrates an in-memory SQLite database under testing settings. Run only against disposable audit settings; it does not patch the source repositories. There is no live R2/production validation in these artifacts.

Example backend suite invocation, using a test-only dummy secret:

```sh
SECRET_KEY=audit-only-test-key-not-for-production \
USE_R2_STORAGE=False USE_S3=False \
DJANGO_SETTINGS_MODULE=config.settings.testing PYTHONDONTWRITEBYTECODE=1 \
/workspace/work/audit/venv/bin/pytest -q -p no:cacheprovider
```

The environment contained no Flutter/Dart executable. Backend checks used the attachment's pinned requirements installed into an audit-only virtual environment. Existing documentation that says a fix was completed is not a substitute for these checks. Findings and replacement snippets are reviewable proposals; implementation, device validation, deployment, and data cleanup remain subsequent work.

## Appendix C — complete source paths for abbreviated references

All paths below are repository-relative. References such as `F:clinic_profile_screen` in the clinic-portal discussion mean the clinic-portal path here, not the patient clinic-profile path.

| Component | Complete path |
|---|---|
| Clinic portal profile and catalog dialogs | `lib/features/clinic_portal/presentation/screens/clinic_profile_screen.dart` |
| Dedicated practitioner form/list | `lib/features/clinic_portal/presentation/screens/clinic_practitioners_screen.dart` |
| Dedicated treatment form/list | `lib/features/clinic_portal/presentation/screens/clinic_treatments_screen.dart` |
| Offer form/list | `lib/features/clinic_portal/presentation/screens/clinic_offers_screen.dart` |
| Clinic portal service | `lib/features/clinic_portal/services/clinic_portal_service.dart` |
| Clinic catalog repository | `lib/features/clinic_portal/data/clinic_catalog_repository.dart` |
| Clinic lead repository | `lib/features/clinic_portal/data/clinic_leads_repository.dart` |
| Clinic checklist UI | `lib/features/clinic_portal/presentation/widgets/clinic_setup_checklist_card.dart` |
| Clinic lead detail/list | `lib/features/clinic_portal/presentation/screens/clinic_lead_detail_screen.dart`, `lib/features/clinic_portal/presentation/screens/clinic_leads_screen.dart` |
| Patient request/success/history | `lib/features/appointment_lead/presentation/screens/appointment_request_screen.dart`, `lib/features/appointment_lead/presentation/screens/appointment_success_screen.dart`, `lib/features/appointment_lead/presentation/screens/my_requests_screen.dart` |
| Patient lead DTO/repository | `lib/features/appointment_lead/models/appointment_request_model.dart`, `lib/features/appointment_lead/data/leads_repository.dart` |
| Auth repository | `lib/features/auth/data/auth_repository.dart` |
| Auth login/register/OTP/reset | `lib/features/auth/presentation/screens/login_screen.dart`, `lib/features/auth/presentation/screens/register_screen.dart`, `lib/features/auth/presentation/screens/otp_screen.dart`, `lib/features/auth/presentation/screens/reset_password_screen.dart` |
| Admin clinic creation | `lib/features/admin/presentation/screens/admin_create_clinic_dialog.dart` |
| Admin clinic editing | `lib/features/admin/presentation/screens/admin_clinic_detail_sheet.dart` |
| Admin product/offer/article moderation | `lib/features/admin/presentation/screens/admin_offers_screen.dart` |
| Admin service/repository | `lib/features/admin/services/admin_portal_service.dart`, `lib/features/admin/data/admin_repository.dart` |
| Clinic/practitioner/product/article DTOs | `lib/features/clinics/models/clinic_model.dart`, `lib/features/practitioners/models/practitioner_model.dart`, `lib/features/products/models/product_model.dart`, `lib/features/articles/models/article_model.dart` |
| Patient clinic discovery/repository | `lib/features/clinics/presentation/screens/clinics_list_screen.dart`, `lib/features/clinics/data/clinics_repository.dart` |
| Patient clinic profile | `lib/features/clinics/presentation/screens/clinic_profile_screen.dart` |
| Patient product/article/practitioner detail | `lib/features/products/presentation/screens/product_detail_screen.dart`, `lib/features/articles/presentation/screens/article_detail_screen.dart`, `lib/features/practitioners/presentation/screens/practitioner_profile_screen.dart` |
| Referral service/model/repository/screen | `lib/features/referral/services/referral_service.dart`, `lib/features/referral/models/referral_model.dart`, `lib/features/referral/data/referral_repository.dart`, `lib/features/referral/presentation/screens/referral_screen.dart` |
| Home screen/feed model | `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/home/data/models/home_feed_model.dart` |
| Backend clinic profile serializer/view | `apps/clinics/portal_serializers.py`, `apps/clinics/portal_views.py` |
| Backend asset models/validators/serializer/view | `apps/media/models.py`, `apps/media/validators.py`, `apps/media/serializers.py`, `apps/media/views.py` |
| Backend admin serializers/provisioning | `apps/admin_portal/serializers.py`, `apps/admin_portal/services/clinic_provisioning.py` |
| Backend lead status/creation endpoints | `apps/leads/views/clinic_views.py`, `apps/leads/views/patient_views.py` |
| Backend account OTP/reset | `apps/accounts/views.py`, `apps/accounts/serializers.py`, `apps/accounts/services/otp.py` |
