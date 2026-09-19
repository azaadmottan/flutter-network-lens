part of '../flutter_network_lens_inspector.dart';

final class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_pathWithQuery(transaction.request.url), maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              PopupMenuButton<_TransactionAction>(
                tooltip: 'Transaction actions',
                icon: const Icon(Icons.more_vert),
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _TransactionAction.copyUrl,
                    child: ListTile(leading: Icon(Icons.link), title: Text('Copy URL')),
                  ),
                  PopupMenuItem(
                    value: _TransactionAction.copyRequestBody,
                    child: ListTile(leading: Icon(Icons.upload_outlined), title: Text('Copy request body')),
                  ),
                  PopupMenuItem(
                    value: _TransactionAction.copyResponseBody,
                    child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Copy response body')),
                  ),
                  PopupMenuItem(
                    value: _TransactionAction.copyHeaders,
                    child: ListTile(leading: Icon(Icons.list_alt_outlined), title: Text('Copy headers')),
                  ),
                  PopupMenuItem(
                    value: _TransactionAction.copyCurl,
                    child: ListTile(leading: Icon(Icons.terminal_outlined), title: Text('Copy cURL')),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _TransactionAction.copyReport,
                    child: ListTile(leading: Icon(Icons.copy_all_outlined), title: Text('Copy debug report')),
                  ),
                  PopupMenuItem(
                    value: _TransactionAction.shareReport,
                    child: ListTile(leading: Icon(Icons.ios_share_outlined), title: Text('Share debug report')),
                  ),
                ],
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Request'),
                Tab(text: 'Response'),
                Tab(text: 'Headers'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _OverviewTab(transaction: transaction),
              _RequestTab(transaction: transaction),
              _ResponseTab(transaction: transaction),
              _HeadersTab(transaction: transaction),
            ],
          ),
        ),
      );

  Future<void> _handleAction(BuildContext context, _TransactionAction action) async {
    final report = NetworkTransactionFormatter.debugReport(
      transaction,
      environment: FlutterNetworkLens.config.environment,
    );
    switch (action) {
      case _TransactionAction.copyUrl:
        await _copy(context, transaction.request.url.toString(), 'URL copied');
      case _TransactionAction.copyRequestBody:
        await _copy(context, NetworkTransactionFormatter.prettyValue(transaction.request.body), 'Request body copied');
      case _TransactionAction.copyResponseBody:
        await _copy(context, NetworkTransactionFormatter.prettyValue(transaction.response?.body), 'Response body copied');
      case _TransactionAction.copyHeaders:
        await _copy(
          context,
          'Request Headers\n${NetworkTransactionFormatter.prettyValue(transaction.request.headers)}\n\n'
              'Response Headers\n${NetworkTransactionFormatter.prettyValue(transaction.response?.headers ?? const {})}',
          'Headers copied',
        );
      case _TransactionAction.copyCurl:
        await _copy(context, NetworkTransactionFormatter.curl(transaction), 'cURL copied');
      case _TransactionAction.copyReport:
        await _copy(context, report, 'Debug report copied');
      case _TransactionAction.shareReport:
        await FlutterNetworkLensShare.text(context, report, subject: 'FlutterNetworkLens Debug Report');
    }
  }

  Future<void> _copy(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

enum _TransactionAction {
  copyUrl,
  copyRequestBody,
  copyResponseBody,
  copyHeaders,
  copyCurl,
  copyReport,
  shareReport,
}

final class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, transaction);
    return _DetailsList(
      children: [
        _TransactionSummary(transaction: transaction, statusColor: statusColor),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Request',
          icon: Icons.upload_outlined,
          children: [
            _DetailItem('Method', transaction.request.method),
            _DetailItem('URL', transaction.request.url.toString()),
          ],
        ),
        const SizedBox(height: 12),
        _DetailSection(
          title: 'Response',
          icon: transaction.isError ? Icons.error_outline : Icons.download_outlined,
          children: [
            _DetailItem('Status', transaction.statusCode?.toString() ?? transaction.error?.type ?? 'No response'),
            if (transaction.error != null) _DetailItem('Error', transaction.error!.message),
          ],
        ),
      ],
    );
  }
}

final class _TransactionSummary extends StatelessWidget {
  const _TransactionSummary({required this.transaction, required this.statusColor});

  final NetworkTransaction transaction;
  final Color statusColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MethodBadge(method: transaction.request.method),
                  const SizedBox(width: 8),
                  _StatusBadge(label: transaction.statusCode?.toString() ?? 'ERROR', color: statusColor),
                  const Spacer(),
                  Text(_durationLabel(transaction.duration), style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 14),
              Text(_pathWithQuery(transaction.request.url), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(_displayHost(transaction.request.url), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(_fullTimeLabel(transaction.timestamp), style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
            ],
          ),
        ),
      );
}

final class _RequestTab extends StatelessWidget {
  const _RequestTab({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => _DetailsList(
        children: [
          _DetailSection(
            title: 'Request details',
            icon: Icons.upload_outlined,
            children: [
              _DetailItem('URL', transaction.request.url.toString()),
              _DetailItem('Method', transaction.request.method),
              _DetailItem('Query parameters', _prettyValue(transaction.request.queryParameters), code: true),
              _DetailItem('Body', _prettyValue(transaction.request.body), code: true),
            ],
          ),
        ],
      );
}

final class _ResponseTab extends StatelessWidget {
  const _ResponseTab({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => _DetailsList(
        children: [
          _DetailSection(
            title: 'Response details',
            icon: transaction.isError ? Icons.error_outline : Icons.download_outlined,
            children: [
              _DetailItem('Status', transaction.statusCode?.toString() ?? 'No response received'),
              _DetailItem('Status message', transaction.response?.statusMessage ?? ''),
              _DetailItem('Body', _prettyValue(transaction.response?.body), code: true),
            ],
          ),
        ],
      );
}

final class _HeadersTab extends StatelessWidget {
  const _HeadersTab({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => _DetailsList(
        children: [
          _DetailSection(
            title: 'Request headers · ${transaction.request.headers.length}',
            icon: Icons.upload_outlined,
            children: [_DetailItem('Headers', _prettyValue(transaction.request.headers), code: true)],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Response headers · ${transaction.response?.headers.length ?? 0}',
            icon: Icons.download_outlined,
            children: [_DetailItem('Headers', _prettyValue(transaction.response?.headers ?? const {}), code: true)],
          ),
        ],
      );
}

final class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      );
}

final class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );
}

final class _DetailItem extends StatelessWidget {
  const _DetailItem(this.label, this.value, {this.code = false});

  final String label;
  final String value;
  final bool code;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 7),
            if (code && value.isNotEmpty)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(value, style: const TextStyle(fontFamily: 'monospace', height: 1.35)),
                ),
              )
            else
              SelectableText(value.isEmpty ? '—' : value),
          ],
        ),
      );
}
