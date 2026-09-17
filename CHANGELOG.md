# Changelog

## 0.1.0

Initial implementation, prepared for the first release.

- Add a shared transaction model and configurable capture registry.
- Capture Dio requests, responses, and client errors through an interceptor.
- Capture `package:http` calls through a wrapping client.
- Add an in-app history inspector with search, filters, and transaction details.
- Persist history locally using `shared_preferences` with configurable retention.
- Mask configured sensitive headers and structured fields on new records.
- Add package documentation, an example, Flutter CI, and Dependabot updates.
- Add masked cURL and debug-report generation, clipboard actions, and native report sharing.
- Add a GetX GetConnect adapter for request/response capture.
