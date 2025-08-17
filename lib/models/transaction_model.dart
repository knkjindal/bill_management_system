class TransactionModel {
  final int? id;
  final int partyId;
  final int itemId;
  final int quantity;
  final double amount;
  final String date;
  final bool isCredit;
  final String type; // 'Sale' or 'Purchase'

  TransactionModel({
    this.id,
    required this.partyId,
    required this.itemId,
    required this.quantity,
    required this.amount,
    required this.date,
    required this.isCredit,
    required this.type, required String note, required List<String> tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyId': partyId,
      'itemId': itemId,
      'quantity': quantity,
      'amount': amount,
      'date': date,
      'isCredit': isCredit ? 1 : 0,
      'type': type,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      partyId: map['partyId'],
      itemId: map['itemId'],
      quantity: map['quantity'],
      amount: map['amount'],
      date: map['date'],
      isCredit: map['isCredit'] == 1,
      type: map['type'] ?? 'Sale', note: '', tags: [],
    );
  }

  get note => null;
}
