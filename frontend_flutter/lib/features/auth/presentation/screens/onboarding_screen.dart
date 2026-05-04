import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingSeenKey = 'onboarding_seen_v1';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingSeenKey) ?? false;
}

Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingSeenKey, true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      icon: Icons.smart_toy_outlined,
      iconColor: AppColors.primary,
      title: 'Conheça a AYA',
      subtitle:
          'A AYA é sua assistente inteligente de pré-atendimento disponível 24h pelo WhatsApp. Ela qualifica seu interesse de viagem antes de você falar com um consultor.',
    ),
    _Slide(
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: Color(0xFF2980B9),
      title: 'Atendimento por Conversa',
      subtitle:
          'Basta enviar uma mensagem no WhatsApp da Cadife Tour. A AYA irá entender seu destino, datas e preferências de forma natural, como uma conversa.',
    ),
    _Slide(
      icon: Icons.people_alt_outlined,
      iconColor: AppColors.success,
      title: 'Consultor Humano Fecha o Negócio',
      subtitle:
          'A AYA coleta seu briefing e repassa para o consultor certo. Só um especialista humano confirma disponibilidade, preços e fecha a sua viagem dos sonhos.',
    ),
    _Slide(
      icon: Icons.track_changes_rounded,
      iconColor: AppColors.warning,
      title: 'Acompanhe sua Viagem',
      subtitle:
          'No app Cadife Smart Travel você acompanha em tempo real o status da sua proposta, acessa documentos e mantém contato direto com seu consultor.',
    ),
  ];

  Future<void> _finish() async {
    await markOnboardingSeen();
    if (mounted) context.go('/auth/login');
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ──────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Pular',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),

            // ── Slides ────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // ── Dots ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── CTA button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? 'COMEÇAR' : 'PRÓXIMO',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
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

// ── Slide model ───────────────────────────────────────────────────────────────

class _Slide {
  const _Slide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
}

// ── Slide view ────────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 56, color: slide.iconColor),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
