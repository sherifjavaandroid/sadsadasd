import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';

// مستويات جودة الفيديو
enum VideoQuality {
  auto, // تلقائي
  low, // 360p
  medium, // 480p
  high, // 720p
  ultra, // 1080p
}

// معلومات جودة الفيديو
class QualityInfo {
  final VideoQuality quality;
  final String resolution;
  final int bitrate; // kbps
  final String codec;

  const QualityInfo({
    required this.quality,
    required this.resolution,
    required this.bitrate,
    required this.codec,
  });

  @override
  String toString() => '$resolution ($bitrate kbps)';
}

// حالة الشبكة
class NetworkCondition {
  final ConnectivityResult connectionType;
  final double bandwidth; // Mbps
  final int latency; // ms
  final double packetLoss; // percentage
  final DateTime timestamp;

  NetworkCondition({
    required this.connectionType,
    required this.bandwidth,
    required this.latency,
    required this.packetLoss,
    required this.timestamp,
  });

  // تقييم جودة الشبكة
  NetworkQualityLevel get qualityLevel {
    if (connectionType == ConnectivityResult.none) {
      return NetworkQualityLevel.none;
    }

    if (bandwidth > 10 && latency < 100 && packetLoss < 1) {
      return NetworkQualityLevel.excellent;
    } else if (bandwidth > 5 && latency < 200 && packetLoss < 3) {
      return NetworkQualityLevel.good;
    } else if (bandwidth > 2 && latency < 500 && packetLoss < 5) {
      return NetworkQualityLevel.fair;
    } else {
      return NetworkQualityLevel.poor;
    }
  }
}

enum NetworkQualityLevel {
  none,
  poor,
  fair,
  good,
  excellent,
}

class AdaptiveQualityManager {
  static final AdaptiveQualityManager _instance =
      AdaptiveQualityManager._internal();

  factory AdaptiveQualityManager() => _instance;

  AdaptiveQualityManager._internal();

  // إعدادات الجودة المتاحة
  static const Map<VideoQuality, QualityInfo> _qualitySettings = {
    VideoQuality.low: QualityInfo(
      quality: VideoQuality.low,
      resolution: '360p',
      bitrate: 500,
      codec: 'h264',
    ),
    VideoQuality.medium: QualityInfo(
      quality: VideoQuality.medium,
      resolution: '480p',
      bitrate: 1000,
      codec: 'h264',
    ),
    VideoQuality.high: QualityInfo(
      quality: VideoQuality.high,
      resolution: '720p',
      bitrate: 2500,
      codec: 'h264',
    ),
    VideoQuality.ultra: QualityInfo(
      quality: VideoQuality.ultra,
      resolution: '1080p',
      bitrate: 5000,
      codec: 'h264',
    ),
  };

  // الحالة الحالية
  VideoQuality _currentQuality = VideoQuality.auto;
  VideoQuality _userPreference = VideoQuality.auto;
  NetworkCondition? _lastNetworkCondition;

  // إحصائيات الأداء
  final List<double> _loadTimes = [];
  final List<int> _bufferingEvents = [];
  final List<NetworkCondition> _networkHistory = [];

  // إعدادات التكيف
  bool _adaptiveQualityEnabled = true;
  bool _dataSaverMode = false;
  bool _wifiOnlyHighQuality = true;
  double _bufferHealthThreshold = 0.8;

  // مراقبة الشبكة
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _networkMonitorTimer;
  Timer? _qualityAdjustmentTimer;

  // تهيئة النظام
  Future<void> initialize() async {
    log('📺 تهيئة نظام جودة الفيديو التكيفي');

    // بدء مراقبة الشبكة
    await _startNetworkMonitoring();

    // جدولة التقييم الدوري
    _startPeriodicEvaluation();

    log('✅ تم تهيئة نظام الجودة التكيفية');
  }

  // بدء مراقبة الشبكة
  Future<void> _startNetworkMonitoring() async {
    final connectivity = Connectivity();

    // مراقبة تغييرات الاتصال
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        // لو انت مش عايز كلها، ممكن تاخد أول عنصر أو تعالجهم كلها
        await _onConnectivityChanged(results);
      },
    );

    // فحص الحالة الأولية
    final initialResult = await connectivity.checkConnectivity();
    await _onConnectivityChanged(initialResult);

    // مراقبة دورية لجودة الشبكة
    _networkMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _measureNetworkQuality(),
    );
  }

  // معالجة تغيير الاتصال
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    // لو انت عاوز تتعامل مع أول عنصر بس مثلا:
    final ConnectivityResult result =
        results.isNotEmpty ? results[0] : ConnectivityResult.none;

    log('📡 تغيير اتصال الشبكة: ${result.name}');

    if (result == ConnectivityResult.none) {
      // تعامل مع انقطاع الشبكة
    } else {
      // تعامل مع الشبكة المتصلة
    }
  }

  // قياس جودة الشبكة
  Future<void> _measureNetworkQuality() async {
    try {
      final connectivity = Connectivity();
      final connectionType = await connectivity.checkConnectivity();

      if (connectionType == ConnectivityResult.none) return;

      // قياس السرعة والزمن
      final networkMetrics = await _performNetworkTest();
      _lastNetworkCondition = NetworkCondition(
        connectionType: connectionType.isNotEmpty
            ? connectionType[0]
            : ConnectivityResult.none,
        bandwidth: networkMetrics['bandwidth'] as double,
        latency: networkMetrics['latency'] as int,
        packetLoss: networkMetrics['packetLoss'] as double,
        timestamp: DateTime.now(),
      );

      // حفظ في التاريخ
      _networkHistory.add(_lastNetworkCondition!);
      if (_networkHistory.length > 20) {
        _networkHistory.removeAt(0);
      }

      log('📊 جودة الشبكة: ${_lastNetworkCondition!.qualityLevel.name}');
      log('   السرعة: ${_lastNetworkCondition!.bandwidth.toStringAsFixed(1)} Mbps');
      log('   الزمن: ${_lastNetworkCondition!.latency}ms');
    } catch (e) {
      log('❌ خطأ في قياس جودة الشبكة: $e');
    }
  }

  // اختبار الشبكة
  Future<Map<String, dynamic>> _performNetworkTest() async {
    final stopwatch = Stopwatch()..start();

    try {
      // اختبار بسيط لقياس السرعة
      final testSize = 100 * 1024; // 100 KB

      final response = await HttpClient()
          .getUrl(Uri.parse('https://httpbin.org/bytes/$testSize'))
          .timeout(const Duration(seconds: 10));

      final httpResponse = await response.close();
      await httpResponse.drain();

      stopwatch.stop();

      final latency = stopwatch.elapsedMilliseconds;
      final bandwidth = (testSize * 8) / (latency / 1000) / 1000000; // Mbps

      return {
        'bandwidth': bandwidth,
        'latency': latency,
        'packetLoss': 0.0, // مبسط - في التطبيق الحقيقي يحتاج قياس أدق
      };
    } catch (e) {
      return {
        'bandwidth': 1.0, // قيمة افتراضية منخفضة
        'latency': 1000,
        'packetLoss': 5.0,
      };
    }
  }

  // تقييم الجودة المثلى
  void _evaluateOptimalQuality() {
    if (!_adaptiveQualityEnabled || _lastNetworkCondition == null) {
      return;
    }

    VideoQuality recommendedQuality = _getRecommendedQuality();

    // تطبيق تفضيلات المستخدم
    if (_userPreference != VideoQuality.auto) {
      recommendedQuality = _applyUserPreference(recommendedQuality);
    }

    // تحديث الجودة إذا تغيرت
    if (recommendedQuality != _currentQuality) {
      _switchQuality(recommendedQuality);
    }
  }

  // الحصول على الجودة الموصى بها
  VideoQuality _getRecommendedQuality() {
    final condition = _lastNetworkCondition!;

    // في وضع توفير البيانات
    if (_dataSaverMode) {
      return VideoQuality.low;
    }

    // جودة عالية على WiFi فقط
    if (_wifiOnlyHighQuality &&
        condition.connectionType != ConnectivityResult.wifi) {
      return VideoQuality.medium;
    }

    // اختيار بناءً على جودة الشبكة
    switch (condition.qualityLevel) {
      case NetworkQualityLevel.excellent:
        return VideoQuality.ultra;
      case NetworkQualityLevel.good:
        return VideoQuality.high;
      case NetworkQualityLevel.fair:
        return VideoQuality.medium;
      case NetworkQualityLevel.poor:
      case NetworkQualityLevel.none:
        return VideoQuality.low;
    }
  }

  // تطبيق تفضيل المستخدم
  VideoQuality _applyUserPreference(VideoQuality recommended) {
    // إذا كان المستخدم يريد جودة أعلى من الموصى بها
    if (_userPreference.index > recommended.index) {
      // تحقق من إمكانية دعم الجودة العالية
      if (_canSupportQuality(_userPreference)) {
        return _userPreference;
      }
    }

    // إذا كان المستخدم يريد جودة أقل، اعطها له
    if (_userPreference.index < recommended.index) {
      return _userPreference;
    }

    return recommended;
  }

  // تحقق من إمكانية دعم جودة معينة
  bool _canSupportQuality(VideoQuality quality) {
    if (_lastNetworkCondition == null) return false;

    final requiredBandwidth = _qualitySettings[quality]?.bitrate ?? 0;
    final availableBandwidth =
        _lastNetworkCondition!.bandwidth * 1000; // تحويل إلى kbps

    // نحتاج مهلة 50% للأمان
    return availableBandwidth > requiredBandwidth * 1.5;
  }

  // تبديل الجودة
  void _switchQuality(VideoQuality newQuality) {
    final oldQuality = _currentQuality;
    _currentQuality = newQuality;

    log('📺 تغيير جودة الفيديو: ${oldQuality.name} → ${newQuality.name}');
    log('   التفاصيل: ${_qualitySettings[newQuality]}');

    // إشعار المستمعين
    _notifyQualityChange(oldQuality, newQuality);
  }

  // تسجيل مقاييس الأداء
  void recordLoadTime(Duration loadTime) {
    _loadTimes.add(loadTime.inMilliseconds.toDouble());

    // الاحتفاظ بآخر 50 عينة
    if (_loadTimes.length > 50) {
      _loadTimes.removeAt(0);
    }

    // تقييم الأداء
    _evaluatePerformance();
  }

  void recordBufferingEvent() {
    _bufferingEvents.add(DateTime.now().millisecondsSinceEpoch);

    // الاحتفاظ بآخر 20 حدث
    if (_bufferingEvents.length > 20) {
      _bufferingEvents.removeAt(0);
    }

    // إذا كان هناك تقطع كثير، قلل الجودة
    if (_bufferingEvents.length >= 3) {
      final recentEvents = _bufferingEvents
          .where(
              (event) => DateTime.now().millisecondsSinceEpoch - event < 60000)
          .length;

      if (recentEvents >= 3) {
        _degradeQuality();
      }
    }
  }

  // تقييم الأداء
  void _evaluatePerformance() {
    if (_loadTimes.length < 5) return;

    final avgLoadTime = _loadTimes.reduce((a, b) => a + b) / _loadTimes.length;

    // إذا كان التحميل بطيء، قلل الجودة
    if (avgLoadTime > 5000 && _currentQuality.index > 0) {
      _degradeQuality();
    }
    // إذا كان التحميل سريع، يمكن زيادة الجودة
    else if (avgLoadTime < 2000 && _canUpgradeQuality()) {
      _upgradeQuality();
    }
  }

  // تقليل الجودة
  void _degradeQuality() {
    if (_currentQuality.index > 0) {
      final newQuality = VideoQuality.values[_currentQuality.index - 1];
      _switchQuality(newQuality);
    }
  }

  // زيادة الجودة
  void _upgradeQuality() {
    if (_currentQuality.index < VideoQuality.values.length - 1) {
      final newQuality = VideoQuality.values[_currentQuality.index + 1];
      if (_canSupportQuality(newQuality)) {
        _switchQuality(newQuality);
      }
    }
  }

  // تحقق من إمكانية زيادة الجودة
  bool _canUpgradeQuality() {
    if (_currentQuality == VideoQuality.ultra) return false;

    final nextQuality = VideoQuality.values[_currentQuality.index + 1];
    return _canSupportQuality(nextQuality);
  }

  // التقييم الدوري
  void _startPeriodicEvaluation() {
    _qualityAdjustmentTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _evaluateOptimalQuality(),
    );
  }

  // إشعار تغيير الجودة
  void _notifyQualityChange(VideoQuality oldQuality, VideoQuality newQuality) {
    // يمكن إضافة callback هنا لإشعار UI
  }

  // إعدادات المستخدم
  void setUserPreference(VideoQuality preference) {
    _userPreference = preference;
    log('👤 تفضيل المستخدم للجودة: ${preference.name}');
    _evaluateOptimalQuality();
  }

  void setAdaptiveQualityEnabled(bool enabled) {
    _adaptiveQualityEnabled = enabled;
    log('⚙️ الجودة التكيفية: ${enabled ? 'مفعلة' : 'معطلة'}');
  }

  void setDataSaverMode(bool enabled) {
    _dataSaverMode = enabled;
    log('💾 وضع توفير البيانات: ${enabled ? 'مفعل' : 'معطل'}');
    if (enabled) {
      _switchQuality(VideoQuality.low);
    } else {
      _evaluateOptimalQuality();
    }
  }

  void setWifiOnlyHighQuality(bool enabled) {
    _wifiOnlyHighQuality = enabled;
    log('📶 جودة عالية على WiFi فقط: ${enabled ? 'مفعل' : 'معطل'}');
    _evaluateOptimalQuality();
  }

  // الحصول على المعلومات الحالية
  VideoQuality get currentQuality => _currentQuality;

  QualityInfo? get currentQualityInfo => _qualitySettings[_currentQuality];

  NetworkCondition? get lastNetworkCondition => _lastNetworkCondition;

  // الحصول على الجودات المتاحة
  Map<VideoQuality, QualityInfo> get availableQualities => _qualitySettings;

  // إحصائيات الأداء
  Map<String, dynamic> getPerformanceStats() {
    final avgLoadTime = _loadTimes.isNotEmpty
        ? _loadTimes.reduce((a, b) => a + b) / _loadTimes.length
        : 0.0;

    final recentBuffering = _bufferingEvents
        .where((event) =>
            DateTime.now().millisecondsSinceEpoch - event <
            300000) // آخر 5 دقائق
        .length;

    return {
      'currentQuality': _currentQuality.name,
      'userPreference': _userPreference.name,
      'adaptiveEnabled': _adaptiveQualityEnabled,
      'dataSaverMode': _dataSaverMode,
      'averageLoadTime': avgLoadTime,
      'recentBufferingEvents': recentBuffering,
      'networkQuality': _lastNetworkCondition?.qualityLevel.name,
      'networkBandwidth': _lastNetworkCondition?.bandwidth,
    };
  }

  // تقرير مفصل
  void printDetailedReport() {
    final stats = getPerformanceStats();

    print('\n' + '=' * 60);
    print('📺 تقرير نظام الجودة التكيفية');
    print('=' * 60);

    print('🎯 الإعدادات الحالية:');
    print('  الجودة الحالية: ${stats['currentQuality']}');
    print('  تفضيل المستخدم: ${stats['userPreference']}');
    print('  الجودة التكيفية: ${stats['adaptiveEnabled'] ? 'مفعلة' : 'معطلة'}');
    print('  وضع توفير البيانات: ${stats['dataSaverMode'] ? 'مفعل' : 'معطل'}');

    print('\n📊 أداء الشبكة:');
    print('  جودة الشبكة: ${stats['networkQuality'] ?? 'غير معروف'}');
    print(
        '  سرعة الشبكة: ${stats['networkBandwidth']?.toStringAsFixed(1) ?? 'غير معروف'} Mbps');

    print('\n⚡ أداء التحميل:');
    print(
        '  متوسط وقت التحميل: ${(stats['averageLoadTime'] as double).toStringAsFixed(0)}ms');
    print('  أحداث التقطع الأخيرة: ${stats['recentBufferingEvents']}');

    if (_networkHistory.isNotEmpty) {
      print('\n📈 تاريخ الشبكة (آخر ${_networkHistory.length} قياس):');
      for (final condition in _networkHistory.take(5)) {
        print(
            '  ${condition.timestamp.toLocal().toString().substring(11, 19)}: '
            '${condition.qualityLevel.name} '
            '(${condition.bandwidth.toStringAsFixed(1)} Mbps)');
      }
    }

    print('=' * 60 + '\n');
  }

  // تنظيف الموارد
  void dispose() {
    _connectivitySubscription.cancel();
    _networkMonitorTimer?.cancel();
    _qualityAdjustmentTimer?.cancel();

    log('🧹 تنظيف نظام الجودة التكيفية');
  }
}
