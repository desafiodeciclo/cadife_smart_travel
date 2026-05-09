import 'dart:typed_data';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ProposalPdfPreviewModal extends StatelessWidget {
  const ProposalPdfPreviewModal({
    required this.pdfBytes,
    required this.titulo,
    this.onSend,
    super.key,
  });

  final Uint8List pdfBytes;
  final String titulo;
  final VoidCallback? onSend;

  static Future<void> show(
    BuildContext context, {
    required Uint8List pdfBytes,
    required String titulo,
    VoidCallback? onSend,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProposalPdfPreviewModal(
        pdfBytes: pdfBytes,
        titulo: titulo,
        onSend: onSend,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                // drag handle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: context.cadife.cardBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Visualizar Proposta',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.cadife.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // ── PDF Viewer ──
          Expanded(
            child: PdfViewer.data(
              pdfBytes,
              sourceName: '$titulo.pdf',
              params: const PdfViewerParams(
                backgroundColor: Color(0xFFF4F4F5),
                margin: 8,
              ),
            ),
          ),

          // ── Bottom actions ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: CadifeButton(
                      text: 'Baixar PDF',
                      icon: Icons.download_rounded,
                      variant: ButtonVariant.secondary,
                      isOutline: true,
                      analyticsLabel: 'proposal_pdf_download',
                      onPressed: () {
                        // Download handled by OS share sheet
                        ShadToaster.of(context).show(
                          const ShadToast(
                            description: Text('Funcionalidade de download em breve.'),
                          ),
                        );
                      },
                    ),
                  ),
                  if (onSend != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: CadifeButton(
                        text: 'Enviar ao Lead',
                        icon: Icons.send_rounded,
                        analyticsLabel: 'proposal_pdf_send',
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSend!();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
