import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/domain/entities/travel_diary.dart';
import 'package:flutter/material.dart';

class TravelDiaryWidget extends StatelessWidget {
  final TravelDiary diary;
  final void Function(int index, DiaryEntry entry)? onEditEntry;
  final VoidCallback? onAddEntry;

  const TravelDiaryWidget({
    required this.diary,
    super.key,
    this.onEditEntry,
    this.onAddEntry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...diary.entries.asMap().entries.map(
                (e) => _DiaryEntryTile(
                  entry: e.value,
                  onEdit: onEditEntry != null
                      ? () => onEditEntry!(e.key, e.value)
                      : null,
                ),
              ),
          if (onAddEntry != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ShadButton.outline(
                width: double.infinity,
                leading: const Icon(LucideIcons.plus, size: 16),
                onPressed: onAddEntry,
                child: const Text('Nova entrada'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _DiaryEntryTile extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback? onEdit;

  const _DiaryEntryTile({required this.entry, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: data + mood + botão editar
          Row(
            children: [
              Text(
                DateFormat('d MMM yyyy').format(entry.date),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cadife.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(entry.mood.emoji, style: const TextStyle(fontSize: 18)),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  icon: Icon(LucideIcons.pencil, size: 15, color: cadife.textSecondary),
                  onPressed: onEdit,
                  tooltip: 'Editar entrada',
                  constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Título
          Text(
            entry.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cadife.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Conteúdo
          Text(
            entry.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cadife.textSecondary,
              height: 1.5,
            ),
          ),

          // Fotos
          if (entry.photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: entry.photos.length,
              itemBuilder: (ctx, idx) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  entry.photos[idx],
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          color: cadife.muted,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                  errorBuilder: (_, __, st) => Container(
                    color: cadife.muted,
                    child: Icon(LucideIcons.image, color: cadife.textSecondary, size: 20),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: cadife.cardBorder),
        ],
      ),
    );
  }
}
