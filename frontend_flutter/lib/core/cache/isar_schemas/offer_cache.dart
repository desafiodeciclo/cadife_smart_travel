import 'package:isar/isar.dart';

part 'offer_cache.g.dart';

@collection
class OfferCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String title;
  late String destination;
  late String category;
  late String description;
  late double estimatedPrice;
  late String imageUrl;
  
  // Para ordenação e buscas
  @Index()
  late DateTime updatedAt;

  // Construtor
  OfferCache({
    required this.serverId,
    required this.title,
    required this.destination,
    required this.category,
    required this.description,
    required this.estimatedPrice,
    required this.imageUrl,
    required this.updatedAt,
  });

  // Default constructor for Isar
  OfferCache.isar();
}
