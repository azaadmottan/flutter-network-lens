import 'dart:convert';

import '../core/flutter_network_lens_config.dart';
import '../models/network_error.dart';
import '../models/network_request.dart';
import '../models/network_response.dart';
import '../models/network_transaction.dart';

/// Removes configured secrets from transactions before FlutterNetworkLens retains them.
final class NetworkDataMasker {
  NetworkDataMasker._();

  /// Replacement used for every hidden value.
  static const maskedValue = '********';

  /// Returns a copy of [transaction] with sensitive values hidden.
  static NetworkTransaction mask(
    NetworkTransaction transaction,
    FlutterNetworkLensConfig config,
  ) =>
      NetworkTransaction(
        id: transaction.id,
        request: NetworkRequest(
          method: transaction.request.method,
          url: transaction.request.url,
          headers: _maskHeaders(transaction.request.headers, config),
          queryParameters: _maskObject(
            transaction.request.queryParameters,
            config,
          ),
          body: _maskBody(transaction.request.body, config),
        ),
        response: transaction.response == null
            ? null
            : NetworkResponse(
                statusCode: transaction.response!.statusCode,
                statusMessage: transaction.response!.statusMessage,
                headers: _maskHeaders(transaction.response!.headers, config),
                body: _maskBody(transaction.response!.body, config),
              ),
        error: transaction.error == null
            ? null
            : NetworkError(
                type: transaction.error!.type,
                message: transaction.error!.message,
                stackTrace: transaction.error!.stackTrace,
              ),
        timestamp: transaction.timestamp,
        duration: transaction.duration,
      );

  static Map<String, String> _maskHeaders(
    Map<String, String> headers,
    FlutterNetworkLensConfig config,
  ) =>
      headers.map(
        (key, value) => MapEntry(
          key,
          _contains(config.sensitiveHeaderNames, key) ? maskedValue : value,
        ),
      );

  static Object? _maskBody(Object? value, FlutterNetworkLensConfig config) {
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return jsonEncode(_maskValue(decoded, config));
      } on FormatException {
        return value;
      }
    }
    return _maskValue(value, config);
  }

  static Object? _maskValue(Object? value, FlutterNetworkLensConfig config) {
    if (value is Map<Object?, Object?>) {
      return _maskObject(value, config);
    }
    if (value is Iterable<Object?>) {
      return value.map((item) => _maskValue(item, config)).toList();
    }
    return value;
  }

  static Map<String, Object?> _maskObject(
    Map<Object?, Object?> values,
    FlutterNetworkLensConfig config,
  ) =>
      values.map(
        (key, value) => MapEntry(
          key.toString(),
          _contains(config.sensitiveBodyFieldNames, key.toString())
              ? maskedValue
              : _maskValue(value, config),
        ),
      );

  static bool _contains(Set<String> names, String value) =>
      names.any((name) => name.toLowerCase() == value.toLowerCase());
}
