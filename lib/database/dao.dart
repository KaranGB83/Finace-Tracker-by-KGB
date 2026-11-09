import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';
import '../models/transaction.dart' as model;

class DAO {
  static Database? _database;

  // Get or create database 
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // Books table
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        balance REAL NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        note TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        isCredit INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id)
      )
    ''');
  }

  // Book Operations

  static Future<void> insertBook(Book book) async {
    final db = await database;
    await db.insert(
      'books',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Book?> getBook(String bookId) async {
    final db = await database;
    final maps = await db.query('books', where: 'id = ?', whereArgs: [bookId]);
    return maps.isEmpty ? null : Book.fromMap(maps.first);
  }

  static Future<List<Book>> getAllBooks() async {
    final db = await database;
    final maps = await db.query('books');
    return maps.map((map) => Book.fromMap(map)).toList();
  }

  static Future<void> updateBookBalance(String bookId, double newBalance) async {
    final db = await database;
    await db.update(
      'books',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  static Future<void> deleteBook(String bookId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete all transactions for this book first, then the book itself
      await txn.delete('transactions', where: 'bookId = ?', whereArgs: [bookId]);
      await txn.delete('books', where: 'id = ?', whereArgs: [bookId]);
    });
  }

  // Transaction Operations 

  /// Saves the transaction and adjusts the book balance in ONE database
  /// transaction, so the two can never get out of sync. Returns the new balance.
  static Future<double> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final delta = transaction.isCredit ? transaction.amount : -transaction.amount;
      await txn.rawUpdate(
        'UPDATE books SET balance = balance + ? WHERE id = ?',
        [delta, transaction.bookId],
      );
      final rows = await txn.query('books',
          columns: ['balance'], where: 'id = ?', whereArgs: [transaction.bookId]);
      return (rows.first['balance'] as num).toDouble();
    });
  }

  static Future<List<model.Transaction>> getTransactionsForBook(String bookId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC', // Latest first
    );
    return maps.map((map) => model.Transaction.fromMap(map)).toList();
  }

  /// Deletes the transaction and reverses its effect on the book balance
  /// atomically. Returns the new balance (null if the book no longer exists).
  static Future<double?> deleteTransaction(
      String transactionId, String bookId, double amount, bool isCredit) async {
    final db = await database;
    return db.transaction((txn) async {
      // was credit -> subtract it back out; was debit -> add it back
      final delta = isCredit ? -amount : amount;
      await txn.rawUpdate(
        'UPDATE books SET balance = balance + ? WHERE id = ?',
        [delta, bookId],
      );
      await txn.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
      final rows = await txn.query('books',
          columns: ['balance'], where: 'id = ?', whereArgs: [bookId]);
      return rows.isEmpty ? null : (rows.first['balance'] as num).toDouble();
    });
  }
}
