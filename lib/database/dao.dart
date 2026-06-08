import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
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
    // Use web factory when running on web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

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
    // Delete all transactions for this book first
    await db.delete(
      'transactions',
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
    // Then delete the book
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // Transaction Operations 

  static Future<void> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  static Future<void> deleteTransaction(String transactionId, String bookId, double amount, bool isCredit) async {
    final db = await database;

    // Reverse the balance effect before deleting
    final books = await db.query('books', where: 'id = ?', whereArgs: [bookId]);
    if (books.isNotEmpty) {
      double currentBalance = books.first['balance'] as double;
      double newBalance = isCredit
          ? currentBalance - amount  // was credit, so subtract
          : currentBalance + amount; // was debit, so add back
      await updateBookBalance(bookId, newBalance);
    }

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
}
