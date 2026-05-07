// ignore_for_file: one_member_abstracts
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';

abstract class IOfferRepository {
  Future<List<Offer>> getOffers({
    int page = 1,
    int limit = 20,
    String? query,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
  });
}
