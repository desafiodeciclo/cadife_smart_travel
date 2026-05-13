import 'dart:typed_data';

import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/entities/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Dados alinhados com backend/scripts/db/seeds/01_users.py (Daniela Costa)
class MockConsultorRepository implements IConsultorRepository {
  ConsultorProfile _profile = const ConsultorProfile(
    id: 'daniela-costa',
    name: 'Daniela Costa',
    email: 'daniela.costa@cadifetoure.com.br',
    bio: 'Especialista em viagens internacionais e destinos europeus há 10 anos. '
        'Apaixonada por criar roteiros personalizados que transformam sonhos em memórias inesquecíveis.',
    phone: '+55 11 97777-7777',
    avatarUrl: null,
    totalSales: 142,
    conversionRate: 0.75,
    activeMonths: 48,
    cargo: 'Consultora Sênior de Viagens',
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
      totalLeadsAtendidos: 42,
      taxaConversao: 75.0,
      receitaGerada: 148000.0,
      leadsAtivosAgora: 2,
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
        target: 10,
        achieved: 7,
        receita: 38500,
      ),
      SaleGoal(
        month: prevMonth(1),
        year: prevYear(1),
        target: 10,
        achieved: 10,
        receita: 52000,
      ),
      SaleGoal(
        month: prevMonth(2),
        year: prevYear(2),
        target: 8,
        achieved: 6,
        receita: 29800,
      ),
    ]);
  }

  @override
  Future<Either<Failure, ConsultorProfile>> uploadPhoto(
    Uint8List bytes,
    String fileName,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    _profile = _profile.copyWith(
      avatarUrl: 'https://i.pravatar.cc/512?u=${_profile.id}',
    );
    return Right(_profile);
  }
}
