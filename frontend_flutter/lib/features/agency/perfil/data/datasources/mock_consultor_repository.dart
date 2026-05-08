import 'dart:typed_data';

import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/entities/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
import 'package:fpdart/fpdart.dart';

class MockConsultorRepository implements IConsultorRepository {
  ConsultorProfile _profile = const ConsultorProfile(
    id: 'consultor-001',
    name: 'Jakeline Ferreira',
    email: 'jakeline@cadifetravel.com.br',
    bio: 'Especialista em viagens internacionais e cruzeiros há 8 anos. '
        'Apaixonada por criar experiências únicas para cada cliente.',
    phone: '+55 11 99876-5432',
    avatarUrl: null,
    totalSales: 142,
    conversionRate: 0.68,
    activeMonths: 38,
    cargo: 'Consultora de Viagens',
    agencia: 'Cadife Tour — São Paulo',
  );

  @override
  Future<Either<Failure, ConsultorProfile>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_profile);
  }

  @override
  Future<Either<Failure, ConsultorProfile>> updateBio(String bio) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _profile = _profile.copyWith(bio: bio);
    return Right(_profile);
  }

  @override
  Future<Either<Failure, ConsultantMetrics>> getMetrics() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Right(ConsultantMetrics(
      totalLeadsAtendidos: 45,
      taxaConversao: 24.5,
      receitaGerada: 125000.0,
      leadsAtivosAgora: 8,
      ultimaAtualizacao: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, List<SaleGoal>>> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();

    int prevMonth(int offset) {
      final m = now.month - offset;
      return m <= 0 ? m + 12 : m;
    }

    int prevYear(int offset) {
      final m = now.month - offset;
      return m <= 0 ? now.year - 1 : now.year;
    }

    return Right([
      SaleGoal(
        month: now.month,
        year: now.year,
        target: 12,
        achieved: 8,
        receita: 42000,
      ),
      SaleGoal(
        month: prevMonth(1),
        year: prevYear(1),
        target: 10,
        achieved: 10,
        receita: 58000,
      ),
      SaleGoal(
        month: prevMonth(2),
        year: prevYear(2),
        target: 10,
        achieved: 7,
        receita: 31500,
      ),
    ]);
  }

  @override
  Future<Either<Failure, ConsultorProfile>> uploadPhoto(
    Uint8List bytes,
    String fileName,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock: return with a placeholder remote URL
    _profile = _profile.copyWith(
      avatarUrl: 'https://i.pravatar.cc/512?u=${_profile.id}',
    );
    return Right(_profile);
  }
}
