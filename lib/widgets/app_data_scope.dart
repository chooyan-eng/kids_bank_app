import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../db/app_repository.dart';
import '../models/child.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';

/// Root StatefulWidget that owns all shared app state.
/// Usage: AppDataScope.of(context).<method or field>
class AppDataScope extends StatefulWidget {
  final AppRepository repository;
  final Widget child;

  const AppDataScope({
    required this.repository,
    required this.child,
    super.key,
  });

  /// Obtain [AppDataScopeState] from the nearest [AppDataScope] ancestor.
  static AppDataScopeState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedAppData>()!
        .state;
  }

  @override
  State<AppDataScope> createState() => AppDataScopeState();
}

class AppDataScopeState extends State<AppDataScope> {
  List<Child> children = [];
  Map<String, List<Transaction>> transactions = {};

  static const _uuid = Uuid();

  // ------------------------------------------------------------------ init

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final loaded = await widget.repository.loadChildren();
    setState(() {
      children = List.of(loaded);
    });
  }

  // -------------------------------------------------------- child operations

  Future<void> addChild(Child child) async {
    await widget.repository.saveChild(child);
    setState(() {
      children = [...children, child];
      transactions.putIfAbsent(child.id, () => []);
    });
  }

  Future<void> updateChild(Child child) async {
    await widget.repository.updateChild(child);
    setState(() {
      children = [
        for (final c in children)
          if (c.id == child.id) child else c,
      ];
    });
  }

  Future<void> deleteChild(String childId) async {
    await widget.repository.deleteChild(childId);
    setState(() {
      children = children.where((c) => c.id != childId).toList();
      transactions.remove(childId);
    });
  }

  // -------------------------------------------------- transaction operations

  /// Saves the transaction, updates the child balance (and
  /// [Child.lastInterestAppliedAt] for interest transactions), and refreshes
  /// in-memory state.
  Future<void> addTransaction(Transaction transaction) async {
    final isInterest = transaction.type == TransactionType.interest;

    await widget.repository.saveTransaction(transaction);
    await widget.repository.updateChildBalance(
      transaction.childId,
      transaction.balanceAfter,
      lastInterestAppliedAt: isInterest ? transaction.date : null,
    );

    setState(() {
      // Append to in-memory transaction list (only if already loaded).
      final txList = transactions[transaction.childId];
      if (txList != null) {
        transactions[transaction.childId] = [...txList, transaction];
      }

      // Update the matching child.
      children = [
        for (final c in children)
          if (c.id == transaction.childId)
            isInterest
                ? c.copyWith(
                    balance: transaction.balanceAfter,
                    lastInterestAppliedAt: transaction.date,
                  )
                : c.copyWith(balance: transaction.balanceAfter)
          else
            c,
      ];
    });
  }

  /// Loads transactions for [childId] from the repository if not yet cached.
  Future<void> loadTransactionsFor(String childId) async {
    if (transactions.containsKey(childId)) return;

    final loaded = await widget.repository.loadTransactions(childId);
    setState(() {
      transactions[childId] = List.of(loaded);
    });
  }

  // ------------------------------------------------------- interest logic

  /// Checks whether a month has elapsed since the last interest application
  /// for [child] and, if so, creates an interest transaction automatically.
  Future<void> checkAndApplyInterest(Child child) async {
    if (child.interestRatePercent == 0.0) return;

    final now = DateTime.now();
    final lastApplied = child.lastInterestAppliedAt ?? child.createdAt;

    if (now.difference(lastApplied).inDays < 30) return;

    // 月利 = 残高 × 年利 ÷ 12、1 円未満切り捨て
    final interest =
        (child.balance * child.interestRatePercent / 100.0 / 12.0)
            .floorToDouble();

    if (interest <= 0.0) return;

    final transaction = Transaction(
      id: _uuid.v4(),
      childId: child.id,
      type: TransactionType.interest,
      amount: interest,
      balanceAfter: child.balance + interest,
      memo: '利息',
      date: now,
      createdAt: now,
    );

    await addTransaction(transaction);
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return _InheritedAppData(
      state: this,
      child: widget.child,
    );
  }
}

/// Internal [InheritedWidget] that propagates [AppDataScopeState] down the tree.
class _InheritedAppData extends InheritedWidget {
  final AppDataScopeState state;

  const _InheritedAppData({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedAppData old) => true;
}
