import '../models/child.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import 'app_repository.dart';

class DummyRepository implements AppRepository {
  // In-memory storage
  final List<Child> _children = [];
  final Map<String, List<Transaction>> _transactions = {};

  DummyRepository() {
    _seed();
  }

  void _seed() {
    // Child 1: たろう
    const child1Id = 'dummy-child-1';
    final child1 = Child(
      id: child1Id,
      name: 'たろう',
      interestRatePercent: 5.0,
      balance: 3500,
      createdAt: DateTime(2025, 11, 1),
    );
    _children.add(child1);
    _transactions[child1Id] = [
      Transaction(
        id: 'dummy-tx-1-1',
        childId: child1Id,
        type: TransactionType.deposit,
        amount: 1000,
        balanceAfter: 1000,
        memo: 'おこづかい',
        date: DateTime(2025, 11, 1),
        createdAt: DateTime(2025, 11, 1),
      ),
      Transaction(
        id: 'dummy-tx-1-2',
        childId: child1Id,
        type: TransactionType.interest,
        amount: 4,
        balanceAfter: 1004,
        memo: '利息',
        date: DateTime(2025, 12, 1),
        createdAt: DateTime(2025, 12, 1),
      ),
      Transaction(
        id: 'dummy-tx-1-3',
        childId: child1Id,
        type: TransactionType.deposit,
        amount: 3000,
        balanceAfter: 4004,
        memo: 'お年玉',
        date: DateTime(2026, 1, 15),
        createdAt: DateTime(2026, 1, 15),
      ),
      Transaction(
        id: 'dummy-tx-1-4',
        childId: child1Id,
        type: TransactionType.withdrawal,
        amount: 500,
        balanceAfter: 3504,
        memo: 'ガチャ',
        date: DateTime(2026, 1, 20),
        createdAt: DateTime(2026, 1, 20),
      ),
      Transaction(
        id: 'dummy-tx-1-5',
        childId: child1Id,
        type: TransactionType.withdrawal,
        amount: 4,
        balanceAfter: 3500,
        memo: 'おかし',
        date: DateTime(2026, 2, 5),
        createdAt: DateTime(2026, 2, 5),
      ),
    ];

    // Child 2: はなこ
    const child2Id = 'dummy-child-2';
    final child2 = Child(
      id: child2Id,
      name: 'はなこ',
      interestRatePercent: 3.0,
      balance: 1200,
      createdAt: DateTime(2025, 12, 1),
    );
    _children.add(child2);
    _transactions[child2Id] = [
      Transaction(
        id: 'dummy-tx-2-1',
        childId: child2Id,
        type: TransactionType.deposit,
        amount: 500,
        balanceAfter: 500,
        memo: 'おこづかい',
        date: DateTime(2025, 12, 1),
        createdAt: DateTime(2025, 12, 1),
      ),
      Transaction(
        id: 'dummy-tx-2-2',
        childId: child2Id,
        type: TransactionType.deposit,
        amount: 1000,
        balanceAfter: 1500,
        memo: 'おばあちゃんから',
        date: DateTime(2026, 1, 10),
        createdAt: DateTime(2026, 1, 10),
      ),
      Transaction(
        id: 'dummy-tx-2-3',
        childId: child2Id,
        type: TransactionType.withdrawal,
        amount: 300,
        balanceAfter: 1200,
        memo: 'えほん',
        date: DateTime(2026, 2, 3),
        createdAt: DateTime(2026, 2, 3),
      ),
    ];
  }

  @override
  Future<List<Child>> loadChildren() async {
    return List.unmodifiable(_children);
  }

  @override
  Future<void> saveChild(Child child) async {
    _children.add(child);
    _transactions.putIfAbsent(child.id, () => []);
  }

  @override
  Future<void> updateChild(Child child) async {
    final index = _children.indexWhere((c) => c.id == child.id);
    if (index != -1) {
      _children[index] = child;
    }
  }

  @override
  Future<void> deleteChild(String childId) async {
    _children.removeWhere((c) => c.id == childId);
    _transactions.remove(childId);
  }

  @override
  Future<List<Transaction>> loadTransactions(String childId) async {
    return List.unmodifiable(_transactions[childId] ?? []);
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    _transactions.putIfAbsent(transaction.childId, () => []);
    _transactions[transaction.childId]!.add(transaction);
  }

  @override
  Future<void> updateChildBalance(
    String childId,
    double newBalance, {
    DateTime? lastInterestAppliedAt,
  }) async {
    final index = _children.indexWhere((c) => c.id == childId);
    if (index != -1) {
      _children[index] = lastInterestAppliedAt != null
          ? _children[index].copyWith(
              balance: newBalance,
              lastInterestAppliedAt: lastInterestAppliedAt,
            )
          : _children[index].copyWith(balance: newBalance);
    }
  }
}
