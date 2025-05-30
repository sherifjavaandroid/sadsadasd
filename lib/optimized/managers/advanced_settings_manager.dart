import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// إعدادات الأداء
class PerformanceSettings {
  final int maxConcurrentLoads;
  final int preloadDistance;
  final int cacheSize;
  final Duration throttleDelay;
  final bool enableBackgroundLoading;
  final bool enablePreloading;
  final bool enableMemoryOptimization;
  final int maxRetries;
  final double videoQuality; // 0.5 = نصف الجودة، 1.0 = جودة كاملة

  const PerformanceSettings({
    required this.maxConcurrentLoads,
    required this.preloadDistance,
    required this.cacheSize,
    required this.throttleDelay,
    required this.enableBackgroundLoading,
    required this.enablePreloading,
    required this.enableMemoryOptimization,
    required this.maxRetries,
    required this.videoQuality,
  });

  Map<String, dynamic> toJson() {
    return {
      'maxConcurrentLoads': maxConcurrentLoads,
      'preloadDistance': preloadDistance,
      'cacheSize': cacheSize,
      'throttleDelay': throttleDelay.inMilliseconds,
      'enableBackgroundLoading': enableBackgroundLoading,
      'enablePreloading': enablePreloading,
      'enableMemoryOptimization': enableMemoryOptimization,
      'maxRetries': maxRetries,
      'videoQuality': videoQuality,
    };
  }

  factory PerformanceSettings.fromJson(Map<String, dynamic> json) {
    return PerformanceSettings(
      maxConcurrentLoads: json['maxConcurrentLoads'] ?? 2,
      preloadDistance: json['preloadDistance'] ?? 2,
      cacheSize: json['cacheSize'] ?? 8,
      throttleDelay: Duration(milliseconds: json['throttleDelay'] ?? 500),
      enableBackgroundLoading: json['enableBackgroundLoading'] ?? true,
      enablePreloading: json['enablePreloading'] ?? true,
      enableMemoryOptimization: json['enableMemoryOptimization'] ?? true,
      maxRetries: json['maxRetries'] ?? 3,
      videoQuality: (json['videoQuality'] ?? 1.0).toDouble(),
    );
  }

  PerformanceSettings copyWith({
    int? maxConcurrentLoads,
    int? preloadDistance,
    int? cacheSize,
    Duration? throttleDelay,
    bool? enableBackgroundLoading,
    bool? enablePreloading,
    bool? enableMemoryOptimization,
    int? maxRetries,
    double? videoQuality,
  }) {
    return PerformanceSettings(
      maxConcurrentLoads: maxConcurrentLoads ?? this.maxConcurrentLoads,
      preloadDistance: preloadDistance ?? this.preloadDistance,
      cacheSize: cacheSize ?? this.cacheSize,
      throttleDelay: throttleDelay ?? this.throttleDelay,
      enableBackgroundLoading:
          enableBackgroundLoading ?? this.enableBackgroundLoading,
      enablePreloading: enablePreloading ?? this.enablePreloading,
      enableMemoryOptimization:
          enableMemoryOptimization ?? this.enableMemoryOptimization,
      maxRetries: maxRetries ?? this.maxRetries,
      videoQuality: videoQuality ?? this.videoQuality,
    );
  }
}

// إعدادات الشبكة
class NetworkSettings {
  final bool enableDataSaver;
  final bool enableWifiOnlyHQ;
  final int connectionTimeout;
  final int requestTimeout;
  final bool enableRetry;
  final bool enableCompression;

  const NetworkSettings({
    required this.enableDataSaver,
    required this.enableWifiOnlyHQ,
    required this.connectionTimeout,
    required this.requestTimeout,
    required this.enableRetry,
    required this.enableCompression,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableDataSaver': enableDataSaver,
      'enableWifiOnlyHQ': enableWifiOnlyHQ,
      'connectionTimeout': connectionTimeout,
      'requestTimeout': requestTimeout,
      'enableRetry': enableRetry,
      'enableCompression': enableCompression,
    };
  }

  factory NetworkSettings.fromJson(Map<String, dynamic> json) {
    return NetworkSettings(
      enableDataSaver: json['enableDataSaver'] ?? false,
      enableWifiOnlyHQ: json['enableWifiOnlyHQ'] ?? true,
      connectionTimeout: json['connectionTimeout'] ?? 10000,
      requestTimeout: json['requestTimeout'] ?? 15000,
      enableRetry: json['enableRetry'] ?? true,
      enableCompression: json['enableCompression'] ?? true,
    );
  }
}

// إعدادات المطور
class DeveloperSettings {
  final bool enableDebugMode;
  final bool enablePerformanceLogging;
  final bool enableNetworkLogging;
  final bool enableMemoryMonitoring;
  final bool showPerformanceOverlay;
  final int logLevel; // 0=Error, 1=Warning, 2=Info, 3=Debug

  const DeveloperSettings({
    required this.enableDebugMode,
    required this.enablePerformanceLogging,
    required this.enableNetworkLogging,
    required this.enableMemoryMonitoring,
    required this.showPerformanceOverlay,
    required this.logLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableDebugMode': enableDebugMode,
      'enablePerformanceLogging': enablePerformanceLogging,
      'enableNetworkLogging': enableNetworkLogging,
      'enableMemoryMonitoring': enableMemoryMonitoring,
      'showPerformanceOverlay': showPerformanceOverlay,
      'logLevel': logLevel,
    };
  }

  factory DeveloperSettings.fromJson(Map<String, dynamic> json) {
    return DeveloperSettings(
      enableDebugMode: json['enableDebugMode'] ?? false,
      enablePerformanceLogging: json['enablePerformanceLogging'] ?? false,
      enableNetworkLogging: json['enableNetworkLogging'] ?? false,
      enableMemoryMonitoring: json['enableMemoryMonitoring'] ?? false,
      showPerformanceOverlay: json['showPerformanceOverlay'] ?? false,
      logLevel: json['logLevel'] ?? 1,
    );
  }
}

class AdvancedSettingsManager {
  static final AdvancedSettingsManager _instance =
      AdvancedSettingsManager._internal();

  factory AdvancedSettingsManager() => _instance;

  AdvancedSettingsManager._internal();

  // الإعدادات الحالية
  PerformanceSettings _performanceSettings = const PerformanceSettings(
    maxConcurrentLoads: 2,
    preloadDistance: 2,
    cacheSize: 8,
    throttleDelay: Duration(milliseconds: 500),
    enableBackgroundLoading: true,
    enablePreloading: true,
    enableMemoryOptimization: true,
    maxRetries: 3,
    videoQuality: 1.0,
  );

  NetworkSettings _networkSettings = const NetworkSettings(
    enableDataSaver: false,
    enableWifiOnlyHQ: true,
    connectionTimeout: 10000,
    requestTimeout: 15000,
    enableRetry: true,
    enableCompression: true,
  );

  DeveloperSettings _developerSettings = const DeveloperSettings(
    enableDebugMode: false,
    enablePerformanceLogging: false,
    enableNetworkLogging: false,
    enableMemoryMonitoring: false,
    showPerformanceOverlay: false,
    logLevel: 1,
  );

  // مفاتيح التخزين
  static const String _performanceKey = 'performance_settings';
  static const String _networkKey = 'network_settings';
  static const String _developerKey = 'developer_settings';

  // Getters
  PerformanceSettings get performanceSettings => _performanceSettings;

  NetworkSettings get networkSettings => _networkSettings;

  DeveloperSettings get developerSettings => _developerSettings;

  // تحميل الإعدادات
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // تحميل إعدادات الأداء
      final performanceJson = prefs.getString(_performanceKey);
      if (performanceJson != null) {
        _performanceSettings = PerformanceSettings.fromJson(
          jsonDecode(performanceJson),
        );
      }

      // تحميل إعدادات الشبكة
      final networkJson = prefs.getString(_networkKey);
      if (networkJson != null) {
        _networkSettings = NetworkSettings.fromJson(
          jsonDecode(networkJson),
        );
      }

      // تحميل إعدادات المطور
      final developerJson = prefs.getString(_developerKey);
      if (developerJson != null) {
        _developerSettings = DeveloperSettings.fromJson(
          jsonDecode(developerJson),
        );
      }

      log('📱 تم تحميل الإعدادات المتقدمة');
      _applySettings();
    } catch (e) {
      log('❌ خطأ في تحميل الإعدادات: $e');
    }
  }

  // حفظ إعدادات الأداء
  Future<void> updatePerformanceSettings(PerformanceSettings settings) async {
    try {
      _performanceSettings = settings;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_performanceKey, jsonEncode(settings.toJson()));

      _applySettings();
      log('💾 تم حفظ إعدادات الأداء');
    } catch (e) {
      log('❌ خطأ في حفظ إعدادات الأداء: $e');
    }
  }

  // حفظ إعدادات الشبكة
  Future<void> updateNetworkSettings(NetworkSettings settings) async {
    try {
      _networkSettings = settings;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_networkKey, jsonEncode(settings.toJson()));

      _applySettings();
      log('💾 تم حفظ إعدادات الشبكة');
    } catch (e) {
      log('❌ خطأ في حفظ إعدادات الشبكة: $e');
    }
  }

  // حفظ إعدادات المطور
  Future<void> updateDeveloperSettings(DeveloperSettings settings) async {
    try {
      _developerSettings = settings;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_developerKey, jsonEncode(settings.toJson()));

      _applySettings();
      log('💾 تم حفظ إعدادات المطور');
    } catch (e) {
      log('❌ خطأ في حفظ إعدادات المطور: $e');
    }
  }

  // تطبيق الإعدادات على الأنظمة
  void _applySettings() {
    _applyPerformanceSettings();
    _applyNetworkSettings();
    _applyDeveloperSettings();
  }

  void _applyPerformanceSettings() {
    // تطبيق إعدادات الأداء على PriorityLoader
    /*
    PriorityLoader().updateSettings(
      maxConcurrentLoads: _performanceSettings.maxConcurrentLoads,
      maxImmediateLoads: (_performanceSettings.maxConcurrentLoads / 2).ceil(),
      maxHighLoads: _performanceSettings.maxConcurrentLoads - 1,
    );

    // تطبيق على VideoCache
    VideoCache().updateSettings(
      maxControllers: _performanceSettings.cacheSize,
      enableOptimization: _performanceSettings.enableMemoryOptimization,
    );
    */

    log('⚙️ تم تطبيق إعدادات الأداء');
  }

  void _applyNetworkSettings() {
    // تطبيق إعدادات الشبكة على OptimizedApiService
    /*
    OptimizedApiService().updateSettings(
      connectionTimeout: Duration(milliseconds: _networkSettings.connectionTimeout),
      requestTimeout: Duration(milliseconds: _networkSettings.requestTimeout),
      enableRetry: _networkSettings.enableRetry,
      enableCompression: _networkSettings.enableCompression,
    );
    */

    log('🌐 تم تطبيق إعدادات الشبكة');
  }

  void _applyDeveloperSettings() {
    // تطبيق إعدادات المطور
    if (_developerSettings.enablePerformanceLogging) {
      // PerformanceMonitor().startMonitoring();
    }

    log('🛠️ تم تطبيق إعدادات المطور');
  }

  // إعدادات مُحددة مسبقاً
  static const Map<String, PerformanceSettings> presetSettings = {
    'power_saver': PerformanceSettings(
      maxConcurrentLoads: 1,
      preloadDistance: 1,
      cacheSize: 4,
      throttleDelay: Duration(milliseconds: 1000),
      enableBackgroundLoading: false,
      enablePreloading: false,
      enableMemoryOptimization: true,
      maxRetries: 2,
      videoQuality: 0.7,
    ),
    'balanced': PerformanceSettings(
      maxConcurrentLoads: 2,
      preloadDistance: 2,
      cacheSize: 8,
      throttleDelay: Duration(milliseconds: 500),
      enableBackgroundLoading: true,
      enablePreloading: true,
      enableMemoryOptimization: true,
      maxRetries: 3,
      videoQuality: 1.0,
    ),
    'performance': PerformanceSettings(
      maxConcurrentLoads: 4,
      preloadDistance: 3,
      cacheSize: 12,
      throttleDelay: Duration(milliseconds: 200),
      enableBackgroundLoading: true,
      enablePreloading: true,
      enableMemoryOptimization: false,
      maxRetries: 4,
      videoQuality: 1.0,
    ),
    'ultra': PerformanceSettings(
      maxConcurrentLoads: 6,
      preloadDistance: 4,
      cacheSize: 16,
      throttleDelay: Duration(milliseconds: 100),
      enableBackgroundLoading: true,
      enablePreloading: true,
      enableMemoryOptimization: false,
      maxRetries: 5,
      videoQuality: 1.0,
    ),
  };

  // تطبيق إعداد مُحدد مسبقاً
  Future<void> applyPreset(String presetName) async {
    final preset = presetSettings[presetName];
    if (preset != null) {
      await updatePerformanceSettings(preset);
      log('🎛️ تم تطبيق الإعداد المُحدد مسبقاً: $presetName');
    }
  }

  // تحسين تلقائي بناءً على أداء الجهاز
  Future<void> autoOptimize() async {
    try {
      log('🤖 بدء التحسين التلقائي');

      // جمع معلومات النظام
      final deviceInfo = await _getDeviceInfo();
      final networkInfo = await _getNetworkInfo();
      final performanceInfo = await _getPerformanceInfo();

      // تحديد الإعداد الأمثل
      String optimalPreset = 'balanced';

      if (deviceInfo['isLowEnd']) {
        optimalPreset = 'power_saver';
      } else if (deviceInfo['isHighEnd'] && networkInfo['isWiFi']) {
        optimalPreset =
            performanceInfo['hasGoodPerformance'] ? 'ultra' : 'performance';
      } else if (networkInfo['isSlowNetwork']) {
        optimalPreset = 'power_saver';
      }

      await applyPreset(optimalPreset);

      log('✅ تم التحسين التلقائي: $optimalPreset');
    } catch (e) {
      log('❌ خطأ في التحسين التلقائي: $e');
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // محاكاة جمع معلومات الجهاز
    return {
      'isLowEnd': false,
      'isHighEnd': true,
      'availableMemory': 4096,
      'cpuCores': 8,
    };
  }

  Future<Map<String, dynamic>> _getNetworkInfo() async {
    // محاكاة جمع معلومات الشبكة
    return {
      'isWiFi': true,
      'isSlowNetwork': false,
      'bandwidth': 50000, // Kbps
    };
  }

  Future<Map<String, dynamic>> _getPerformanceInfo() async {
    // محاكاة جمع معلومات الأداء
    return {
      'hasGoodPerformance': true,
      'averageFPS': 60.0,
      'averageLoadTime': 1.5,
    };
  }

  // تصدير الإعدادات
  Map<String, dynamic> exportSettings() {
    return {
      'performance': _performanceSettings.toJson(),
      'network': _networkSettings.toJson(),
      'developer': _developerSettings.toJson(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  // استيراد الإعدادات
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings['performance'] != null) {
        await updatePerformanceSettings(
          PerformanceSettings.fromJson(settings['performance']),
        );
      }

      if (settings['network'] != null) {
        await updateNetworkSettings(
          NetworkSettings.fromJson(settings['network']),
        );
      }

      if (settings['developer'] != null) {
        await updateDeveloperSettings(
          DeveloperSettings.fromJson(settings['developer']),
        );
      }

      log('📥 تم استيراد الإعدادات بنجاح');
    } catch (e) {
      log('❌ خطأ في استيراد الإعدادات: $e');
    }
  }

  // إعادة تعيين الإعدادات للافتراضية
  Future<void> resetToDefaults() async {
    await updatePerformanceSettings(presetSettings['balanced']!);
    await updateNetworkSettings(const NetworkSettings(
      enableDataSaver: false,
      enableWifiOnlyHQ: true,
      connectionTimeout: 10000,
      requestTimeout: 15000,
      enableRetry: true,
      enableCompression: true,
    ));
    await updateDeveloperSettings(const DeveloperSettings(
      enableDebugMode: false,
      enablePerformanceLogging: false,
      enableNetworkLogging: false,
      enableMemoryMonitoring: false,
      showPerformanceOverlay: false,
      logLevel: 1,
    ));

    log('🔄 تم إعادة تعيين جميع الإعدادات');
  }

  // الحصول على ملخص الإعدادات
  Map<String, dynamic> getSettingsSummary() {
    return {
      'performance': {
        'maxConcurrentLoads': _performanceSettings.maxConcurrentLoads,
        'preloadDistance': _performanceSettings.preloadDistance,
        'cacheSize': _performanceSettings.cacheSize,
        'videoQuality': _performanceSettings.videoQuality,
      },
      'network': {
        'dataSaverEnabled': _networkSettings.enableDataSaver,
        'wifiOnlyHQ': _networkSettings.enableWifiOnlyHQ,
        'retryEnabled': _networkSettings.enableRetry,
      },
      'developer': {
        'debugMode': _developerSettings.enableDebugMode,
        'performanceLogging': _developerSettings.enablePerformanceLogging,
        'logLevel': _developerSettings.logLevel,
      },
    };
  }
}
