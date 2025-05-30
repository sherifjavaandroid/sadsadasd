import 'dart:collection';
import 'package:video_player/video_player.dart';
import 'package:bubbly/modal/user_video/user_video.dart';

class VideoCache {
  static final VideoCache _instance = VideoCache._internal();

  factory VideoCache() => _instance;

  VideoCache._internal();

  // كاش للفيديو controllers
  final Map<String, VideoPlayerController> _videoControllers = {};

  // كاش للبيانات
  final Map<String, List<Data>> _videosCache = {};

  // كاش للصفحات التالية
  final Map<String, bool> _hasMoreData = {};

  // آخر وقت تحديث للكاش
  final Map<String, DateTime> _lastUpdated = {};

  // مدة انتهاء صلاحية الكاش (5 دقائق)
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // الحد الأقصى لعدد الكونترولرز في الذاكرة
  static const int _maxControllers = 10;

  // Queue لتتبع ترتيب استخدام الكونترولرز
  final Queue<String> _controllerUsageQueue = Queue<String>();

  // إضافة فيديوهات للكاش
  void cacheVideos(String cacheKey, List<Data> videos, {bool hasMore = true}) {
    _videosCache[cacheKey] = List.from(videos);
    _hasMoreData[cacheKey] = hasMore;
    _lastUpdated[cacheKey] = DateTime.now();
  }

  // إضافة فيديوهات جديدة للكاش الموجود
  void appendVideos(String cacheKey, List<Data> newVideos,
      {bool hasMore = true}) {
    if (_videosCache.containsKey(cacheKey)) {
      _videosCache[cacheKey]!.addAll(newVideos);
    } else {
      _videosCache[cacheKey] = List.from(newVideos);
    }
    _hasMoreData[cacheKey] = hasMore;
    _lastUpdated[cacheKey] = DateTime.now();
  }

  // الحصول على الفيديوهات من الكاش
  List<Data>? getCachedVideos(String cacheKey) {
    if (!_videosCache.containsKey(cacheKey)) return null;

    final lastUpdate = _lastUpdated[cacheKey];
    if (lastUpdate != null &&
        DateTime.now().difference(lastUpdate) > _cacheExpiry) {
      // انتهت صلاحية الكاش
      clearVideoCache(cacheKey);
      return null;
    }

    return _videosCache[cacheKey];
  }

  // التحقق من وجود المزيد من البيانات
  bool hasMoreVideos(String cacheKey) {
    return _hasMoreData[cacheKey] ?? true;
  }

  // إدارة video controllers مع تحسين الذاكرة
  VideoPlayerController? getController(String videoUrl) {
    _updateControllerUsage(videoUrl);
    return _videoControllers[videoUrl];
  }

  Future<VideoPlayerController> getOrCreateController(String videoUrl) async {
    if (_videoControllers.containsKey(videoUrl)) {
      _updateControllerUsage(videoUrl);
      return _videoControllers[videoUrl]!;
    }

    // تنظيف الذاكرة إذا تجاوزنا الحد الأقصى
    if (_videoControllers.length >= _maxControllers) {
      await _cleanupOldControllers();
    }

    // إنشاء كونترولر جديد
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoControllers[videoUrl] = controller;
    _updateControllerUsage(videoUrl);

    return controller;
  }

  void _updateControllerUsage(String videoUrl) {
    // إزالة من الموضع الحالي إذا كان موجود
    _controllerUsageQueue.remove(videoUrl);
    // إضافة في المقدمة (الأحدث استخداماً)
    _controllerUsageQueue.addFirst(videoUrl);
  }

  Future<void> _cleanupOldControllers() async {
    // إزالة النصف الأقل استخداماً
    final controllersToRemove = _maxControllers ~/ 2;

    for (int i = 0;
        i < controllersToRemove && _controllerUsageQueue.isNotEmpty;
        i++) {
      final oldestUrl = _controllerUsageQueue.removeLast();
      final controller = _videoControllers.remove(oldestUrl);
      if (controller != null) {
        await controller.dispose();
      }
    }
  }

  // إزالة كونترولر محدد
  Future<void> removeController(String videoUrl) async {
    final controller = _videoControllers.remove(videoUrl);
    if (controller != null) {
      await controller.dispose();
    }
    _controllerUsageQueue.remove(videoUrl);
  }

  // مسح كاش الفيديوهات
  void clearVideoCache(String cacheKey) {
    _videosCache.remove(cacheKey);
    _hasMoreData.remove(cacheKey);
    _lastUpdated.remove(cacheKey);
  }

  // مسح جميع الكاش
  Future<void> clearAllCache() async {
    // تنظيف video controllers
    for (final controller in _videoControllers.values) {
      await controller.dispose();
    }
    _videoControllers.clear();
    _controllerUsageQueue.clear();

    // مسح كاش البيانات
    _videosCache.clear();
    _hasMoreData.clear();
    _lastUpdated.clear();
  }

  // تنظيف دوري للكاش المنتهي الصلاحية
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _lastUpdated.forEach((key, lastUpdate) {
      if (now.difference(lastUpdate) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      clearVideoCache(key);
    }
  }

  // الحصول على حالة الكاش
  Map<String, dynamic> getCacheStats() {
    return {
      'videosInCache': _videosCache.length,
      'controllersInMemory': _videoControllers.length,
      'totalCachedVideos': _videosCache.values.fold<int>(
        0,
        (sum, list) => sum + (list != null ? list.length : 0),
      ),
    };
  }
}
