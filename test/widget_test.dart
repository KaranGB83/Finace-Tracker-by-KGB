import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/book.dart';
import 'package:finance_tracker/models/transaction.dart';

void main() {
  test('Book survives a toMap/fromMap round trip', () {
    final book = Book(id: 'b1', title: 'Personal', description: '', balance: 100);
    final copy = Book.fromMap(book.toMap());
    expect(copy.id, 'b1');
    expect(copy.title, 'Personal');
    expect(copy.balance, 100.0);
  });

  test('Transaction survives a toMap/fromMap round trip', () {
    final now = DateTime(2026, 11, 9, 12, 30);
    final tx = Transaction(
      id: 't1',
      bookId: 'b1',
      note: 'Salary',
      description: 'Nov',
      amount: 2500.5,
      isCredit: true,
      createdAt: now,
    );
    final copy = Transaction.fromMap(tx.toMap());
    expect(copy.amount, 2500.5);
    expect(copy.isCredit, isTrue);
    expect(copy.createdAt, now);
  });

  test('Models tolerate NULL description and integer amounts from SQLite', () {
    final tx = Transaction.fromMap({
      'id': 't2',
      'bookId': 'b1',
      'note': 'x',
      'description': null,
      'amount': 5,
      'isCredit': 0,
      'createdAt': DateTime(2026).toIso8601String(),
    });
    expect(tx.description, '');
    expect(tx.amount, 5.0);
    expect(tx.isCredit, isFalse);
  });
}
