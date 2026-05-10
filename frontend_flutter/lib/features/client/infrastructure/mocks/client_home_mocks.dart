// lib/features/client/infrastructure/mocks/client_home_mocks.dart

import 'package:cadife_smart_travel/features/client/domain/entities/client_trip.dart';

class ClientHomeMocks {
  static ClientTrip mockCurrentTrip() => ClientTrip(
    id: 'trip-001',
    destination: 'Paris',
    destinationCountry: 'França',
    destinationFlag: '🇫🇷',
    startDate: DateTime(2026, 6, 15),
    endDate: DateTime(2026, 6, 22),
    coverImageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=800&auto=format&fit=crop',
    status: 'planejando',
    progressPercentage: 0.65,
    currentCheckpoint: const TripCheckpoint(
      id: 'cp-002',
      name: 'Proposta de Orçamento',
      completed: false,
      isCurrent: true,
    ),
    checkpoints: [
      const TripCheckpoint(
        id: 'cp-001',
        name: 'Briefing Coletado',
        completed: true,
        isCurrent: false,
      ),
      const TripCheckpoint(
        id: 'cp-002',
        name: 'Proposta de Orçamento',
        completed: false,
        isCurrent: true,
      ),
      const TripCheckpoint(
        id: 'cp-003',
        name: 'Proposta Aprovada',
        completed: false,
        isCurrent: false,
      ),
      const TripCheckpoint(
        id: 'cp-004',
        name: 'Viagem Confirmada',
        completed: false,
        isCurrent: false,
      ),
    ],
  );
  
  static ConsultantInfo mockConsultant() => const ConsultantInfo(
    id: 'consultant-001',
    name: 'João Santos',
    phone: '+5511999887766',
    photoUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=200&auto=format&fit=crop',
    email: 'joao.santos@cadife.com',
  );
  
  static List<ClientDocument> mockDocuments() => [
    ClientDocument(
      id: 'doc-001',
      type: 'passport',
      displayName: 'Passaporte',
      url: 'https://example.com/passport.pdf',
      uploadedAt: DateTime(2026, 4, 10),
      expiresAt: '2033-08-15',
    ),
    ClientDocument(
      id: 'doc-002',
      type: 'proposal',
      displayName: 'Proposta de Orçamento',
      url: 'https://example.com/proposal.pdf',
      uploadedAt: DateTime(2026, 4, 12),
      expiresAt: null,
    ),
    ClientDocument(
      id: 'doc-003',
      type: 'insurance',
      displayName: 'Seguro Viagem',
      url: 'https://example.com/insurance.pdf',
      uploadedAt: DateTime(2026, 4, 15),
      expiresAt: '2026-06-22',
    ),
    ClientDocument(
      id: 'doc-004',
      type: 'itinerary',
      displayName: 'Roteiro',
      url: 'https://example.com/itinerary.pdf',
      uploadedAt: DateTime(2026, 4, 18),
      expiresAt: null,
    ),
  ];
  
  static List<TravelRecommendation> mockRecommendations() => [
    const TravelRecommendation(
      id: 'rec-001',
      title: 'Milão',
      description: 'Moda, cultura e gastronomia no coração da Itália',
      imageUrl: 'https://images.unsplash.com/photo-1513581166391-887a96ddeafd?q=80&w=800&auto=format&fit=crop',
      destination: 'Milão, Itália',
      reasons: ['Moda & Design', 'Gastronomia'],
      rating: 4.8,
      numberOfReviews: 1240,
    ),
    const TravelRecommendation(
      id: 'rec-002',
      title: 'Praga',
      description: 'A Cidade Dourada com arquitetura medieval incomparável',
      imageUrl: 'https://images.unsplash.com/photo-1541849543133-21941425a69f?q=80&w=800&auto=format&fit=crop',
      destination: 'Praga, República Tcheca',
      reasons: ['Arquitetura Medieval', 'Vida Noturna'],
      rating: 4.7,
      numberOfReviews: 980,
    ),
  ];
}
