import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/item.dart';
import '../models/party.dart';

class PurchaseBillBookScreen extends StatefulWidget {
  const PurchaseBillBookScreen({super.key});

  @override
  State<PurchaseBillBookScreen> createState() => _PurchaseBillBookScreenState();
}

class _PurchaseBillBookScreenState extends State<PurchaseBillBookScreen> {
  List<TransactionModel> _transactions = [];
  List<Party> _parties = [];
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final txns = await DBHelper.getAllTransactions();
    final parties = await DBHelper.getAllParties();
    final items = await DBHelper.getAllItems();
    setState(() {
      _transactions = txns.where((t) => t.type == 'purchase').toList();
      _parties = parties;
      _items = items;
    });
  }

  Future<void> _confirmDelete(TransactionModel txn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.deleteTransaction(txn.id!);
      _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    }
  }

  String _getPartyName(int partyId) {
    return _parties.firstWhere(
      (p) => p.id == partyId,
      orElse: () => Party(id: 0, name: 'Unknown', phone: '', balance: 0, isCreditor: true),
    ).name;
  }

  String _getItemName(int itemId) {
    return _items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => Item(id: 0, name: 'Unknown', quantity: 0, purchasePrice: 0, sellingPrice: 0),
    ).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Purchase Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAllData,
          )
        ],
      ),
      body: _transactions.isEmpty
          ? const Center(child: Text('No purchases recorded.', style: TextStyle(fontSize: 16)))
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (_, index) {
                final txn = _transactions[index];
                final partyName = _getPartyName(txn.partyId);
                final itemName = _getItemName(txn.itemId);
                final date = DateFormat.yMMMd().format(DateTime.parse(txn.date));

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 3,
                  child: ListTile(
                    title: Text('$partyName → $itemName', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Qty: ${txn.quantity} | ₹${txn.amount.toStringAsFixed(2)} • $date'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          txn.isCredit ? 'Credit' : 'Cash',
                          style: TextStyle(
                            color: txn.isCredit ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(txn),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
