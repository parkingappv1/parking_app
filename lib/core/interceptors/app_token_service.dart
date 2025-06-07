import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parking_app/core/api/api_constants.dart';

/// 全局的令牌管理服务，提供应用中所有组件访问和刷新认证令牌的能力
class TokenService {
  // 单例实现
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;

  // 安全存储
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 键名常量
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  // 避免多次同时刷新令牌
  bool _isRefreshing = false;

  // 用于刷新令牌的Dio实例（避免循环依赖）
  final Dio _tokenDio = Dio();

  TokenService._internal() {
    // 配置用于刷新令牌的Dio实例
    _tokenDio.options.baseUrl = ApiConstants.BASE_URL;
  }

  /// 获取当前有效的访问令牌
  ///
  /// 如果令牌过期且可以自动刷新，会尝试刷新令牌
  /// 返回有效的访问令牌或null（如果无法获取有效令牌）
  Future<String?> getAccessToken({bool autoRefresh = true}) async {
    try {
      final token = await _secureStorage.read(key: _accessTokenKey);

      // 检查令牌是否存在
      if (token == null || token.isEmpty) {
        return null;
      }

      // 检查令牌是否过期
      if (autoRefresh && await _isTokenExpired()) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return await _secureStorage.read(key: _accessTokenKey);
        }
        return null;
      }

      return token;
    } catch (e) {
      debugPrint('获取访问令牌时出错: $e');
      return null;
    }
  }

  /// 刷新访问令牌
  ///
  /// 使用刷新令牌（refresh token）获取新的访问令牌
  /// 返回刷新是否成功
  Future<bool> refreshToken() async {
    // 防止多次同时刷新
    if (_isRefreshing) {
      // 等待其他刷新过程完成
      await Future.delayed(const Duration(milliseconds: 500));
      return await _isTokenValid();
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // 调用实际的刷新令牌API
      final response = await _tokenDio.post(
        ApiConstants.REFRESH_TOKEN,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        // 从响应中提取令牌信息
        final responseData = response.data;

        // 存储新的访问令牌和刷新令牌
        if (responseData['access_token'] != null) {
          await _secureStorage.write(
            key: _accessTokenKey,
            value: responseData['access_token'],
          );
        }

        if (responseData['refresh_token'] != null) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: responseData['refresh_token'],
          );
        }

        // 设置令牌过期时间
        final expiresIn = responseData['expires_in'] ?? 3600; // 默认1小时
        final expiryTime =
            DateTime.now()
                .add(Duration(seconds: expiresIn))
                .millisecondsSinceEpoch;
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: expiryTime.toString(),
        );

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('刷新令牌时出错: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 保存新的访问令牌和刷新令牌
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 3600,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

    // 设置令牌过期时间
    final expiryTime =
        DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
    await _secureStorage.write(
      key: _tokenExpiryKey,
      value: expiryTime.toString(),
    );
  }

  /// 清除所有令牌（如登出时）
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _tokenExpiryKey);
    await clearUserInfo();
  }

  /// 检查令牌是否已过期
  Future<bool> _isTokenExpired() async {
    try {
      final expiryTimeString = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryTimeString == null || expiryTimeString.isEmpty) {
        return true;
      }

      final expiryTime = int.parse(expiryTimeString);
      final now = DateTime.now().millisecondsSinceEpoch;

      // 给过期时间预留30秒缓冲区，避免边缘情况
      return now > (expiryTime - 30000);
    } catch (e) {
      return true;
    }
  }

  /// 检查是否有有效的令牌
  Future<bool> _isTokenValid() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    final isExpired = await _isTokenExpired();

    return token != null && token.isNotEmpty && !isExpired;
  }

  /// 公开方法：检查是否有有效的访问令牌
  Future<bool> hasValidToken() async {
    return await _isTokenValid();
  }

  /// 保存访问令牌（简化版本）
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  /// 保存刷新令牌（简化版本）
  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// 用户信息存储键名
  static const String _userInfoKey = 'user_info';

  /// 保存用户信息
  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final userInfoJson = jsonEncode(userInfo);
      await _secureStorage.write(key: _userInfoKey, value: userInfoJson);
    } catch (e) {
      debugPrint('保存用户信息时出错: $e');
    }
  }

  /// 获取用户信息
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final userInfoJson = await _secureStorage.read(key: _userInfoKey);
      if (userInfoJson == null || userInfoJson.isEmpty) {
        return null;
      }
      return jsonDecode(userInfoJson);
    } catch (e) {
      debugPrint('获取用户信息时出错: $e');
      return null;
    }
  }

  /// 清除用户信息
  Future<void> clearUserInfo() async {
    await _secureStorage.delete(key: _userInfoKey);
  }
}
