class Party {
  int? id;
  String name;
  String phone;
  double balance;
  bool isCreditor; // true = to be received, false = to be paid

  Party({
    this.id,
    required this.name,
    required this.phone,
    required this.balance,
    required this.isCreditor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'balance': balance,
      'isCreditor': isCreditor ? 1 : 0,
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      balance: map['balance'] ?? 0.0,
      isCreditor: map['isCreditor'] == 1,
    );
  }
}
