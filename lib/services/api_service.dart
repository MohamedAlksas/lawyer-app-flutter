import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  Dio get dio => _dio;

  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.requestTimeout,
      receiveTimeout: AppConstants.requestTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final success = await _refreshToken();
          if (success) {
            final token = await _storage.read(key: _accessTokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              handler.next(error);
              return;
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<void> setTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<bool> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: _refreshTokenKey);
      if (refresh == null) return false;
      final res = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh',
        data: {'refreshToken': refresh},
      );
      if (res.statusCode == 200) {
        final data = res.data;
        await setTokens(data['accessToken'], data['refreshToken']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasToken() async {
    final t = await _storage.read(key: _accessTokenKey);
    return t != null;
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);

  Future<Response> delete(String path, {dynamic data}) => _dio.delete(path, data: data);

  Future<Response> uploadFile(
    String path,
    File file, {
    required String caseId,
    required String docCategory,
    required String name,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      'caseId': caseId,
      'docCategory': docCategory,
      'name': name,
    });
    return _dio.post(path, data: form);
  }
}
