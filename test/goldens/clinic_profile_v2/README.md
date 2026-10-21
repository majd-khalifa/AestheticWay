# Clinic profile golden ownership, v2

These fixtures use a pinned **test-only** Android presentation on both
`TargetPlatform.android` and `TargetPlatform.windows` test variants. A variant
changes framework defaults; it does not emulate another native renderer.

The original four `../patient_clinic_*.png` files remain unchanged as historical
Linux provenance. They were captured with incomplete font ownership. V2 is an
explicit harness migration, not a production design change or a relaxed pixel
comparison. All eight test cases and staff/offer navigation assertions remain.

V2 pins:

- Flutter 3.41.5 / Dart 3.11.3, framework `2c9eb20739`, engine `052f31d115`.
- Logical viewport 390 × 844, device pixel ratio 3, capture ratio 1, text scale 1.
- Android theme, standard density, padded Material targets.
- Bundled DejaVu Sans regular **and real bold**, including primary typography,
  explicit button styles, app bar and input text. Material Icons from that SDK.

| Font | SHA-256 |
|---|---|
| DejaVuSans.ttf | `57f73e11f51999432bf7ab22ce55b6f945d5eca1bf824404cfa9ec2e3718c84e` |
| DejaVuSans-Bold.ttf | `a4c5bc453ca281d90ea079e596da7ae0dfeb5777497c29ec254e76d97ff6f890` |
| SDK MaterialIcons-Regular.otf | `d9865b671a09d683d13a863089d8825e0f61a37696ce5d7d448bc8023aa62453` |

Both native owners passed all eight exact raster tests and the shared geometry
contract in [verification run 39564633002](https://github.com/majd-khalifa/AestheticWay/actions/runs/39564633002).
The full suites passed 508/508 on both Ubuntu 24.04 and Windows Server 2022.
This does not certify an untested Windows build or SDK.

The existing DejaVu license covers both font fixtures. No production font,
asset registration, widget, theme or signing configuration is changed.

## Review and comparison

`linux/` owns the reviewed Linux renders; `windows/` owns native Windows
Server 2022 renders from [CI run 39562770335](https://github.com/majd-khalifa/AestheticWay/actions/runs/39562770335),
source commit `17abbf96a8d87a10c7de02f416830853f243c270`. Fonts and SDK hashes
match, but native font/icon rasterization still differs. Independent Windows
captures were byte-identical. See `provenance.json` for hashes.

`geometry/` contains **one common** theme/language contract for text/icon bounds,
fonts, styles, colors and directions. Every native host must match it; layout is
recorded at 1/64 dp precision to avoid floating-point JSON noise. This is an
additional assertion, not a raster threshold. Pixel comparison stays exact.

Native OS selection uses `dart:io Platform.operatingSystem`, not the simulated
TargetPlatformVariant. Missing/unsupported host baselines fail; there is no Linux
fallback on Windows and no automatic approval of an unknown renderer.

Normal runs use Flutter's exact comparator: no tolerance, skip, host-name
fallback or automatic baseline generation. Missing baselines fail. CI runs on
native Linux and Windows with the same SDK, uploads environment/fixture hashes,
and captures separate candidate PNGs for review even if comparison fails.
Candidate generation writes only to the CI temporary directory, never these
committed expectations.

To propose a harness/design baseline change, render candidates first:

```sh
flutter test test/patient_portal_visual_test.dart --plain-name "Clinic profile golden" \
  --update-goldens --dart-define=PATIENT_GOLDEN_CAPTURE_DIR=/absolute/review-directory
```

Use a native Windows directory when running on Windows. Review all themes and
languages, actual pixel diffs and the environment manifest before copying an
approved candidate into its native host directory. Keep the common geometry
contract in sync only when a reviewed layout change requires it. CI cannot approve its own output. A native-renderer
difference must be investigated from its PNG/diff; it must never be converted
into a percentage allowance. Native verification results and limits belong in
[the regression report](../../../docs/PR9_WINDOWS_TEST_REGRESSION_REPORT.md).
