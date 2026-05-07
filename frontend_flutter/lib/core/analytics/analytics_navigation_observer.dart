import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:flutter/material.dart';

class AnalyticsNavigationObserver extends RouteObserver<ModalRoute<void>> {
  final AnalyticsService _analytics = sl<AnalyticsService>();

  @override
  void didPush(Route<void> route, Route<void>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreen(route);
  }

  @override
  void didReplace({Route<void>? newRoute, Route<void>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logScreen(newRoute);
    }
  }

  @override
  void didPop(Route<void> route, Route<void>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logScreen(previousRoute);
    }
  }

  void _logScreen(Route<void> route) {
    final screenName = route.settings.name;
    if (screenName != null) {
      _analytics.logScreenView(screenName);
    }
  }
}
