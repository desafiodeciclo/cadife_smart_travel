class TripCheckpoint {
  final String id;
  final String name;
  final bool completed;
  final bool isCurrent;

  const TripCheckpoint({
    required this.id,
    required this.name,
    required this.completed,
    required this.isCurrent,
  });
}

class ConsultantInfo {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;

  const ConsultantInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}

class HomeDocument {
  final String id;
  final String type; // passport, proposal, insurance, itinerary
  final String displayName;
  final String url;
  final DateTime uploadedAt;
  final String? expiresAt;

  const HomeDocument({
    required this.id,
    required this.type,
    required this.displayName,
    required this.url,
    required this.uploadedAt,
    this.expiresAt,
  });

  String get formattedUploadDate {
    final d = uploadedAt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class TravelRecommendation {
  final String id;
  final String title;
  final String description;
  final String destination;
  final List<String> reasons;
  final double rating;
  final int numberOfReviews;

  const TravelRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.destination,
    required this.reasons,
    required this.rating,
    required this.numberOfReviews,
  });
}

class ClientHomeData {
  final String tripId;
  final String destination;
  final String destinationCountry;
  final String destinationFlag;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImageUrl;
  final String status;
  final double progressPercentage;
  final List<TripCheckpoint> checkpoints;
  final ConsultantInfo consultant;
  final List<HomeDocument> documents;
  final List<TravelRecommendation> recommendations;

  const ClientHomeData({
    required this.tripId,
    required this.destination,
    required this.destinationCountry,
    required this.destinationFlag,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.progressPercentage,
    required this.checkpoints,
    required this.consultant,
    required this.documents,
    required this.recommendations,
    this.coverImageUrl,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String get formattedDateRange => '${_fmt(startDate)} — ${_fmt(endDate)}';
}
