import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ItineraryItemType {
  voo,
  hotelCheckin,
  hotelCheckout,
  passeio,
  transferencia,
  refeicao,
  eventoCustomizado;

  IconData get icon {
    switch (this) {
      case ItineraryItemType.voo:
        return LucideIcons.plane;
      case ItineraryItemType.hotelCheckin:
      case ItineraryItemType.hotelCheckout:
        return LucideIcons.building2;
      case ItineraryItemType.passeio:
        return LucideIcons.mapPin;
      case ItineraryItemType.transferencia:
        return LucideIcons.bus;
      case ItineraryItemType.refeicao:
        return LucideIcons.utensils;
      case ItineraryItemType.eventoCustomizado:
        return LucideIcons.star;
    }
  }

  Color get color {
    switch (this) {
      case ItineraryItemType.voo:
        return const Color(0xFFDD0B0E);
      case ItineraryItemType.hotelCheckin:
      case ItineraryItemType.hotelCheckout:
        return const Color(0xFF0066CC);
      case ItineraryItemType.passeio:
        return const Color(0xFF00AA44);
      case ItineraryItemType.transferencia:
        return const Color(0xFFFF9900);
      case ItineraryItemType.refeicao:
        return const Color(0xFF9933FF);
      case ItineraryItemType.eventoCustomizado:
        return const Color(0xFFFFCC00);
    }
  }

  String get label {
    switch (this) {
      case ItineraryItemType.voo:
        return 'Voo';
      case ItineraryItemType.hotelCheckin:
        return 'Check-in';
      case ItineraryItemType.hotelCheckout:
        return 'Check-out';
      case ItineraryItemType.passeio:
        return 'Passeio';
      case ItineraryItemType.transferencia:
        return 'Transfer';
      case ItineraryItemType.refeicao:
        return 'Refeição';
      case ItineraryItemType.eventoCustomizado:
        return 'Evento';
    }
  }

  static ItineraryItemType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'voo':
        return ItineraryItemType.voo;
      case 'hotel_checkin':
        return ItineraryItemType.hotelCheckin;
      case 'hotel_checkout':
        return ItineraryItemType.hotelCheckout;
      case 'passeio':
        return ItineraryItemType.passeio;
      case 'transferencia':
        return ItineraryItemType.transferencia;
      case 'refeicao':
        return ItineraryItemType.refeicao;
      default:
        return ItineraryItemType.eventoCustomizado;
    }
  }
}

class ItineraryItem extends Equatable {
  const ItineraryItem({
    required this.id,
    required this.leadId,
    required this.tipo,
    required this.titulo,
    required this.dataHora,
    this.descricao,
    this.local,
    this.endereco,
    this.dataHoraFim,
    this.notas,
  });

  final String id;
  final String leadId;
  final ItineraryItemType tipo;
  final String titulo;
  final String? descricao;
  final String? local;
  final String? endereco;
  final DateTime dataHora;
  final DateTime? dataHoraFim;
  final String? notas;

  factory ItineraryItem.fromJson(Map<String, dynamic> json, String leadId) {
    return ItineraryItem(
      id: json['id'] as String,
      leadId: leadId,
      tipo: ItineraryItemType.fromString(json['tipo'] as String? ?? ''),
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String?,
      local: json['local'] as String?,
      endereco: json['endereco'] as String?,
      dataHora: DateTime.parse(json['horarioInicio'] as String),
      dataHoraFim: json['horarioFim'] != null
          ? DateTime.parse(json['horarioFim'] as String)
          : null,
      notas: json['notas'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leadId': leadId,
        'tipo': tipo.name,
        'titulo': titulo,
        'descricao': descricao,
        'local': local,
        'endereco': endereco,
        'horarioInicio': dataHora.toIso8601String(),
        'horarioFim': dataHoraFim?.toIso8601String(),
        'notas': notas,
      };

  ItineraryItem copyWith({String? notas}) {
    return ItineraryItem(
      id: id,
      leadId: leadId,
      tipo: tipo,
      titulo: titulo,
      descricao: descricao,
      local: local,
      endereco: endereco,
      dataHora: dataHora,
      dataHoraFim: dataHoraFim,
      notas: notas ?? this.notas,
    );
  }

  @override
  List<Object?> get props => [
        id,
        leadId,
        tipo,
        titulo,
        descricao,
        local,
        endereco,
        dataHora,
        dataHoraFim,
        notas,
      ];
}
