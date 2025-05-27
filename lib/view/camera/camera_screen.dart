import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/modal/sound/sound.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/assert_image.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/view/camera/widget/seconds_tab.dart';
import 'package:bubbly/view/dialog/confirmation_dialog.dart';
import 'package:bubbly/view/music/music_screen.dart';
import 'package:bubbly/view/preview_screen.dart';
import 'package:bubbly_camera/bubbly_camera.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:video_compress/video_compress.dart';

class CameraScreen extends StatefulWidget {
  final String? soundUrl;
  final String? soundTitle;
  final String? soundId;

  CameraScreen({this.soundUrl, this.soundTitle, this.soundId});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  RetrytechPlugin _retryTechPlugin = RetrytechPlugin();
  bool isFlashOn = false;
  bool isFront = false;
  bool isSelected15s = true;
  bool isMusicSelect = false;
  bool isStartRecording = false;
  bool isRecordingStaring = false;
  bool isShowPlayer = false;
  String soundId = '';

  Timer? timer;
  double currentSecond = 0;
  double currentPercentage = 0;
  double totalSeconds = 15;

  AudioPlayer? _audioPlayer;

  SoundList? _selectedMusic;
  String? _localMusic;

  Map<String, dynamic> creationParams = <String, dynamic>{};

  ImagePicker _picker = ImagePicker();
  Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  List<CameraDescription> _cameras = [];
  bool _permissionNotGranted = true;

  @override
  void initState() {
    super.initState();
    initPermission();
    if (widget.soundUrl != null) {
      soundId = widget.soundId ?? '';
      downloadMusic();
    }
    if (Platform.isAndroid) {
      MethodChannel(ConstRes.bubblyCamera)
          .setMethodCallHandler((payload) async {
        gotoPreviewScreen(payload.arguments.toString());
      });
    }
    if (Platform.isIOS) {
      _initCameraView();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _audioPlayer?.release();
    _audioPlayer?.dispose();
    if (Platform.isAndroid) {
      BubblyCamera.cameraDispose;
    } else {
      cameraController.value?.dispose();
    }
    super.dispose();
  }

  Future<void> _initCameraView() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      print('Error : No camera available');
      return;
    }

    _initializeCameraController(_cameras[0]);
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    if (cameraController.value == null) {
      cameraController.value =
          CameraController(cameraDescription, ResolutionPreset.high);

      cameraController.value
          ?.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } else {
      cameraController.value = CameraController(
          cameraDescription, cameraController.value!.resolutionPreset);

      cameraController.refresh();
    }

    try {
      await cameraController.value?.initialize();
      cameraController.refresh();
      await cameraController.value
          ?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await cameraController.value?.prepareForVideoRecording();
    } catch (e) {
      print(e);
      if (e is CameraException) {
        CommonUI.showToast(msg: '${e.description}');
      } else {
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (Platform.isIOS)
            Obx(() {
              final camController = cameraController.value;
              if (camController == null || !camController.value.isInitialized) {
                return LoaderDialog(); // Show loader
              }
              return Align(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: .52,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                            width: camController.value.previewSize?.height,
                            height: camController.value.previewSize?.width,
                            child: CameraPreview(camController))),
                  ),
                ),
              );
            }),
          if (Platform.isAndroid)
            AndroidView(
                viewType: 'camera',
                layoutDirection: TextDirection.ltr,
                creationParams: creationParams,
                creationParamsCodec: StandardMessageCodec()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: LinearProgressIndicator(
                        backgroundColor: ColorRes.white,
                        minHeight: 3,
                        value: currentPercentage / 100,
                        color: ColorRes.colorPrimaryDark),
                  ),
                ),
              ),
              Visibility(
                visible: isMusicSelect,
                replacement: SizedBox(height: 10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    widget.soundTitle != null
                        ? '${widget.soundTitle ?? ''}'
                        : _selectedMusic != null
                            ? "${_selectedMusic?.soundTitle ?? ''}"
                            : '',
                    style: TextStyle(
                        fontFamily: FontRes.fNSfUiSemiBold,
                        fontSize: 15,
                        color: ColorRes.white),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isStartRecording)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: IconWithRoundGradient(
                        size: 22,
                        iconData: Icons.close_rounded,
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (mContext) {
                                return ConfirmationDialog(
                                  aspectRatio: 2,
                                  title1: LKey.areYouSure.tr,
                                  title2: LKey.doYouReallyWantToGoBack.tr,
                                  positiveText: LKey.yes.tr,
                                  onPositiveTap: () async {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                );
                              });
                        },
                      ),
                    ),
                  Spacer(),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: IconWithRoundGradient(
                          size: 20,
                          iconData: !isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          onTap: () async {
                            if (Platform.isAndroid) {
                              isFlashOn = !isFlashOn;
                              await BubblyCamera.flashOnOff;
                            } else {
                              if (!isFlashOn) {
                                cameraController.value
                                    ?.setFlashMode(FlashMode.torch);
                                isFlashOn = true;
                              } else {
                                cameraController.value
                                    ?.setFlashMode(FlashMode.off);
                                isFlashOn = false;
                              }
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      if (!isRecordingStaring)
                        Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: IconWithRoundGradient(
                            iconData: Icons.flip_camera_android_rounded,
                            size: 20,
                            onTap: () async {
                              if (Platform.isAndroid) {
                                BubblyCamera.toggleCamera;
                              } else {
                                CameraDescription? currentCamera =
                                    cameraController.value?.description;
                                final isFrontCamera =
                                    currentCamera?.lensDirection ==
                                        CameraLensDirection.front;
                                final newCamera = isFrontCamera
                                    ? _cameras.firstWhere((cam) =>
                                        cam.lensDirection ==
                                        CameraLensDirection.back)
                                    : _cameras.firstWhere((cam) =>
                                        cam.lensDirection ==
                                        CameraLensDirection.front);
                                if (currentCamera != null) {
                                  cameraController.value
                                      ?.setDescription(newCamera);
                                } else {
                                  _initializeCameraController(newCamera);
                                }
                              }
                            },
                          ),
                        ),
                      if (!isRecordingStaring)
                        Visibility(
                          visible: soundId.isEmpty,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(15))),
                                backgroundColor: ColorRes.colorPrimaryDark,
                                isScrollControlled: true,
                                builder: (context) {
                                  return MusicScreen(
                                    (data, localMusic) async {
                                      isMusicSelect = true;
                                      _selectedMusic = data;
                                      _localMusic = localMusic;
                                      soundId = data?.soundId.toString() ?? '';
                                      setState(() {});
                                    },
                                  );
                                },
                              ).then((value) {
                                Provider.of<MyLoading>(context, listen: false)
                                    .setLastSelectSoundId('');
                              });
                            },
                            child: Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: ImageWithRoundGradient(icMusic, 11)),
                          ),
                        ),
                    ],
                  )
                ],
              ),
              Spacer(),
              isRecordingStaring
                  ? SizedBox()
                  : Visibility(
                      visible: !isMusicSelect,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SecondsTab(
                            onTap: () {
                              isSelected15s = true;
                              totalSeconds = 15;
                              setState(() {});
                            },
                            isSelected: isSelected15s,
                            title: AppRes.fiftySecond,
                          ),
                          SizedBox(width: 15),
                          SecondsTab(
                            onTap: () {
                              isSelected15s = false;
                              totalSeconds = 30;
                              setState(() {});
                            },
                            isSelected: !isSelected15s,
                            title: AppRes.thirtySecond,
                          ),
                        ],
                      ),
                    ),
              SizedBox(height: 5),
              SafeArea(
                top: false,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isRecordingStaring
                          ? SizedBox(
                              width: 40,
                              height: isMusicSelect ? 0 : 40,
                            )
                          : Container(
                              width: 40,
                              height: isMusicSelect ? 0 : 40,
                              child: IconWithRoundGradient(
                                iconData: Icons.image,
                                size: isMusicSelect ? 0 : 20,
                                onTap: () => _showFilePicker(),
                              ),
                            ),
                      InkWell(
                        onTap: () async {
                          isStartRecording = !isStartRecording;
                          isRecordingStaring = true;
                          setState(() {});
                          startProgress();
                        },
                        child: Container(
                          height: 85,
                          width: 85,
                          decoration: BoxDecoration(
                              color: ColorRes.white, shape: BoxShape.circle),
                          padding: EdgeInsets.all(10.0),
                          alignment: Alignment.center,
                          child: isStartRecording
                              ? Icon(
                                  Icons.pause,
                                  color: ColorRes.colorTheme,
                                  size: 50,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: ColorRes.colorTheme,
                                    shape: isStartRecording
                                        ? BoxShape.rectangle
                                        : BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),
                      Visibility(
                        visible: !isStartRecording,
                        replacement: SizedBox(height: 38, width: 38),
                        child: IconWithRoundGradient(
                          iconData: Icons.check_circle_rounded,
                          size: 20,
                          onTap: () async {
                            if (!isRecordingStaring) {
                              CommonUI.showToast(msg: LKey.videoIsToShort.tr);
                            } else {
                              if (Platform.isAndroid) {
                                await BubblyCamera.stopRecording;
                              } else {
                                onVideoRecordingStop();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!_permissionNotGranted)
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: ColorRes.colorPrimaryDark,
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Container(
                            height: 35,
                            width: 35,
                            margin: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: ColorRes.white.withValues(alpha: 0.1)),
                            alignment: Alignment.center,
                            child: const Icon(Icons.close_rounded,
                                color: ColorRes.white, size: 25)),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: RichText(
                        text: TextSpan(
                          text: '${LKey.allow.tr} ',
                          children: [
                            TextSpan(
                                text: appName,
                                style: TextStyle(
                                    color: ColorRes.colorPink,
                                    fontFamily: FontRes.fNSfUiBold,
                                    fontSize: 17)),
                            TextSpan(
                                text:
                                    ' ${LKey.toAccessYourCameraAndMicrophone}')
                          ],
                          style: TextStyle(
                            fontFamily: FontRes.fNSfUiSemiBold,
                            fontSize: 20,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        LKey.ifAppearsThatCameraPermissionHasNotBeenGrantedEtc
                            .tr,
                        style: TextStyle(
                            fontFamily: FontRes.fNSfUiRegular,
                            color: ColorRes.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    InkWell(
                      onTap: () {
                        openAppSettings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: ColorRes.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          LKey.openSettings.tr,
                          style: TextStyle(
                              color: ColorRes.colorPink,
                              fontFamily: FontRes.fNSfUiSemiBold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 33),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 40,
                          height: isMusicSelect ? 0 : 40,
                          child: IconWithRoundGradient(
                            iconData: Icons.image,
                            size: isMusicSelect ? 0 : 20,
                            onTap: () => _showFilePicker(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15)
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Future<String> _findLocalPath() async {
    final directory = Platform.isAndroid
        ? await (getExternalStorageDirectory())
        : await getApplicationDocumentsDirectory();
    return directory!.path;
  }

  void downloadMusic() async {
    File musicFile = await DefaultCacheManager()
        .getSingleFile('${ConstRes.itemBaseUrl}${widget.soundUrl}');
    _localMusic = musicFile.path;
    setState(() {});
  }

  // Recording
  void startProgress() async {
    if (timer == null) {
      initProgress();
    } else {
      if (isStartRecording) {
        initProgress();
      } else {
        cancelTimer();
      }
    }

    if (isStartRecording) {
      if (currentSecond == 0) {
        if (soundId.isNotEmpty) {
          try {
            _audioPlayer = AudioPlayer(playerId: '1');
            await _audioPlayer?.play(
              DeviceFileSource(_localMusic!),
              mode: PlayerMode.mediaPlayer,
              ctx: AudioContext(
                android: AudioContextAndroid(isSpeakerphoneOn: true),
                iOS: AudioContextIOS(
                  category: AVAudioSessionCategory.playAndRecord,
                  options: {
                    AVAudioSessionOptions.allowAirPlay,
                    AVAudioSessionOptions.allowBluetooth,
                    AVAudioSessionOptions.allowBluetoothA2DP,
                    AVAudioSessionOptions.defaultToSpeaker
                  },
                ),
              ),
            );
            var totalSecond = await Future.delayed(
                Duration(milliseconds: 300), () => _audioPlayer?.getDuration());
            totalSeconds = totalSecond!.inSeconds.toDouble();
            initProgress();
          } catch (e) {
            print('Error playing audio: $e');
          }
        }
        if (Platform.isAndroid) {
          try {
            await BubblyCamera.startRecording();
          } catch (e) {
            print('Error starting recording: $e');
          }
        } else {
          onVideoRecordingStart();
        }
      } else {
        print('Audio Resume Recording');
        await _audioPlayer?.resume();
        if (Platform.isAndroid) {
          try {
            await BubblyCamera.resumeRecording();
          } catch (e) {
            print('Error resuming recording: $e');
          }
        } else {
          onVideoRecordingResume();
        }
      }
    } else {
      print('Audio Pause Recording');
      await _audioPlayer?.pause();
      if (Platform.isAndroid) {
        try {
          await BubblyCamera.pauseRecording();
        } catch (e) {
          print('Error pausing recording: $e');
        }
      } else {
        onVideoRecordingPause();
      }
    }
  }

  void gotoPreviewScreen(String pathOfVideo) async {
    File thumbnail = await VideoCompress.getFileThumbnail(pathOfVideo);

    if (soundId.isNotEmpty) {
      CommonUI.showLoader(context);

      try {
        String localPath = await _findLocalPath();
        String outputPath = '$localPath/out.mp4';
        bool? result = await _retryTechPlugin.applyFilterAndAudioToVideo(
            inputPath: pathOfVideo,
            audioPath: '$_localMusic',
            outputPath: outputPath);

        Get.back();
        if (result == true) {
          _navigatePreviewScreen(
              postVideo: outputPath, thumbnail: thumbnail.path);
        } else {
          print('Error: $result');
          CommonUI.showToast(msg: 'Error while applying Audio...');
        }
      } catch (e) {
        Get.back();
        print('Error: $e');
      }
    } else {
      CommonUI.showLoader(context);
      try {
        String localPath = await _findLocalPath();
        String soundPath = '$localPath/sound.m4a';
        bool? result = await _retryTechPlugin.extractAudio(
            inputPath: "$pathOfVideo", outputPath: soundPath);
        Get.back();
        if (result == true) {
          _navigatePreviewScreen(
              postVideo: pathOfVideo,
              thumbnail: thumbnail.path,
              sound: soundPath);
        } else {
          print('Audio Not extract');
          CommonUI.showToast(msg: 'Error while extracting audio...');
        }
      } catch (e) {
        Get.back();
        CommonUI.showToast(msg: '$e');
      }
    }
  }

  void _navigatePreviewScreen({required String postVideo,
    required String thumbnail,
    String? sound,
    int? duration}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          postVideo: '$postVideo',
          thumbNail: "$thumbnail",
          soundId: soundId,
          duration: duration ?? currentSecond.toInt(),
          sound: sound,
        ),
      ),
    ).then((value) {
      Get.back();
      Get.back();
    });
  }

  Future<void> _showFilePicker() async {
    HapticFeedback.mediumImpact();
    CommonUI.getLoader();

    try {
      final XFile? videoFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      Get.back(); // Close loader after picking

      if (videoFile == null) {
        CommonUI.showToast(msg: 'Video file not found');
        return;
      }

      final file = File(videoFile.path);
      final fileSize = await getFileSizeInMB(file);

      if (fileSize > maxUploadMB) {
        return _showDialog(
          title1: LKey.tooLargeVideo,
          title2: LKey.thisVideoIsGreaterThan50MbNPleaseSelectAnother.tr,
        );
      }

      final MediaInfo? videoInfo =
          await VideoCompress.getMediaInfo(videoFile.path);
      final videoDuration = ((videoInfo?.duration ?? 0) / 1000).toInt();

      if (videoDuration > maxUploadSecond) {
        return _showDialog(
          title1: LKey.tooLongVideo.tr,
          title2: LKey.thisVideoIsGreaterThan1MinNPleaseSelectAnother.tr,
        );
      }

      CommonUI.getLoader(); // Show loader before extraction

      final localPath = await _findLocalPath();
      final audioOutputPath = '$localPath/sound.m4a';

      final bool? extractionSuccess = await _retryTechPlugin.extractAudio(
        inputPath: videoFile.path,
        outputPath: audioOutputPath,
      );

      if (extractionSuccess != true) {
        Get.back(); // Close loader
        return CommonUI.showToast(msg: 'Failed to extract audio');
      }

      final File thumbnail =
          await VideoCompress.getFileThumbnail(videoFile.path);

      Get.back(); // Close loader

      _navigatePreviewScreen(
        postVideo: videoFile.path,
        thumbnail: thumbnail.path,
        sound: audioOutputPath,
        duration: videoDuration,
      );
    } catch (e) {
      Get.back(); // Ensure loader is closed
      CommonUI.showToast(
        msg: LKey.pleaseAcceptLibraryPermissionToPickAVideo.tr,
      );
    }
  }

  /// Helper to show re-pick confirmation dialogs
  void _showDialog({
    required String title1,
    required String title2,
  }) {
    Get.dialog(
      ConfirmationDialog(
        aspectRatio: 1.8,
        title1: title1,
        title2: title2,
        positiveText: LKey.selectAnother.tr,
        onPositiveTap: () {
          Get.back();
          _showFilePicker(); // Retry
        },
      ),
    );
  }

  void initProgress() {
    timer?.cancel();
    timer = null;

    timer = Timer.periodic(Duration(milliseconds: 10), (time) async {
      currentSecond += 0.01;
      currentPercentage = (100 * currentSecond) / totalSeconds;
      if (totalSeconds.toInt() <= currentSecond.toInt()) {
        timer?.cancel();
        timer = null;
        // if (soundId.isNotEmpty && Platform.isIOS) {
        //   _stopAndMergeVideoForIos(isAutoStop: true);
        // } else {
        //   await BubblyCamera.stopRecording;
        // }
        if (Platform.isAndroid) {
          await BubblyCamera.stopRecording;
        } else {
          onVideoRecordingStop();
        }
      }
      setState(() {});
    });
  }

  void cancelTimer() {
    timer?.cancel();
    timer = null;
  }

  Future<double> getFileSizeInMB(File file) async {
    try {
      int fileSizeInBytes = await file.length();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      return fileSizeInMB;
    } catch (e) {
      print('Error getting file size: $e');
      return -1;
    }
  }

  void initPermission() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      print('[Permission] Granted');
      _permissionNotGranted = true;
    } else {
      _permissionNotGranted = false;
      print('[Permission] Not Granted');
    }
    setState(() {});
  }

  void onVideoRecordingStart() async {
    final controller = cameraController.value;
    if (controller == null) return;
    try {
      await controller.startVideoRecording();
    } catch (e) {
      print("Error starting video recording: $e");
    }
  }

  void onVideoRecordingPause() async {
    final controller = cameraController.value;
    if (controller == null) return;
    try {
      await controller.pauseVideoRecording();
      print('VIDEO RECORDING PAUSED');
    } catch (e) {
      print("Error pausing video recording: $e");
    }
  }

  void onVideoRecordingResume() async {
    final controller = cameraController.value;
    if (controller == null) return;
    try {
      await controller.resumeVideoRecording();
      print('VIDEO RECORDING RESUMED');
    } catch (e) {
      print("Error resuming video recording: $e");
    }
  }

  void onVideoRecordingStop() async {
    final controller = cameraController.value;
    if (controller == null) return;
    try {
      XFile? file = await controller.stopVideoRecording();
      gotoPreviewScreen(file.path);
    } catch (e) {
      print("Error stopping video recording: $e");
    }
  }
}

class IconWithRoundGradient extends StatelessWidget {
  final IconData iconData;
  final double size;
  final Function? onTap;

  IconWithRoundGradient(
      {required this.iconData, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: InkWell(
        onTap: () => onTap?.call(),
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [ColorRes.colorTheme, ColorRes.colorPink])),
          child: Icon(iconData, color: ColorRes.white, size: size),
        ),
      ),
    );
  }
}

class ImageWithRoundGradient extends StatelessWidget {
  final String imageData;
  final double padding;

  ImageWithRoundGradient(this.imageData, this.padding);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ColorRes.colorTheme, ColorRes.colorPink],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Image(
            image: AssetImage(imageData),
            color: ColorRes.white,
          ),
        ),
      ),
    );
  }
}
