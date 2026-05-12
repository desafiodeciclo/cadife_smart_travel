import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/domain/entities/travel_diary.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/travel_diary_widget.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/providers/diary_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiariesTab extends ConsumerWidget {
  const DiariesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diariesAsync = ref.watch(diaryProvider);

    return diariesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro ao carregar diários: $err')),
      data: (diaries) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: ShadButton.outline(
              width: double.infinity,
              leading: const Icon(LucideIcons.plus, size: 18),
              onPressed: () => _showCreateDiaryDialog(context, ref),
              child: const Text('Criar novo diário'),
            ),
          ),
          if (diaries.isEmpty)
            const Expanded(child: _EmptyDiariesState())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: diaries.length,
                itemBuilder: (ctx, idx) => DiaryCard(diary: diaries[idx]),
              ),
            ),
        ],
      ),
    );
  }

  void _showCreateDiaryDialog(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.read(travelHistoryProvider);

    showShadDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Selecione a viagem'),
        description: const Text('Para qual viagem deseja criar um novo diário?'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
        child: historyAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Erro ao carregar viagens: $e'),
          ),
          data: (travels) => travels.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Nenhuma viagem encontrada.'),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: travels
                      .map(
                        (t) => ListTile(
                          title: Text(t.name),
                          subtitle: Text(t.destino ?? ''),
                          leading: const Icon(LucideIcons.plane),
                          onTap: () {
                            ref
                                .read(diaryProvider.notifier)
                                .createDiary(t.id, t.name);
                            Navigator.pop(ctx);
                            if (context.mounted) {
                              ShadToaster.of(context).show(
                                ShadToast(
                                  description:
                                      Text('Diário criado para ${t.name}'),
                                ),
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }
}

// ─── DiaryCard ────────────────────────────────────────────────────────────────

class DiaryCard extends ConsumerWidget {
  final TravelDiary diary;

  const DiaryCard({required this.diary, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: isDark ? cadife.cardBackground : Colors.white,
        radius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDiaryDetail(context, ref),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.bookOpen, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diary.travelTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cadife.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      diary.entries.isEmpty
                          ? 'Sem memórias ainda'
                          : '${diary.entries.length} memória${diary.entries.length == 1 ? '' : 's'} registrada${diary.entries.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cadife.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 20, color: cadife.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiaryDetail(BuildContext context, WidgetRef ref) {
    showShadDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(diary.travelTitle),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: TravelDiaryWidget(
            diary: diary,
            onAddEntry: () {
              Navigator.pop(ctx);
              _showAddEntryDialog(context, ref);
            },
            onEditEntry: (index, entry) {
              Navigator.pop(ctx);
              _showEditEntryDialog(context, ref, index, entry);
            },
          ),
        ),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    DiaryMood selectedMood = DiaryMood.happy;

    showShadDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ShadDialog(
          title: const Text('Nova entrada'),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ShadButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final content = contentCtrl.text.trim();
                if (title.isEmpty || content.isEmpty) return;
                ref.read(diaryProvider.notifier).addEntry(
                      diary.id,
                      DiaryEntry(
                        date: DateTime.now(),
                        mood: selectedMood,
                        title: title,
                        content: content,
                      ),
                    );
                Navigator.pop(ctx);
                if (context.mounted) {
                  ShadToaster.of(context).show(
                    const ShadToast(description: Text('Entrada adicionada!')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
          child: _EntryForm(
            titleCtrl: titleCtrl,
            contentCtrl: contentCtrl,
            selectedMood: selectedMood,
            onMoodChanged: (m) => setDialogState(() => selectedMood = m),
          ),
        ),
      ),
    );
  }

  void _showEditEntryDialog(
    BuildContext context,
    WidgetRef ref,
    int index,
    DiaryEntry entry,
  ) {
    final titleCtrl = TextEditingController(text: entry.title);
    final contentCtrl = TextEditingController(text: entry.content);
    DiaryMood selectedMood = entry.mood;

    showShadDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ShadDialog(
          title: const Text('Editar entrada'),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ShadButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final content = contentCtrl.text.trim();
                if (title.isEmpty || content.isEmpty) return;
                ref.read(diaryProvider.notifier).updateEntry(
                      diary.id,
                      index,
                      DiaryEntry(
                        date: entry.date,
                        mood: selectedMood,
                        title: title,
                        content: content,
                        photos: entry.photos,
                      ),
                    );
                Navigator.pop(ctx);
                if (context.mounted) {
                  ShadToaster.of(context).show(
                    const ShadToast(description: Text('Entrada atualizada!')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
          child: _EntryForm(
            titleCtrl: titleCtrl,
            contentCtrl: contentCtrl,
            selectedMood: selectedMood,
            onMoodChanged: (m) => setDialogState(() => selectedMood = m),
          ),
        ),
      ),
    );
  }
}

// ─── Formulário reutilizável de entrada ───────────────────────────────────────

class _EntryForm extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final DiaryMood selectedMood;
  final ValueChanged<DiaryMood> onMoodChanged;

  const _EntryForm({
    required this.titleCtrl,
    required this.contentCtrl,
    required this.selectedMood,
    required this.onMoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShadInput(
          controller: titleCtrl,
          placeholder: const Text('Título da entrada'),
          autofocus: true,
        ),
        const SizedBox(height: 10),
        ShadInput(
          controller: contentCtrl,
          placeholder: const Text('Como foi este dia?'),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        Text(
          'Humor',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cadife.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: DiaryMood.values.map((mood) {
            final selected = mood == selectedMood;
            return GestureDetector(
              onTap: () => onMoodChanged(mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : cadife.muted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : cadife.cardBorder,
                  ),
                ),
                child: Text(
                  '${mood.emoji} ${mood.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? AppColors.primary : cadife.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────

class _EmptyDiariesState extends StatelessWidget {
  const _EmptyDiariesState();

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: 64,
              color: cadife.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum diário ainda',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas memórias de viagem aparecerão aqui',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cadife.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
