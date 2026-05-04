import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock data Ã¢â‚¬â€ serÃƒÂ¡ substituÃƒÂ­do por API real
final _mockGlobalDocuments = [
  Documento(
    id: 'doc-1',
    name: 'Roteiro da Viagem',
    type: DocumentType.pdf,
    size: 2048000,
    url: 'https://example.com/roteiro.pdf',
    isGlobal: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    category: 'Roteiro',
  ),
  Documento(
    id: 'doc-2',
    name: 'Voucher de Hotel',
    type: DocumentType.pdf,
    size: 1100000,
    url: 'https://example.com/voucher.pdf',
    isGlobal: true,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    category: 'Voucher',
  ),
  Documento(
    id: 'doc-3',
    name: 'Comprovante de Seguro',
    type: DocumentType.pdf,
    size: 800000,
    url: 'https://example.com/seguro.pdf',
    isGlobal: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    category: 'Seguro',
  ),
  Documento(
    id: 'doc-4',
    name: 'Passagens AÃƒÂ©reas',
    type: DocumentType.pdf,
    size: 3200000,
    url: 'https://example.com/passagens.pdf',
    isGlobal: true,
    createdAt: DateTime.now(),
    category: 'Passagens',
  ),
  Documento(
    id: 'doc-5',
    name: 'Foto do Passaporte',
    type: DocumentType.image,
    size: 500000,
    url: 'https://images.unsplash.com/photo-1544027993-37dbfe43562a?auto=format&fit=crop&q=80&w=800',
    isGlobal: true,
    createdAt: DateTime.now(),
    category: 'Geral',
  ),
];

final _mockTripsWithDocuments = [
  Lead(
    id: 'trip-1',
    name: 'Paris & Londres 2024',
    phone: '+5511999999999',
    status: LeadStatus.agendado,
    score: LeadScore.quente,
    completudePct: 100,
    destino: 'Paris, FranÃƒÂ§a e Londres, Reino Unido',
    dataIda: DateTime(2024, 7, 15),
    dataVolta: DateTime(2024, 7, 22),
    numPessoas: 2,
    imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&q=80&w=400',
  ),
  Lead(
    id: 'trip-2',
    name: 'Maldivas 2024',
    phone: '+5511999999999',
    status: LeadStatus.proposta,
    score: LeadScore.quente,
    completudePct: 95,
    destino: 'Maldivas',
    dataIda: DateTime(2024, 8, 20),
    dataVolta: DateTime(2024, 8, 27),
    numPessoas: 4,
    imageUrl: 'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?auto=format&fit=crop&q=80&w=400',
  ),
];

final _mockTripDocuments = {
  'trip-1': [
    Documento(
      id: 'trip1-doc-1',
      name: 'Roteiro da Viagem',
      type: DocumentType.pdf,
      size: 2048000,
      url: 'https://example.com/paris-roteiro.pdf',
      tripId: 'trip-1',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Documento(
      id: 'trip1-doc-2',
      name: 'Voucher de Hotel',
      type: DocumentType.pdf,
      size: 1100000,
      url: 'https://example.com/paris-hotel.pdf',
      tripId: 'trip-1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Documento(
      id: 'trip1-doc-3',
      name: 'Comprovante de Seguro',
      type: DocumentType.pdf,
      size: 800000,
      url: 'https://example.com/paris-seguro.pdf',
      tripId: 'trip-1',
      createdAt: DateTime.now(),
    ),
    Documento(
      id: 'trip1-doc-4',
      name: 'Passagens AÃƒÂ©reas',
      type: DocumentType.pdf,
      size: 3200000,
      url: 'https://example.com/paris-passagens.pdf',
      tripId: 'trip-1',
      createdAt: DateTime.now(),
    ),
  ],
  'trip-2': [
    Documento(
      id: 'trip2-doc-1',
      name: 'Roteiro Maldivas',
      type: DocumentType.pdf,
      size: 1500000,
      url: 'https://example.com/maldivas-roteiro.pdf',
      tripId: 'trip-2',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Documento(
      id: 'trip2-doc-2',
      name: 'Resort Booking',
      type: DocumentType.pdf,
      size: 900000,
      url: 'https://example.com/maldivas-resort.pdf',
      tripId: 'trip-2',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ],
};

/// Provedor para documentos principais (globais)
final globalDocumentsProvider = FutureProvider<List<Documento>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockGlobalDocuments;
});

/// Provedor para lista de trips/viagens que possuem documentos
final tripsWithDocumentsProvider = FutureProvider<List<Lead>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockTripsWithDocuments;
});

/// Provedor para documentos de uma trip especÃƒÂ­fica
final tripDocumentsProvider = FutureProvider.family<List<Documento>, String>((ref, tripId) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockTripDocuments[tripId] ?? [];
});



