import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/data/repositories/offer_repository.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/providers/offers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);
    final searchController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('OFERTAS'),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar destino...',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      prefixIcon: const Icon(Icons.search, color: AppColors.zinc500),
                    ),
                    onSubmitted: (value) {
                      ref.read(offersProvider.notifier).setSearch(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.primary),
                    onPressed: () => _showFiltersModal(context, ref),
                  ),
                ),
              ],
            ),
          ),

          // Lista de ofertas
          Expanded(
            child: offersAsync.when(
              data: (offers) => offers.isEmpty
                  ? const Center(child: Text('Nenhuma oferta disponível'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, WidgetRef ref, Offer offer) {
    return GestureDetector(
      onTap: () => context.push('/offers/${offer.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            Stack(
              children: [
                Image.network(
                  offer.destinationImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: AppColors.zinc100,
                    child: const Center(child: Icon(Icons.image_not_supported, size: 50)),
                  ),
                ),

                // Desconto badge
                if (offer.hasDiscount)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${offer.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                // Vagas esgotadas
                if (!offer.availableSpot)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.black.withValues(alpha: 0.4),
                      child: const Center(
                        child: Text(
                          'VAGAS ESGOTADAS',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destino e duração
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          offer.destination.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.zinc500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (offer.durationDays != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.zinc100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${offer.durationDays} DIAS',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.zinc700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Datas
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.zinc500),
                      const SizedBox(width: 6),
                      Text(
                        offer.dates != null
                            ? '${offer.departureDate!.day}/${offer.departureDate!.month} a '
                              '${offer.returnDate!.day}/${offer.returnDate!.month}/${offer.returnDate!.year}'
                            : 'Datas a definir',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Highlights
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: offer.highlights.take(2).map((h) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          h,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Preço e botão
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offer.hasDiscount)
                            Text(
                              'R\$ ${offer.basePrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.zinc400,
                              ),
                            ),
                          Text(
                            'R\$ ${offer.finalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'por pessoa',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.zinc500,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: offer.availableSpot
                            ? () => _showInterestModal(context, ref, offer)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'INTERESSAR',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FILTRAR OFERTAS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            const Text('Preço máximo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Example slider for price
            Slider(
              value: 10000,
              min: 0,
              max: 20000,
              activeColor: AppColors.primary,
              onChanged: (v) {},
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('APLICAR FILTROS'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInterestModal(BuildContext context, WidgetRef ref, Offer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tenho interesse!'),
        content: Text(
          'Deseja que um consultor da Cadife entre em contato para falar sobre "${offer.title}"? \n\nCriaremos um lead qualificado para você.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.zinc500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _expressInterest(context, ref, offer);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _expressInterest(
    BuildContext context,
    WidgetRef ref,
    Offer offer,
  ) async {
    try {
      await ref.read(offerRepositoryProvider).expressInterest(offer.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Seu interesse foi registrado! Um consultor entrará em contato.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar interesse: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
