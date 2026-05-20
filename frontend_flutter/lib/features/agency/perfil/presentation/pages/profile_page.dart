import 'dart:math' as math;

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/entities/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/perfil/presentation/providers/profile_notifier.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ConsultorProfileScreen extends ConsumerStatefulWidget {
  const ConsultorProfileScreen({super.key});

  @override
  ConsumerState<ConsultorProfileScreen> createState() =>
      _ConsultorProfileScreenState();
}

class _ConsultorProfileScreenState
    extends ConsumerState<ConsultorProfileScreen> {
  bool _isUploading = false;

  Future<void> _onTapChangePhoto() async {
    final source = await _showPhotoSourceDialog();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (image == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar foto',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Recortar foto',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final compressed = await FlutterImageCompress.compressWithFile(
      cropped.path,
      minWidth: 512,
      minHeight: 512,
      quality: 75,
    );
    if (compressed == null || !mounted) return;

    setState(() => _isUploading = true);
    final error = await ref
        .read(consultorProfileProvider.notifier)
        .uploadPhoto(compressed, 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (!mounted) return;
    setState(() => _isUploading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<ImageSource?> _showPhotoSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.zinc300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Trocar foto de perfil', style: AppTextStyles.h4),
            const SizedBox(height: 20),
            _SourceTile(
              icon: Icons.camera_alt_outlined,
              label: 'Câmera',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Galeria',
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            _SourceTile(
              icon: Icons.close,
              label: 'Cancelar',
              onTap: () => Navigator.pop(ctx),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(consultorProfileProvider.notifier).refresh(),
      ref.read(consultantMetricsProvider.notifier).refresh(),
      ref.read(saleGoalsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(consultorProfileProvider);
    final metricsAsync = ref.watch(consultantMetricsProvider);
    final goalsAsync = ref.watch(saleGoalsProvider);

    return PageScaffold(
      appBar: CadifeAppBar(
        title: 'Meu Perfil',
        showProfile: false,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.settings, color: context.cadife.textPrimary),
            tooltip: 'Configurações',
            onPressed: () => context.push('/agency/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const _ProfileSkeleton(),
        error: (e, _) => AppErrorWidget(
          message: 'Erro ao carregar perfil',
          onRetry: () => ref.invalidate(consultorProfileProvider),
        ),
        data: (profile) => LoadingOverlay(
          isLoading: _isUploading,
          message: 'Enviando foto...',
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(
                    profile: profile,
                    onTapPhoto: _onTapChangePhoto,
                  ),
                  const SizedBox(height: 28),
                  _BioSection(profile: profile),
                  const SizedBox(height: 28),
                  _MetricsSection(metricsAsync: metricsAsync),
                  const SizedBox(height: 28),
                  _GoalsSection(goalsAsync: goalsAsync),
                  const SizedBox(height: 28),
                  _ActionsSection(profile: profile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Photo source tile ─────────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? context.cadife.textSecondary : context.cadife.textPrimary;
    return ShadCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: AppTextStyles.labelLarge.copyWith(color: color)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onTapPhoto});

  final ConsultorProfile profile;
  final VoidCallback onTapPhoto;

  @override
  Widget build(BuildContext context) {
    final initials = profile.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Column(
      children: [
        // Avatar with camera overlay
        Center(
          child: Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: ClipOval(
                  child: profile.avatarUrl != null &&
                          profile.avatarUrl!.isNotEmpty
                      ? Image.network(
                          profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _InitialsAvatar(initials: initials),
                        )
                      : _InitialsAvatar(initials: initials),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onTapPhoto,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          profile.name,
          style: AppTextStyles.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Cargo + Agência
        Text(
          profile.cargo,
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          profile.agencia,
          style: AppTextStyles.bodySmall
              .copyWith(color: context.cadife.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Contact info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined,
                size: 14, color: context.cadife.textSecondary),
            const SizedBox(width: 4),
            Text(profile.email,
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.cadife.textSecondary)),
          ],
        ),
        if (profile.phone != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_outlined,
                  size: 14, color: context.cadife.textSecondary),
              const SizedBox(width: 4),
              Text(profile.phone!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.cadife.textSecondary)),
            ],
          ),
        ],
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Bio Section ───────────────────────────────────────────────────────────────

class _BioSection extends ConsumerStatefulWidget {
  const _BioSection({required this.profile});

  final ConsultorProfile profile;

  @override
  ConsumerState<_BioSection> createState() => _BioSectionState();
}

class _BioSectionState extends ConsumerState<_BioSection> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _controller;

  static const _maxChars = 200;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bio = _controller.text.trim();
    setState(() => _saving = true);
    final error =
        await ref.read(consultorProfileProvider.notifier).updateBio(bio);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bio atualizada!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancel() {
    _controller.text = widget.profile.bio;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Minha Bio', style: AppTextStyles.h4),
            if (!_editing && !_saving)
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: Text(
                  'Editar',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_editing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) => ShadInput(
                  controller: _controller,
                  placeholder: const Text('Escreva sua bio...'),
                  maxLines: 4,
                  maxLength: _maxChars,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) {
                  final count = _controller.text.length;
                  final over = count > _maxChars;
                  return Text(
                    '$count/$_maxChars',
                    style: AppTextStyles.caption.copyWith(
                      color: over ? AppColors.error : context.cadife.textSecondary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadButton.outline(
                    onPressed: _saving ? null : _cancel,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ShadButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ],
          )
        else
          Text(
            widget.profile.bio.isEmpty
                ? 'Adicione uma bio para se apresentar aos clientes.'
                : widget.profile.bio,
            style: AppTextStyles.bodyMedium.copyWith(
              color: widget.profile.bio.isEmpty
                  ? context.cadife.textSecondary
                  : context.cadife.textPrimary,
              height: 1.6,
            ),
          ),
      ],
    );
  }
}

// ── Metrics Section ───────────────────────────────────────────────────────────

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.metricsAsync});

  final AsyncValue<ConsultantMetrics> metricsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minhas Métricas', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        metricsAsync.when(
          loading: () => const _MetricsSkeleton(),
          error: (_, _) => const _MetricsSkeleton(isEmpty: true),
          data: (metrics) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _MetricCard(
                icon: Icons.people_outline_rounded,
                value: metrics.totalLeadsAtendidos.toString(),
                label: 'Leads Atendidos',
                color: AppColors.info,
              ),
              _MetricCard(
                icon: Icons.track_changes_rounded,
                value: '${(metrics.taxaConversao * 100).toStringAsFixed(1)}%',
                label: 'Taxa de Conversão',
                color: AppColors.success,
              ),
              _MetricCard(
                icon: Icons.monetization_on_outlined,
                value: _formatCurrency(metrics.receitaGerada),
                label: 'Receita Gerada',
                color: AppColors.warning,
              ),
              _MetricCard(
                icon: Icons.local_fire_department_rounded,
                value: metrics.leadsAtivosAgora.toString(),
                label: 'Leads Ativos',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
    }
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0)
        .format(value);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      radius: BorderRadius.circular(14),
      backgroundColor: color.withValues(alpha: 0.07),
      border: ShadBorder.all(color: color.withValues(alpha: 0.18)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: context.cadife.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton({this.isEmpty = false});

  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: !isEmpty,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: context.cadife.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: isEmpty
                ? Center(
                    child: Text('—',
                        style: AppTextStyles.h4
                            .copyWith(color: context.cadife.textSecondary)),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

// ── Goals Section ─────────────────────────────────────────────────────────────

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goalsAsync});

  final AsyncValue<List<SaleGoal>> goalsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Metas — Últimos 3 Meses', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        // Legend
        const Row(
          children: [
            _LegendDot(color: AppColors.info, label: 'Meta'),
            SizedBox(width: 16),
            _LegendDot(color: AppColors.success, label: 'Realizado'),
          ],
        ),
        const SizedBox(height: 16),
        goalsAsync.when(
          loading: () => const _ChartSkeleton(),
          error: (_, _) => const _ChartSkeleton(isEmpty: true),
          data: (goals) {
            if (goals.isEmpty) {
              return const _ChartSkeleton(isEmpty: true);
            }
            return _GoalsBarChart(goals: goals.take(3).toList());
          },
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: context.cadife.textSecondary)),
      ],
    );
  }
}

class _GoalsBarChart extends StatefulWidget {
  const _GoalsBarChart({required this.goals});

  final List<SaleGoal> goals;

  @override
  State<_GoalsBarChart> createState() => _GoalsBarChartState();
}

class _GoalsBarChartState extends State<_GoalsBarChart> {
  int? _tappedIndex;

  double get _maxY {
    final values = widget.goals.expand(
      (g) => [g.target.toDouble(), g.achieved.toDouble()],
    );
    final max = values.fold<double>(0, math.max);
    return (max + 2).ceilToDouble();
  }

  void _showGoalDetail(SaleGoal goal) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalDetailSheet(goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = widget.goals;
    final maxY = _maxY;

    return ShadCard(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      radius: BorderRadius.circular(16),
      backgroundColor: context.cadife.cardBackground,
      border: ShadBorder.all(color: context.cadife.cardBorder),
      child: SizedBox(
        height: 200,
        child: BarChart(
          duration: const Duration(milliseconds: 200),
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              enabled: true,
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                if (event is FlTapUpEvent && response?.spot != null) {
                  final idx = response!.spot!.touchedBarGroupIndex;
                  setState(() => _tappedIndex = idx);
                  if (idx >= 0 && idx < goals.length) {
                    _showGoalDetail(goals[idx]);
                  }
                }
              },
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: math.max(1, (maxY / 4).ceilToDouble()),
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: context.cadife.textSecondary,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= goals.length) {
                      return const SizedBox.shrink();
                    }
                    final g = goals[idx];
                    final label = DateFormat('MMM', 'pt_BR')
                        .format(DateTime(g.year, g.month));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label[0].toUpperCase() + label.substring(1),
                        style: AppTextStyles.caption.copyWith(
                          color: context.cadife.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: math.max(1, (maxY / 4).ceilToDouble()),
              getDrawingHorizontalLine: (value) => FlLine(
                color: context.cadife.divider.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: goals.asMap().entries.map((entry) {
              final i = entry.key;
              final g = entry.value;
              final isTapped = _tappedIndex == i;
              return BarChartGroupData(
                x: i,
                barsSpace: 6,
                barRods: [
                  BarChartRodData(
                    toY: g.target.toDouble(),
                    color: AppColors.info
                        .withValues(alpha: isTapped ? 1.0 : 0.65),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  BarChartRodData(
                    toY: g.achieved.toDouble(),
                    color: g.isCompleted
                        ? AppColors.success
                            .withValues(alpha: isTapped ? 1.0 : 0.8)
                        : AppColors.primary
                            .withValues(alpha: isTapped ? 1.0 : 0.75),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _GoalDetailSheet extends StatelessWidget {
  const _GoalDetailSheet({required this.goal});

  final SaleGoal goal;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'pt_BR')
        .format(DateTime(goal.year, goal.month));
    final pct = (goal.progressPct * 100).toStringAsFixed(0);
    final color = goal.isCompleted ? AppColors.success : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.zinc300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            monthLabel[0].toUpperCase() + monthLabel.substring(1),
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 20),
          _DetailRow(
            label: 'Meta',
            value: '${goal.target} leads',
            color: AppColors.info,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Realizado',
            value: '${goal.achieved} leads',
            color: color,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Progresso',
            value: '$pct%',
            color: color,
          ),
          if (goal.receita != null) ...[
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Receita',
              value: NumberFormat.currency(
                locale: 'pt_BR',
                symbol: 'R\$',
                decimalDigits: 0,
              ).format(goal.receita),
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progressPct,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 20),
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            width: double.infinity,
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: context.cadife.textSecondary)),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton({this.isEmpty = false});

  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return ShadCard(
        padding: const EdgeInsets.all(24),
        radius: BorderRadius.circular(16),
        backgroundColor: context.cadife.cardBackground,
        border: ShadBorder.all(color: context.cadife.cardBorder),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 40, color: context.cadife.textSecondary),
              const SizedBox(height: 8),
              Text('Nenhum histórico de metas',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.cadife.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ShimmerLoading(
      isLoading: true,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: context.cadife.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Actions Section ───────────────────────────────────────────────────────────

class _ActionsSection extends ConsumerWidget {
  const _ActionsSection({required this.profile});

  final ConsultorProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.logout_rounded,
          label: 'Sair da conta',
          isDestructive: true,
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja mesmo encerrar sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/auth/login');
      }
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.error : context.cadife.textPrimary;

    return ShadCard(
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(12),
      backgroundColor: context.cadife.cardBackground,
      border: ShadBorder.all(color: context.cadife.cardBorder),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20),
        title:
            Text(label, style: AppTextStyles.labelLarge.copyWith(color: color)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: context.cadife.textSecondary, size: 18),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Full page skeleton ────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          children: [
            // Avatar skeleton
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: context.cadife.surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Skeleton(width: 180, height: 22, borderRadius: 6),
            const SizedBox(height: 6),
            const Skeleton(width: 120, height: 14, borderRadius: 4),
            const SizedBox(height: 4),
            const Skeleton(width: 140, height: 12, borderRadius: 4),
            const SizedBox(height: 28),
            // Bio skeleton
            const Skeleton(width: double.infinity, height: 80, borderRadius: 10),
            const SizedBox(height: 28),
            // Metrics skeleton
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: List.generate(
                4,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: context.cadife.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Chart skeleton
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: context.cadife.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
