# Image display forensic fix

Date: 2026-10-19. Working-tree base: `53e56ada7399342bd5c2ec8401dac9b97f8ce1c4`.

## Confirmed causes and fixes

1. **Empty aliases masked actual images.** All six domain parsers used null-coalescing chains. For example, `{"image_url":"","image":"https://storage.example/new.png"}` selected the empty string and never reached the valid URL. `ApiConfig.firstMediaUrl()` now selects the first supported, nonblank string without stringifying objects. Canonical computed serializer URLs retain precedence over legacy fields when populated.
2. **Bare storage names were rejected by the renderer.** A value such as `offers/new.png` survived the old API resolver unchanged and was rejected by `LuxuryImage`, producing an immediate placeholder. Storage-relative names now resolve under `/media/`; `/media/...`, `media/...`, and protocol-relative URLs also resolve correctly. Relative URLs use the configured API origin instead of always going to the production domain, fixing development/staging media requests.
3. **Valid asset/device sources were treated as missing images.** `LuxuryImage` and `LuxuryAvatar` previously only loaded network images. The shared resolver now chooses `NetworkImage`, `FileImage`, or `AssetImage` as appropriate and retains bounded image decoding. Existing local picker paths and file URIs render without becoming HTTP requests. Asset paths remain asset paths.
4. **Some consumers bypassed the shared renderer.** Eleven direct entity `Image.network` renderers across the patient, clinic, and admin portals now use `LuxuryImage`; article author avatars use the shared avatar resolver. The clinic hero gallery accepts the same supported sources and removes duplicate cover/gallery entries.
5. **Identity thumbnails showed covers rather than logos.** Clinic dashboard and admin clinic identity thumbnails now bind their primary image to the uploaded logo, with the cover as a secondary source.
6. **Image absence and fallback identity were mixed in offer parsing.** `OfferModel.imageUrl` no longer becomes a clinic logo when the offer has no photo. The renderer owns the fallback hierarchy, so an actual offer image always remains the primary source.
7. **Clinic-shaped JSON could abort parsing before displaying an image.** Product/article parsers now tolerate a clinic UUID or omitted clinic instead of casting every clinic value to a map. Nested/flat clinic logos and article author avatars use the same nonblank alias rules.
8. **Admin mixed-media uploads used the wrong dependency/scope.** `AdminRepository` constructed the global media uploader even when a custom API client was supplied. It now shares its configured client/uploader and passes the target clinic ID for pre-uploads during mixed replace/remove updates. The actual repository has no catalog `_resolveMediaAssetPayload` method: admin media writes use `_buildPayload`; catalog creation is owned by `ClinicCatalogRepository`.

No signed URL is decoded, reconstructed, or given a cache-busting query string. Outer whitespace is trimmed; encoded paths and query values remain intact. A pending primary image request shows no logo/emblem fallback. Load errors may show the clinic fallback and then the custom placeholder/emblem. Replacing a failed source with a valid source renders the new image. The same failed URL is not retried as its own fallback.

## Parser order

| Entity | Image candidates, first nonblank supported value wins |
| --- | --- |
| Clinic logo | `logo`, `logo_url` |
| Clinic cover | `cover_image`, `cover_image_url` |
| Practitioner avatar | `avatar_url`, `photo_url`, `avatar` |
| Product / Offer / Treatment | `image_url`, `image` |
| Article cover | `cover_image_url`, `cover_image`, `image_url`, `image` |
| Admin clinic branding | Same logo/cover order as clinic |
| Home featured-ad image | `image_url`, `image` |

The canonical `image_url`/`avatar_url`/`cover_image_url` fields in the latest backend derive fresh asset media before legacy URLs. Flutter does not replace a valid canonical URL with an older raw field or a clinic logo.

## Upload contract verification

- Clinic catalog local selections pre-upload using the entity media type, then submit both the uploaded `media_asset` UUID and returned URL in `avatar`, `image`, or `cover_image`. These fresh values overwrite any stale asset ID in the input map.
- Relative upload URLs normalize to the configured backend origin. Existing remote URLs retain their signed query; whitespace-only catalog image values are explicit removals.
- Removal clears both the legacy image field and `media_asset`. Omitted image fields remain omitted.
- Profile/admin direct binary uploads remain multipart. Mixed replacement/removal pre-uploads the new image, then PATCHes JSON with its URL and explicit `null` for the other image.
- All four catalog creation paths, all four removal paths, remote URL handling, admin multipart payloads, and admin mixed-media clinic scope are covered by regression tests.

## Verification and limits

- `flutter analyze --no-pub`: **0 issues**.
- `flutter test --no-pub --reporter expanded`: **244 tests passed**.
- `test/image_display_regression_test.dart`: **30 new tests**, including actual PNG decoding through `NetworkImage` with deterministic HTTP responses, local files, file URIs, bundled assets, pending requests, error fallback, and failed-to-valid source replacement.
- `git diff --check`: passed.
- The latest backend archive remains read-only; all 636 extracted files match the archive.

The Windows paths supplied by the user are not mounted here. Work used `/workspace/AestheticWay` and the extracted `/workspace/work/backend-latest-reference` from `backend_latest.zip`. Archive SHA-256: `a858e2aafbadadaa3c6b80c2c652aa1a20ae85bc6e4582ff16c9887b8aaef98d`.

The supplied public and portal treatment serializers do not expose a treatment photo or image upload field. Flutter now honors a treatment `image_url`/`image` when supplied, but it cannot display a treatment photograph that the server does not return. Such responses correctly retain fallback media; this change does not invent a treatment upload API.

No live authenticated uploads or production storage requests were made. A syntactically valid URL that returns 403/404, expired credentials, non-image bytes, or a malformed stored path can still trigger an actual load-error fallback. The local results verify the client contracts/rendering, not production storage availability. Django source files were not changed.
