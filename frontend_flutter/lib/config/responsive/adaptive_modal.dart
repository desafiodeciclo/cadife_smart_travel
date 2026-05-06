import 'package:cadife_smart_travel/config/responsive/responsive_breakpoints.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Helper para exibir modais que se adaptam ao tamanho da tela.
/// No Mobile: Bottom Sheet padrão.
/// No Tablet/Desktop: Side Sheet (desliza da direita).
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isDismissible = true,
  bool useRootNavigator = false,
}) async {
  if (context.isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: useRootNavigator,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.cadife.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.cadife.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
            ],
            Flexible(child: child),
          ],
        ),
      ),
    );
  } else {
    // Tablet/Desktop: Side Sheet
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: title ?? 'Modal',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      useRootNavigator: useRootNavigator,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 450,
              height: double.infinity,
              decoration: BoxDecoration(
                color: context.cadife.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (title != null)
                          Expanded(
                            child: Text(
                              title,
                              style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }
}
