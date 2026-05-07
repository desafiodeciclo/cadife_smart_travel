import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfferDetailsPage extends ConsumerWidget {
  final String offerId;
  final Offer? offer;

  const OfferDetailsPage({
    required this.offerId,
    super.key,
    this.offer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    
    // Se a oferta não foi passada via extra, poderíamos carregar via provider
    // Por enquanto usamos a que veio ou um placeholder
    final displayOffer = offer;

    return PageScaffold(
      title: displayOffer?.title ?? 'Detalhes da Oferta',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayOffer != null) ...[
              // Imagem de destaque
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  displayOffer.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.muted,
                    child: const Icon(LucideIcons.imageOff, size: 48),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            displayOffer.category.toUpperCase(),
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ID: ${displayOffer.id}',
                          style: theme.textTheme.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayOffer.title,
                      style: theme.textTheme.h3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          displayOffer.destination,
                          style: theme.textTheme.large,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sobre este pacote',
                      style: theme.textTheme.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayOffer.description,
                      style: theme.textTheme.p,
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A partir de',
                              style: theme.textTheme.small,
                            ),
                            Text(
                              'R\$ ${displayOffer.price.toStringAsFixed(2)}',
                              style: theme.textTheme.h2.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        CadifeButton(
                          text: 'Reservar Agora',
                          onPressed: () {
                            // Implementar reserva
                            ShadToaster.of(context).show(
                              const ShadToast(
                                description: Text('Funcionalidade de reserva em desenvolvimento.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: AppLoadingWidget(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
