import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro no servidor. Tente novamente mais tarde.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sessão expirada ou acesso negado.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao acessar dados locais.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class GenericFailure extends Failure {
  const GenericFailure([super.message = 'Ocorreu um erro inesperado.']);
}
