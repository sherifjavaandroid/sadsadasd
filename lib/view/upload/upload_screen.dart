import 'dart:developer';
import 'dart:io';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/custom_view/privacy_policy_view.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utils/app_res.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/font_res.dart';
import 'package:bubbly/utils/my_loading/my_loading.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class UploadScreen extends StatefulWidget {
  final String? postVideo;
  final String? thumbNail;
  final String? sound;
  final String soundId;

  UploadScreen({this.postVideo, this.thumbNail, this.sound, required this.soundId});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<String> hashTags = [];
  SessionManager _sessionManager = SessionManager();
  DetectableTextEditingController detectableController = DetectableTextEditingController(
      regExp: detectionRegExp(hashtag: true),
      detectedStyle: TextStyle(fontFamily: FontRes.fNSfUiSemiBold, color: ColorRes.colorPink));

  @override
  void initState() {
    initSessionManager();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, MyLoading myLoading, child) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: 440,
          decoration: BoxDecoration(
            color: myLoading.isDark ? ColorRes.colorPrimary : ColorRes.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(
            children: [
              Column(
                children: [
                  SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(LKey.uploadVideo.tr,
                          style: TextStyle(fontSize: 16, fontFamily: FontRes.fNSfUiBold)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.close_rounded),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      )
                    ],
                  ),
                  Divider(thickness: 1),
                  SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        child: Image(
                          height: 160,
                          width: 110,
                          fit: BoxFit.cover,
                          image: FileImage(File(widget.thumbNail!)),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LKey.describe.tr,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: myLoading.isDark
                                    ? ColorRes.colorPrimaryDark
                                    : ColorRes.greyShade100,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              padding: EdgeInsets.only(left: 15, right: 15),
                              height: 130,
                              child: DetectableTextField(
                                controller: detectableController,
                                style: TextStyle(
                                  fontFamily: FontRes.fNSfUiRegular,
                                  letterSpacing: 0.6,
                                  fontSize: 13,
                                  color: ColorRes.colorTextLight,
                                ),
                                textInputAction: TextInputAction.done,
                                inputFormatters: [LengthLimitingTextInputFormatter(175)],
                                enableSuggestions: false,
                                maxLines: 8,
                                onChanged: onChangeDetectableTextField,
                                onTapOutside: (event) =>
                                    FocusManager.instance.primaryFocus?.unfocus(),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: LKey.awesomeCaption.tr,
                                  hintStyle: TextStyle(
                                    color: ColorRes.colorTextLight,
                                  ),
                                ),
                                cursorColor: ColorRes.colorTextLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                      child: Text(
                        '${detectableController.text.length}/${AppRes.maxLengthText}',
                        style: TextStyle(
                          color: ColorRes.colorTextLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: InkWell(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();

                    List<String> removeHasTag = [];
                    for (var element in hashTags) {
                      removeHasTag.add(element.replaceAll('#', ''));
                    }

                    CommonUI.showLoader(context);
                    if (widget.soundId.isNotEmpty) {
                      log('SOUND ID NOT NULL');
                      ApiService()
                          .addPost(
                              postVideo: File(widget.postVideo ?? ''),
                              thumbnail: File(widget.thumbNail ?? ''),
                              duration: '1',
                              isOriginalSound: '0',
                              postDescription: detectableController.text.trim(),
                              postHashTag: removeHasTag.join(","),
                              soundId: widget.soundId)
                          .then(
                        (value) {
                          Get.back();
                          if (value.status == 200) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            CommonUI.showToast(msg: LKey.postUploadSuccessfully.tr);
                          } else if (value.status == 401) {
                            Navigator.pop(context);
                            CommonUI.showToast(msg: "${value.message}");
                          }
                        },
                      );
                    } else {
                      log('SOUND ID NULL');
                      ApiService()
                          .addPost(
                        postVideo: File(widget.postVideo!),
                        thumbnail: File(widget.thumbNail!),
                        // postSound: File(widget.sound),
                        soundImage: File(widget.thumbNail!),
                        duration: '1',
                        isOriginalSound: widget.soundId.isNotEmpty ? '0' : '1',
                        postDescription: detectableController.text.trim(),
                        postHashTag: removeHasTag.join(","),
                        singer: _sessionManager.getUser()?.data?.fullName,
                        soundTitle: 'Original Sound',
                      )
                          .then(
                        (value) {
                          Get.back();
                          if (value.status == 200) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            CommonUI.showToast(msg: LKey.postUploadSuccessfully.tr);
                          } else if (value.status == 401) {
                            CommonUI.showToast(msg: "${value.message}");
                          }
                        },
                      );
                    }
                  },
                  child: FittedBox(
                    child: Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorRes.colorTheme,
                            ColorRes.colorPink,
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Center(
                        child: Text(
                          LKey.publish.tr.toUpperCase(),
                          style: TextStyle(
                              fontFamily: FontRes.fNSfUiBold,
                              letterSpacing: 1,
                              color: ColorRes.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              PrivacyPolicyView()
            ],
          ),
        ),
      );
    });
  }

  void initSessionManager() async {
    await _sessionManager.initPref();
  }

  void onChangeDetectableTextField(String value) {
    hashTags = TextPatternDetector.extractDetections(value, hashTagRegExp);
    setState(() {});
  }
}
