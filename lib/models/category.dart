class Category {
  final int? id;
  final String name;
  final String type; // 'income' or 'expense'
  final int colorValue; // For UI customization
  final bool isEnabled; // Whether category is active/enabled

  Category({
    this.id,
    required this.name,
    required this.type,
    this.colorValue = 0xFF2196F3, // Default blue color
    this.isEnabled = true, // Default to enabled
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'colorValue': colorValue,
      'isEnabled': isEnabled ? 1 : 0, // SQLite stores boolean as integer
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      colorValue: map['colorValue'] ?? 0xFF2196F3,
      isEnabled: (map['isEnabled'] ?? 1) == 1, // Convert integer back to boolean
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    int? colorValue,
    bool? isEnabled,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, type: $type, colorValue: $colorValue, isEnabled: $isEnabled}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 