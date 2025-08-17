import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final data = await DBHelper.getAllItems();
    setState(() => _items = data);
  }

  void _showItemDialog({Item? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final qtyController =
        TextEditingController(text: existing?.quantity.toString() ?? '');
    final purchaseController =
        TextEditingController(text: existing?.purchasePrice.toString() ?? '');
    final sellingController =
        TextEditingController(text: existing?.sellingPrice.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Item' : 'Edit Item'),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0), // ✅ FIX: added padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purchaseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Purchase Price'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sellingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Selling Price'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final item = Item(
                id: existing?.id,
                name: nameController.text.trim(),
                quantity: int.tryParse(qtyController.text) ?? 0,
                purchasePrice: double.tryParse(purchaseController.text) ?? 0,
                sellingPrice: double.tryParse(sellingController.text) ?? 0,
              );

              if (existing == null) {
                await DBHelper.insertItem(item);
              } else {
                await DBHelper.updateItem(item);
              }

              if (!mounted) return;
              Navigator.pop(context);
              _loadItems();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.deleteItem(itemId);
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          final isLowStock = item.quantity < 5;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: isLowStock ? Colors.red.shade50 : null,
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Qty: ${item.quantity} • ₹${item.sellingPrice}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showItemDialog(existing: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(item.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
