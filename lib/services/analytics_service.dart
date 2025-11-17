// analytics_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logger/app_logger.dart';

/// Analytics service for tracking user behavior and errors
/// Now uses Riverpod Provider
class AnalyticsService {
  AnalyticsService() {
    AppLogger.debug('AnalyticsService Initialized', tag: 'ANALYTICS');
  }

  /// Track user events
  Future<void> trackEvent(
      String eventName, {
        Map<String, dynamic>? parameters,
        bool includeUserInfo = true,
      }) async {
    try {
      final eventData = <String, dynamic>{
        'event': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.toString(),
      };

      if (parameters != null) {
        eventData.addAll(parameters);
      }

      // TODO: Integrate with your analytics provider (Firebase Analytics, Mixpanel, etc.)
      // await FirebaseAnalytics.instance.logEvent(
      //   name: eventName,
      //   parameters: eventData,
      // );

      AppLogger.debug('Analytics Event: $eventName', tag: 'ANALYTICS', error: eventData);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to track analytics event', tag: 'ANALYTICS', error: e, stackTrace: stackTrace);
    }
  }

  /// Track screen views
  Future<void> trackScreenView(String screenName, {String? screenClass}) async {
    await trackEvent(
      'screen_view',
      parameters: {
        'screen_name': screenName,
        'screen_class': screenClass ?? screenName,
      },
    );
  }

  /// Track errors and exceptions
  Future<void> trackError(
      String errorType, {
        required dynamic error,
        required StackTrace stackTrace,
        String? context,
        bool fatal = false,
      }) async {
    try {
      await trackEvent(
        fatal ? 'fatal_error' : 'non_fatal_error',
        parameters: {
          'error_type': errorType,
          'error_message': error.toString(),
          'context': context,
          'fatal': fatal,
          'stack_trace': stackTrace.toString(),
        },
      );

      // TODO: Also send to crash reporting service
      // await Crashlytics.instance.recordError(error, stackTrace);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to track error', tag: 'ANALYTICS', error: e, stackTrace: stackTrace);
    }
  }

  /// Track user engagement
  Future<void> trackUserEngagement(String action, {String? target, int? value}) async {
    await trackEvent(
      'user_engagement',
      parameters: {
        'action': action,
        if (target != null) 'target': target,
        if (value != null) 'value': value,
      },
    );
  }

  /// Track performance metrics
  Future<void> trackPerformance(String metricName, int durationMs, {String? feature}) async {
    await trackEvent(
      'performance_metric',
      parameters: {
        'metric_name': metricName,
        'duration_ms': durationMs,
        if (feature != null) 'feature': feature,
      },
    );
  }
}
