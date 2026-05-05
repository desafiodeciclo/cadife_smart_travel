import 'package:cadife_smart_travel/core/utils/extensions/string_extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _ForgotStep { email, confirmation, success }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  _ForgotStep _step = _ForgotStep.email;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await ref
        .read(authNotifierProvider.notifier)
        .forgotPassword(_emailController.text.trim());
    if (!mounted) return;
    result.fold(
      (failure) => setState(
          () => _errorMessage = 'Não foi possível enviar o e-mail. Tente novamente.'),
      (_) => setState(() => _step = _ForgotStep.confirmation),
    );
    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Scaffold(
      appBar: const CadifeAppBar(
        title: 'Recuperar senha',
        showProfile: false,
        actions: [], // Empty list to override default notifications if needed
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          ),
          child: switch (_step) {
            _ForgotStep.email => _EmailStep(
                key: const ValueKey('email-step'),
                formKey: _formKey,
                controller: _emailController,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                primaryColor: cadife.primary,
                onSubmit: _sendReset,
              ),
            _ForgotStep.confirmation => _ConfirmationStep(
                key: const ValueKey('confirmation-step'),
                email: _emailController.text.trim(),
                onResend: _sendReset,
                isResending: _isLoading,
              ),
            _ForgotStep.success => _SuccessStep(
                key: const ValueKey('success-step'),
                onBackToLogin: () => context.go('/auth/login'),
              ),
          },
        ),
      ),
    );
  }
}

// ── Email Step ───────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.errorMessage,
    required this.primaryColor,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final String? errorMessage;
  final Color primaryColor;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text('Esqueceu a senha?', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Informe o e-mail da sua conta. Enviaremos um link para criar uma nova senha.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            CadifeInput(
              label: 'E-mail',
              hint: 'seu@email.com',
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                if (!v.trim().isValidEmail) return 'E-mail inválido';
                return null;
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: errorMessage!),
            ],
            const SizedBox(height: 28),
            CadifeButton(
              text: 'ENVIAR LINK',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confirmation Step ────────────────────────────────────────────────────────

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({
    super.key,
    required this.email,
    required this.onResend,
    required this.isResending,
  });

  final String email;
  final VoidCallback onResend;
  final bool isResending;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 32,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Verifique seu e-mail', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: context.cadife.textSecondary),
                    children: [
                      const TextSpan(
                          text: 'Enviamos um link de recuperação para '),
                      TextSpan(
                        text: email,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.cadife.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(
                          text: '. Verifique também a caixa de spam.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ShadCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? context.cadife.cardBackground 
                      : context.cadife.surface,
                  radius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Não recebeu o e-mail?',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: context.cadife.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aguarde alguns minutos e verifique a caixa de spam antes de reenviar.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: context.cadife.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: isResending ? null : onResend,
                        child: Text(
                          isResending ? 'Reenviando…' : 'Reenviar link',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isResending
                                ? context.cadife.textSecondary
                                : AppColors.primary,
                            decoration:
                                isResending ? null : TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CadifeButton(
                  text: 'VOLTAR AO LOGIN',
                  isOutline: true,
                  onPressed: () => context.go('/auth/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Success Step ─────────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({super.key, required this.onBackToLogin});
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.check_circle_outline_rounded,
                    size: 80, color: AppColors.success),
                const SizedBox(height: 24),
                Text('Senha redefinida!',
                    style: AppTextStyles.h3, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Sua senha foi alterada com sucesso. Faça login com a nova senha.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.cadife.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                CadifeButton(
                  text: 'IR PARA O LOGIN',
                  onPressed: onBackToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      backgroundColor: AppColors.error.withValues(alpha: 0.08),
      radius: BorderRadius.circular(8),
      border: ShadBorder.all(color: AppColors.error.withValues(alpha: 0.3)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
