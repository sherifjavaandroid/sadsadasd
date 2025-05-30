import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/const_res.dart';

import '../code/performance_monitor.dart';
import '../code/priority_loader.dart';
import '../code/video_cache.dart';

// نوع التحميل
enum LoadingStrategy {
  aggressive, // تحميل سريع
  balanced, // متوازن
  conservative, // محافظ (للأجهزة الضعيفة)
}

class SmoothVideoList extends StatefulWidget {
  final List<Data> videos;
  final int initialIndex;
  final Widget Function(BuildContext, Data, VideoPlayerController?) itemBuilder;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final LoadingStrategy strategy;

  const SmoothVideoList({
    Key? key,
    required this.videos,
    required this.itemBuilder,
    this.initialIndex = 0,
    this.onLoadMore,
    this.hasMore = true,
    this.strategy = LoadingStrategy.balanced,
  }) : super(key: key);

  @override
  State<SmoothVideoList> createState() => _SmoothVideoListState();
}

class _SmoothVideoListState extends State<SmoothVideoList>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  late ScrollController _scrollController;

  int _currentIndex = 0;
  bool _isScrolling = false;

  // أنظمة الإدارة
  final VideoCache _videoCache = VideoCache();
  final PriorityLoader _priorityLoader = PriorityLoader();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // إعدادات التحميل حسب الاستراتيجية
  late int _preloadRange;
  late int _maxSimultaneousLoads;
  late Duration _scrollThrottleDuration;

  // حالة التحميل
  final Map<int, bool> _loadingStates = {};
  final Map<int, bool> _errorStates = {};

  // مؤقتات
  Timer? _scrollEndTimer;
  Timer? _preloadTimer;
  Timer? _memoryCleanupTimer;

  // إحصائيات
  int _totalScrolls = 0;
  int _successfulLoads = 0;
  int _failedLoads = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _setupControllers();
    _startPerformanceMonitoring();
    _initializeInitialVideos();
  }

  void _initializeSettings() {
    switch (widget.strategy) {
      case LoadingStrategy.aggressive:
        _preloadRange = 3;
        _maxSimultaneousLoads = 4;
        _scrollThrottleDuration = const Duration(milliseconds: 100);
        break;
      case LoadingStrategy.balanced:
        _preloadRange = 2;
        _maxSimultaneousLoads = 3;
        _scrollThrottleDuration = const Duration(milliseconds: 200);
        break;
      case LoadingStrategy.conservative:
        _preloadRange = 1;
        _maxSimultaneousLoads = 2;
        _scrollThrottleDuration = const Duration(milliseconds: 500);
        break;
    }

    // تحديث إعدادات PriorityLoader
    _priorityLoader.updateSettings(
      maxConcurrentLoads: _maxSimultaneousLoads,
      maxImmediateLoads: 2,
      maxHighLoads: 2,
    );
  }

  void _setupControllers() {
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _scrollController = ScrollController();

    // مراقبة أحداث التمرير
    _pageController.addListener(_onPageScroll);
  }

  void _startPerformanceMonitoring() {
    _performanceMonitor.startMonitoring();

    // تنظيف دوري للذاكرة
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _performMemoryCleanup(),
    );
  }

  Future<void> _initializeInitialVideos() async {
    // تحميل الفيديو الحالي والقادم
    final indicesToLoad = <int>[];

    // الفيديو الحالي
    indicesToLoad.add(_currentIndex);

    // الفيديوهات القادمة حسب النطاق
    for (int i = 1; i <= _preloadRange; i++) {
      if (_currentIndex + i < widget.videos.length) {
        indicesToLoad.add(_currentIndex + i);
      }
      if (_currentIndex - i >= 0) {
        indicesToLoad.add(_currentIndex - i);
      }
    }

    // تحميل متوازي
    await Future.wait(
      indicesToLoad.map((index) => _loadVideoWithPriority(index)),
    );

    // تشغيل الفيديو الحالي
    _playVideoAtIndex(_currentIndex);
  }

  Future<void> _loadVideoWithPriority(int index) async {
    if (index < 0 || index >= widget.videos.length) return;
    if (_loadingStates[index] == true) return;

    _loadingStates[index] = true;
    _errorStates[index] = false;

    final video = widget.videos[index];
    final videoUrl = ConstRes.itemBaseUrl + (video.postVideo ?? '');

    // تحديد الأولوية
    final priority = _priorityLoader.getPriorityForIndex(index, _currentIndex);

    try {
      _performanceMonitor.recordNetworkRequest('loadVideo');

      final controller = await _priorityLoader.loadVideo(
        videoUrl: videoUrl,
        videoIndex: index,
        priority: priority,
      );

      if (controller != null && mounted) {
        _successfulLoads++;
        _performanceMonitor.recordVideoLoad(fromCache: false);

        log('✅ تحميل ناجح للفيديو $index');
        setState(() {
          _loadingStates[index] = false;
        });
      } else {
        throw Exception('فشل في إنشاء الكونترولر');
      }
    } catch (e) {
      _failedLoads++;
      _errorStates[index] = true;
      _loadingStates[index] = false;

      _performanceMonitor.recordError('Video load failed: $e');
      log('❌ فشل تحميل الفيديو $index: $e');

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;

    final page = _pageController.page;
    if (page == null) return;

    final newIndex = page.round();

    if (newIndex != _currentIndex) {
      _onPageChanged(newIndex);
    }

    // تحديد حالة التمرير
    _isScrolling = true;
    _scheduleScrollEndDetection();
  }

  void _scheduleScrollEndDetection() {
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(_scrollThrottleDuration, () {
      if (mounted) {
        _isScrolling = false;
        _onScrollEnd();
      }
    });
  }

  void _onPageChanged(int newIndex) {
    if (newIndex == _currentIndex) return;

    _totalScrolls++;
    final oldIndex = _currentIndex;
    _currentIndex = newIndex;

    log('📱 تغيير الصفحة: $oldIndex → $newIndex');

    // إيقاف الفيديو السابق
    _pauseVideoAtIndex(oldIndex);

    // تشغيل الفيديو الجديد
    _playVideoAtIndex(newIndex);

    // تحديث أولويات التحميل
    _updateLoadingPriorities();

    // تحميل الفيديوهات القادمة
    _schedulePreloading();

    // تحقق من الحاجة لتحميل المزيد
    _checkForLoadMore();
  }

  void _playVideoAtIndex(int index) {
    if (index < 0 || index >= widget.videos.length) return;

    final video = widget.videos[index];
    final videoUrl = ConstRes.itemBaseUrl + (video.postVideo ?? '');
    final controller = _priorityLoader.getLoadedController(videoUrl);

    if (controller != null && controller.value.isInitialized) {
      controller.play();
      controller.setLooping(true);

      // تسجيل المشاهدة (مع throttling)
      _recordViewCount(video.postId.toString());

      log('▶️ تشغيل الفيديو $index');
    } else {
      // تحميل فوري إذا لم يكن محملاً
      _loadVideoWithPriority(index);
    }
  }

  void _pauseVideoAtIndex(int index) {
    if (index < 0 || index >= widget.videos.length) return;

    final video = widget.videos[index];
    final videoUrl = ConstRes.itemBaseUrl + (video.postVideo ?? '');
    final controller = _priorityLoader.getLoadedController(videoUrl);

    if (controller != null && controller.value.isPlaying) {
      controller.pause();
      log('⏸️ إيقاف الفيديو $index');
    }
  }

  void _updateLoadingPriorities() {
    _priorityLoader.updatePriorities(
      currentIndex: _currentIndex,
      totalVideos: widget.videos.length,
      preloadRange: _preloadRange,
    );
  }

  void _schedulePreloading() {
    _preloadTimer?.cancel();
    _preloadTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !_isScrolling) {
        _preloadAdjacentVideos();
      }
    });
  }

  void _preloadAdjacentVideos() {
    final indicesToPreload = <int>[];

    for (int i = 1; i <= _preloadRange; i++) {
      // الفيديوهات القادمة
      if (_currentIndex + i < widget.videos.length) {
        indicesToPreload.add(_currentIndex + i);
      }
      // الفيديوهات السابقة
      if (_currentIndex - i >= 0) {
        indicesToPreload.add(_currentIndex - i);
      }
    }

    // تحميل متوازي للفيديوهات المطلوبة
    for (final index in indicesToPreload) {
      if (_loadingStates[index] != true && _errorStates[index] != true) {
        _loadVideoWithPriority(index);
      }
    }
  }

  void _onScrollEnd() {
    log('📜 انتهاء التمرير في الفهرس $_currentIndex');

    // تنظيف الذاكرة إذا لزم الأمر
    _checkMemoryUsage();

    // طباعة إحصائيات أداء دورية
    if (_totalScrolls % 10 == 0) {
      _printPerformanceStats();
    }
  }

  void _checkForLoadMore() {
    if (widget.onLoadMore != null &&
        widget.hasMore &&
        _currentIndex >= widget.videos.length - 3) {
      log('📥 تحميل المزيد من المحتوى');
      widget.onLoadMore!();
    }
  }

  void _recordViewCount(String postId) {
    // استخدام throttling لتجنب الطلبات المتكررة
    // يتم التعامل مع هذا في PriorityLoader أو ApiService
  }

  void _performMemoryCleanup() {
    log('🧹 تنظيف دوري للذاكرة');

    // تنظيف الكاش المنتهي الصلاحية
    _videoCache.cleanupExpiredCache();

    // تنظيف الفيديوهات البعيدة
    _priorityLoader.updatePriorities(
      currentIndex: _currentIndex,
      totalVideos: widget.videos.length,
      preloadRange: _preloadRange,
    );

    // إجبار garbage collection في وضع التطوير
    if (kDebugMode) {
      SystemChannels.platform.invokeMethod('Runtime.gc');
    }
  }

  void _checkMemoryUsage() {
    final stats = _priorityLoader.getStats();
    final loadedControllers = stats['loadedControllersCount'] as int;

    if (loadedControllers > _maxSimultaneousLoads * 2) {
      log('⚠️ استهلاك ذاكرة عالي: $loadedControllers كونترولر');
      _performMemoryCleanup();
    }
  }

  void _printPerformanceStats() {
    log('\n📊 إحصائيات الأداء (كل 10 تمريرات):');
    log('إجمالي التمريرات: $_totalScrolls');
    log('التحميلات الناجحة: $_successfulLoads');
    log('التحميلات الفاشلة: $_failedLoads');
    log('معدل النجاح: ${(_successfulLoads / (_successfulLoads + _failedLoads) * 100).toStringAsFixed(1)}%');

    _priorityLoader.printDetailedStats();
    _performanceMonitor.printDetailedReport();
  }

  Widget _buildVideoItem(int index) {
    if (index >= widget.videos.length) {
      return _buildLoadingPlaceholder();
    }

    final video = widget.videos[index];
    final videoUrl = ConstRes.itemBaseUrl + (video.postVideo ?? '');
    final controller = _priorityLoader.getLoadedController(videoUrl);

    // معالجة حالات التحميل والأخطاء
    if (_loadingStates[index] == true) {
      return _buildLoadingPlaceholder();
    }

    if (_errorStates[index] == true) {
      return _buildErrorPlaceholder(index);
    }

    return widget.itemBuilder(context, video, controller);
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الفيديو...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(int index) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'فشل في تحميل الفيديو',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _retryLoadVideo(index),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  void _retryLoadVideo(int index) {
    _errorStates[index] = false;
    _loadVideoWithPriority(index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const ClampingScrollPhysics(),
      itemCount: widget.videos.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.videos.length) {
          return _buildLoadingPlaceholder();
        }
        return _buildVideoItem(index);
      },
    );
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _preloadTimer?.cancel();
    _memoryCleanupTimer?.cancel();

    _pageController.dispose();
    _scrollController.dispose();

    _performanceMonitor.stopMonitoring();

    // طباعة إحصائيات نهائية
    _printFinalStats();

    super.dispose();
  }

  void _printFinalStats() {
    log('\n📊 الإحصائيات النهائية لـ SmoothVideoList:');
    log('إجمالي التمريرات: $_totalScrolls');
    log('التحميلات الناجحة: $_successfulLoads');
    log('التحميلات الفاشلة: $_failedLoads');

    if (_successfulLoads + _failedLoads > 0) {
      final successRate =
          (_successfulLoads / (_successfulLoads + _failedLoads)) * 100;
      log('معدل نجاح التحميل: ${successRate.toStringAsFixed(1)}%');
    }
  }
}
