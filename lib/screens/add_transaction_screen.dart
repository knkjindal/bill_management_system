import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/item.dart';
import '../models/party.dart';
import '../models/transaction_model.dart';
import '../screens/invoice_preview_screen.dart';
import '../widgets/item_selection_dialog.dart';

class AddTransactionScreen extends StatefulWidget {
  final String transactionType; // 'sale' or 'purchase'
  const AddTransactionScreen({super.key, required this.transactionType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  DateTime selectedDate = DateTime.now();
  Party? selectedParty;
  List<Item> selectedItems = [];
  List<int> itemQuantities = [];
  String paymentType = 'Cash';

  double discount = 0;
  double finalAmount = 0;

  TextEditingController noteController = TextEditingController();
  TextEditingController tagsController = TextEditingController();

  List<Item> allItems = [];
  List<Party> allParties = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    allItems = await DBHelper.getAllItems();
    allParties = await DBHelper.getAllParties();
    setState(() {});
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (int i = 0; i < selectedItems.length; i++) {
      total += (widget.transactionType == 'sale'
              ? selectedItems[i].sellingPrice
              : selectedItems[i].purchasePrice) *
          itemQuantities[i];
    }
    return total;
  }

  void _updateFinalAmount(String value) {
    final entered = double.tryParse(value) ?? _calculateTotalAmount();
    setState(() {
      finalAmount = entered;
      discount = _calculateTotalAmount() - finalAmount;
    });
  }

  Future<void> _saveTransaction({required bool printAfter}) async {
    if (selectedParty == null || selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a party and add items')),
      );
      return;
    }

    final double total = _calculateTotalAmount();
    final double actualAmount = finalAmount == 0 ? total : finalAmount;
    final List<String> tags = tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (int i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      final quantity = itemQuantities[i];
      final price = widget.transactionType == 'sale'
          ? item.sellingPrice
          : item.purchasePrice;

      final txn = TransactionModel(
        id: null,
        partyId: selectedParty!.id!,
        itemId: item.id!,
        quantity: quantity,
        amount: price * quantity,
        isCredit: paymentType == 'Credit',
        date: selectedDate.toIso8601String(),
        note: noteController.text.trim(),
        tags: tags,
        type: widget.transactionType,
      );

      await DBHelper.insertTransaction(txn);

      final newQty = widget.transactionType == 'sale'
          ? item.quantity - quantity
          : item.quantity + quantity;

      await DBHelper.updateItemQuantity(item.id!, newQty);
    }

    if (paymentType == 'Credit') {
      double updatedBalance = selectedParty!.balance + actualAmount;
      await DBHelper.updatePartyBalance(selectedParty!.id!, updatedBalance);
    }

    if (!mounted) return;

    if (printAfter) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePreviewScreen(
            party: selectedParty!,
            items: selectedItems,
            quantities: itemQuantities,
            date: selectedDate,
            isCredit: paymentType == 'Credit',
            note: noteController.text.trim(),
            tags: tags,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPurchase = widget.transactionType == 'purchase';

    return Scaffold(
      appBar: AppBar(title: Text('Add ${widget.transactionType.capitalize()}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text('Date: ${DateFormat.yMMMd().format(selectedDate)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Party>(
                  value: selectedParty,
                  items: allParties.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.name));
                  }).toList(),
                  onChanged: (p) => setState(() => selectedParty = p),
                  decoration: const InputDecoration(labelText: 'Select Party'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                tooltip: 'Add Party',
                onPressed: () async {
                  final nameController = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Add Party'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Party Name'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isNotEmpty) {
                              final newParty = Party(name: name, phone: '', balance: 0, isCreditor: true);
                              await DBHelper.insertParty(newParty);
                              Navigator.pop(context);
                              _loadInitialData();
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => ItemSelectionDialog(
                  items: allItems,
                  isPurchase: isPurchase,
                ),
              );
              if (result != null) {
                setState(() {
                  selectedItems = List.from(result['items']);
                  itemQuantities = List.from(result['quantities']);
                  finalAmount = _calculateTotalAmount();
                  discount = 0;
                });
              }
            },
            child: const Text('Select Items'),
          ),
          if (selectedItems.isNotEmpty)
            Column(
              children: List.generate(selectedItems.length, (i) {
                final item = selectedItems[i];
                final price = isPurchase ? item.purchasePrice : item.sellingPrice;
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Qty: ${itemQuantities[i]} x ₹$price'),
                  trailing: Text('₹${(price * itemQuantities[i]).toStringAsFixed(2)}'),
                );
              }),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Payment:'),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Cash'),
                selected: paymentType == 'Cash',
                onSelected: (_) => setState(() => paymentType = 'Cash'),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Credit'),
                selected: paymentType == 'Credit',
                onSelected: (_) => setState(() => paymentType = 'Credit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: tagsController,
            decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(labelText: 'Note'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Text('Total: ₹${_calculateTotalAmount().toStringAsFixed(2)}'),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Final Amount (after discount)'),
            onChanged: _updateFinalAmount,
          ),
          if (discount > 0)
            Text('Discount: ₹${discount.toStringAsFixed(2)}'),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _saveTransaction(printAfter: false),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveTransaction(printAfter: true),
                  icon: const Icon(Icons.print),
                  label: const Text('Save & Print'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
