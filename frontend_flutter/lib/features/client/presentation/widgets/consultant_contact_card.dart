// lib/features/client/presentation/widgets/consultant_contact_card.dart

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/consultant_info.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultantContactCard extends StatelessWidget {
  final ConsultantInfo consultant;

  const ConsultantContactCard({required this.consultant, super.key});

  Future<void> _launchPhone() async {
    final uri = Uri(
      scheme: 'tel',
      path: consultant.phone.replaceAll(RegExp(r'\D'), ''),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/${consultant.phone.replaceAll(RegExp(r'\D'), '')}',
    );
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
            color: cadife.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        CadifeGlassCard(
          blur: 20,
          opacity: 0.1,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Foto circular
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(consultant.photoUrl),
                backgroundColor: AppColors.primaryLight,
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultant.name,
                      style: TextStyle(
                        color: cadife.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 13, color: cadife.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          consultant.phone,
                          style: TextStyle(
                            color: cadife.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: ContactButton(
                            label: 'Ligar',
                            icon: Icons.call,
                            color: AppColors.success,
                            onTap: _launchPhone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ContactButton(
                            label: 'WhatsApp',
                            icon: Icons.chat,
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

class ContactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ContactButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
