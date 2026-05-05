import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/schedule_appointment_provider.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ScheduleAppointmentModal extends ConsumerStatefulWidget {
  final Lead lead;

  const ScheduleAppointmentModal({super.key, required this.lead});

  static Future<bool?> show(BuildContext context, Lead lead) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleAppointmentModal(lead: lead),
    );
  }

  @override
  ConsumerState<ScheduleAppointmentModal> createState() =>
      _ScheduleAppointmentModalState();
}

class _ScheduleAppointmentModalState
    extends ConsumerState<ScheduleAppointmentModal> {
  final _monthFormat = DateFormat('MMMM yyyy');
  final _dayNameFormat = DateFormat('EEE');
  final _dayFormat = DateFormat('d');
  final _timeFormat = DateFormat('HH:mm');

  late PageController _datePageController;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _datePageController = PageController();
  }

  @override
  void dispose() {
    _datePageController.dispose();
    super.dispose();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    return List.generate(
      daysInMonth,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleAppointmentProvider);
    final notifier = ref.read(scheduleAppointmentProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // Obter dias do mês atual para o seletor
    final days = _getDaysInMonth(_currentMonth);
    // Para facilitar, focar no dia de hoje se o mês atual for o mês de hoje
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.primary),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'SCHEDULE APPOINTMENT',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: context.cadife.cardBorder, height: 1),
            const SizedBox(height: 24),

            // Lead Info Card
            ShadCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.primary.withValues(alpha: 0.05),
              radius: BorderRadius.circular(12),
              border: ShadBorder.all(color: AppColors.primary.withValues(alpha: 0.2)),
              child: Row(
                children: [
                  ShadAvatar(
                    '',
                    placeholder: const Icon(Icons.person, color: AppColors.primary),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    size: const Size(48, 48),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lead',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.cadife.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.lead.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.cadife.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: context.cadife.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              widget.lead.destino ?? 'Destino não informado',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.cadife.textSecondary,
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
            const SizedBox(height: 24),

            // Date Selector Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.cadife.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _prevMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Text(
                      _monthFormat.format(_currentMonth),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _nextMonth,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Date List
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = days[index];
                  // Desabilitar dias anteriores a hoje
                  final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
                  final isSelected = state.selectedDate.year == date.year &&
                      state.selectedDate.month == date.month &&
                      state.selectedDate.day == date.day;

                  return GestureDetector(
                    onTap: isPast ? null : () => notifier.selectDate(date),
                    child: ShadCard(
                      width: 56,
                      padding: EdgeInsets.zero,
                      backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                      radius: BorderRadius.circular(12),
                      border: ShadBorder.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : (isPast ? context.cadife.cardBorder.withValues(alpha: 0.5) : context.cadife.cardBorder),
                        width: isSelected ? 2 : 1,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayNameFormat.format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected 
                                  ? AppColors.primary 
                                  : (isPast ? context.cadife.textSecondary.withValues(alpha: 0.5) : context.cadife.textSecondary),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dayFormat.format(date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected 
                                  ? AppColors.primary 
                                  : (isPast ? context.cadife.textPrimary.withValues(alpha: 0.3) : context.cadife.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Available Times Header
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: context.cadife.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Available Times',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.cadife.textPrimary,
                  ),
                ),
                if (state.isLoading) ...[
                  const Spacer(),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 16),

            // Time Slots Grid
            if (!state.isLoading && state.availableSlots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Nenhum horário disponível para esta data.'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: state.availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = state.availableSlots[index];
                  final isSelected = state.selectedSlot == slot;
                  
                  return GestureDetector(
                    onTap: slot.available ? () => notifier.selectSlot(slot) : null,
                    child: ShadCard(
                      padding: EdgeInsets.zero,
                      backgroundColor: isSelected 
                          ? AppColors.primary 
                          : (slot.available ? Colors.transparent : context.cadife.cardBorder.withValues(alpha: 0.3)),
                      radius: BorderRadius.circular(8),
                      border: ShadBorder.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : (slot.available ? context.cadife.cardBorder : context.cadife.cardBorder.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          _timeFormat.format(slot.startTime),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected 
                                ? Colors.white 
                                : (slot.available ? context.cadife.textPrimary : context.cadife.textSecondary.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Erro ao carregar horários: ${state.error}',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 32),

            // Actions
            ShadButton(
              onPressed: state.selectedSlot != null && !state.isLoading
                  ? () async {
                      final success = await notifier.confirmAppointment(widget.lead.id);
                      if (success && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  : null,
              leading: state.isLoading && state.selectedSlot != null
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              child: const Text('CONFIRM SCHEDULE'),
            ),
            const SizedBox(height: 8),
            ShadButton.outline(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
