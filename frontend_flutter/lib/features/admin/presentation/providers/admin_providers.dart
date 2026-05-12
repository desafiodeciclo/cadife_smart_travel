import 'package:cadife_smart_travel/features/admin/data/repositories/mock_admin_repository.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Consultor Detail (family — carrega por ID) ──────────────────────────────

final consultorDetailProvider = AsyncNotifierProvider.family<ConsultorDetailNotifier, ConsultorAdmin?, String>(
  ConsultorDetailNotifier.new,
);

class ConsultorDetailNotifier extends FamilyAsyncNotifier<ConsultorAdmin?, String> {
  @override
  Future<ConsultorAdmin?> build(String arg) async {
    final repo = ref.watch(mockAdminRepositoryProvider);
    return repo.getConsultorById(arg);
  }

  Future<void> toggleStatus() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncValue.loading();
    final repo = ref.read(mockAdminRepositoryProvider);
    try {
      final updated = await repo.toggleConsultorStatus(current.id);
      state = AsyncValue.data(updated);
      ref.invalidate(adminConsultoresNotifierProvider);
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final mockAdminRepositoryProvider = Provider<MockAdminRepository>((ref) {
  return MockAdminRepository();
});

final adminMetricsProvider = FutureProvider<AgenciaMetrics>((ref) async {
  final repo = ref.watch(mockAdminRepositoryProvider);
  return repo.getMetrics();
});

final adminConsultoresProvider = FutureProvider<List<ConsultorAdmin>>((ref) async {
  final repo = ref.watch(mockAdminRepositoryProvider);
  return repo.getConsultores();
});

final adminConsultoresNotifierProvider = AsyncNotifierProvider<AdminConsultoresNotifier, List<ConsultorAdmin>>(AdminConsultoresNotifier.new);

class AdminConsultoresNotifier extends AsyncNotifier<List<ConsultorAdmin>> {
  @override
  Future<List<ConsultorAdmin>> build() async {
    final repo = ref.watch(mockAdminRepositoryProvider);
    return repo.getConsultores();
  }

  Future<void> toggleStatus(String id) async {
    state = const AsyncValue.loading();
    final repo = ref.read(mockAdminRepositoryProvider);
    try {
      await repo.toggleConsultorStatus(id);
      state = AsyncValue.data(await repo.getConsultores());
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createConsultor({
    required String name,
    required String email,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(mockAdminRepositoryProvider);
    try {
      await repo.createConsultor(name: name, email: email, phone: phone);
      state = AsyncValue.data(await repo.getConsultores());
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateConsultor(ConsultorAdmin consultor) async {
    state = const AsyncValue.loading();
    final repo = ref.read(mockAdminRepositoryProvider);
    try {
      await repo.updateConsultor(consultor);
      state = AsyncValue.data(await repo.getConsultores());
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteConsultor(String id) async {
    state = const AsyncValue.loading();
    final repo = ref.read(mockAdminRepositoryProvider);
    try {
      await repo.deleteConsultor(id);
      state = AsyncValue.data(await repo.getConsultores());
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final repo = ref.read(mockAdminRepositoryProvider);
    try {
      state = AsyncValue.data(await repo.getConsultores());
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
