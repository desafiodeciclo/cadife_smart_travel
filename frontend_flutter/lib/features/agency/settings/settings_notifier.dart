import 'package:cadife_smart_travel/features/agency/settings/domain/repositories/agency_settings_port.dart';
import 'package:cadife_smart_travel/features/agency/settings/settings_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final agencySettingsPortProvider = Provider<AgencySettingsPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final agencySettingsProvider =
    AsyncNotifierProvider<AgencySettingsNotifier, AgencySettings>(
  AgencySettingsNotifier.new,
);

class AgencySettingsNotifier extends AsyncNotifier<AgencySettings> {
  @override
  Future<AgencySettings> build() =>
      ref.watch(agencySettingsPortProvider).getSettings();

  Future<void> _save(AgencySettings updated) async {
    final previous = state.valueOrNull;
    state = AsyncData(updated);
    try {
      final saved =
          await ref.read(agencySettingsPortProvider).updateSettings(updated);
      state = AsyncData(saved);
    } catch (e, st) {
      if (previous != null) state = AsyncData(previous);
      state = AsyncError(e, st);
    }
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

