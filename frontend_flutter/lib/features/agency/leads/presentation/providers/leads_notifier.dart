import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/providers/leads_provider.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class LeadsNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() async {
    final result = await ref.watch(getLeadsUseCaseProvider).call();
    return result.fold(
      (failure) => throw failure,
      (leads) => leads,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(getLeadsUseCaseProvider).call();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> filterByStatus(LeadStatus? status) async {
    state = const AsyncLoading();
    final result = await ref.read(getLeadsUseCaseProvider).call(status: status);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> filterByScore(LeadScore? score) async {
    state = const AsyncLoading();
    final result = await ref.read(getLeadsUseCaseProvider).call(score: score);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> updateStatus(String id, LeadStatus newStatus) async {
    final result = await ref.read(updateLeadStatusUseCaseProvider).call(id, newStatus);
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) => refresh(),
    );
  }

  Future<Either<Failure, Lead>> createManualLead(ManualLeadCreate request) async {
    final result = await ref.read(createManualLeadUseCaseProvider).call(request);
    return result.fold(
      Left.new,
      (lead) {
        refresh();
        return Right(lead);
      },
    );
  }

  Future<void> reassignLead(String id, String consultorNome) async {
    final datasource = ref.read(leadsDatasourceProvider);
    try {
      await datasource.reassignLead(id, consultorNome);
      await refresh();
    } on Exception catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Lead? findByPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return null;
    
    try {
      return state.valueOrNull?.firstWhere(
        (l) {
          final lPhone = l.phone.replaceAll(RegExp(r'\D'), '');
          return lPhone == cleanPhone;
        },
      );
    } on StateError catch (_) {
      return null;
    }
  }
}

final leadsNotifierProvider = AsyncNotifierProvider<LeadsNotifier, List<Lead>>(
  LeadsNotifier.new,
);
