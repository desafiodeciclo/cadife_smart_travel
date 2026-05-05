import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/settings/domain/entities/agency_settings.dart';
import 'package:cadife_smart_travel/features/agency/settings/presentation/providers/settings_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(agencySettingsProvider);

    return Scaffold(
      backgroundColor: context.cadife.background,
      appBar: const CadifeAppBar(
        title: 'Configurações',
        showProfile: false,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Erro ao carregar configurações'),
              const SizedBox(height: 8),
              ShadButton.outline(
                onPressed: () => ref.invalidate(agencySettingsProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const _SectionHeader(title: 'Horários de Atendimento'),
            _OfficeHoursSection(hours: settings.officeHours),
            const SizedBox(height: 8),
            const _SectionHeader(title: 'Notificações'),
            _NotificationsSection(prefs: settings.notifications),
            const SizedBox(height: 8),
            const _SectionHeader(title: 'Templates de Mensagem'),
            _TemplatesSection(templates: settings.templates),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          letterSpacing: 1.2,
          color: context.cadife.textSecondary,
        ),
      ),
    );
  }
}

// ── Office Hours ──────────────────────────────────────────────────────────────

class _OfficeHoursSection extends ConsumerWidget {
  const _OfficeHoursSection({required this.hours});
  final List<OfficeHours> hours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShadCard(
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(color: context.cadife.cardBorder, width: 1),
      child: Column(
        children: hours.asMap().entries.map((e) {
          final i = e.key;
          final h = e.value;
          return Column(
            children: [
              _DayRow(hours: h),
              if (i < hours.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DayRow extends ConsumerWidget {
  const _DayRow({required this.hours});
  final OfficeHours hours;

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    bool isOpen,
  ) async {
    final parts = isOpen
        ? hours.openTime.split(':')
        : hours.closeTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await ref.read(agencySettingsProvider.notifier).updateHours(
          hours.weekday,
          isOpen ? formatted : hours.openTime,
          isOpen ? hours.closeTime : formatted,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(hours.weekdayLabel,
                style: AppTextStyles.bodyMedium),
          ),
          ShadSwitch(
            value: hours.isOpen,
            onChanged: (v) => ref
                .read(agencySettingsProvider.notifier)
                .toggleDay(hours.weekday, isOpen: v),
          ),
          if (hours.isOpen) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => _pickTime(context, ref, true),
              child: _TimeChip(time: hours.openTime),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: TextStyle(color: context.cadife.textSecondary)),
            ),
            GestureDetector(
              onTap: () => _pickTime(context, ref, false),
              child: _TimeChip(time: hours.closeTime),
            ),
          ] else ...[
            const Spacer(),
            Text('Fechado',
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.cadife.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) {
    return ShadBadge.secondary(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(time),
    );
  }
}

// ── Notifications ─────────────────────────────────────────────────────────────

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection({required this.prefs});
  final NotificationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(agencySettingsProvider.notifier);
    return ShadCard(
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(color: context.cadife.cardBorder, width: 1),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Novos leads', style: AppTextStyles.bodyMedium),
                      Text('Notificar quando um lead for criado',
                          style: AppTextStyles.bodySmall.copyWith(color: context.cadife.textSecondary)),
                    ],
                  ),
                ),
                ShadSwitch(
                  value: prefs.newLeads,
                  onChanged: (v) => notifier.toggleNotification(
                      newLeads: v, qualifiedLeads: prefs.qualifiedLeads),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Leads qualificados', style: AppTextStyles.bodyMedium),
                      Text('Notificar quando score ≥ 60%',
                          style: AppTextStyles.bodySmall.copyWith(color: context.cadife.textSecondary)),
                    ],
                  ),
                ),
                ShadSwitch(
                  value: prefs.qualifiedLeads,
                  onChanged: (v) => notifier.toggleNotification(
                      newLeads: prefs.newLeads, qualifiedLeads: v),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Templates ─────────────────────────────────────────────────────────────────

class _TemplatesSection extends ConsumerWidget {
  const _TemplatesSection({required this.templates});
  final List<MessageTemplate> templates;

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    await showShadDialog<void>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Novo Template'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ShadButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty ||
                  bodyCtrl.text.trim().isEmpty) { return; }
              ref.read(agencySettingsProvider.notifier).addTemplate(
                    titleCtrl.text.trim(),
                    bodyCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Adicionar'),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInput(
              controller: titleCtrl,
              placeholder: const Text('Título'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: bodyCtrl,
              placeholder: const Text('Mensagem'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    bodyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...templates.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShadCard(
                padding: EdgeInsets.zero,
                radius: BorderRadius.circular(12),
                border: ShadBorder.all(color: context.cadife.cardBorder, width: 1),
                child: ListTile(
                  title: Text(t.title, style: AppTextStyles.labelLarge),
                  subtitle: Text(
                    t.body,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.cadife.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    onPressed: () => ref
                        .read(agencySettingsProvider.notifier)
                        .removeTemplate(t.id),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ShadButton.outline(
            onPressed: () => _showAddDialog(context, ref),
            leading: const Icon(Icons.add, size: 18),
            child: const Text('Adicionar template'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
