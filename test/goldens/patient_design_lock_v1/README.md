# Approved patient design baseline, v1

This baseline family records the explicitly approved production UI change. Historical original and `clinic_profile_v2` baselines remain untouched.

The native renderer owns its raster: `linux/` or `windows/`. Comparisons remain exact. `geometry/` contains one common set of layout/style snapshots, quantized to 1/64dp, for both native hosts and TargetPlatform variants. Candidate captures are reviewed before adoption; CI never updates committed expectations automatically.

Pinned Flutter 3.41.5, logical 390×844, DPR 3, capture ratio 1, scale 1, canonical Android presentation. The patient production fonts are bundled Playfair Display/Noto Sans Arabic and loaded explicitly in the visual harness; Material Icons and the retained fixture typography are pinned as before. Provenance/hashes are in `provenance.json`.
