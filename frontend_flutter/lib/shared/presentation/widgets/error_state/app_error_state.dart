import 'dart:async';
import 'dart:io';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/error_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  final ErrorType type;
  final String? customTitle;
  final String? customSubtitle;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String retryButtonLabel;
  
  const AppErrorState({
    required this.type,
    this.customTitle,
    this.customSubtitle,
    this.onRetry,
    this.onDismiss,
    this.retryButtonLabel = 'Tentar Novamente',
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final showRetry = type.isRetryable && onRetry != null;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: type.iconColor.withAlpha(51), // 20% opacity
                shape: BoxShape.circle,
              ),
              child: Icon(
                type.icon,
                size: 40,
                color: type.iconColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Título
            Text(
              customTitle ?? type.title,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtítulo
            Text(
              customSubtitle ?? type.subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.cadife.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Botões de ação
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (showRetry)
                  CadifeButton(
                    text: retryButtonLabel,
                    onPressed: onRetry,
                  ),
                if (onDismiss != null)
                  CadifeButton(
                    text: 'Fechar',
                    onPressed: onDismiss,
                    isOutline: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Factory para criar a partir de exceções
extension AppErrorStateFactory on AppErrorState {
  static AppErrorState fromException(
    Object exception, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    final errorType = switch (exception) {
      TimeoutException _ => ErrorType.networkError,
      SocketException _ => ErrorType.networkError,
      DioException(type: DioExceptionType.connectionTimeout) =>
        ErrorType.networkError,
      DioException(type: DioExceptionType.receiveTimeout) =>
        ErrorType.networkError,
      DioException(type: DioExceptionType.sendTimeout) =>
        ErrorType.networkError,
      DioException(type: DioExceptionType.connectionError) =>
        ErrorType.networkError,
      DioException(response: final r?) => switch (r.statusCode) {
        401 => ErrorType.unauthorized,
        403 => ErrorType.forbidden,
        404 => ErrorType.notFound,
        429 => ErrorType.rateLimited,
        final int status when status >= 500 => ErrorType.serverError,
        400 => ErrorType.validationError,
        _ => ErrorType.genericError,
      },
      _ => ErrorType.genericError,
    };
    
    return AppErrorState(
      type: errorType,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }
}
