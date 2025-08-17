import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/item.dart';

class FullDashboardScreen extends StatefulWidget {
  const FullDashboardScreen({super.key});

  @override
  State<FullDashboardScreen> createState() => _FullDashboardScreenState();
}

class _FullDashboardScreenState extends State<FullDashboardScreen> {
  double totalCredit = 0;
  double totalCash = 0;
  List<TransactionModel> _transactions = [];
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final txns = await DBHelper.getAllTransactions();
    final items = await DBHelper.getAllItems();

    double credit = 0;
    double cash = 0;

    for (var txn in txns) {
      if (txn.isCredit) {
        credit += txn.amount;
      } else {
        cash += txn.amount;
      }
    }

    setState(() {
      _transactions = txns;
      _items = items;
      totalCredit = credit;
      totalCash = cash;
    });
  }

  List<Item> get _mostSoldItems {
    final Map<int, int> soldMap = {};
    for (var t in _transactions) {
      if (t.itemId != -1) {
        soldMap[t.itemId] = (soldMap[t.itemId] ?? 0) + t.quantity;
      }
    }

    final sorted = soldMap.entries
        .where((e) => _items.any((i) => i.id == e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map((e) => _items.firstWhere((i) => i.id == e.key))
        .toList();
  }

  List<Item> get _leastSoldItems {
    final Map<int, int> soldMap = {};
    for (var t in _transactions) {
      if (t.itemId != -1) {
        soldMap[t.itemId] = (soldMap[t.itemId] ?? 0) + t.quantity;
      }
    }

    final sorted = soldMap.entries
        .where((e) => _items.any((i) => i.id == e.key))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sorted
        .take(5)
        .map((e) => _items.firstWhere((i) => i.id == e.key))
        .toList();
  }

  List<Item> get _lowStockItems {
    return _items.where((i) => i.quantity <= 5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = totalCash + totalCredit;
    final creditPercent = total == 0 ? 0.0 : totalCredit / total;
    final cashPercent = total == 0 ? 0.0 : totalCash / total;

    return Scaffold(
      appBar: AppBar(title: const Text('📈 Full Dashboard')),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPieChart(creditPercent, cashPercent),
            const SizedBox(height: 20),
            _buildListCard('🔥 Most Sold Items', _mostSoldItems),
            _buildListCard('📉 Least Sold Items', _leastSoldItems),
            _buildListCard('⚠️ Low Stock Alerts', _lowStockItems, alert: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double credit, double cash) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Credit vs Cash', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: credit * 100,
                      color: Colors.orange,
                      title: credit > 0 ? 'Credit' : '',
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: cash * 100,
                      color: Colors.green,
                      title: cash > 0 ? 'Cash' : '',
                      radius: 60,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(String title, List<Item> items, {bool alert = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: alert ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: alert ? Colors.red : Colors.black)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text('None')
            else
              ...items.map((item) => ListTile(
                    dense: true,
                    title: Text(item.name),
                    trailing: Text('Qty: ${item.quantity}'),
                  )),
          ],
        ),
      ),
    );
  }
}
