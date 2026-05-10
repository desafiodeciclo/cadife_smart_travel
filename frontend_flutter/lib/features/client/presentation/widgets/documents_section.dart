// lib/features/client/presentation/widgets/documents_section.dart

import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart' as doc_entity;
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/cadife_document_card.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_document.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentsSection extends StatelessWidget {
  final List<ClientDocument> documents;

  const DocumentsSection({required this.documents, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = MediaQuery.of(context).size.width * 0.72;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DOCUMENTOS',
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/client/documents'),
              child: Text(
                'Ver todos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (documents.isEmpty)
          Container(
            height: 72,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              'Sem documentos anexados',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          SizedBox(
            // CadifeDocumentCard compact = ~72px content + ShadCard padding
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: documents.length > 5 ? 5 : documents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final doc = documents[index];

                final documento = doc_entity.Documento(
                  id: doc.id,
                  name: doc.displayName,
                  type: doc_entity.DocumentType.pdf,
                  size: 2 * 1024 * 1024,
                  url: doc.url,
                  category: doc.type,
                  createdAt: doc.uploadedAt,
                );

                return SizedBox(
                  width: cardWidth,
                  child: CadifeDocumentCard(
                    document: documento,
                    isCompact: true,
                    padding: EdgeInsets.zero,
                    onView: () {
                      context.push(
                        '/client/documentos/viewer',
                        extra: documento,
                      );
                    },
                    onDownload: () {
                      context.push(
                        '/client/documentos/viewer',
                        extra: documento,
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
