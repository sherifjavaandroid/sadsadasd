import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/const_res.dart';

// أولوية التحميل
enum LoadPriority {
  immediate, // فوري (الفيديو الحالي)
  high, // عالي (الفيديو القادم)
  medium, // متوسط (الفيديوهات القريبة)
  low, // منخفض (الفيديوهات البعيدة)
  background, // خلفي (تحميل استباقي)
}

// مهمة تحميل
class LoadTask {
  final String id;
  final String videoUrl;
  final LoadPriority priority;
  final DateTime createdAt;
  final Completer<VideoPlayerController?> completer;
  final int videoIndex;

  bool isCompleted = false;
  bool isCancelled = false;

  LoadTask({
    required this.id,
    required this.videoUrl,
    required this.priority,
    required this.videoIndex,
  })  : createdAt = DateTime.now(),
        completer = Completer<VideoPlayerController?>();

  // مقارنة الأولوية
  int compareTo(LoadTask other) {
    // ترتيب حسب الأولوية أولاً
    final priorityComparison = priority.index.compareTo(other.priority.index);
    if (priorityComparison != 0) return priorityComparison;

    // ثم حسب وقت الإنشاء
    return createdAt.compareTo(other.createdAt);
  }
}

class PriorityLoader {
  static final PriorityLoader _instance = PriorityLoader._internal();

  factory PriorityLoader() => _instance;

  PriorityLoader._internal();

  // طوابير التحميل حسب الأولوية
  final Queue<LoadTask> _immediateQueue = Queue<LoadTask>();
  final Queue<LoadTask> _highQueue = Queue<LoadTask>();
  final Queue<LoadTask> _mediumQueue = Queue<LoadTask>();
  final Queue<LoadTask> _lowQueue = Queue<LoadTask>();
  final Queue<LoadTask> _backgroundQueue = Queue<LoadTask>();

  // المهام الجارية
  final Map<String, LoadTask> _activeTasks = {};
  final Map<String, VideoPlayerController> _loadedControllers = {};

  // إعدادات التحميل
  int _maxConcurrentLoads = 3;
  int _maxImmediateLoads = 2;
  int _maxHighLoads = 2;
  int _currentLoads = 0;

  // حالة النظام
  bool _isProcessing = false;
  Timer? _processingTimer;

  // إحصائيات
  int _totalTasksCreated = 0;
  int _totalTasksCompleted = 0;
  int _totalTasksCancelled = 0;

  // إضافة مهمة تحميل جديدة
  Future<VideoPlayerController?> loadVideo({
    required String videoUrl,
    required int videoIndex,
    required LoadPriority priority,
  }) async {
    // التحقق من وجود كونترولر محمل مسبقاً
    if (_loadedControllers.containsKey(videoUrl)) {
      log('📱 إرجاع كونترولر محمل مسبقاً: $videoIndex');
      return _loadedControllers[videoUrl];
    }

    // إنشاء مهمة جديدة
    final taskId = '${videoIndex}_${DateTime.now().millisecondsSinceEpoch}';
    final task = LoadTask(
      id: taskId,
      videoUrl: videoUrl,
      priority: priority,
      videoIndex: videoIndex,
    );

    _totalTasksCreated++;
    _activeTasks[taskId] = task;

    // إضافة المهمة للطابور المناسب
    _addToQueue(task);

    log('📋 إضافة مهمة تحميل: الفهرس $videoIndex، الأولوية ${priority.name}');

    // بدء المعالجة
    _startProcessing();

    return task.completer.future;
  }

  void _addToQueue(LoadTask task) {
    switch (task.priority) {
      case LoadPriority.immediate:
        _immediateQueue.addLast(task);
        break;
      case LoadPriority.high:
        _highQueue.addLast(task);
        break;
      case LoadPriority.medium:
        _mediumQueue.addLast(task);
        break;
      case LoadPriority.low:
        _lowQueue.addLast(task);
        break;
      case LoadPriority.background:
        _backgroundQueue.addLast(task);
        break;
    }
  }

  void _startProcessing() {
    if (_isProcessing) return;

    _isProcessing = true;
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _processQueues(),
    );
  }

  void _processQueues() {
    if (_currentLoads >= _maxConcurrentLoads) return;

    LoadTask? nextTask;

    // معالجة الطوابير حسب الأولوية
    if (_immediateQueue.isNotEmpty && _currentLoads < _maxImmediateLoads) {
      nextTask = _immediateQueue.removeFirst();
    } else if (_highQueue.isNotEmpty && _currentLoads < _maxHighLoads) {
      nextTask = _highQueue.removeFirst();
    } else if (_mediumQueue.isNotEmpty) {
      nextTask = _mediumQueue.removeFirst();
    } else if (_lowQueue.isNotEmpty) {
      nextTask = _lowQueue.removeFirst();
    } else if (_backgroundQueue.isNotEmpty) {
      nextTask = _backgroundQueue.removeFirst();
    }

    if (nextTask != null && !nextTask.isCancelled) {
      _currentLoads++;
      _executeLoadTask(nextTask);
    } else if (_isAllQueuesEmpty() && _currentLoads == 0) {
      _stopProcessing();
    }
  }

  Future<void> _executeLoadTask(LoadTask task) async {
    log('🎬 بدء تحميل الفيديو: ${task.videoIndex} (${task.priority.name})');

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(task.videoUrl),
      );

      // تحديد timeout حسب الأولوية
      final timeout = _getTimeoutForPriority(task.priority);

      await controller.initialize().timeout(timeout);

      if (!task.isCancelled) {
        _loadedControllers[task.videoUrl] = controller;
        task.completer.complete(controller);
        task.isCompleted = true;
        _totalTasksCompleted++;

        log('✅ تم تحميل الفيديو بنجاح: ${task.videoIndex}');
      } else {
        await controller.dispose();
        task.completer.complete(null);
        _totalTasksCancelled++;

        log('❌ تم إلغاء تحميل الفيديو: ${task.videoIndex}');
      }
    } catch (e) {
      log('❌ فشل تحميل الفيديو ${task.videoIndex}: $e');
      task.completer.complete(null);
    } finally {
      _currentLoads--;
      _activeTasks.remove(task.id);
    }
  }

  Duration _getTimeoutForPriority(LoadPriority priority) {
    switch (priority) {
      case LoadPriority.immediate:
        return const Duration(seconds: 10);
      case LoadPriority.high:
        return const Duration(seconds: 15);
      case LoadPriority.medium:
        return const Duration(seconds: 20);
      case LoadPriority.low:
        return const Duration(seconds: 30);
      case LoadPriority.background:
        return const Duration(seconds: 45);
    }
  }

  bool _isAllQueuesEmpty() {
    return _immediateQueue.isEmpty &&
        _highQueue.isEmpty &&
        _mediumQueue.isEmpty &&
        _lowQueue.isEmpty &&
        _backgroundQueue.isEmpty;
  }

  void _stopProcessing() {
    _isProcessing = false;
    _processingTimer?.cancel();
    log('⏹️ إيقاف معالج التحميل');
  }

  // إلغاء مهام تحميل محددة
  void cancelTasksForIndices(List<int> indices) {
    final indicesToCancel = Set<int>.from(indices);

    _activeTasks.values
        .where((task) => indicesToCancel.contains(task.videoIndex))
        .forEach((task) {
      task.isCancelled = true;
      _totalTasksCancelled++;
    });

    // إزالة من الطوابير
    _removeFromQueues((task) => indicesToCancel.contains(task.videoIndex));

    log('❌ إلغاء مهام التحميل للفهارس: $indices');
  }

  void _removeFromQueues(bool Function(LoadTask) predicate) {
    _immediateQueue.removeWhere(predicate);
    _highQueue.removeWhere(predicate);
    _mediumQueue.removeWhere(predicate);
    _lowQueue.removeWhere(predicate);
    _backgroundQueue.removeWhere(predicate);
  }

  // تحديث أولويات التحميل بناءً على الموضع الحالي
  void updatePriorities({
    required int currentIndex,
    required int totalVideos,
    int preloadRange = 2,
  }) {
    // إلغاء المهام البعيدة
    final distantIndices = <int>[];

    for (int i = 0; i < totalVideos; i++) {
      final distance = (i - currentIndex).abs();
      if (distance > preloadRange + 2) {
        distantIndices.add(i);
      }
    }

    if (distantIndices.isNotEmpty) {
      cancelTasksForIndices(distantIndices);

      // إزالة الكونترولرز البعيدة
      _cleanupDistantControllers(distantIndices);
    }
  }

  void _cleanupDistantControllers(List<int> indices) {
    final controllersToRemove = <String>[];

    _loadedControllers.forEach((url, controller) {
      // استخراج الفهرس من URL إذا أمكن
      for (final index in indices) {
        if (url.contains('video_$index') || url.contains('/$index/')) {
          controllersToRemove.add(url);
          break;
        }
      }
    });

    for (final url in controllersToRemove) {
      final controller = _loadedControllers.remove(url);
      controller?.dispose();
    }

    log('🧹 تنظيف ${controllersToRemove.length} كونترولر بعيد');
  }

  // الحصول على كونترولر محمل
  VideoPlayerController? getLoadedController(String videoUrl) {
    return _loadedControllers[videoUrl];
  }

  // تحديد أولوية تحميل بناءً على المسافة
  LoadPriority getPriorityForIndex(int targetIndex, int currentIndex) {
    final distance = (targetIndex - currentIndex).abs();

    if (targetIndex == currentIndex) {
      return LoadPriority.immediate;
    } else if (distance == 1) {
      return LoadPriority.high;
    } else if (distance <= 2) {
      return LoadPriority.medium;
    } else if (distance <= 4) {
      return LoadPriority.low;
    } else {
      return LoadPriority.background;
    }
  }

  // إحصائيات الأداء
  Map<String, dynamic> getStats() {
    return {
      'totalTasksCreated': _totalTasksCreated,
      'totalTasksCompleted': _totalTasksCompleted,
      'totalTasksCancelled': _totalTasksCancelled,
      'activeTasksCount': _activeTasks.length,
      'loadedControllersCount': _loadedControllers.length,
      'currentLoads': _currentLoads,
      'queueSizes': {
        'immediate': _immediateQueue.length,
        'high': _highQueue.length,
        'medium': _mediumQueue.length,
        'low': _lowQueue.length,
        'background': _backgroundQueue.length,
      },
      'successRate': _totalTasksCreated > 0
          ? (_totalTasksCompleted / _totalTasksCreated) * 100
          : 0.0,
    };
  }

  // طباعة تقرير مفصل
  void printDetailedStats() {
    final stats = getStats();

    print('\n' + '=' * 50);
    print('📊 إحصائيات PriorityLoader');
    print('=' * 50);
    print('إجمالي المهام: ${stats['totalTasksCreated']}');
    print('المهام المكتملة: ${stats['totalTasksCompleted']}');
    print('المهام الملغاة: ${stats['totalTasksCancelled']}');
    print(
        'معدل النجاح: ${(stats['successRate'] as double).toStringAsFixed(1)}%');
    print('التحميلات الحالية: ${stats['currentLoads']}/$_maxConcurrentLoads');
    print('الكونترولرز المحملة: ${stats['loadedControllersCount']}');

    final queueSizes = stats['queueSizes'] as Map<String, dynamic>;
    print('\nأحجام الطوابير:');
    queueSizes.forEach((priority, size) {
      print('  $priority: $size');
    });

    print('=' * 50 + '\n');
  }

  // تنظيف شامل
  void clearAll() {
    // إلغاء جميع المهام
    _activeTasks.values.forEach((task) {
      task.isCancelled = true;
    });

    // مسح الطوابير
    _immediateQueue.clear();
    _highQueue.clear();
    _mediumQueue.clear();
    _lowQueue.clear();
    _backgroundQueue.clear();

    // تنظيف الكونترولرز
    _loadedControllers.values.forEach((controller) {
      controller.dispose();
    });
    _loadedControllers.clear();

    // إعادة تعيين المتغيرات
    _activeTasks.clear();
    _currentLoads = 0;

    _stopProcessing();

    log('🧹 تنظيف شامل لـ PriorityLoader');
  }

  // تحديث إعدادات التحميل
  void updateSettings({
    int? maxConcurrentLoads,
    int? maxImmediateLoads,
    int? maxHighLoads,
  }) {
    if (maxConcurrentLoads != null) {
      _maxConcurrentLoads = maxConcurrentLoads;
    }
    if (maxImmediateLoads != null) {
      _maxImmediateLoads = maxImmediateLoads;
    }
    if (maxHighLoads != null) {
      _maxHighLoads = maxHighLoads;
    }

    log('⚙️ تحديث إعدادات التحميل: concurrent=$_maxConcurrentLoads, immediate=$_maxImmediateLoads, high=$_maxHighLoads');
  }

  void dispose() {
    clearAll();
  }
}
