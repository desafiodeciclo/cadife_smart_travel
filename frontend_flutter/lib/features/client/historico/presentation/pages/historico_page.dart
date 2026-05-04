import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/date_divider.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/historico_states.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/message_bubble.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/whatsapp_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  final _scrollController = ScrollController();
  bool _hasAutoScrolled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Widget> _buildTimelineItems(List<Interacao> interactions) {
    final items = <Widget>[];
    DateTime? lastDate;

    for (final msg in interactions) {
      final msgDate = DateTime(
        msg.timestamp.year,
        msg.timestamp.month,
        msg.timestamp.day,
      );
      if (lastDate == null || msgDate != lastDate) {
        items.add(DateDivider(date: msg.timestamp));
        lastDate = msgDate;
      }
      items.add(MessageBubble(interaction: msg));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final interactionsAsync = ref.watch(historicoProvider);

    ref.listen(historicoProvider, (_, next) {
      if (!_hasAutoScrolled && next.hasValue && (next.value?.isNotEmpty ?? false)) {
        _hasAutoScrolled = true;
        _scrollToBottom();
      }
    });

    return PageScaffold(
      title: 'Histórico',
      floatingActionButton: const WhatsAppFab(),
      body: interactionsAsync.when(
        loading: () => const HistoricoShimmer(),
        error: (_, s) => HistoricoErrorState(
          onRetry: () => ref.invalidate(historicoProvider),
        ),
        data: (interactions) {
          if (interactions.isEmpty) return const HistoricoEmptyState();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(historicoProvider.notifier).refresh(),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 100, bottom: 96, left: 16, right: 16),
              children: _buildTimelineItems(interactions),
            ),
          );
        },
      ),
    );
  }
}
