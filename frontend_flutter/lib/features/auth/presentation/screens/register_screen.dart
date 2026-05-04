import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      appBar: const CadifeAppBar(
        title: 'Criar conta',
        showProfile: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text('Cadastro de cliente', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              Text(
                'Essa funcionalidade estará disponível em breve.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CadifeButton(
                text: 'VOLTAR AO LOGIN',
                isOutline: true,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
