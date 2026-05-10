import 'package:cadife_smart_travel/design_system/design_system.dart';
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
    final cadife = context.cadife;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DOCUMENTOS',
              style: TextStyle(
                color: cadife.textPrimary,
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
                  color: cadife.primary,
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
              color: cadife.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cadife.cardBorder),
            ),
            child: Text(
              'Sem documentos anexados',
              style: TextStyle(
                color: cadife.textSecondary.withValues(alpha: 0.5),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          SizedBox(
            height: 130, // Increased height for the new premium card
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: CadifeDocumentCard(
                    document: doc_entity.Documento(
                      id: doc.id,
                      name: doc.displayName,
                      type: doc_entity.DocumentType.pdf,
                      size: 0,
                      url: doc.url,
                      category: doc.type,
                      createdAt: doc.uploadedAt,
                    ),
                    onView: () => context.push(
                      '/client/documentos/viewer',
                      extra: doc_entity.Documento(
                        id: doc.id,
                        name: doc.displayName,
                        type: doc_entity.DocumentType.pdf,
                        size: 0,
                        url: doc.url,
                        category: doc.type,
                        createdAt: doc.uploadedAt,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
