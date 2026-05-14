import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/providers/leads_provider.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/leads_list_response.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class LeadsNotifier extends AsyncNotifier<LeadsListResponse> {
  int _currentPage = 1;
  String? _currentStatus;
  String? _currentSearch;

  @override
  Future<LeadsListResponse> build() async {
    return _fetchLeads();
  }

  Future<LeadsListResponse> _fetchLeads() async {
    final result = await ref.read(getLeadsUseCaseProvider).call(
          page: _currentPage,
          status: _currentStatus,
          search: _currentSearch,
        );
    return result.fold(
      (failure) => throw failure,
      (response) => response,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLeads());
  }

  Future<void> nextPage() async {
    final currentResponse = state.valueOrNull;
    if (currentResponse != null && _currentPage < currentResponse.pages) {
      _currentPage++;
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetchLeads());
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetchLeads());
    }
  }

  Future<void> updateFilter({String? status, String? search}) async {
    _currentStatus = status ?? _currentStatus;
    _currentSearch = search ?? _currentSearch;
    _currentPage = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLeads());
  }

  Future<void> clearFilters() async {
    _currentStatus = null;
    _currentSearch = null;
    _currentPage = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLeads());
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
      return state.valueOrNull?.items.firstWhere(
        (l) {
          final lPhone = l.telefone.replaceAll(RegExp(r'\D'), '');
          return lPhone == cleanPhone;
        },
      );
    } on StateError catch (_) {
      return null;
    }
  }
  
  int get currentPage => _currentPage;
  String? get currentStatus => _currentStatus;
  String? get currentSearch => _currentSearch;
}

final leadsNotifierProvider = AsyncNotifierProvider<LeadsNotifier, LeadsListResponse>(
  LeadsNotifier.new,
);
