import 'dart:developer';
import 'dart:async';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/data_not_found.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:bubbly/view/video/item_video.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../code/video_cache.dart';

// إضافة VideoCache

class OptimizedForYouScreen extends StatefulWidget {
  @override
  _OptimizedForYouScreenState createState() => _OptimizedForYouScreenState();
}

class _OptimizedForYouScreenState extends State<OptimizedForYouScreen>
    with AutomaticKeepAliveClientMixin {
  List<Data> mList = [];
  PageController pageController = PageController();
  int focusedIndex = 0;

  bool isLoading = false;
  bool isInitialLoading = true;
  bool hasMoreData = true;

  // نظام الكاشينج
  final VideoCache _videoCache = VideoCache();
  final String _cacheKey = 'for_you_videos';

  // تحسين التحميل
  static const int _initialLoadCount = 3; // تحميل 3 فيديوهات في البداية
  static const int _paginationSize = 2; // تحميل فيديوهات إضافية
  static const int _preloadDistance = 1; // المسافة للتحميل المسبق

  // Throttling للطلبات
  Timer? _loadMoreTimer;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _initializeScreen() async {
    // محاولة تحميل من الكاش أولاً
    final cachedVideos = _videoCache.getCachedVideos(_cacheKey);

    if (cachedVideos != null && cachedVideos.isNotEmpty) {
      log('📱 تحميل الفيديوهات من الكاش');
      mList = cachedVideos.take(_initialLoadCount).toList();
      isInitialLoading = false;
      hasMoreData = _videoCache.hasMoreVideos(_cacheKey);

      setState(() {});
      await _initVideoControllers();
    } else {
      // تحميل من الشبكة
      await _loadVideosFromNetwork(isInitial: true);
    }
  }

  Future<void> _loadVideosFromNetwork({bool isInitial = false}) async {
    if (_isLoadingMore && !isInitial) return;

    setState(() {
      if (isInitial) {
        isInitialLoading = true;
        isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final loadCount = isInitial ? _initialLoadCount : _paginationSize;
      final startIndex = isInitial ? 0 : mList.length;

      log('🌐 تحميل الفيديوهات من الشبكة - Start: $startIndex, Count: $loadCount');

      final response = await ApiService().getPostList(
        loadCount.toString(),
        SessionManager.userId.toString(),
        UrlRes.related,
      );

      if (response.data != null && response.data!.isNotEmpty) {
        final newVideos = response.data!;

        if (isInitial) {
          mList = newVideos;
          _videoCache.cacheVideos(_cacheKey, newVideos,
              hasMore: newVideos.length >= loadCount);
        } else {
          mList.addAll(newVideos);
          _videoCache.appendVideos(_cacheKey, newVideos,
              hasMore: newVideos.length >= _paginationSize);
        }

        hasMoreData = newVideos.length >=
            (isInitial ? _initialLoadCount : _paginationSize);

        if (isInitial) {
          await _initVideoControllers();
        } else {
          await _preloadNextVideos();
        }
      } else {
        hasMoreData = false;
      }
    } catch (e) {
      log('❌ خطأ في تحميل الفيديوهات: $e');
      if (isInitial && mList.isEmpty) {
        // إظهار خطأ فقط إذا لم يكن لدينا بيانات
        CommonUI.showToast(msg: 'حدث خطأ في تحميل المحتوى');
      }
    } finally {
      setState(() {
        isInitialLoading = false;
        isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _initVideoControllers() async {
    // تهيئة الكونترولر للفيديو الحالي والقادم
    final indicesToInit = <int>[];

    // الفيديو الحالي
    if (focusedIndex < mList.length) {
      indicesToInit.add(focusedIndex);
    }

    // الفيديو القادم
    if (focusedIndex + 1 < mList.length) {
      indicesToInit.add(focusedIndex + 1);
    }

    for (final index in indicesToInit) {
      await _initializeControllerAtIndex(index);
    }

    // تشغيل الفيديو الحالي
    _playControllerAtIndex(focusedIndex);
  }

  Future<void> _initializeControllerAtIndex(int index) async {
    if (index < 0 || index >= mList.length) return;

    final videoUrl = ConstRes.itemBaseUrl + (mList[index].postVideo ?? '');

    try {
      final controller = await _videoCache.getOrCreateController(videoUrl);

      if (!controller.value.isInitialized) {
        await controller.initialize();
        log('🎬 تم تهيئة الفيديو في الفهرس $index');
      }

      if (mounted) setState(() {});
    } catch (e) {
      log('❌ خطأ في تهيئة الفيديو $index: $e');
    }
  }

  void _playControllerAtIndex(int index) {
    if (index < 0 || index >= mList.length) return;

    focusedIndex = index;
    final videoUrl = ConstRes.itemBaseUrl + (mList[index].postVideo ?? '');
    final controller = _videoCache.getController(videoUrl);

    if (controller != null && controller.value.isInitialized) {
      // إيقاف جميع الفيديوهات الأخرى
      _pauseAllControllers();

      // تشغيل الفيديو الحالي
      controller.play();
      controller.setLooping(true);

      // تسجيل المشاهدة
      ApiService().increasePostViewCount(mList[index].postId.toString());

      log('▶️ تشغيل الفيديو في الفهرس $index');

      if (mounted) setState(() {});
    }
  }

  void _pauseAllControllers() {
    for (final video in mList) {
      final url = ConstRes.itemBaseUrl + (video.postVideo ?? '');
      final controller = _videoCache.getController(url);
      if (controller != null && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  Future<void> _preloadNextVideos() async {
    // تحميل مسبق للفيديوهات القادمة
    for (int i = 1; i <= _preloadDistance; i++) {
      final nextIndex = focusedIndex + i;
      if (nextIndex < mList.length) {
        await _initializeControllerAtIndex(nextIndex);
      }
    }
  }

  void _onPageChanged(int index) {
    // تحميل المزيد عند الاقتراب من النهاية
    if (index >= mList.length - 2 && hasMoreData && !_isLoadingMore) {
      _throttledLoadMore();
    }

    // تحديث الفيديو المشغل
    _playControllerAtIndex(index);

    // تحميل مسبق للفيديوهات القادمة
    _preloadNextVideos();

    // تنظيف الكونترولرز البعيدة
    _cleanupDistantControllers(index);
  }

  void _throttledLoadMore() {
    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 500), () {
      if (hasMoreData && !_isLoadingMore) {
        _loadVideosFromNetwork();
      }
    });
  }

  void _cleanupDistantControllers(int currentIndex) {
    // إزالة الكونترولرز البعيدة لتوفير الذاكرة
    const maxDistance = 3;

    for (int i = 0; i < mList.length; i++) {
      if ((i - currentIndex).abs() > maxDistance) {
        final videoUrl = ConstRes.itemBaseUrl + (mList[i].postVideo ?? '');
        _videoCache.removeController(videoUrl);
      }
    }
  }

  Widget _buildVideoItem(int index) {
    if (index >= mList.length) return const SizedBox();

    final data = mList[index];
    final videoUrl = ConstRes.itemBaseUrl + (data.postVideo ?? '');
    final controller = _videoCache.getController(videoUrl);

    return ItemVideo(
      videoData: data,
      videoPlayerController: controller,
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isInitialLoading) {
      return _buildLoadingIndicator();
    }

    if (mList.isEmpty) {
      return DataNotFound();
    }

    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: mList.length + (hasMoreData ? 1 : 0),
          // +1 للـ loading indicator
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            // عرض loading indicator في النهاية
            if (index >= mList.length) {
              return _buildLoadingIndicator();
            }

            return _buildVideoItem(index);
          },
        ),

        // مؤشر التحميل السفلي
        if (_isLoadingMore)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildLoadingIndicator(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _loadMoreTimer?.cancel();
    pageController.dispose();

    // تنظيف دوري للكاش
    _videoCache.cleanupExpiredCache();

    super.dispose();
  }
}
