class Transaction {
  final int? id;
  final String type; // 'income' or 'expense'
  final double amount;
  final int categoryId;
  final DateTime date;
  final String? note;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      amount: map['amount'].toDouble(),
      categoryId: map['categoryId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      note: map['note'],
    );
  }

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    int? categoryId,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'Transaction{id: $id, type: $type, amount: $amount, categoryId: $categoryId, date: $date, note: $note}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 