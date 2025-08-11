class SubscriptionModel {
  final String id;
  final String name;
  final String price;
  final String nextDue;
  final String userId;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.price,
    required this.nextDue,
    required this.userId,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      name: map['name'],
      price: map['price'],
      nextDue: map['nextDue'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'nextDue': nextDue, 'userId': userId};
  }
}
