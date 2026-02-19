import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

import '../models/child.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import 'avatar_widget.dart';

/// Card widget displayed in the home screen for each child.
class ChildCard extends StatelessWidget {
  final Child child;
  final List<Transaction> recentTransactions;
  final VoidCallback onTap;
  final VoidCallback onDeposit;
  final VoidCallback onWithdrawal;

  const ChildCard({
    required this.child,
    required this.onTap,
    required this.onDeposit,
    required this.onWithdrawal,
    this.recentTransactions = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final yenFormat = NumberFormat.currency(
      locale: 'ja',
      symbol: '¥',
      decimalDigits: 0,
    );

    final recent = recentTransactions.take(2).toList();

    return GestureDetector(
      onTap: onTap,
      child: Neumorphic(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        style: NeumorphicStyle(
          depth: 6,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarWidget(child: child),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A3828),
                          ),
                        ),
                        Text(
                          '年利 ${child.interestRatePercent}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9E8A78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    yenFormat.format(child.balance),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: child.balance >= 0
                          ? const Color(0xFF8B7355)
                          : const Color(0xFFE07A5F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NeumorphicButton(
                    onPressed: onDeposit,
                    style: NeumorphicStyle(
                      color: const Color(0xFF6AAF8B),
                      depth: 4,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          '入金',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  NeumorphicButton(
                    onPressed: onWithdrawal,
                    style: NeumorphicStyle(
                      color: const Color(0xFFE07A5F),
                      depth: 4,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          '出金',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: Color(0xFFD4C9BC)),
                const SizedBox(height: 8),
                ...recent.map((tx) => _RecentTransactionRow(tx: tx)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionRow extends StatelessWidget {
  final Transaction tx;

  const _RecentTransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M/d', 'ja');
    final yenFormat = NumberFormat.currency(
      locale: 'ja',
      symbol: '¥',
      decimalDigits: 0,
    );

    final (IconData icon, Color color, String sign) = switch (tx.type) {
      TransactionType.deposit => (
          Icons.arrow_downward_rounded,
          const Color(0xFF6AAF8B),
          '+'
        ),
      TransactionType.withdrawal => (
          Icons.arrow_upward_rounded,
          const Color(0xFFE07A5F),
          '-'
        ),
      TransactionType.interest => (
          Icons.star_rounded,
          const Color(0xFFE89B41),
          '+'
        ),
    };

    final label = tx.memo.isNotEmpty
        ? tx.memo
        : switch (tx.type) {
            TransactionType.deposit => '入金',
            TransactionType.withdrawal => '出金',
            TransactionType.interest => '利息',
          };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A3828),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            dateFormat.format(tx.date),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9E8A78),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$sign${yenFormat.format(tx.amount)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
