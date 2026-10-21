# Reference-fidelity recovery baselines

Intentional Patient Portal composition changes following the independent PR10 visual review. All historical `patient_design_lock_v1` and `clinic_profile_v2` baselines remain unchanged.

Native Linux and native Windows own separate exact rasters. Shared geometry/style assertions retain the existing 1/16dp precision. No skips, broad tolerances, automatic baseline approval or production changes to accommodate raster differences. Linux captures were reviewed locally. All four native Windows candidates were captured from a7922ee in CI run39620681391 and visually reviewed before adoption. All common geometry/style JSONs match Linux exactly. See provenance.json. The initial missing-baseline failure was expected and is not full-suite Windows approval; final native verification is published in PR10 Checks.
