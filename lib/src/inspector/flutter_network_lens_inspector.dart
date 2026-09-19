import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/flutter_network_lens.dart';
import '../models/network_transaction.dart';
import '../sharing/flutter_network_lens_share.dart';
import '../utilities/network_transaction_formatter.dart';

part 'screens/transaction_details.dart';
part 'utils/inspector_formatters.dart';
part 'widgets/inspector_widgets.dart';

/// Full-screen, in-app UI for browsing captured network transactions.
final class FlutterNetworkLensInspector extends StatefulWidget {
  /// Creates the FlutterNetworkLens inspector.
  const FlutterNetworkLensInspector({super.key});

  @override
  State<FlutterNetworkLensInspector> createState() => _FlutterNetworkLensInspectorState();
}

final class _FlutterNetworkLensInspectorState extends State<FlutterNetworkLensInspector> {
  final TextEditingController _searchController = TextEditingController();
  _TransactionFilter _filter = _TransactionFilter.all;
  bool _isRefreshing = true;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshHistory());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('FlutterNetworkLens'),
          actions: [
            IconButton(
              tooltip: 'Clear network history',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmClear,
            ),
          ],
        ),
        body: Stack(
          children: [
            StreamBuilder<List<NetworkTransaction>>(
              stream: FlutterNetworkLens.transactionChanges,
              initialData: FlutterNetworkLens.transactions,
              builder: (context, snapshot) {
                final transactions = snapshot.data ?? const <NetworkTransaction>[];
                final visible = _filterTransactions(transactions);
                return Column(
                  children: [
                    _InspectorSearchField(
                      controller: _searchController,
                      onChanged: () => setState(() {}),
                    ),
                    _FilterBar(
                      selected: _filter,
                      onChanged: (filter) => setState(() => _filter = filter),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? _EmptyState(hasHistory: transactions.isNotEmpty)
                          : _TransactionList(transactions: visible),
                    ),
                  ],
                );
              },
            ),
            if (_isRefreshing) const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator()),
          ],
        ),
      );

  Future<void> _refreshHistory() async {
    await FlutterNetworkLens.refreshHistory();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  List<NetworkTransaction> _filterTransactions(
    List<NetworkTransaction> transactions,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return transactions.where((transaction) {
      final matchesFilter = switch (_filter) {
        _TransactionFilter.all => true,
        _TransactionFilter.success => !transaction.isError &&
            (transaction.statusCode == null || transaction.statusCode! < 400),
        _TransactionFilter.errors => transaction.isError ||
            (transaction.statusCode != null && transaction.statusCode! >= 400),
      };
      if (!matchesFilter || query.isEmpty) {
        return matchesFilter;
      }
      final searchable = [
        transaction.request.method,
        transaction.request.url.toString(),
        transaction.request.url.path,
        transaction.statusCode?.toString() ?? '',
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList(growable: false);
  }

  Future<void> _confirmClear() async {
    if (FlutterNetworkLens.transactions.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear network history?'),
        content: const Text('This removes all captured requests from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      FlutterNetworkLens.clear();
    }
  }
}

enum _TransactionFilter { all, success, errors }
