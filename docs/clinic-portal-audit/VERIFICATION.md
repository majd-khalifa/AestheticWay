# Verification record / سجل التحقق

Base main: `b402d3bf7cc46c73cc1f142c7e93c4066e92d594`. Branch: `codex/clinic-portal-contract-remediation`.

## Flutter — Linux execution environment

Flutter 3.41.5 / Dart 3.11.3. Canonical Patient goldens retained; no skipped or weakened image assertions.

| Check | Result |
|---|---|
| `dart format .` | Clean, 229 Dart files considered |
| `flutter analyze` | Zero issues |
| `flutter test --reporter expanded` | **774 passed, 0 failed** |
| Focused treatment/gallery/video regressions with render capture | **21 passed** |
| Detached base before-category render harness | **4 passed** (not part of the final 774) |
| `git diff --check` | Clean |
| Django source changes | **0**, all 393 hashes unchanged |

The new tests add 21 cases to the existing 753-case suite. Five old category cases were rewritten in place to stop mocking APIs absent from d1023b0. No category success path is falsely represented as supported. Assertions cover typed local guards, actual no-network behavior, paged read/select/error semantics and form preservation; future API write acceptance cases are in the handoff.

Real image files are decoded in widget tests. Actual multipart image bytes, returned asset UUID, explicit clinic ownership and MIME fields are asserted. Video tests use real MP4 signature reads and deterministic platform events for 2-second duration; **native codec execution is not claimed**. Host file/stream I/O is flushed alongside fake-time widget continuations, with explicit completion and no stuck loading state assertions.

## Native hosted CI

The existing [Flutter visual regressions workflow](https://github.com/majd-khalifa/AestheticWay/actions/workflows/flutter-visual-regressions.yml) runs Flutter 3.41.5 on **ubuntu-24.04 and windows-2022**. It runs existing real-decoding and Patient golden tests, analyzer and the full suite; this change additionally captures the Clinic Portal EN/AR Light/Dark renders as review artifacts. Baselines are not overwritten in the checkout used for assertions.

The dedicated Clinic Portal PR's Checks tab is the authoritative native CI result for its tested head SHA. Hosted Windows execution is separate from this Linux workspace; no physical Windows, Android or iOS device test is claimed here. No Android signing or iOS/release workflow change is included.

## Controlled Django source execution

Supplied archive label: d1023b0. Django 5.2.4 / DRF 3.15.2 / Python 3.12.14 / pytest 9.1.1. Disposable SQLite and local test storage only. No production credentials, JWT issuance, R2 access or production writes.

- Existing treatment/profile/branches/dashboard/checklist/practitioner/offer/product/article/media/lead source suites: **96 passed**.
- `apps/media/tests/test_media_hardening_b02_b07.py`: **9 passed** (suspended/deleted ownership, unparseable duration, 25MP bounds and page-size ceiling).
- [Controlled request ledger](controlled-django-contracts.json): **67 responses**, including actual 404/405 category rejection, treatment/practitioner persistence/foreign ID denial, three gallery uploads, per-asset removal/foreign permission rejection, real MP4 save/reload/public delivery mapping, logo/cover direct multipart, and four typed catalog image association/preserve/clear pipelines.
- `tool/audit_clinic_contracts.py` refuses a non-testing persistent database and checks backend file hashes before/after. It never calls production. The script assumes a trusted supplied backend source root with compatible test dependencies; do not point it at arbitrary untrusted code.

Reproduce the supplemental ledger with compatible Django test dependencies installed:

```sh
PYTHONDONTWRITEBYTECODE=1 python tool/audit_clinic_contracts.py \
  --backend-root /path/to/read-only/backend-d1023b0 \
  --output /path/to/local/controlled-django-contracts.json
```

Source-only script execution cannot prove production CDN configuration or mobile restart persistence. Complete the device acceptance checklist in the [bilingual handoff](../CLINIC_PORTAL_FULL_AUDIT_FOR_ALI.md) before declaring live delivery verified.

**نتائج Linux مثبتة محلياً، ونتائج Windows/Ubuntu المستضافة تؤخذ من Checks للـSHA المختبر.** اختبارات Django محلية ومعزولة دون تعديل ملف واحد. لا تمثل اختبارات الكاميرا أو فك الفيديو الأصلي أو R2 على جهاز حقيقي. نجاح دورة الاستشارة على أندرويد منقول عن صاحب المشروع، وليس تنفيذاً جديداً هنا.

## Windows fixture correction discovered by hosted CI

The first bounded Windows Clinic Portal run caught an invalid test adapter response in the new video save/reopen scenario (`test/clinic_media_contract_test.dart`): it echoed the input device filename into `video_ad_file`. On Windows, `C:\...` is not a valid backend media URL, so `ClinicModel` correctly discarded it and “Remove saved video” was absent. Linux masked the invalid fixture by resolving its `/...` absolute path against the configured server origin. Real Django returns a storage URL (independently demonstrated by the MP4 contract probe), not the client's filename.

The adapter now returns an explicit test-only canonical HTTPS storage URL after save and preserves null removal. The test still asserts the original native input path, actual file signature/duration preflight, lazy playback/disposal, independent cover, reopened saved URL and removal. No production resolver was loosened, no assertion removed and no timeout increased. CI runs the 21 Clinic Portal cases with a bounded diagnostic step before the full suite so a stall cannot obscure their result.

**صححنا بيانات الاختبار، لا عقد الإنتاج:** كان المحاكي يعيد مسار ملف الجهاز بدلاً من رابط التخزين. يقبل الاختبار الآن رد الخادم الصحيح ويؤكد الرابط المحفوظ بعد إعادة فتح المحرر، مع بقاء فحوص الملف والتشغيل والحذف والغلاف كما هي. لا تغيير في Django أو محلل الوسائط الإنتاجي لهذا التصحيح.
