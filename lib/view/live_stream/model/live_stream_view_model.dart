import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/custom_view/common_ui.dart';
import 'package:bubbly/modal/live_stream/live_stream.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/firebase_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/view/live_stream/screen/audience_screen.dart';
import 'package:bubbly/view/live_stream/screen/broad_cast_screen.dart';
import 'package:bubbly/view/live_stream/widget/live_stream_end_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LiveStreamScreenViewModel extends BaseViewModel {
  SessionManager pref = SessionManager();
  FirebaseFirestore db = FirebaseFirestore.instance;
  List<LiveStreamUser> liveUsers = [];
  StreamSubscription<QuerySnapshot<LiveStreamUser>>? userStream;
  List<String> joinedUser = [];
  User? registrationUser;

  SettingData? settingData;

  void init() {
    prefData();
    WakelockPlus.enable();
  }

  void prefData() async {
    await pref.initPref();
    registrationUser = pref.getUser();
    settingData = pref.getSetting()?.data;
    getLiveStreamUser();
  }

  void goLiveTap(BuildContext context) async {
    CommonUI.showLoader(context);
    try {
      await ApiService()
          .generateAgoraToken(registrationUser?.data?.identity)
          .then((value) async {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => BroadCastScreen(
                registrationUser: registrationUser,
                agoraToken: value.token,
                channelName: registrationUser?.data?.identity),
          ),
        );
      });
    } catch (e) {
      Navigator.pop(context);
      CommonUI.showToast(msg: 'حدث خطأ أثناء بدء البث المباشر');
      log('Error in goLiveTap: $e');
    }
  }

  void getLiveStreamUser() {
    userStream = db
        .collection(FirebaseRes.liveStreamUser)
        .withConverter(
          fromFirestore: LiveStreamUser.fromFireStore,
          toFirestore: (LiveStreamUser value, options) {
            return value.toFireStore();
          },
        )
        .snapshots()
        .listen((event) {
      liveUsers = [];
      for (int i = 0; i < event.docs.length; i++) {
        liveUsers.add(event.docs[i].data());
      }
      notifyListeners();
    });
  }

  void onImageTap(BuildContext context, LiveStreamUser user) async {
    // التحقق من صحة البيانات المطلوبة
    if (user.hostIdentity == null || user.hostIdentity!.isEmpty) {
      CommonUI.showToast(msg: 'معرف المضيف غير صحيح');
      return;
    }

    if (settingData?.agoraAppId == null) {
      CommonUI.showToast(msg: 'إعدادات التطبيق غير متوفرة');
      return;
    }

    String authString = '${ConstRes.customerId}:${ConstRes.customerSecret}';
    String authToken = base64.encode(authString.codeUnits);
    CommonUI.showLoader(context);

    try {
      final response = await ApiService().agoraListStreamingCheck(
          user.hostIdentity!, authToken, '${settingData!.agoraAppId}');

      Navigator.pop(context);

      // طباعة تفاصيل الاستجابة للتشخيص
      log('Full API Response: ${response.toString()}');
      log('Response message: ${response.message ?? 'No message'}');
      log('Response data: ${response.data?.toJson().toString() ?? 'No data received'}');

      // التحقق من وجود رسالة خطأ (عدا مشاكل المصادقة)
      if (response.message != null &&
          response.message!.isNotEmpty &&
          !response.message!.contains('مصادقة')) {
        CommonUI.showToast(msg: response.message!);
        return;
      }

      // التحقق من حالة البث
      bool shouldAllowEntry = false;

      if (response.data != null) {
        bool channelExists = response.data?.channelExist == true;
        bool hasBroadcasters = response.data?.broadcasters != null &&
            response.data!.broadcasters!.isNotEmpty;

        log('Channel exists: $channelExists');
        log('Has broadcasters: $hasBroadcasters');
        log('Broadcasters count: ${response.data?.broadcasters?.length ?? 0}');

        shouldAllowEntry = channelExists || hasBroadcasters;
      } else {
        // إذا لم نحصل على بيانات، نسمح بالدخول (fallback)
        log('No data received, allowing entry as fallback');
        shouldAllowEntry = true;
      }

      if (shouldAllowEntry) {
        // البث نشط أو نسمح بالدخول - يمكن الانضمام
        log('Allowing entry to stream...');

        // التحقق من وجود معرف المستخدم
        String? userIdentity = registrationUser?.data?.identity;
        if (userIdentity != null && userIdentity.isNotEmpty) {
          joinedUser.clear(); // مسح القائمة أولاً
          joinedUser.add(userIdentity);
        }

        // التحقق من وجود watchingCount
        int currentWatchingCount = user.watchingCount ?? 0;

        try {
          await db
              .collection(FirebaseRes.liveStreamUser)
              .doc(user.hostIdentity)
              .update({
            FirebaseRes.watchingCount: currentWatchingCount + 1,
            FirebaseRes.joinedUser: FieldValue.arrayUnion(joinedUser),
          });

          // الانتقال لشاشة المشاهدة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudienceScreen(
                channelName: user.hostIdentity,
                agoraToken: user.agoraToken,
                user: user,
              ),
            ),
          );
        } catch (error) {
          log('Error updating watching count: $error');

          // حتى لو فشل التحديث، ندخل المستخدم للبث
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudienceScreen(
                channelName: user.hostIdentity,
                agoraToken: user.agoraToken,
                user: user,
              ),
            ),
          );
        }
      } else {
        // البث غير نشط
        log('Stream is not active, showing end sheet');

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (c) {
            return LiveStreamEndSheet(
              name: user.fullName ?? 'مستخدم غير معروف',
              onExitBtn: () async {
                Navigator.pop(context);

                try {
                  // حذف وثيقة البث المباشر
                  await db
                      .collection(FirebaseRes.liveStreamUser)
                      .doc(user.hostIdentity)
                      .delete();

                  // حذف التعليقات المرتبطة
                  final batch = db.batch();
                  var collection = db
                      .collection(FirebaseRes.liveStreamUser)
                      .doc(user.hostIdentity)
                      .collection(FirebaseRes.comment);
                  var snapshots = await collection.get();
                  for (var doc in snapshots.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();
                } catch (e) {
                  log('Error deleting live stream data: $e');
                  CommonUI.showToast(msg: 'حدث خطأ أثناء إنهاء البث');
                }
              },
            );
          },
        );
      }
    } catch (e) {
      Navigator.pop(context);
      log('Error in onImageTap: $e');

      // في حالة الخطأ، نسمح بالدخول للبث (fallback behavior)
      log('Fallback: Allowing entry due to error');

      try {
        String? userIdentity = registrationUser?.data?.identity;
        if (userIdentity != null && userIdentity.isNotEmpty) {
          joinedUser.clear();
          joinedUser.add(userIdentity);
        }

        int currentWatchingCount = user.watchingCount ?? 0;

        await db
            .collection(FirebaseRes.liveStreamUser)
            .doc(user.hostIdentity)
            .update({
          FirebaseRes.watchingCount: currentWatchingCount + 1,
          FirebaseRes.joinedUser: FieldValue.arrayUnion(joinedUser),
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudienceScreen(
              channelName: user.hostIdentity,
              agoraToken: user.agoraToken,
              user: user,
            ),
          ),
        );
      } catch (fallbackError) {
        log('Fallback also failed: $fallbackError');
        CommonUI.showToast(msg: 'حدث خطأ أثناء الدخول للبث');
      }
    }
  }

  @override
  void dispose() {
    userStream?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}