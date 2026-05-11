import 'dart:async';

import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

class DailyNoteField extends StatefulWidget {
  const DailyNoteField({
    required this.initialNote,
    required this.onSave,
    super.key,
  });

  final String? initialNote;
  final Future<void> Function(String) onSave;

  @override
  State<DailyNoteField> createState() => _DailyNoteFieldState();
}

class _DailyNoteFieldState extends State<DailyNoteField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  _SaveState _saveState = _SaveState.idle;

  static const _maxLength = 500;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void didUpdateWidget(DailyNoteField old) {
    super.didUpdateWidget(old);
    if (old.initialNote != widget.initialNote &&
        _saveState == _SaveState.idle) {
      _controller.text = widget.initialNote ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _saveState = _SaveState.idle);
    _debounce = Timer(const Duration(seconds: 1), () => _triggerSave(value));
  }

  Future<void> _triggerSave(String value) async {
    if (!mounted) return;
    setState(() => _saveState = _SaveState.saving);
    try {
      await widget.onSave(value);
      if (mounted) setState(() => _saveState = _SaveState.saved);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saveState = _SaveState.idle);
    } on Exception catch (_) {
      if (mounted) setState(() => _saveState = _SaveState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxLength - (_controller.text.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Anotações do dia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _SaveIndicator(state: _saveState),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLength: _maxLength,
            maxLines: 3,
            onChanged: _onChanged,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Anotações sobre este dia...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.zinc400,
              ),
              border: InputBorder.none,
              counterText: '$remaining restantes',
              counterStyle: TextStyle(
                fontSize: 11,
                color: remaining < 50
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SaveState { idle, saving, saved, error }

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.state});

  final _SaveState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _SaveState.saving:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            SizedBox(width: 4),
            Text(
              'Salvando...',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        );
      case _SaveState.saved:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Anotação salva',
              style: TextStyle(fontSize: 11, color: AppColors.success),
            ),
          ],
        );
      case _SaveState.error:
        return const Text(
          'Erro ao salvar',
          style: TextStyle(fontSize: 11, color: AppColors.primary),
        );
      case _SaveState.idle:
        return const SizedBox.shrink();
    }
  }
}
