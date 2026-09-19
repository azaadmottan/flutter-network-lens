import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/flutter_network_lens.dart';
import '../../models/network_error.dart';
import '../../models/network_request.dart';
import '../../models/network_response.dart';
import '../../models/network_transaction.dart';

/// An [http.Client] that records calls in FlutterNetworkLens.
///
/// Use this client in place of `http.Client`. It delegates all networking to
/// its wrapped client and preserves the original response stream for callers.
final class FlutterNetworkLensHttpClient extends http.BaseClient {
  /// Creates a capturing client.
  ///
  /// When [inner] is omitted, a default [http.Client] is used.
  FlutterNetworkLensHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;
  int _sequence = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!FlutterNetworkLens.config.enabled) {
      return _inner.send(request);
    }

    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final capturedRequest = _requestFrom(request);

    try {
      final response = await _inner.send(request);
      return _captureResponse(
        response,
        request: capturedRequest,
        startedAt: startedAt,
        stopwatch: stopwatch,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      FlutterNetworkLens.record(
        NetworkTransaction(
          id: _nextId(startedAt),
          request: capturedRequest,
          error: NetworkError(type: 'httpClient', message: error.toString(), stackTrace: stackTrace),
          timestamp: startedAt,
          duration: stopwatch.elapsed,
        ),
      );
      rethrow;
    }
  }

  @override
  void close() => _inner.close();

  http.StreamedResponse _captureResponse(
    http.StreamedResponse response, {
    required NetworkRequest request,
    required DateTime startedAt,
    required Stopwatch stopwatch,
  }) {
    final body = BytesBuilder(copy: false);
    var recorded = false;

    void recordResponse() {
      if (recorded) {
        return;
      }
      recorded = true;
      stopwatch.stop();
      FlutterNetworkLens.record(
        NetworkTransaction(
          id: _nextId(startedAt),
          request: request,
          response: NetworkResponse(
            statusCode: response.statusCode,
            statusMessage: response.reasonPhrase,
            headers: response.headers,
            body: _bodyAsText(body.toBytes()),
          ),
          timestamp: startedAt,
          duration: stopwatch.elapsed,
        ),
      );
    }

    void recordStreamError(Object error, StackTrace stackTrace) {
      if (recorded) {
        return;
      }
      recorded = true;
      stopwatch.stop();
      FlutterNetworkLens.record(
        NetworkTransaction(
          id: _nextId(startedAt),
          request: request,
          error: NetworkError(type: 'responseStream', message: error.toString(), stackTrace: stackTrace),
          timestamp: startedAt,
          duration: stopwatch.elapsed,
        ),
      );
    }

    final capturedStream = response.stream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          body.add(chunk);
          sink.add(chunk);
        },
        handleError: (error, stackTrace, sink) {
          recordStreamError(error, stackTrace);
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          recordResponse();
          sink.close();
        },
      ),
    );

    return http.StreamedResponse(
      capturedStream,
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  NetworkRequest _requestFrom(http.BaseRequest request) => NetworkRequest(
        method: request.method,
        url: request.url,
        headers: request.headers,
        queryParameters: request.url.queryParameters,
        body: request is http.Request ? request.body : null,
      );

  String _nextId(DateTime startedAt) =>
      '${startedAt.microsecondsSinceEpoch}-${_sequence++}';

  String _bodyAsText(Uint8List bytes) => utf8.decode(bytes, allowMalformed: true);
}
