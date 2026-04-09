enum ExpenseStatus { pending, approved, rejected }

extension ExpenseStatusExt on ExpenseStatus {
  String get label {
    switch (this) {
      case ExpenseStatus.pending:
        return 'Kutilmoqda';
      case ExpenseStatus.approved:
        return 'Tasdiqlangan';
      case ExpenseStatus.rejected:
        return 'Rad etilgan';
    }
  }

  static ExpenseStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return ExpenseStatus.approved;
      case 'rejected':
        return ExpenseStatus.rejected;
      default:
        return ExpenseStatus.pending;
    }
  }
}

class ExpenseRequestWorker {
  final String id;
  final String firstName;
  final String lastName;
  final String position;

  const ExpenseRequestWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
  });

  factory ExpenseRequestWorker.fromJson(Map<String, dynamic> json) {
    return ExpenseRequestWorker(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      position: json['position'] as String,
    );
  }

  String get fullName => '$firstName $lastName';
}

class ExpenseRequest {
  final String id;
  final String workerId;
  final ExpenseRequestWorker? worker;
  final double amount;
  final String reason;
  final String cardNumber;
  final ExpenseStatus status;
  final String? reviewNote;
  final String createdAt;
  final String updatedAt;

  const ExpenseRequest({
    required this.id,
    required this.workerId,
    this.worker,
    required this.amount,
    required this.reason,
    required this.cardNumber,
    required this.status,
    this.reviewNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseRequest.fromJson(Map<String, dynamic> json) {
    return ExpenseRequest(
      id: json['id'] as String,
      workerId: json['workerId'] as String,
      worker: json['worker'] != null
          ? ExpenseRequestWorker.fromJson(json['worker'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      cardNumber: json['cardNumber'] as String,
      status: ExpenseStatusExt.fromString(json['status'] as String),
      reviewNote: json['reviewNote'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class ExpenseRequestCreatePayload {
  final double amount;
  final String reason;
  final String cardNumber;

  const ExpenseRequestCreatePayload({
    required this.amount,
    required this.reason,
    required this.cardNumber,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'reason': reason,
        'cardNumber': cardNumber,
      };
}
