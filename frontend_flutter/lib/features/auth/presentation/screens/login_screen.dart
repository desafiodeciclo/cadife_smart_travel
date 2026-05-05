import 'dart:async';
import 'dart:math' as math;

import 'package:cadife_smart_travel/core/utils/extensions/string_extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _EmailState { idle, validating, valid, invalid }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _EmailState _emailState = _EmailState.idle;
  Timer? _emailDebounce;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state is AuthLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_emailState == _EmailState.invalid) return;

    context.read<AuthBloc>().add(AuthEvent.loginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }




  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final cadife = context.cadife;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          authenticated: (user) {
            // GoRouter handles redirection automatically via refreshListenable
          },
          failure: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          orElse: () {},
        );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoggingIn = state is AuthLoading;
          final hasLoginError = state is AuthFailure;

          final textSecondary = isDark ? Colors.white60 : context.cadife.textSecondary;
          final dividerColor = isDark ? Colors.white12 : context.cadife.cardBorder;

    // ── FIX: Column layout instead of Stack — avoids unbounded constraints
    //         and hit-testing issues that blocked all interactions.
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Theme toggle — always on top, never behind ScrollView ──────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12, bottom: 4),
                child: _ThemeToggle(isDark: isDark),
              ),
            ),

            // ── Scrollable form body ──────────────────────────────────────
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
                        Center(child: _CadifeLogo(isDark: isDark)),
                        const SizedBox(height: 28),

                        // ── Heading ───────────────────────────────────────
                        Text(
                          'Smart Travel',
                          style: AppTextStyles.h2.copyWith(
                            color: cadife.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Faça login para continuar',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 32),

                        // ── E-mail field ──────────────────────────────────
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
                        const SizedBox(height: 20),

                        // ── Esqueci a senha ─────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () =>
                                context.push('/auth/forgot-password'),
                            child: Text(
                              'Esqueci a senha',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: cadife.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: cadife.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ── Senha field ───────────────────────────────────
                        CadifeInput(
                          key: const ValueKey('password_field'),
                          label: 'Senha',
                          hint: '••••••••',
                          controller: _passwordController,
                          isPassword: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a senha';
                            }
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── ENTRAR button ──────────────────
                        CadifeButton(
                          text: 'ENTRAR',
                          isLoading: isLoggingIn,
                          onPressed: _handleLogin,
                        ),

                        // ── Error message ─────────────────────────────────
                        if (hasLoginError) ...[
                          const SizedBox(height: 14),
                          ShadCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            backgroundColor: AppColors.error.withValues(alpha: 0.08),
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
                                    'E-mail ou senha incorretos. Tente novamente.',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // ── Divider "ou" ──────────────────────────────────
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

                        // ── Social buttons ────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: ShadButton.outline(
                                onPressed: () => ShadToaster.of(context).show(
                                  const ShadToast(description: Text('Login social em breve')),
                                ),
                                leading: const _GoogleIcon(),
                                child: const Text('Google'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ShadButton.outline(
                                onPressed: () => ShadToaster.of(context).show(
                                  const ShadToast(description: Text('Login social em breve')),
                                ),
                                leading: Icon(
                                  Icons.apple,
                                  size: 20,
                                  color: isDark ? Colors.white : context.cadife.textPrimary,
                                ),
                                child: const Text('Apple'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Sign-up CTA ───────────────────────────────────
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: textSecondary),
                              children: [
                                const TextSpan(text: 'Não tem uma conta? '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.push('/auth/register'),
                                    child: Text(
                                      'Cadastre-se',
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
        },
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
      onTap: () {
        if (isDark) {
          ref.read(themeModeProvider.notifier).setLight();
        } else {
          ref.read(themeModeProvider.notifier).setDark();
        }
      },
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
            Icon(
              Icons.wb_sunny_rounded,
              size: 16,
              color: isDark ? Colors.white38 : AppColors.warning,
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.nightlight_round,
              size: 16,
              color: isDark ? Colors.white : context.cadife.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CadifeLogo extends StatelessWidget {
  const _CadifeLogo({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final asset = isDark
        ? 'assets/images/cadife_logo_negativo.svg'
        : 'assets/images/cadife_logo_positivo.svg';

    return SvgPicture.asset(
      asset,
      width: 200,
      height: 100,
      fit: BoxFit.contain,
    );
  }
}



class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

// Draws the Google "G" logo using four colored arcs + right-side horizontal bar
class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();

  static const _blue   = AppColors.googleBlue;
  static const _green  = AppColors.googleGreen;
  static const _yellow = AppColors.googleYellow;
  static const _red    = AppColors.googleRed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    const strokeW = 3.5;
    final arcR = r - strokeW / 2;

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt;
      const toRad = math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: arcR),
        startDeg * toRad,
        sweepDeg * toRad,
        false,
        paint,
      );
    }

    // Four colored arc segments of the Google G ring
    arc(-30, 120, _blue);   // top-right (blue)
    arc(90, 120, _green);   // bottom (green)
    arc(210, 90, _yellow);  // bottom-left (yellow)
    arc(300, 30, _red);     // top-left (red)

    // Horizontal bar inside the G (right half)
    final barPaint = Paint()
      ..color = _blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + arcR, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
