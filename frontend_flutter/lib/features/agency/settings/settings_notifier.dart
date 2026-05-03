import 'package:cadife_smart_travel/features/agency/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AgencySettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AgencySettings> {
  @override
  Future<AgencySettings> build() =>
      ref.read(settingsRepositoryProvider).getSettings();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(settingsRepositoryProvider).getSettings(),
    );
  }

  Future<void> updateOfficeHours(OfficeHours hours) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(officeHours: hours);
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> updateNotificationPrefs(NotificationPrefs prefs) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(notificationPrefs: prefs);
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> addTemplate(String name, String content) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final template =
        await ref.read(settingsRepositoryProvider).addTemplate(name, content);
    final updated = current.copyWith(
      messageTemplates: [...current.messageTemplates, template],
    );
    state = AsyncData(updated);
  }

  Future<void> deleteTemplate(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref.read(settingsRepositoryProvider).deleteTemplate(id);
    final updated = current.copyWith(
      messageTemplates:
          current.messageTemplates.where((t) => t.id != id).toList(),
    );
    state = AsyncData(updated);
  }

  void toggleDay(int dayIndex) {
    final current = state.valueOrNull;
    if (current == null) return;
    final days = List<bool>.from(current.officeHours.activeDays);
    days[dayIndex] = !days[dayIndex];
    final updated = current.copyWith(
      officeHours: current.officeHours.copyWith(activeDays: days),
    );
    state = AsyncData(updated);
  }

  Future<void> updateStartTime(TimeOfDay time) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(
      officeHours: current.officeHours.copyWith(startTime: time),
    );
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> updateEndTime(TimeOfDay time) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(
      officeHours: current.officeHours.copyWith(endTime: time),
    );
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> _persist(AgencySettings settings) async {
    try {
      await ref.read(settingsRepositoryProvider).saveSettings(settings);
    } catch (_) {
      // Optimistic update already applied — backend sync failure is non-blocking
    }
  }
}
