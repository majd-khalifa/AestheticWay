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

The user supplied mismatch percentages but no native actual/diff PNGs. Their
exact differing pixels cannot be independently attributed to a particular glyph
or rasterizer from percentages alone. The controlled source findings above are
confirmed; native evidence is needed to confirm the complete residual cause.
The new native Linux/Windows CI matrix records the matching SDK and fixture
hashes, runs comparisons/full tests, and uploads candidate renders/diffs for that
purpose. CI candidate generation never updates committed baselines or changes a
failed comparison into a pass.

## Validation and boundaries

Linux verification completed: all **508 tests pass** (the existing 496 plus
12 new harness cases), `flutter analyze` reports **0 issues**, Dart formatting
and `git diff --check` pass. All 42 media previews and eight exact v2 golden
variants pass. Native Linux/Windows CI evidence is pending the branch push;
that result will be recorded separately rather than inferred from Linux.

Only tests, test fixtures, CI and verification tooling/documentation are in
scope. Production Flutter code, Django and release-signing files remain
unchanged. Clinic, Super Admin, Patient, Security, Performance and Media-first
history is preserved. No PR is merged. A simulated Windows TargetPlatform is
explicitly distinct from native Windows execution or a physical device test.
