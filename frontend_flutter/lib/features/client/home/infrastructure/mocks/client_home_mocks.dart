import 'package:cadife_smart_travel/features/client/home/domain/entities/client_document.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_trip.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/consultant_info.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';

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
        roteiro: 'Uma jornada inesquecível por Paris, a Cidade Luz. Exploraremos os principais monumentos, como a Torre Eiffel e o Museu do Louvre, além de caminhadas charmosas pelo bairro de Le Marais e jantares em bistrôs típicos franceses.',
      );

  /// Alinhado com backend/scripts/db/seeds/01_users.py — Daniela Costa
  static ConsultantInfo mockConsultant() => const ConsultantInfo(
        id: 'daniela-costa',
        name: 'Daniela Costa',
        phone: '+5511977777777',
        photoUrl: 'https://i.pravatar.cc/150?u=daniela',
        email: 'daniela.costa@cadifetoure.com.br',
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

  static List<Offer> mockRecommendations() => [
        Offer(
          id: 'rec-001',
          title: 'Milão - Moda e Gastronomia',
          destination: 'Itália',
          category: 'Cultura',
          description: 'Moda, cultura e gastronomia no coração da Itália',
          basePrice: 5500.0,
          finalPrice: 5200.0,
          currency: 'BRL',
          departureDate: DateTime(2026, 9, 10),
          returnDate: DateTime(2026, 9, 17),
          durationDays: 7,
          travelers: 2,
          availableSpots: 10,
          spotsReserved: 2,
          status: 'active',
          highlights: ['Moda', 'Gastronomia', 'Cultura'],
          amenities: ['Voo incluso', 'Hotel 4 estrelas'],
          views: 120,
          interests: 45,
          destinationImageUrl: 'https://images.unsplash.com/photo-1520923179278-ee25e24e467e?auto=format&fit=crop&q=80&w=800',
        ),
        Offer(
          id: 'rec-002',
          title: 'Praga - Cidade Dourada',
          destination: 'Rep. Tcheca',
          category: 'História',
          description: 'A Cidade Dourada com arquitetura medieval incomparável',
          basePrice: 4500.0,
          finalPrice: 4100.0,
          currency: 'BRL',
          departureDate: DateTime(2026, 10, 5),
          returnDate: DateTime(2026, 10, 10),
          durationDays: 5,
          travelers: 2,
          availableSpots: 8,
          spotsReserved: 3,
          status: 'active',
          highlights: ['História', 'Arquitetura', 'Cerveja Artesanal'],
          amenities: ['Voo incluso', 'Guia em português'],
          views: 85,
          interests: 22,
          destinationImageUrl: 'https://images.unsplash.com/photo-1519677100203-a0e668c92439?auto=format&fit=crop&q=80&w=800',
        ),
        Offer(
          id: 'rec-003',
          title: 'Santorini - O Azul do Egeu',
          destination: 'Grécia',
          category: 'Romântico',
          description: 'Vistas deslumbrantes do pôr do sol e águas cristalinas',
          basePrice: 7000.0,
          finalPrice: 6500.0,
          currency: 'BRL',
          departureDate: DateTime(2026, 8, 20),
          returnDate: DateTime(2026, 8, 26),
          durationDays: 6,
          travelers: 2,
          availableSpots: 6,
          spotsReserved: 4,
          status: 'active',
          highlights: ['Pôr do Sol', 'Mar Egeu', 'Romantismo'],
          amenities: ['Hotel Boutique', 'Café da manhã incluso'],
          views: 210,
          interests: 88,
          destinationImageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&q=80&w=800',
        ),
      ];

  static List<ItineraryItem> mockItineraryItems(String leadId) => [
        ItineraryItem(
          id: 'itin-001',
          leadId: leadId,
          tipo: ItineraryItemType.voo,
          titulo: 'Voo GRU → CDG',
          descricao: 'Air France AF457. Portão G12. Check-in às 19h.',
          local: 'Aeroporto de Guarulhos (GRU)',
          dataHora: DateTime(2026, 6, 15, 22, 10),
          dataHoraFim: DateTime(2026, 6, 16, 14, 00),
          notas: 'Franquia de bagagem: 2 x 23kg',
        ),
        ItineraryItem(
          id: 'itin-002',
          leadId: leadId,
          tipo: ItineraryItemType.transferencia,
          titulo: 'Traslado Aeroporto → Hotel',
          descricao: 'Motorista particular aguardando no desembarque com placa.',
          local: 'Aeroporto Charles de Gaulle (CDG)',
          dataHora: DateTime(2026, 6, 16, 15, 00),
          dataHoraFim: DateTime(2026, 6, 16, 16, 00),
        ),
        ItineraryItem(
          id: 'itin-003',
          leadId: leadId,
          tipo: ItineraryItemType.hotelCheckin,
          titulo: 'Check-in — Hôtel Le Marais',
          descricao: 'Reserva confirmada. Quarto Deluxe com vista.',
          local: '75003 Paris, França',
          dataHora: DateTime(2026, 6, 16, 16, 30),
          dataHoraFim: DateTime(2026, 6, 22, 11, 00),
        ),
        ItineraryItem(
          id: 'itin-004',
          leadId: leadId,
          tipo: ItineraryItemType.refeicao,
          titulo: 'Jantar de Boas-vindas',
          descricao: 'Reserva no Le Comptoir du Relais.',
          local: '9 Carrefour de l\'Odéon, Paris',
          dataHora: DateTime(2026, 6, 16, 20, 00),
        ),
      ];
}
