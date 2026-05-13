import 'package:cadife_smart_travel/providers/leads_provider.dart';
import 'package:cadife_smart_travel/widgets/lead_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CrmTab extends ConsumerWidget {
  const CrmTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsProvider);
    final notifier = ref.read(leadsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header com Filtro
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Gestão de Leads',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButton<String>(
                  value: notifier.currentStatus,
                  hint: const Text('Todos Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    const DropdownMenuItem(value: 'novo', child: Text('Novo')),
                    const DropdownMenuItem(value: 'qualificado', child: Text('Qualificado')),
                    const DropdownMenuItem(value: 'em_atendimento', child: Text('Em Atendimento')),
                    const DropdownMenuItem(value: 'proposta', child: Text('Proposta')),
                    const DropdownMenuItem(value: 'fechado', child: Text('Fechado')),
                    const DropdownMenuItem(value: 'perdido', child: Text('Perdido')),
                  ],
                  onChanged: (val) => notifier.filterByStatus(val),
                ),
              ],
            ),
          ),
          
          // Lista de Leads
          Expanded(
            child: leadsAsync.when(
              data: (response) {
                if (response.items.isEmpty) {
                  return const Center(child: Text('Nenhum lead encontrado.'));
                }
                return ListView.builder(
                  itemCount: response.items.length,
                  itemBuilder: (context, index) {
                    return LeadCard(lead: response.items[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar dados: $err'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(leadsProvider),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Paginação
          if (leadsAsync.hasValue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Página ${leadsAsync.value!.page} de ${leadsAsync.value!.pages}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: leadsAsync.value!.page > 1
                            ? () => notifier.changePage(leadsAsync.value!.page - 1)
                            : null,
                        child: const Text('Anterior'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: leadsAsync.value!.page < leadsAsync.value!.pages
                            ? () => notifier.changePage(leadsAsync.value!.page + 1)
                            : null,
                        child: const Text('Próximo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
