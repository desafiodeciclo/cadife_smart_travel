import 'package:cadife_smart_travel/features/agency/settings/domain/entities/agency_settings.dart';
import 'package:cadife_smart_travel/features/agency/settings/domain/repositories/i_agency_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final iAgencySettingsRepositoryProvider = Provider<IAgencySettingsRepository>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final agencySettingsProvider =
    AsyncNotifierProvider<AgencySettingsNotifier, AgencySettings>(
  AgencySettingsNotifier.new,
);

class AgencySettingsNotifier extends AsyncNotifier<AgencySettings> {
  @override
  Future<AgencySettings> build() async {
    final result = await ref.watch(iAgencySettingsRepositoryProvider).getSettings();
    return result.fold<AgencySettings>(
      (failure) => throw failure, // ignore: only_throw_errors
      (settings) => settings,
    );
  }

  Future<void> _save(AgencySettings updated) async {
    final previous = state.valueOrNull;
    state = AsyncData(updated);
    
    final result = await ref.read(iAgencySettingsRepositoryProvider).updateSettings(updated);
    state = result.fold(
      (failure) {
        if (previous != null) {
          // Emitting AsyncData(previous) then AsyncError(failure) might be weird, 
          // usually we just emit the error or revert.
          return AsyncError(failure, StackTrace.current);
        }
        return AsyncError(failure, StackTrace.current);
      },
      AsyncData.new,
    );
  }

  Future<void> toggleDay(int weekday, {required bool isOpen}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final hours = current.officeHours
        .map((h) => h.weekday == weekday ? h.copyWith(isOpen: isOpen) : h)
        .toList();
    await _save(current.copyWith(officeHours: hours));
  }

  Future<void> updateHours(
      int weekday, String openTime, String closeTime) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final hours = current.officeHours
        .map((h) => h.weekday == weekday
            ? h.copyWith(openTime: openTime, closeTime: closeTime)
            : h)
        .toList();
    await _save(current.copyWith(officeHours: hours));
  }

  Future<void> toggleNotification(
      {required bool newLeads, required bool qualifiedLeads}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(
      notifications: NotificationPrefs(
          newLeads: newLeads, qualifiedLeads: qualifiedLeads),
    ));
  }

  Future<void> addTemplate(String title, String body) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final id = 'tpl-${DateTime.now().millisecondsSinceEpoch}';
    final templates = [
      ...current.templates,
      MessageTemplate(id: id, title: title, body: body),
    ];
    await _save(current.copyWith(templates: templates));
  }

  Future<void> removeTemplate(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final templates =
        current.templates.where((t) => t.id != id).toList();
    await _save(current.copyWith(templates: templates));
  }
}


