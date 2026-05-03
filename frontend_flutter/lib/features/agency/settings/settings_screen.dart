import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/features/agency/settings/settings_notifier.dart';
import 'package:cadife_smart_travel/features/agency/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações da Agência'),
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Erro ao carregar configurações.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(settingsProvider.notifier).refresh(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _OfficeHoursSection(settings: settings),
            const SizedBox(height: 8),
            _NotificationSection(prefs: settings.notificationPrefs),
            const SizedBox(height: 8),
            _MessageTemplatesSection(templates: settings.messageTemplates),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Office Hours ─────────────────────────────────────────────────────────────

class _OfficeHoursSection extends ConsumerWidget {
  const _OfficeHoursSection({required this.settings});
  final AgencySettings settings;

  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = settings.officeHours;

    return _SectionCard(
      title: 'Horários de Atendimento',
      icon: Icons.access_time_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dias da semana',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(_dayLabels.length, (i) {
              final active = hours.activeDays[i];
              return FilterChip(
                label: Text(_dayLabels[i]),
                selected: active,
                onSelected: (_) =>
                    ref.read(settingsProvider.notifier).toggleDay(i),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimePicker(
                  label: 'Início',
                  time: hours.startTime,
                  onChanged: (t) =>
                      ref.read(settingsProvider.notifier).updateStartTime(t),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePicker(
                  label: 'Fim',
                  time: hours.endTime,
                  onChanged: (t) =>
                      ref.read(settingsProvider.notifier).updateEndTime(t),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Preferences ─────────────────────────────────────────────────

class _NotificationSection extends ConsumerWidget {
  const _NotificationSection({required this.prefs});
  final NotificationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: 'Notificações de Leads',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          _NotifTile(
            title: 'Leads qualificados',
            subtitle: 'Notifique quando um lead atingir score ≥ 60%',
            value: prefs.leadsQualificados,
            onChanged: (v) {
              ref.read(settingsProvider.notifier).updateNotificationPrefs(
                    prefs.copyWith(leadsQualificados: v),
                  );
            },
          ),
          const Divider(height: 1),
          _NotifTile(
            title: 'Novos leads',
            subtitle: 'Notifique imediatamente ao criar um novo lead',
            value: prefs.novosLeads,
            onChanged: (v) {
              ref.read(settingsProvider.notifier).updateNotificationPrefs(
                    prefs.copyWith(novosLeads: v),
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    );
  }
}

// ── Message Templates ─────────────────────────────────────────────────────────

class _MessageTemplatesSection extends ConsumerWidget {
  const _MessageTemplatesSection({required this.templates});
  final List<MessageTemplate> templates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: 'Templates de Mensagem',
      icon: Icons.chat_bubble_outline,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        tooltip: 'Novo template',
        onPressed: () => _showAddDialog(context, ref),
      ),
      child: templates.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nenhum template cadastrado. Toque em + para adicionar.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : Column(
              children: templates
                  .map((t) => _TemplateTile(template: t))
                  .toList(),
            ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do template',
                hintText: 'Ex: Boas-vindas',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Conteúdo',
                hintText: 'Olá {nome}! Bem-vindo à Cadife Tour...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final content = contentCtrl.text.trim();
              if (name.isEmpty || content.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(settingsProvider.notifier)
                    .addTemplate(name, content);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao salvar template.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.template});
  final MessageTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            template.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            template.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textSecondary, size: 20),
            tooltip: 'Remover template',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover template'),
        content:
            Text('Deseja remover o template "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(settingsProvider.notifier)
                    .deleteTemplate(template.id);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao remover template.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

// ── Shared card wrapper ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (trailing != null) ...[
                    const Spacer(),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
