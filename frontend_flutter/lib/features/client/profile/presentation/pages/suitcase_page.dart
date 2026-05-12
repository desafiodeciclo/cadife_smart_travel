import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/suitcase_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuitcasePage extends StatelessWidget {
  const SuitcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/client/profile');
        }
      },
      child: Scaffold(
        backgroundColor: cadife.background,
        appBar: AppBar(
          backgroundColor: cadife.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: cadife.textPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go('/client/profile'),
          ),
          title: Text(
            'Minha Mala',
            style: AppTextStyles.h3.copyWith(
              color: cadife.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const SuitcaseTab(),
      ),
    );
  }
}
