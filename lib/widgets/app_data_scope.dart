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
  List<Child> _children = [];
  final Map<String, List<Transaction>> _transactions = {};

  /// Read-only view of the registered children.
  List<Child> get children => List.unmodifiable(_children);

  /// Read-only view of cached transactions, keyed by child ID.
  Map<String, List<Transaction>> get transactions =>
      Map.unmodifiable(_transactions.map(
        (k, v) => MapEntry(k, List.unmodifiable(v)),
      ));

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
      _children = List.of(loaded);
    });
  }

  // -------------------------------------------------------- child operations

  Future<void> addChild(Child child) async {
    await widget.repository.saveChild(child);
    await _loadChildren();
  }

  Future<void> updateChild(Child child) async {
    await widget.repository.updateChild(child);
    await _loadChildren();
  }

  Future<void> deleteChild(String childId) async {
    await widget.repository.deleteChild(childId);
    await _loadChildren();
    setState(() {
      _transactions.remove(childId);
    });
  }

  // -------------------------------------------------- transaction operations

  /// Saves the transaction, updates the child balance (and
  /// [Child.lastInterestAppliedAt] for interest transactions), then reloads
  /// children and — if already cached — transactions from the repository.
  Future<void> addTransaction(Transaction transaction) async {
    final isInterest = transaction.type == TransactionType.interest;

    await widget.repository.saveTransaction(transaction);
    await widget.repository.updateChildBalance(
      transaction.childId,
      transaction.balanceAfter,
      lastInterestAppliedAt: isInterest ? transaction.date : null,
    );

    await _loadChildren();

    // Reload transactions only if they were already cached for this child.
    if (_transactions.containsKey(transaction.childId)) {
      await _reloadTransactionsFor(transaction.childId);
    }
  }

  /// Loads transactions for [childId] from the repository if not yet cached.
  Future<void> loadTransactionsFor(String childId) async {
    if (_transactions.containsKey(childId)) return;
    await _reloadTransactionsFor(childId);
  }

  /// Always reloads transactions for [childId] from the repository.
  Future<void> _reloadTransactionsFor(String childId) async {
    final loaded = await widget.repository.loadTransactions(childId);
    setState(() {
      _transactions[childId] = List.of(loaded);
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
