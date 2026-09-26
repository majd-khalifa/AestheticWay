class CategoryModel {
  final String id;
  final String nameEn;
  final String nameAr;
  final String slug;
  final String? icon;
  final int displayOrder;

  const CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.slug,
    this.icon,
    this.displayOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
      displayOrder: json['display_order'] is int ? json['display_order'] as int : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_ar': nameAr,
      'slug': slug,
      'icon': icon,
      'display_order': displayOrder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
