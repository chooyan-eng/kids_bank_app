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
  bool _didCheckInterest = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppDataScope.of(context);
    final children = scope.children;
    if (!_didCheckInterest && children.isNotEmpty) {
      _didCheckInterest = true;
      for (final child in children) {
        scope.checkAndApplyInterest(child);
      }
    }
    // Load recent transactions for all children so ChildCard can display them.
    for (final child in children) {
      scope.loadTransactionsFor(child.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppDataScope.of(context);
    final children = scope.children;

    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      appBar: NeumorphicAppBar(
        title: const Text('こどもぎんこう'),
        centerTitle: true,
        actions: [
          NeumorphicButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChildEditScreen()),
            ),
            style: NeumorphicStyle(
              boxShape: NeumorphicBoxShape.circle(),
              depth: 4,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.person_add_outlined,
              size: 20,
              color: Color(0xFF4A3828),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: children.isEmpty
          ? _EmptyState(
              onAdd: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChildEditScreen()),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                final txList = scope.transactions[child.id] ?? const [];
                return ChildCard(
                  child: child,
                  recentTransactions: txList,
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Neumorphic(
            style: NeumorphicStyle(
              boxShape: NeumorphicBoxShape.circle(),
              depth: 6,
            ),
            child: const Padding(
              padding: EdgeInsets.all(28),
              child: Icon(
                Icons.child_care,
                size: 56,
                color: Color(0xFF9E8A78),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '最初の子どもを追加しよう！',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF9E8A78),
            ),
          ),
          const SizedBox(height: 24),
          NeumorphicButton(
            onPressed: onAdd,
            style: NeumorphicStyle(
              depth: 6,
              color: const Color(0xFF8B7355),
              boxShape: NeumorphicBoxShape.roundRect(
                BorderRadius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  '追加する',
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
    );
  }
}
