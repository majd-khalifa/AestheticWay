# PR #9: Windows test regression follow-up

21 October 2026 (Asia/Damascus). Starting commit:
`f357f9628752836a402a0a538ab4f08af2ee7c82`. Existing branch and PR #9 remain stacked
on PR #8, `codex/performance-latency-readiness`.

The reported native Windows run used Flutter 3.41.5, framework `2c9eb20739`,
engine `052f31d115`, Dart 3.11.3: the same revisions as the Linux environment.
An SDK-version mismatch therefore does not explain the reported failures.

## A. Six file-backed media previews

The old warm-up reconstructed `FileImage(File(relativePath).absolute)` and
hard-coded resize widths before configuring the view. The actual widgets parse
file URIs and construct their own `ResizeImage` from measured constraints and
DPR. On Windows, the warmed absolute path can retain mixed separators while
`File.fromUri` normalizes them. Flutter `FileImage` equality compares the **path
string**, not file identity. Resize keys also include width, height, policy and
upscaling. A different key means the warm-up provides no decoded frame to the
mounted image. The numeric size guesses also made the fixture sensitive to
future layout or DPR changes.

`pumpWidget` can then start FileImage IO in Flutter's fake async zone. The old
settler entered `tester.runAsync` and resolved the provider again, but ImageCache
returned the **already pending completer**. Entering another zone does not move
the existing IO/timer chain to that zone. Its three-second wait expired; the
exception was queued by `runAsync`, then surfaced at the later `takeException`.
This explains the six file-backed cases while asset-only previews passed.

The replacement reads every mounted Image's actual provider and local
ImageConfiguration, obtains its exact key, evicts only pending entries, and
starts the real decode inside `runAsync`. The timeout remains three seconds.
The helper owns/removes its listeners and disposes its ImageInfo references.
Flutter's reassembly hook reconnects mounted ImageState objects after the cache
replacement; the helper pumps the scheduled frame before awaiting completion.
It then requires each mounted RawImage to have actual decoded pixels. Errors
are rethrown in the test zone with their stack rather than deferred to an
unrelated assertion.

There is no shared mutable fixture file or global cache flush. Test-file
processes have independent bindings/caches; temporary files have unique native
paths. This addresses deterministic fake-clock/cache ownership rather than
assuming concurrent tests merely need longer timeouts.

Added tests cover mixed Windows separator keys, resize-key identity, eight cold
file/URI cases at DPR 1/1.25/2.75/3 and widths 137/211.3, Unicode/space/# paths,
and corrupt bytes. A delayed native File proxy reproduces a stalled fake-clock
load on every host while still reading real PNG bytes and using the real
Flutter decoder. Product and practitioner preview assertions also require the
intended file-backed primary image, not an emblem fallback.

## B. Eight clinic-profile golden comparisons

The original harness pinned part of TextTheme, but not primary typography or
explicit button text styles. It loaded only a regular face while requesting
bold weights, leaving synthesis/font fallback host-dependent. Setting platform
through ThemeData.copyWith does not reconstruct defaults already selected when
AppTheme was created. The viewport also inherited the native test view's DPR
and physical dimensions. TargetPlatformVariant does not change native Skia or
the OS font renderer, so two passing Linux variants did not establish native
Windows compatibility. This harness weakness predates the media-first commit.

The v2 **test-only** harness pins viewport/DPR, primary/body/button/app-bar/input
font ownership, real regular/bold font fixtures, SDK icons, density and touch
targets. All eight comparisons remain exact, with all subsequent staff/offer
navigation assertions. No production UX was changed. Original Linux PNGs are
unchanged; reviewed v2 candidates have a separate owned directory and provenance
README. The change from the old Linux fixture pixels is intentional fixture
typography normalization, not acceptance of arbitrary Windows percentage error.

Native CI supplied actual/diff PNGs after the first follow-up. The SDK and
font/media fixture hashes match Linux exactly, yet native Windows retained:

| V2 comparison against Linux | Different pixels |
|---|---|
| English Light | 11,783 (3.58%) |
| English Dark | 11,697 (3.55%) |
| Arabic Light | 7,791 (2.37%) |
| Arabic Dark | 7,714 (2.34%) |

The isolated diffs follow glyph/icon outlines. Logos and bottom background
regions are pixel-identical. Separate native Windows comparisons and capture
runs produce byte-identical PNGs. This confirms residual **native rasterizer**
differences after controlling fonts, SDK, density and viewport. Pinning inputs
alone cannot make a Linux raster baseline universal.

The reliable strategy now combines exact native-owned `linux/` and `windows/`
raster baselines with one common `geometry/` snapshot per theme/language. Bounds,
font/style/color/direction properties of every Text and Icon must match that
shared contract. Geometry records 1/64 dp layout precision; all raster comparisons
still use zero tolerance. Missing native baselines fail. The Windows baselines
come from CI run 39562770335 at source `17abbf9`; all four were visually reviewed
against Linux and their diffs before copying. Original Linux PNGs are untouched.
No production UX was changed to force raster similarity.

The first native run also found a new negative test deleting a corrupt native
file while a decode buffer still held a Windows file lock. That negative fixture
now reads and closes the native file before handing real invalid bytes to the
real decoder through its FileImage proxy. The decode-failure assertion remains;
no test is skipped and no placeholder substitutes for pixels.

The user initially supplied mismatch percentages but no native actual/diff PNGs. Percentages alone could not establish the cause; the native evidence above now
distinguishes it from font/viewport fixture leakage. The native Linux/Windows CI
matrix records SDK/fixture hashes, runs comparisons/full tests, and uploads
candidate renders/diffs for ongoing review. CI candidate generation never updates committed baselines or changes a
failed comparison into a pass.

## Validation and boundaries

Linux verification completed: all **508 tests pass** (the existing 496 plus
12 new harness cases), `flutter analyze` reports **0 issues**, Dart formatting
and `git diff --check` pass. All 42 media previews and eight exact v2 golden
variants pass. CI run 39562770335 confirms Ubuntu full-suite success and all six formerly
failing media previews on native Windows. Windows found the residual raster
ownership and negative-fixture cleanup issues described above. The corrected
native-host baselines/common-geometry follow-up is undergoing final verification;
its result is recorded separately rather than inferred from Linux.

Only tests, test fixtures, CI and verification tooling/documentation are in
scope. Production Flutter code, Django and release-signing files remain
unchanged. Clinic, Super Admin, Patient, Security, Performance and Media-first
history is preserved. No PR is merged. A simulated Windows TargetPlatform is
explicitly distinct from native Windows execution or a physical device test.
