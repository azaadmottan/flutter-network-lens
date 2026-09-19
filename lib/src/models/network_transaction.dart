import 'network_error.dart';
import 'network_request.dart';
import 'network_response.dart';

/// A complete network request lifecycle captured by FlutterNetworkLens.
final class NetworkTransaction {
  /// Creates a captured transaction.
  const NetworkTransaction({
    required this.id,
    required this.request,
    required this.timestamp,
    required this.duration,
    this.response,
    this.error,
  }) : assert(
          response != null || error != null,
          'A transaction must have a response or an error.',
        );

  /// Unique identifier assigned by the integration.
  final String id;

  /// Data sent by the application.
  final NetworkRequest request;

  /// Data returned by the server, if a response was received.
  final NetworkResponse? response;

  /// Error raised by the HTTP client, if the request failed.
  final NetworkError? error;

  /// Time at which the request was started.
  final DateTime timestamp;

  /// Elapsed time from request start until completion or failure.
  final Duration duration;

  /// HTTP status code, if a response was received.
  int? get statusCode => response?.statusCode;

  /// Whether the HTTP call completed without a client error.
  bool get isError => error != null;
}
