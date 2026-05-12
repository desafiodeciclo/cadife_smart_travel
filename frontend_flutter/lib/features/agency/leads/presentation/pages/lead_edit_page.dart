import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/lead_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tela de edição de lead — Fase 4.2
/// Permite atualizar nome, telefone, email, status e score de um lead existente.
class LeadEditPage extends ConsumerStatefulWidget {
  final String leadId;
  const LeadEditPage({required this.leadId, super.key});

  @override
  ConsumerState<LeadEditPage> createState() => _LeadEditPageState();
}

class _LeadEditPageState extends ConsumerState<LeadEditPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  String _status = 'novo';
  String? _score;
  bool _saving = false;
  bool _initialized = false;

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
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _initializeData(Lead lead) {
    if (_initialized) return;
    _nomeController.text = lead.name;
    _phoneController.text = lead.phone;
    _emailController.text = lead.email ?? '';
    _status = lead.status.name;
    _score = lead.score.name;
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    
    try {
      await ref.read(leadDetailProvider(widget.leadId).notifier).updateLead(
        name: _nomeController.text,
        phone: _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        status: LeadStatus.values.firstWhere((e) => e.name == _status),
        score: _score != null ? LeadScore.values.firstWhere((e) => e.name == _score) : null,
      );

      // Status e Score se alterados (opcional, dependendo se o backend suporta tudo num patch só)
      // Por enquanto vamos focar no que o usuário pediu explicitamente: nome, telefone e email.
      // Mas já que temos status e score na UI, vamos atualizar também se o notifier suportar.
      // O notifier que criei só aceita name, phone, email. Vamos manter assim por simplicidade
      // ou atualizar o notifier para aceitar mais campos.
      
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Lead atualizado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
       if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Erro ao atualizar lead: $e'),
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
    final leadAsync = ref.watch(leadDetailProvider(widget.leadId));

    return leadAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro: $err'))),
      data: (lead) {
        if (lead == null) return const Scaffold(body: Center(child: Text('Lead não encontrado')));
        _initializeData(lead);

        return PageScaffold(
          showBackgroundEffects: false,
          extendBodyBehindAppBar: false,
          useSafeArea: false,
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
                                CadifeInput(
                                  label: 'Nome do lead',
                                  hint: 'Nome completo',
                                  controller: _nomeController,
                                  validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
                                ),
                                const SizedBox(height: 20),

                                // Telefone
                                CadifeInput(
                                  label: 'Telefone',
                                  hint: '(00) 00000-0000',
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
                                ),
                                const SizedBox(height: 20),

                                // Email
                                CadifeInput(
                                  label: 'E-mail',
                                  hint: 'exemplo@email.com',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
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
                          CadifeButton(
                            text: 'Salvar Alterações',
                            isLoading: _saving,
                            analyticsLabel: 'lead_edit_save',
                            onPressed: _saving ? null : _save,
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
