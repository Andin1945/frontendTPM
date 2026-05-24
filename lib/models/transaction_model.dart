class TransactionModel {
  int? id;
  String title;
  double amount;
  String type;
  String date;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "amount": amount,
      "type": type,
      "date": date,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map["id"],
      title: map["title"],
      amount: (map["amount"] as num).toDouble(),
      type: map["type"],
      date: map["date"],
    );
  }
}
