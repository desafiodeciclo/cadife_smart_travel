class Offer {
  final String id;
  final String title;
  final String destination;
  final String category;
  final String description;
  final double estimatedPrice;
  final String imageUrl;

  const Offer({
    required this.id,
    required this.title,
    required this.destination,
    required this.category,
    required this.description,
    required this.estimatedPrice,
    required this.imageUrl,
  });

  double get price => estimatedPrice;

  // copyWith
  Offer copyWith({
    String? id,
    String? title,
    String? destination,
    String? category,
    String? description,
    double? estimatedPrice,
    String? imageUrl,
  }) {
    return Offer(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      category: category ?? this.category,
      description: description ?? this.description,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
