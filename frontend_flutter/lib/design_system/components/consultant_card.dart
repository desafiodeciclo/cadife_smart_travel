import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultantCard extends StatelessWidget {
  const ConsultantCard({
    super.key,
    this.consultantName = 'Ricardo Silva',
    this.consultantTitle = 'Cadife Tour Experiências',
    this.whatsappNumber = '5511999999999',
    this.avatarUrl,
  });

  final String consultantName;
  final String consultantTitle;
  final String whatsappNumber;
  final String? avatarUrl;

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/$whatsappNumber'
      '?text=Ol%C3%A1!%20Gostaria%20de%20informa%C3%A7%C3%B5es%20sobre%20minha%20viagem.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEU CONSULTOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _ConsultantAvatar(avatarUrl: avatarUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultantName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            consultantTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _WhatsAppButton(onPressed: _openWhatsApp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultantAvatar extends StatelessWidget {
  const _ConsultantAvatar({this.avatarUrl});
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
      child: Icon(Icons.person, color: theme.primaryColor, size: 28),
    );
  }
}

class _WhatsAppButton extends StatefulWidget {
  const _WhatsAppButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_WhatsAppButton> createState() => _WhatsAppButtonState();
}

class _WhatsAppButtonState extends State<_WhatsAppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Falar no WhatsApp',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
