import 'dart:convert';

import '../models/network_transaction.dart';

/// Generates copy-ready representations of captured, already-masked transactions.
final class NetworkTransactionFormatter {
  NetworkTransactionFormatter._();

  /// Produces a readable debug report for [transaction].
  static String debugReport(
    NetworkTransaction transaction, {
    String? environment,
  }) {
    final buffer = StringBuffer('FlutterNetworkLens Debug Report\n\n');
    if (environment != null && environment.isNotEmpty) {
      buffer.writeln('Environment: $environment');
    }
    buffer
      ..writeln('Request: ${transaction.request.method} ${_pathWithQuery(transaction.request.url)}')
      ..writeln('URL: ${transaction.request.url}')
      ..writeln('Status: ${transaction.statusCode ?? transaction.error?.type ?? 'No response'}')
      ..writeln('Duration: ${_durationLabel(transaction.duration)}')
      ..writeln('Timestamp: ${transaction.timestamp.toIso8601String()}')
      ..writeln('\nRequest Headers:\n${prettyValue(transaction.request.headers)}')
      ..writeln('\nRequest Body:\n${prettyValue(transaction.request.body)}')
      ..writeln('\nResponse Headers:\n${prettyValue(transaction.response?.headers ?? const {})}')
      ..writeln('\nResponse Body:\n${prettyValue(transaction.response?.body)}');
    if (transaction.error != null) {
      buffer.writeln('\nError:\n${transaction.error!.message}');
    }
    return buffer.toString().trimRight();
  }

  /// Produces a cURL command for [transaction].
  ///
  /// The supplied transaction is already masked by FlutterNetworkLens before retention.
  static String curl(NetworkTransaction transaction) {
    final request = transaction.request;
    final arguments = <String>[
      'curl --request ${request.method.toUpperCase()}',
      '--url ${_shellQuote(request.url.toString())}',
      ...request.headers.entries.map(
        (entry) => '--header ${_shellQuote('${entry.key}: ${entry.value}')}',
      ),
    ];
    if (request.body != null && _bodyText(request.body).isNotEmpty) {
      arguments.add('--data ${_shellQuote(prettyValue(request.body))}');
    }
    return arguments.join(' \\\n  ');
  }

  /// Formats values as indented JSON where possible.
  static String prettyValue(Object? value) {
    if (value == null) {
      return '—';
    }
    if (value is String) {
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(value));
      } on FormatException {
        return value;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } on JsonUnsupportedObjectError {
      return value.toString();
    }
  }

  static String _bodyText(Object? value) => value is String ? value : prettyValue(value);

  static String _pathWithQuery(Uri uri) => uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

  static String _durationLabel(Duration duration) => duration.inMilliseconds < 1000
      ? '${duration.inMilliseconds} ms'
      : '${(duration.inMilliseconds / 1000).toStringAsFixed(2)} s';

  static String _shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
}
