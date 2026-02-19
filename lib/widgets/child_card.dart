import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

import '../models/child.dart';
import 'avatar_widget.dart';

/// Card widget displayed in the home screen for each child.
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
            ],
          ),
        ),
      ),
    );
  }
}
