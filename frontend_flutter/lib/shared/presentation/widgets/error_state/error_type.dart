import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ErrorType {
  networkError,        // Sem conexão / timeout
  serverError,         // 5xx do servidor
  unauthorized,        // 401 — Sessão expirada
  forbidden,           // 403 — Permissão negada
  notFound,            // 404 — Recurso não encontrado
  validationError,     // 400 — Dados inválidos
  genericError,        // Erro desconhecido
  rateLimited,         // 429 — Muitas requisições
}

extension ErrorTypeConfig on ErrorType {
  String get title {
    return switch (this) {
      ErrorType.networkError => 'Sem conexão',
      ErrorType.serverError => 'Algo deu errado',
      ErrorType.unauthorized => 'Sessão expirada',
      ErrorType.forbidden => 'Acesso negado',
      ErrorType.notFound => 'Não encontrado',
      ErrorType.validationError => 'Dados inválidos',
      ErrorType.genericError => 'Erro desconhecido',
      ErrorType.rateLimited => 'Muitas requisições',
    };
  }
  
  String get subtitle {
    return switch (this) {
      ErrorType.networkError =>
        'Verifique sua conexão e tente novamente',
      ErrorType.serverError =>
        'Nossos servidores estão fora do ar. Tente em breve.',
      ErrorType.unauthorized =>
        'Sua sessão expirou. Faça login novamente.',
      ErrorType.forbidden =>
        'Você não tem permissão para acessar esta área.',
      ErrorType.notFound =>
        'O recurso que você procura não existe.',
      ErrorType.validationError =>
        'Os dados enviados contêm erros. Verifique e tente novamente.',
      ErrorType.genericError =>
        'Um erro inesperado ocorreu. Tente novamente.',
      ErrorType.rateLimited =>
        'Você fez muitas requisições. Aguarde um momento.',
    };
  }
  
  IconData get icon {
    return switch (this) {
      ErrorType.networkError => LucideIcons.wifiOff,
      ErrorType.serverError => LucideIcons.cloudOff,
      ErrorType.unauthorized => LucideIcons.lock,
      ErrorType.forbidden => LucideIcons.shieldAlert,
      ErrorType.notFound => LucideIcons.searchX,
      ErrorType.validationError => LucideIcons.circleAlert,
      ErrorType.genericError => LucideIcons.triangleAlert,
      ErrorType.rateLimited => LucideIcons.timer,
    };
  }
  
  Color get iconColor => switch (this) {
    ErrorType.networkError => Colors.orange,
    ErrorType.serverError => Colors.red,
    ErrorType.unauthorized => Colors.amber,
    ErrorType.forbidden => Colors.red,
    ErrorType.notFound => Colors.grey,
    ErrorType.validationError => Colors.red,
    ErrorType.genericError => Colors.red,
    ErrorType.rateLimited => Colors.orange,
  };
  
  bool get isRetryable => switch (this) {
    ErrorType.networkError => true,
    ErrorType.serverError => true,
    ErrorType.unauthorized => false,
    ErrorType.forbidden => false,
    ErrorType.notFound => false,
    ErrorType.validationError => false,
    ErrorType.genericError => true,
    ErrorType.rateLimited => true,
  };
}
