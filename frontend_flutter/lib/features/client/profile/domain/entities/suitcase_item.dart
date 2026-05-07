import 'package:equatable/equatable.dart';

class SuitcaseItem extends Equatable {
  const SuitcaseItem({
    required this.id,
    required this.tripId,
    required this.category,
    required this.name,
    required this.createdAt,
    this.quantity = 1,
    this.packed = false,
    this.isSuggestion = false,
  });

  final String id;
  final String tripId;
  // Documentos | Roupas | Higiene | Eletrônicos | Outros
  final String category;
  final String name;
  final int quantity;
  final bool packed;
  final bool isSuggestion;
  final DateTime createdAt;

  SuitcaseItem copyWith({
    String? name,
    int? quantity,
    bool? packed,
    String? category,
  }) {
    return SuitcaseItem(
      id: id,
      tripId: tripId,
      category: category ?? this.category,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      packed: packed ?? this.packed,
      isSuggestion: isSuggestion,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, tripId, category, name, quantity, packed, isSuggestion, createdAt];
}
