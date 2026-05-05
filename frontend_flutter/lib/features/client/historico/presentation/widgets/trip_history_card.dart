import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:flutter/material.dart';

class TripHistoryCard extends StatelessWidget {
  const TripHistoryCard({
    super.key,
    required this.trip,
    this.onTap,
  });

  final TripSummary trip;
  final VoidCallback? onTap;

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/--';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatCurrency(double? value) {
    if (value == null) return r'R$ 0,00';
    return NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ShadCard(
        padding: EdgeInsets.zero,
        radius: BorderRadius.circular(24),
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        border: ShadBorder.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagem central maior
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (trip.imageUrl != null)
                        Hero(
                          tag: 'trip_image_${trip.id}',
                          child: Image.network(
                            trip.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _ImagePlaceholder(isDark: isDark),
                          ),
                        )
                      else
                        _ImagePlaceholder(isDark: isDark),
                      
                      // Gradiente sobre a imagem
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Nome da viagem sobre a imagem
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Text(
                          trip.name,
                          style: context.shadText.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Informações básicas na parte inferior
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              icon: LucideIcons.mapPin,
                              label: 'Destino',
                              value: trip.destino ?? 'Não informado',
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              icon: LucideIcons.calendar,
                              label: 'Data',
                              value: _formatDate(trip.dataIda),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              icon: LucideIcons.users,
                              label: 'Pessoas',
                              value: '${trip.numPessoas ?? 0} ${trip.numPessoas == 1 ? 'pessoa' : 'pessoas'}',
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              icon: LucideIcons.wallet,
                              label: 'Orçamento',
                              value: _formatCurrency(trip.orcamento),
                              valueColor: AppColors.primary,
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
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad);
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.shadText.small.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: context.shadText.p.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: valueColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;
  const _ImagePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          LucideIcons.image,
          color: isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.24),
          size: 48,
        ),
      ),
    );
  }
}
