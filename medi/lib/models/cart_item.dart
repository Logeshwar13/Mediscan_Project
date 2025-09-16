import 'medicine.dart';

class CartItem {
  final Medicine medicine;
  int quantity;

  CartItem({
    required this.medicine, 
    required this.quantity
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      medicine: Medicine.fromJson(json['medicine']),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine': medicine.toJson(),
      'quantity': quantity,
    };
  }

  double get totalPrice => medicine.price * quantity;

  @override
  String toString() => 'CartItem{medicine: ${medicine.name}, quantity: $quantity}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.medicine.id == medicine.id &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => medicine.id.hashCode ^ quantity.hashCode;

  // Create a copy of this CartItem with updated quantity
  CartItem copyWith({int? quantity}) {
    return CartItem(
      medicine: medicine,
      quantity: quantity ?? this.quantity,
    );
  }
}