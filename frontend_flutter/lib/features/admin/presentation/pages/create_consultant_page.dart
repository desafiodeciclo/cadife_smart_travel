import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateConsultantPage extends ConsumerStatefulWidget {
  const CreateConsultantPage({super.key});

  @override
  ConsumerState<CreateConsultantPage> createState() => _CreateConsultantPageState();
}

class _CreateConsultantPageState extends ConsumerState<CreateConsultantPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
    });

    var isValid = true;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      _nameError = 'Informe o nome';
      isValid = false;
    } else if (name.length < 3) {
      _nameError = 'Nome muito curto';
      isValid = false;
    }

    if (email.isEmpty) {
      _emailError = 'Informe o e-mail';
      isValid = false;
    } else {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(email)) {
        _emailError = 'E-mail inválido';
        isValid = false;
      }
    }

    if (phone.isEmpty) {
      _phoneError = 'Informe o telefone';
      isValid = false;
    } else if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      _phoneError = 'Telefone inválido';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Informe a senha';
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = 'A senha deve ter pelo menos 6 caracteres';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    await ref.read(adminConsultoresNotifierProvider.notifier).createConsultor(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Consultor criado com sucesso!'),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      appBar: const CadifeAppBar(
        title: 'Criar Consultor',
        showProfile: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados do Consultor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Preencha os dados abaixo para cadastrar o novo consultor no sistema.',
              style: TextStyle(
                fontSize: 13,
                color: context.cadife.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ShadInput(
              controller: _nameController,
              placeholder: const Text('Nome completo'),
              leading: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(LucideIcons.user, size: 18),
              ),
            ),
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _nameError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            ShadInput(
              controller: _emailController,
              placeholder: const Text('E-mail corporativo'),
              leading: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(LucideIcons.mail, size: 18),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_emailError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _emailError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            ShadInput(
              controller: _phoneController,
              placeholder: const Text('Telefone / WhatsApp'),
              leading: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(LucideIcons.phone, size: 18),
              ),
              keyboardType: TextInputType.phone,
            ),
            if (_phoneError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _phoneError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            ShadInput(
              controller: _passwordController,
              placeholder: const Text('Senha de acesso'),
              obscureText: _obscurePassword,
              leading: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(LucideIcons.lock, size: 18),
              ),
              trailing: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: context.cadife.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            if (_passwordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _passwordError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CadifeButton(
                text: 'Criar Consultor',
                icon: LucideIcons.userPlus,
                analyticsLabel: 'admin_create_consultor',
                onPressed: _isLoading ? null : _submit,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
