import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cadife.background,
      appBar: AppBar(
        backgroundColor: cadife.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: cadife.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Configurações',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cadife.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(LucideIcons.user, color: cadife.textPrimary),
            title: Text('Conta', style: TextStyle(color: cadife.textPrimary)),
            trailing: Icon(LucideIcons.chevronRight, color: cadife.textSecondary),
            onTap: () {
              ShadToaster.of(context).show(
                const ShadToast(description: Text('Configurações de conta em breve')),
              );
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.bell, color: cadife.textPrimary),
            title: Text('Notificações', style: TextStyle(color: cadife.textPrimary)),
            trailing: Icon(LucideIcons.chevronRight, color: cadife.textSecondary),
            onTap: () {
              ShadToaster.of(context).show(
                const ShadToast(description: Text('Configurações de notificações em breve')),
              );
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.shield, color: cadife.textPrimary),
            title: Text('Privacidade e Segurança', style: TextStyle(color: cadife.textPrimary)),
            trailing: Icon(LucideIcons.chevronRight, color: cadife.textSecondary),
            onTap: () {
              ShadToaster.of(context).show(
                const ShadToast(description: Text('Privacidade e Segurança em breve')),
              );
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.info, color: cadife.textPrimary),
            title: Text('Sobre o app', style: TextStyle(color: cadife.textPrimary)),
            trailing: Icon(LucideIcons.chevronRight, color: cadife.textSecondary),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Cadife Smart Travel',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }
}
