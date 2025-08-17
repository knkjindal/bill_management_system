import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/party.dart';
import 'party_detail_screen.dart'; // Make sure this import is correct

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  List<Party> _allParties = [];
  List<Party> _filteredParties = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParties();
    _searchController.addListener(_filterParties);
  }

  Future<void> _loadParties() async {
    final parties = await DBHelper.getAllParties();
    setState(() {
      _allParties = parties;
      _filteredParties = parties; // Initially, all parties are filtered parties
    });
  }

  void _filterParties() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredParties = _allParties.where((p) {
        return p.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Parties')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredParties.length,
              itemBuilder: (_, i) {
                final p = _filteredParties[i]; // Use 'p' for consistency with original code
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(p.phone.isNotEmpty ? p.phone : 'No phone'),
                    trailing: Text(
                      (p.balance >= 0 ? '₹${p.balance}' : '- ₹${-p.balance}'),
                      style: TextStyle(
                        color: p.balance >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PartyDetailsScreen(party: p)),
                      );
                      _loadParties(); // Refresh parties and balances after returning from details screen
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}