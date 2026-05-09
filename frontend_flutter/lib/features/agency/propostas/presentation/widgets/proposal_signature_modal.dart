import 'dart:convert';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

class ProposalSignatureModal extends StatefulWidget {
  const ProposalSignatureModal({
    required this.nomeConsultor,
    this.existing,
    super.key,
  });

  final String nomeConsultor;
  final AssinaturaDigital? existing;

  static Future<AssinaturaDigital?> show(
    BuildContext context, {
    required String nomeConsultor,
    AssinaturaDigital? existing,
  }) {
    return showModalBottomSheet<AssinaturaDigital>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProposalSignatureModal(
        nomeConsultor: nomeConsultor,
        existing: existing,
      ),
    );
  }

  @override
  State<ProposalSignatureModal> createState() => _ProposalSignatureModalState();
}

class _ProposalSignatureModalState extends State<ProposalSignatureModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _textController = TextEditingController();
  final List<Offset?> _strokes = [];
  bool _canvasHasContent = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    if (widget.existing?.textoAssinatura != null) {
      _textController.text = widget.existing!.textoAssinatura!;
    } else {
      _textController.text = widget.nomeConsultor;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _clearCanvas() => setState(() {
        _strokes.clear();
        _canvasHasContent = false;
      });

  AssinaturaDigital _buildSignature(String texto) {
    final timestamp = DateTime.now();
    final payload = '${widget.nomeConsultor}|$texto|${timestamp.toIso8601String()}';
    final hash = sha256.convert(utf8.encode(payload)).toString();
    return AssinaturaDigital(
      nomeConsultor: widget.nomeConsultor,
      timestamp: timestamp,
      hash: hash,
      textoAssinatura: texto,
    );
  }

  void _confirm() {
    final isCanvas = _tabs.index == 0;
    if (isCanvas) {
      if (!_canvasHasContent) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text('Desenhe sua assinatura antes de confirmar.'),
          ),
        );
        return;
      }
      Navigator.of(context).pop(
        _buildSignature('${widget.nomeConsultor} (manuscrita)'),
      );
    } else {
      final text = _textController.text.trim();
      if (text.isEmpty) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text('Digite sua assinatura antes de confirmar.'),
          ),
        );
        return;
      }
      Navigator.of(context).pop(_buildSignature(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
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
            const SizedBox(height: 16),
            Text(
              'Assinatura Digital',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.nomeConsultor,
              style: TextStyle(
                fontSize: 13,
                color: context.cadife.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Tabs: Desenho | Texto
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: context.cadife.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Desenho'),
                Tab(text: 'Texto'),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 180,
              child: TabBarView(
                controller: _tabs,
                children: [
                  // ── Canvas ──
                  _CanvasTab(
                    strokes: _strokes,
                    isDark: isDark,
                    onStrokeAdded: (offset) => setState(() {
                      _strokes.add(offset);
                      if (offset != null) _canvasHasContent = true;
                    }),
                    onClear: _clearCanvas,
                  ),

                  // ── Texto ──
                  _TextTab(controller: _textController),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info row
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: context.cadife.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.cadife.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CadifeButton(
                    text: 'Cancelar',
                    variant: ButtonVariant.secondary,
                    isOutline: true,
                    analyticsLabel: 'signature_cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CadifeButton(
                    text: 'Confirmar',
                    icon: Icons.check_rounded,
                    analyticsLabel: 'signature_confirm',
                    onPressed: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Canvas drawing tab ──────────────────────────────────────────────────────

class _CanvasTab extends StatelessWidget {
  const _CanvasTab({
    required this.strokes,
    required this.isDark,
    required this.onStrokeAdded,
    required this.onClear,
  });

  final List<Offset?> strokes;
  final bool isDark;
  final void Function(Offset?) onStrokeAdded;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.globalPosition);
                onStrokeAdded(local);
              },
              onPanEnd: (_) => onStrokeAdded(null),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: _SignaturePainter(
                    strokes: strokes,
                    color: isDark ? Colors.white : AppColors.zinc900,
                  ),
                  child: strokes.isEmpty
                      ? Center(
                          child: Text(
                            'Desenhe aqui',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton.ghost(
            onPressed: onClear,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 16),
                SizedBox(width: 4),
                Text('Limpar'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, required this.color});

  final List<Offset?> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < strokes.length - 1; i++) {
      if (strokes[i] != null && strokes[i + 1] != null) {
        canvas.drawLine(strokes[i]!, strokes[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.strokes != strokes;
}

// ── Text signature tab ──────────────────────────────────────────────────────

class _TextTab extends StatelessWidget {
  const _TextTab({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digite seu nome como assinatura:',
            style: TextStyle(
              fontSize: 13,
              color: context.cadife.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ShadInput(
            controller: controller,
            placeholder: const Text('Seu nome completo'),
            style: const TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O nome digitado será registrado como assinatura eletrônica.',
            style: TextStyle(fontSize: 11, color: context.cadife.textSecondary),
          ),
        ],
      ),
    );
  }
}
