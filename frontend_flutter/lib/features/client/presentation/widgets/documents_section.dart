// lib/features/client/presentation/widgets/documents_section.dart

import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart' as doc_entity;
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/cadife_document_card.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_document.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentsSection extends StatefulWidget {
  final List<ClientDocument> documents;

  const DocumentsSection({required this.documents, super.key});

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        const SizedBox(height: 16),
        SizedBox(
          height: 80, // Height for the compact card
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none, // Allow cards to bleed out if needed
            itemCount: widget.documents.length > 5 ? 5 : widget.documents.length, // Limit for home screen
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final doc = widget.documents[index];
              
              // Map ClientDocument to doc_entity.Documento
              final documento = doc_entity.Documento(
                id: doc.id,
                name: doc.displayName,
                type: doc_entity.DocumentType.pdf,
                size: 2 * 1024 * 1024, // Mock size 2MB
                url: doc.url,
                category: doc.type,
                createdAt: doc.uploadedAt,
              );

              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: CadifeDocumentCard(
                  document: documento,
                  isCompact: true,
                  padding: EdgeInsets.zero, // Remove default bottom padding
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
