import 'package:flutter/material.dart';

import '../widgets/app_data_scope.dart';
import '../widgets/child_card.dart';
import '../widgets/transaction_dialog.dart';
import 'child_detail_screen.dart';
import 'child_edit_screen.dart';

/// S01: Home screen — shows all children's balance cards.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppDataScope.of(context);
    final children = scope.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('こどもぎんこう'),
        centerTitle: true,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChildEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
