import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/lead_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeadDetailScreen extends ConsumerWidget {
  final String leadId;

  const LeadDetailScreen({required this.leadId, Key? key}) : super(key: key);

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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
            _buildInfoCard('Destino', destination, Icons.location_on),
            _buildInfoCard(
              'Data da Viagem',
              '$startDateStr a $endDateStr',
              Icons.calendar_today,
            ),
            _buildInfoCard(
              'Orçamento',
              budgetStr,
              Icons.attach_money,
            ),
            _buildInfoCard(
              'Passageiros',
              '$passengers pessoas',
              Icons.people,
            ),
            _buildInfoCard(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  briefing,
                  style: const TextStyle(fontSize: 13, height: 1.6),
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
    // Modal para editar nome, destino, orçamento, etc
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
                decoration: InputDecoration(
                  labelText: 'Nome',
                  hintText: lead.name,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Destino',
                  hintText: lead.destino ?? 'Não informado',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Orçamento',
                  hintText: lead.orcamentoFaixa ?? 'Não informado',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: PATCH /leads/{id} com dados atualizados
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
    // Modal para agendar horário de curadoria
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
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
            // TODO: Date picker para selecionar data/hora
            ElevatedButton(
              onPressed: () {
                // POST /agenda/slots com lead_id e horário
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
      ),
    );
  }

  Color _getStatusColor(String status) => AppColors.statusColor(status);
}
