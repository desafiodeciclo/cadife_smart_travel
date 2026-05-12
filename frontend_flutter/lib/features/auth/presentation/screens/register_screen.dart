import 'dart:async';

import 'package:cadife_smart_travel/core/constants/assets_constants.dart';
import 'package:cadife_smart_travel/core/utils/extensions/string_extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _EmailState { idle, validating, valid, invalid }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _EmailState _emailState = _EmailState.idle;
  Timer? _emailDebounce;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailDebounce?.cancel();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _emailState = _EmailState.idle);
      return;
    }
    setState(() => _emailState = _EmailState.validating);
    _emailDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _emailState = value.trim().isValidEmail
            ? _EmailState.valid
            : _EmailState.invalid;
      });
    });
  }

  int get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Future<void> _handleRegister() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isLoading) return;
    if (_emailState == _EmailState.invalid) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Aceite os termos de uso para continuar.'),
        ),
      );
      return;
    }

    await ref.read(authNotifierProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthUser?>>(authNotifierProvider, (previous, next) {
      if (next.hasError && !(previous?.hasError ?? false)) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description:
                Text(next.error?.toString() ?? 'Erro ao criar conta.'),
          ),
        );
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final hasError = authState.hasError;

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final cadife = context.cadife;
    final textSecondary =
        isDark ? Colors.white60 : cadife.textSecondary;
    final dividerColor = isDark ? Colors.white12 : cadife.cardBorder;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Theme toggle ──────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12, bottom: 4),
                child: _ThemeToggle(isDark: isDark),
              ),
            ),

            // ── Scrollable form ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Logo ──────────────────────────────────────────
                        Center(
                          child: SvgPicture.asset(
                            isDark ? AssetsConstants.logoSvgNegativo : AssetsConstants.logoSvgPositivo,
                            width: 220,
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Heading ───────────────────────────────────────
                        Text(
                          'Criar conta',
                          style: AppTextStyles.h2
                              .copyWith(color: cadife.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Preencha seus dados para começar',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 28),

                        // ── Nome ──────────────────────────────────────────
                        CadifeInput(
                          key: const ValueKey('name_field'),
                          label: 'Nome completo',
                          hint: 'Seu nome',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe seu nome';
                            }
                            if (v.trim().length < 3) {
                              return 'Nome muito curto';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── E-mail ────────────────────────────────────────
                        CadifeInput(
                          key: const ValueKey('email_field'),
                          label: 'E-mail',
                          hint: 'seu@email.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: _onEmailChanged,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o e-mail';
                            }
                            if (!v.trim().isValidEmail) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Telefone ──────────────────────────────────────
                        CadifeInput(
                          key: const ValueKey('phone_field'),
                          label: 'Telefone (opcional)',
                          hint: '(11) 9 0000-0000',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // ── Senha ─────────────────────────────────────────
                        CadifeInput(
                          key: const ValueKey('password_field'),
                          label: 'Senha',
                          hint: '••••••••',
                          controller: _passwordController,
                          isPassword: true,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a senha';
                            }
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),

                        // ── Strength bar ──────────────────────────────────
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _PasswordStrengthBar(strength: _passwordStrength),
                        ],
                        const SizedBox(height: 16),

                        // ── Confirmar senha ───────────────────────────────
                        CadifeInput(
                          key: const ValueKey('confirm_password_field'),
                          label: 'Confirmar senha',
                          hint: '••••••••',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Confirme a senha';
                            }
                            if (v != _passwordController.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Terms checkbox ────────────────────────────────
                        GestureDetector(
                          onTap: () =>
                              setState(() => _acceptedTerms = !_acceptedTerms),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  activeColor: cadife.primary,
                                  onChanged: (v) => setState(
                                      () => _acceptedTerms = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: textSecondary),
                                    children: [
                                      const TextSpan(
                                          text: 'Li e aceito os '),
                                      TextSpan(
                                        text: 'Termos de Uso',
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                          color: cadife.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.underline,
                                          decorationColor: cadife.primary,
                                        ),
                                      ),
                                      const TextSpan(text: ' e a '),
                                      TextSpan(
                                        text: 'Política de Privacidade',
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                          color: cadife.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.underline,
                                          decorationColor: cadife.primary,
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── CRIAR CONTA button ────────────────────────────
                        CadifeButton(
                          text: 'CRIAR CONTA',
                          isLoading: isLoading,
                          onPressed: _handleRegister,
                        ),

                        // ── Error card ────────────────────────────────────
                        if (hasError) ...[
                          const SizedBox(height: 14),
                          ShadCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            backgroundColor:
                                AppColors.error.withValues(alpha: 0.08),
                            radius: BorderRadius.circular(8),
                            border: ShadBorder.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Não foi possível criar a conta. Tente novamente.',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // ── Divider ───────────────────────────────────────
                        Row(
                          children: [
                            Expanded(child: Divider(color: dividerColor)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ou',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: textSecondary),
                              ),
                            ),
                            Expanded(child: Divider(color: dividerColor)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Já tem conta? Entrar ──────────────────────────
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: textSecondary),
                              children: [
                                const TextSpan(text: 'Já tem uma conta? '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () => context.pop(),
                                    child: Text(
                                      'Entrar',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: cadife.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: cadife.primary,
                                      ),
                                    ),
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () =>
          ref.read(themeNotifierProvider.notifier).toggleDarkMode(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : context.cadife.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white24 : context.cadife.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny_rounded,
                size: 16,
                color: isDark ? Colors.white38 : AppColors.warning),
            const SizedBox(width: 6),
            Icon(Icons.nightlight_round,
                size: 16,
                color: isDark ? Colors.white : context.cadife.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    final labels = ['Muito fraca', 'Fraca', 'Razoável', 'Forte', 'Muito forte'];
    final colors = [
      AppColors.error,
      AppColors.warning,
      const Color(0xFFD4AC0D),
      AppColors.success,
      AppColors.success,
    ];

    final color = colors[strength.clamp(0, 4)];
    final label = labels[strength.clamp(0, 4)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < strength
                      ? color
                      : context.cadife.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}
