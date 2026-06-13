// ── Product Models ────────────────────────────────────────────────────────────
//
// A Product has many Variants. Each Variant is one (color, size) combination
// with its own price and stock count.
//
// Example:
//   Product: "Áo thun cổ tròn"
//   Variants: [Đỏ/S: 120k (50 cái), Đỏ/M: 120k (30 cái), Xanh/S: 130k (20 cái)]

class Variant {
  final int? id;
  final String color;
  final String size;
  final int price;  // VND, always an integer (no floats)
  final int stock;

  const Variant({
    this.id,
    required this.color,
    required this.size,
    required this.price,
    required this.stock,
  });

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        id: j['id'] as int?,
        color: (j['color'] ?? '').toString(),
        size: (j['size'] ?? '').toString(),
        price: (j['price'] ?? 0) as int,
        stock: (j['stock'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'color': color,
        'size': size,
        'price': price,
        'stock': stock,
      };

  String get displayName {
    final parts = [if (color.isNotEmpty) color, if (size.isNotEmpty) size];
    return parts.isEmpty ? 'Mặc định' : parts.join(' / ');
  }
}

class Product {
  final int id;
  final String code;
  final String name;
  final String image;       // relative path or full URL
  final String priceRange;  // e.g. "120.000 – 150.000 ₫" — computed by backend
  final List<Variant> variants;

  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.image,
    required this.priceRange,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        code: (j['code'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        image: (j['image'] ?? '').toString(),
        priceRange: (j['price_range'] ?? '').toString(),
        variants: (j['variants'] as List? ?? [])
            .map((v) => Variant.fromJson(v as Map<String, dynamic>))
            .toList(),
      );

  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);
}
