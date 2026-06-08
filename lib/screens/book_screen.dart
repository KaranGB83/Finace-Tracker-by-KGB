import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/transaction.dart' as model;
import '../database/dao.dart';

class BookScreen extends StatefulWidget {
  final Book book;
  const BookScreen({super.key, required this.book});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  List<model.Transaction> _transactions = [];
  bool _isLoading = true;
  late Book _book;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final transactions = await DAO.getTransactionsForBook(_book.id);
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  // Transaction Dialog (shared for credit & debit)
  void _showTransactionDialog(bool isCredit) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isCredit ? 'Add Credit' : 'Add Debit'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amount
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Amount is required';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Enter a valid number';
                    if (parsed <= 0) return 'Amount must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Note (title)
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'e.g. Salary, Groceries',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Note is required' : null,
                ),
                const SizedBox(height: 16),
                // Description
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isCredit ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final amount = double.parse(amountController.text.trim());
              final newBalance = isCredit
                  ? _book.balance + amount
                  : _book.balance - amount;

              final transaction = model.Transaction(
                id: _uuid.v4(),
                bookId: _book.id,
                note: noteController.text.trim(),
                description: descriptionController.text.trim(),
                amount: amount,
                isCredit: isCredit,
                createdAt: DateTime.now(),
              );

              await DAO.insertTransaction(transaction);
              await DAO.updateBookBalance(_book.id, newBalance);

              setState(() => _book.balance = newBalance);

              if (context.mounted) Navigator.pop(context);
              _loadTransactions();
            },
            child: Text(isCredit ? 'Add Credit' : 'Add Debit'),
          ),
        ],
      ),
    );
  }

  // Delete Transaction
  void _confirmDeleteTransaction(model.Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete "${transaction.note}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DAO.deleteTransaction(
                transaction.id,
                transaction.bookId,
                transaction.amount,
                transaction.isCredit,
              );
              if (context.mounted) Navigator.pop(context);
              // Reload book balance too
              final books = await DAO.getAllBooks();
              final updatedBook = books.firstWhere((b) => b.id == _book.id);
              setState(() => _book.balance = updatedBook.balance);
              _loadTransactions();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Transaction Card
  Widget _buildTransactionCard(model.Transaction transaction) {
    final isCredit = transaction.isCredit;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt);

    return GestureDetector(
      onLongPress: () => _confirmDeleteTransaction(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            transaction.note,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.description.isNotEmpty)
                Text(transaction.description, style: const TextStyle(fontSize: 12)),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          trailing: Text(
            '${isCredit ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isCredit ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final isNegative = _book.balance < 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(_book.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNegative
                    ? [Colors.red.shade700, Colors.red.shade400]
                    : [Colors.indigo.shade700, Colors.indigo.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹ ${_book.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_book.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _book.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),

          // Credit / Debit Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showTransactionDialog(true),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Credit', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showTransactionDialog(false),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Debit', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transactions List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_transactions.length} total',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No transactions yet',
                                style: TextStyle(color: Colors.grey, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Use Credit / Debit buttons above',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _transactions.length,
                        itemBuilder: (_, index) =>
                            _buildTransactionCard(_transactions[index]),
                      ),
          ),
        ],
      ),
    );
  }
}
