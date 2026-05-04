import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Erro no servidor. Tente novamente mais tarde.'])
      : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Sem conexão com a internet.'])
      : super(message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Sessão expirada ou acesso negado.'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Erro ao acessar dados locais.'])
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class GenericFailure extends Failure {
  const GenericFailure([String message = 'Ocorreu um erro inesperado.'])
      : super(message);
}
