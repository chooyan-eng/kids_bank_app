enum IconType { gallery, drawing }

class Child {
  final String id;
  final String name;
  final IconType? iconType;
  final String? iconImagePath;
  final double interestRatePercent;
  final double balance;
  final DateTime? lastInterestAppliedAt;
  final DateTime createdAt;

  const Child({
    required this.id,
    required this.name,
    this.iconType,
    this.iconImagePath,
    required this.interestRatePercent,
    required this.balance,
    this.lastInterestAppliedAt,
    required this.createdAt,
  });

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'] as String,
      name: map['name'] as String,
      iconType: map['icon_type'] == null
          ? null
          : IconType.values.byName(map['icon_type'] as String),
      iconImagePath: map['icon_image_path'] as String?,
      interestRatePercent: map['interest_rate_percent'] as double,
      balance: map['balance'] as double,
      lastInterestAppliedAt: map['last_interest_applied_at'] == null
          ? null
          : DateTime.parse(map['last_interest_applied_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_type': iconType?.name,
      'icon_image_path': iconImagePath,
      'interest_rate_percent': interestRatePercent,
      'balance': balance,
      'last_interest_applied_at': lastInterestAppliedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Child copyWith({
    String? id,
    String? name,
    Object? iconType = _sentinel,
    Object? iconImagePath = _sentinel,
    double? interestRatePercent,
    double? balance,
    Object? lastInterestAppliedAt = _sentinel,
    DateTime? createdAt,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      iconType: iconType == _sentinel ? this.iconType : iconType as IconType?,
      iconImagePath: iconImagePath == _sentinel
          ? this.iconImagePath
          : iconImagePath as String?,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      balance: balance ?? this.balance,
      lastInterestAppliedAt: lastInterestAppliedAt == _sentinel
          ? this.lastInterestAppliedAt
          : lastInterestAppliedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Sentinel object used to distinguish "not provided" from explicit null in copyWith.
const Object _sentinel = Object();
