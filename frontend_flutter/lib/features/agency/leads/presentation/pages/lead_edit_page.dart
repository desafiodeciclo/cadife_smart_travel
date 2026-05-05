import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela de edição de lead — Fase 4.2
/// Permite atualizar nome, status e score de um lead existente.
class LeadEditPage extends ConsumerStatefulWidget {
  final String leadId;
  const LeadEditPage({super.key, required this.leadId});

  @override
  ConsumerState<LeadEditPage> createState() => _LeadEditPageState();
}

class _LeadEditPageState extends ConsumerState<LeadEditPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  String _status = 'novo';
  String? _score;
  bool _saving = false;

  static const _statusOptions = [
    'novo',
    'em_atendimento',
    'qualificado',
    'agendado',
    'proposta',
    'fechado',
    'perdido',
  ];

  static const _scoreOptions = ['quente', 'morno', 'frio'];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Simulate async save — replace with actual repository call
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead atualizado com sucesso!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header gradient ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Editar Lead',
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

          // ── Form body ────────────────────────────────────────────────────
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
                              label: 'Dados Básicos',
                            ),
                            const SizedBox(height: 16),

                            // Nome
                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome do lead',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 20),

                            // Status
                            const _SectionHeader(
                              icon: Icons.flag_outlined,
                              label: 'Status',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _statusOptions.map((s) {
                                final selected = _status == s;
                                final color = AppColors.statusColor(s);
                                return AnimatedScale(
                                  scale: selected ? 1.05 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: FilterChip(
                                    label: Text(
                                      s.replaceAll('_', ' '),
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _status = s),
                                    backgroundColor:
                                        color.withValues(alpha: 0.1),
                                    selectedColor: color,
                                    checkmarkColor: Colors.white,
                                    side: BorderSide(color: color),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Score
                            const _SectionHeader(
                              icon: Icons.local_fire_department_outlined,
                              label: 'Temperatura (Score)',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: _scoreOptions.map((sc) {
                                final selected = _score == sc;
                                final icon = sc == 'quente'
                                    ? Icons.whatshot_rounded
                                    : sc == 'morno'
                                        ? Icons.thermostat_rounded
                                        : Icons.ac_unit_rounded;
                                final color = sc == 'quente'
                                    ? Colors.deepOrange
                                    : sc == 'morno'
                                        ? Colors.amber
                                        : Colors.blueAccent;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: sc != 'frio' ? 8 : 0),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? color.withValues(alpha: 0.15)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: selected
                                              ? color
                                              : Colors.grey.shade400,
                                          width: selected ? 2 : 1,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        onTap: () => setState(() =>
                                            _score = selected ? null : sc),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Column(
                                            children: [
                                              Icon(icon,
                                                  color: selected
                                                      ? color
                                                      : Colors.grey,
                                                  size: 22),
                                              const SizedBox(height: 4),
                                              Text(
                                                sc,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: selected
                                                      ? color
                                                      : Colors.grey,
                                                  fontWeight: selected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Save button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _saving ? null : _save,
                            child: Center(
                              child: _saving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Salvar Alterações',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
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
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

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
