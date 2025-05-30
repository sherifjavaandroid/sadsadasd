import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bubbly/modal/user_video/user_video.dart';
import 'package:bubbly/modal/rest/rest_response.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/session_manager.dart';
import 'package:bubbly/utils/url_res.dart';
import 'package:http/http.dart' as http;

class OptimizedApiService {
  static final OptimizedApiService _instance = OptimizedApiService._internal();

  factory OptimizedApiService() => _instance;

  OptimizedApiService._internal();

  var client = http.Client();

  // نظام Throttling للطلبات
  final Map<String, Timer> _throttleTimers = {};
  final Map<String, DateTime> _lastRequestTimes = {};
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  // فترات الانتظار للطلبات المختلفة
  static const Duration _defaultThrottleDuration = Duration(milliseconds: 500);
  static const Duration _postListThrottleDuration =
      Duration(milliseconds: 1000);
  static const Duration _viewCountThrottleDuration =
      Duration(milliseconds: 2000);

  // كاش للطلبات المتكررة
  final Map<String, dynamic> _requestCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 2);

  // تحسين الشبكة
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _requestTimeout = Duration(seconds: 15);

  // طريقة محسنة لجلب قائمة المنشورات مع throttling
  Future<UserVideo> getPostListOptimized({
    required String limit,
    required String userId,
    required String type,
    bool useCache = true,
  }) async {
    final cacheKey = 'post_list_${type}_${userId}_$limit';

    // التحقق من الكاش أولاً
    if (useCache && _isCacheValid(cacheKey)) {
      log('📱 استخدام الكاش للمنشورات: $cacheKey');
      return UserVideo.fromJson(_requestCache[cacheKey]);
    }

    // تطبيق throttling
    return _throttledRequest(
      key: 'getPostList_$type',
      duration: _postListThrottleDuration,
      request: () => _executeGetPostList(limit, userId, type, cacheKey),
    );
  }

  Future<UserVideo> _executeGetPostList(
      String limit, String userId, String type, String cacheKey) async {
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
      description: 'جلب قائمة المنشورات (محسن)',
    );

    final response = await client
        .post(
          Uri.parse(UrlRes.getPostList),
          body: body,
          headers: headers,
        )
        .timeout(_requestTimeout);

    _logResponse(
        response: response, description: 'نتيجة جلب قائمة المنشورات (محسن)');

    final responseJson = jsonDecode(response.body);

    // حفظ في الكاش
    _cacheResponse(cacheKey, responseJson);

    return UserVideo.fromJson(responseJson);
  }

  // طريقة محسنة لزيادة عدد المشاهدات مع throttling قوي
  Future<void> increasePostViewCountOptimized(String postId) async {
    final throttleKey = 'viewCount_$postId';

    // منع الطلبات المتكررة لنفس الفيديو
    if (_lastRequestTimes.containsKey(throttleKey)) {
      final timeSinceLastRequest =
          DateTime.now().difference(_lastRequestTimes[throttleKey]!);
      if (timeSinceLastRequest < _viewCountThrottleDuration) {
        log('⏱️ تجاهل طلب مشاهدة متكرر للفيديو: $postId');
        return;
      }
    }

    _lastRequestTimes[throttleKey] = DateTime.now();

    // تنفيذ الطلب بدون انتظار للاستجابة (fire and forget)
    _executeViewCountIncrease(postId).catchError((error) {
      log('❌ خطأ في زيادة عدد المشاهدات: $error');
    });
  }

  Future<RestResponse> _executeViewCountIncrease(String postId) async {
    final body = {UrlRes.postId: postId};
    final headers = {
      UrlRes.uniqueKey: ConstRes.apiKey,
      UrlRes.authorization: SessionManager.accessToken,
    };

    final response = await client
        .post(
          Uri.parse(UrlRes.increasePostViewCount),
          body: body,
          headers: headers,
        )
        .timeout(_requestTimeout);

    return RestResponse.fromJson(jsonDecode(response.body));
  }

  // طريقة محسنة للإعجاب/إلغاء الإعجاب
  Future<RestResponse> likeUnlikePostOptimized(String postId) async {
    return _throttledRequest(
      key: 'likeUnlike_$postId',
      duration: _defaultThrottleDuration,
      request: () => _executeLikeUnlike(postId),
    );
  }

  Future<RestResponse> _executeLikeUnlike(String postId) async {
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
      description: 'إعجاب/إلغاء إعجاب المنشور (محسن)',
    );

    final response = await client
        .post(
          Uri.parse(UrlRes.likeUnlikePost),
          body: body,
          headers: headers,
        )
        .timeout(_requestTimeout);

    _logResponse(
        response: response, description: 'نتيجة الإعجاب/إلغاء الإعجاب (محسن)');

    return RestResponse.fromJson(jsonDecode(response.body));
  }

  // طريقة محسنة لإضافة التعليقات
  Future<RestResponse> addCommentOptimized(
      String comment, String postId) async {
    return _throttledRequest(
      key: 'addComment_$postId',
      duration: _defaultThrottleDuration,
      request: () => _executeAddComment(comment, postId),
    );
  }

  Future<RestResponse> _executeAddComment(String comment, String postId) async {
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
      description: 'إضافة تعليق جديد (محسن)',
    );

    final response = await client
        .post(
          Uri.parse(UrlRes.addComment),
          body: body,
          headers: headers,
        )
        .timeout(_requestTimeout);

    _logResponse(response: response, description: 'نتيجة إضافة التعليق (محسن)');

    return RestResponse.fromJson(jsonDecode(response.body));
  }

  // نظام Throttling العام
  Future<T> _throttledRequest<T>({
    required String key,
    required Duration duration,
    required Future<T> Function() request,
  }) async {
    // إلغاء المؤقت السابق إذا وجد
    _throttleTimers[key]?.cancel();

    // التحقق من وجود طلب معلق
    if (_pendingRequests.containsKey(key)) {
      log('⏱️ انتظار الطلب المعلق: $key');
      return await _pendingRequests[key]!.future;
    }

    // إنشاء completer جديد
    final completer = Completer<T>();
    _pendingRequests[key] = completer;

    // تنفيذ الطلب بعد فترة throttling
    _throttleTimers[key] = Timer(duration, () async {
      try {
        final result = await request();
        completer.complete(result);
      } catch (error) {
        completer.completeError(error);
      } finally {
        _pendingRequests.remove(key);
        _throttleTimers.remove(key);
      }
    });

    return completer.future;
  }

  // إدارة الكاش
  void _cacheResponse(String key, dynamic data) {
    _requestCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // تنظيف الكاش القديم
    _cleanupExpiredCache();
  }

  bool _isCacheValid(String key) {
    if (!_requestCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final age = DateTime.now().difference(_cacheTimestamps[key]!);
    return age < _cacheExpiry;
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _requestCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // مسح جميع البيانات المؤقتة
  void clearCache() {
    _requestCache.clear();
    _cacheTimestamps.clear();

    // إلغاء جميع المؤقتات
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }
    _throttleTimers.clear();

    // إكمال جميع الطلبات المعلقة بخطأ
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('Cache cleared');
      }
    }
    _pendingRequests.clear();

    _lastRequestTimes.clear();

    log('🧹 تم مسح جميع بيانات API المؤقتة');
  }

  // دوال مساعدة للتسجيل (مبسطة)
  void _logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
    String? description,
  }) {
    log('🚀 API Request: $method $url - ${description ?? ""}');
  }

  void _logResponse({
    required http.Response response,
    String? description,
  }) {
    log('📥 API Response: ${response.statusCode} - ${description ?? ""}');
  }

  // إحصائيات الأداء
  Map<String, dynamic> getPerformanceStats() {
    return {
      'cacheSize': _requestCache.length,
      'activeTimers': _throttleTimers.length,
      'pendingRequests': _pendingRequests.length,
      'lastRequestTimes': _lastRequestTimes.length,
    };
  }

  // تنظيف الموارد عند إغلاق التطبيق
  void dispose() {
    clearCache();
    client.close();
  }
}
