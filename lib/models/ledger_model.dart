class LedgerModel {
  final int id;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String amount;
  final String transactionType;
  final String description;
  final int user;
  final int? expense;
  final int? payroll;

  LedgerModel({
    required this.id,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.user,
    this.expense,
    this.payroll,
  });

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      id: json['id'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      amount: json['amount'] as String,
      transactionType: json['transaction_type'] as String,
      description: json['description'] as String? ?? '',
      user: json['user'] as int,
      expense: json['expense'] as int?,
      payroll: json['payroll'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'amount': amount,
      'transaction_type': transactionType,
      'description': description,
      'user': user,
      'expense': expense,
      'payroll': payroll,
    };
  }
}
