# FlutterNetworkLens

A local, in-app network traffic tracker and inspector for Flutter development and QA builds.
Connect your HTTP client, make a request, and inspect its headers, body, status,
and duration directly in your app, without connecting to a development machine.

## Features

- Capture completed requests and client errors from Dio, `package:http`, and GetX GetConnect.
- Browse history and search by URL, method, or status.
- Inspect request and response bodies, headers, query parameters, and timing.
- Restore local history with `shared_preferences` whenever the inspector opens and limit retained transactions.
- Mask configured headers and structured fields before recording new entries.
- Open the inspector from your own button or developer menu.
- Copy request details, a masked cURL command, or a full debug report.
- Share a masked debug report through the native platform share sheet.

FlutterNetworkLens has no backend, accounts, or cloud sync.

## Installation

Once the package is published on pub.dev:

```sh
flutter pub add flutter_network_lens
```

Until then, use a local checkout:

```yaml
dependencies:
  flutter_network_lens:
    path: ../flutter-network-lens
```

Adjust the path to your checkout. Use a current stable Flutter SDK; validation of
the oldest supported SDK is still pending before publication.

## Initialize

Initialize FlutterNetworkLens before sending requests:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_network_lens/flutter_network_lens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterNetworkLens.initialize(
    enabled: const bool.fromEnvironment('ENABLE_FLUTTER_NETWORK_LENS'),
    maxTransactions: 200,
    environment: 'staging',
  );
  runApp(const MyApp()); // Your application's root widget.
}
```

Enable capture for a development or QA build:

```sh
flutter run --dart-define=ENABLE_FLUTTER_NETWORK_LENS=true
```

The same define can be supplied to a release build. Capture defaults to `true`
when `enabled` is omitted; the explicit build flag above defaults to `false`.
Disabling capture stops new entries, but does not erase history or hide the
inspector. Gate your inspector button with the same flag if needed.

## Connect your HTTP client

### Dio

Add `dio` as a direct dependency if you use its API, then attach the interceptor
to the Dio instance used by your application:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_network_lens/flutter_network_lens.dart';

final dio = Dio();
dio.interceptors.add(FlutterNetworkLensDioInterceptor());
final response = await dio.get('https://your-api.example.com/profile');
```

Use your own endpoint and handle responses and errors in your application.

### package:http

Use `FlutterNetworkLensHttpClient` for the requests you want to capture:

```dart
import 'package:flutter_network_lens/flutter_network_lens.dart';

final client = FlutterNetworkLensHttpClient();
try {
  final response = await client.get(
    Uri.parse('https://your-api.example.com/profile'),
  );
  // Handle the response in your application.
} finally {
  client.close();
}
```

You can also wrap an existing client with `FlutterNetworkLensHttpClient(existingClient)`.
Closing the wrapper closes that client. Calls through other clients or top-level
`http.get` functions are not captured automatically.

For `send()` calls, consume the response stream: successful transactions are
recorded when the stream finishes. Standard `get()` and `post()` calls consume
it for you. Multipart and streamed request bodies are not captured by this adapter.

### GetX GetConnect

Attach FlutterNetworkLens after configuring each `GetConnect` provider or client:

```dart
import 'package:flutter_network_lens/flutter_network_lens.dart';
import 'package:get/get_connect.dart';

final api = GetConnect()..baseUrl = 'https://your-api.example.com';
FlutterNetworkLensGetConnect.attach(api);

final response = await api.get('/profile');
```

GetConnect's native modifiers preserve its networking behavior. FlutterNetworkLens
captures the method, URL, query parameters, headers, status, timing, response
headers, and decoded response body. GetConnect does not expose a dedicated error
modifier; a failed response without an HTTP status is recorded as an error.
Request bodies are not captured by this adapter because GetConnect provides them
as a one-shot stream, which FlutterNetworkLens must not consume.

### Other networking libraries

Libraries built on Dio are covered when they use the instrumented Dio instance
(for example, Retrofit-generated clients). Libraries that accept an `http.Client`
are covered by passing `FlutterNetworkLensHttpClient`. A library with its own HTTP stack
needs a dedicated FlutterNetworkLens adapter and should only be supported where it
offers a non-invasive request/response hook.

## Open the inspector

Use a context below your application's `MaterialApp` / `Navigator`:

```dart
FilledButton(
  onPressed: () => FlutterNetworkLens.openInspector(context),
  child: const Text('Open network inspector'),
)
```

The inspector includes history, search, All/Success/Errors filters, transaction
details, copy actions, native sharing, and a clear-history action. The transaction
overflow menu can copy the URL, request/response body, combined headers, masked
cURL command, or full debug report. **Share debug report** opens the native share
sheet with the same masked report.

See [the example](example/README.md) for a complete Flutter entry point that
uses a mock HTTP response without contacting a server.

## Configuration and storage

| Option | Default | Purpose |
| --- | --- | --- |
| `enabled` | `true` | Record new transactions. |
| `maxTransactions` | `200` | Keep this many newest entries; must be positive. |
| `environment` | `null` | Store an optional label in the configuration. |
| `sensitiveHeaderNames` | Built-in names | Add headers to mask. |
| `sensitiveBodyFieldNames` | Built-in names | Add structured field names to mask. |
| `storage` | `LocalNetworkStorage()` | Supply a custom `NetworkStorage`. |

Default storage uses `shared_preferences`; FlutterNetworkLens does not encrypt it.
Persistence is asynchronous and storage failures are caught. History is best
effort, not an audit log. The transaction limit does not limit body size.

Read `FlutterNetworkLens.transactions` for a snapshot, subscribe to
`FlutterNetworkLens.transactionChanges` for updates, or call `FlutterNetworkLens.clear()` to
clear memory and request deletion of persisted history. Custom integrations can
submit completed `NetworkTransaction` objects with `FlutterNetworkLens.record()`.

## Masking

Built-in names are matched case-insensitively:

- Headers: `Authorization`, `Cookie`, `Set-Cookie`, `Proxy-Authorization`.
- Structured fields: `access_token`, `refresh_token`, `password`.

Add application-specific names during initialization:

```dart
await FlutterNetworkLens.initialize(
  sensitiveHeaderNames: {'X-API-Key'},
  sensitiveBodyFieldNames: {'pin', 'sessionSecret'},
);
```

Matching values become `********`. Structured maps, lists, and JSON strings are
processed recursively; configured field names also apply to the separate query
parameter map. The original URL, error messages, stack traces, and non-JSON text
are not redacted. Secrets embedded in URL query strings can therefore remain
visible. Restored history is not re-masked when configuration changes.

Use controlled test data and check captured content before distributing builds.

## Development

```sh
flutter pub get
flutter analyze
flutter test
```

Report bugs with reproduction steps, Flutter version, and client integration at
[GitHub Issues](https://github.com/azaadmottan/flutter-network-lens/issues). Remove private
request data from reports.

The [project plan](docs/PROJECT_PLAN.md) describes intended work, including
features beyond this version. See [CHANGELOG.md](CHANGELOG.md) for release notes
and [the publishing checklist](docs/PUBLISHING.md) for remaining release checks.

## License

FlutterNetworkLens is available under the [MIT License](LICENSE).
