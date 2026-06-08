class Transaction {
  final String id;
  final String bookId;
  final String note;
  final String description;
  final double amount;
  final bool isCredit;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.bookId,
    required this.note,
    required this.description,
    required this.amount,
    required this.isCredit,
    required this.createdAt,
  });

  // Convert Transaction to a Map (for saving to database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'note': note,
      'description': description,
      'amount': amount,
      'isCredit': isCredit ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create a Transaction from a Map (for reading from database)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      bookId: map['bookId'],
      note: map['note'],
      description: map['description'],
      amount: map['amount'],
      isCredit: map['isCredit'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
