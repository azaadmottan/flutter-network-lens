import 'dart:async';

import 'package:flutter/material.dart';

import '../inspector/flutter_network_lens_inspector.dart';
import '../models/network_transaction.dart';
import '../privacy/network_data_masker.dart';
import 'flutter_network_lens_config.dart';
import '../storage/local_network_storage.dart';
import '../storage/network_storage.dart';

/// Entry point and in-memory transaction registry for FlutterNetworkLens.
///
/// HTTP client integrations call [record] only after their original request has
/// completed. Failures in this observational layer are contained so that the
/// host application's networking behavior remains unaffected.
final class FlutterNetworkLens {
  FlutterNetworkLens._();

  static FlutterNetworkLensConfig _config = FlutterNetworkLensConfig();
  static final List<NetworkTransaction> _transactions = [];
  static final StreamController<List<NetworkTransaction>> _changes =
      StreamController<List<NetworkTransaction>>.broadcast();
  static NetworkStorage? _storage;
  static Future<void> _pendingPersistence = Future<void>.value();
  static int _historyRevision = 0;

  /// Initializes the in-memory capture layer.
  ///
  /// Calling this again replaces the configuration and trims existing history
  /// if the maximum transaction count was reduced.
  static Future<void> initialize({
    bool enabled = true,
    int maxTransactions = 200,
    String? environment,
    Set<String>? sensitiveHeaderNames,
    Set<String>? sensitiveBodyFieldNames,
    NetworkStorage? storage,
  }) async {
    _config = FlutterNetworkLensConfig(
      enabled: enabled,
      maxTransactions: maxTransactions,
      environment: environment,
      sensitiveHeaderNames: sensitiveHeaderNames,
      sensitiveBodyFieldNames: sensitiveBodyFieldNames,
    );
    _storage = storage ?? LocalNetworkStorage();

    await refreshHistory();
    unawaited(_schedulePersist());
  }

  /// Current FlutterNetworkLens configuration.
  static FlutterNetworkLensConfig get config => _config;

  /// A read-only snapshot of captured transactions, newest first.
  static List<NetworkTransaction> get transactions =>
      List<NetworkTransaction>.unmodifiable(_transactions);

  /// Stream of transaction snapshots, newest first.
  static Stream<List<NetworkTransaction>> get transactionChanges => _changes.stream;

  /// Reloads persisted history into memory.
  ///
  /// The inspector calls this when it opens so a new app session always shows
  /// the latest locally saved transactions. Storage failures are ignored to
  /// keep FlutterNetworkLens observational.
  static Future<void> refreshHistory() async {
    final storage = _storage;
    if (storage == null) {
      return;
    }

    await _pendingPersistence;
    final revision = _historyRevision;
    try {
      final restored = await storage.readAll();
      if (revision != _historyRevision) {
        return;
      }
      _transactions
        ..clear()
        ..addAll(restored);
      _trimToLimit();
      _emit();
    } catch (_) {
      // Persistence failures must not block the host application.
    }
  }

  /// Records a completed request lifecycle.
  ///
  /// This method deliberately never throws: integrations must not allow a
  /// capture failure to interfere with the application's original HTTP call.
  static void record(NetworkTransaction transaction) {
    if (!_config.enabled) {
      return;
    }

    try {
      _transactions.insert(0, NetworkDataMasker.mask(transaction, _config));
      _historyRevision++;
      _trimToLimit();
      _emit();
      unawaited(_schedulePersist());
    } catch (_) {
      // FlutterNetworkLens is observational and must stay invisible to the host app.
    }
  }

  /// Removes all in-memory transactions.
  static void clear() {
    _transactions.clear();
    _historyRevision++;
    _emit();
    final storage = _storage;
    if (storage != null) {
      unawaited(_scheduleClear(storage));
    }
  }

  /// Opens FlutterNetworkLens' in-app network inspector.
  static Future<void> openInspector(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const FlutterNetworkLensInspector(),
        ),
      );

  static void _trimToLimit() {
    if (_transactions.length > _config.maxTransactions) {
      _transactions.removeRange(_config.maxTransactions, _transactions.length);
    }
  }

  static void _emit() {
    if (!_changes.isClosed) {
      _changes.add(transactions);
    }
  }

  static Future<void> _schedulePersist() {
    _pendingPersistence = _pendingPersistence.then((_) => _persist());
    return _pendingPersistence;
  }

  static Future<void> _scheduleClear(NetworkStorage storage) {
    _pendingPersistence = _pendingPersistence.then(
      (_) => _clearPersistedHistory(storage),
    );
    return _pendingPersistence;
  }

  static Future<void> _persist() async {
    final storage = _storage;
    if (storage == null) {
      return;
    }
    try {
      await storage.writeAll(transactions);
    } catch (_) {
      // Persistence failures must not break request interception.
    }
  }

  static Future<void> _clearPersistedHistory(NetworkStorage storage) async {
    try {
      await storage.clear();
    } catch (_) {
      // Persistence failures must not break request interception.
    }
  }
}
