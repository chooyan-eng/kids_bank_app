import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

import '../models/child.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../widgets/app_data_scope.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/transaction_dialog.dart';
import 'child_edit_screen.dart';

const _kBase = Color(0xFFE8E0D5);
const _kTextDark = Color(0xFF4A3828);
const _kTextMid = Color(0xFF9E8A78);
const _kAccent = Color(0xFF8B7355);
const _kGreen = Color(0xFF6AAF8B);
const _kRed = Color(0xFFE07A5F);

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
        backgroundColor: _kBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Neumorphic(
                style: NeumorphicStyle(
                  boxShape: NeumorphicBoxShape.circle(),
                  depth: 4,
                  color: _kRed.withValues(alpha: 0.15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child:
                      Icon(Icons.warning_amber_rounded, color: _kRed, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '削除の確認',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '「${child.name}」のデータをすべて削除しますか？',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextMid, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: NeumorphicButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: NeumorphicStyle(
                        depth: 4,
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        'キャンセル',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _kTextMid),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeumorphicButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: NeumorphicStyle(
                        depth: 4,
                        color: _kRed,
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        '削除',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
      backgroundColor: _kBase,
      appBar: NeumorphicAppBar(
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
            color: _kBase,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: const Icon(Icons.more_vert, color: _kTextDark),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('編集', style: TextStyle(color: _kTextDark)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('削除', style: TextStyle(color: _kRed)),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header: avatar, balance card, action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                children: [
                  AvatarWidget(child: child, radius: 44),
                  const SizedBox(height: 20),
                  // Balance display (concave card)
                  Neumorphic(
                    style: NeumorphicStyle(
                      depth: -5,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          const Text(
                            '残高',
                            style: TextStyle(fontSize: 14, color: _kTextMid),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            yenFormat.format(child.balance),
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: child.balance >= 0 ? _kAccent : _kRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '年利 ${child.interestRatePercent}%',
                            style: const TextStyle(
                                fontSize: 13, color: _kTextMid),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NeumorphicButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => TransactionDialog(
                            child: child,
                            initialIsDeposit: true,
                          ),
                        ),
                        style: NeumorphicStyle(
                          color: _kGreen,
                          depth: 5,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(14),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        child: const Row(
                          children: [
                            Icon(Icons.add, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              '入金',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      NeumorphicButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => TransactionDialog(
                            child: child,
                            initialIsDeposit: false,
                          ),
                        ),
                        style: NeumorphicStyle(
                          color: _kRed,
                          depth: 5,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(14),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        child: const Row(
                          children: [
                            Icon(Icons.remove, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              '出金',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Row(
                children: [
                  const Text(
                    '取引履歴',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _kTextMid,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (transactions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${transactions.length}件',
                      style: const TextStyle(fontSize: 12, color: _kTextMid),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Empty state
          if (items.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                  child: Text(
                    'まだ取引がありません',
                    style: TextStyle(color: _kTextMid),
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
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kAccent,
                      ),
                    ),
                  );
                }

                final tx = item as Transaction;
                final (icon, color) = switch (tx.type) {
                  TransactionType.deposit => (Icons.arrow_downward, _kGreen),
                  TransactionType.withdrawal => (Icons.arrow_upward, _kRed),
                  TransactionType.interest => (Icons.star, _kAccent),
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

                return Neumorphic(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  style: NeumorphicStyle(
                    depth: 3,
                    boxShape: NeumorphicBoxShape.roundRect(
                      BorderRadius.circular(14),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Neumorphic(
                          style: NeumorphicStyle(
                            depth: 3,
                            boxShape: NeumorphicBoxShape.circle(),
                            color: color.withValues(alpha: 0.15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(icon, color: color, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _kTextDark,
                                ),
                              ),
                              Text(
                                dayFormat.format(tx.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTextMid,
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
                                color: tx.type == TransactionType.withdrawal
                                    ? _kRed
                                    : _kGreen,
                              ),
                            ),
                            Text(
                              yenFormat.format(tx.balanceAfter),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _kTextMid,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
