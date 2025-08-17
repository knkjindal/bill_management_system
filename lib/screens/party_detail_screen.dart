import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../models/transaction_model.dart';
import '../models/item.dart';
import '../db/db_helper.dart';

class PartyDetailsScreen extends StatefulWidget {
  final Party party;
  const PartyDetailsScreen({super.key, required this.party});

  @override
  State<PartyDetailsScreen> createState() => _PartyDetailsScreenState();
}

class _PartyDetailsScreenState extends State<PartyDetailsScreen> {
  List<TransactionModel> _transactions = [];
  List<Item> _items = [];
  Party? _updatedParty;
  double _totalCredit = 0;
  double _totalCash = 0;

  @override
  void initState() {
    super.initState();
    _loadPartyTransactions();
  }

  Future<void> _loadPartyTransactions() async {
    final allTxns = await DBHelper.getAllTransactions();
    final items = await DBHelper.getAllItems();
    final updatedParty = await DBHelper.getPartyById(widget.party.id!);

    final partyTxns = allTxns.where((t) => t.partyId == widget.party.id).toList();
    double credit = 0;
    double cash = 0;

    for (var t in partyTxns) {
      if (t.isCredit) {
        credit += t.amount;
      } else {
        cash += t.amount;
      }
    }

    if (!mounted) return;
    setState(() {
      _transactions = partyTxns;
      _items = items;
      _totalCredit = credit;
      _totalCash = cash;
      _updatedParty = updatedParty;
    });
  }

  String _getItemName(int id) {
    if (id == -1) return 'Payment';
    return _items.firstWhere(
      (i) => i.id == id,
      orElse: () => Item(id: 0, name: 'Unknown Item', quantity: 0, purchasePrice: 0, sellingPrice: 0),
    ).name;
  }

  Future<void> _recordPaymentDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isCredit = false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Type:'),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Credit'),
                      value: true,
                      groupValue: isCredit,
                      onChanged: (val) => setState(() => isCredit = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Debit'),
                      value: false,
                      groupValue: isCredit,
                      onChanged: (val) => setState(() => isCredit = val!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final entered = double.tryParse(amountController.text.trim());
                if (entered != null && entered > 0) {
                  final txn = TransactionModel(
                    partyId: widget.party.id!,
                    itemId: -1,
                    quantity: 0,
                    amount: entered,
                    isCredit: isCredit,
                    type: 'payment',
                    date: DateTime.now().toIso8601String(),
                    note: noteController.text.trim(),
                    tags: [],
                  );

                  await DBHelper.insertTransaction(txn);

                  final party = await DBHelper.getPartyById(widget.party.id!);
                  party.balance = isCredit ? party.balance + entered : party.balance - entered;
                  await DBHelper.updateParty(party);

                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadPartyTransactions();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(TransactionModel txn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This will affect party balance. Proceed?'),
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

      final party = await DBHelper.getPartyById(widget.party.id!);
      party.balance = txn.isCredit ? party.balance - txn.amount : party.balance + txn.amount;
      await DBHelper.updateParty(party);

      if (!mounted) return;
      _loadPartyTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBalance = _updatedParty?.balance ?? widget.party.balance;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.party.name} Details'),
        actions: [
          IconButton(
            onPressed: _recordPaymentDialog,
            icon: const Icon(Icons.attach_money),
            tooltip: 'Record Payment',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: const Text('Current Balance'),
                subtitle: Text(widget.party.isCreditor ? 'To Receive' : 'To Pay'),
                trailing: Text(
                  '₹${currentBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: widget.party.isCreditor ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTotalCard('Credit', _totalCredit, Colors.orange),
                const SizedBox(width: 12),
                _buildTotalCard('Cash', _totalCash, Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (_, i) {
                        final txn = _transactions[i];
                        final formattedDate = DateFormat.yMMMd().format(DateTime.parse(txn.date));
                        final title = _getItemName(txn.itemId);
                        final subtitleParts = [
                          if (txn.quantity > 0) 'Qty: ${txn.quantity}',
                          formattedDate,
                          txn.type,
                          if (txn.note.isNotEmpty) 'Note: ${txn.note}',
                        ];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text(subtitleParts.join(' • ')),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  txn.isCredit ? 'Credit' : 'Cash',
                                  style: TextStyle(
                                    color: txn.isCredit ? Colors.orange : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('₹${txn.amount.toStringAsFixed(2)}'),
                              ],
                            ),
                            onLongPress: () => _confirmDeleteTransaction(txn),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('₹${amount.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
