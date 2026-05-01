import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wrapper para aplicar efeito de Shimmer seguindo o padrão visual do projeto.
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    // Cores baseadas no background conforme feedback do usuário
    return Shimmer.fromColors(
      baseColor: AppColors.deepGraphite.withValues(alpha: 0.1),
      highlightColor: AppColors.deepGraphite.withValues(alpha: 0.05),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Helper para criar blocos de skeleton com tamanhos pré-definidos.
class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Templates comuns de Skeleton para o CRM.
class AppSkeletons {
  static Widget leadCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Skeleton(width: 50, height: 50, borderRadius: 25),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 150, height: 16),
                  SizedBox(height: 8),
                  Skeleton(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget listPage() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: leadCard(),
      ),
    );
  }
}

/// Overlay de carregamento premium com efeito de desfoque (Glassmorphism).
class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.isLoading = false,
    this.message = 'Carregando...',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

