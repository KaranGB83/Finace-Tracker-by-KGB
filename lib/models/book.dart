class Book {
  final String id;
  final String title;
  final String description;
  double balance;

  Book({
    required this.id,
    required this.title,
    required this.description,
    required this.balance,
  });

  // Convert Book to a Map (for saving to database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'balance': balance,
    };
  }

  // Create a Book from a Map (for reading from database)
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      balance: map['balance'],
    );
  }
}
