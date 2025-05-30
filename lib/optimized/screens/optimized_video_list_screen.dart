import 'dart:developer';
import 'dart:async';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/view/login/login_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../view/video/item_video.dart';
import '../code/video_cache.dart';

class OptimizedVideoListScreen extends StatefulWidget {
  final List<Data> list;
  final int index;
  final int? type;
  final String? userId;
  final String? soundId;
  final String? hashTag;
  final String? keyWord;

  OptimizedVideoListScreen({
    required this.list,
    required this.index,
    required this.type,
    this.userId,
    this.soundId,
    this.hashTag,
    this.keyWord,
  });

  @override
  _OptimizedVideoListScreenState createState() =>
      _OptimizedVideoListScreenState();
}

class _OptimizedVideoListScreenState extends State<OptimizedVideoListScreen> {
  List<Data> mList = [];
  PageController _pageController = PageController();

  int position = 0;
  int focusedIndex = 0;

  TextEditingController _commentController = TextEditingController();
  SessionManager sessionManager = SessionManager();
  FocusNode commentFocusNode = FocusNode();
  bool isLogin = false;

  bool hasMoreData = true;
  bool _isLoadingMore = false;

  // نظام الكاشينج
  final VideoCache _videoCache = VideoCache();
  late String _cacheKey;

  // تحسين التحميل
  static const int _paginationSize = 3; // تحميل 3 فيديوهات إضافية
  static const int _preloadDistance = 1;

  // Throttling للطلبات
  Timer? _loadMoreTimer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    // إنشاء مفتاح الكاش بناءً على نوع الطلب
    _cacheKey = _generateCacheKey();

    mList = List.from(widget.list);
    _pageController = PageController(initialPage: widget.index);
    position = widget.index;
    focusedIndex = widget.index;

    _prefData();
    _initVideoControllers();
  }

  String _generateCacheKey() {
    final type = widget.type ?? 0;
    switch (type) {
      case 1:
        return 'user_videos_${widget.userId}';
      case 2:
        return 'user_likes_${widget.userId}';
      case 3:
        return 'sound_videos_${widget.soundId}';
      case 4:
        return 'hashtag_videos_${widget.hashTag}';
      case 5:
        return 'search_videos_${widget.keyWord}';
      default:
        return 'video_list_${DateTime.now().millisecondsSinceEpoch}';
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

    // تهيئة الفيديو السابق إذا كان موجوداً
    if (focusedIndex - 1 >= 0) {
      indicesToInit.add(focusedIndex - 1);
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
    position = index;
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
    if (index >= mList.length - 2 && hasMoreData && !_isLoadingMore) {
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
        _loadMoreVideos();
      }
    });
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      log('🌐 تحميل المزيد من الفيديوهات - نوع: ${widget.type}');

      final response = await ApiService().getPostsByType(
        pageDataType: widget.type,
        userId: widget.userId,
        soundId: widget.soundId,
        hashTag: widget.hashTag,
        keyWord: widget.keyWord,
        start: mList.length.toString(),
        limit: _paginationSize.toString(),
      );

      if (response.data != null && response.data!.isNotEmpty) {
        final newVideos = response.data!;
        mList.addAll(newVideos);

        // تحديث الكاش
        _videoCache.appendVideos(_cacheKey, newVideos,
            hasMore: newVideos.length >= _paginationSize);

        hasMoreData = newVideos.length >= _paginationSize;

        // تحميل مسبق للفيديوهات الجديدة
        await _preloadNextVideos();
      } else {
        hasMoreData = false;
      }
    } catch (e) {
      log('❌ خطأ في تحميل المزيد من الفيديوهات: $e');
      CommonUI.showToast(msg: 'حدث خطأ في تحميل المحتوى');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _cleanupDistantControllers(int currentIndex) {
    const maxDistance = 4; // زيادة المسافة قليلاً للفيديو ليست

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

  Widget _buildCommentInput() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: commentFocusNode,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: LKey.leaveYourComment.tr,
                  hintStyle: const TextStyle(fontFamily: FontRes.fNSfUiRegular),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                cursorColor: ColorRes.colorTextLight,
              ),
            ),
            ClipOval(
              child: InkWell(
                onTap: _handleCommentSubmit,
                child: Container(
                  height: 35,
                  width: 35,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ColorRes.colorTheme, ColorRes.colorPink],
                    ),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: ColorRes.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCommentSubmit() {
    if (_commentController.text.trim().isEmpty) {
      CommonUI.showToast(msg: LKey.enterCommentFirst.tr);
      return;
    }

    if (SessionManager.userId == -1 || !isLogin) {
      _showLoginSheet();
      return;
    }

    _submitComment();
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) => LoginSheet(),
    );
  }

  void _submitComment() {
    final commentText = _commentController.text.trim();
    final postId = mList[position].postId.toString();

    ApiService().addComment(commentText, postId).then((value) {
      _commentController.clear();
      commentFocusNode.unfocus();
      mList[position].setPostCommentCount(true);
      setState(() {});
    }).catchError((error) {
      log('❌ خطأ في إضافة التعليق: $error');
      CommonUI.showToast(msg: 'حدث خطأ في إضافة التعليق');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  pageSnapping: true,
                  onPageChanged: _onPageChanged,
                  scrollDirection: Axis.vertical,
                  itemCount: mList.length + (hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= mList.length) {
                      return _buildLoadingIndicator();
                    }
                    return _buildVideoItem(index);
                  },
                ),
              ),
              _buildCommentInput(),
            ],
          ),

          // زر الرجوع
          SafeArea(
            bottom: false,
            child: IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              color: ColorRes.white,
              iconSize: 35,
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // مؤشر التحميل السفلي
          if (_isLoadingMore)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: _buildLoadingIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _prefData() async {
    await sessionManager.initPref();
    isLogin = sessionManager.getBool(KeyRes.login) ?? false;
    setState(() {});
  }

  @override
  void dispose() {
    _loadMoreTimer?.cancel();
    _pageController.dispose();
    _commentController.dispose();
    commentFocusNode.dispose();

    // تنظيف الكاش
    _videoCache.cleanupExpiredCache();

    super.dispose();
  }
}
