# Reference-fidelity recovery baselines

Intentional Patient Portal composition changes following the independent PR10 visual review. All historical `patient_design_lock_v1` and `clinic_profile_v2` baselines remain unchanged.

Native Linux and native Windows own separate exact rasters. Shared geometry/style assertions retain the existing 1/16dp precision. No skips, broad tolerances, automatic baseline approval or production changes to accommodate raster differences. Linux captures were reviewed locally. Native Windows candidates must be captured and reviewed in CI before adding `windows/`; that initial missing-baseline result is not Windows approval.
