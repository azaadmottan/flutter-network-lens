# Publishing FlutterNetworkLens

This checklist prepares a release; it does not publish the package.

## Before the first release

- Confirm the MIT license and copyright holder in `LICENSE`.
- Confirm package-name availability and ownership on pub.dev.
- Confirm the version, description, and repository URLs in `pubspec.yaml`.
- Validate and correct the SDK lower bounds. The source uses newer Flutter APIs
  such as `Color.withValues`, so the currently declared Flutter 3.16.0 minimum
  must not be treated as verified compatibility.
- Review the README against implemented behavior and update the changelog.
- Run the example in a Flutter host app and inspect a captured request.
- Check masking with representative test data, including URL and free-text
  limitations documented in the README.

## Validate the release

Run from the package root with a supported Flutter SDK:

```sh
flutter pub get
flutter analyze
flutter test
dart doc
flutter pub publish --dry-run
```

Resolve errors and review warnings. Inspect the dry-run file list for accidental
build output, private data, or unnecessary files. Repeat the checks after fixes.
The dry run does not upload the package.

Publish only after these checks pass and the maintainer decides to release.

References: [Publishing packages](https://dart.dev/tools/pub/publishing) and
[package layout](https://dart.dev/tools/pub/package-layout).
