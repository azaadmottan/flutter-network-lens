/// Configuration for FlutterNetworkLens' in-memory capture layer.
final class FlutterNetworkLensConfig {
  /// Creates configuration for FlutterNetworkLens.
  FlutterNetworkLensConfig({
    this.enabled = true,
    this.maxTransactions = 200,
    this.environment,
    Set<String>? sensitiveHeaderNames,
    Set<String>? sensitiveBodyFieldNames,
  })  : sensitiveHeaderNames = {
          ..._defaultSensitiveHeaderNames,
          ...?sensitiveHeaderNames,
        },
        sensitiveBodyFieldNames = {
          ..._defaultSensitiveBodyFieldNames,
          ...?sensitiveBodyFieldNames,
        },
        assert(maxTransactions > 0, 'maxTransactions must be greater than zero.');

  /// Whether new transactions should be captured.
  final bool enabled;

  /// Maximum number of most-recent transactions kept in memory.
  final int maxTransactions;

  /// Optional label supplied by the host app, for example `staging`.
  final String? environment;

  /// Case-insensitive HTTP header names whose values must be hidden.
  final Set<String> sensitiveHeaderNames;

  /// Case-insensitive JSON/body field names whose values must be hidden.
  final Set<String> sensitiveBodyFieldNames;

  static const Set<String> _defaultSensitiveHeaderNames = {
    'authorization',
    'cookie',
    'set-cookie',
    'proxy-authorization',
  };

  static const Set<String> _defaultSensitiveBodyFieldNames = {
    'access_token',
    'refresh_token',
    'password',
  };
}
