import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/lead_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeadDetailScreen extends ConsumerWidget {
  final String leadId;

  const LeadDetailScreen({required this.leadId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadDetailProvider(leadId));

    return leadAsync.when(
      data: (lead) => lead == null
          ? const Scaffold(body: Center(child: Text('Lead não encontrado')))
          : _buildDetail(context, ref, lead),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const Scaffold(
        body: Center(child: Text('Erro ao carregar lead')),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Lead lead) {
    // Map fields from the existing Lead entity
    final String name = lead.name;
    final String status = lead.status.name;
    final String? avatarUrl = lead.imageUrl;
    final String destination = lead.destino ?? 'Não informado';
    final String startDateStr = lead.dataIda != null
        ? DateFormat('dd/MM/yyyy').format(lead.dataIda!)
        : 'A definir';
    final String endDateStr = lead.dataVolta != null
        ? DateFormat('dd/MM/yyyy').format(lead.dataVolta!)
        : 'A definir';
    final String budgetStr = lead.orcamentoFaixa ?? 'Não informado';
    final int passengers = lead.numPessoas ?? 0;
    final double score = lead.completudePct.toDouble();
    final String? briefing = lead.preferencias;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DETALHE DO LEAD'),
        elevation: 0,

        actions: [
          // Menu (3 pontinhos) para editar
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _showEditLeadModal(context, ref, lead),
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 12),
                    Text('Editar Lead'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto do cliente (grande)
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 4,
                ),
                image: avatarUrl != null && avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            // Nome e status
            Text(
              name.toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(status),
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Informações (cards)
            _buildInfoCard(context, 'Destino', destination, Icons.location_on),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Data da Viagem',
              '$startDateStr a $endDateStr',
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Orçamento',
              budgetStr,
              Icons.attach_money,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Passageiros',
              '$passengers pessoas',
              Icons.people,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Score de Completude',
              '${score.toStringAsFixed(0)}%',
              Icons.trending_up,
            ),

            const SizedBox(height: 24),

            // Seção Briefing (dados extraídos pela IA)
            if (briefing != null && briefing.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'BRIEFING COLETADO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CadifeCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  briefing,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: context.cadife.textPrimary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botão Confirmar Horário
            ElevatedButton(
              onPressed: () => _showScheduleModal(context, ref, lead),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('CONFIRMAR HORÁRIO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    return CadifeCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.cadife.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.cadife.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditLeadModal(
    BuildContext context,
    WidgetRef ref,
    Lead lead,
  ) {
    final nameController = TextEditingController(text: lead.name);
    final destinationController = TextEditingController(text: lead.destino);
    final budgetController = TextEditingController(text: lead.orcamentoFaixa);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EDITAR LEAD',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destino',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Orçamento',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Simula PATCH /leads/{id}
                  // await ref.read(leadDetailProvider(leadId).notifier).updateLead(...)
                  
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lead atualizado com sucesso!')),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleModal(
    BuildContext context,
    WidgetRef ref,
    Lead lead,
  ) {
    DateTime? selectedDateTime;

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AGENDAR CURADORIA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecione uma data e horário para a reunião de curadoria com o cliente.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // Date/Time Picker Trigger
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setModalState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          selectedDateTime == null
                              ? 'Selecionar Data e Horário'
                              : DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime!),
                          style: TextStyle(
                            color: selectedDateTime == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: selectedDateTime == null ? null : () async {
                    // Simula POST /agenda/slots
                    // await ...
                    
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Horário agendado com sucesso!')),
                    );
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar Horário'),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Color _getStatusColor(String status) => AppColors.statusColor(status);
}
