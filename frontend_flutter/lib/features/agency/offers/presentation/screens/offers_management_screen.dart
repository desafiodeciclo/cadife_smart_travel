import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/data/repositories/offer_repository.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/providers/offers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OffersManagementScreen extends ConsumerWidget {
  const OffersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myOffersAsync = ref.watch(myOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('MINHAS OFERTAS'),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/agency/offers/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text('NOVA OFERTA', style: TextStyle(color: AppColors.white)),
      ),
      body: myOffersAsync.when(
        data: (offers) => offers.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                itemBuilder: (context, idx) => _buildOfferCard(
                  context,
                  ref,
                  offers[idx],
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_giftcard, size: 80, color: AppColors.zinc300),
          const SizedBox(height: 24),
          const Text(
            'Nenhuma oferta criada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.zinc600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Crie ofertas para que seus clientes \npossam ver na vitrine.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.zinc500),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.push('/agency/offers/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('CRIAR PRIMEIRA OFERTA'),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, WidgetRef ref, Offer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(offer.status),
            ],
          ),

          const SizedBox(height: 8),

          // Destino e datas
          Text(
            offer.destination,
            style: const TextStyle(fontSize: 13, color: AppColors.zinc500, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: AppColors.zinc400),
              const SizedBox(width: 6),
              Text(
                '${offer.departureDate.day}/${offer.departureDate.month} a '
                '${offer.returnDate.day}/${offer.returnDate.month}',
                style: const TextStyle(fontSize: 12, color: AppColors.zinc400),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Estatísticas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.zinc50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.zinc100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Views', offer.views.toString(), Icons.visibility_outlined),
                _buildStatItem('Leads', offer.interests.toString(), Icons.person_add_outlined),
                _buildStatItem('Vendas', offer.conversions.toString(), Icons.shopping_bag_outlined),
                _buildStatItem('Vagas', '${offer.availableSpots - offer.spotsReserved}', Icons.event_seat_outlined),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Preço
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'R\$ ${offer.finalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (offer.hasDiscount)
                Text(
                  'R\$ ${offer.basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.zinc400,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Ações
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('EDITAR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.zinc700,
                    side: const BorderSide(color: AppColors.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.push('/agency/offers/${offer.id}/edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    offer.status == 'published' ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                  ),
                  label: Text(offer.status == 'published' ? 'PAUSAR' : 'PUBLICAR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: offer.status == 'published' ? AppColors.warning : AppColors.success,
                    side: BorderSide(
                      color: (offer.status == 'published' ? AppColors.warning : AppColors.success).withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _togglePublish(context, ref, offer),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.primary),
                onPressed: () => _deleteOffer(context, ref, offer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.zinc400),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 8, color: AppColors.zinc500, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'draft':
        color = AppColors.zinc500;
        label = 'RASCUNHO';
        break;
      case 'published':
        color = AppColors.success;
        label = 'PUBLICADA';
        break;
      case 'sold_out':
        color = AppColors.primary;
        label = 'ESGOTADA';
        break;
      case 'archived':
        color = AppColors.zinc400;
        label = 'ARQUIVADA';
        break;
      default:
        color = AppColors.zinc500;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _togglePublish(BuildContext context, WidgetRef ref, Offer offer) {
    final isPublished = offer.status == 'published';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPublished ? 'Despublicar' : 'Publicar'),
        content: Text(
          'Tem certeza que deseja ${isPublished ? 'remover' : 'exibir'} esta oferta na vitrine?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(offerRepositoryProvider).togglePublish(offer.id);
                ref.invalidate(myOffersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isPublished ? 'Oferta despublicada' : 'Oferta publicada na vitrine')),
                  );
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.primary),
                  );
                }
              }
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

  void _deleteOffer(BuildContext context, WidgetRef ref, Offer offer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar oferta'),
        content: const Text('Esta ação não pode ser desfeita. Deseja continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(offerRepositoryProvider).deleteOffer(offer.id);
                ref.invalidate(myOffersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Oferta removida')),
                  );
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.primary),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('DELETAR'),
          ),
        ],
      ),
    );
  }
}
