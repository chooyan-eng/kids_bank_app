import 'transaction_type.dart';

class Transaction {
  final String id;
  final String childId;
  final TransactionType type;
  final double amount;
  final double balanceAfter;
  final String memo;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.childId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.memo,
    required this.date,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      type: TransactionType.values.byName(map['type'] as String),
      amount: map['amount'] as double,
      balanceAfter: map['balance_after'] as double,
      memo: map['memo'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'type': type.name,
      'amount': amount,
      'balance_after': balanceAfter,
      'memo': memo,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
