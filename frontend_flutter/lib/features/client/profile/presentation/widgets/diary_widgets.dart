import 'package:cached_network_image/cached_network_image.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/profile/data/mocks/client_profile_mocks.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/entities/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiariesTab extends StatelessWidget {
  const DiariesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = ClientProfileMocks.diaryEntries();
    final tripNames = ClientProfileMocks.tripNames();

    // Group entries by tripId
    final grouped = <String, List<DiaryEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.tripId, () => []).add(e);
    }
    // Sort entries within each trip chronologically
    for (final list in grouped.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
    }

    if (grouped.isEmpty) {
      return const _EmptyDiariesState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final tripId = grouped.keys.toList()[index];
        final tripEntries = grouped[tripId]!;
        final tripName = tripNames[tripId] ?? tripId;
        return TravelJournalCard(
          tripId: tripId,
          tripName: tripName,
          entries: tripEntries,
        );
      },
    );
  }
}

class TravelJournalCard extends StatelessWidget {
  const TravelJournalCard({
    required this.tripId,
    required this.tripName,
    required this.entries,
    super.key,
  });

  final String tripId;
  final String tripName;
  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final cover = entries.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => context.push('/client/profile/diary/$tripId'),
        child: ShadCard(
          padding: const EdgeInsets.all(12),
          backgroundColor:
              isDark ? cadife.cardBackground : Colors.white,
          radius: BorderRadius.circular(20),
          border: ShadBorder.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : cadife.cardBorder,
            width: 1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: cover.photoUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  placeholder: (_, _) => Container(
                    width: 90,
                    height: 90,
                    color: cadife.muted,
                    child: const Center(
                        child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: 90,
                    height: 90,
                    color: cadife.muted,
                    child: Icon(LucideIcons.imageOff,
                        color: cadife.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tripName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cadife.textPrimary,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                            size: 14, color: cadife.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tripName.replaceAll(RegExp(r'[^\w\s,]'), '').trim(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cadife.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.calendar,
                            size: 14, color: cadife.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_shortDate(entries.first.date)} - ${_shortDate(entries.last.date)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cadife.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.users,
                            size: 14, color: cadife.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '2 pessoas',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cadife.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight,
                  size: 20, color: cadife.textSecondary),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

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
