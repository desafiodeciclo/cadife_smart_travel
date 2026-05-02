import 'dart:async';
import 'dart:math' as math;

import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/core/theme/app_text_styles.dart';
import 'package:cadife_smart_travel/core/theme/cadife_theme_extension.dart';
import 'package:cadife_smart_travel/core/theme/theme_mode_provider.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/shared/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  bool _obscurePassword = true;
  // Local state — independent of the AsyncNotifier's initial loading
  bool _isLoggingIn = false;
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
    if (_isLoggingIn) return;
    if (!_formKey.currentState!.validate()) return;
    if (_emailState == _EmailState.invalid) return;

    setState(() => _isLoggingIn = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Widget _emailSuffix() => switch (_emailState) {
        _EmailState.validating => const SizedBox(
            width: 20,
            height: 20,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        _EmailState.valid =>
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        _EmailState.invalid =>
          const Icon(Icons.cancel, color: AppColors.error, size: 20),
        _EmailState.idle => const SizedBox.shrink(),
      };

  OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final cadife = context.cadife;
    final hasLoginError = ref.watch(authProvider).hasError;

    final textSecondary = isDark ? Colors.white60 : AppColors.textSecondary;
    final borderColor = isDark ? Colors.white24 : AppColors.border;
    final dividerColor = isDark ? Colors.white12 : AppColors.border;
    final labelStyle = AppTextStyles.labelSmall.copyWith(
      letterSpacing: 1.2,
      color: textSecondary,
    );

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

                        // ── E-mail label ──────────────────────────────────
                        Text('E-MAIL', style: labelStyle),
                        const SizedBox(height: 6),

                        // ── E-mail field ──────────────────────────────────
                        TextFormField(
                          key: const ValueKey('email_field'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          onChanged: _onEmailChanged,
                          decoration: InputDecoration(
                            hintText: 'seu@email.com',
                            suffixIcon: _emailSuffix(),
                            enabledBorder: _border(
                              _emailState == _EmailState.valid
                                  ? AppColors.success
                                  : _emailState == _EmailState.invalid
                                      ? AppColors.error
                                      : borderColor,
                            ),
                            focusedBorder: _border(
                              _emailState == _EmailState.invalid
                                  ? AppColors.error
                                  : cadife.primary,
                              width: 2,
                            ),
                            errorBorder: _border(AppColors.error),
                            focusedErrorBorder:
                                _border(AppColors.error, width: 2),
                          ),
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

                        // ── Senha label + Esqueci a senha ─────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SENHA', style: labelStyle),
                            GestureDetector(
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
                          ],
                        ),
                        const SizedBox(height: 6),

                        // ── Senha field ───────────────────────────────────
                        TextFormField(
                          key: const ValueKey('password_field'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _handleLogin,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            enabledBorder: _border(borderColor),
                            focusedBorder: _border(cadife.primary, width: 2),
                            errorBorder: _border(AppColors.error),
                            focusedErrorBorder:
                                _border(AppColors.error, width: 2),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a senha';
                            }
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── ENTRAR button — explicit brand color ──────────
                        // FIX: use local _isLoggingIn, not authAsync.isLoading
                        // (isLoading is true during provider init, keeping the
                        //  button disabled before the user ever touches it)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            // Keep onPressed always active — _handleLogin guards
                            // against double-submission via _isLoggingIn. This
                            // avoids Flutter's disabled-button opacity washing
                            // out the spinner against the scaffold background.
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cadife.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoggingIn
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'ENTRAR',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),

                        // ── Error message ─────────────────────────────────
                        if (hasLoginError) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
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
                              child: _SocialButton(
                                label: 'Google',
                                icon: const _GoogleIcon(),
                                isDark: isDark,
                                onTap: () => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text('Login social em breve'))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SocialButton(
                                label: 'Apple',
                                icon: Icon(
                                  Icons.apple,
                                  size: 22,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                isDark: isDark,
                                onTap: () => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text('Login social em breve'))),
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
          color: isDark ? Colors.white12 : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white24 : AppColors.border,
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
              color: isDark ? Colors.white : AppColors.textSecondary,
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(
          color: isDark ? Colors.white24 : AppColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        backgroundColor: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
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

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

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
