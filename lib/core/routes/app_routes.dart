/// アプリケーション内で使用される全てのルート定数を定義
/// ナビゲーションの一元管理とタイプセーフなルーティングを提供
class AppRoutes {
  // プライベートコンストラクタ - インスタンス化を防止
  AppRoutes._();

  // ===== 基本ルート =====
  /// スプラッシュ画面 - アプリ起動時の初期画面
  static const String SPLASH = '/splash';

  /// 汎用エラー画面 - 予期しないエラー発生時
  static const String ERROR = '/error';

  /// ネットワークエラー画面 - 接続問題発生時
  static const String NETWORK_ERROR = '/network-error';

  /// 認証エラー画面 - 権限不足時
  static const String UNAUTHORIZED = '/unauthorized';

  // ===== 認証関連ルート =====
  /// サインイン画面 - ユーザーログイン
  static const String SIGNIN = '/signin';

  /// サインアップ画面 - 新規ユーザー登録
  static const String SIGNUP = '/signup';

  /// レジスター画面（signupのエイリアス）
  static const String REGISTER = '/register';

  /// パスワード忘れ画面 - パスワードリセット要求
  static const String FORGOT_PASSWORD = '/forgot-password';

  /// パスワードリセット画面 - 新しいパスワード設定
  static const String PASSWORD_RESET = '/password-reset';

  /// 認証コード確認画面 - SMS/メール認証
  static const String VERIFY_CODE = '/verify-code';

  /// メール認証画面 - メールアドレス確認
  static const String VERIFY_EMAIL = '/verify-email';

  /// パスワードリセット実行画面
  static const String RESET_PASSWORD = '/reset-password';

  /// ログアウト処理ルート
  static const String LOGOUT = '/logout';

  // ===== メイン画面ルート =====
  /// ホーム画面 - アプリのメインダッシュボード
  static const String HOME = '/home';

  /// 駐車場検索画面 - 駐車場の検索・絞り込み
  static const String PARKING_SEARCH = '/parking-search';

  /// プロフィール画面 - ユーザー情報管理
  static const String PROFILE = '/profile';

  /// 設定画面 - アプリ設定とユーザー設定
  static const String SETTINGS = '/settings';

  // ===== 駐車場利用者向けルート =====
  /// 駐車場検索画面 - 近くの駐車場を探す
  static const String FIND_PARKING = '/find-parking';

  /// 駐車場詳細画面 - 特定駐車場の詳細情報
  static const String PARKING_DETAILS = '/parking-details';

  /// 駐車場予約画面 - 予約手続き
  static const String BOOK_PARKING = '/book-parking';

  /// 予約一覧画面 - ユーザーの予約履歴
  static const String RESERVATIONS = '/reservations';

  /// 支払い履歴画面 - 決済記録
  static const String PAYMENT_HISTORY = '/payment-history';

  // ===== 駐車場オーナー向けルート =====
  /// オーナーダッシュボード - 駐車場管理の概要
  static const String OWNER_DASHBOARD = '/owner-dashboard';

  /// 駐車場追加画面 - 新しい駐車場の登録
  static const String ADD_PARKING_SPACE = '/add-parking-space';

  /// 駐車場編集画面 - 既存駐車場の情報更新
  static const String EDIT_PARKING_SPACE = '/edit-parking-space';

  /// オーナー予約管理画面 - 自分の駐車場の予約状況
  static const String OWNER_RESERVATIONS = '/owner-reservations';

  /// オーナー分析画面 - 収益と利用統計
  static const String OWNER_ANALYTICS = '/owner-analytics';

  // ===== ユーティリティメソッド =====

  /// 全てのルートマッピングを取得
  /// デバッグやログ出力時に使用
  static Map<String, String> getAllRoutes() {
    return {
      'SPLASH': SPLASH,
      'ERROR': ERROR,
      'NETWORK_ERROR': NETWORK_ERROR,
      'UNAUTHORIZED': UNAUTHORIZED,
      'SIGNIN': SIGNIN,
      'SIGNUP': SIGNUP,
      'REGISTER': REGISTER,
      'FORGOT_PASSWORD': FORGOT_PASSWORD,
      'PASSWORD_RESET': PASSWORD_RESET,
      'VERIFY_CODE': VERIFY_CODE,
      'VERIFY_EMAIL': VERIFY_EMAIL,
      'RESET_PASSWORD': RESET_PASSWORD,
      'LOGOUT': LOGOUT,
      'HOME': HOME,
      'PARKING_SEARCH': PARKING_SEARCH,
      'PROFILE': PROFILE,
      'SETTINGS': SETTINGS,
      'FIND_PARKING': FIND_PARKING,
      'PARKING_DETAILS': PARKING_DETAILS,
      'BOOK_PARKING': BOOK_PARKING,
      'RESERVATIONS': RESERVATIONS,
      'PAYMENT_HISTORY': PAYMENT_HISTORY,
      'OWNER_DASHBOARD': OWNER_DASHBOARD,
      'ADD_PARKING_SPACE': ADD_PARKING_SPACE,
      'EDIT_PARKING_SPACE': EDIT_PARKING_SPACE,
      'OWNER_RESERVATIONS': OWNER_RESERVATIONS,
      'OWNER_ANALYTICS': OWNER_ANALYTICS,
    };
  }

  /// 認証が必要なルートのリストを取得
  static List<String> getProtectedRoutes() {
    return [
      HOME,
      PROFILE,
      SETTINGS,
      FIND_PARKING,
      PARKING_DETAILS,
      BOOK_PARKING,
      RESERVATIONS,
      PAYMENT_HISTORY,
      OWNER_DASHBOARD,
      ADD_PARKING_SPACE,
      EDIT_PARKING_SPACE,
      OWNER_RESERVATIONS,
      OWNER_ANALYTICS,
    ];
  }

  /// 認証不要なパブリックルートのリストを取得
  static List<String> getPublicRoutes() {
    return [
      SPLASH,
      SIGNIN,
      SIGNUP,
      REGISTER,
      FORGOT_PASSWORD,
      PASSWORD_RESET,
      VERIFY_CODE,
      VERIFY_EMAIL,
      RESET_PASSWORD,
      ERROR,
      NETWORK_ERROR,
      UNAUTHORIZED,
    ];
  }

  /// 指定されたルートが認証を必要とするかチェック
  static bool requiresAuthentication(String route) {
    return getProtectedRoutes().contains(route);
  }

  /// ルートの表示名を取得（デバッグ用）
  static String getRouteDisplayName(String route) {
    final routeNames = {
      SPLASH: 'スプラッシュ画面',
      ERROR: 'エラー画面',
      NETWORK_ERROR: 'ネットワークエラー画面',
      UNAUTHORIZED: '認証エラー画面',
      SIGNIN: 'サインイン画面',
      SIGNUP: 'サインアップ画面',
      REGISTER: 'レジスター画面',
      FORGOT_PASSWORD: 'パスワード忘れ画面',
      PASSWORD_RESET: 'パスワードリセット画面',
      VERIFY_CODE: '認証コード確認画面',
      VERIFY_EMAIL: 'メール認証画面',
      RESET_PASSWORD: 'パスワードリセット実行画面',
      LOGOUT: 'ログアウト',
      HOME: 'ホーム画面',
      PARKING_SEARCH: '駐車場検索画面',
      PROFILE: 'プロフィール画面',
      SETTINGS: '設定画面',
      FIND_PARKING: '駐車場検索画面',
      PARKING_DETAILS: '駐車場詳細画面',
      BOOK_PARKING: '駐車場予約画面',
      RESERVATIONS: '予約一覧画面',
      PAYMENT_HISTORY: '支払い履歴画面',
      OWNER_DASHBOARD: 'オーナーダッシュボード',
      ADD_PARKING_SPACE: '駐車場追加画面',
      EDIT_PARKING_SPACE: '駐車場編集画面',
      OWNER_RESERVATIONS: 'オーナー予約管理画面',
      OWNER_ANALYTICS: 'オーナー分析画面',
    };

    return routeNames[route] ?? '不明な画面';
  }
}
