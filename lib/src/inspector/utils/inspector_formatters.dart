part of '../flutter_network_lens_inspector.dart';

String _pathWithQuery(Uri uri) => uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

String _displayHost(Uri uri) => uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;

Color _methodColor(BuildContext context, String method) => switch (method.toUpperCase()) {
  'GET' => Colors.blue,
  'POST' => Colors.green,
  'PUT' || 'PATCH' => Colors.orange,
  'DELETE' => Theme.of(context).colorScheme.error,
  _ => Theme.of(context).colorScheme.primary,
};

Color _statusColor(BuildContext context, NetworkTransaction transaction) {
  final status = transaction.statusCode;
  if (transaction.isError || status == null || status >= 500) {
    return Theme.of(context).colorScheme.error;
  }
  if (status >= 400) {
    return Colors.deepOrange;
  }
  if (status >= 300) {
    return Colors.orange;
  }
  return Colors.green;
}

String _durationLabel(Duration duration) => duration.inMilliseconds < 1000
    ? '${duration.inMilliseconds} ms'
    : '${(duration.inMilliseconds / 1000).toStringAsFixed(2)} s';

String _timeLabel(DateTime timestamp) =>
    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

String _fullTimeLabel(DateTime timestamp) =>
    '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${_timeLabel(timestamp)}';

String _prettyValue(Object? value) => value == null ? '' : NetworkTransactionFormatter.prettyValue(value);
