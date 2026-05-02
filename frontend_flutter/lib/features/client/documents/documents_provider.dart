import 'package:cadife_smart_travel/shared/models/document_model.dart';
import 'package:cadife_smart_travel/shared/models/lead_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock data — será substituído por API real
final _mockGlobalDocuments = [
  DocumentModel(
    id: 'doc-1',
    name: 'Roteiro da Viagem',
    type: DocumentType.pdf,
    size: 2048000,
    url: 'https://example.com/roteiro.pdf',
    isGlobal: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    category: 'Roteiro',
  ),
  DocumentModel(
    id: 'doc-2',
    name: 'Voucher de Hotel',
    type: DocumentType.pdf,
    size: 1100000,
    url: 'https://example.com/voucher.pdf',
    isGlobal: true,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    category: 'Voucher',
  ),
  DocumentModel(
    id: 'doc-3',
    name: 'Comprovante de Seguro',
    type: DocumentType.pdf,
    size: 800000,
    url: 'https://example.com/seguro.pdf',
    isGlobal: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    category: 'Seguro',
  ),
  DocumentModel(
    id: 'doc-4',
    name: 'Passagens Aéreas',
    type: DocumentType.pdf,
    size: 3200000,
    url: 'https://example.com/passagens.pdf',
    isGlobal: true,
    createdAt: DateTime.now(),
    category: 'Passagens',
  ),
  DocumentModel(
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
  LeadModel(
    id: 'trip-1',
    name: 'Paris & Londres 2024',
    phone: '+5511999999999',
    status: LeadStatus.agendado,
    score: LeadScore.quente,
    completudePct: 100,
    destino: 'Paris, França e Londres, Reino Unido',
    dataIda: DateTime(2024, 7, 15),
    dataVolta: DateTime(2024, 7, 22),
    numPessoas: 2,
    imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&q=80&w=400',
  ),
  LeadModel(
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
    DocumentModel(
      id: 'trip1-doc-1',
      name: 'Roteiro da Viagem',
      type: DocumentType.pdf,
      size: 2048000,
      url: 'https://example.com/paris-roteiro.pdf',
      tripId: 'trip-1',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DocumentModel(
      id: 'trip1-doc-2',
      name: 'Voucher de Hotel',
      type: DocumentType.pdf,
      size: 1100000,
      url: 'https://example.com/paris-hotel.pdf',
      tripId: 'trip-1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DocumentModel(
      id: 'trip1-doc-3',
      name: 'Comprovante de Seguro',
      type: DocumentType.pdf,
      size: 800000,
      url: 'https://example.com/paris-seguro.pdf',
      tripId: 'trip-1',
      createdAt: DateTime.now(),
    ),
    DocumentModel(
      id: 'trip1-doc-4',
      name: 'Passagens Aéreas',
      type: DocumentType.pdf,
      size: 3200000,
      url: 'https://example.com/paris-passagens.pdf',
      tripId: 'trip-1',
      createdAt: DateTime.now(),
    ),
  ],
  'trip-2': [
    DocumentModel(
      id: 'trip2-doc-1',
      name: 'Roteiro Maldivas',
      type: DocumentType.pdf,
      size: 1500000,
      url: 'https://example.com/maldivas-roteiro.pdf',
      tripId: 'trip-2',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    DocumentModel(
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
final globalDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockGlobalDocuments;
});

/// Provedor para lista de trips/viagens que possuem documentos
final tripsWithDocumentsProvider = FutureProvider<List<LeadModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockTripsWithDocuments;
});

/// Provedor para documentos de uma trip específica
final tripDocumentsProvider = FutureProvider.family<List<DocumentModel>, String>((ref, tripId) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockTripDocuments[tripId] ?? [];
});
