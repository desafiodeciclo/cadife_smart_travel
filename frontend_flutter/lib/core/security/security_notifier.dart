import 'dart:async';

import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/core/security/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityState {
  final bool isLocked;
  final DateTime? lastActive;

  SecurityState({this.isLocked = false, this.lastActive});

  SecurityState copyWith({bool? isLocked, DateTime? lastActive}) {
    return SecurityState(
      isLocked: isLocked ?? this.isLocked,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> with WidgetsBindingObserver {
  final BiometricService _biometricService;
  static const int lockTimeoutMinutes = 5;

  SecurityNotifier(this._biometricService) : super(SecurityState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      this.state = this.state.copyWith(lastActive: DateTime.now());
    } else if (state == AppLifecycleState.resumed) {
      _checkLock();
    }
  }

  void _checkLock() {
    if (state.lastActive != null) {
      final difference = DateTime.now().difference(state.lastActive!);
      if (difference.inMinutes >= lockTimeoutMinutes) {
        state = state.copyWith(isLocked: true);
      }
    }
  }

  Future<bool> unlock() async {
    final success = await _biometricService.authenticate();
    if (success) {
      state = state.copyWith(isLocked: false, lastActive: DateTime.now());
    }
    return success;
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  return SecurityNotifier(sl<BiometricService>());
});
