part of '../flutter_lens_inspector.dart';

final class _InspectorSearchField extends StatelessWidget {
  const _InspectorSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Search URL, method, or status',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
}

final class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _TransactionFilter selected;
  final ValueChanged<_TransactionFilter> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: _TransactionFilter.values
              .map(
                (filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(switch (filter) {
                      _TransactionFilter.all => Icons.layers_outlined,
                      _TransactionFilter.success => Icons.check_circle_outline,
                      _TransactionFilter.errors => Icons.error_outline,
                    }, size: 17),
                    label: Text(switch (filter) {
                      _TransactionFilter.all => 'All activity',
                      _TransactionFilter.success => 'Successful',
                      _TransactionFilter.errors => 'Errors',
                    }),
                    selected: filter == selected,
                    showCheckmark: false,
                    onSelected: (_) => onChanged(filter),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      );
}

final class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});

  final List<NetworkTransaction> transactions;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _TransactionCard(
          transaction: transactions[index],
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _TransactionDetails(transaction: transactions[index]),
            ),
          ),
        ),
      );
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasHistory});

  final bool hasHistory;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(Icons.network_check_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasHistory ? 'No matching requests' : 'No network requests yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                hasHistory
                    ? 'Try changing the search or filter.'
                    : 'API requests made by your application will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
}

final class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.onTap});

  final NetworkTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, transaction);
    final responseLabel = transaction.statusCode?.toString() ?? 'ERROR';
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MethodBadge(method: transaction.request.method),
                  const SizedBox(width: 8),
                  _StatusBadge(label: responseLabel, color: statusColor),
                  const Spacer(),
                  Icon(Icons.timer_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(_durationLabel(transaction.duration), style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _pathWithQuery(transaction.request.url),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _displayHost(transaction.request.url),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _FlowLabel(icon: Icons.upload_outlined, label: 'Request'),
                  const SizedBox(width: 16),
                  _FlowLabel(
                    icon: transaction.isError ? Icons.error_outline : Icons.download_outlined,
                    label: transaction.isError ? 'Failed' : 'Response',
                    color: statusColor,
                  ),
                  const Spacer(),
                  Text(_timeLabel(transaction.timestamp), style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = _methodColor(context, method);
    return _Badge(label: method.toUpperCase(), color: color);
  }
}

final class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => _Badge(label: label, color: color);
}

final class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(7)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      );
}

final class _FlowLabel extends StatelessWidget {
  const _FlowLabel({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: foreground),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
      ],
    );
  }
}
