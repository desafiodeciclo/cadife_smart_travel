import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/core/theme/app_text_styles.dart';
import 'package:cadife_smart_travel/core/widgets/app_text_field.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flight_takeoff, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'CADIFE TOUR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plataforma de Atendimento Inteligente',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _emailController,
                            label: 'E-mail',
                            hint: 'Seu e-mail corporativo',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.email,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Senha',
                            hint: 'Informe sua senha',
                            isPassword: true,
                            prefixIcon: Icons.lock_outlined,
                            validator: AppValidators.required,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _handleLogin,
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textOnPrimary,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ),
                          if (authState.hasError) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao fazer login. Verifique suas credenciais.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}