import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnalyticsBlocObserver extends BlocObserver {
  final AnalyticsService _analytics = sl<AnalyticsService>();

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    
    final newState = transition.nextState;
    
    if (newState is AuthAuthenticated) {
      final user = newState.user;
      _analytics.setUser(user.id);
      _analytics.logEvent('user_login', parameters: {
        'user_role': user.role.name,
        'user_id': user.id, // Redacted by sanitize anyway, but good to have
      });
    } else if (newState is AuthUnauthenticated && transition.currentState is AuthAuthenticated) {
      _analytics.setUser(null);
      _analytics.logEvent('user_logout');
    } else if (newState is AuthFailure) {
      _analytics.logEvent('auth_failure', parameters: {
        'error': newState.message,
      });
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _analytics.logError(error, stackTrace);
  }
}
