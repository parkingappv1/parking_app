import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parking_app/core/interceptors/app_token_service.dart';
import 'package:parking_app/core/routes/app_routes.dart';
import 'package:parking_app/main.dart';
import 'package:parking_app/views/auth/signin_screen.dart';
import 'package:parking_app/views/auth/signup_screen.dart';
import 'package:parking_app/views/auth/verification_code_screen.dart';
import 'package:parking_app/views/error/error_screen.dart';
import 'package:parking_app/views/owner/owner_dashboard_screen.dart';
import 'package:parking_app/views/parking/parking_search_screen.dart';

/// アプリケーションのルーティングを管理するクラス
/// ナビゲーション、認証チェック、エラーハンドリングを統合的に処理
class AppRouter {
  // プライベートコンストラクタ - インスタンス化を防止
  AppRouter._();

  /// トークンサービスのインスタンス - 認証状態管理用
  static final TokenService _tokenService = TokenService();

  /// ルート設定に基づいてルートを生成
  /// 認証が必要なページには自動的に認証チェックを適用
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 引数があれば抽出
    final args = settings.arguments;
    final routeName = settings.name ?? '';

    if (kDebugMode) {
      debugPrint('🧭 ルート生成開始: $routeName');
      if (args != null) {
        debugPrint('📋 ルート引数: $args');
      }
    }

    try {
      switch (routeName) {
        // ===== 認証フロー =====

        case AppRoutes.SPLASH:
          if (kDebugMode) debugPrint('🚀 スプラッシュ画面へナビゲート');
          return _createRoute(const SplashScreen(), settings);

        case AppRoutes.SIGNIN:
          if (kDebugMode) debugPrint('🔑 サインイン画面へナビゲート');
          return _createRoute(const SignInScreen(), settings);

        case AppRoutes.SIGNUP:
          if (kDebugMode) debugPrint('📝 サインアップ画面へナビゲート');
          return _createRoute(const SignUpScreen(), settings);

        case AppRoutes.VERIFY_CODE:
          if (kDebugMode) debugPrint('✅ 認証コード確認画面へナビゲート');
          if (args is String && args.isNotEmpty) {
            return _createRoute(VerificationCodeScreen(email: args), settings);
          }
          if (kDebugMode) debugPrint('❌ メールアドレスが必要です');
          return _errorRoute('メール認証には有効なメールアドレスが必要です');

        // case AppRoutes.PASSWORD_RESET:
        //   if (kDebugMode) debugPrint('🔄 パスワードリセット画面へナビゲート');
        //   return _createRoute(const PasswordResetScreen(), settings);

        // ===== 保護されたメイン画面 =====

        case AppRoutes
            .PARKING_SEARCH: // Assuming AppRoutes.PARKING_SEARCH = '/parking-search';
          if (kDebugMode) debugPrint('🅿️ 駐車場検索画面へナビゲート（認証保護）');
          return _protectedRoute(
            const ParkingSearchScreen(),
            settings: settings,
          );

        // case AppRoutes.HOME:
        //   if (kDebugMode) debugPrint('🏠 ホーム画面へナビゲート（認証保護）');
        //   return _protectedRoute(const HomeScreen(), settings: settings);
        case AppRoutes.OWNER_DASHBOARD:
          if (kDebugMode) debugPrint('🏠 駐車場ホーム画面へナビゲート');
          if (args is Map<String, dynamic>) {
            final ownerId = args['ownerId'];
            final isOwner = args['isOwner'];

            return _protectedRoute(
              OwnerDashboardScreen(
                ownerId: ownerId,
                isOwner: isOwner,
              ),
              settings: settings,
            );
          } else {
            return _errorRoute('ルート引数が正しくありません');
          }
        case AppRoutes.ADD_PARKING_SPACE:
          if (kDebugMode) debugPrint('🏠 新しい駐車場の登録画面へナビゲート');
          if (args is Map<String, dynamic>) {
            final ownerId = args['ownerId'];
            final isOwner = args['isOwner'];

            return _protectedRoute(
              OwnerDashboardScreen(
                ownerId: ownerId,
                isOwner: isOwner,
              ),
              settings: settings,
            );
          } else {
            return _errorRoute('ルート引数が正しくありません');
          }


        // ===== エラーハンドリング画面 =====

        // case AppRoutes.NETWORK_ERROR:
        //   if (kDebugMode) debugPrint('🌐 ネットワークエラー画面へナビゲート');
        //   return _createRoute(const NetworkErrorScreen(), settings);

        // case AppRoutes.UNAUTHORIZED:
        //   if (kDebugMode) debugPrint('🚫 認証エラー画面へナビゲート');
        //   return _createRoute(const UnauthorizedScreen(), settings);

        default:
          // 未定義ルートの処理
          if (kDebugMode) debugPrint('⚠️ 未定義ルート: $routeName');
          return _errorRoute('ルート「$routeName」は定義されていません');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 ルート生成エラー: $routeName - $e');
      }
      return _errorRoute('ルート生成中にエラーが発生しました: $e');
    }
  }

  /// 基本的なルートを作成
  /// アニメーションとトランジション設定を含む
  static Route<dynamic> _createRoute(
    Widget destination,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // スライドアニメーションを適用
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// 認証が必要なルートを作成
  /// 認証チェック後、適切な画面にリダイレクト
  // ignore: unused_element
  static Route<dynamic> _protectedRoute(
    Widget destination, {
    RouteSettings? settings,
  }) {
    if (kDebugMode) {
      debugPrint('🔒 保護されたルートの認証チェック開始');
    }

    return MaterialPageRoute(
      settings: settings,
      builder:
          (context) => FutureBuilder<bool>(
            future: _isAuthenticated(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                if (kDebugMode) debugPrint('⏳ 認証状態確認中...');
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('認証状態を確認中...'),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                if (kDebugMode) {
                  debugPrint('❌ 認証チェックエラー: ${snapshot.error}');
                }
                // エラーが発生した場合はサインインページにリダイレクト
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.SIGNIN, (route) => false);
                });
                return const Scaffold(
                  body: Center(child: Text('認証エラーが発生しました')),
                );
              }

              final isAuthenticated = snapshot.data ?? false;

              if (isAuthenticated) {
                if (kDebugMode) debugPrint('✅ 認証済み - 目的地に遷移');
                return destination;
              } else {
                if (kDebugMode) debugPrint('🚫 未認証 - サインイン画面にリダイレクト');
                // 未認証の場合はサインインページにリダイレクト
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.SIGNIN, (route) => false);
                });

                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('認証が必要です。サインイン画面に移動します...'),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
    );
  }

  /// ユーザーの認証状態をチェック
  /// アクセストークンの存在と有効性を確認
  static Future<bool> _isAuthenticated() async {
    try {
      final token = await _tokenService.getAccessToken();
      final isValid = token != null && token.isNotEmpty;

      if (kDebugMode) {
        debugPrint('🔍 認証チェック結果: ${isValid ? '認証済み' : '未認証'}');
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ 認証チェック中にエラー: $e');
      }
      return false;
    }
  }

  /// エラールートを作成
  /// エラーメッセージを表示する画面を生成
  static Route<dynamic> _errorRoute(String message) {
    if (kDebugMode) {
      debugPrint('🚨 エラールート作成: $message');
    }

    return MaterialPageRoute(builder: (_) => ErrorScreen(message: message));
  }

  /// APIエラーを処理して適切な画面にリダイレクト
  /// エラーコードに基づいて最適なエラー画面を表示
  static void handleApiError(
    BuildContext context,
    int? statusCode,
    String? message,
  ) {
    if (kDebugMode) {
      debugPrint('🚨 APIエラーハンドリング開始');
      debugPrint('📊 ステータスコード: $statusCode');
      debugPrint('📝 エラーメッセージ: $message');
    }

    // ナビゲーターが利用可能かチェック
    if (!Navigator.canPop(context) && !context.mounted) {
      if (kDebugMode) debugPrint('⚠️ ナビゲーターが利用できません');
      return;
    }

    try {
      switch (statusCode) {
        case 401:
          // 認証エラー - サインインページにリダイレクト
          if (kDebugMode) debugPrint('🔑 401エラー - サインインページにリダイレクト');
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.SIGNIN, (route) => false);
          break;

        case 403:
          // 権限不足 - 認証エラー画面に遷移
          if (kDebugMode) debugPrint('🚫 403エラー - 権限不足画面に遷移');
          Navigator.of(context).pushNamed(AppRoutes.UNAUTHORIZED);
          break;

        case null:
          // ネットワークエラー
          if (kDebugMode) debugPrint('🌐 ネットワークエラー画面に遷移');
          Navigator.of(context).pushNamed(AppRoutes.NETWORK_ERROR);
          break;

        case 500:
        case 502:
        case 503:
          // サーバーエラー
          if (kDebugMode) debugPrint('🔧 サーバーエラー - エラー画面に遷移');
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.ERROR, arguments: message ?? 'サーバーエラーが発生しました');
          break;

        default:
          // その他のエラー
          if (kDebugMode) debugPrint('❓ その他のエラー - 汎用エラー画面に遷移');
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.ERROR, arguments: message ?? 'エラーが発生しました');
      }
    } catch (navigationError) {
      if (kDebugMode) {
        debugPrint('💥 ナビゲーションエラー: $navigationError');
      }
      // ナビゲーションに失敗した場合はスナックバーでエラーを表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'エラーが発生しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 認証が必要かどうかをチェック
  static bool requiresAuthentication(String route) {
    return AppRoutes.requiresAuthentication(route);
  }

  /// デバッグ用：現在のルート情報を出力
  static void debugCurrentRoute(BuildContext context) {
    if (kDebugMode) {
      final currentRoute = ModalRoute.of(context);
      if (currentRoute != null) {
        debugPrint('📍 現在のルート: ${currentRoute.settings.name}');
        debugPrint('📋 ルート引数: ${currentRoute.settings.arguments}');
      } else {
        debugPrint('❓ 現在のルートが取得できません');
      }
    }
  }
}
