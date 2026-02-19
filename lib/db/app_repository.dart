import '../models/child.dart';
import '../models/transaction.dart';

abstract class AppRepository {
  Future<List<Child>> loadChildren();
  Future<void> saveChild(Child child);
  Future<void> updateChild(Child child);
  Future<void> deleteChild(String childId);

  Future<List<Transaction>> loadTransactions(String childId);
  Future<void> saveTransaction(Transaction transaction);

  // balance と lastInterestAppliedAt をアトミックに更新
  Future<void> updateChildBalance(
    String childId,
    double newBalance, {
    DateTime? lastInterestAppliedAt,
  });
}
