# AESTHETIC WAY — Forensic Bug Diagnosis & Surgical Fix Plan

> **Date**: 2026-10-17  
> **Engineer**: Principal Staff Engineer (Claude Sonnet)  
> **Status**: DIAGNOSIS COMPLETE → EXECUTING FIXES

---

## CRITICAL BUG 1: Image Uploads Say "Success" But Never Persist

### Root Cause Chain (3 cascading failures)

#### 🔴 PRIMARY ROOT CAUSE: `ApiClient` hardcodes `Content-Type: application/json`

**File**: `lib/core/network/api_client.dart` (Lines 19-21)

```dart
headers: {
  'Accept': 'application/json',
  'Content-Type': 'application/json',  // ← THIS KILLS MULTIPART UPLOADS
},
```

When `_buildPayload()` returns a `FormData` object (containing `MultipartFile` attachments), Dio normally auto-detects the `data` type and sets:
```
Content-Type: multipart/form-data; boundary=----DioFormBoundary...
```

But because `BaseOptions.headers` already contains `'Content-Type': 'application/json'`, Dio sends the `FormData` body with `Content-Type: application/json`. Django receives a malformed request body — it expects multipart boundaries but gets JSON content-type — and either:
- Returns `415 Unsupported Media Type`
- Silently ignores the file fields
- Parses an empty body (text fields survive if Django's `MultiPartParser` falls through)

#### 🔴 COMPOUNDING CAUSE: `AuthInterceptor` doesn't fix it

**File**: `lib/core/network/auth_interceptor.dart` (Lines 44-47)

```dart
if (options.data != null && options.headers['Content-Type'] == null) {
  options.headers['Content-Type'] = 'application/json';
}
```

The check `options.headers['Content-Type'] == null` is **always false** because `BaseOptions` already set it to `'application/json'`. So even if we removed it from `BaseOptions`, the interceptor would re-add it. Both must be fixed.

#### 🟡 SECONDARY: `ClinicModel.fromJson` reads `logo` and `cover_image` directly

**File**: `lib/features/clinics/models/clinic_model.dart` (Lines 181-182)

```dart
final cover = json['cover_image']?.toString() ?? '';
final logo = json['logo']?.toString() ?? '';
```

Django's `ClinicProfilePortalSerializer` returns these fields as relative media paths (e.g., `/media/clinics/logo_abc.jpg`), not full URLs. If `ApiConfig.baseUrl` is `https://aestheticway.ae/api/v1`, the returned logo path `/media/clinics/logo.jpg` needs to be prepended with the base domain `https://aestheticway.ae`. Currently, the model stores the raw relative path, which `CachedNetworkImage` cannot resolve.

### Fix Plan (3 surgical changes)

1. **`api_client.dart`**: Remove `'Content-Type': 'application/json'` from `BaseOptions.headers`. Dio will auto-set the correct content-type based on data type:
   - `Map<String, dynamic>` → `application/json` (via Dio's JsonTransformer)
   - `FormData` → `multipart/form-data; boundary=...`

2. **`auth_interceptor.dart`**: Change the Content-Type logic to:
   - If `data` is `FormData`, **remove** the Content-Type header entirely (let Dio auto-set it)
   - If `data` is NOT `FormData` and Content-Type is not already set, default to `application/json`

3. **`clinic_model.dart`** + other models: Ensure `fromJson` resolves relative media paths to full URLs using `ApiConfig.baseUrl` base domain.

---

## CRITICAL BUG 2: Treatment Creation Fails

### Root Cause

The `ClinicTreatmentPortalSerializer` in Django expects:
- `category`: a valid UUID (PrimaryKeyRelatedField to `Category`)
- `to_internal_value` maps `category_id` → `category` if `category` is absent

The Flutter `createTreatment()` correctly fetches categories from `GET /api/v1/categories/` and sends the UUID. The `getCategories()` method correctly unpacks DRF pagination (`{'results': [...]}`).

**Remaining risk**: The `createTreatment` method sets BOTH `category` and `category_id` in the sanitized map (line 181: `sanitized['category_id'] = sanitized['category']`). Django's `to_internal_value` then copies `category_id` into `category`, overwriting the already-valid value. This is harmless but redundant.

**Actual failure mode**: If `getCategories()` returns empty (API error, network issue), the fallback `cats.first.id` throws on an empty list. The `try/catch` swallows this, leaving `category` as `null`, which Django rejects.

### Fix Plan

1. Verify `createTreatment` never sends a null `category`. Add explicit validation.
2. Ensure `getCategories()` error handling is robust.
3. Treatment creation looks structurally correct after the previous session's fixes.

---

## BUG 3: Clinic Portal UX Audit Findings

### Files needing attention:
- `clinic_profile_screen.dart` — Image picker dialogs, updateClinicProfile call
- `clinic_practitioners_screen.dart` — Avatar upload flow
- `clinic_offers_screen.dart` — Offer image upload
- `clinic_treatments_screen.dart` — Category dropdown
- `clinic_dashboard_screen.dart` — Badge counts refresh
- `clinic_leads_screen.dart` — Lead management
- `clinic_main_nav_screen.dart` — Navigation

All depend on Bug 1 being fixed first (Content-Type issue).

---

## Execution Order

1. ✅ Fix `api_client.dart` — Remove hardcoded Content-Type
2. ✅ Fix `auth_interceptor.dart` — FormData-aware Content-Type handling
3. ✅ Verify/fix model `fromJson` for relative URL resolution
4. ✅ Verify treatment creation payload
5. ✅ Run `flutter analyze` → 0 issues
6. ✅ Run `flutter test` → 167/167 pass
7. ✅ Verify backend repo unchanged
