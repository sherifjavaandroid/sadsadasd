import 'dart:io';

import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:bubbly_camera/bubbly_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinkShareSheet extends StatefulWidget {
  final Data videoData;

  const SocialLinkShareSheet({Key? key, required this.videoData});

  @override
  State<SocialLinkShareSheet> createState() => _SocialLinkShareSheetState();
}

class _SocialLinkShareSheetState extends State<SocialLinkShareSheet> {
  List<String> shareIconList = [
    icDownloads,
    icWhatsapp,
    icInstagram,
    icCopy,
    icMore
  ];
  bool androidExistNotSave = false;
  RetrytechPlugin _retrytechPlugin = RetrytechPlugin();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, MyLoading myLoading, child) {
        return Wrap(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Screenshot(
                  controller: screenshotController,
                  child: Column(
                    children: [
                      Image.asset(
                        myLoading.isDark ? icLogo : icLogoLight,
                        width: 30,
                        fit: BoxFit.fitHeight,
                      ),
                      Text(
                        '@${widget.videoData.userName ?? appName}',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: AppBar().preferredSize.height),
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                      color: myLoading.isDark
                          ? ColorRes.colorPrimary
                          : ColorRes.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            LKey.shareThisVideo.tr,
                            style: TextStyle(
                                fontFamily: FontRes.fNSfUiMedium, fontSize: 16),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(Icons.close)),
                          )
                        ],
                      ),
                      Divider(color: ColorRes.colorTextLight),
                      Wrap(
                        children: List.generate(shareIconList.length, (index) {
                          return InkWell(
                            onTap: () => _onTap(index),
                            child: Container(
                              height: 40,
                              width: 40,
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.all(8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    ColorRes.colorTheme,
                                    ColorRes.colorIcon
                                  ],
                                ),
                              ),
                              child: Image.asset(
                                shareIconList[index],
                                color: ColorRes.white,
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: AppBar().preferredSize.height)
                    ],
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<void> _onTap(int index) async {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);

    Uint8List? imageFile = await screenshotController.capture();
    if (imageFile != null) {
      print('Screenshot captured: $imageFile');
    }

    final sharedLink = await _shareBranchLink();
    Get.dialog(LoaderDialog());

    switch (index) {
      case 0:
        addWatermarkToVideo(imageFile);
        break;
      case 1:
        _share('whatsapp', sharedLink);
        break;
      case 2:
        if (Platform.isIOS) {
          _share('instagram', sharedLink);
        } else {
          BubblyCamera.shareToInstagram(sharedLink);
        }
        break;
      case 3:
        Clipboard.setData(ClipboardData(text: sharedLink));
        break;
      case 4:
        Share.share(
          AppRes.checkOutThisAmazingProfile(sharedLink),
          subject: '${AppRes.look} ${widget.videoData.userName}',
        );
        break;
    }

    Get.back();
  }

  void _share(String platform, String sharedLink) async {
    final uri = Uri.parse(platform == 'whatsapp'
        ? 'whatsapp://send?text=$sharedLink'
        : 'instagram://sharesheet?text=$sharedLink');

    if (!await launchUrl(uri)) {
      // Handle failure to launch URL
    }
  }

  Future<String> _shareBranchLink() async {
    // Creating BranchUniversalObject
    BranchUniversalObject buo = BranchUniversalObject(
      canonicalIdentifier: 'flutter/branch',
      title: widget.videoData.userName ?? '',
      imageUrl: ConstRes.itemBaseUrl + widget.videoData.postImage!,
      contentDescription: '',
      publiclyIndex: true,
      locallyIndex: true,
      contentMetadata: BranchContentMetaData()
        ..addCustomMetadata(UrlRes.postId, widget.videoData.postId),
    );

    // Creating BranchLinkProperties
    BranchLinkProperties lp = BranchLinkProperties(
      channel: 'facebook',
      feature: 'sharing',
      stage: 'new share',
      tags: ['one', 'two', 'three'],
    )
      ..addControlParam('url', 'http://www.google.com')
      ..addControlParam('url2', 'http://flutter.dev');

    // Getting Short URL
    BranchResponse response =
        await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
    return response.success ? response.result : '';
  }

  Future<void> addWatermarkToVideo(Uint8List? imageFile) async {
    try {
      final directory = Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : await getExternalStorageDirectory();
      if (directory == null) {
        CommonUI.showToast(msg: 'Storage directory not available.');
        return;
      }

      final outputPath = '${directory.path}/watermark_video.mp4';
      final watermarkImagePath = '${directory.path}/watermark_thumb.jpg';

      CommonUI.showToast(msg: LKey.videoDownloadingStarted.tr);

      // Save watermark image
      final watermarkBytes = await rootBundle.load(icLogo);
      File? watermarkFile = File(watermarkImagePath);
      await watermarkFile.writeAsBytes(watermarkBytes.buffer.asUint8List(),
          flush: true);

      File? captureFile = await _capturePng(imageFile, watermarkImagePath);
      if (captureFile == null) return print('Thumbnail not found');
      watermarkFile = captureFile;

      print('Watermark Path : ${watermarkFile.path}');

      // Download video
      File? videoFile;
      try {
        videoFile = await DefaultCacheManager().getSingleFile(
          '${ConstRes.itemBaseUrl}${widget.videoData.postVideo}',
        );
        print('✅ Video downloaded: ${videoFile.path}');
      } catch (e) {
        print('⛔️ Error downloading video: $e');
        CommonUI.showToast(msg: 'Failed to download video.');
        return;
      }

      // Add watermark
      final watermarkResult = await _retrytechPlugin.addWaterMarkInVideo(
        inputPath: videoFile.path,
        thumbnailPath: watermarkFile.path,
        username: '@${widget.videoData.userName ?? appName}',
        outputPath: outputPath,
      );

      if (watermarkResult == true) {
        // Save watermarked video to gallery
        final saveResult = await ImageGallerySaverPlus.saveFile(outputPath);
        print('🎞️ Video saved to gallery: $saveResult');
        CommonUI.showToast(msg: 'Video successfully saved to the gallery.');
      } else {
        print('❌ Failed to add watermark');
        CommonUI.showToast(msg: 'Failed to process video.');
      }
    } catch (e, stackTrace) {
      print('⛔️ Unexpected error: $e\n$stackTrace');
    } finally {
      await Future.delayed(Duration(seconds: 1));
      // Clean up the temp watermark video file if it exists
      try {
        final file = File(
            '${(await getExternalStorageDirectory())?.path}/watermark_video.mp4');
        if (await file.exists()) {
          await file.delete();
        }
        print('Cleaning video successfully');
      } catch (e) {
        print('⚠️ Failed to delete temp file: $e');
      }
    }
  }

  Future<File?> _capturePng(Uint8List? pngBytes, String outputPath) async {
    if (pngBytes == null) {
      print('Screenshot not captured');
      return null;
    }

    final imgFile = File(outputPath);
    return await imgFile.writeAsBytes(pngBytes);
  }
}
