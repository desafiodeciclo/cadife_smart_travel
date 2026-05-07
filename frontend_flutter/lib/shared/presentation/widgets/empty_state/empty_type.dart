import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum EmptyType {
  emptyList,           // Lista vazia
  emptySearch,         // Nenhum resultado de busca
  noLeads,             // Nenhum lead encontrado
  noNotifications,     // Nenhuma notificação
  noTrips,             // Nenhuma viagem
  noOffers,            // Nenhuma oferta
  noDocuments,         // Nenhum documento
  emptyJournal,        // Diário vazio
  notFound,            // Recurso não encontrado
  notImplemented,      // Feature não implementada
}

extension EmptyTypeConfig on EmptyType {
  String get title {
    return switch (this) {
      EmptyType.emptyList => 'Nenhum item encontrado',
      EmptyType.emptySearch => 'Nenhum resultado',
      EmptyType.noLeads => 'Nenhum lead no momento',
      EmptyType.noNotifications => 'Nenhuma notificação',
      EmptyType.noTrips => 'Nenhuma viagem contratada',
      EmptyType.noOffers => 'Nenhuma oferta disponível',
      EmptyType.noDocuments => 'Nenhum documento',
      EmptyType.emptyJournal => 'Comece a registrar suas memórias',
      EmptyType.notFound => 'Não encontrado',
      EmptyType.notImplemented => 'Em breve',
    };
  }
  
  String get subtitle {
    return switch (this) {
      EmptyType.emptyList =>
        'Não há itens para exibir no momento.',
      EmptyType.emptySearch =>
        'Tente ajustar os filtros ou a busca.',
      EmptyType.noLeads =>
        'Crie um novo lead para começar.',
      EmptyType.noNotifications =>
        'Você verá notificações aqui quando surgir algo novo.',
      EmptyType.noTrips =>
        'Explore nossas ofertas e contrate uma viagem.',
      EmptyType.noOffers =>
        'Volte em breve para ver novas ofertas.',
      EmptyType.noDocuments =>
        'Os documentos da sua viagem aparecerão aqui.',
      EmptyType.emptyJournal =>
        'Adicione fotos e notas das suas experiências.',
      EmptyType.notFound =>
        'O item que você procura não foi encontrado.',
      EmptyType.notImplemented =>
        'Esta funcionalidade será lançada em breve.',
    };
  }
  
  IconData get icon {
    return switch (this) {
      EmptyType.emptyList => LucideIcons.inbox,
      EmptyType.emptySearch => LucideIcons.searchX,
      EmptyType.noLeads => LucideIcons.userPlus,
      EmptyType.noNotifications => LucideIcons.bellOff,
      EmptyType.noTrips => LucideIcons.plane,
      EmptyType.noOffers => LucideIcons.tag,
      EmptyType.noDocuments => LucideIcons.files,
      EmptyType.emptyJournal => LucideIcons.camera,
      EmptyType.notFound => LucideIcons.searchX,
      EmptyType.notImplemented => LucideIcons.construction,
    };
  }
  
  String? get actionButtonLabel {
    return switch (this) {
      EmptyType.noLeads => 'Novo Lead',
      EmptyType.noTrips => 'Explorar Ofertas',
      EmptyType.emptySearch => 'Limpar Filtros',
      EmptyType.emptyJournal => 'Adicionar Memória',
      _ => null,
    };
  }
}
