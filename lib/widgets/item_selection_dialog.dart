import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/item.dart';

class ItemSelectionDialog extends StatefulWidget {
  final List<Item> items;
  final bool isPurchase;
  const ItemSelectionDialog({
    super.key,
    required this.items,
    required this.isPurchase,
  });

  @override
  State<ItemSelectionDialog> createState() => _ItemSelectionDialogState();
}

class _ItemSelectionDialogState extends State<ItemSelectionDialog> {
  final List<Item> selected = [];
  final List<int> quantities = [];

  void _refreshItems() async {
    final updated = await DBHelper.getAllItems();
    setState(() {
      widget.items.clear();
      widget.items.addAll(updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Items'),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        width: double.maxFinite,
        child: Column(
          children: [
            Expanded(
              child: widget.items.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      itemCount: widget.items.length,
                      itemBuilder: (_, index) {
                        final item = widget.items[index];
                        final isSelected = selected.contains(item);
                        final qtyIndex = selected.indexOf(item);
                        final price = widget.isPurchase
                            ? item.purchasePrice
                            : item.sellingPrice;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: isSelected
                                ? TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                    ),
                                    onChanged: (v) {
                                      final q = int.tryParse(v) ?? 1;
                                      quantities[qtyIndex] = q;
                                    },
                                  )
                                : Text('Price: ₹${price.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: Icon(isSelected
                                  ? Icons.remove_circle
                                  : Icons.add_circle),
                              onPressed: () {
                                setState(() {
                                  if (isSelected) {
                                    final i = selected.indexOf(item);
                                    selected.removeAt(i);
                                    quantities.removeAt(i);
                                  } else {
                                    selected.add(item);
                                    quantities.add(1);
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Item'),
              onPressed: () async {
                final nameCtrl = TextEditingController();
                final purchaseCtrl = TextEditingController();
                final sellCtrl = TextEditingController();

                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Add Item'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        TextField(
                          controller: purchaseCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Purchase Price'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: sellCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Selling Price'),
                          keyboardType: TextInputType.number,
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
                          final name = nameCtrl.text.trim();
                          final purchase = double.tryParse(purchaseCtrl.text) ?? 0;
                          final sell = double.tryParse(sellCtrl.text) ?? 0;

                          if (name.isNotEmpty && (purchase > 0 || sell > 0)) {
                            final newItem = Item(
                              name: name,
                              quantity: 0,
                              purchasePrice: purchase,
                              sellingPrice: sell,
                            );
                            await DBHelper.insertItem(newItem);
                            Navigator.pop(context);
                            _refreshItems();
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'items': selected,
              'quantities': quantities,
            });
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
