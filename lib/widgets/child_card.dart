import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

import '../models/child.dart';
import 'avatar_widget.dart';

/// Neumorphic card widget displayed on the home screen for each child.
class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback onTap;
  final VoidCallback onDeposit;
  final VoidCallback onWithdrawal;

  const ChildCard({
    required this.child,
    required this.onTap,
    required this.onDeposit,
    required this.onWithdrawal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final yenFormat = NumberFormat.currency(
      locale: 'ja',
      symbol: '¥',
      decimalDigits: 0,
    );
    final isNegative = child.balance < 0;

    return GestureDetector(
      onTap: onTap,
      child: Neumorphic(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        style: NeumorphicStyle(
          depth: 6,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarWidget(child: child),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '年利 ${child.interestRatePercent}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E8E),
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
                      color: isNegative
                          ? const Color(0xFFE53935)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 4,
                      color: const Color(0xFFA5D6A7),
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    onPressed: onDeposit,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Color(0xFF1B5E20)),
                        SizedBox(width: 4),
                        Text(
                          '入金',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 4,
                      color: const Color(0xFFFFCDD2),
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    onPressed: onWithdrawal,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove, size: 16, color: Color(0xFFB71C1C)),
                        SizedBox(width: 4),
                        Text(
                          '出金',
                          style: TextStyle(
                            color: Color(0xFFB71C1C),
                            fontWeight: FontWeight.w600,
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
    );
  }
}
