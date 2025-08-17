import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/item.dart';
import 'party_list_screen.dart';
import 'inventory_screen.dart';
import 'bill_book_screen.dart';
import 'full_dashboard_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalCredit = 0;
  double totalCash = 0;
  List<Item> _lowStockItems = [];

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

    for (var t in txns) {
      if (t.isCredit) {
        credit += t.amount;
      } else {
        cash += t.amount;
      }
    }

    setState(() {
      totalCredit = credit;
      totalCash = cash;
      _lowStockItems = items.where((i) => i.quantity <= 5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Smart Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadDashboardData();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '📅 ${DateFormat.yMMMMd().format(DateTime.now())}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FullDashboardScreen()),
                );
              },
              child: Row(
                children: [
                  Expanded(child: _buildSummaryCard('Credit Pending', totalCredit, Colors.orange)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSummaryCard('Cash Received', totalCash, Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildLowStockCard(),
            const SizedBox(height: 24),
            _buildNavButton('📒 Parties', Icons.people, const PartyListScreen()),
            _buildNavButton('📦 Inventory', Icons.inventory_2, const InventoryScreen()),
            _buildNavButton('🧾 Bill Book', Icons.receipt_long, const BillBookScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard() {
    if (_lowStockItems.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Low Stock Items', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (var item in _lowStockItems)
              Text('${item.name} - ${item.quantity} left', style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String label, IconData icon, Widget screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 60,
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.indigo.shade50,
            foregroundColor: Colors.indigo.shade800,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
          ),
          icon: Icon(icon, size: 26),
          label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          },
        ),
      ),
    );
  }
}
