# Visual-test photographs (never production content)

- `portrait_photo.png`: Flutter Gallery Assets 1.0.2, `lib/people/square/sandra.png`, copyright Chromium Authors, BSD notice in `LICENSE-flutter-gallery-assets.txt`. This is a photographic layout fixture; the subject is not represented as an Aesthetic Way clinician.
- `fragrance_photo.jpg`: Frontend Mentor product-preview-card educational challenge photograph, mirrored by Kevin Powell at commit `c18b8b17a7dd2c0250bb945af3613121e7fe47c2`, `images/image-product-desktop.jpg` ([source](https://github.com/kevin-powell/product-preview-card-component-main/tree/c18b8b17a7dd2c0250bb945af3613121e7fe47c2), [challenge](https://www.frontendmentor.io/challenges/product-preview-card-component-GO7UmttRfa)). Used only to exercise cosmetic-bottle framing in educational regression captures; no ownership, sponsor relationship, medical claim or production listing is implied.
- Earlier labelled `packaging_fixture.png` and `portrait_frame_fixture.png` remain available for the historical decode tests and baseline provenance.

None of these photographs is in the Flutter asset manifest or used by `lib/`. All preview records, including ratings and prices, are explicitly test data. They prove rendering, never live delivery or provenance of production records. Approved reference photographs are not used as fixtures or application media.

`intentionally_corrupt_image.fixture` is original plain text, deliberately not an image. FileImage/codec regression tests read it without modification. Keeping this source immutable for the process lifetime avoids unlinking a Windows-mapped corrupt buffer before the VM finalizer runs; genuine decoding failure and provider assertions remain required. This file is not a bundled application asset or photograph.
