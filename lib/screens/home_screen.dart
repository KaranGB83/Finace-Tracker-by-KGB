import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../database/dao.dart';
import 'book_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _books = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final books = await DAO.getAllBooks();
    if (!mounted) return;
    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  // Create Book Dialog
  void _showCreateBookDialog() {
    final titleController = TextEditingController();
    final balanceController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Book'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Personal, Business',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                // Opening Balance
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Balance is required';
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || !parsed.isFinite) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Description
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this book for?',
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final book = Book(
                id: _uuid.v4(),
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                balance: double.parse(balanceController.text.trim()),
              );
              await DAO.insertBook(book);
              if (context.mounted) Navigator.pop(context);
              _loadBooks();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Delete Book
  void _confirmDeleteBook(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Delete "${book.title}"? All transactions will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DAO.deleteBook(book.id);
              if (context.mounted) Navigator.pop(context);
              _loadBooks();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Book Card
  Widget _buildBookCard(Book book) {
    final isNegative = book.balance < 0;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookScreen(book: book)),
        );
        _loadBooks(); // Refresh balance when coming back
      },
      onLongPress: () => _confirmDeleteBook(book),
      child: Container(
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
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title & icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.account_balance_wallet, color: Colors.white70),
              ],
            ),
            // Description
            if (book.description.isNotEmpty)
              Text(
                book.description,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '₹ ${book.balance.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Backup / Restore (no extra packages: uses the clipboard)
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _backup() async {
    final json = await DAO.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    _snack('Backup copied. Paste it into Notes, WhatsApp or email to keep it safe.');
  }

  void _showRestoreDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste your backup here',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final r = await DAO.importJson(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
                _snack('Restored ${r.books} book(s), ${r.transactions} transaction(s).');
                _loadBooks();
              } catch (e) {
                _snack('Could not restore: not a valid Finance Tracker backup.');
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('Finance Tracker', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            iconColor: Colors.white,
            onSelected: (v) => v == 'backup' ? _backup() : _showRestoreDialog(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'backup', child: Text('Backup (copy to clipboard)')),
              PopupMenuItem(value: 'restore', child: Text('Restore (paste backup)')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No books yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Tap + to create your first book', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Books',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          // extra bottom space so the + button never covers a card
                          padding: const EdgeInsets.only(bottom: 88),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: _books.length,
                          itemBuilder: (_, index) => _buildBookCard(_books[index]),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBookDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
