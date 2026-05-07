import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/home_page_data.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultantContactCard extends StatelessWidget {
  const ConsultantContactCard({required this.consultant, super.key});

  final ConsultantInfo consultant;

  String get _cleanPhone => consultant.phone.replaceAll(RegExp(r'\D'), '');

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: _cleanPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seu Consultor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: cadife.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        CadifeGlassCard(
          blur: 20,
          opacity: 0.07,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ConsultantAvatar(consultant: consultant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultant.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cadife.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: cadife.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            consultant.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: cadife.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ContactButton(
                            label: 'Ligar',
                            icon: Icons.call_outlined,
                            color: AppColors.success,
                            onTap: _launchPhone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ContactButton(
                            label: 'WhatsApp',
                            icon: Icons.chat_outlined,
                            color: const Color(0xFF25D366),
                            onTap: _launchWhatsApp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsultantAvatar extends StatelessWidget {
  const _ConsultantAvatar({required this.consultant});

  final ConsultantInfo consultant;

  @override
  Widget build(BuildContext context) {
    final url = consultant.photoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 34,
        backgroundImage: NetworkImage(url),
        backgroundColor: AppColors.primaryLight,
      );
    }
    return CircleAvatar(
      radius: 34,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        consultant.initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
