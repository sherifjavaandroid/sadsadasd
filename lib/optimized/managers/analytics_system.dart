import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

// حدث تحليلات
class AnalyticsEvent {
  final String eventName;
  final DateTime timestamp;
  final Map<String, dynamic> properties;
  final String sessionId;

  AnalyticsEvent({
    required this.eventName,
    required this.timestamp,
    required this.properties,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties,
      'sessionId': sessionId,
    };
  }
}

// جلسة المستخدم
class UserSession {
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  final List<AnalyticsEvent> events = [];

  // مقاييس الجلسة
  int videosWatched = 0;
  int videosLoaded = 0;
  int errorOccurred = 0;
  double totalWatchTime = 0.0;
  int scrollEvents = 0;

  UserSession({
    required this.sessionId,
    required this.startTime,
  });

  Duration get sessionDuration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': sessionDuration.inSeconds,
      'videosWatched': videosWatched,
      'videosLoaded': videosLoaded,
      'errorOccurred': errorOccurred,
      'totalWatchTime': totalWatchTime,
      'scrollEvents': scrollEvents,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}

// تقرير الأداء التفصيلي
class PerformanceReport {
  final DateTime generatedAt;
  final Duration reportPeriod;
  final Map<String, dynamic> metrics;
  final List<String> insights;
  final List<String> recommendations;

  PerformanceReport({
    required this.generatedAt,
    required this.reportPeriod,
    required this.metrics,
    required this.insights,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'reportPeriod': reportPeriod.inHours,
      'metrics': metrics,
      'insights': insights,
      'recommendations': recommendations,
    };
  }
}

class AnalyticsSystem {
  static final AnalyticsSystem _instance = AnalyticsSystem._internal();

  factory AnalyticsSystem() => _instance;

  AnalyticsSystem._internal();

  // الجلسة الحالية
  UserSession? _currentSession;

  // جلسات سابقة (آخر 10 جلسات)
  final List<UserSession> _pastSessions = [];

  // الأحداث المؤقتة (في انتظار الإرسال)
  final List<AnalyticsEvent> _pendingEvents = [];

  // مؤقتات ومتتبعات
  Timer? _sessionTimer;
  Timer? _autoReportTimer;
  DateTime? _lastVideoStartTime;

  // إعدادات النظام
  bool _isEnabled = true;
  bool _enableRealTimeReports = false;
  Duration _sessionTimeout = Duration(minutes: 30);
  int _maxEventsInMemory = 1000;

  // بدء جلسة جديدة
  void startSession() {
    if (!_isEnabled) return;

    _endCurrentSession();

    final sessionId = _generateSessionId();
    _currentSession = UserSession(
      sessionId: sessionId,
      startTime: DateTime.now(),
    );

    log('📊 بدء جلسة تحليلات جديدة: $sessionId');

    // بدء مؤقت انتهاء الجلسة
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, _endCurrentSession);

    // بدء التقارير التلقائية
    if (_enableRealTimeReports) {
      _autoReportTimer?.cancel();
      _autoReportTimer = Timer.periodic(Duration(minutes: 5), (_) {
        _generateRealTimeReport();
      });
    }

    // تسجيل بدء الجلسة
    trackEvent('session_start', {
      'sessionId': sessionId,
      'platform': defaultTargetPlatform.name,
    });
  }

  // إنهاء الجلسة الحالية
  void _endCurrentSession() {
    if (_currentSession != null) {
      _currentSession!.endTime = DateTime.now();

      // تسجيل نهاية الجلسة
      trackEvent('session_end', {
        'duration': _currentSession!.sessionDuration.inSeconds,
        'videosWatched': _currentSession!.videosWatched,
        'totalEvents': _currentSession!.events.length,
      });

      // حفظ الجلسة في التاريخ
      _pastSessions.add(_currentSession!);
      if (_pastSessions.length > 10) {
        _pastSessions.removeAt(0);
      }

      log('📊 انتهاء الجلسة: ${_currentSession!.sessionId}');
      _currentSession = null;
    }

    _sessionTimer?.cancel();
    _autoReportTimer?.cancel();
  }

  // تتبع حدث
  void trackEvent(String eventName, [Map<String, dynamic>? properties]) {
    if (!_isEnabled || _currentSession == null) return;

    final event = AnalyticsEvent(
      eventName: eventName,
      timestamp: DateTime.now(),
      properties: properties ?? {},
      sessionId: _currentSession!.sessionId,
    );

    _currentSession!.events.add(event);
    _pendingEvents.add(event);

    // معالجة خاصة لأحداث معينة
    _processSpecialEvent(eventName, properties);

    // تنظيف الذاكرة
    if (_pendingEvents.length > _maxEventsInMemory) {
      _pendingEvents.removeRange(0, _pendingEvents.length - _maxEventsInMemory);
    }

    log('📝 تسجيل حدث: $eventName');
  }

  // معالجة الأحداث الخاصة
  void _processSpecialEvent(
      String eventName, Map<String, dynamic>? properties) {
    if (_currentSession == null) return;

    switch (eventName) {
      case 'video_start':
        _currentSession!.videosWatched++;
        _lastVideoStartTime = DateTime.now();
        break;

      case 'video_loaded':
        _currentSession!.videosLoaded++;
        break;

      case 'video_end':
      case 'video_pause':
        if (_lastVideoStartTime != null) {
          final watchTime =
              DateTime.now().difference(_lastVideoStartTime!).inSeconds;
          _currentSession!.totalWatchTime += watchTime;
          _lastVideoStartTime = null;
        }
        break;

      case 'scroll':
        _currentSession!.scrollEvents++;
        break;

      case 'error':
        _currentSession!.errorOccurred++;
        break;
    }
  }

  // أحداث محددة مسبقاً للفيديوهات
  void trackVideoLoad({
    required String videoId,
    required Duration loadTime,
    required bool fromCache,
    String? quality,
  }) {
    trackEvent('video_load', {
      'videoId': videoId,
      'loadTimeMs': loadTime.inMilliseconds,
      'fromCache': fromCache,
      'quality': quality,
    });
  }

  void trackVideoPlay({
    required String videoId,
    required int position,
    String? source,
  }) {
    trackEvent('video_play', {
      'videoId': videoId,
      'position': position,
      'source': source,
    });
  }

  void trackVideoError({
    required String videoId,
    required String errorMessage,
    String? errorCode,
  }) {
    trackEvent('video_error', {
      'videoId': videoId,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
    });
  }

  void trackPerformanceMetric({
    required String metricName,
    required double value,
    String? unit,
  }) {
    trackEvent('performance_metric', {
      'metricName': metricName,
      'value': value,
      'unit': unit,
    });
  }

  void trackUserInteraction({
    required String action,
    required String target,
    Map<String, dynamic>? context,
  }) {
    trackEvent('user_interaction', {
      'action': action,
      'target': target,
      'context': context,
    });
  }

  // تحليل البيانات وإنشاء رؤى
  Map<String, dynamic> analyzePerformance() {
    if (_pastSessions.isEmpty && _currentSession == null) {
      return {'status': 'no_data'};
    }

    final allSessions = [..._pastSessions];
    if (_currentSession != null) {
      allSessions.add(_currentSession!);
    }

    // حساب المقاييس الأساسية
    final totalSessions = allSessions.length;
    final totalVideosWatched = allSessions.fold<int>(
      0,
      (sum, session) => sum + (session.videosWatched ?? 0),
    );

    final totalVideosLoaded = allSessions.fold<int>(
      0,
      (sum, session) => sum + (session.videosLoaded ?? 0),
    );

    final totalErrors = allSessions.fold<int>(
      0,
      (sum, session) => sum + (session.errorOccurred ?? 0),
    );

    final totalWatchTime = allSessions.fold<double>(
      0.0,
      (sum, session) => sum + (session.totalWatchTime ?? 0.0),
    );

    // حساب المتوسطات
    final avgVideosPerSession =
        totalSessions > 0 ? totalVideosWatched / totalSessions : 0.0;
    final avgWatchTime =
        totalVideosWatched > 0 ? totalWatchTime / totalVideosWatched : 0.0;
    final errorRate =
        totalVideosLoaded > 0 ? (totalErrors / totalVideosLoaded) * 100 : 0.0;

    // حساب معدلات التحميل من الكاش
    final cacheEvents = _getAllEvents()
        .where((e) =>
            e.eventName == 'video_load' && e.properties['fromCache'] == true)
        .length;
    final totalLoadEvents =
        _getAllEvents().where((e) => e.eventName == 'video_load').length;
    final cacheHitRate =
        totalLoadEvents > 0 ? (cacheEvents / totalLoadEvents) * 100 : 0.0;

    // تحليل أوقات التحميل
    final loadTimes = _getAllEvents()
        .where((e) => e.eventName == 'video_load')
        .map((e) => (e.properties['loadTimeMs'] as int?) ?? 0)
        .where((time) => time > 0)
        .toList();

    final avgLoadTime = loadTimes.isNotEmpty
        ? loadTimes.reduce((a, b) => a + b) / loadTimes.length
        : 0.0;

    return {
      'analysis_timestamp': DateTime.now().toIso8601String(),
      'session_metrics': {
        'total_sessions': totalSessions,
        'avg_videos_per_session': avgVideosPerSession,
        'avg_watch_time_seconds': avgWatchTime,
      },
      'performance_metrics': {
        'avg_load_time_ms': avgLoadTime,
        'cache_hit_rate_percent': cacheHitRate,
        'error_rate_percent': errorRate,
      },
      'usage_metrics': {
        'total_videos_watched': totalVideosWatched,
        'total_videos_loaded': totalVideosLoaded,
        'total_watch_time_seconds': totalWatchTime,
        'total_errors': totalErrors,
      },
    };
  }

  // إنشاء تقرير أداء مفصل
  PerformanceReport generateDetailedReport() {
    final analysis = analyzePerformance();
    final insights = <String>[];
    final recommendations = <String>[];

    // تحليل الأداء وإنتاج رؤى
    if (analysis['performance_metrics'] != null) {
      final perfMetrics =
          analysis['performance_metrics'] as Map<String, dynamic>;

      // تحليل وقت التحميل
      final avgLoadTime = perfMetrics['avg_load_time_ms'] as double;
      if (avgLoadTime > 3000) {
        insights.add(
            'أوقات التحميل أبطأ من المتوقع (${avgLoadTime.toStringAsFixed(0)}ms)');
        recommendations.add('تحسين إعدادات الشبكة وزيادة حجم الكاش');
      } else if (avgLoadTime < 1000) {
        insights
            .add('أوقات تحميل ممتازة (${avgLoadTime.toStringAsFixed(0)}ms)');
      }

      // تحليل معدل الكاش
      final cacheHitRate = perfMetrics['cache_hit_rate_percent'] as double;
      if (cacheHitRate < 60) {
        insights.add(
            'معدل استخدام الكاش منخفض (${cacheHitRate.toStringAsFixed(1)}%)');
        recommendations.add('زيادة حجم الكاش وتحسين استراتيجية التحميل المسبق');
      } else if (cacheHitRate > 80) {
        insights.add(
            'معدل استخدام كاش ممتاز (${cacheHitRate.toStringAsFixed(1)}%)');
      }

      // تحليل معدل الأخطاء
      final errorRate = perfMetrics['error_rate_percent'] as double;
      if (errorRate > 5) {
        insights.add('معدل أخطاء عالي (${errorRate.toStringAsFixed(1)}%)');
        recommendations.add('تحسين معالجة الأخطاء وإضافة retry logic');
      } else if (errorRate < 2) {
        insights
            .add('معدل أخطاء منخفض جداً (${errorRate.toStringAsFixed(1)}%)');
      }
    }

    // تحليل سلوك المستخدم
    if (analysis['session_metrics'] != null) {
      final sessionMetrics =
          analysis['session_metrics'] as Map<String, dynamic>;

      final avgVideosPerSession =
          sessionMetrics['avg_videos_per_session'] as double;
      if (avgVideosPerSession < 5) {
        insights.add(
            'المستخدمون يشاهدون فيديوهات قليلة (${avgVideosPerSession.toStringAsFixed(1)} per session)');
        recommendations.add('تحسين اقتراح المحتوى وتجربة المستخدم');
      } else if (avgVideosPerSession > 20) {
        insights.add(
            'معدل مشاهدة عالي جداً (${avgVideosPerSession.toStringAsFixed(1)} per session)');
      }
    }

    return PerformanceReport(
      generatedAt: DateTime.now(),
      reportPeriod: Duration(hours: 24),
      // افتراضي
      metrics: analysis,
      insights: insights,
      recommendations: recommendations,
    );
  }

  // تقرير في الوقت الفعلي
  void _generateRealTimeReport() {
    if (_currentSession == null) return;

    final sessionDuration = _currentSession!.sessionDuration;
    final videosWatched = _currentSession!.videosWatched;
    final errors = _currentSession!.errorOccurred;

    log('📊 تقرير مباشر:');
    log('  مدة الجلسة: ${sessionDuration.inMinutes} دقيقة');
    log('  فيديوهات مشاهدة: $videosWatched');
    log('  أخطاء: $errors');
    log('  أحداث: ${_currentSession!.events.length}');
  }

  // الحصول على جميع الأحداث
  List<AnalyticsEvent> _getAllEvents() {
    final allEvents = <AnalyticsEvent>[];

    for (final session in _pastSessions) {
      allEvents.addAll(session.events);
    }

    if (_currentSession != null) {
      allEvents.addAll(_currentSession!.events);
    }

    return allEvents;
  }

  // تصدير البيانات
  Map<String, dynamic> exportData() {
    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'current_session': _currentSession?.toJson(),
      'past_sessions': _pastSessions.map((s) => s.toJson()).toList(),
      'pending_events': _pendingEvents.map((e) => e.toJson()).toList(),
      'settings': {
        'enabled': _isEnabled,
        'realtime_reports': _enableRealTimeReports,
        'session_timeout_minutes': _sessionTimeout.inMinutes,
        'max_events_in_memory': _maxEventsInMemory,
      },
    };
  }

  // طباعة تقرير مفصل
  void printDetailedAnalytics() {
    final report = generateDetailedReport();

    print('\n' + '=' * 80);
    print('📊 تقرير التحليلات المتقدم');
    print('=' * 80);
    print('🕐 تاريخ التقرير: ${report.generatedAt}');

    // طباعة المقاييس
    print('\n📈 مقاييس الأداء:');
    final metrics = report.metrics;

    if (metrics['session_metrics'] != null) {
      final sessionMetrics = metrics['session_metrics'] as Map<String, dynamic>;
      print('  إجمالي الجلسات: ${sessionMetrics['total_sessions']}');
      print(
          '  متوسط الفيديوهات/جلسة: ${(sessionMetrics['avg_videos_per_session'] as double).toStringAsFixed(1)}');
      print(
          '  متوسط وقت المشاهدة: ${(sessionMetrics['avg_watch_time_seconds'] as double).toStringAsFixed(1)}s');
    }

    if (metrics['performance_metrics'] != null) {
      final perfMetrics =
          metrics['performance_metrics'] as Map<String, dynamic>;
      print(
          '  متوسط وقت التحميل: ${(perfMetrics['avg_load_time_ms'] as double).toStringAsFixed(0)}ms');
      print(
          '  معدل استخدام الكاش: ${(perfMetrics['cache_hit_rate_percent'] as double).toStringAsFixed(1)}%');
      print(
          '  معدل الأخطاء: ${(perfMetrics['error_rate_percent'] as double).toStringAsFixed(1)}%');
    }

    // طباعة الرؤى
    if (report.insights.isNotEmpty) {
      print('\n💡 رؤى مهمة:');
      for (final insight in report.insights) {
        print('  • $insight');
      }
    }

    // طباعة التوصيات
    if (report.recommendations.isNotEmpty) {
      print('\n🎯 توصيات للتحسين:');
      for (final recommendation in report.recommendations) {
        print('  • $recommendation');
      }
    }

    print('=' * 80 + '\n');
  }

  // تنظيف البيانات القديمة
  void cleanup() {
    final cutoffDate = DateTime.now().subtract(Duration(days: 7));

    _pastSessions
        .removeWhere((session) => session.startTime.isBefore(cutoffDate));
    _pendingEvents.removeWhere((event) => event.timestamp.isBefore(cutoffDate));

    log('🧹 تنظيف بيانات التحليلات القديمة');
  }

  // إعدادات النظام
  void updateSettings({
    bool? enabled,
    bool? enableRealTimeReports,
    Duration? sessionTimeout,
    int? maxEventsInMemory,
  }) {
    if (enabled != null) _isEnabled = enabled;
    if (enableRealTimeReports != null)
      _enableRealTimeReports = enableRealTimeReports;
    if (sessionTimeout != null) _sessionTimeout = sessionTimeout;
    if (maxEventsInMemory != null) _maxEventsInMemory = maxEventsInMemory;

    log('⚙️ تحديث إعدادات التحليلات');
  }

  // توليد معرف جلسة فريد
  String _generateSessionId() {
    final random = math.Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return '${timestamp}_$randomPart';
  }

  // الحصول على إحصائيات سريعة
  Map<String, dynamic> getQuickStats() {
    if (_currentSession == null) {
      return {'status': 'no_active_session'};
    }

    return {
      'session_duration_minutes': _currentSession!.sessionDuration.inMinutes,
      'videos_watched': _currentSession!.videosWatched,
      'videos_loaded': _currentSession!.videosLoaded,
      'errors_occurred': _currentSession!.errorOccurred,
      'total_events': _currentSession!.events.length,
      'watch_time_seconds': _currentSession!.totalWatchTime,
    };
  }

  // تنظيف الموارد
  void dispose() {
    _endCurrentSession();
    _sessionTimer?.cancel();
    _autoReportTimer?.cancel();

    log('🧹 تنظيف نظام التحليلات');
  }
}
