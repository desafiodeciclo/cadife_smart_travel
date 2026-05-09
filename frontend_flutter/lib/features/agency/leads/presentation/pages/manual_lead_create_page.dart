import 'package:cadife_smart_travel/core/utils/validators.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ManualLeadCreatePage extends ConsumerStatefulWidget {
  const ManualLeadCreatePage({super.key});

  @override
  ConsumerState<ManualLeadCreatePage> createState() => _ManualLeadCreatePageState();
}

class _ManualLeadCreatePageState extends ConsumerState<ManualLeadCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _destinoController = TextEditingController();
  final _pessoasController = TextEditingController();
  final _preferenciasController = TextEditingController();
  
  LeadOrigem _origem = LeadOrigem.manual;
  DateTime? _dataIda;
  String? _orcamentoFaixa;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _destinoController.dispose();
    _pessoasController.dispose();
    _preferenciasController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final request = ManualLeadCreate(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      origem: _origem,
      destino: _destinoController.text.trim().isEmpty ? null : _destinoController.text.trim(),
      dataIda: _dataIda,
      numPessoas: int.tryParse(_pessoasController.text),
      orcamentoFaixa: _orcamentoFaixa,
      preferencias: _preferenciasController.text.trim().isEmpty ? null : _preferenciasController.text.trim(),
    );

    final result = await ref.read(leadsNotifierProvider.notifier).createManualLead(request);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSubmitting = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Erro ao criar lead'),
            description: Text(failure.message),
          ),
        );
      },
      (lead) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Sucesso!'),
            description: Text('Lead criado com sucesso.'),
          ),
        );
        // Navega para a tela de detalhes do lead recém-criado
        context.pushReplacement('/agency/leads/${lead.id}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return PageScaffold(
      appBar: const CadifeAppBar(
        title: 'Novo Lead Manual',
        showProfile: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informações do Cliente',
                style: AppTextStyles.h4.copyWith(color: cadife.primary),
              ),
              const SizedBox(height: 16),
              CadifeInput(
                label: 'Nome Completo*',
                hint: 'Ex: João Silva',
                controller: _nameController,
                validator: AppValidators.required,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CadifeInput(
                      label: 'Telefone*',
                      hint: '(00) 00000-0000',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.validatePhone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Origem', style: AppTextStyles.labelSmall.copyWith(color: cadife.textSecondary)),
                        const SizedBox(height: 8),
                        ShadSelectFormField<LeadOrigem>(
                          id: 'origem',
                          initialValue: _origem,
                          options: LeadOrigem.values
                              .map((e) => ShadOption(
                                    value: e,
                                    child: Text(e.label),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _origem = v!),
                          selectedOptionBuilder: (context, value) =>
                              Text(value.label),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CadifeInput(
                label: 'E-mail (Opcional)',
                hint: 'cliente@email.com',
                controller: _emailController,
                validator: AppValidators.validateEmail,
              ),
              
              const SizedBox(height: 32),
              Text(
                'Briefing da Viagem',
                style: AppTextStyles.h4.copyWith(color: cadife.primary),
              ),
              const SizedBox(height: 16),
              CadifeInput(
                label: 'Destino',
                hint: 'Ex: Maldivas',
                controller: _destinoController,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data Prevista', style: AppTextStyles.labelSmall.copyWith(color: cadife.textSecondary)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (date != null) setState(() => _dataIda = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: cadife.cardBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: cadife.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  _dataIda == null ? 'Selecionar' : DateFormat('dd/MM/yyyy').format(_dataIda!),
                                  style: TextStyle(color: _dataIda == null ? cadife.textSecondary : cadife.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CadifeInput(
                      label: 'Nº Pessoas',
                      hint: 'Ex: 2',
                      controller: _pessoasController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faixa de Orçamento', style: AppTextStyles.labelSmall.copyWith(color: cadife.textSecondary)),
                  const SizedBox(height: 8),
                  ShadSelectFormField<String>(
                    id: 'orcamento',
                    initialValue: _orcamentoFaixa,
                    placeholder: const Text('Selecione'),
                    options: [
                      'Até 10k',
                      '10k - 20k',
                      '20k - 50k',
                      '50k - 100k',
                      'Acima de 100k',
                    ]
                        .map((e) => ShadOption(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _orcamentoFaixa = v),
                    selectedOptionBuilder: (context, value) => Text(value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CadifeInput(
                label: 'Observações / Preferências',
                hint: 'Ex: Hotel beira-mar, voo noturno...',
                controller: _preferenciasController,
                maxLines: 3,
              ),
              
              const SizedBox(height: 40),
              CadifeButton(
                text: 'CRIAR LEAD',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
