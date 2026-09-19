import 'package:dio/dio.dart';

import '../../core/flutter_network_lens.dart';
import '../../models/network_error.dart';
import '../../models/network_request.dart';
import '../../models/network_response.dart';
import '../../models/network_transaction.dart';

/// A Dio interceptor that records completed HTTP calls in FlutterNetworkLens.
///
/// Add an instance to the [Dio.interceptors] collection. This interceptor never
/// changes, resolves, rejects, or retries the original Dio request.
final class FlutterNetworkLensDioInterceptor extends Interceptor {
  final Expando<_RequestTiming> _timings = Expando<_RequestTiming>();
  int _sequence = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _timings[options] = _RequestTiming.started();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _recordResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordError(err);
    handler.next(err);
  }

  void _recordResponse(Response<dynamic> response) {
    final timing = _takeTiming(response.requestOptions);
    FlutterNetworkLens.record(
      NetworkTransaction(
        id: _nextId(timing.startedAt),
        request: _requestFrom(response.requestOptions),
        response: _responseFrom(response),
        timestamp: timing.startedAt,
        duration: timing.stopwatch.elapsed,
      ),
    );
  }

  void _recordError(DioException error) {
    final timing = _takeTiming(error.requestOptions);
    final response = error.response;
    FlutterNetworkLens.record(
      NetworkTransaction(
        id: _nextId(timing.startedAt),
        request: _requestFrom(error.requestOptions),
        response: response == null ? null : _responseFrom(response),
        error: NetworkError(
          type: error.type.name,
          message: error.message ?? error.toString(),
          stackTrace: error.stackTrace,
        ),
        timestamp: timing.startedAt,
        duration: timing.stopwatch.elapsed,
      ),
    );
  }

  _RequestTiming _takeTiming(RequestOptions options) {
    final timing = _timings[options] ?? _RequestTiming.started();
    timing.stopwatch.stop();
    _timings[options] = null;
    return timing;
  }

  String _nextId(DateTime startedAt) =>
      '${startedAt.microsecondsSinceEpoch}-${_sequence++}';

  NetworkRequest _requestFrom(RequestOptions options) => NetworkRequest(
        method: options.method,
        url: options.uri,
        headers: _stringifyMap(options.headers),
        queryParameters: Map<String, Object?>.from(options.queryParameters),
        body: options.data,
      );

  NetworkResponse _responseFrom(Response<dynamic> response) => NetworkResponse(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage,
        headers: _stringifyMap(response.headers.map),
        body: response.data,
      );

  Map<String, String> _stringifyMap(Map<String, dynamic> values) =>
      values.map((key, value) => MapEntry(key, value.toString()));
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
