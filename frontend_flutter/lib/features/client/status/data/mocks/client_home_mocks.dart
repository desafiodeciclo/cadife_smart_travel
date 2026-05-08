import 'package:cadife_smart_travel/features/client/status/domain/entities/home_page_data.dart';

class ClientHomeMocks {
  ClientHomeMocks._();

  static ClientHomeData homeData() => ClientHomeData(
        tripId: 'trip-1',
        destination: 'Paris',
        destinationCountry: 'França',
        destinationFlag: '🇫🇷',
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 6, 22),
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
        consultant: const ConsultantInfo(
          id: 'consultant-001',
          name: 'João Santos',
          phone: '+5511999887766',
        ),
        documents: [
          HomeDocument(
            id: 'doc-001',
            type: 'passport',
            displayName: 'Passaporte',
            url: '',
            uploadedAt: DateTime(2026, 4, 10),
            expiresAt: '15/08/2033',
          ),
          HomeDocument(
            id: 'doc-002',
            type: 'proposal',
            displayName: 'Proposta de Orçamento',
            url: '',
            uploadedAt: DateTime(2026, 4, 12),
          ),
          HomeDocument(
            id: 'doc-003',
            type: 'insurance',
            displayName: 'Seguro Viagem',
            url: '',
            uploadedAt: DateTime(2026, 4, 15),
            expiresAt: '22/06/2026',
          ),
          HomeDocument(
            id: 'doc-004',
            type: 'itinerary',
            displayName: 'Roteiro Detalhado',
            url: '',
            uploadedAt: DateTime(2026, 4, 18),
          ),
        ],
        recommendations: const [
          TravelRecommendation(
            id: 'rec-001',
            title: 'Milão',
            description: 'Moda, cultura e gastronomia no coração da Itália',
            destination: 'Milão, Itália',
            reasons: ['Moda & Design', 'Gastronomia'],
            rating: 4.8,
            numberOfReviews: 1240,
          ),
          TravelRecommendation(
            id: 'rec-002',
            title: 'Praga',
            description: 'A Cidade Dourada com arquitetura medieval incomparável',
            destination: 'Praga, República Tcheca',
            reasons: ['Arquitetura', 'Vida Noturna'],
            rating: 4.7,
            numberOfReviews: 980,
          ),
        ],
      );
}
