import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/network_transaction.dart';
import 'network_storage.dart';
import 'network_transaction_codec.dart';

/// On-device [NetworkStorage] backed by `shared_preferences`.
final class LocalNetworkStorage implements NetworkStorage {
  /// Creates local storage using [preferences], or the platform default.
  LocalNetworkStorage({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'flutter_network_lens.transactions.v1';

  final SharedPreferencesAsync _preferences;
  Future<void> _pendingWrite = Future<void>.value();

  @override
  Future<List<NetworkTransaction>> readAll() async {
    final encoded = await _preferences.getStringList(_key) ?? const <String>[];
    final transactions = <NetworkTransaction>[];

    for (final source in encoded) {
      try {
        transactions.add(NetworkTransactionCodec.decode(source));
      } on FormatException {
        // Ignore only malformed legacy/corrupt entries; preserve valid history.
      }
    }
    return transactions;
  }

  @override
  Future<void> writeAll(List<NetworkTransaction> transactions) {
    final encoded = transactions.map(NetworkTransactionCodec.encode).toList(growable: false);
    return _enqueue(() => _preferences.setStringList(_key, encoded));
  }

  @override
  Future<void> clear() => _enqueue(() => _preferences.remove(_key));

  Future<void> _enqueue(Future<void> Function() operation) {
    _pendingWrite = _pendingWrite.then((_) => operation());
    return _pendingWrite;
  }
}
