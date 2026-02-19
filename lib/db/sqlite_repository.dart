import '../models/child.dart';
import '../models/transaction.dart';
import 'app_repository.dart';
import 'database.dart';

class SqliteRepository implements AppRepository {
  @override
  Future<List<Child>> loadChildren() async {
    final db = await AppDatabase.database;
    final rows = await db.query('children', orderBy: 'created_at ASC');
    return rows.map(Child.fromMap).toList();
  }

  @override
  Future<void> saveChild(Child child) async {
    final db = await AppDatabase.database;
    await db.insert('children', child.toMap());
  }

  @override
  Future<void> updateChild(Child child) async {
    final db = await AppDatabase.database;
    await db.update(
      'children',
      child.toMap(),
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  @override
  Future<void> deleteChild(String childId) async {
    final db = await AppDatabase.database;
    await db.delete('children', where: 'id = ?', whereArgs: [childId]);
  }

  @override
  Future<List<Transaction>> loadTransactions(String childId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'transactions',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final db = await AppDatabase.database;
    await db.insert('transactions', transaction.toMap());
  }

  @override
  Future<void> updateChildBalance(
    String childId,
    double newBalance, {
    DateTime? lastInterestAppliedAt,
  }) async {
    final db = await AppDatabase.database;
    final values = <String, dynamic>{'balance': newBalance};
    if (lastInterestAppliedAt != null) {
      values['last_interest_applied_at'] =
          lastInterestAppliedAt.toIso8601String();
    }
    await db.update('children', values, where: 'id = ?', whereArgs: [childId]);
  }
}
