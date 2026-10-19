# Clinic Partner Portal — device fixes

Date: 2026-10-19. Incremental patch base: `cfadfd23790a6a727abb1bcce09d8b374c08a0f8`.

## Implemented

- Shared Dio connection timeout is 30 seconds; send and receive timeouts are 60 seconds. The native image picker requests 1200 × 1200 maximum dimensions with quality 78. Actual encoded size depends on the source image and platform.
- Existing profile multipart uploads and uploaded-URL/explicit-null handling are preserved. Catalog uploads retain both the uploaded asset UUID and URL. No JSON content type is forced onto multipart requests.
- Profile and dashboard now read the latest canonical clinic inside their service listener; successful saves no longer leave those headers bound to the original clinic object.
- A location sheet replaces the raw Maps URL input. It offers seven emirates, UAE district presets, an interactive map pin, explicit place search, coordinate entry, and Arabic/English street/building address inputs. A preset or pin must be confirmed before an initially unset location can be saved. Cancellation leaves the profile unchanged.
- Location saves persist `city`, `emirate`, `address_ar`, `address_en`, `latitude`, `longitude`, and the generated `google_maps_url`. Coordinates and links use seven decimal places to match Django's precision. Existing locations/media are omitted from unrelated edits.
- The Location card displays a map preview when coordinates exist and exposes Update Location / Open in Google Maps. The maps link is passed to the external map launcher.
- The profile uses one 140px editorial banner with an overlapping 72px logo. Empty media uses a gradient and a single clinic icon avatar. Dashboard/profile location labels join nonempty values and have bilingual UAE fallbacks.
- Circular image pickers contain an icon; upload instructions appear below the circle. Long field labels wrap.
- Setup checklist titles remain readable without strikethrough; completed items show an emerald status pill and retain their existing actions.
- Clinic Portal input labels remain visible above their existing example hints. Loaded treatment categories appear in a bounded dropdown; the paginated category directory remains available for larger catalogs.
- Profile and dedicated Treatments use the same treatment editor. The editor loads practitioners and listens for collection updates, so assignment chips appear when practitioners arrive.
- Staff/treatment management buttons have adaptive text colors and bordered outlines. Staff, treatments, offers, products, and articles use consistent thumbnail/content/action rows; offer/treatment rows show price information. Product rows remain a brand showcase without prices.
- Profile catalog deletion asks for confirmation and displays API failures. Edit actions use the respective existing editors, including treatment editing from the profile.

## Backend reference and compatibility

The supplied `backend_latest.zip` was extracted separately and treated as read-only. All **636 archive files** match their original contents. Archive SHA-256:

`a858e2aafbadadaa3c6b80c2c652aa1a20ae85bc6e4582ff16c9887b8aaef98d`

The latest reference contains `PortalImageInputField` / `ScopedPortalImageMixin` for catalog images and clinic profile string-media handling in `ClinicProfilePortalSerializer.to_internal_value()`. Profile coordinates and emirate/city/address fields are writable. Flutter uses those existing contracts; no Django files were modified.

Normal profile image replacements use binary multipart PATCH. Mixed replace/remove saves pre-upload the replacement and PATCH JSON with the returned URL plus explicit `null`. Catalog image edits pre-upload and submit `media_asset` plus the corresponding image URL; removal sends both representations as `null`.

## Verification

- `flutter analyze --no-pub`: **0 issues**.
- `flutter test --no-pub --reporter expanded`: **214 tests passed**.
- Nine new regression cases cover canonical clinic refresh, location service/repository payloads, empty location labels, category UUID selection, location confirmation/cancel, and 320px layouts with enlarged text in Arabic/English and light/dark themes.
- Four additional font-loaded component preview runs passed. These previews show the header, circular image picker, and catalog row; they are not screenshots from the user's physical device.
- Existing profile tests now scroll to the logout control, accommodating the taller catalog rows, and assert the new Maps button copy.
- `git diff --check` passed.

## Operational notes

No authenticated production requests, uploads, deployment, or physical-device network tests were performed. Local checks do not establish that the live server matches the supplied backend archive or that production storage works.

The embedded map uses `flutter_map` / `latlong2` and OpenStreetMap tiles with visible attribution. Place search uses Nominatim only on explicit submission, scopes results to the UAE, limits results to four, and prevents rapid submissions. Its separate unauthenticated Dio client never attaches application bearer credentials. Search errors preserve preset/pin selection as a fallback. Public tile/search service limits still apply; use a managed provider when production traffic requires it. This implementation does not request device GPS permission.

All changes remain in the local working tree for review. The incremental patch applies to the base above; the cumulative patch targets the existing local `origin/main` reference `9c6d211d618ba33bdca2413d0b3bcf109ab9873a`. Do not apply both patches. The workspace ZIP already contains all changes.
