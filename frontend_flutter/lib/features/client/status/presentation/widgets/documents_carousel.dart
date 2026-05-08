import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/home_page_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentsCarousel extends StatefulWidget {
  const DocumentsCarousel({
    required this.documents,
    required this.tripId,
    super.key,
  });

  final List<HomeDocument> documents;
  final String tripId;

  @override
  State<DocumentsCarousel> createState() => _DocumentsCarouselState();
}

class _DocumentsCarouselState extends State<DocumentsCarousel> {
  late final PageController _ctrl;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.52);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Documentos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cadife.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/client/documents'),
              child: Text(
                'Ver todos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cadife.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _ctrl,
            padEnds: false,
            onPageChanged: (p) => setState(() => _page = p),
            itemCount: widget.documents.length,
            itemBuilder: (context, i) {
              final isLast = i == widget.documents.length - 1;
              return Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 12),
                child: _DocCard(
                  doc: widget.documents[i],
                  tripId: widget.tripId,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.documents.length, (i) {
            final active = _page == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? cadife.primary : cadife.cardBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({required this.doc, required this.tripId});

  final HomeDocument doc;
  final String tripId;

  IconData get _icon => switch (doc.type) {
        'passport' => Icons.badge_outlined,
        'proposal' => Icons.article_outlined,
        'insurance' => Icons.health_and_safety_outlined,
        'itinerary' => Icons.route_outlined,
        _ => Icons.attach_file_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return GestureDetector(
      onTap: () => context.push('/client/documents/$tripId'),
      child: CadifeGlassCard(
        blur: 20,
        opacity: 0.07,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cadife.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, size: 20, color: cadife.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: cadife.muted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PDF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cadife.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              doc.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (doc.expiresAt != null)
              Text(
                'Expira: ${doc.expiresAt}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.warning,
                ),
              ),
            Text(
              'Enviado: ${doc.formattedUploadDate}',
              style: TextStyle(fontSize: 11, color: cadife.textSecondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.push('/client/documents/$tripId'),
                style: TextButton.styleFrom(
                  foregroundColor: cadife.primary,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: const Size(0, 28),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
