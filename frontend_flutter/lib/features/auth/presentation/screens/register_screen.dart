import 'dart:async';

import 'package:cadife_smart_travel/core/constants/assets_constants.dart';
import 'package:cadife_smart_travel/core/constants/legal_constants.dart';
import 'package:cadife_smart_travel/core/utils/extensions/string_extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _EmailState { idle, validating, valid, invalid }

enum _PhoneState { idle, valid, invalid }

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
  _PhoneState _phoneState = _PhoneState.idle;
  Timer? _phoneDebounce;
  bool _acceptedTerms = false;

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _showLegalModal(
            LegalConstants.termsOfUseTitle,
            LegalConstants.termsOfUseContent,
          );
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _showLegalModal(
            LegalConstants.privacyPolicyTitle,
            LegalConstants.privacyPolicyContent,
          );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailDebounce?.cancel();
    _phoneDebounce?.cancel();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
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

  void _onPhoneChanged(String value) {
    _phoneDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _phoneState = _PhoneState.idle);
      return;
    }
    _phoneDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _phoneState = value.trim().isValidPhone
            ? _PhoneState.valid
            : _PhoneState.invalid;
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

  void _showLegalModal(String title, String content) {
    showShadDialog(
      context: context,
      builder: (context) {
        final cadife = context.cadife;
        return ShadDialog(
          title: Text(title, style: AppTextStyles.h3),
          description: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Última atualização: Maio 2026',
                  style: AppTextStyles.labelSmall.copyWith(color: cadife.textSecondary),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cadife.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ShadButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('FECHAR'),
            ),
          ],
        );
      },
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
                        if (_emailState == _EmailState.validating) ...[
                          const SizedBox(height: 4),
                          const _InlineValidationHint(
                            isLoading: true,
                            text: 'Verificando...',
                          ),
                        ] else if (_emailState == _EmailState.valid) ...[
                          const SizedBox(height: 4),
                          const _InlineValidationHint(
                            isValid: true,
                            text: 'E-mail válido',
                          ),
                        ] else if (_emailState == _EmailState.invalid) ...[
                          const SizedBox(height: 4),
                          const _InlineValidationHint(
                            isValid: false,
                            text: 'Formato de e-mail inválido',
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ── Telefone ──────────────────────────────────────
                        CadifeInput(
                          key: const ValueKey('phone_field'),
                          label: 'Telefone',
                          hint: '(11) 9 0000-0000',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: _onPhoneChanged,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o telefone';
                            }
                            if (!v.trim().isValidPhone) {
                              return 'Telefone inválido — informe DDD + número (10 ou 11 dígitos)';
                            }
                            return null;
                          },
                        ),
                        if (_phoneState == _PhoneState.valid) ...[
                          const SizedBox(height: 4),
                          const _InlineValidationHint(
                            isValid: true,
                            text: 'Telefone válido',
                          ),
                        ] else if (_phoneState == _PhoneState.invalid) ...[
                          const SizedBox(height: 4),
                          const _InlineValidationHint(
                            isValid: false,
                            text: 'Informe DDD + número (10 ou 11 dígitos)',
                          ),
                        ],
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
                            if (v.length < 8) return 'Mínimo 8 caracteres';
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
                                        recognizer: _termsRecognizer,
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
                                        recognizer: _privacyRecognizer,
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

class _InlineValidationHint extends StatelessWidget {
  const _InlineValidationHint({
    required this.text,
    this.isValid,
    this.isLoading = false,
  });

  final String text;
  final bool? isValid;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: context.cadife.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.cadife.textSecondary,
            ),
          ),
        ],
      );
    }

    final color = isValid == true ? AppColors.success : AppColors.error;
    final icon = isValid == true
        ? Icons.check_circle_outline
        : Icons.error_outline;

    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ),
      ],
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
