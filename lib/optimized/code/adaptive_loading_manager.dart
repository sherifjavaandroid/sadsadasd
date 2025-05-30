import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

// مستوى أداء الجهاز
enum DevicePerformanceLevel {
  low, // أجهزة ضعيفة
  medium, // أجهزة متوسطة
  high, // أجهزة قوية
  premium, // أجهزة عالية الأداء
}

// جودة الشبكة
enum NetworkQuality {
  poor, // شبكة ضعيفة
  moderate, // شبكة متوسطة
  good, // شبكة جيدة
  excellent, // شبكة ممتازة
}

// استراتيجية التحميل
class LoadingStrategy {
  final int maxConcurrentLoads;
  final int preloadDistance;
  final int cacheSize;
  final Duration throttleDelay;
  final bool enableBackgroundLoading;
  final int maxRetries;

  const LoadingStrategy({
    required this.maxConcurrentLoads,
    required this.preloadDistance,
    required this.cacheSize,
    required this.throttleDelay,
    required this.enableBackgroundLoading,
    required this.maxRetries,
  });
}

class AdaptiveLoadingManager {
  static final AdaptiveLoadingManager _instance =
      AdaptiveLoadingManager._internal();

  factory AdaptiveLoadingManager() => _instance;

  AdaptiveLoadingManager._internal();

  // معلومات الجهاز والشبكة
  DevicePerformanceLevel _devicePerformance = DevicePerformanceLevel.medium;
  NetworkQuality _networkQuality = NetworkQuality.moderate;

  // استراتيجية التحميل الحالية
  LoadingStrategy _currentStrategy =
      _defaultStrategies[DevicePerformanceLevel.medium]!;

  // مراقبة الشبكة
  final Connectivity _connectivity = Connectivity();

  // إحصائيات الأداء
  final List<double> _loadTimes = [];
  final List<int> _networkSpeeds = [];
  int _failedLoads = 0;
  int _successfulLoads = 0;

  // إعدادات المراقبة
  static const Duration _performanceCheckInterval = Duration(minutes: 1);
  static const int _maxPerformanceSamples = 20;

  Timer? _performanceTimer;
  bool _isInitialized = false;

  // استراتيجيات التحميل المحددة مسبقاً

  Future<void> autoOptimize() async {
    log('🤖 بدء التحسين التلقائي في AdaptiveLoadingManager');

    // لو مش مهيأ مش نكمل
    if (!_isInitialized) {
      log('⚠️ النظام مش مهيأ، لا يمكن التحسين التلقائي');
      return;
    }

    try {
      // تحليل الأداء الحالي
      final totalLoads = _successfulLoads + _failedLoads;
      if (totalLoads == 0) {
        log('⚠️ لا توجد بيانات تحميل لتحليل الأداء');
        return;
      }

      final successRate = _successfulLoads / totalLoads;
      final avgLoadTime = _loadTimes.isNotEmpty
          ? _loadTimes.reduce((a, b) => a + b) / _loadTimes.length
          : double.infinity;

      log('📊 الأداء الحالي: معدل النجاح ${(successRate * 100).toStringAsFixed(1)}%، متوسط وقت التحميل ${avgLoadTime.toStringAsFixed(2)}s');

      // استراتيجيات التحميل
      bool changed = false;

      // بناءً على معدل النجاح ومتوسط الوقت نقرر نرفع أو ننزل مستوى الأداء
      if (avgLoadTime > 5.0 || successRate < 0.8) {
        _degradePerformanceLevel();
        changed = true;
      } else if (avgLoadTime < 2.0 && successRate > 0.95) {
        _upgradePerformanceLevel();
        changed = true;
      }

      // تحديث استراتيجية التحميل بناءً على مستوى الأداء الجديد وجودة الشبكة
      if (changed) {
        _updateLoadingStrategy();
        log('⚙️ تم تحديث استراتيجية التحميل بعد التحسين التلقائي');
      } else {
        log('ℹ️ لا تغيير في استراتيجية التحميل بناءً على البيانات الحالية');
      }

      // إعادة تعيين الإحصائيات القديمة لتجميع بيانات جديدة بعد التحسين
      reset();
    } catch (e) {
      log('❌ خطأ أثناء التحسين التلقائي: $e');
    }
  }

  static const Map<DevicePerformanceLevel, LoadingStrategy> _defaultStrategies =
      {
    DevicePerformanceLevel.low: LoadingStrategy(
      maxConcurrentLoads: 1,
      preloadDistance: 1,
      cacheSize: 5,
      throttleDelay: Duration(milliseconds: 1000),
      enableBackgroundLoading: false,
      maxRetries: 2,
    ),
    DevicePerformanceLevel.medium: LoadingStrategy(
      maxConcurrentLoads: 2,
      preloadDistance: 2,
      cacheSize: 8,
      throttleDelay: Duration(milliseconds: 500),
      enableBackgroundLoading: true,
      maxRetries: 3,
    ),
    DevicePerformanceLevel.high: LoadingStrategy(
      maxConcurrentLoads: 3,
      preloadDistance: 3,
      cacheSize: 12,
      throttleDelay: Duration(milliseconds: 300),
      enableBackgroundLoading: true,
      maxRetries: 3,
    ),
    DevicePerformanceLevel.premium: LoadingStrategy(
      maxConcurrentLoads: 4,
      preloadDistance: 4,
      cacheSize: 16,
      throttleDelay: Duration(milliseconds: 200),
      enableBackgroundLoading: true,
      maxRetries: 4,
    ),
  };

  // تهيئة النظام
  Future<void> initialize() async {
    if (_isInitialized) return;

    log('🔧 تهيئة AdaptiveLoadingManager');

    // تحديد مستوى أداء الجهاز
    await _detectDevicePerformance();

    // مراقبة جودة الشبكة
    await _setupNetworkMonitoring();

    // بدء مراقبة الأداء
    _startPerformanceMonitoring();

    // تحديث الاستراتيجية الأولية
    _updateLoadingStrategy();

    _isInitialized = true;
    log('✅ تم تهيئة AdaptiveLoadingManager بنجاح');
  }

  Future<void> _detectDevicePerformance() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _devicePerformance = _analyzeAndroidPerformance(androidInfo);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _devicePerformance = _analyzeIOSPerformance(iosInfo);
      }

      log('📱 مستوى أداء الجهاز: ${_devicePerformance.name}');
    } catch (e) {
      log('❌ خطأ في تحديد أداء الجهاز: $e');
      _devicePerformance = DevicePerformanceLevel.medium; // قيمة افتراضية
    }
  }

  DevicePerformanceLevel _analyzeAndroidPerformance(
      AndroidDeviceInfo androidInfo) {
    // تحليل بناءً على مواصفات الجهاز
    final sdkInt = androidInfo.version.sdkInt;
    final totalMemory = _getTotalMemoryMB();

    // تحديد الأداء بناءً على نسخة Android والذاكرة
    if (sdkInt >= 30 && totalMemory > 6000) {
      return DevicePerformanceLevel.premium;
    } else if (sdkInt >= 28 && totalMemory > 4000) {
      return DevicePerformanceLevel.high;
    } else if (sdkInt >= 26 && totalMemory > 3000) {
      return DevicePerformanceLevel.medium;
    } else {
      return DevicePerformanceLevel.low;
    }
  }

  DevicePerformanceLevel _analyzeIOSPerformance(IosDeviceInfo iosInfo) {
    // تحليل بناءً على نموذج الجهاز
    final model = iosInfo.utsname.machine.toLowerCase();

    if (model.contains('iphone14') || model.contains('iphone13')) {
      return DevicePerformanceLevel.premium;
    } else if (model.contains('iphone12') || model.contains('iphone11')) {
      return DevicePerformanceLevel.high;
    } else if (model.contains('iphonex') || model.contains('iphone8')) {
      return DevicePerformanceLevel.medium;
    } else {
      return DevicePerformanceLevel.low;
    }
  }

  int _getTotalMemoryMB() {
    // محاولة الحصول على معلومات الذاكرة عبر platform channel
    try {
      // هذا مثال - قد تحتاج لتنفيذ platform channel مخصص
      return 4000; // قيمة افتراضية
    } catch (e) {
      return 3000; // قيمة افتراضية منخفضة
    }
  }

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  Future<void> _setupNetworkMonitoring() async {
    // مراقبة تغييرات الاتصال
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _onConnectivityChanged(results);
      },
    );

    // فحص الحالة الأولية
    final List<ConnectivityResult> result =
        await _connectivity.checkConnectivity();
    await _onConnectivityChanged(result);
  }

// الدالة اللي بتتعامل مع ليستة نتائج
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    if (results.contains(ConnectivityResult.wifi)) {
      print('واي فاي متصل');
    } else if (results.contains(ConnectivityResult.mobile)) {
      print('شبكة موبايل متصلة');
    } else if (results.contains(ConnectivityResult.none)) {
      print('لا يوجد اتصال');
    } else {
      print('حالة اتصال غير معروفة');
    }
  }

  ed() async {
    try {
      final stopwatch = Stopwatch()..start();

      // تنزيل ملف اختبار صغير
      final client = HttpClient();
      final request =
          await client.getUrl(Uri.parse('https://httpbin.org/bytes/1024'));
      final response = await request.close();

      await response.drain();
      stopwatch.stop();

      final speedKbps = (1024 * 8) / (stopwatch.elapsedMilliseconds / 1000);
      _networkSpeeds.add(speedKbps.round());

      // تقييم جودة الشبكة
      if (speedKbps > 5000) {
        _networkQuality = NetworkQuality.excellent;
      } else if (speedKbps > 2000) {
        _networkQuality = NetworkQuality.good;
      } else if (speedKbps > 500) {
        _networkQuality = NetworkQuality.moderate;
      } else {
        _networkQuality = NetworkQuality.poor;
      }

      log('🌐 سرعة الشبكة: ${speedKbps.toStringAsFixed(0)} Kbps - جودة: ${_networkQuality.name}');
    } catch (e) {
      log('❌ خطأ في اختبار سرعة الشبكة: $e');
      _networkQuality = NetworkQuality.moderate;
    }
  }

  void _startPerformanceMonitoring() {
    _performanceTimer?.cancel();
    _performanceTimer = Timer.periodic(_performanceCheckInterval, (_) {
      _analyzePerformanceMetrics();
    });
  }

  void _analyzePerformanceMetrics() {
    if (_loadTimes.isEmpty) return;

    // حساب متوسط وقت التحميل
    final avgLoadTime = _loadTimes.reduce((a, b) => a + b) / _loadTimes.length;

    // حساب معدل نجاح التحميل
    final totalLoads = _successfulLoads + _failedLoads;
    final successRate = totalLoads > 0 ? _successfulLoads / totalLoads : 1.0;

    log('📊 تحليل الأداء: متوسط التحميل ${avgLoadTime.toStringAsFixed(2)}s، معدل النجاح ${(successRate * 100).toStringAsFixed(1)}%');

    // تعديل مستوى الأداء بناءً على المقاييس
    if (avgLoadTime > 5.0 || successRate < 0.8) {
      _degradePerformanceLevel();
    } else if (avgLoadTime < 2.0 && successRate > 0.95) {
      _upgradePerformanceLevel();
    }

    // تنظيف العينات القديمة
    if (_loadTimes.length > _maxPerformanceSamples) {
      _loadTimes.removeRange(0, _loadTimes.length - _maxPerformanceSamples);
    }
  }

  void _degradePerformanceLevel() {
    final currentIndex =
        DevicePerformanceLevel.values.indexOf(_devicePerformance);
    if (currentIndex > 0) {
      _devicePerformance = DevicePerformanceLevel.values[currentIndex - 1];
      log('⬇️ تقليل مستوى الأداء إلى: ${_devicePerformance.name}');
      _updateLoadingStrategy();
    }
  }

  void _upgradePerformanceLevel() {
    final currentIndex =
        DevicePerformanceLevel.values.indexOf(_devicePerformance);
    if (currentIndex < DevicePerformanceLevel.values.length - 1) {
      _devicePerformance = DevicePerformanceLevel.values[currentIndex + 1];
      log('⬆️ رفع مستوى الأداء إلى: ${_devicePerformance.name}');
      _updateLoadingStrategy();
    }
  }

  void _updateLoadingStrategy() {
    var baseStrategy = _defaultStrategies[_devicePerformance]!;

    // تعديل الاستراتيجية بناءً على جودة الشبكة
    _currentStrategy = LoadingStrategy(
      maxConcurrentLoads: _adjustForNetwork(baseStrategy.maxConcurrentLoads),
      preloadDistance: _adjustForNetwork(baseStrategy.preloadDistance),
      cacheSize: baseStrategy.cacheSize,
      throttleDelay: _adjustThrottleForNetwork(baseStrategy.throttleDelay),
      enableBackgroundLoading: baseStrategy.enableBackgroundLoading &&
          _networkQuality != NetworkQuality.poor,
      maxRetries: baseStrategy.maxRetries,
    );

    log('⚙️ تحديث استراتيجية التحميل: جهاز ${_devicePerformance.name}، شبكة ${_networkQuality.name}');
    log('   التحميل المتزامن: ${_currentStrategy.maxConcurrentLoads}');
    log('   مسافة التحميل المسبق: ${_currentStrategy.preloadDistance}');
    log('   حجم الكاش: ${_currentStrategy.cacheSize}');
  }

  int _adjustForNetwork(int baseValue) {
    switch (_networkQuality) {
      case NetworkQuality.poor:
        return (baseValue * 0.5).round().clamp(1, baseValue);
      case NetworkQuality.moderate:
        return (baseValue * 0.7).round();
      case NetworkQuality.good:
        return baseValue;
      case NetworkQuality.excellent:
        return (baseValue * 1.2).round();
    }
  }

  Duration _adjustThrottleForNetwork(Duration baseDelay) {
    switch (_networkQuality) {
      case NetworkQuality.poor:
        return Duration(milliseconds: (baseDelay.inMilliseconds * 2).round());
      case NetworkQuality.moderate:
        return Duration(milliseconds: (baseDelay.inMilliseconds * 1.5).round());
      case NetworkQuality.good:
        return baseDelay;
      case NetworkQuality.excellent:
        return Duration(milliseconds: (baseDelay.inMilliseconds * 0.8).round());
    }
  }

  // تسجيل مقاييس الأداء
  void recordLoadTime(Duration loadTime) {
    _loadTimes.add(loadTime.inMilliseconds / 1000.0);
    _successfulLoads++;
  }

  void recordLoadFailure() {
    _failedLoads++;
  }

  // الحصول على الاستراتيجية الحالية
  LoadingStrategy get currentStrategy => _currentStrategy;

  DevicePerformanceLevel get devicePerformance => _devicePerformance;

  NetworkQuality get networkQuality => _networkQuality;

  // إحصائيات النظام
  Map<String, dynamic> getSystemStats() {
    final totalLoads = _successfulLoads + _failedLoads;
    final successRate = totalLoads > 0 ? _successfulLoads / totalLoads : 0.0;
    final avgLoadTime = _loadTimes.isNotEmpty
        ? _loadTimes.reduce((a, b) => a + b) / _loadTimes.length
        : 0.0;

    return {
      'devicePerformance': _devicePerformance.name,
      'networkQuality': _networkQuality.name,
      'successfulLoads': _successfulLoads,
      'failedLoads': _failedLoads,
      'successRate': successRate * 100,
      'averageLoadTime': avgLoadTime,
      'currentStrategy': {
        'maxConcurrentLoads': _currentStrategy.maxConcurrentLoads,
        'preloadDistance': _currentStrategy.preloadDistance,
        'cacheSize': _currentStrategy.cacheSize,
        'throttleDelay': _currentStrategy.throttleDelay.inMilliseconds,
        'enableBackgroundLoading': _currentStrategy.enableBackgroundLoading,
        'maxRetries': _currentStrategy.maxRetries,
      },
    };
  }

  // طباعة تقرير مفصل
  void printDetailedReport() {
    final stats = getSystemStats();

    print('\n' + '=' * 60);
    print('🤖 تقرير نظام التحميل التكيفي');
    print('=' * 60);

    print('📱 مستوى أداء الجهاز: ${stats['devicePerformance']}');
    print('🌐 جودة الشبكة: ${stats['networkQuality']}');
    print(
        '📊 معدل نجاح التحميل: ${(stats['successRate'] as double).toStringAsFixed(1)}%');
    print(
        '⏱️ متوسط وقت التحميل: ${(stats['averageLoadTime'] as double).toStringAsFixed(2)}s');

    final strategy = stats['currentStrategy'] as Map<String, dynamic>;
    print('\n⚙️ الاستراتيجية الحالية:');
    print('  التحميل المتزامن: ${strategy['maxConcurrentLoads']}');
    print('  مسافة التحميل المسبق: ${strategy['preloadDistance']}');
    print('  حجم الكاش: ${strategy['cacheSize']}');
    print('  تأخير الـ throttling: ${strategy['throttleDelay']}ms');
    print('  التحميل الخلفي: ${strategy['enableBackgroundLoading']}');
    print('  عدد المحاولات: ${strategy['maxRetries']}');

    print('=' * 60 + '\n');
  }

  // إعادة تعيين النظام
  void reset() {
    _loadTimes.clear();
    _networkSpeeds.clear();
    _successfulLoads = 0;
    _failedLoads = 0;

    log('🔄 إعادة تعيين AdaptiveLoadingManager');
  }

  // تنظيف الموارد
  void dispose() {
    _performanceTimer?.cancel();
    _connectivitySubscription.cancel();
    _isInitialized = false;

    log('🧹 تنظيف AdaptiveLoadingManager');
  }
}
