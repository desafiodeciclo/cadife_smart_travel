import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class CreateProposalModal extends StatefulWidget {
  final String leadId;

  const CreateProposalModal({required this.leadId, super.key});

  static Future<void> show(BuildContext context, String leadId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateProposalModal(leadId: leadId),
    );
  }

  @override
  State<CreateProposalModal> createState() => _CreateProposalModalState();
}

class _CreateProposalModalState extends State<CreateProposalModal> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 24),
              const Text(
                'Criar Nova Proposta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CadifeInput(
                controller: _valorController,
                label: 'Valor da Proposta',
                hintText: '0,00',
                prefixIcon: Icons.attach_money,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o valor da proposta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CadifeInput(
                controller: _descricaoController,
                label: 'Descrição (Resumo)',
                maxLines: 4,
                hintText: 'Descreva os detalhes e inclusões da proposta...',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a descrição da proposta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CadifeButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proposta criada com sucesso!')),
                    );
                  }
                },
                text: 'Enviar Proposta',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
