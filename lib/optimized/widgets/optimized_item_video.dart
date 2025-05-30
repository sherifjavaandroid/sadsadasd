import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:bubbly/custom_view/image_place_holder.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/key_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/view/comment/comment_screen.dart';
import 'package:bubbly/view/hashtag/videos_by_hashtag.dart';
import 'package:bubbly/view/login/login_sheet.dart';
import 'package:bubbly/view/profile/profile_screen.dart';
import 'package:bubbly/view/report/report_screen.dart';
import 'package:bubbly/view/send_bubble/dialog_send_bubble.dart';
import 'package:bubbly/view/video/widget/like_unlike_button.dart';
import 'package:bubbly/view/video/widget/music_disk.dart';
import 'package:bubbly/view/video/widget/share_sheet.dart';
import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

// ignore: must_be_immutable
class OptimizedItemVideo extends StatefulWidget {
  final Data? videoData;
  final VideoPlayerController? videoPlayerController;
  ItemVideoState? item;

  OptimizedItemVideo({
    Key? key,
    this.videoData,
    this.videoPlayerController,
  }) : super(key: key);

  @override
  ItemVideoState createState() => ItemVideoState();
}

class ItemVideoState extends State<OptimizedItemVideo>
    with AutomaticKeepAliveClientMixin {
  bool isLogin = false;
  SessionManager sessionManager = SessionManager();

  // تحسين الأداء
  bool _isVisible = false;
  bool _isInitialized = false;

  // تخزين القيم المحسوبة مؤقتاً
  late String _videoKey;
  late String _userProfileUrl;
  late String _userName;
  late String _postDescription;
  late String _soundTitle;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeVideoItem();
    _prefData();
  }

  void _initializeVideoItem() {
    // حساب القيم مرة واحدة فقط
    _videoKey =
        'video_${widget.videoData?.postId ?? DateTime.now().millisecondsSinceEpoch}';
    _userProfileUrl =
        ConstRes.itemBaseUrl + (widget.videoData?.userProfile ?? '');
    _userName = widget.videoData?.userName ?? '';
    _postDescription = widget.videoData?.postDescription ?? '';
    _soundTitle = widget.videoData?.soundTitle ?? '';

    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    // إيقاف الفيديو عند إزالة العنصر
    if (_isVisible && widget.videoPlayerController != null) {
      await widget.videoPlayerController?.pause();
    }
  }

  Widget _buildVideoPlayer() {
    if (widget.videoPlayerController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorRes.white),
          ),
        ),
      );
    }

    final controller = widget.videoPlayerController!;

    if (!controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorRes.white),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: (controller.value.size.width) < (controller.value.size.height)
            ? BoxFit.cover
            : BoxFit.fitWidth,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 100,
        width: double.infinity,
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.2, 0.6, 1],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    if (widget.videoData == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // فئة الملف الشخصي
          if (widget.videoData!.profileCategoryName?.isNotEmpty == true)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Text(
                widget.videoData?.profileCategoryName ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: FontRes.fNSfUiSemiBold,
                  color: Colors.black,
                ),
              ),
            ),

          // اسم المستخدم
          InkWell(
            onTap: _navigateToProfile,
            child: Container(
              margin: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Text(
                    '${AppRes.atSign}$_userName',
                    style: const TextStyle(
                      fontFamily: FontRes.fNSfUiSemiBold,
                      letterSpacing: 0.6,
                      fontSize: 16,
                      color: ColorRes.white,
                    ),
                  ),
                  const SizedBox(width: 5),
                  if (widget.videoData?.isVerify == 1)
                    const Image(
                      image: AssetImage(icVerify),
                      height: 18,
                      width: 18,
                    ),
                ],
              ),
            ),
          ),

          // وصف المنشور
          if (_postDescription.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              child: DetectableText(
                text: _postDescription,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                detectedStyle: const TextStyle(
                  fontFamily: FontRes.fNSfUiBold,
                  letterSpacing: 0.6,
                  fontSize: 13,
                  color: ColorRes.white,
                ),
                basicStyle: TextStyle(
                  fontFamily: FontRes.fNSfUiRegular,
                  letterSpacing: 0.6,
                  fontSize: 13,
                  color: ColorRes.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 5,
                    ),
                  ],
                ),
                onTap: _navigateToHashtag,
                detectionRegExp: detectionRegExp(hashtag: true)!,
              ),
            ),

          // عنوان الصوت
          Text(
            _soundTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FontRes.fNSfUiMedium,
              letterSpacing: 0.7,
              fontSize: 13,
              color: ColorRes.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.videoData == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // صورة المستخدم
          _buildUserAvatar(),
          const SizedBox(height: 15),

          // زر الهدية
          if (SessionManager.userId != widget.videoData!.userId)
            _buildGiftButton(),

          if (SessionManager.userId != widget.videoData?.userId)
            const SizedBox(height: 15),

          // زر الإعجاب
          _buildLikeButton(),
          _buildLikeCount(),
          const SizedBox(height: 15),

          // زر التعليقات
          _buildCommentButton(),
          _buildCommentCount(),
          const SizedBox(height: 15),

          // زر المشاركة
          _buildShareButton(),
          const SizedBox(height: 15),

          // قرص الموسيقى
          MusicDisk(widget.videoData),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return BouncingWidget(
      duration: const Duration(milliseconds: 100),
      scaleFactor: 1,
      onPressed: _navigateToProfile,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          border: Border.all(color: ColorRes.white),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            _userProfileUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return ImagePlaceHolder(
                heightWeight: 40,
                name: widget.videoData?.fullName,
                fontSize: 20,
              );
            },
            // تحسين تحميل الصور
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 40,
                width: 40,
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGiftButton() {
    return InkWell(
      onTap: _handleGiftTap,
      child: Image.asset(
        icGift,
        height: 35,
        width: 35,
      ),
    );
  }

  Widget _buildLikeButton() {
    return LikeUnLikeButton(
      videoData: widget.videoData,
      likeUnlike: _handleLikeUnlike,
    );
  }

  Widget _buildLikeCount() {
    return Text(
      NumberFormat.compact(locale: 'en')
          .format(widget.videoData?.postLikesCount ?? 0),
      style: const TextStyle(
        color: ColorRes.white,
        fontFamily: FontRes.fNSfUiSemiBold,
      ),
    );
  }

  Widget _buildCommentButton() {
    return InkWell(
      onTap: _showComments,
      child: Image.asset(
        icComment,
        height: 35,
        width: 35,
        color: ColorRes.white,
      ),
    );
  }

  Widget _buildCommentCount() {
    return Text(
      NumberFormat.compact(locale: 'en')
          .format(widget.videoData?.postCommentsCount ?? 0),
      style: const TextStyle(color: ColorRes.white),
    );
  }

  Widget _buildShareButton() {
    return InkWell(
      onTap: _shareLink,
      child: Image.asset(
        icShare,
        height: 32,
        width: 32,
        color: ColorRes.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized || widget.videoData == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorRes.white),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // تحسين VisibilityDetector
        InkWell(
          onLongPress: _onLongPress,
          onTap: _onTap,
          child: VisibilityDetector(
            onVisibilityChanged: _onVisibilityChanged,
            key: Key(_videoKey),
            child: _buildVideoPlayer(),
          ),
        ),

        // التدرج السفلي
        InkWell(
          onLongPress: _onLongPress,
          onTap: _onTap,
          child: _buildGradientOverlay(),
        ),

        // المحتوى السفلي
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildUserInfo()),
                _buildActionButtons(),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ],
    );
  }

  // معالجات الأحداث
  void _onVisibilityChanged(VisibilityInfo info) {
    final visiblePercentage = info.visibleFraction * 100;
    final shouldPlay = visiblePercentage > 50;

    if (_isVisible != shouldPlay) {
      _isVisible = shouldPlay;

      if (shouldPlay) {
        widget.videoPlayerController?.play();
      } else {
        widget.videoPlayerController?.pause();
      }
    }
  }

  void _onTap() {
    if (widget.videoPlayerController != null) {
      if (widget.videoPlayerController!.value.isPlaying) {
        widget.videoPlayerController?.pause();
      } else {
        widget.videoPlayerController?.play();
      }
    }
  }

  void _onLongPress() {
    if (widget.videoData != null) {
      showModalBottomSheet(
        context: context,
        builder: (context) =>
            ReportScreen(1, widget.videoData!.postId.toString()),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  void _navigateToProfile() {
    if (widget.videoData?.userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            type: 1,
            userId: widget.videoData!.userId.toString(),
          ),
        ),
      );
    }
  }

  void _navigateToHashtag(String text) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideosByHashTagScreen(text),
      ),
    );
  }

  void _handleGiftTap() {
    if (SessionManager.userId != -1 && isLogin) {
      showDialog(
        context: context,
        builder: (context) => DialogSendBubble(widget.videoData),
      );
    } else {
      _showLoginSheet();
    }
  }

  void _handleLikeUnlike() {
    if (widget.videoData != null) {
      if (widget.videoData!.videoLikesOrNot == 1) {
        widget.videoData!.setVideoLikesOrNot(0);
      } else {
        widget.videoData!.setVideoLikesOrNot(1);
      }
      setState(() {});
    }
  }

  void _showComments() {
    Get.bottomSheet(
      CommentScreen(widget.videoData, () {
        setState(() {});
      }),
      isScrollControlled: true,
    );
  }

  void _shareLink() {
    if (widget.videoData != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            SocialLinkShareSheet(videoData: widget.videoData!),
      );
    }
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

  Future<void> _prefData() async {
    await sessionManager.initPref();
    isLogin = sessionManager.getBool(KeyRes.login) ?? false;
    if (mounted) setState(() {});
  }
}
