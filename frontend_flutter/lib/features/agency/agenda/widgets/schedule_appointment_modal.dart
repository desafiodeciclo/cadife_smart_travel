import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/features/agency/agenda/providers/schedule_appointment_provider.dart';
import 'package:cadife_smart_travel/shared/models/agenda_model.dart';
import 'package:cadife_smart_travel/shared/models/lead_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ScheduleAppointmentModal extends ConsumerStatefulWidget {
  final LeadModel lead;

  const ScheduleAppointmentModal({super.key, required this.lead});

  static Future<bool?> show(BuildContext context, LeadModel lead) {
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
    final isCurrentMonth = _currentMonth.year == today.year && _currentMonth.month == today.month;

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
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 24),

            // Lead Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    radius: 24,
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lead',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.lead.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              widget.lead.destino ?? 'Destino não informado',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
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
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primary 
                              : (isPast ? AppColors.border.withValues(alpha: 0.5) : AppColors.border),
                          width: isSelected ? 2 : 1,
                        ),
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
                                  : (isPast ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary),
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
                                  : (isPast ? AppColors.textPrimary.withValues(alpha: 0.3) : AppColors.textPrimary),
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
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Available Times',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primary 
                            : (slot.available ? Colors.transparent : AppColors.border.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primary 
                              : (slot.available ? AppColors.border : AppColors.border.withValues(alpha: 0.3)),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _timeFormat.format(slot.startTime),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : (slot.available ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5)),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.border,
              ),
              onPressed: state.selectedSlot != null && !state.isLoading
                  ? () async {
                      final success = await notifier.confirmAppointment(widget.lead.id);
                      if (success && mounted) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  : null,
              icon: state.isLoading && state.selectedSlot != null
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'CONFIRM SCHEDULE',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
