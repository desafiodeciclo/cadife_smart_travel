import 'dart:async';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/providers/proposal_form_provider.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/widgets/proposal_pdf_preview_modal.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/widgets/proposal_signature_modal.dart';
import 'package:cadife_smart_travel/features/agency/propostas/utils/proposal_pdf_generator.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ProposalFormTab extends ConsumerStatefulWidget {
  const ProposalFormTab({required this.lead, super.key});

  final Lead lead;

  @override
  ConsumerState<ProposalFormTab> createState() => _ProposalFormTabState();
}

class _ProposalFormTabState extends ConsumerState<ProposalFormTab> {
  final _tituloCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _condicoesPagamentoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final _currencyFormatter = MaskTextInputFormatter(
    mask: '###.###.###,##',
    filter: {'#': RegExp(r'\d')},
    type: MaskAutoCompletionType.eager,
  );

  List<ServicoIncluso> _servicos = [];
  DateTime? _validadeProposta;
  AssinaturaDigital? _assinatura;
  Uint8List? _pdfBytesCache;

  Timer? _debounceTimer;
  bool _isDirty = false;
  bool _isGeneratingPdf = false;
  int _retryCount = 0;

  final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _tituloCtrl.text =
        'Proposta ${widget.lead.destino ?? ''} — ${widget.lead.name}'.trim();
    _tituloCtrl.addListener(_onChanged);
    _valorCtrl.addListener(_onChanged);
    _condicoesPagamentoCtrl.addListener(_onChanged);
    _observacoesCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _valorCtrl.dispose();
    _condicoesPagamentoCtrl.dispose();
    _observacoesCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
    _pdfBytesCache = null; // invalidate cache on any change
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(const Duration(seconds: 5), () => _autoSave(retryable: true));
  }

  Future<void> _autoSave({bool retryable = false}) async {
    final errors = _validate(requireSignature: false);
    if (errors.isNotEmpty) return;

    final notifier =
        ref.read(proposalFormSaveProvider(widget.lead.id).notifier);
    final consultorId =
        ref.read(authNotifierProvider).valueOrNull?.id ?? '';

    final success = await notifier.save(
      titulo: _tituloCtrl.text.trim(),
      destinos: widget.lead.destino != null ? [widget.lead.destino!] : [],
      dataSaida: widget.lead.dataIda,
      dataRetorno: widget.lead.dataVolta,
      numAdultos: _numAdultos,
      numCriancas: _numCriancas,
      servicosInclusos: _servicos,
      valorTotal: _parseValor(),
      condicoesPagamento: _condicoesPagamentoCtrl.text.trim(),
      validadeProposta: _validadeProposta,
      observacoesGerais: _observacoesCtrl.text.trim(),
      htmlContent: '',
      assinatura: _assinatura,
      consultorId: consultorId,
    );

    if (!success && retryable && _retryCount < 3) {
      _retryCount++;
      Future.delayed(const Duration(seconds: 10), _autoSave);
    } else {
      _retryCount = 0;
      if (success) setState(() => _isDirty = false);
    }
  }

  int get _numAdultos => (widget.lead.numPessoas ?? 1).clamp(1, 99);
  int get _numCriancas => 0;

  double _parseValor() {
    final raw = _valorCtrl.text
        .replaceAll(RegExp(r'[^\d,]'), '')
        .replaceAll(',', '.');
    return double.tryParse(raw) ?? 0.0;
  }

  Map<String, String> _validate({required bool requireSignature}) {
    final errors = <String, String>{};
    if (_tituloCtrl.text.trim().isEmpty) {
      errors['titulo'] = 'Título é obrigatório';
    }
    if (_servicos.isEmpty) {
      errors['servicos'] = 'Selecione pelo menos um serviço';
    }
    if (_parseValor() <= 0) {
      errors['valor'] = 'Informe um valor maior que zero';
    }
    if (_validadeProposta == null) {
      errors['validade'] = 'Informe a validade da proposta';
    } else if (_validadeProposta!.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    )) {
      errors['validade'] = 'Validade não pode ser no passado';
    }
    if (requireSignature && _assinatura == null) {
      errors['assinatura'] = 'Assinatura é obrigatória para enviar';
    }
    return errors;
  }

  Future<Uint8List?> _generatePdf() async {
    if (_pdfBytesCache != null) return _pdfBytesCache;
    setState(() => _isGeneratingPdf = true);
    try {
      final saveState =
          ref.read(proposalFormSaveProvider(widget.lead.id));
      final data = ProposalPdfData(
        titulo: _tituloCtrl.text.trim().isEmpty
            ? 'Proposta de Viagem'
            : _tituloCtrl.text.trim(),
        destinos:
            widget.lead.destino != null ? [widget.lead.destino!] : [],
        dataSaida: widget.lead.dataIda,
        dataRetorno: widget.lead.dataVolta,
        numAdultos: _numAdultos,
        numCriancas: _numCriancas,
        servicosInclusos: _servicos,
        valorTotal: _parseValor(),
        condicoesPagamento: _condicoesPagamentoCtrl.text.trim(),
        validadeProposta: _validadeProposta,
        observacoesGerais: _observacoesCtrl.text.trim(),
        nomeConsultor:
            ref.read(authNotifierProvider).valueOrNull?.name ?? 'Consultor',
        versao: saveState.proposalId != null ? 1 : 1,
        assinatura: _assinatura,
      );
      final bytes = await generateProposalPdf(data);
      if (mounted) setState(() => _pdfBytesCache = bytes);
      return bytes;
    } on Exception catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Erro ao gerar PDF: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _onPreviewPdf() async {
    final errors = _validate(requireSignature: false);
    if (errors.isNotEmpty) {
      _showErrorSummary(errors);
      return;
    }
    final bytes = await _generatePdf();
    if (bytes == null || !mounted) return;
    await ProposalPdfPreviewModal.show(
      context,
      pdfBytes: bytes,
      titulo: _tituloCtrl.text.trim(),
      onSend: _onSendToLead,
    );
  }

  Future<void> _onSendToLead() async {
    final errors = _validate(requireSignature: true);
    if (errors.isNotEmpty) {
      _showErrorSummary(errors);
      return;
    }

    // Ensure saved first
    await _autoSave();
    if (!mounted) return;
    final saveState = ref.read(proposalFormSaveProvider(widget.lead.id));
    if (saveState.proposalId == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Salve o rascunho antes de enviar.'),
        ),
      );
      return;
    }

    final success = await ref
        .read(proposalFormSaveProvider(widget.lead.id).notifier)
        .sendProposal();

    if (!mounted) return;
    if (success) {
      unawaited(HapticFeedback.mediumImpact());
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Proposta enviada ao lead com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Erro ao enviar proposta. Tente novamente.'),
        ),
      );
    }
  }

  void _showErrorSummary(Map<String, String> errors) {
    ShadToaster.of(context).show(
      ShadToast.destructive(
        description: Text(errors.values.join('\n')),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _validadeProposta ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Validade da proposta',
    );
    if (picked != null) {
      setState(() => _validadeProposta = picked);
      _onChanged();
    }
  }

  Future<void> _onAddSignature() async {
    final nomeConsultor =
        ref.read(authNotifierProvider).valueOrNull?.name ?? 'Consultor';
    final result = await ProposalSignatureModal.show(
      context,
      nomeConsultor: nomeConsultor,
      existing: _assinatura,
    );
    if (result != null) {
      setState(() => _assinatura = result);
      _onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(proposalFormSaveProvider(widget.lead.id));
    final isEnviada = saveState.isEnviada;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Auto-save status indicator
        _AutoSaveBar(status: saveState.autoSaveStatus),
        const SizedBox(height: 12),

        if (isEnviada)
          _SentBanner(onEdit: () {
            ref
                .read(proposalFormSaveProvider(widget.lead.id).notifier)
                .resetStatus();
          }),

        // ── Seção 1: Informações da Viagem ──────────────────────────
        _FormSection(
          title: 'Informações da Viagem',
          icon: Icons.flight_takeoff_rounded,
          children: [
            const _FieldLabel('Título da Proposta *'),
            ShadInput(
              controller: _tituloCtrl,
              placeholder: const Text('Ex: Viagem Salvador 2026'),
              enabled: !isEnviada,
              maxLength: 100,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ReadOnlyField(
                    label: 'Destino',
                    value: widget.lead.destino ?? 'Não informado',
                    icon: Icons.place_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReadOnlyField(
                    label: 'Passageiros',
                    value: '${widget.lead.numPessoas ?? 1}',
                    icon: Icons.people_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ReadOnlyField(
                    label: 'Data de Saída',
                    value: widget.lead.dataIda != null
                        ? _dateFmt.format(widget.lead.dataIda!)
                        : 'Não informada',
                    icon: Icons.flight_takeoff_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReadOnlyField(
                    label: 'Data de Retorno',
                    value: widget.lead.dataVolta != null
                        ? _dateFmt.format(widget.lead.dataVolta!)
                        : 'Não informada',
                    icon: Icons.flight_land_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Seção 2: Serviços Inclusos ───────────────────────────────
        _FormSection(
          title: 'Serviços Inclusos *',
          icon: Icons.checklist_rounded,
          children: [
            ...ServicoIncluso.values.map(
              (s) => _ServiceCheckbox(
                servico: s,
                checked: _servicos.contains(s),
                enabled: !isEnviada,
                onChanged: (v) => setState(() {
                  if (v) {
                    _servicos = [..._servicos, s];
                  } else {
                    _servicos = _servicos.where((e) => e != s).toList();
                  }
                  _onChanged();
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Seção 3: Valores ─────────────────────────────────────────
        _FormSection(
          title: 'Valores',
          icon: Icons.attach_money_rounded,
          children: [
            const _FieldLabel('Valor Total (R\$) *'),
            ShadInput(
              controller: _valorCtrl,
              placeholder: const Text('0,00'),
              enabled: !isEnviada,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_currencyFormatter],
              leading: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('R\$', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            const _FieldLabel('Condições de Pagamento'),
            ShadInput(
              controller: _condicoesPagamentoCtrl,
              placeholder: const Text(
                'Ex: 50% na confirmação, 50% com 30 dias de antecedência',
              ),
              enabled: !isEnviada,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Seção 4: Configuração ────────────────────────────────────
        _FormSection(
          title: 'Configuração',
          icon: Icons.tune_rounded,
          children: [
            const _FieldLabel('Validade da Proposta *'),
            _DatePickerTile(
              date: _validadeProposta,
              enabled: !isEnviada,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            const _FieldLabel('Observações Gerais'),
            ShadInput(
              controller: _observacoesCtrl,
              placeholder: const Text(
                'Informações adicionais, inclusões especiais...',
              ),
              enabled: !isEnviada,
              maxLines: 5,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Seção 5: Assinatura Digital ──────────────────────────────
        _FormSection(
          title: 'Assinatura Digital',
          icon: Icons.draw_outlined,
          children: [
            if (_assinatura != null)
              _SignaturePreview(
                assinatura: _assinatura!,
                onRemove: isEnviada
                    ? null
                    : () => setState(() {
                          _assinatura = null;
                          _onChanged();
                        }),
              )
            else
              CadifeButton(
                text: 'Adicionar Assinatura',
                icon: Icons.draw_outlined,
                variant: ButtonVariant.secondary,
                isOutline: true,
                analyticsLabel: 'proposal_add_signature',
                onPressed: isEnviada ? null : _onAddSignature,
              ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Ações ────────────────────────────────────────────────────
        CadifeButton(
          text: _isGeneratingPdf ? 'Gerando PDF...' : 'Visualizar PDF',
          icon: Icons.picture_as_pdf_outlined,
          variant: ButtonVariant.secondary,
          isOutline: true,
          isLoading: _isGeneratingPdf,
          analyticsLabel: 'proposal_preview_pdf',
          onPressed: _isGeneratingPdf ? null : _onPreviewPdf,
        ),
        const SizedBox(height: 12),
        CadifeButton(
          text: saveState.isSending ? 'Enviando...' : 'Enviar ao Lead',
          icon: Icons.send_rounded,
          isLoading: saveState.isSending,
          analyticsLabel: 'proposal_send',
          onPressed:
              (isEnviada || saveState.isSending) ? null : _onSendToLead,
        ),
      ],
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _AutoSaveBar extends StatelessWidget {
  const _AutoSaveBar({required this.status});
  final AutoSaveStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      AutoSaveStatus.idle => (
          Icons.cloud_queue_outlined,
          'Rascunho',
          context.cadife.textSecondary,
        ),
      AutoSaveStatus.saving => (
          Icons.cloud_upload_outlined,
          'Salvando...',
          AppColors.info,
        ),
      AutoSaveStatus.saved => (
          Icons.cloud_done_outlined,
          'Salvo',
          AppColors.success,
        ),
      AutoSaveStatus.error => (
          Icons.cloud_off_outlined,
          'Erro ao salvar',
          AppColors.warning,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
        if (status == AutoSaveStatus.saving) ...[
          const SizedBox(width: 6),
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.info,
            ),
          ),
        ],
      ],
    );
  }
}

class _SentBanner extends StatelessWidget {
  const _SentBanner({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Proposta enviada ao lead.',
              style: TextStyle(color: AppColors.success, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: context.cadife.textSecondary,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.cadife.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cadife.cardBorder.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.cadife.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.cadife.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 12, color: context.cadife.textSecondary),
        ],
      ),
    );
  }
}

class _ServiceCheckbox extends StatelessWidget {
  const _ServiceCheckbox({
    required this.servico,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  final ServicoIncluso servico;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  static const _icons = {
    ServicoIncluso.aereo: Icons.flight,
    ServicoIncluso.hotel: Icons.hotel_outlined,
    ServicoIncluso.transfer: Icons.directions_bus_outlined,
    ServicoIncluso.seguro: Icons.health_and_safety_outlined,
    ServicoIncluso.passeios: Icons.explore_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!checked) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: enabled ? (v) => onChanged(v ?? false) : null,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Icon(
              _icons[servico] ?? Icons.check_box_outline_blank,
              size: 18,
              color: checked ? AppColors.primary : context.cadife.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              servico.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
                color: checked
                    ? AppColors.primary
                    : context.cadife.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.date,
    required this.enabled,
    required this.onTap,
  });

  final DateTime? date;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    final hasDate = date != null;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: hasDate
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate ? AppColors.primary : Colors.grey.shade300,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: hasDate ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDate ? fmt.format(date!) : 'Selecionar data',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      hasDate ? FontWeight.w600 : FontWeight.normal,
                  color: hasDate
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.grey,
                ),
              ),
            ),
            if (!enabled)
              Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _SignaturePreview extends StatelessWidget {
  const _SignaturePreview({required this.assinatura, this.onRemove});

  final AssinaturaDigital assinatura;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assinatura.textoAssinatura ?? assinatura.nomeConsultor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Assinado em ${fmt.format(assinatura.timestamp)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.cadife.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onRemove,
              color: context.cadife.textSecondary,
            ),
        ],
      ),
    );
  }
}
