import 'package:get/get_connect.dart';

import '../../core/flutter_lens.dart';
import '../../models/network_error.dart';
import '../../models/network_request.dart';
import '../../models/network_response.dart';
import '../../models/network_transaction.dart';

/// Attaches FlutterLens capture to GetX's [GetConnect] HTTP client.
///
/// It uses GetConnect's request and response modifiers without changing the
/// original request or response returned to the application.
final class FlutterLensGetConnect {
  FlutterLensGetConnect._();

  /// Registers FlutterLens capture modifiers on [connect].
  ///
  /// Call this once for every [GetConnect] instance after configuring it.
  static void attach(GetConnect connect) => attachClient(connect.httpClient);

  /// Registers FlutterLens capture modifiers on an existing [GetHttpClient].
  static void attachClient(GetHttpClient client) {
    final recorder = _GetConnectRecorder();
    client
      ..addRequestModifier<dynamic>((request) {
        recorder.recordRequest(request);
        return request;
      })
      ..addResponseModifier<dynamic>((request, response) {
        recorder.recordResponse(request, response);
        return response;
      });
  }
}

final class _GetConnectRecorder {
  final Expando<_RequestTiming> _timings = Expando<_RequestTiming>();
  int _sequence = 0;

  void recordRequest(Object request) {
    _timings[request] = _RequestTiming.started();
  }

  void recordResponse(dynamic request, dynamic response) {
    final timing = _takeTiming(request);
    final statusCode = response.statusCode;
    FlutterLens.record(
      NetworkTransaction(
        id: _nextId(timing.startedAt),
        request: NetworkRequest(
          method: request.method,
          url: request.url,
          headers: request.headers,
          queryParameters: request.url.queryParameters,
        ),
        response: statusCode == null
            ? null
            : NetworkResponse(
                statusCode: statusCode,
                statusMessage: response.statusText,
                headers: response.headers ?? const <String, String>{},
                body: response.body ?? response.bodyString,
              ),
        error: statusCode == null
            ? NetworkError(
                type: 'getConnect',
                message: response.statusText ?? 'GetConnect request failed.',
              )
            : null,
        timestamp: timing.startedAt,
        duration: timing.stopwatch.elapsed,
      ),
    );
  }

  _RequestTiming _takeTiming(Object request) {
    final timing = _timings[request] ?? _RequestTiming.started();
    timing.stopwatch.stop();
    _timings[request] = null;
    return timing;
  }

  String _nextId(DateTime startedAt) =>
      '${startedAt.microsecondsSinceEpoch}-${_sequence++}';
}

final class _RequestTiming {
  _RequestTiming._(this.startedAt, this.stopwatch);

  factory _RequestTiming.started() {
    final stopwatch = Stopwatch()..start();
    return _RequestTiming._(DateTime.now(), stopwatch);
  }

  final DateTime startedAt;
  final Stopwatch stopwatch;
}
