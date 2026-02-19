import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: 10,
            color: NeumorphicTheme.baseColor(ctx),
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '削除の確認',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '「${child.name}」のデータをすべて削除しますか？',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF5D5D5D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: NeumorphicButton(
                        style: NeumorphicStyle(
                          depth: 4,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Center(
                          child: Text(
                            'キャンセル',
                            style: TextStyle(color: Color(0xFF5D5D5D)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeumorphicButton(
                        style: NeumorphicStyle(
                          depth: 4,
                          color: const Color(0xFFFFCDD2),
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Center(
                          child: Text(
                            '削除',
                            style: TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    final baseColor = NeumorphicTheme.baseColor(context);

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
      backgroundColor: baseColor,
      appBar: NeumorphicAppBar(
        title: Text(
          child.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF3D3D3D),
          ),
        ),
        actions: [
          NeumorphicButton(
            style: const NeumorphicStyle(
              boxShape: NeumorphicBoxShape.circle(),
              depth: 3,
            ),
            padding: const EdgeInsets.all(8),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildEditScreen(child: child),
                ),
              );
            },
            child: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(width: 6),
          NeumorphicButton(
            style: const NeumorphicStyle(
              boxShape: NeumorphicBoxShape.circle(),
              depth: 3,
            ),
            padding: const EdgeInsets.all(8),
            onPressed: () => _showDeleteDialog(child),
            child: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header card with balance, rate, and action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Neumorphic(
                style: NeumorphicStyle(
                  depth: 6,
                  boxShape: NeumorphicBoxShape.roundRect(
                      BorderRadius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      AvatarWidget(child: child, radius: 44),
                      const SizedBox(height: 16),
                      Text(
                        yenFormat.format(child.balance),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: child.balance >= 0
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '年利 ${child.interestRatePercent}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E8E),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeumorphicButton(
                            style: NeumorphicStyle(
                              depth: 5,
                              color: const Color(0xFFA5D6A7),
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(14)),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 14),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => TransactionDialog(
                                child: child,
                                initialIsDeposit: true,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: 18, color: Color(0xFF1B5E20)),
                                SizedBox(width: 6),
                                Text(
                                  '入金',
                                  style: TextStyle(
                                    color: Color(0xFF1B5E20),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          NeumorphicButton(
                            style: NeumorphicStyle(
                              depth: 5,
                              color: const Color(0xFFFFCDD2),
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(14)),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 14),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => TransactionDialog(
                                child: child,
                                initialIsDeposit: false,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove,
                                    size: 18, color: Color(0xFFB71C1C)),
                                SizedBox(width: 6),
                                Text(
                                  '出金',
                                  style: TextStyle(
                                    color: Color(0xFFB71C1C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Section label
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: Text(
                '取引履歴',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D5D5D),
                ),
              ),
            ),
          ),

          // Empty state
          if (items.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'まだ取引がありません',
                    style: TextStyle(fontSize: 16, color: Color(0xFF8E8E8E)),
                  ),
                ),
              ),
            ),

          // Transaction list with month headers
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];

                  // Month section header
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E8E8E),
                        ),
                      ),
                    );
                  }

                  final tx = item as Transaction;
                  final (iconData, iconColor, bgColor) = switch (tx.type) {
                    TransactionType.deposit => (
                        Icons.arrow_downward,
                        const Color(0xFF2E7D32),
                        const Color(0xFFC8E6C9),
                      ),
                    TransactionType.withdrawal => (
                        Icons.arrow_upward,
                        const Color(0xFFB71C1C),
                        const Color(0xFFFFCDD2),
                      ),
                    TransactionType.interest => (
                        Icons.star,
                        const Color(0xFF7B4F00),
                        const Color(0xFFFFE0B2),
                      ),
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

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: 3,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(16)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Neumorphic(
                              style: NeumorphicStyle(
                                depth: 2,
                                color: bgColor,
                                boxShape: NeumorphicBoxShape.circle(),
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: Icon(iconData,
                                      color: iconColor, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xFF3D3D3D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dayFormat.format(tx.date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8E8E8E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$amountSign${yenFormat.format(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color:
                                        tx.type == TransactionType.withdrawal
                                            ? const Color(0xFFB71C1C)
                                            : const Color(0xFF2E7D32),
                                  ),
                                ),
                                Text(
                                  yenFormat.format(tx.balanceAfter),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8E8E8E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
