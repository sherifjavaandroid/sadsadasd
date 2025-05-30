import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bubbly/modal/agora/agora.dart';
import 'package:bubbly/modal/agora/agora_token.dart';
import 'package:bubbly/modal/comment/comment.dart';
import 'package:bubbly/modal/explore/explore_hash_tag.dart';
import 'package:bubbly/modal/file_path/file_path.dart';
import 'package:bubbly/modal/followers/follower_following_data.dart';
import 'package:bubbly/modal/notification/notification.dart';
import 'package:bubbly/modal/nudity/nudity_checker.dart';
import 'package:bubbly/modal/nudity/nudity_media_id.dart';
import 'package:bubbly/modal/plan/coin_plans.dart';
import 'package:bubbly/modal/profileCategory/profile_category.dart';
import 'package:bubbly/modal/rest/rest_response.dart';
import 'package:bubbly/modal/search/search_user.dart';
import 'package:bubbly/modal/setting/setting.dart';
import 'package:bubbly/modal/single/single_post.dart';
import 'package:bubbly/modal/sound/fav/favourite_music.dart';
import 'package:bubbly/modal/sound/sound.dart';
import 'package:bubbly/modal/status.dart';
import 'package:bubbly/modal/user/user.dart';
import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/modal/wallet/my_wallet.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:firebase_auth/firebase_auth.dart' as FireBaseAuth1;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class ApiService {
  var client = http.Client();

  // دالة مساعدة لطباعة تفاصيل الطلب
  void _logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
    String? description,
  }) {
    print('\n' + '=' * 80);
    print('🚀 إرسال طلب API جديد');
    print('=' * 80);
    print('📝 الوصف: ${description ?? 'غير محدد'}');
    print('🔗 الرابط: $url');
    print('📋 النوع: $method');
    print('🕐 الوقت: ${DateTime.now().toIso8601String()}');

    if (headers != null && headers.isNotEmpty) {
      print('\n📤 Headers:');
      headers.forEach((key, value) {
        // إخفاء التوكن للأمان
        if (key.toLowerCase().contains('authorization') && value.isNotEmpty) {
          print(
              '  $key: ${value.length > 10 ? value.substring(0, 10) + '...[مخفي]' : '[مخفي]'}');
        } else {
          print('  $key: $value');
        }
      });
    }

    if (body != null) {
      print('\n📦 البيانات المرسلة:');
      if (body is Map) {
        body.forEach((key, value) {
          print('  $key: $value');
        });
      } else if (body is String) {
        if (body.length > 500) {
          print('  ${body.substring(0, 500)}...[مقطوع]');
        } else {
          print('  $body');
        }
      } else {
        print('  $body');
      }
    }
    print('=' * 80 + '\n');
  }

  // دالة مساعدة لطباعة تفاصيل الاستجابة
  void _logResponse({
    required http.Response response,
    String? description,
  }) {
    print('\n' + '=' * 80);
    print('📥 استلام استجابة API');
    print('=' * 80);
    print('📝 الوصف: ${description ?? 'غير محدد'}');
    print('🔗 الرابط: ${response.request?.url}');
    print('📊 كود الحالة: ${response.statusCode}');
    print('🕐 الوقت: ${DateTime.now().toIso8601String()}');

    if (response.headers.isNotEmpty) {
      print('\n📥 Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
    }

    print('\n📋 محتوى الاستجابة:');
    print('حجم البيانات: ${response.body.length} حرف');

    // محاولة تنسيق JSON إذا كان صالحاً
    try {
      final jsonData = jsonDecode(response.body);
      final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);
      print('📄 JSON المنسق:');
      if (prettyJson.length > 2000) {
        print('${prettyJson.substring(0, 2000)}...[مقطوع]');
      } else {
        print(prettyJson);
      }
    } catch (e) {
      print('📄 النص الخام:');
      if (response.body.length > 1000) {
        print('${response.body.substring(0, 1000)}...[مقطوع]');
      } else {
        print(response.body);
      }
    }
    print('=' * 80 + '\n');
  }

  // دالة مساعدة لطباعة تفاصيل Multipart Request
  void _logMultipartRequest({
    required http.MultipartRequest request,
    String? description,
  }) {
    print('\n' + '=' * 80);
    print('🚀 إرسال طلب Multipart');
    print('=' * 80);
    print('📝 الوصف: ${description ?? 'غير محدد'}');
    print('🔗 الرابط: ${request.url}');
    print('📋 النوع: ${request.method}');
    print('🕐 الوقت: ${DateTime.now().toIso8601String()}');

    if (request.headers.isNotEmpty) {
      print('\n📤 Headers:');
      request.headers.forEach((key, value) {
        if (key.toLowerCase().contains('authorization') && value.isNotEmpty) {
          print(
              '  $key: ${value.length > 10 ? value.substring(0, 10) + '...[مخفي]' : '[مخفي]'}');
        } else {
          print('  $key: $value');
        }
      });
    }

    if (request.fields.isNotEmpty) {
      print('\n📦 الحقول:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });
    }

    if (request.files.isNotEmpty) {
      print('\n📁 الملفات:');
      for (var file in request.files) {
        print('  ${file.field}: ${file.filename} (${file.length} بايت)');
      }
    }
    print('=' * 80 + '\n');
  }

  // دالة مساعدة لطباعة استجابة Multipart
  void _logMultipartResponse({
    required http.StreamedResponse response,
    required String responseBody,
    String? description,
  }) {
    print('\n' + '=' * 80);
    print('📥 استلام استجابة Multipart');
    print('=' * 80);
    print('📝 الوصف: ${description ?? 'غير محدد'}');
    print('🔗 الرابط: ${response.request?.url}');
    print('📊 كود الحالة: ${response.statusCode}');
    print('🕐 الوقت: ${DateTime.now().toIso8601String()}');

    if (response.headers.isNotEmpty) {
      print('\n📥 Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
    }

    print('\n📋 محتوى الاستجابة:');
    print('حجم البيانات: ${responseBody.length} حرف');

    try {
      final jsonData = jsonDecode(responseBody);
      final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);
      print('📄 JSON المنسق:');
      if (prettyJson.length > 2000) {
        print('${prettyJson.substring(0, 2000)}...[مقطوع]');
      } else {
        print(prettyJson);
      }
    } catch (e) {
      print('📄 النص الخام:');
      if (responseBody.length > 1000) {
        print('${responseBody.substring(0, 1000)}...[مقطوع]');
      } else {
        print(responseBody);
      }
    }
    print('=' * 80 + '\n');
  }

  // دالة مساعدة لطباعة استجابة GET
  void _logGetResponse({
    required http.Response response,
    String? description,
  }) {
    print('\n' + '=' * 80);
    print('📥 استلام استجابة GET');
    print('=' * 80);
    print('📝 الوصف: ${description ?? 'غير محدد'}');
    print('🔗 الرابط: ${response.request?.url}');
    print('📊 كود الحالة: ${response.statusCode}');
    print('🕐 الوقت: ${DateTime.now().toIso8601String()}');

    if (response.headers.isNotEmpty) {
      print('\n📥 Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
    }

    print('\n📋 محتوى الاستجابة:');
    print('حجم البيانات: ${response.body.length} حرف');

    try {
      final jsonData = jsonDecode(response.body);
      final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);
      print('📄 JSON المنسق:');
      if (prettyJson.length > 2000) {
        print('${prettyJson.substring(0, 2000)}...[مقطوع]');
      } else {
        print(prettyJson);
      }
    } catch (e) {
      print('📄 النص الخام:');
      if (response.body.length > 1000) {
        print('${response.body.substring(0, 1000)}...[مقطوع]');
      } else {
        print(response.body);
      }
    }
    print('=' * 80 + '\n');
  }

  Future<User> registerUser(HashMap<String, String?> params) async {
    final url = UrlRes.registerUser;
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: url,
      headers: headers,
      body: params,
      description: 'تسجيل مستخدم جديد',
    );

    final response = await client.post(
      Uri.parse(url),
      headers: headers,
      body: params,
    );

    _logResponse(response: response, description: 'نتيجة تسجيل المستخدم');

    final responseJson = jsonDecode(response.body);
    SessionManager sessionManager = SessionManager();
    await sessionManager.initPref();
    sessionManager.saveUser(jsonEncode(User.fromJson(responseJson)));
    return User.fromJson(responseJson);
  }

  Future<UserVideo> getUserVideos(String star, String limit, String? userId, int type) async {
    Map<String, String> body = {
      UrlRes.start: star,
      UrlRes.limit: limit,
      UrlRes.userId: '$userId',
      UrlRes.myUserId: '${SessionManager.userId}',
    };

    final url = type == 0 ? UrlRes.getUserVideos : UrlRes.getUserLikesVideos;
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
      description:
          type == 0 ? 'جلب فيديوهات المستخدم' : 'جلب فيديوهات الإعجابات',
    );

    final response = await client.post(
      Uri.parse(url),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة جلب الفيديوهات');

    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }

  Future<UserVideo> getPostList(String limit, String userId, String type) async {
    final body = {
      UrlRes.limit: limit,
      UrlRes.userId: userId,
      UrlRes.type: type,
    };
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.getPostList,
      headers: headers,
      body: body,
      description: 'جلب قائمة المنشورات',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getPostList),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة جلب قائمة المنشورات');

    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }

  Future<RestResponse> likeUnlikePost(String postId) async {
    final body = {UrlRes.postId: postId};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.likeUnlikePost,
      headers: headers,
      body: body,
      description: 'إعجاب/إلغاء إعجاب المنشور',
    );

    final response = await client.post(
      Uri.parse(UrlRes.likeUnlikePost),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response, description: 'نتيجة الإعجاب/إلغاء الإعجاب');

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<Comment> getCommentByPostId(String start, String limit, String postId) async {
    final body = {
      UrlRes.postId: postId,
      UrlRes.start: start,
      UrlRes.limit: limit,
    };
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.getCommentByPostId,
      headers: headers,
      body: body,
      description: 'جلب تعليقات المنشور',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getCommentByPostId),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة جلب التعليقات');

    final responseJson = jsonDecode(response.body);
    return Comment.fromJson(responseJson);
  }

  Future<RestResponse> addComment(String comment, String postId) async {
    final body = {
      UrlRes.postId: postId,
      UrlRes.comment: comment,
    };
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.addComment,
      headers: headers,
      body: body,
      description: 'إضافة تعليق جديد',
    );

    final response = await client.post(
      Uri.parse(UrlRes.addComment),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة إضافة التعليق');

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> deleteComment(String commentID) async {
    final body = {UrlRes.commentId: commentID};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.deleteComment,
      headers: headers,
      body: body,
      description: 'حذف تعليق',
    );

    final response = await client.post(
      Uri.parse(UrlRes.deleteComment),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة حذف التعليق');

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<UserVideo> getPostByHashTag(String start, String limit, String? hashTag) async {
    final body = {
      UrlRes.start: start,
      UrlRes.limit: limit,
      UrlRes.userId: SessionManager.userId.toString(),
      UrlRes.hashTag: hashTag,
    };
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.videosByHashTag,
      headers: headers,
      body: body,
      description: 'جلب المنشورات بالهاشتاج',
    );

    final response = await client.post(
      Uri.parse(UrlRes.videosByHashTag),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response, description: 'نتيجة جلب المنشورات بالهاشتاج');

    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }

  Future<UserVideo> getPostBySoundId(String start, String limit, String? soundId) async {
    final body = {
      UrlRes.start: start,
      UrlRes.limit: limit,
      UrlRes.userId: SessionManager.userId.toString(),
      UrlRes.soundId: soundId,
    };
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.getPostBySoundId,
      headers: headers,
      body: body,
      description: 'جلب المنشورات بالصوت',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getPostBySoundId),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة جلب المنشورات بالصوت');

    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }

  Future<RestResponse> sendCoin(String coin, String toUserId) async {
    try {
      final body = {
        UrlRes.coin: coin,
        UrlRes.toUserId: toUserId,
      };
      final headers = {
        UrlRes.uniqueKey: ConstRes.apiKey,
        UrlRes.authorization: SessionManager.accessToken,
      };

      _logRequest(
        method: 'POST',
        url: UrlRes.sendCoin,
        headers: headers,
        body: body,
        description: 'إرسال عملات للمستخدم',
      );

      final response = await client.post(
        Uri.parse(UrlRes.sendCoin),
        body: body,
        headers: headers,
      );

      _logResponse(response: response, description: 'نتيجة إرسال العملات');

      // Check if response is successful
      if (response.statusCode != 200) {
        throw Exception(
            'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }

      // Check if response body is empty
      if (response.body.isEmpty) {
        throw Exception('Empty response body');
      }

      // Check if response is HTML (error page)
      if (response.body.trim().toLowerCase().startsWith('<!doctype') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        print('⚠️ تحذير: تم استلام HTML بدلاً من JSON');
        throw Exception(
            'Server returned HTML instead of JSON. Check API endpoint and authentication.');
      }

      final responseJson = jsonDecode(response.body);

      // Update user profile
      await getProfile(SessionManager.userId.toString());

      return RestResponse.fromJson(responseJson);
    } catch (e) {
      print('❌ خطأ في إرسال العملات: $e');
      rethrow;
    }
  }

  Future<ExploreHashTag> getExploreHashTag(String start, String limit) async {
    final body = {
      UrlRes.start: start,
      UrlRes.limit: limit,
    };
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.getExploreHashTag,
      headers: headers,
      body: body,
      description: 'جلب هاشتاجات الاستكشاف',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getExploreHashTag),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response, description: 'نتيجة جلب هاشتاجات الاستكشاف');

    final responseJson = jsonDecode(response.body);
    return ExploreHashTag.fromJson(responseJson);
  }

  Future<SearchUser> getSearchUser(String start, String limit, String keyWord) async {
    client = http.Client();
    final body = {
      UrlRes.start: start,
      UrlRes.limit: limit,
      UrlRes.keyWord: keyWord,
    };
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.getUserSearchPostList,
      headers: headers,
      body: body,
      description: 'البحث في المستخدمين',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getUserSearchPostList),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة البحث في المستخدمين');

    final responseJson = jsonDecode(response.body);
    return SearchUser.fromJson(responseJson);
  }

  Future<UserVideo> getSearchPostList(
      String start, String limit, String? userId, String? keyWord) async {
    client = http.Client();
    final body = {
      UrlRes.start: start,
      UrlRes.limit: limit,
      UrlRes.userId: userId,
      UrlRes.keyWord: keyWord,
    };
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.getSearchPostList,
      headers: headers,
      body: body,
      description: 'البحث في المنشورات',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getSearchPostList),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة البحث في المنشورات');

    final responseJson = jsonDecode(response.body);
    return UserVideo.fromJson(responseJson);
  }

  Future<UserNotifications> getNotificationList(String start, String limit) async {
    client = http.Client();
    final body = {
      UrlRes.start: start,
      UrlRes.limit: limit,
    };
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.getNotificationList,
      headers: headers,
      body: body,
      description: 'جلب قائمة الإشعارات',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getNotificationList),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة جلب قائمة الإشعارات');

    final responseJson = jsonDecode(response.body);
    return UserNotifications.fromJson(responseJson);
  }

  Future<RestResponse> setNotificationSettings(String? deviceToken) async {
    client = http.Client();
    final body = {UrlRes.deviceToken: deviceToken};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.setNotificationSettings,
      headers: headers,
      body: body,
      description: 'تعديل إعدادات الإشعارات',
    );

    final response = await client.post(
      Uri.parse(UrlRes.setNotificationSettings),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response, description: 'نتيجة تعديل إعدادات الإشعارات');

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<MyWallet> getMyWalletCoin() async {
    client = http.Client();
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'GET',
      url: UrlRes.getMyWalletCoin,
      headers: headers,
      description: 'جلب عملات المحفظة',
    );

    final response = await client.get(
      Uri.parse(UrlRes.getMyWalletCoin),
      headers: headers,
    );

    _logGetResponse(response: response, description: 'نتيجة جلب عملات المحفظة');

    final responseJson = jsonDecode(response.body);
    return MyWallet.fromJson(responseJson);
  }

  Future<RestResponse> redeemRequest(String amount, String redeemRequestType,
      String account, String coin) async {
    client = http.Client();
    final body = {
      UrlRes.amount: amount,
      UrlRes.redeemRequestType: redeemRequestType,
      UrlRes.account: account,
      UrlRes.coin: coin,
    };
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.redeemRequest,
      headers: headers,
      body: body,
      description: 'طلب استرداد العملات',
    );

    final response = await client.post(
      Uri.parse(UrlRes.redeemRequest),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة طلب استرداد العملات');

    final responseJson = jsonDecode(response.body);
    await getProfile(SessionManager.userId.toString());
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> verifyRequest(String idNumber, String name, String address,
      File? photoIdImage, File? photoWithIdImage) async {
    var request =
        http.MultipartRequest("POST", Uri.parse(UrlRes.verifyRequest));
    request.headers[UrlRes.uniqueKey] = ConstRes.apiKey;
    request.headers[UrlRes.authorization] = SessionManager.accessToken;
    request.fields[UrlRes.idNumber] = idNumber;
    request.fields[UrlRes.name] = name;
    request.fields[UrlRes.address] = address;

    if (photoIdImage != null) {
      request.files.add(
        http.MultipartFile(
          UrlRes.photoIdImage,
          photoIdImage.readAsBytes().asStream(),
          photoIdImage.lengthSync(),
          filename: photoIdImage.path.split("/").last,
        ),
      );
    }
    if (photoWithIdImage != null) {
      request.files.add(
        http.MultipartFile(
          UrlRes.photoWithIdImage,
          photoWithIdImage.readAsBytes().asStream(),
          photoWithIdImage.lengthSync(),
          filename: photoWithIdImage.path.split("/").last,
        ),
      );
    }

    _logMultipartRequest(request: request, description: 'طلب التحقق من الهوية');

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    _logMultipartResponse(
      response: response,
      responseBody: respStr,
      description: 'نتيجة طلب التحقق من الهوية',
    );

    await getProfile(SessionManager.userId.toString());
    return RestResponse.fromJson(jsonDecode(respStr));
  }

  Future<User> getProfile(String? userId) async {
    Map<String, dynamic> body = {};
    if (SessionManager.userId != -1) {
      body[UrlRes.myUserId] = SessionManager.userId.toString();
    }
    body[UrlRes.userId] = userId;
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.getProfile,
      headers: headers,
      body: body,
      description: 'جلب الملف الشخصي',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getProfile),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة جلب الملف الشخصي');

    final responseJson = jsonDecode(response.body);
    if (userId == SessionManager.userId.toString()) {
      SessionManager sessionManager = SessionManager();
      await sessionManager.initPref();
      User user = User.fromJson(responseJson);
      if (SessionManager.accessToken.isNotEmpty) {
        user.data?.setToken(SessionManager.accessToken);
      }
      sessionManager.saveUser(jsonEncode(user));
    }
    return User.fromJson(responseJson);
  }

  Future<ProfileCategory> getProfileCategoryList() async {
    client = http.Client();
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'GET',
      url: UrlRes.getProfileCategoryList,
      headers: headers,
      description: 'جلب قائمة فئات الملف الشخصي',
    );

    final response = await client.get(
      Uri.parse(UrlRes.getProfileCategoryList),
      headers: headers,
    );

    _logGetResponse(
        response: response, description: 'نتيجة جلب قائمة فئات الملف الشخصي');

    final responseJson = jsonDecode(response.body);
    return ProfileCategory.fromJson(responseJson);
  }

  Future<User> updateProfile({
    String? fullName,
    String? userName,
    String? bio,
    String? fbUrl,
    String? instagramUrl,
    String? youtubeUrl,
    String? profileCategory,
    File? profileImage,
    String? isNotification,
  }) async {
    var request =
        http.MultipartRequest("POST", Uri.parse(UrlRes.updateProfile));
    request.headers[UrlRes.uniqueKey] = ConstRes.apiKey;
    request.headers[UrlRes.authorization] = SessionManager.accessToken;

    if (fullName != null && fullName.isNotEmpty) {
      request.fields[UrlRes.fullName] = fullName;
    }
    if (userName != null && userName.isNotEmpty) {
      request.fields[UrlRes.userName] = userName;
    }
    if (bio != null && bio.isNotEmpty) {
      request.fields[UrlRes.bio] = bio;
    }
    if (isNotification != null && isNotification.isNotEmpty) {
      request.fields[UrlRes.isNotification] = isNotification;
    }
    if (fbUrl != null && fbUrl.isNotEmpty) {
      request.fields[UrlRes.fbUrl] = fbUrl;
    }
    if (instagramUrl != null && instagramUrl.isNotEmpty) {
      request.fields[UrlRes.instaUrl] = instagramUrl;
    }
    if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
      request.fields[UrlRes.youtubeUrl] = youtubeUrl;
    }
    if (profileCategory != null && profileCategory.isNotEmpty) {
      request.fields[UrlRes.profileCategory] = profileCategory;
    }
    if (profileImage != null) {
      request.files.add(
        http.MultipartFile(
          UrlRes.userProfile,
          profileImage.readAsBytes().asStream(),
          profileImage.lengthSync(),
          filename: profileImage.path.split("/").last,
        ),
      );
    }

    _logMultipartRequest(request: request, description: 'تحديث الملف الشخصي');

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    _logMultipartResponse(
      response: response,
      responseBody: respStr,
      description: 'نتيجة تحديث الملف الشخصي',
    );

    User user = User.fromJson(jsonDecode(respStr));
    if (user.data?.userId.toString() == SessionManager.userId.toString()) {
      SessionManager sessionManager = SessionManager();
      await sessionManager.initPref();
      if (SessionManager.accessToken.isNotEmpty) {
        user.data?.setToken(SessionManager.accessToken);
      }
      sessionManager.saveUser(jsonEncode(user));
    }
    return User.fromJson(jsonDecode(respStr));
  }

  Future<RestResponse> followUnFollowUser(String toUserId) async {
    final body = {UrlRes.toUserId: toUserId};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.followUnFollowPost,
      headers: headers,
      body: body,
      description: 'متابعة/إلغاء متابعة المستخدم',
    );

    final response = await client.post(
      Uri.parse(UrlRes.followUnFollowPost),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response, description: 'نتيجة متابعة/إلغاء متابعة المستخدم');

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<FollowerFollowingData> getFollowersList(
      String userId, String start, String count, int type) async {
    final body = {
      UrlRes.userId: userId,
      UrlRes.start: start,
      UrlRes.limit: count,
    };
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    final url = type == 0 ? UrlRes.getFollowerList : UrlRes.getFollowingList;

    _logRequest(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
      description: type == 0 ? 'جلب قائمة المتابعين' : 'جلب قائمة المتابَعين',
    );

    final response = await client.post(
      Uri.parse(url),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response,
        description: type == 0
            ? 'نتيجة جلب قائمة المتابعين'
            : 'نتيجة جلب قائمة المتابَعين');

    final responseJson = jsonDecode(response.body);
    return FollowerFollowingData.fromJson(responseJson);
  }

  Future<Sound> getSoundList() async {
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'GET',
      url: UrlRes.getSoundList,
      headers: headers,
      description: 'جلب قائمة الأصوات',
    );

    final response = await client.get(
      Uri.parse(UrlRes.getSoundList),
      headers: headers,
    );

    _logGetResponse(response: response, description: 'نتيجة جلب قائمة الأصوات');

    final responseJson = jsonDecode(response.body);
    return Sound.fromJson(responseJson);
  }

  Future<FavouriteMusic> getFavouriteSoundList() async {
    SessionManager sessionManager = SessionManager();
    await sessionManager.initPref();

    final body = jsonEncode(<String, List<String>>{
      UrlRes.soundIds: sessionManager.getFavouriteMusic(),
    });
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.getFavouriteSoundList,
      headers: headers,
      body: body,
      description: 'جلب قائمة الأصوات المفضلة',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getFavouriteSoundList),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response, description: 'نتيجة جلب قائمة الأصوات المفضلة');

    final responseJson = jsonDecode(response.body);
    return FavouriteMusic.fromJson(responseJson);
  }

  Future<RestResponse> addPost({
    required String postDescription,
    required String postHashTag,
    required String isOriginalSound,
    String? soundTitle,
    String? duration,
    String? singer,
    String? soundId,
    File? postVideo,
    File? thumbnail,
    File? postSound,
    File? soundImage,
  }) async {
    var request = http.MultipartRequest("POST", Uri.parse(UrlRes.addPost));
    request.headers[UrlRes.uniqueKey] = ConstRes.apiKey;
    request.headers[UrlRes.authorization] = SessionManager.accessToken;
    request.fields[UrlRes.userId] = SessionManager.userId.toString();

    if (postDescription.isNotEmpty) {
      request.fields[UrlRes.postDescription] = postDescription;
    }
    if (postHashTag.isNotEmpty) {
      request.fields[UrlRes.postHashTag] = postHashTag;
    }
    request.fields[UrlRes.isOriginalSound] = isOriginalSound;

    if (isOriginalSound == '1') {
      request.fields[UrlRes.soundTitle] = soundTitle!;
      request.fields[UrlRes.duration] = duration!;
      request.fields[UrlRes.singer] = singer!;
      if (postSound != null) {
        request.files.add(
          http.MultipartFile(
            UrlRes.postSound,
            postSound.readAsBytes().asStream(),
            postSound.lengthSync(),
            filename: postSound.path.split("/").last,
          ),
        );
      }
      if (soundImage != null) {
        request.files.add(
          http.MultipartFile(
            UrlRes.soundImage,
            soundImage.readAsBytes().asStream(),
            soundImage.lengthSync(),
            filename: soundImage.path.split("/").last,
          ),
        );
      }
    } else {
      request.fields[UrlRes.soundId] = soundId!;
    }

    if (postVideo != null) {
      request.files.add(
        http.MultipartFile(
          UrlRes.postVideo,
          postVideo.readAsBytes().asStream(),
          postVideo.lengthSync(),
          filename: postVideo.path.split("/").last,
        ),
      );
    }
    if (thumbnail != null) {
      request.files.add(
        http.MultipartFile(
          UrlRes.postImage,
          thumbnail.readAsBytes().asStream(),
          thumbnail.lengthSync(),
          filename: thumbnail.path.split("/").last,
        ),
      );
    }

    _logMultipartRequest(request: request, description: 'إضافة منشور جديد');

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    _logMultipartResponse(
      response: response,
      responseBody: respStr,
      description: 'نتيجة إضافة المنشور',
    );

    final responseJson = jsonDecode(respStr);
    addCoin();
    return RestResponse.fromJson(responseJson);
  }

  Future<FavouriteMusic> getSearchSoundList(String keyword) async {
    client = http.Client();
    final body = {UrlRes.keyWord: keyword};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.getSearchSoundList,
      headers: headers,
      body: body,
      description: 'البحث في الأصوات',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getSearchSoundList),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة البحث في الأصوات');

    final responseJson = jsonDecode(response.body);
    return FavouriteMusic.fromJson(responseJson);
  }

  Future<UserVideo> getPostsByType({
    required int? pageDataType,
    required String start,
    required String limit,
    String? userId,
    String? soundId,
    String? hashTag,
    String? keyWord,
  }) {
    ///PagedDataType
    ///1 = UserVideo
    ///2 = UserLikesVideo
    ///3 = PostsBySound
    ///4 = PostsByHashTag
    ///5 = PostsBySearch
    switch (pageDataType) {
      case 1:
        return getUserVideos(start, limit, userId, 0);
      case 2:
        return getUserVideos(start, limit, userId, 1);
      case 3:
        return getPostBySoundId(start, limit, soundId);
      case 4:
        return getPostByHashTag(start, limit, hashTag!.replaceAll('#', ''));
      case 5:
        return getSearchPostList(start, limit, userId, keyWord);
    }
    return getPostByHashTag(start, limit, hashTag);
  }

  Future<RestResponse> logoutUser() async {
    SessionManager sessionManager = SessionManager();
    await sessionManager.initPref();
    final body = {UrlRes.userId: SessionManager.userId.toString()};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.logoutUser,
      headers: headers,
      body: body,
      description: 'تسجيل خروج المستخدم',
    );

    final response = await client.post(
      Uri.parse(UrlRes.logoutUser),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة تسجيل خروج المستخدم');

    final responseJson = jsonDecode(response.body);
    sessionManager.clean();
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> deleteAccount() async {
    SessionManager sessionManager = SessionManager();
    await sessionManager.initPref();
    await FireBaseAuth1.FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.deleteAccount,
      headers: headers,
      description: 'حذف الحساب',
    );

    final response = await client.post(
      Uri.parse(UrlRes.deleteAccount),
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة حذف الحساب');

    final responseJson = jsonDecode(response.body);
    sessionManager.clean();
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> deletePost(String postId) async {
    final body = {UrlRes.postId: postId};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.deletePost,
      headers: headers,
      body: body,
      description: 'حذف المنشور',
    );

    final response = await client.post(
      Uri.parse(UrlRes.deletePost),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة حذف المنشور');

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> reportUserOrPost({
    required String reportType,
    String? postIdOrUserId,
    String? reason,
    required String description,
    required String contactInfo,
  }) async {
    final body = {
      UrlRes.reportType: reportType,
      reportType == '1' ? UrlRes.userId : UrlRes.postId: postIdOrUserId,
      UrlRes.reason: reason,
      UrlRes.description: description,
      UrlRes.contactInfo: contactInfo,
    };
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.reportPostOrUser,
      headers: headers,
      body: body,
      description: 'الإبلاغ عن مستخدم أو منشور',
    );

    final response = await client.post(
      Uri.parse(UrlRes.reportPostOrUser),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response, description: 'نتيجة الإبلاغ عن مستخدم أو منشور');

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> blockUser(String? userId) async {
    final body = {UrlRes.userId: userId};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.blockUser,
      headers: headers,
      body: body,
      description: 'حظر المستخدم',
    );

    final response = await client.post(
      Uri.parse(UrlRes.blockUser),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة حظر المستخدم');

    return RestResponse.fromJson(jsonDecode(response.body));
  }

  Future<SinglePost> getPostByPostId(String postId) async {
    final body = {UrlRes.postId: postId};
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.getPostListById,
      headers: headers,
      body: body,
      description: 'جلب المنشور بالمعرف',
    );

    final response = await client.post(
      Uri.parse(UrlRes.getPostListById),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة جلب المنشور بالمعرف');

    return SinglePost.fromJson(jsonDecode(response.body));
  }

  Future<CoinPlans> getCoinPlanList() async {
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'GET',
      url: UrlRes.getCoinPlanList,
      headers: headers,
      description: 'جلب خطط العملات',
    );

    final response = await client.get(
      Uri.parse(UrlRes.getCoinPlanList),
      headers: headers,
    );

    _logGetResponse(response: response, description: 'نتيجة جلب خطط العملات');

    final responseJson = jsonDecode(response.body);
    return CoinPlans.fromJson(responseJson);
  }

  Future<CoinPlans> addCoin() async {
    final body = {UrlRes.rewardingActionId: '3'};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.addCoin,
      headers: headers,
      body: body,
      description: 'إضافة عملات مكافأة',
    );

    final response = await client.post(
      Uri.parse(UrlRes.addCoin),
      headers: headers,
      body: body,
    );

    _logResponse(response: response, description: 'نتيجة إضافة عملات مكافأة');

    final responseJson = jsonDecode(response.body);
    await getProfile(SessionManager.userId.toString());
    return CoinPlans.fromJson(responseJson);
  }

  Future<RestResponse> purchaseCoin(int coin) async {
    final body = {UrlRes.coin: '$coin'};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.purchaseCoin,
      headers: headers,
      body: body,
      description: 'شراء العملات',
    );

    final response = await client.post(
      Uri.parse(UrlRes.purchaseCoin),
      body: body,
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة شراء العملات');

    final responseJson = jsonDecode(response.body);
    await getProfile(SessionManager.userId.toString());
    return RestResponse.fromJson(responseJson);
  }

  Future<RestResponse> increasePostViewCount(String postId) async {
    final body = {UrlRes.postId: postId};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.increasePostViewCount,
      headers: headers,
      body: body,
      description: 'زيادة عدد مشاهدات المنشور',
    );

    final response = await client.post(
      Uri.parse(UrlRes.increasePostViewCount),
      body: body,
      headers: headers,
    );

    _logResponse(
        response: response, description: 'نتيجة زيادة عدد مشاهدات المنشور');

    final responseJson = jsonDecode(response.body);
    return RestResponse.fromJson(responseJson);
  }

  static HttpClient getHttpClient() {
    HttpClient httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

    return httpClient;
  }

  Future<FilePath> filePath({File? filePath}) async {
    var request =
        http.MultipartRequest('POST', Uri.parse(UrlRes.fileGivenPath));
    request.headers.addAll({
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    });

    if (filePath != null) {
      request.files.add(
        http.MultipartFile(
          'file',
          filePath.readAsBytes().asStream(),
          filePath.lengthSync(),
          filename: filePath.path.split("/").last,
        ),
      );
    }

    _logMultipartRequest(
        request: request, description: 'رفع ملف للحصول على المسار');

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    _logMultipartResponse(
      response: response,
      responseBody: respStr,
      description: 'نتيجة رفع الملف للحصول على المسار',
    );

    final responseJson = jsonDecode(respStr);
    FilePath path = FilePath.fromJson(responseJson);
    return path;
  }

  Future pushNotification({
    required String title,
    required String body,
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final requestBody = json.encode({
      'message': {
        'notification': {
          'title': title,
          'body': body,
        },
        'token': token,
        'data': data,
      }
    });
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
      'content-type': 'application/json',
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.notificationUrl,
      headers: headers,
      body: requestBody,
      description: 'إرسال إشعار فوري',
    );

    await http
        .post(
      Uri.parse(UrlRes.notificationUrl),
      headers: headers,
      body: requestBody,
    )
        .then((response) {
      _logResponse(
          response: response, description: 'نتيجة إرسال الإشعار الفوري');
    });
  }

  Future<Setting> fetchSettingsData() async {
    final headers = {UrlRes.uniqueKey: ConstRes.apiKey};

    _logRequest(
      method: 'POST',
      url: UrlRes.fetchSettingsData,
      headers: headers,
      description: 'جلب إعدادات التطبيق',
    );

    final response = await client.post(
      Uri.parse(UrlRes.fetchSettingsData),
      headers: headers,
    );

    _logResponse(response: response, description: 'نتيجة جلب إعدادات التطبيق');

    SessionManager sessionManager = SessionManager();
    await sessionManager.initPref();
    sessionManager.saveSetting(response.body);
    return Setting.fromJson(jsonDecode(response.body));
  }

  Future<AgoraToken> generateAgoraToken(String? channelName) async {
    final body = {UrlRes.channelName: channelName};
    final headers = {
      UrlRes.authorization: SessionManager.accessToken,
      UrlRes.uniqueKey: ConstRes.apiKey,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.generateAgoraToken,
      headers: headers,
      body: body,
      description: 'توليد رمز Agora',
    );

    final response = await client.post(
      Uri.parse(UrlRes.generateAgoraToken),
      headers: headers,
      body: body,
    );

    _logResponse(response: response, description: 'نتيجة توليد رمز Agora');

    return AgoraToken.fromJson(jsonDecode(response.body));
  }

  Future<Agora> agoraListStreamingCheck(
      String channelName, String authToken, String agoraAppId) async {
    try {
      // التحقق من صحة البيانات قبل إرسال الطلب
      ConstRes.validateCredentials();

      final url = '${UrlRes.agoraLiveStreamingCheck}$agoraAppId/$channelName';
      final headers = {
        UrlRes.authorization: 'Basic $authToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      _logRequest(
        method: 'GET',
        url: url,
        headers: headers,
        description: 'فحص حالة البث المباشر Agora',
      );

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      _logGetResponse(
          response: response, description: 'نتيجة فحص حالة البث المباشر Agora');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          log('Empty response body - assuming stream is inactive');
          return Agora(
            success: false,
            message: null,
            data: AgoraData(
              channelExist: false,
              mode: 0,
              broadcasters: [],
              audience: [],
              audienceTotal: 0,
            ),
          );
        }

        try {
          final decodedResponse = jsonDecode(response.body);
          return Agora.fromJson(decodedResponse);
        } catch (e) {
          log('Error parsing JSON: $e');
          return Agora(
            success: false,
            message: 'خطأ في تحليل البيانات المستلمة',
            data: null,
          );
        }
      } else if (response.statusCode == 404) {
        log('Channel not found - stream is not active');
        return Agora(
          success: false,
          message: null,
          data: AgoraData(
            channelExist: false,
            mode: 0,
            broadcasters: [],
            audience: [],
            audienceTotal: 0,
          ),
        );
      } else if (response.statusCode == 401) {
        log('Unauthorized - Invalid credentials');
        log('Please check your Agora App ID and App Certificate');

        return Agora(
          success: true,
          message: null,
          data: AgoraData(
            channelExist: true,
            mode: 1,
            broadcasters: [1],
            audience: [],
            audienceTotal: 0,
          ),
        );
      } else {
        log('HTTP Error: ${response.statusCode}');
        return Agora(
          success: true,
          message: null,
          data: AgoraData(
            channelExist: true,
            mode: 1,
            broadcasters: [1],
            audience: [],
            audienceTotal: 0,
          ),
        );
      }
    } on TimeoutException {
      log('Request timeout - allowing entry');
      return Agora(
        success: true,
        message: null,
        data: AgoraData(
          channelExist: true,
          mode: 1,
          broadcasters: [1],
          audience: [],
          audienceTotal: 0,
        ),
      );
    } on SocketException {
      log('No internet connection - allowing entry');
      return Agora(
        success: true,
        message: null,
        data: AgoraData(
          channelExist: true,
          mode: 1,
          broadcasters: [1],
          audience: [],
          audienceTotal: 0,
        ),
      );
    } catch (e) {
      log('Unexpected error in agoraListStreamingCheck: $e');
      return Agora(
        success: true,
        message: null,
        data: AgoraData(
          channelExist: true,
          mode: 1,
          broadcasters: [1],
          audience: [],
          audienceTotal: 0,
        ),
      );
    }
  }

  Future<Status> checkUsername({required String userName}) async {
    final body = {UrlRes.userName: userName};
    final headers = {
      UrlRes.authorization: SessionManager.accessToken,
      UrlRes.uniqueKey: ConstRes.apiKey,
    };

    _logRequest(
      method: 'POST',
      url: UrlRes.checkUsername,
      headers: headers,
      body: body,
      description: 'فحص توفر اسم المستخدم',
    );

    http.Response response = await http.post(
      Uri.parse(UrlRes.checkUsername),
      headers: headers,
      body: body,
    );

    _logResponse(
        response: response, description: 'نتيجة فحص توفر اسم المستخدم');

    return Status.fromJson(jsonDecode(response.body));
  }

  Future<NudityMediaId> checkVideoModerationApiMoreThenOneMinutes({
    required File? file,
    required String apiUser,
    required String apiSecret,
  }) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse(UrlRes.checkVideoModerationMoreThenOneMinutes));
    request.fields['models'] = nudityModels;
    request.fields['api_user'] = apiUser;
    request.fields['api_secret'] = apiSecret;

    if (file != null) {
      request.files.add(
        http.MultipartFile(
          'media',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: file.path.split("/").last,
        ),
      );
    }

    _logMultipartRequest(
        request: request, description: 'فحص محتوى الفيديو للمحتوى غير المناسب');

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    _logMultipartResponse(
      response: response,
      responseBody: respStr,
      description: 'نتيجة فحص محتوى الفيديو للمحتوى غير المناسب',
    );

    NudityMediaId nudityStatus = NudityMediaId.fromJson(jsonDecode(respStr));
    return nudityStatus;
  }

  Future<NudityChecker> getOnGoingVideoJob({
    required String mediaId,
    required String apiUser,
    required String apiSecret,
  }) async {
    final url =
        'https://api.sightengine.com/1.0/video/byid.json?id=${mediaId}&api_user=${apiUser}&api_secret=${apiSecret}';

    _logRequest(
      method: 'GET',
      url: url,
      description: 'الحصول على نتيجة فحص المحتوى الجاري',
    );

    http.Response response = await http.get(Uri.parse(url));

    _logGetResponse(
        response: response, description: 'نتيجة الحصول على فحص المحتوى الجاري');

    NudityChecker nudityChecker = NudityChecker.fromJson(jsonDecode(response.body));
    return nudityChecker;
  }
}