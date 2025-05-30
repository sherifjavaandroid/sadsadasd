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
import 'package:tiktok_double_tap_like/tiktok_double_tap_like.dart';

// Import your API service
import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/modal/rest/rest_response.dart';

// ignore: must_be_immutable
class ItemVideo extends StatefulWidget {
  final Data? videoData;
  ItemVideoState? item;
  final VideoPlayerController? videoPlayerController;

  ItemVideo({this.videoData, this.videoPlayerController});

  @override
  ItemVideoState createState() => ItemVideoState();
}

class ItemVideoState extends State<ItemVideo> with TickerProviderStateMixin {
  bool isLogin = false;
  SessionManager sessionManager = SessionManager();
  ApiService apiService = ApiService();

  // Follow button state
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  bool _isLiking = false;

  @override
  void initState() {
    prefData();

    // Check if user is already following this creator
    _checkFollowStatus();

    super.initState();
  }

  @override
  void didUpdateWidget(ItemVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh follow status when widget data changes
    if (oldWidget.videoData?.userId != widget.videoData?.userId ||
        oldWidget.videoData?.followOrNot != widget.videoData?.followOrNot) {
      _checkFollowStatus();
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await widget.videoPlayerController?.pause();
  }

  void _checkFollowStatus() {
    // Use the followOrNot field from your data model
    if (widget.videoData?.followOrNot != null) {
      setState(() {
        _isFollowing = widget.videoData?.followOrNot == 1;
      });
    }
  }

  Future<void> _handleDoubleTapLike(int likeCount) async {
    if (!isLogin || SessionManager.userId == -1) {
      _showLoginSheet();
      return;
    }

    // Only like if not already liked (prevent double-like)
    if (widget.videoData?.videoLikesOrNot != 1 && !_isLiking) {
      setState(() {
        _isLiking = true;
      });

      try {
        // Update UI immediately for responsiveness
        widget.videoData?.setVideoLikesOrNot(1);
        setState(() {});

        // Call actual API to like the video
        await _likeVideo();

        // Show success feedback
        _showLikeSuccess();
      } catch (e) {
        // Revert the like if API call fails
        widget.videoData?.setVideoLikesOrNot(0);
        setState(() {});

        _showErrorMessage('Failed to like video: ${e.toString()}');
      } finally {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  Future<void> _likeVideo() async {
    try {
      final response = await apiService
          .likeUnlikePost(widget.videoData?.postId.toString() ?? '');

      if (response.status != 200) {
        throw Exception(response.message ?? 'Failed to like video');
      }

      print('✅ Video liked successfully: ${response.message}');
    } catch (e) {
      print('❌ Error liking video: $e');
      throw e;
    }
  }

  Future<void> _unlikeVideo() async {
    try {
      final response = await apiService
          .likeUnlikePost(widget.videoData?.postId.toString() ?? '');

      if (response.status != 200) {
        throw Exception(response.message ?? 'Failed to unlike video');
      }

      print('✅ Video unliked successfully: ${response.message}');
    } catch (e) {
      print('❌ Error unliking video: $e');
      throw e;
    }
  }

  void _showLikeSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.favorite, color: Colors.red),
            SizedBox(width: 8),
            Text('Video liked!'),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLikeButtonPress() async {
    if (!isLogin || SessionManager.userId == -1) {
      _showLoginSheet();
      return;
    }

    if (_isLiking) return; // Prevent multiple clicks

    setState(() {
      _isLiking = true;
    });

    try {
      bool wasLiked = widget.videoData?.videoLikesOrNot == 1;

      if (wasLiked) {
        // Unlike the video
        widget.videoData?.setVideoLikesOrNot(0);
        setState(() {});
        await _unlikeVideo();
        _showSuccessMessage('Video unliked');
      } else {
        // Like the video
        widget.videoData?.setVideoLikesOrNot(1);
        setState(() {});
        await _likeVideo();
        _showLikeSuccess();
      }
    } catch (e) {
      // Revert the change if API call fails
      if (widget.videoData?.videoLikesOrNot == 1) {
        widget.videoData?.setVideoLikesOrNot(0);
      } else {
        widget.videoData?.setVideoLikesOrNot(1);
      }
      setState(() {});
      _showErrorMessage('Failed to update like: ${e.toString()}');
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  Future<void> _handleFollow() async {
    if (!isLogin || SessionManager.userId == -1) {
      _showLoginSheet();
      return;
    }

    if (SessionManager.userId == widget.videoData?.userId) {
      return; // Can't follow yourself
    }

    if (_isFollowLoading) return; // Prevent multiple clicks

    setState(() {
      _isFollowLoading = true;
    });

    try {
      bool wasFollowing = _isFollowing;

      // Update UI immediately for responsiveness
      setState(() {
        _isFollowing = !wasFollowing;
      });

      // Update the data model to persist the state when scrolling
      widget.videoData?.setFollowStatus(_isFollowing ? 1 : 0);

      // Call actual API
      final response = await apiService
          .followUnFollowUser(widget.videoData?.userId.toString() ?? '');

      if (response.status != 200) {
        // Revert if API call failed
        setState(() {
          _isFollowing = wasFollowing;
        });
        widget.videoData?.setFollowStatus(wasFollowing ? 1 : 0);
        throw Exception(response.message ?? 'Failed to update follow status');
      }

      // Show success message
      String message = _isFollowing
          ? 'Following ${widget.videoData?.userName}'
          : 'Unfollowed ${widget.videoData?.userName}';
      _showSuccessMessage(message);

      print('✅ Follow status updated successfully: $message');
    } catch (e) {
      print('❌ Error updating follow status: $e');
      _showErrorMessage('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isFollowLoading = false;
      });
    }
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return LoginSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video player with TikTok double-tap like
        DoubleTapLikeWidget(
          onLike: _handleDoubleTapLike,
          likeWidget: Icon(
            Icons.favorite,
            color: Colors.red,
            size: 100,
          ),
          likeWidth: 100,
          likeHeight: 100,
          child: GestureDetector(
            onTap: _onTap,
            onLongPress: _onLongPress,
            child: VisibilityDetector(
              onVisibilityChanged: (VisibilityInfo info) {
                var visiblePercentage = info.visibleFraction * 100;
                if (visiblePercentage > 50) {
                  widget.videoPlayerController?.play();
                } else {
                  widget.videoPlayerController?.pause();
                }
              },
              key: Key('ke1' +
                  (ConstRes.itemBaseUrl + widget.videoData!.postVideo!)),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: (widget.videoPlayerController?.value.size.width ?? 0) <
                          (widget.videoPlayerController?.value.size.height ?? 0)
                      ? BoxFit.cover
                      : BoxFit.fitWidth,
                  child: SizedBox(
                    width: widget.videoPlayerController?.value.size.width ?? 0,
                    height:
                        widget.videoPlayerController?.value.size.height ?? 0,
                    child: widget.videoPlayerController != null
                        ? VideoPlayer(widget.videoPlayerController!)
                        : SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom gradient overlay
        GestureDetector(
          onTap: _onTap,
          onLongPress: _onLongPress,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 100,
              width: double.infinity,
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.2, 0.6, 1],
                ),
              ),
            ),
          ),
        ),

        // UI Content
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: widget.videoData!.profileCategoryName!.isNotEmpty,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300, borderRadius: BorderRadius.all(Radius.circular(3))),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            child: Text(
                              widget.videoData?.profileCategoryName ?? '',
                              style: TextStyle(fontSize: 11, fontFamily: FontRes.fNSfUiSemiBold, color: Colors.black),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(type: 1, userId: widget.videoData?.userId.toString() ?? '-1'),
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                Text(
                                  '${AppRes.atSign}${widget.videoData?.userName}',
                                  style: TextStyle(
                                    fontFamily: FontRes.fNSfUiSemiBold,
                                    letterSpacing: 0.6,
                                    fontSize: 16,
                                    color: ColorRes.white,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Image(
                                  image: AssetImage(icVerify),
                                  height: widget.videoData!.isVerify == 1 ? 18 : 0,
                                  width: widget.videoData!.isVerify == 1 ? 18 : 0,
                                )
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: widget.videoData!.postDescription!.isNotEmpty,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 5),
                            child: DetectableText(
                              text: widget.videoData?.postDescription ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              detectedStyle: TextStyle(
                                  fontFamily: FontRes.fNSfUiBold,
                                  letterSpacing: 0.6,
                                  fontSize: 13,
                                  color: ColorRes.white),
                              basicStyle: TextStyle(
                                fontFamily: FontRes.fNSfUiRegular,
                                letterSpacing: 0.6,
                                fontSize: 13,
                                color: ColorRes.white,
                                shadows: [
                                  Shadow(
                                      offset: Offset(1, 1),
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 5),
                                ],
                              ),
                              onTap: (text) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideosByHashTagScreen(text),
                                  ),
                                );
                              },
                              detectionRegExp: detectionRegExp(hashtag: true)!,
                            ),
                          ),
                        ),
                        Text(
                          widget.videoData?.soundTitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontRes.fNSfUiMedium,
                            letterSpacing: 0.7,
                            fontSize: 13,
                            color: ColorRes.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      // Profile picture with follow button
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          BouncingWidget(
                            duration: Duration(milliseconds: 100),
                            scaleFactor: 1,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return ProfileScreen(
                                        type: 1,
                                        userId: widget.videoData?.userId
                                                .toString() ??
                                            '-1');
                                  },
                                ),
                              );
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                  border: Border.all(color: ColorRes.white),
                                  shape: BoxShape.circle),
                              child: ClipOval(
                                child: Image.network(
                                  ConstRes.itemBaseUrl +
                                      widget.videoData!.userProfile!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ImagePlaceHolder(
                                      heightWeight: 40,
                                      name: widget.videoData?.fullName,
                                      fontSize: 20,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Follow button (like TikTok)
                          if (SessionManager.userId != widget.videoData?.userId)
                            Positioned(
                              bottom: -6,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: GestureDetector(
                                  onTap: _handleFollow,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _isFollowing
                                          ? Colors.grey
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: _isFollowLoading
                                        ? SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Icon(
                                            _isFollowing
                                                ? Icons.check
                                                : Icons.add,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Visibility(
                        visible: SessionManager.userId != widget.videoData!.userId,
                        child: InkWell(
                          onTap: () {
                            if (SessionManager.userId != -1 || isLogin) {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return DialogSendBubble(widget.videoData);
                                  });
                            } else {
                              _showLoginSheet();
                            }
                          },
                          child: Image.asset(
                            icGift,
                            height: 35,
                            width: 35,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: SessionManager.userId != widget.videoData?.userId ? 15 : 0,
                      ),

                      // Enhanced Like Button with Loading State
                      GestureDetector(
                        onTap: _handleLikeButtonPress,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: _isLiking
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Icon(
                                  Icons.favorite,
                                  color: widget.videoData?.videoLikesOrNot == 1
                                      ? Colors.red
                                      : Colors.white,
                                  size: 35,
                                ),
                        ),
                      ),
                      Text(
                        NumberFormat.compact(locale: 'en').format(widget.videoData?.postLikesCount ?? 0),
                        style: TextStyle(color: ColorRes.white, fontFamily: FontRes.fNSfUiSemiBold),
                      ),
                      SizedBox(height: 15),
                      InkWell(
                        onTap: () {
                          Get.bottomSheet(
                            CommentScreen(widget.videoData, () {
                              setState(() {});
                            }),
                            isScrollControlled: true,
                          );
                        },
                        child: Image.asset(icComment, height: 35, width: 35, color: ColorRes.white),
                      ),
                      Text(NumberFormat.compact(locale: 'en').format(widget.videoData?.postCommentsCount ?? 0),
                          style: TextStyle(color: ColorRes.white)),
                      SizedBox(height: 15),
                      InkWell(
                        onTap: () {
                          shareLink(widget.videoData!);
                        },
                        child: Image.asset(icShare, height: 32, width: 32, color: ColorRes.white),
                      ),
                      SizedBox(height: 15),
                      MusicDisk(widget.videoData),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
          ],
        ),
      ],
    );
  }

  void shareLink(Data videoData) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SocialLinkShareSheet(videoData: videoData);
      },
    );
  }

  void _onTap() {
    if (widget.videoPlayerController != null && widget.videoPlayerController!.value.isPlaying) {
      widget.videoPlayerController?.pause();
    } else {
      widget.videoPlayerController?.play();
    }
  }

  void _onLongPress() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return ReportScreen(1, widget.videoData!.postId.toString());
        },
        isScrollControlled: true,
        backgroundColor: Colors.transparent);
  }

  void prefData() async {
    await sessionManager.initPref();
    isLogin = sessionManager.getBool(KeyRes.login) ?? false;
    setState(() {});
  }
}