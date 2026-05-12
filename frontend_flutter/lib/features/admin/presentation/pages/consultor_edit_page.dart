import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConsultorEditPage extends ConsumerStatefulWidget {
  final String consultorId;
  const ConsultorEditPage({required this.consultorId, super.key});

  @override
  ConsumerState<ConsultorEditPage> createState() => _ConsultorEditPageState();
}

class _ConsultorEditPageState extends ConsumerState<ConsultorEditPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool _isActive = true;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _initializeData(ConsultorAdmin consultor) {
    if (_initialized) return;
    _nomeController.text = consultor.name;
    _emailController.text = consultor.email;
    _phoneController.text = consultor.phone;
    _isActive = consultor.isActive;
    _initialized = true;
  }

  Future<void> _save(ConsultorAdmin original) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final updated = original.copyWith(
        name: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        isActive: _isActive,
      );

      await ref
          .read(adminConsultoresNotifierProvider.notifier)
          .updateConsultor(updated);
      ref.invalidate(consultorDetailProvider(widget.consultorId));

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Consultor atualizado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Erro ao atualizar consultor: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final consultorAsync = ref.watch(consultorDetailProvider(widget.consultorId));

    return consultorAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erro: $err'))),
      data: (consultor) {
        if (consultor == null) {
          return const Scaffold(
            body: Center(child: Text('Consultor não encontrado')),
          );
        }
        _initializeData(consultor);

        return PageScaffold(
          showBackgroundEffects: false,
          extendBodyBehindAppBar: false,
          useSafeArea: false,
          body: CustomScrollView(
            slivers: [
              // ── Header gradient ────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Editar Consultor',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: cs.onPrimary,
                  onPressed: () => context.pop(),
                ),
              ),

              // ── Form body ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionHeader(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Dados do Consultor',
                                ),
                                const SizedBox(height: 16),

                                // Nome
                                CadifeInput(
                                  label: 'Nome completo',
                                  hint: 'Nome completo',
                                  controller: _nomeController,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Campo obrigatório'
                                          : v.trim().length < 3
                                              ? 'Nome muito curto'
                                              : null,
                                ),
                                const SizedBox(height: 20),

                                // E-mail
                                CadifeInput(
                                  label: 'E-mail corporativo',
                                  hint: 'consultor@cadifetour.com.br',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Campo obrigatório';
                                    }
                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                    if (!emailRegex.hasMatch(v.trim())) {
                                      return 'E-mail inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Telefone
                                CadifeInput(
                                  label: 'Telefone / WhatsApp',
                                  hint: '+55 (00) 00000-0000',
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Campo obrigatório';
                                    }
                                    if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                                      return 'Telefone inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Status
                                const _SectionHeader(
                                  icon: Icons.toggle_on_outlined,
                                  label: 'Status',
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatusOption(
                                        label: 'Ativo',
                                        icon: LucideIcons.userCheck,
                                        color: AppColors.success,
                                        selected: _isActive,
                                        onTap: () => setState(() => _isActive = true),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatusOption(
                                        label: 'Inativo',
                                        icon: LucideIcons.userX,
                                        color: AppColors.zinc400,
                                        selected: !_isActive,
                                        onTap: () => setState(() => _isActive = false),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Save button
                          CadifeButton(
                            text: 'Salvar Alterações',
                            icon: LucideIcons.save,
                            isLoading: _saving,
                            analyticsLabel: 'consultor_edit_save',
                            onPressed: _saving ? null : () => _save(consultor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Reusable widgets ──────────────────────────────────────────────────────────

class _StatusOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
        border: Border.all(
          color: selected ? color : Colors.grey.shade400,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? color : Colors.grey,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
