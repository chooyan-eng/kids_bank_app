import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../widgets/app_data_scope.dart';
import '../widgets/child_card.dart';
import '../widgets/transaction_dialog.dart';
import 'child_detail_screen.dart';
import 'child_edit_screen.dart';

/// S01: Home screen — shows all children's balance cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Tracks whether the startup interest check has already been performed.
  bool _didCheckInterest = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Run once: when children are first available after async load, check interest for all.
    if (!_didCheckInterest) {
      final scope = AppDataScope.of(context);
      final children = scope.children;
      if (children.isNotEmpty) {
        _didCheckInterest = true;
        for (final child in children) {
          scope.checkAndApplyInterest(child);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppDataScope.of(context);
    final children = scope.children;
    final baseColor = NeumorphicTheme.baseColor(context);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: NeumorphicAppBar(
        title: const Text(
          'こどもぎんこう',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF3D3D3D),
          ),
        ),
        centerTitle: true,
        actions: [
          NeumorphicButton(
            style: const NeumorphicStyle(
              boxShape: NeumorphicBoxShape.circle(),
              depth: 4,
            ),
            padding: const EdgeInsets.all(10),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChildEditScreen()),
            ),
            child: const Icon(
              Icons.person_add_outlined,
              color: Color(0xFF3D3D3D),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: children.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Neumorphic(
                    style: const NeumorphicStyle(
                      boxShape: NeumorphicBoxShape.circle(),
                      depth: 6,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(28),
                      child: Icon(
                        Icons.child_care,
                        size: 56,
                        color: Color(0xFF8E8E8E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '最初の子どもを追加しよう！',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8E8E8E),
                    ),
                  ),
                  const SizedBox(height: 28),
                  NeumorphicButton(
                    style: NeumorphicStyle(
                      depth: 5,
                      color: const Color(0xFFFFB74D),
                      boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(16)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChildEditScreen()),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Color(0xFF7B4F00)),
                        SizedBox(width: 8),
                        Text(
                          '追加する',
                          style: TextStyle(
                            color: Color(0xFF7B4F00),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                return ChildCard(
                  child: child,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChildDetailScreen(child: child),
                    ),
                  ),
                  onDeposit: () => showDialog(
                    context: context,
                    builder: (_) => TransactionDialog(
                      child: child,
                      initialIsDeposit: true,
                    ),
                  ),
                  onWithdrawal: () => showDialog(
                    context: context,
                    builder: (_) => TransactionDialog(
                      child: child,
                      initialIsDeposit: false,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
