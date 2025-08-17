class Item {
  int? id;
  String name;
  int quantity;
  double purchasePrice;
  double sellingPrice;

  Item({
    this.id,
    required this.name,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      purchasePrice: map['purchasePrice'],
      sellingPrice: map['sellingPrice'],
    );
  }
}
