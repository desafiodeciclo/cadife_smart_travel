import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Mock local state for demonstration of "working" toggles
  bool _notifLead = true;
  bool _notifSchedule = true;
  bool _notifProposals = true;
  String _selectedTheme = 'Automático';
  String _selectedCurrency = 'BRL (R\$)';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Usuário não autenticado')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.cardBackground,
          appBar: AppBar(
            title: const Text(
              'CONFIGURAÇÕES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEÇÃO: Notificações (genérica)
                _buildSection(
                  title: 'NOTIFICAÇÕES',
                  children: [
                    _buildSettingToggle(
                      label: 'Novo Lead Qualificado',
                      description: 'Receber notificação quando um lead é qualificado',
                      initialValue: _notifLead,
                      onChanged: (value) => setState(() => _notifLead = value),
                    ),
                    _buildSettingToggle(
                      label: 'Agendamento Confirmado',
                      description: 'Receber notificação quando cliente confirma horário',
                      initialValue: _notifSchedule,
                      onChanged: (value) => setState(() => _notifSchedule = value),
                    ),
                    _buildSettingToggle(
                      label: 'Propostas Atualizadas',
                      description: 'Receber notificação sobre status de propostas',
                      initialValue: _notifProposals,
                      onChanged: (value) => setState(() => _notifProposals = value),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SEÇÃO: Horários de Trabalho (apenas consultor)
                if (user.role == UserRole.consultor)
                  _buildSection(
                    title: 'HORÁRIOS DE TRABALHO',
                    children: [
                      _buildTimeInput(
                        label: 'Início',
                        initialTime: _startTime,
                        onChanged: (time) => setState(() => _startTime = time),
                      ),
                      const SizedBox(height: 12),
                      _buildTimeInput(
                        label: 'Fim',
                        initialTime: _endTime,
                        onChanged: (time) => setState(() => _endTime = time),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text(
                          'Dias de trabalho: Seg-Sex',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (user.role == UserRole.consultor)
                  const SizedBox(height: 24),

                if (user.role == UserRole.consultor)
                  _buildSection(
                    title: 'TEMPLATES DE RESPOSTA',
                    children: [
                      _buildSettingButton(
                        label: 'Gerenciar Templates',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gerenciamento de templates em breve')),
                          );
                        },
                      ),
                    ],
                  ),

                // SEÇÃO: Preferências de Viagem (apenas cliente)
                if (user.role == UserRole.cliente)
                  _buildSection(
                    title: 'PREFERÊNCIAS DE VIAGEM',
                    children: [
                      _buildSettingButton(
                        label: 'Estilo de Viagem',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Configuração de estilo em breve')),
                          );
                        },
                      ),
                      _buildSettingOption(
                        label: 'Moeda Preferencial',
                        options: ['BRL (R\$)', 'USD (\$)', 'EUR (€)'],
                        initialValue: _selectedCurrency,
                        onChanged: (value) => setState(() => _selectedCurrency = value),
                      ),
                    ],
                  ),

                if (user.role == UserRole.consultor || user.role == UserRole.cliente)
                  const SizedBox(height: 24),

                // SEÇÃO: Tema (genérica)
                _buildSection(
                  title: 'APARÊNCIA',
                  children: [
                    _buildSettingOption(
                      label: 'Tema',
                      options: ['Claro', 'Escuro', 'Automático'],
                      initialValue: _selectedTheme,
                      onChanged: (value) => setState(() => _selectedTheme = value),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SEÇÃO: Segurança (genérica)
                _buildSection(
                  title: 'SEGURANÇA',
                  children: [
                    _buildSettingButton(
                      label: 'Alterar Senha',
                      onTap: () => _showChangePasswordModal(context),
                    ),
                    _buildSettingButton(
                      label: 'Logout em Todos os Dispositivos',
                      onTap: () => _showLogoutAllModal(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SEÇÃO: Informações (genérica)
                _buildSection(
                  title: 'INFORMAÇÕES',
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Versão: 1.0.0',
                            style: TextStyle(fontSize: 13),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Desenvolvido por Cadife Smart Travel',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Botão Logout
                ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('FAZER LOGOUT'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingToggle({
    required String label,
    required String description,
    required bool initialValue,
    required void Function(bool value) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${initialTime.hour}:${initialTime.minute.toString().padLeft(2, '0')}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingOption({
    required String label,
    required List<String> options,
    required String initialValue,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: initialValue,
                isExpanded: true,
                items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => onChanged(value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Senha Atual'),
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Nova Senha'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Senha alterada com sucesso')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout em Todos os Dispositivos'),
        content: const Text('Você será desconectado de todos os seus dispositivos'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go('/auth/login');
  }
}
