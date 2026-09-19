# FlutterNetworkLens example

[main.dart](lib/main.dart) is a complete Flutter entry point. It wraps an HTTP
mock client, records a JSON response, and opens the inspector. The request stays
inside the mock client; no external server or network permission is needed.
History uses FlutterNetworkLens' default local storage.

To try it in a host application:

1. Create an app with `flutter create flutter_network_lens_demo`.
2. In that app's `pubspec.yaml`, add `flutter_network_lens` as a path dependency pointing
   to this package checkout and add `http: ^1.6.0` as a direct dependency.
3. Replace the app's `lib/main.dart` with this example's `lib/main.dart`.
4. Run `flutter pub get` and `flutter run` in the host app.
5. Tap **Capture demo request**, then **Open inspector**. Open the request to see
   its JSON response and masked password field.

This directory provides source for a host app; it does not include generated
Android, iOS, web, or desktop runners. The mock is for demonstration only. Use
your real client and endpoint when integrating FlutterNetworkLens into your own app.
