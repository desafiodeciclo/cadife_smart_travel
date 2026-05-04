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
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: false,
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
              TextButton(
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
          color: AppColors.textSecondary,
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
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
          Switch(
            value: hours.isOpen,
            activeThumbColor: AppColors.primary,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: TextStyle(color: AppColors.textSecondary)),
            ),
            GestureDetector(
              onTap: () => _pickTime(context, ref, false),
              child: _TimeChip(time: hours.closeTime),
            ),
          ] else ...[
            const Spacer(),
            Text('Fechado',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(time, style: AppTextStyles.bodySmall),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Novos leads', style: AppTextStyles.bodyMedium),
            subtitle: Text('Notificar quando um lead for criado',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            value: prefs.newLeads,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => notifier.toggleNotification(
                newLeads: v, qualifiedLeads: prefs.qualifiedLeads),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: Text('Leads qualificados', style: AppTextStyles.bodyMedium),
            subtitle: Text('Notificar quando score ≥ 60%',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            value: prefs.qualifiedLeads,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => notifier.toggleNotification(
                newLeads: prefs.newLeads, qualifiedLeads: v),
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
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Mensagem'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
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
            (t) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                title: Text(t.title, style: AppTextStyles.labelLarge),
                subtitle: Text(
                  t.body,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
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
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar template'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
