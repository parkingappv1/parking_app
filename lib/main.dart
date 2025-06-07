/// パーキングアプリ - メインアプリケーションファイル
///
/// このファイルはFlutterアプリケーションのエントリーポイントとして機能し、
/// 以下の主要機能を提供します：
///
/// - アプリケーションの初期化と設定
/// - 環境変数の読み込み (.env ファイル)
/// - グローバルテーマとローカライゼーションの設定
/// - ルーティングシステムの構築
/// - エラーハンドリングとフォールバック処理
///
/// 作成者: Parking App Development Team
/// 最終更新: 2025-05-28
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/views/auth/signin_screen.dart';
import 'package:parking_app/views/dummy_screen.dart';
import 'theme/app_theme.dart';
import 'package:parking_app/core/routes/app_routes.dart'; // Added import
import 'package:parking_app/views/parking/parking_search_screen.dart'; // Added import

/// パーキングアプリのメインエントリーポイント
///
/// アプリの初期化処理、環境変数の読み込み、
/// Flutter bindings の初期化を行う
Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Load the .env file with error handling
    await dotenv.load(fileName: ".env");

    // Run the app
    runApp(const MyApp());
  } catch (e) {
    // Handle initialization errors gracefully
    debugPrint('アプリ初期化エラー: $e');
    runApp(const MyApp()); // Run app anyway with default settings
  }
}

/// メインアプリケーションウィジェット
///
/// アプリのテーマ、国際化、ルーティングを設定し、
/// 全体的なアプリケーション構造を定義する
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // =================================================================
      // APP CONFIGURATION
      // =================================================================
      title: 'パーキングアプリ',
      debugShowCheckedModeBanner: false, // Remove debug banner in release
      // =================================================================
      // THEME CONFIGURATION
      // =================================================================
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system, // Follow system theme preference
      // =================================================================
      // LOCALIZATION CONFIGURATION
      // =================================================================
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'), // Japanese (default)
        Locale('en'), // English
        Locale('zh'), // Chinese
      ],
      locale: const Locale('ja'), // Set Japanese as default locale
      // =================================================================
      // TITLE GENERATION
      // =================================================================
      onGenerateTitle: (context) {
        return AppLocalizations.of(context).appTitle;
      },

      // =================================================================
      // ROUTING CONFIGURATION
      // =================================================================
      initialRoute: AppRoutes.SPLASH,
      routes: _buildAppRoutes(),

      // =================================================================
      // ERROR HANDLING & NAVIGATION
      // =================================================================
      builder: (context, child) {
        // Global error boundary and responsive adjustments
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(
              context,
            ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.3),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Handle unknown routes gracefully
      onUnknownRoute: (settings) {
        debugPrint('Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder:
              (context) => const _PlaceholderScreen(
                title: 'ページが見つかりません',
                message: '指定されたページは存在しません',
                icon: Icons.error_outline,
              ),
        );
      },
    );
  }

  /// アプリケーションのルート定義
  ///
  /// 各画面への遷移パスとウィジェットのマッピングを定義
  static Map<String, WidgetBuilder> _buildAppRoutes() {
    return {
      // =================================================================
      // CORE ROUTES
      // =================================================================
      AppRoutes.SPLASH:
          (context) => const SplashScreen(), // Updated to use AppRoutes
      '/dummy':
          (context) =>
              const DummyScreen(), // Kept as is, '/dummy' not in AppRoutes
      // =================================================================
      // AUTHENTICATION ROUTES
      // =================================================================
      AppRoutes.SIGNIN:
          (context) => const SignInScreen(), // Updated to use AppRoutes
      AppRoutes.SIGNUP: // Updated to use AppRoutes
          (context) => const _PlaceholderScreen(
            title: '新規登録',
            message: 'Register Screen - Coming Soon',
            icon: Icons.person_add,
          ),
      AppRoutes.FORGOT_PASSWORD: // Updated to use AppRoutes
          (context) => const _PlaceholderScreen(
            title: 'パスワード忘れ',
            message: 'Forgot Password - Coming Soon',
            icon: Icons.lock_reset,
          ),

      // =================================================================
      // MAIN APP ROUTES
      // =================================================================
      AppRoutes.PARKING_SEARCH: // Updated to use AppRoutes and actual screen
          (context) => const ParkingSearchScreen(),
      AppRoutes.HOME: // Updated to use AppRoutes
          (context) => const _PlaceholderScreen(
            title: 'ユーザーホーム',
            message: 'User Home - redirecting...',
            icon: Icons.home,
          ),
      AppRoutes.OWNER_DASHBOARD: // Updated to use AppRoutes
          (context) => const _PlaceholderScreen(
            title: 'オーナーホーム',
            message: 'Owner Home - redirecting...',
            icon: Icons.business,
          ),
    };
  }
}

/// プレースホルダー画面ウィジェット
///
/// 未実装の画面用の共通プレースホルダー
/// アイコン、タイトル、メッセージを表示
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _PlaceholderScreen({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80.0, color: Theme.of(context).primaryColor),
              const SizedBox(height: 24.0),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create a proper splash screen as entry point
/// スプラッシュ画面ウィジェット
///
/// アプリ起動時の初期画面として機能し、
/// 認証状態の確認とナビゲーションを担当
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // =================================================================
  // ANIMATION CONTROLLERS
  // =================================================================
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // =================================================================
  // STATE VARIABLES
  // =================================================================
  String _loadingText = "ログイン情報を確認中...";

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// アニメーションの初期化
  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
  }

  /// スプラッシュシーケンスの開始
  void _startSplashSequence() {
    // アニメーション開始
    _fadeController.forward();

    // 認証チェック後のナビゲーション
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        _checkAuthAndNavigate();
      });
    });
  }

  /// 認証状態確認とナビゲーション処理
  Future<void> _checkAuthAndNavigate() async {
    try {
      if (!mounted) return;

      // ローディングテキスト更新
      setState(() {
        _loadingText = "画面を準備中...";
      });

      // 短い遅延後にDummyScreenへ遷移
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dummy');
      }
    } catch (e) {
      debugPrint('スプラッシュナビゲーションエラー: $e');

      // エラー時も安全にナビゲーション
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dummy');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // =================================================================
            // APP LOGO WITH ANIMATIONS
            // =================================================================
            _buildAnimatedLogo(),
            const SizedBox(height: 40),

            // =================================================================
            // APP NAME
            // =================================================================
            _buildAppName(),
            const SizedBox(height: 20),

            // =================================================================
            // LOADING FEEDBACK
            // =================================================================
            _buildLoadingSection(),
          ],
        ),
      ),
    );
  }

  /// アニメーション付きロゴ
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Image.asset(
              'assets/images/app_logo.png',
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.local_parking,
                  size: 100.0,
                  color: Theme.of(context).primaryColor,
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// アプリ名表示
  Widget _buildAppName() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        'パーキングアプリ',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// ローディングセクション
  Widget _buildLoadingSection() {
    return Column(
      children: [
        // ローディングテキスト
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            _loadingText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ローディングインジケーター
        FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
