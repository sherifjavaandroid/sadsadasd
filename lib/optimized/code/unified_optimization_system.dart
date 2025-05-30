import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';

// استيراد جميع الأنظمة المطورة
import '../managers/advanced_settings_manager.dart';
import '../managers/analytics_system.dart';
import '../managers/diagnostic_toolkit.dart';
import 'video_cache.dart';
import 'priority_loader.dart';
import 'performance_monitor.dart';
import 'adaptive_loading_manager.dart';
import 'adaptive_quality_manager.dart';

// حالة النظام العامة
enum SystemStatus {
  uninitialized,
  initializing,
  ready,
  optimizing,
  error,
}

// تقرير الحالة الشامل
class SystemHealthReport {
  final SystemStatus status;
  final DateTime timestamp;
  final Map<String, dynamic> componentStatus;
  final List<String> warnings;
  final List<String> errors;
  final Map<String, dynamic> performanceMetrics;

  SystemHealthReport({
    required this.status,
    required this.timestamp,
    required this.componentStatus,
    required this.warnings,
    required this.errors,
    required this.performanceMetrics,
  });

  bool get isHealthy => status == SystemStatus.ready && errors.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'isHealthy': isHealthy,
      'componentStatus': componentStatus,
      'warnings': warnings,
      'errors': errors,
      'performanceMetrics': performanceMetrics,
    };
  }
}

class UnifiedOptimizationSystem {
  static final UnifiedOptimizationSystem _instance =
      UnifiedOptimizationSystem._internal();

  factory UnifiedOptimizationSystem() => _instance;

  UnifiedOptimizationSystem._internal();

  // حالة النظام
  SystemStatus _status = SystemStatus.uninitialized;
  final List<String> _initializationLog = [];

  // مراجع الأنظمة الفرعية
  late VideoCache _videoCache;
  late PriorityLoader _priorityLoader;
  late PerformanceMonitor _performanceMonitor;
  late AdaptiveLoadingManager _adaptiveLoadingManager;
  late AdvancedSettingsManager _settingsManager;
  late DiagnosticToolkit _diagnosticToolkit;
  late AnalyticsSystem _analyticsSystem;
  late AdaptiveQualityManager _qualityManager;

  // مؤقتات الصيانة
  Timer? _healthCheckTimer;
  Timer? _maintenanceTimer;
  Timer? _reportGenerationTimer;

  // إعدادات النظام
  bool _autoOptimizationEnabled = true;
  bool _healthMonitoringEnabled = true;
  bool _analyticsEnabled = true;
  Duration _healthCheckInterval = Duration(minutes: 5);
  Duration _maintenanceInterval = Duration(hours: 1);

  // Getters للوصول للأنظمة الفرعية
  VideoCache get videoCache => _videoCache;

  PriorityLoader get priorityLoader => _priorityLoader;

  PerformanceMonitor get performanceMonitor => _performanceMonitor;

  AdaptiveLoadingManager get adaptiveLoadingManager => _adaptiveLoadingManager;

  AdvancedSettingsManager get settingsManager => _settingsManager;

  DiagnosticToolkit get diagnosticToolkit => _diagnosticToolkit;

  AnalyticsSystem get analyticsSystem => _analyticsSystem;

  AdaptiveQualityManager get qualityManager => _qualityManager;

  // حالة النظام
  SystemStatus get status => _status;

  bool get isReady => _status == SystemStatus.ready;

  // تهيئة النظام الشامل
  Future<bool> initialize() async {
    if (_status != SystemStatus.uninitialized) {
      log('⚠️ النظام مُهيأ مسبقاً');
      return _status == SystemStatus.ready;
    }

    _status = SystemStatus.initializing;
    _initializationLog.clear();

    log('🚀 بدء تهيئة النظام الموحد للتحسينات');
    _addToLog('بدء التهيئة');

    try {
      // تهيئة الأنظمة الأساسية
      await _initializeCoreComponents();

      // تحميل الإعدادات
      await _loadSettings();

      // تهيئة الأنظمة المتقدمة
      await _initializeAdvancedComponents();

      // تفعيل المراقبة والصيانة
      _startSystemMonitoring();

      // بدء التحليلات
      if (_analyticsEnabled) {
        _analyticsSystem.startSession();
      }

      _status = SystemStatus.ready;
      _addToLog('تم إكمال التهيئة بنجاح');

      log('✅ تم تهيئة النظام الموحد بنجاح');
      return true;
    } catch (e) {
      _status = SystemStatus.error;
      _addToLog('خطأ في التهيئة: $e');

      log('❌ فشل في تهيئة النظام: $e');
      return false;
    }
  }

  // تهيئة المكونات الأساسية
  Future<void> _initializeCoreComponents() async {
    _addToLog('تهيئة المكونات الأساسية');

    // تهيئة نظام الكاش
    _videoCache = VideoCache();
    _addToLog('✓ VideoCache');

    // تهيئة نظام التحميل
    _priorityLoader = PriorityLoader();
    _addToLog('✓ PriorityLoader');

    // تهيئة مراقب الأداء
    _performanceMonitor = PerformanceMonitor();
    _addToLog('✓ PerformanceMonitor');

    // تهيئة مدير الإعدادات
    _settingsManager = AdvancedSettingsManager();
    _addToLog('✓ AdvancedSettingsManager');

    // تهيئة أدوات التشخيص
    _diagnosticToolkit = DiagnosticToolkit();
    _addToLog('✓ DiagnosticToolkit');
  }

  // تحميل الإعدادات
  Future<void> _loadSettings() async {
    _addToLog('تحميل الإعدادات');

    await _settingsManager.loadSettings();

    // تطبيق الإعدادات على الأنظمة
    final settings = _settingsManager.performanceSettings;

    _priorityLoader.updateSettings(
      maxConcurrentLoads: settings.maxConcurrentLoads,
      maxImmediateLoads: (settings.maxConcurrentLoads / 2).ceil(),
      maxHighLoads: settings.maxConcurrentLoads - 1,
    );

    _addToLog('✓ تم تحميل وتطبيق الإعدادات');
  }

  // تهيئة المكونات المتقدمة
  Future<void> _initializeAdvancedComponents() async {
    _addToLog('تهيئة المكونات المتقدمة');

    // تهيئة نظام التحميل التكيفي
    _adaptiveLoadingManager = AdaptiveLoadingManager();
    await _adaptiveLoadingManager.initialize();
    _addToLog('✓ AdaptiveLoadingManager');

    // تهيئة نظام التحليلات
    _analyticsSystem = AnalyticsSystem();
    _addToLog('✓ AnalyticsSystem');

    // تهيئة نظام جودة الفيديو التكيفي
    _qualityManager = AdaptiveQualityManager();
    await _qualityManager.initialize();
    _addToLog('✓ AdaptiveQualityManager');
  }

  // بدء مراقبة النظام
  void _startSystemMonitoring() {
    if (!_healthMonitoringEnabled) return;

    _addToLog('بدء مراقبة النظام');

    // مراقبة الحالة الصحية
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });

    // الصيانة الدورية
    _maintenanceTimer = Timer.periodic(_maintenanceInterval, (_) {
      _performMaintenance();
    });

    // تقارير دورية (في وضع التطوير)
    if (kDebugMode) {
      _reportGenerationTimer = Timer.periodic(Duration(minutes: 10), (_) {
        _generatePeriodicReport();
      });
    }

    // بدء مراقبة الأداء
    _performanceMonitor.startMonitoring();

    _addToLog('✓ تم تفعيل المراقبة');
  }

  // فحص الحالة الصحية
  Future<SystemHealthReport> _performHealthCheck() async {
    final warnings = <String>[];
    final errors = <String>[];
    final componentStatus = <String, dynamic>{};
    final performanceMetrics = <String, dynamic>{};

    try {
      // فحص حالة الكاش
      final cacheStats = _videoCache.getCacheStats();
      componentStatus['videoCache'] = 'healthy';
      performanceMetrics['cacheSize'] = cacheStats['controllersInMemory'];

      if ((cacheStats['controllersInMemory'] as int) > 15) {
        warnings.add('استهلاك ذاكرة عالي في الكاش');
      }

      // فحص حالة التحميل
      final loaderStats = _priorityLoader.getStats();
      componentStatus['priorityLoader'] = 'healthy';
      performanceMetrics['activeLoads'] = loaderStats['activeTasksCount'];

      final successRate = loaderStats['successRate'] as double;
      if (successRate < 90) {
        warnings
            .add('معدل نجاح التحميل منخفض: ${successRate.toStringAsFixed(1)}%');
      }

      // فحص حالة الأداء
      final perfReport = _performanceMonitor.generateReport();
      componentStatus['performanceMonitor'] = 'healthy';
      performanceMetrics['averageFPS'] = perfReport.averageFPS;

      if (perfReport.averageFPS < 50) {
        warnings.add(
            'أداء الرسوميات منخفض: ${perfReport.averageFPS.toStringAsFixed(1)} FPS');
      }

      // فحص حالة الشبكة
      final networkCondition = _qualityManager.lastNetworkCondition;
      if (networkCondition != null) {
        componentStatus['network'] = networkCondition.qualityLevel.name;
        performanceMetrics['networkBandwidth'] = networkCondition.bandwidth;

        if (networkCondition.qualityLevel.index < 2) {
          warnings.add('جودة شبكة ضعيفة');
        }
      } else {
        componentStatus['network'] = 'unknown';
        warnings.add('لا يمكن تحديد حالة الشبكة');
      }
    } catch (e) {
      errors.add('خطأ في فحص الحالة الصحية: $e');
      componentStatus['system'] = 'error';
    }

    final report = SystemHealthReport(
      status: errors.isEmpty ? SystemStatus.ready : SystemStatus.error,
      timestamp: DateTime.now(),
      componentStatus: componentStatus,
      warnings: warnings,
      errors: errors,
      performanceMetrics: performanceMetrics,
    );

    // تسجيل التحليلات
    if (_analyticsEnabled) {
      _analyticsSystem.trackEvent('health_check', {
        'isHealthy': report.isHealthy,
        'warningsCount': warnings.length,
        'errorsCount': errors.length,
      });
    }

    return report;
  }

  // الصيانة الدورية
  Future<void> _performMaintenance() async {
    log('🔧 بدء الصيانة الدورية');

    try {
      // تنظيف الكاش
      _videoCache.cleanupExpiredCache();

      // تنظيف بيانات التحميل
      // _priorityLoader.cleanup(); // إذا كانت الدالة متوفرة

      // تنظيف بيانات التحليلات القديمة
      _analyticsSystem.cleanup();

      // تحسين تلقائي إذا كان مفعل
      if (_autoOptimizationEnabled) {
        await _performAutoOptimization();
      }

      log('✅ تمت الصيانة الدورية بنجاح');
    } catch (e) {
      log('❌ خطأ في الصيانة الدورية: $e');
    }
  }

  // التحسين التلقائي
  Future<void> _performAutoOptimization() async {
    log('🤖 بدء التحسين التلقائي');

    try {
      // تحسين إعدادات التحميل
      await _adaptiveLoadingManager.autoOptimize();

      // تحسين إعدادات جودة الفيديو
      // _qualityManager.optimizeForCurrentConditions(); // إذا كانت متوفرة

      log('✅ تم التحسين التلقائي');
    } catch (e) {
      log('❌ خطأ في التحسين التلقائي: $e');
    }
  }

  // تقرير دوري
  void _generatePeriodicReport() {
    log('\n📊 تقرير النظام الدوري:');

    // إحصائيات سريعة
    final cacheStats = _videoCache.getCacheStats();
    final loaderStats = _priorityLoader.getStats();
    final qualityStats = _qualityManager.getPerformanceStats();

    log('  الكاش: ${cacheStats['controllersInMemory']} كونترولر');
    log('  التحميل: ${loaderStats['activeTasksCount']} مهمة نشطة');
    log('  الجودة: ${qualityStats['currentQuality']}');
    log('  الشبكة: ${qualityStats['networkQuality']}');
  }

  // تشغيل تشخيص شامل
  Future<DiagnosticReport> runFullDiagnostic() async {
    log('🔍 تشغيل التشخيص الشامل');

    _status = SystemStatus.optimizing;

    try {
      final report = await _diagnosticToolkit.runFullDiagnostic();

      // تسجيل النتائج في التحليلات
      if (_analyticsEnabled) {
        _analyticsSystem.trackEvent('full_diagnostic', {
          'allTestsPassed': report.allTestsPassed,
          'passedTests': report.passedTests,
          'failedTests': report.failedTests,
          'duration': report.totalDuration.inSeconds,
        });
      }

      _status = SystemStatus.ready;
      return report;
    } catch (e) {
      _status = SystemStatus.error;
      log('❌ خطأ في التشخيص: $e');
      rethrow;
    }
  }

  // تحسين شامل للنظام
  Future<void> optimizeSystem() async {
    log('⚡ بدء تحسين شامل للنظام');

    _status = SystemStatus.optimizing;

    try {
      // تشخيص سريع لتحديد المشاكل
      final quickDiagnostic = await _diagnosticToolkit.runQuickDiagnostic();

      // تحسين بناءً على النتائج
      for (final result in quickDiagnostic) {
        if (!result.passed) {
          await _applyOptimizationForFailedTest(result.testName);
        }
      }

      // تحسين الإعدادات
      await _settingsManager.autoOptimize();

      // إعادة تحميل الإعدادات المحسنة
      await _loadSettings();

      _status = SystemStatus.ready;
      log('✅ تم التحسين الشامل بنجاح');
    } catch (e) {
      _status = SystemStatus.error;
      log('❌ خطأ في التحسين الشامل: $e');
      rethrow;
    }
  }

  // تطبيق تحسين محدد
  Future<void> _applyOptimizationForFailedTest(String testName) async {
    switch (testName) {
      case 'اختبار الذاكرة':
        // تنظيف الذاكرة
        _videoCache.clearAllCache();
        break;
      case 'اختبار الشبكة':
        // تفعيل وضع توفير البيانات
        _qualityManager.setDataSaverMode(true);
        break;
      case 'اختبار مشغل الفيديو':
        // تقليل عدد التحميلات المتزامنة
        _priorityLoader.updateSettings(maxConcurrentLoads: 2);
        break;
    }
  }

  // تصدير تقرير شامل
  Map<String, dynamic> exportComprehensiveReport() {
    return {
      'system': {
        'status': _status.name,
        'initializationLog': _initializationLog,
        'settings': _settingsManager.getSettingsSummary(),
      },
      'performance': _performanceMonitor.generateReport().toJson(),
      'analytics': _analyticsSystem.analyzePerformance(),
      'adaptive': _adaptiveLoadingManager.getSystemStats(),
      'quality': _qualityManager.getPerformanceStats(),
      'cache': _videoCache.getCacheStats(),
      'loader': _priorityLoader.getStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // طباعة تقرير موجز
  void printSystemSummary() {
    print('\n' + '=' * 80);
    print('🏠 ملخص النظام الموحد للتحسينات');
    print('=' * 80);
    print('📊 الحالة: ${_status.name}');
    print('⚙️ التحسين التلقائي: ${_autoOptimizationEnabled ? 'مفعل' : 'معطل'}');
    print('🔍 مراقبة الصحة: ${_healthMonitoringEnabled ? 'مفعلة' : 'معطلة'}');
    print('📈 التحليلات: ${_analyticsEnabled ? 'مفعلة' : 'معطلة'}');

    // ملخص المكونات
    print('\n🧩 حالة المكونات:');
    print(
        '  📱 VideoCache: ${_videoCache.getCacheStats()['controllersInMemory']} كونترولر');
    print(
        '  ⬇️ PriorityLoader: ${_priorityLoader.getStats()['activeTasksCount']} مهمة');
    print('  📊 PerformanceMonitor: مفعل');
    print('  📺 QualityManager: ${_qualityManager.currentQuality.name}');

    print('=' * 80 + '\n');
  }

  // إعدادات النظام
  void updateSystemSettings({
    bool? autoOptimization,
    bool? healthMonitoring,
    bool? analytics,
    Duration? healthCheckInterval,
    Duration? maintenanceInterval,
  }) {
    if (autoOptimization != null) _autoOptimizationEnabled = autoOptimization;
    if (healthMonitoring != null) _healthMonitoringEnabled = healthMonitoring;
    if (analytics != null) _analyticsEnabled = analytics;
    if (healthCheckInterval != null) _healthCheckInterval = healthCheckInterval;
    if (maintenanceInterval != null) _maintenanceInterval = maintenanceInterval;

    log('⚙️ تحديث إعدادات النظام');
  }

  // دالة مساعدة للتسجيل
  void _addToLog(String message) {
    final logEntry = '[${DateTime.now().toIso8601String()}] $message';
    _initializationLog.add(logEntry);

    // الاحتفاظ بآخر 100 إدخال
    if (_initializationLog.length > 100) {
      _initializationLog.removeAt(0);
    }
  }

  // تنظيف الموارد
  Future<void> dispose() async {
    log('🧹 تنظيف النظام الموحد');

    _healthCheckTimer?.cancel();
    _maintenanceTimer?.cancel();
    _reportGenerationTimer?.cancel();

    // تنظيف الأنظمة الفرعية
    _performanceMonitor.dispose();
    _adaptiveLoadingManager.dispose();
    _analyticsSystem.dispose();
    _qualityManager.dispose();
    await _videoCache.clearAllCache();

    _status = SystemStatus.uninitialized;

    log('✅ تم تنظيف النظام الموحد');
  }
}
