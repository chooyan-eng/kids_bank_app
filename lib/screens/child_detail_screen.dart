import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/child.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../widgets/app_data_scope.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/transaction_dialog.dart';
import 'child_edit_screen.dart';

/// S02: Child detail screen — shows balance, interest rate, and full transaction history.
class ChildDetailScreen extends StatefulWidget {
  final Child child;

  const ChildDetailScreen({required this.child, super.key});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final scope = AppDataScope.of(context);
      final child = _currentChild(scope);
      await scope.loadTransactionsFor(child.id);
      await scope.checkAndApplyInterest(child);
    });
  }

  /// Returns the up-to-date [Child] from [scope], falling back to [widget.child].
  Child _currentChild(AppDataScopeState scope) {
    return scope.children.firstWhere(
      (c) => c.id == widget.child.id,
      orElse: () => widget.child,
    );
  }

  Future<void> _showDeleteDialog(Child child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${child.name}」のデータをすべて削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AppDataScope.of(context).deleteChild(child.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppDataScope.of(context);
    final child = _currentChild(scope);

    final transactions = List<Transaction>.from(
      scope.transactions[child.id] ?? [],
    )..sort((a, b) => b.date.compareTo(a.date));

    final yenFormat = NumberFormat.currency(
      locale: 'ja',
      symbol: '¥',
      decimalDigits: 0,
    );
    final monthFormat = DateFormat('yyyy年M月', 'ja');
    final dayFormat = DateFormat('M月d日', 'ja');
    final theme = Theme.of(context);

    // Build a flat list of month-header strings and Transaction objects.
    final List<Object> items = [];
    String? lastMonth;
    for (final tx in transactions) {
      final month = monthFormat.format(tx.date);
      if (month != lastMonth) {
        items.add(month);
        lastMonth = month;
      }
      items.add(tx);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(child.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildEditScreen(child: child),
                  ),
                );
              } else if (value == 'delete') {
                await _showDeleteDialog(child);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('編集')),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  '削除',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header: avatar, balance, interest rate, action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                children: [
                  AvatarWidget(child: child, radius: 40),
                  const SizedBox(height: 12),
                  Text(
                    yenFormat.format(child.balance),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: child.balance >= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '年利 ${child.interestRatePercent}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => TransactionDialog(
                            child: child,
                            initialIsDeposit: true,
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('入金'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => TransactionDialog(
                            child: child,
                            initialIsDeposit: false,
                          ),
                        ),
                        icon: const Icon(Icons.remove),
                        label: const Text('出金'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
          ),

          // Empty state
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'まだ取引がありません',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),

          // Transaction list with month headers
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];

                if (item is String) {
                  // Month section header
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      item,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  );
                }

                final tx = item as Transaction;
                final (icon, color) = switch (tx.type) {
                  TransactionType.deposit => (
                      Icons.arrow_downward,
                      Colors.green
                    ),
                  TransactionType.withdrawal => (
                      Icons.arrow_upward,
                      Colors.red
                    ),
                  TransactionType.interest => (Icons.star, Colors.amber),
                };

                final amountSign =
                    tx.type == TransactionType.withdrawal ? '−' : '＋';

                final label = tx.memo.isNotEmpty
                    ? tx.memo
                    : switch (tx.type) {
                        TransactionType.deposit => '入金',
                        TransactionType.withdrawal => '出金',
                        TransactionType.interest => '利息',
                      };

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(label),
                  subtitle: Text(dayFormat.format(tx.date)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountSign${yenFormat.format(tx.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx.type == TransactionType.withdrawal
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      Text(
                        yenFormat.format(tx.balanceAfter),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
              childCount: items.length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
