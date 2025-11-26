class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'credit' or 'debit'
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String status;
  final String? paymentMethod;
  final String? description;
  final String? callId;
  final String? paymentReference;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    this.paymentMethod,
    this.description,
    this.callId,
    this.paymentReference,
    this.metadata,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      balanceBefore: (json['balanceBefore'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String?,
      description: json['description'] as String?,
      callId: json['callId'] as String?,
      paymentReference: json['paymentReference'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'status': status,
      'paymentMethod': paymentMethod,
      'description': description,
      'callId': callId,
      'paymentReference': paymentReference,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}
