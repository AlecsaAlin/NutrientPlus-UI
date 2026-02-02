/// Model for inventory items
class InventoryItem {
  final String name;
  final String quantity;
  final String category;
  final String emoji;

  InventoryItem({
    required this.name,
    required this.quantity,
    required this.category,
    required this.emoji,
  });

  InventoryItem copyWith({
    String? name,
    String? quantity,
    String? category,
    String? emoji,
  }) {
    return InventoryItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'category': category,
      'emoji': emoji,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      name: json['name'],
      quantity: json['quantity'],
      category: json['category'],
      emoji: json['emoji'],
    );
  }
}
