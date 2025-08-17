import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../db/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/item.dart';
import '../models/party.dart';
import 'add_transaction_screen.dart';

class BillBookScreen extends StatefulWidget {
  const BillBookScreen({super.key});

  @override
  State<BillBookScreen> createState() => _BillBookScreenState();
}

class _BillBookScreenState extends State<BillBookScreen> {
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  List<Party> _parties = [];
  List<Item> _items = [];

  String _txnType = 'sale'; // 'sale' or 'purchase'

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
      _allTransactions = txns;
      _parties = parties;
      _items = items;
      _applyTypeFilter();
    });
  }

  void _applyTypeFilter() {
    setState(() {
      _filteredTransactions = _allTransactions.where((t) => t.type == _txnType).toList();
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

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Bill Book - ${_txnType.capitalize()} Transactions', style: pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Party', 'Item', 'Qty', 'Amount', 'Payment'],
            data: _filteredTransactions.map((txn) {
              final date = DateFormat.yMMMd().format(DateTime.parse(txn.date));
              return [
                date,
                _getPartyName(txn.partyId),
                _getItemName(txn.itemId),
                txn.quantity.toString(),
                '₹${txn.amount.toStringAsFixed(2)}',
                txn.isCredit ? 'Credit' : 'Cash',
              ];
            }).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<void> _exportExcel() async {
    final granted = await requestStoragePermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel[_txnType.capitalize()];
    sheet.appendRow(['Date', 'Party', 'Item', 'Quantity', 'Amount', 'Payment']);

    for (var txn in _filteredTransactions) {
      final date = DateFormat.yMMMd().format(DateTime.parse(txn.date));
      sheet.appendRow([
        date,
        _getPartyName(txn.partyId),
        _getItemName(txn.itemId),
        txn.quantity,
        txn.amount,
        txn.isCredit ? 'Credit' : 'Cash'
      ]);
    }

    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/${_txnType}_billbook.xlsx');
    await file.writeAsBytes(excel.encode()!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧾 Bill Book'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pdf') _exportPDF();
              if (value == 'excel') _exportExcel();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
              const PopupMenuItem(value: 'excel', child: Text('Export as Excel')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: ToggleButtons(
              isSelected: [_txnType == 'sale', _txnType == 'purchase'],
              onPressed: (index) {
                _txnType = index == 0 ? 'sale' : 'purchase';
                _applyTypeFilter();
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: Theme.of(context).primaryColor,
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Sale')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Purchase')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions recorded.', style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (_, index) {
                      final txn = _filteredTransactions[index];
                      final partyName = _getPartyName(txn.partyId);
                      final itemName = _getItemName(txn.itemId);
                      final date = DateFormat.yMMMd().format(DateTime.parse(txn.date));

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 3,
                        child: ListTile(
                          title: Text('$partyName → $itemName',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Qty: ${txn.quantity} | ₹${txn.amount.toStringAsFixed(2)} • $date'),
                          leading: Chip(
                            label: Text(
                              txn.type.capitalize(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor:
                                txn.type == 'sale' ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Edit not yet implemented')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(txn),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(transactionType: _txnType),
            ),
          );
          _loadAllData();
        },
        icon: const Icon(Icons.add),
        label: Text(_txnType == 'sale' ? 'Add Sale' : 'Add Purchase'),
      ),
    );
  }
}

extension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
