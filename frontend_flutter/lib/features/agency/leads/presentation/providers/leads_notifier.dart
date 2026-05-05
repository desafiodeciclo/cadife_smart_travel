import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

final leadsNotifierProvider = AsyncNotifierProvider<LeadsNotifier, List<Lead>>(
  LeadsNotifier.new,
);

final selectedLeadIdProvider = StateProvider<String?>((ref) => null);
