# FlutterNetworkLens project overview

FlutterNetworkLens is a local, in-app network traffic inspector for Flutter
development and QA builds. It records supported HTTP activity in the host
application and presents it in an inspector that can be opened by the
application.

## Supported integrations

- Dio, through `FlutterNetworkLensDioInterceptor`.
- `package:http`, through `FlutterNetworkLensHttpClient`.
- GetX GetConnect, through `FlutterNetworkLensGetConnect.attach`.

Only calls made through the configured adapter or instrumented client are
recorded. Other networking clients are unaffected.

## What the inspector provides

Captured transactions include the request method, URL, headers, query
parameters, body when available, status, response headers and body, timing,
and client errors. The inspector provides history, search, success/error
filters, transaction details, copy actions, masked cURL generation, and native
sharing of masked debug reports.

## Data handling

FlutterNetworkLens has no backend, accounts, cloud sync, remote debugging, or
web dashboard. The default storage uses `shared_preferences` on the device and
is not encrypted. It is intended for diagnostic history, not as an audit log.

Sensitive header names and structured body-field names are masked before a
transaction is retained. Configure application-specific names during
initialization. Values embedded in URLs, free-form text, error messages, and
stack traces are not automatically redacted; use controlled test data and
review captured content before sharing it.

## Scope

The package is an observational debugging utility. Capture, persistence, and
inspector failures are handled without changing the host application's network
request or response flow.

For setup and integration examples, see the package [README](../README.md).
Report reproducible issues at the
[GitHub issue tracker](https://github.com/azaadmottan/flutter-network-lens/issues).
