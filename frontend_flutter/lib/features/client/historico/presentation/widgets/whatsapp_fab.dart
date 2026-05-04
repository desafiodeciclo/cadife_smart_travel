import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _kCadifeWhatsApp = '5511999999999';

class WhatsAppFab extends StatelessWidget {
  const WhatsAppFab({super.key});

  Future<void> _launch() async {
    final uri = Uri.parse(
      'https://wa.me/$_kCadifeWhatsApp'
      '?text=Olá!%20Gostaria%20de%20continuar%20meu%20atendimento.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _launch,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.chat_bubble_outline_rounded),
      label: const Text(
        'Continuar no WhatsApp',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
