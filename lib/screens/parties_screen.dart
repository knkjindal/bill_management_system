import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/party.dart';
import 'party_detail_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  List<Party> _parties = [];

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    final parties = await DBHelper.getAllParties();
    setState(() {
      _parties = parties;
    });
  }

  Future<void> _showPartyForm({Party? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    bool isCreditor = existing?.isCreditor ?? true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Party' : 'Edit Party'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Type:'),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Creditor'),
                      value: true,
                      groupValue: isCreditor,
                      onChanged: (val) => setState(() => isCreditor = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Debitor'),
                      value: false,
                      groupValue: isCreditor,
                      onChanged: (val) => setState(() => isCreditor = val!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final party = Party(
                  id: existing?.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  balance: existing?.balance ?? 0,
                  isCreditor: isCreditor,
                );

                if (existing == null) {
                  await DBHelper.insertParty(party);
                } else {
                  await DBHelper.updateParty(party);
                }

                if (!mounted) return;
                Navigator.pop(context);
                _loadParties();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Party?'),
        content: const Text('Are you sure you want to delete this party?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.deleteParty(id);
      _loadParties();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Party deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties'),
        centerTitle: true,
      ),
      body: _parties.isEmpty
          ? const Center(child: Text('No parties added yet.'))
          : ListView.builder(
              itemCount: _parties.length,
              itemBuilder: (_, i) {
                final party = _parties[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartyDetailsScreen(party: party),
                        ),
                      );
                    },
                    title: Text(
                      party.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(party.phone.isNotEmpty ? 'Phone: ${party.phone}' : 'No phone'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${party.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: party.balance >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showPartyForm(existing: party),
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit Party',
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(party.id!),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Party',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPartyForm(),
        tooltip: 'Add Party',
        child: const Icon(Icons.add),
      ),
    );
  }
}
