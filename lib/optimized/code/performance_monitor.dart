import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  factory PerformanceMonitor() => _instance;

  PerformanceMonitor._internal();

  // متغيرات مراقبة الأداء
  int _videoLoadsCount = 0;
  int _cacheHitsCount = 0;
  int _networkRequestsCount = 0;
  int _errorsCount = 0;

  final List<double> _frameTimes = [];
  final List<int> _memoryUsage = [];
  final Map<String, int> _apiCallCounts = {};
  final Map<String, Duration> _apiResponseTimes = {};

  Timer? _memoryMonitorTimer;
  bool _isMonitoring = false;

  // إعدادات المراقبة
  static const int _maxFrameTimeSamples = 100;
  static const int _maxMemorySamples = 50;
  static const Duration _memoryCheckInterval = Duration(seconds: 5);

  // بدء مراقبة الأداء
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    log('🔍 بدء مراقبة الأداء');

    // مراقبة استهلاك الذاكرة
    _startMemoryMonitoring();

    // مراقبة معدل الإطارات
    _startFrameMonitoring();
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    log('⏹️ إيقاف مراقبة الأداء');
  }

  void _startMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = Timer.periodic(_memoryCheckInterval, (timer) {
      _checkMemoryUsage();
    });
  }

  void _startFrameMonitoring() {
    WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
      if (!_isMonitoring) return;

      final frameTime =
          timeStamp.inMicroseconds / 1000.0; // تحويل إلى ميلي ثانية
      _recordFrameTime(frameTime);
    });
  }

  void _checkMemoryUsage() async {
    if (Platform.isAndroid) {
      try {
        // استخدام platform channel للحصول على معلومات الذاكرة
        const platform = MethodChannel('performance_monitor');
        final memoryInfo = await platform.invokeMethod('getMemoryInfo');

        if (memoryInfo != null) {
          final usedMemory = memoryInfo['usedMemory'] as int? ?? 0;
          _recordMemoryUsage(usedMemory);

          // تحذير عند استهلاك ذاكرة عالي
          if (usedMemory > 200 * 1024 * 1024) {
            // 200 MB
            log('⚠️ تحذير: استهلاك ذاكرة عالي: ${_formatBytes(usedMemory)}');
            _triggerMemoryCleanup();
          }
        }
      } catch (e) {
        log('❌ خطأ في مراقبة الذاكرة: $e');
      }
    }
  }

  void _recordFrameTime(double frameTime) {
    _frameTimes.add(frameTime);

    // الاحتفاظ بآخر عينات فقط
    if (_frameTimes.length > _maxFrameTimeSamples) {
      _frameTimes.removeAt(0);
    }

    // تحذير عند انخفاض الأداء
    if (frameTime > 16.67) {
      // أقل من 60 FPS
      log('⚠️ انخفاض الأداء: ${frameTime.toStringAsFixed(2)}ms/frame');
    }
  }

  void _recordMemoryUsage(int bytes) {
    _memoryUsage.add(bytes);

    if (_memoryUsage.length > _maxMemorySamples) {
      _memoryUsage.removeAt(0);
    }
  }

  // تسجيل أحداث الأداء
  void recordVideoLoad({required bool fromCache}) {
    _videoLoadsCount++;
    if (fromCache) {
      _cacheHitsCount++;
      log('📱 تحميل فيديو من الكاش (${_cacheHitsCount}/${_videoLoadsCount})');
    } else {
      log('🌐 تحميل فيديو من الشبكة (${_videoLoadsCount - _cacheHitsCount}/${_videoLoadsCount})');
    }
  }

  void recordNetworkRequest(String endpoint) {
    _networkRequestsCount++;
    _apiCallCounts[endpoint] = (_apiCallCounts[endpoint] ?? 0) + 1;
    log('📡 طلب شبكة: $endpoint (العدد: ${_apiCallCounts[endpoint]})');
  }

  void recordApiResponseTime(String endpoint, Duration responseTime) {
    _apiResponseTimes[endpoint] = responseTime;

    if (responseTime.inMilliseconds > 3000) {
      log('⚠️ استجابة بطيئة: $endpoint - ${responseTime.inMilliseconds}ms');
    }
  }

  void recordError(String error) {
    _errorsCount++;
    log('❌ خطأ مسجل: $error (إجمالي الأخطاء: $_errorsCount)');
  }

  // تنظيف الذاكرة عند الحاجة
  void _triggerMemoryCleanup() {
    log('🧹 تشغيل تنظيف الذاكرة التلقائي');

    // إشارة للمكونات الأخرى لتنظيف الذاكرة
    SystemChannels.platform
        .invokeMethod('SystemChrome.setEnabledSystemUIOverlays', []);

    // إجبار garbage collection
    if (kDebugMode) {
      // في وضع التطوير فقط
      SystemChannels.platform.invokeMethod('Runtime.gc');
    }
  }

  // تحليل الأداء
  PerformanceReport generateReport() {
    final avgFrameTime = _frameTimes.isNotEmpty
        ? _frameTimes.reduce((a, b) => a + b) / _frameTimes.length
        : 0.0;

    final fps = avgFrameTime > 0 ? 1000.0 / avgFrameTime : 0.0;

    final avgMemory = _memoryUsage.isNotEmpty
        ? _memoryUsage.reduce((a, b) => a + b) / _memoryUsage.length
        : 0;

    final cacheHitRate =
        _videoLoadsCount > 0 ? (_cacheHitsCount / _videoLoadsCount) * 100 : 0.0;

    return PerformanceReport(
      averageFrameTime: avgFrameTime,
      averageFPS: fps,
      averageMemoryUsage: avgMemory.toInt(),
      totalVideoLoads: _videoLoadsCount,
      cacheHitRate: cacheHitRate,
      totalNetworkRequests: _networkRequestsCount,
      totalErrors: _errorsCount,
      apiCallCounts: Map.from(_apiCallCounts),
      apiResponseTimes: Map.from(_apiResponseTimes),
      memoryPeakUsage: _memoryUsage.isNotEmpty
          ? _memoryUsage.reduce((a, b) => a > b ? a : b)
          : 0,
    );
  }

  // طباعة تقرير مفصل
  void printDetailedReport() {
    final report = generateReport();

    print('\n' + '=' * 60);
    print('📊 تقرير الأداء المفصل');
    print('=' * 60);

    // أداء الرسوميات
    print('🎨 أداء الرسوميات:');
    print(
        '  متوسط وقت الإطار: ${report.averageFrameTime.toStringAsFixed(2)}ms');
    print('  متوسط FPS: ${report.averageFPS.toStringAsFixed(1)}');
    print('  حالة الأداء: ${_getPerformanceStatus(report.averageFPS)}');

    // استهلاك الذاكرة
    print('\n💾 استهلاك الذاكرة:');
    print('  متوسط الاستهلاك: ${_formatBytes(report.averageMemoryUsage)}');
    print('  ذروة الاستهلاك: ${_formatBytes(report.memoryPeakUsage)}');

    // كفاءة الكاش
    print('\n📱 كفاءة الكاش:');
    print('  إجمالي تحميل الفيديوهات: ${report.totalVideoLoads}');
    print('  معدل استخدام الكاش: ${report.cacheHitRate.toStringAsFixed(1)}%');
    print('  حالة الكاش: ${_getCacheStatus(report.cacheHitRate)}');

    // طلبات الشبكة
    print('\n📡 طلبات الشبكة:');
    print('  إجمالي الطلبات: ${report.totalNetworkRequests}');
    print('  إجمالي الأخطاء: ${report.totalErrors}');
    print('  معدل نجاح الطلبات: ${_getSuccessRate(report)}%');

    // تفاصيل API
    if (report.apiCallCounts.isNotEmpty) {
      print('\n🔌 تفاصيل استخدام API:');
      report.apiCallCounts.forEach((endpoint, count) {
        final responseTime = report.apiResponseTimes[endpoint];
        final responseTimeStr =
            responseTime != null ? ' (${responseTime.inMilliseconds}ms)' : '';
        print('  $endpoint: $count طلب$responseTimeStr');
      });
    }

    // توصيات التحسين
    print('\n💡 توصيات التحسين:');
    _printOptimizationSuggestions(report);

    print('=' * 60 + '\n');
  }

  String _getPerformanceStatus(double fps) {
    if (fps >= 55) return '🟢 ممتاز';
    if (fps >= 45) return '🟡 جيد';
    if (fps >= 30) return '🟠 مقبول';
    return '🔴 يحتاج تحسين';
  }

  String _getCacheStatus(double hitRate) {
    if (hitRate >= 80) return '🟢 ممتاز';
    if (hitRate >= 60) return '🟡 جيد';
    if (hitRate >= 40) return '🟠 مقبول';
    return '🔴 يحتاج تحسين';
  }

  double _getSuccessRate(PerformanceReport report) {
    if (report.totalNetworkRequests == 0) return 100.0;
    return ((report.totalNetworkRequests - report.totalErrors) /
            report.totalNetworkRequests) *
        100;
  }

  void _printOptimizationSuggestions(PerformanceReport report) {
    final suggestions = <String>[];

    if (report.averageFPS < 45) {
      suggestions.add('تقليل عدد الفيديوهات المحملة في نفس الوقت');
      suggestions.add('تحسين تأثيرات الرسوميات والانيميشن');
    }

    if (report.averageMemoryUsage > 150 * 1024 * 1024) {
      // 150 MB
      suggestions.add('زيادة تكرار تنظيف الذاكرة');
      suggestions.add('تقليل جودة الفيديوهات المحملة مؤقتاً');
    }

    if (report.cacheHitRate < 60) {
      suggestions.add('زيادة حجم الكاش');
      suggestions.add('تحسين استراتيجية التحميل المسبق');
    }

    if (report.totalErrors > report.totalNetworkRequests * 0.1) {
      suggestions.add('تحسين معالجة أخطاء الشبكة');
      suggestions.add('إضافة retry logic للطلبات الفاشلة');
    }

    if (suggestions.isEmpty) {
      print('  🎉 الأداء ممتاز! لا توجد اقتراحات للتحسين.');
    } else {
      suggestions.forEach((suggestion) {
        print('  • $suggestion');
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // إعادة تعيين الإحصائيات
  void resetStats() {
    _videoLoadsCount = 0;
    _cacheHitsCount = 0;
    _networkRequestsCount = 0;
    _errorsCount = 0;
    _frameTimes.clear();
    _memoryUsage.clear();
    _apiCallCounts.clear();
    _apiResponseTimes.clear();

    log('🔄 تم إعادة تعيين إحصائيات الأداء');
  }

  void dispose() {
    stopMonitoring();
  }
}

// فئة تقرير الأداء
class PerformanceReport {
  final double averageFrameTime;
  final double averageFPS;
  final int averageMemoryUsage;
  final int totalVideoLoads;
  final double cacheHitRate;
  final int totalNetworkRequests;
  final int totalErrors;
  final Map<String, int> apiCallCounts;
  final Map<String, Duration> apiResponseTimes;
  final int memoryPeakUsage;

  PerformanceReport({
    required this.averageFrameTime,
    required this.averageFPS,
    required this.averageMemoryUsage,
    required this.totalVideoLoads,
    required this.cacheHitRate,
    required this.totalNetworkRequests,
    required this.totalErrors,
    required this.apiCallCounts,
    required this.apiResponseTimes,
    required this.memoryPeakUsage,
  });

  Map<String, dynamic> toJson() {
    return {
      'averageFrameTime': averageFrameTime,
      'averageFPS': averageFPS,
      'averageMemoryUsage': averageMemoryUsage,
      'totalVideoLoads': totalVideoLoads,
      'cacheHitRate': cacheHitRate,
      'totalNetworkRequests': totalNetworkRequests,
      'totalErrors': totalErrors,
      'apiCallCounts': apiCallCounts,
      'memoryPeakUsage': memoryPeakUsage,
    };
  }
}
