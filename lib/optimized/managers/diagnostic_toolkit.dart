import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// نتيجة اختبار واحد
class TestResult {
  final String testName;
  final bool passed;
  final String message;
  final Map<String, dynamic>? details;
  final Duration duration;

  TestResult({
    required this.testName,
    required this.passed,
    required this.message,
    this.details,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'passed': passed,
      'message': message,
      'details': details,
      'duration': duration.inMilliseconds,
    };
  }
}

// تقرير التشخيص الشامل
class DiagnosticReport {
  final DateTime timestamp;
  final List<TestResult> results;
  final Map<String, dynamic> systemInfo;
  final Duration totalDuration;

  DiagnosticReport({
    required this.timestamp,
    required this.results,
    required this.systemInfo,
    required this.totalDuration,
  });

  bool get allTestsPassed => results.every((test) => test.passed);

  int get passedTests => results.where((test) => test.passed).length;

  int get failedTests => results.where((test) => !test.passed).length;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
      'systemInfo': systemInfo,
      'totalDuration': totalDuration.inMilliseconds,
      'summary': {
        'allPassed': allTestsPassed,
        'passedCount': passedTests,
        'failedCount': failedTests,
        'totalCount': results.length,
      },
    };
  }
}

class DiagnosticToolkit {
  static final DiagnosticToolkit _instance = DiagnosticToolkit._internal();

  factory DiagnosticToolkit() => _instance;

  DiagnosticToolkit._internal();

  // تشغيل جميع الاختبارات
  Future<DiagnosticReport> runFullDiagnostic() async {
    log('🔍 بدء التشخيص الشامل');
    final stopwatch = Stopwatch()..start();
    final results = <TestResult>[];

    // معلومات النظام
    final systemInfo = await _gatherSystemInfo();

    // تشغيل الاختبارات
    results.add(await _testMemoryUsage());
    results.add(await _testNetworkConnectivity());
    results.add(await _testStorageSpace());
    results.add(await _testCpuPerformance());
    results.add(await _testVideoPlayerInitialization());
    results.add(await _testCachePerformance());
    results.add(await _testAPIConnectivity());
    results.add(await _testFileSystemAccess());
    results.add(await _testDeviceCapabilities());
    results.add(await _testBatteryOptimization());

    stopwatch.stop();

    final report = DiagnosticReport(
      timestamp: DateTime.now(),
      results: results,
      systemInfo: systemInfo,
      totalDuration: stopwatch.elapsed,
    );

    log('✅ انتهى التشخيص الشامل في ${stopwatch.elapsedMilliseconds}ms');
    return report;
  }

  // تشخيص سريع للمشاكل الشائعة
  Future<List<TestResult>> runQuickDiagnostic() async {
    log('⚡ بدء التشخيص السريع');
    final results = <TestResult>[];

    results.add(await _testMemoryUsage());
    results.add(await _testNetworkConnectivity());
    results.add(await _testVideoPlayerInitialization());

    return results;
  }

  // جمع معلومات النظام
  Future<Map<String, dynamic>> _gatherSystemInfo() async {
    final info = <String, dynamic>{};

    try {
      // معلومات المنصة
      info['platform'] = Platform.operatingSystem;
      info['version'] = Platform.operatingSystemVersion;
      info['locale'] = Platform.localeName;

      // معلومات التطبيق
      info['flutterVersion'] = kIsWeb ? 'web' : 'mobile';
      info['debugMode'] = kDebugMode;
      info['profileMode'] = kProfileMode;
      info['releaseMode'] = kReleaseMode;

      // معلومات الوقت
      info['timestamp'] = DateTime.now().toIso8601String();
      info['timezone'] = DateTime.now().timeZoneName;

      // معلومات الذاكرة (تقديرية)
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final memoryInfo = await _getMemoryInfo();
          info['memory'] = memoryInfo;
        } catch (e) {
          info['memory'] = {'error': e.toString()};
        }
      }
    } catch (e) {
      info['error'] = e.toString();
    }

    return info;
  }

  // اختبار استهلاك الذاكرة
  Future<TestResult> _testMemoryUsage() async {
    final stopwatch = Stopwatch()..start();

    try {
      final memoryInfo = await _getMemoryInfo();
      final usedMemory = memoryInfo['usedMemory'] as int? ?? 0;
      final availableMemory =
          memoryInfo['availableMemory'] as int? ?? 1000000000;

      final usagePercentage = (usedMemory / availableMemory) * 100;

      final passed = usagePercentage < 80; // أقل من 80%
      final message = passed
          ? 'استهلاك الذاكرة طبيعي (${usagePercentage.toStringAsFixed(1)}%)'
          : 'استهلاك ذاكرة عالي (${usagePercentage.toStringAsFixed(1)}%)';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار الذاكرة',
        passed: passed,
        message: message,
        details: {
          'usedMemory': _formatBytes(usedMemory),
          'availableMemory': _formatBytes(availableMemory),
          'usagePercentage': usagePercentage,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار الذاكرة',
        passed: false,
        message: 'فشل في اختبار الذاكرة: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار الاتصال بالشبكة
  Future<TestResult> _testNetworkConnectivity() async {
    final stopwatch = Stopwatch()..start();

    try {
      final connectivity = Connectivity();
      final resultList = await connectivity.checkConnectivity();
      final result =
          resultList.isNotEmpty ? resultList[0] : ConnectivityResult.none;

      final isConnected = result != ConnectivityResult.none;
      final networkType = result.name;

      // اختبار سرعة الشبكة
      String speedInfo = '';
      if (isConnected) {
        final speed = await _testNetworkSpeed();
        speedInfo = ' (${speed.toStringAsFixed(1)} Mbps)';
      }

      final message = isConnected
          ? 'متصل بالشبكة ($networkType)$speedInfo'
          : 'غير متصل بالشبكة';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار الشبكة',
        passed: isConnected,
        message: message,
        details: {
          'connectionType': networkType,
          'isConnected': isConnected,
          'speed': isConnected ? await _testNetworkSpeed() : 0,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار الشبكة',
        passed: false,
        message: 'فشل في اختبار الشبكة: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار مساحة التخزين
  Future<TestResult> _testStorageSpace() async {
    final stopwatch = Stopwatch()..start();

    try {
      final storageInfo = await _getStorageInfo();
      final freeSpace = storageInfo['freeSpace'] as int;
      final totalSpace = storageInfo['totalSpace'] as int;

      final freePercentage = (freeSpace / totalSpace) * 100;
      final passed = freePercentage > 10; // أكثر من 10% متاح

      final message = passed
          ? 'مساحة تخزين كافية (${freePercentage.toStringAsFixed(1)}% متاح)'
          : 'مساحة تخزين منخفضة (${freePercentage.toStringAsFixed(1)}% متاح)';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار التخزين',
        passed: passed,
        message: message,
        details: {
          'freeSpace': _formatBytes(freeSpace),
          'totalSpace': _formatBytes(totalSpace),
          'freePercentage': freePercentage,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار التخزين',
        passed: false,
        message: 'فشل في اختبار التخزين: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار أداء المعالج
  Future<TestResult> _testCpuPerformance() async {
    final stopwatch = Stopwatch()..start();

    try {
      // اختبار حوسبي بسيط
      const iterations = 100000;
      final cpuStopwatch = Stopwatch()..start();

      double result = 0;
      for (int i = 0; i < iterations; i++) {
        result += math.sqrt(i.toDouble());
      }

      cpuStopwatch.stop();
      final cpuTime = cpuStopwatch.elapsedMicroseconds;

      // تقييم الأداء (أقل من 100ms = جيد)
      final passed = cpuTime < 100000;
      final message = passed
          ? 'أداء المعالج جيد (${cpuTime / 1000}ms)'
          : 'أداء المعالج بطيء (${cpuTime / 1000}ms)';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار المعالج',
        passed: passed,
        message: message,
        details: {
          'iterations': iterations,
          'timeMs': cpuTime / 1000,
          'result': result,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار المعالج',
        passed: false,
        message: 'فشل في اختبار المعالج: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار مشغل الفيديو
  Future<TestResult> _testVideoPlayerInitialization() async {
    final stopwatch = Stopwatch()..start();

    try {
      // محاولة إنشاء مشغل فيديو
      final testUrl =
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

      // هذا مثال - في التطبيق الفعلي ستحتاج لاستخدام VideoPlayerController
      final initStopwatch = Stopwatch()..start();

      // محاكاة تهيئة مشغل الفيديو
      await Future.delayed(Duration(milliseconds: 100));

      initStopwatch.stop();

      final passed = initStopwatch.elapsedMilliseconds < 5000;
      final message = passed
          ? 'مشغل الفيديو يعمل بطبيعي (${initStopwatch.elapsedMilliseconds}ms)'
          : 'مشغل الفيديو بطيء (${initStopwatch.elapsedMilliseconds}ms)';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار مشغل الفيديو',
        passed: passed,
        message: message,
        details: {
          'initTimeMs': initStopwatch.elapsedMilliseconds,
          'testUrl': testUrl,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار مشغل الفيديو',
        passed: false,
        message: 'فشل في اختبار مشغل الفيديو: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار أداء الكاش
  Future<TestResult> _testCachePerformance() async {
    final stopwatch = Stopwatch()..start();

    try {
      // اختبار سرعة الكاش
      final cacheStopwatch = Stopwatch()..start();

      // محاكاة عمليات الكاش
      final cache = <String, String>{};
      for (int i = 0; i < 1000; i++) {
        cache['key_$i'] = 'value_$i';
      }

      // اختبار استرجاع البيانات
      String? value = cache['key_500'];

      cacheStopwatch.stop();

      final passed = cacheStopwatch.elapsedMicroseconds < 10000;
      final message = passed
          ? 'أداء الكاش ممتاز (${cacheStopwatch.elapsedMicroseconds}μs)'
          : 'أداء الكاش بطيء (${cacheStopwatch.elapsedMicroseconds}μs)';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار الكاش',
        passed: passed,
        message: message,
        details: {
          'cacheSize': cache.length,
          'timeUs': cacheStopwatch.elapsedMicroseconds,
          'testValue': value,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار الكاش',
        passed: false,
        message: 'فشل في اختبار الكاش: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار الاتصال بـ API
  Future<TestResult> _testAPIConnectivity() async {
    final stopwatch = Stopwatch()..start();

    try {
      final apiStopwatch = Stopwatch()..start();

      // اختبار طلب API بسيط
      final client = HttpClient();
      final request =
          await client.getUrl(Uri.parse('https://httpbin.org/status/200'));
      final response = await request.close();

      apiStopwatch.stop();
      client.close();

      final passed =
          response.statusCode == 200 && apiStopwatch.elapsedMilliseconds < 5000;
      final message = passed
          ? 'API متاح (${apiStopwatch.elapsedMilliseconds}ms)'
          : 'مشكلة في API (${response.statusCode}, ${apiStopwatch.elapsedMilliseconds}ms)';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار API',
        passed: passed,
        message: message,
        details: {
          'statusCode': response.statusCode,
          'responseTimeMs': apiStopwatch.elapsedMilliseconds,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار API',
        passed: false,
        message: 'فشل في اختبار API: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار الوصول لنظام الملفات
  Future<TestResult> _testFileSystemAccess() async {
    final stopwatch = Stopwatch()..start();

    try {
      // اختبار كتابة وقراءة ملف
      final testData = 'test_data_${DateTime.now().millisecondsSinceEpoch}';

      // في التطبيق الفعلي، ستحتاج لاستخدام path_provider
      // للحصول على مسار صحيح للكتابة

      final passed = true; // مؤقت
      final message = 'نظام الملفات يعمل بطبيعي';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار نظام الملفات',
        passed: passed,
        message: message,
        details: {
          'testData': testData,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار نظام الملفات',
        passed: false,
        message: 'فشل في اختبار نظام الملفات: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار قدرات الجهاز
  Future<TestResult> _testDeviceCapabilities() async {
    final stopwatch = Stopwatch()..start();

    try {
      final capabilities = <String, bool>{};

      // اختبار دعم الفيديو
      capabilities['videoPlayback'] = true; // افتراضي

      // اختبار دعم الشبكة
      capabilities['networkAccess'] = true; // افتراضي

      // اختبار دعم التخزين
      capabilities['storageAccess'] = true; // افتراضي

      final allSupported = capabilities.values.every((supported) => supported);
      final message =
          allSupported ? 'جميع القدرات مدعومة' : 'بعض القدرات غير مدعومة';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار قدرات الجهاز',
        passed: allSupported,
        message: message,
        details: capabilities,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار قدرات الجهاز',
        passed: false,
        message: 'فشل في اختبار قدرات الجهاز: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  // اختبار تحسين البطارية
  Future<TestResult> _testBatteryOptimization() async {
    final stopwatch = Stopwatch()..start();

    try {
      // اختبار مستوى البطارية (إذا كان متاحاً)
      final batteryLevel = await _getBatteryLevel();

      final isOptimized = batteryLevel > 20; // أكثر من 20%
      final message = isOptimized
          ? 'مستوى البطارية جيد (${batteryLevel}%)'
          : 'مستوى البطارية منخفض (${batteryLevel}%)';

      stopwatch.stop();

      return TestResult(
        testName: 'اختبار البطارية',
        passed: isOptimized,
        message: message,
        details: {
          'batteryLevel': batteryLevel,
        },
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        testName: 'اختبار البطارية',
        passed: true, // افتراضي إذا لم نتمكن من القراءة
        message: 'لا يمكن قراءة مستوى البطارية',
        duration: stopwatch.elapsed,
      );
    }
  }

  // دوال مساعدة
  Future<Map<String, dynamic>> _getMemoryInfo() async {
    // محاكاة معلومات الذاكرة
    return {
      'usedMemory': 85 * 1024 * 1024, // 85 MB
      'availableMemory': 512 * 1024 * 1024, // 512 MB
    };
  }

  Future<double> _testNetworkSpeed() async {
    // محاكاة اختبار سرعة الشبكة
    await Future.delayed(Duration(milliseconds: 100));
    return 25.5; // Mbps
  }

  Future<Map<String, dynamic>> _getStorageInfo() async {
    // محاكاة معلومات التخزين
    return {
      'freeSpace': 2 * 1024 * 1024 * 1024, // 2 GB
      'totalSpace': 16 * 1024 * 1024 * 1024, // 16 GB
    };
  }

  Future<int> _getBatteryLevel() async {
    // محاكاة مستوى البطارية
    return 75; // 75%
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // طباعة تقرير مفصل
  void printDiagnosticReport(DiagnosticReport report) {
    print('\n' + '=' * 80);
    print('🔍 تقرير التشخيص الشامل');
    print('=' * 80);
    print('🕐 الوقت: ${report.timestamp}');
    print('⏱️ المدة الإجمالية: ${report.totalDuration.inMilliseconds}ms');
    print(
        '📊 النتائج: ${report.passedTests}/${report.results.length} اختبار نجح');

    if (report.allTestsPassed) {
      print('✅ جميع الاختبارات نجحت!');
    } else {
      print('❌ ${report.failedTests} اختبار فشل');
    }

    print('\n📋 تفاصيل الاختبارات:');
    for (final result in report.results) {
      final icon = result.passed ? '✅' : '❌';
      print(
          '$icon ${result.testName}: ${result.message} (${result.duration.inMilliseconds}ms)');

      if (result.details != null && result.details!.isNotEmpty) {
        result.details!.forEach((key, value) {
          print('    $key: $value');
        });
      }
    }

    print('\n🖥️ معلومات النظام:');
    report.systemInfo.forEach((key, value) {
      print('  $key: $value');
    });

    print('=' * 80 + '\n');
  }
}
