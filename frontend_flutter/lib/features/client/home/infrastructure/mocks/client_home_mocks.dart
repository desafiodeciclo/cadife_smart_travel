import 'package:cadife_smart_travel/features/client/home/domain/entities/client_document.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_trip.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/consultant_info.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';

class ClientHomeMocks {
  ClientHomeMocks._();

  static ClientTrip mockCurrentTrip() => ClientTrip(
        id: 'trip-1',
        destination: 'Paris',
        destinationCountry: 'França',
        destinationFlag: '🇫🇷',
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 6, 22),
        coverImageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&q=80&w=1200',
        status: 'planejando',
        progressPercentage: 0.65,
        checkpoints: const [
          TripCheckpoint(
            id: 'cp-001',
            name: 'Briefing Coletado',
            completed: true,
            isCurrent: false,
          ),
          TripCheckpoint(
            id: 'cp-002',
            name: 'Proposta de Orçamento',
            completed: false,
            isCurrent: true,
          ),
          TripCheckpoint(
            id: 'cp-003',
            name: 'Proposta Aprovada',
            completed: false,
            isCurrent: false,
          ),
          TripCheckpoint(
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
        photoUrl: 'https://via.placeholder.com/150?text=João',
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
        ),
      ];

  static List<Offer> mockRecommendations() => const [
        Offer(
          id: 'rec-001',
          title: 'Milão - Moda e Gastronomia',
          destination: 'Itália',
          category: 'Cultura',
          description: 'Moda, cultura e gastronomia no coração da Itália',
          estimatedPrice: 5200.0,
          imageUrl: 'https://images.unsplash.com/photo-1513581166358-b66d2a6438b4?auto=format&fit=crop&q=80&w=800',
        ),
        Offer(
          id: 'rec-002',
          title: 'Praga - Cidade Dourada',
          destination: 'Rep. Tcheca',
          category: 'História',
          description: 'A Cidade Dourada com arquitetura medieval incomparável',
          estimatedPrice: 4100.0,
          imageUrl: 'https://images.unsplash.com/photo-1519677100203-a0e668c92439?auto=format&fit=crop&q=80&w=800',
        ),
        Offer(
          id: 'rec-003',
          title: 'Santorini - O Azul do Egeu',
          destination: 'Grécia',
          category: 'Romântico',
          description: 'Vistas deslumbrantes do pôr do sol e águas cristalinas',
          estimatedPrice: 6500.0,
          imageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&q=80&w=800',
        ),
      ];
}
