import 'package:flutter/material.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('こどもぎんこう'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'add_child') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChildEditScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'add_child',
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined),
                    SizedBox(width: 12),
                    Text('子どもを追加'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: children.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.child_care,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '最初の子どもを追加しよう！',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChildEditScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('追加する'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
