import 'dart:developer';
import 'dart:async';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/data_not_found.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:bubbly/view/home/widget/item_following.dart';
import 'package:bubbly/view/video/item_video.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../code/video_cache.dart';

// إضافة VideoCache

class OptimizedFollowingScreen extends StatefulWidget {
  @override
  _OptimizedFollowingScreenState createState() =>
      _OptimizedFollowingScreenState();
}

class _OptimizedFollowingScreenState extends State<OptimizedFollowingScreen>
    with AutomaticKeepAliveClientMixin {
  List<Data> mList = [];
  PageController pageController = PageController();

  bool isFollowingDataEmpty = false;
  bool isInitialLoading = true;
  bool hasMoreData = true;
  bool _isLoadingMore = false;

  int focusedIndex = 0;

  // نظام الكاشينج
  final VideoCache _videoCache = VideoCache();
  final String _followingCacheKey = 'following_videos';
  final String _forYouCacheKey = 'following_for_you_videos';

  // تحسين التحميل
  static const int _initialLoadCount = 3;
  static const int _paginationSize = 2;
  static const int _preloadDistance = 1;

  // Throttling للطلبات
  Timer? _loadMoreTimer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _initializeScreen() async {
    // محاولة تحميل من الكاش أولاً
    final cachedVideos = _videoCache.getCachedVideos(_followingCacheKey);

    if (cachedVideos != null && cachedVideos.isNotEmpty) {
      log('📱 تحميل فيديوهات المتابعين من الكاش');
      mList = cachedVideos.take(_initialLoadCount).toList();
      isInitialLoading = false;
      hasMoreData = _videoCache.hasMoreVideos(_followingCacheKey);

      setState(() {});
      await _initVideoControllers();
    } else {
      // تحميل من الشبكة
      await _loadFollowingVideos(isInitial: true);
    }
  }

  Future<void> _loadFollowingVideos({bool isInitial = false}) async {
    if (_isLoadingMore && !isInitial) return;

    setState(() {
      if (isInitial) {
        isInitialLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final loadCount = isInitial ? _initialLoadCount : _paginationSize;

      log('🌐 تحميل فيديوهات المتابعين من الشبكة - Count: $loadCount');

      final response = await ApiService().getPostList(
        loadCount.toString(),
        SessionManager.userId.toString(),
        UrlRes.following,
      );

      if (response.data != null && response.data!.isNotEmpty) {
        final newVideos = response.data!;

        if (isInitial) {
          mList = newVideos;
          _videoCache.cacheVideos(_followingCacheKey, newVideos,
              hasMore: newVideos.length >= loadCount);
        } else {
          mList.addAll(newVideos);
          _videoCache.appendVideos(_followingCacheKey, newVideos,
              hasMore: newVideos.length >= _paginationSize);
        }

        hasMoreData = newVideos.length >=
            (isInitial ? _initialLoadCount : _paginationSize);
        isFollowingDataEmpty = false;

        if (isInitial) {
          await _initVideoControllers();
        } else {
          await _preloadNextVideos();
        }
      } else {
        // لا توجد فيديوهات متابعين، جرب For You
        if (isInitial) {
          await _loadForYouVideos();
        } else {
          hasMoreData = false;
        }
      }
    } catch (e) {
      log('❌ خطأ في تحميل فيديوهات المتابعين: $e');
      if (isInitial && mList.isEmpty) {
        await _loadForYouVideos();
      }
    } finally {
      setState(() {
        isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadForYouVideos() async {
    log('🌐 تحميل فيديوهات For You كبديل');

    try {
      // محاولة تحميل من كاش For You
      final cachedForYou = _videoCache.getCachedVideos(_forYouCacheKey);

      if (cachedForYou != null && cachedForYou.isNotEmpty) {
        mList = cachedForYou.take(_initialLoadCount).toList();
        isFollowingDataEmpty = true;
      } else {
        // تحميل من الشبكة
        final response = await ApiService().getPostList(
          _initialLoadCount.toString(),
          "2",
          UrlRes.trending,
        );

        if (response.data != null && response.data!.isNotEmpty) {
          mList = response.data!;
          _videoCache.cacheVideos(_forYouCacheKey, mList, hasMore: true);
          isFollowingDataEmpty = true;
        }
      }

      await _initVideoControllers();
    } catch (e) {
      log('❌ خطأ في تحميل فيديوهات For You: $e');
    }
  }

  Future<void> _initVideoControllers() async {
    // تهيئة الكونترولر للفيديو الحالي والقادم
    final indicesToInit = <int>[];

    if (focusedIndex < mList.length) {
      indicesToInit.add(focusedIndex);
    }

    if (focusedIndex + 1 < mList.length) {
      indicesToInit.add(focusedIndex + 1);
    }

    for (final index in indicesToInit) {
      await _initializeControllerAtIndex(index);
    }

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
      _pauseAllControllers();

      controller.play();
      controller.setLooping(true);

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
    for (int i = 1; i <= _preloadDistance; i++) {
      final nextIndex = focusedIndex + i;
      if (nextIndex < mList.length) {
        await _initializeControllerAtIndex(nextIndex);
      }
    }
  }

  void _onPageChanged(int index) {
    // تحميل المزيد عند الاقتراب من النهاية
    if (index >= mList.length - 2 &&
        hasMoreData &&
        !_isLoadingMore &&
        !isFollowingDataEmpty) {
      _throttledLoadMore();
    }

    _playControllerAtIndex(index);
    _preloadNextVideos();
    _cleanupDistantControllers(index);
  }

  void _throttledLoadMore() {
    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 500), () {
      if (hasMoreData && !_isLoadingMore) {
        _loadFollowingVideos();
      }
    });
  }

  void _cleanupDistantControllers(int currentIndex) {
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

  Widget _buildFollowingItem(int index) {
    if (index >= mList.length) return const SizedBox();

    final data = mList[index];
    final videoUrl = ConstRes.itemBaseUrl + (data.postVideo ?? '');
    final controller = _videoCache.getController(videoUrl);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ItemFollowing(data, controller),
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

  Widget _buildEmptyFollowingState() {
    return Consumer<MyLoading>(
      builder: (context, myLoading, child) => Column(
        children: [
          SizedBox(height: AppBar().preferredSize.height * 2),
          Image(
            width: 60,
            image: AssetImage(myLoading.isDark ? icLogo : icLogoLight),
          ),
          const SizedBox(height: 10),
          Text(
            LKey.popularCreator.tr,
            style: const TextStyle(
                fontSize: 18, fontFamily: FontRes.fNSfUiSemiBold),
          ),
          const SizedBox(height: 5),
          Text(
            LKey.followSomeCreatorsTonWatchTheirVideos.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: ColorRes.colorTextLight,
              fontFamily: FontRes.fNSfUiRegular,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: MediaQuery.of(context).size.height / 2,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.7),
              itemCount: mList.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _buildFollowingItem(index),
            ),
          ),
          const Spacer(),
        ],
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

    return Consumer<MyLoading>(
      builder: (context, myLoading, child) {
        if (isFollowingDataEmpty) {
          return _buildEmptyFollowingState();
        }

        return Stack(
          children: [
            PageView.builder(
              itemCount: mList.length + (hasMoreData ? 1 : 0),
              controller: pageController,
              pageSnapping: true,
              onPageChanged: _onPageChanged,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
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
      },
    );
  }

  @override
  void dispose() {
    _loadMoreTimer?.cancel();
    pageController.dispose();
    _videoCache.cleanupExpiredCache();
    super.dispose();
  }
}
