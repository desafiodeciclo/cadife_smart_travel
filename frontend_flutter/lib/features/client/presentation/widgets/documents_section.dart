import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart' as doc_entity;
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/document_card_item.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_document.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentsSection extends StatelessWidget {
  final List<ClientDocument> documents;

  const DocumentsSection({required this.documents, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = documents.length > 3 ? documents.sublist(0, 3) : documents;

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
            height: 60,
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
          Column(
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                DocumentCardItem(
                  documentName: visible[i].displayName,
                  documentType: doc_entity.DocumentType.pdf,
                  fileSize: '—',
                  onTap: () => context.push(
                    '/client/documentos/viewer',
                    extra: doc_entity.Documento(
                      id: visible[i].id,
                      name: visible[i].displayName,
                      type: doc_entity.DocumentType.pdf,
                      size: 0,
                      url: visible[i].url,
                      category: visible[i].type,
                      createdAt: visible[i].uploadedAt,
                    ),
                  ),
                ),
                if (i < visible.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}
