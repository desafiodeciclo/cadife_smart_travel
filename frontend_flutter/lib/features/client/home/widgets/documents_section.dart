import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentsSection extends StatelessWidget {
  const DocumentsSection({super.key, this.documents = const []});

  final List<DocumentItem> documents;

  static const _placeholder = [
    DocumentItem(name: 'Roteiro da Viagem', sizeMb: '2.4 MB'),
    DocumentItem(name: 'Orçamento Detalhado', sizeMb: '1.1 MB'),
  ];

  @override
  Widget build(BuildContext context) {
    final docs = documents.isEmpty ? _placeholder : documents;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DOCUMENTOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/client/documentos'),
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _DocumentCard(item: docs[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentItem {
  const DocumentItem({required this.name, required this.sizeMb, this.url});

  final String name;
  final String sizeMb;
  final String? url;
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.item});
  final DocumentItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'PDF • ${item.sizeMb}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
