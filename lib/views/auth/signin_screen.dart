import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/core/routes/app_routes.dart';
import 'package:parking_app/views/auth/signup_screen.dart';
import 'package:parking_app/views/common/widgets/buttons.dart';
import 'package:parking_app/views/common/widgets/error.dart';
import 'package:parking_app/views/common/widgets/input_fields.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/core/services/auth_signin_service.dart';

// Define enum outside the class
enum UserRole { user, owner }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Form and validation
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // State variables
  bool _rememberMe = false;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.user;
  String? _errorMessage;

  // Service
  late final AuthSigninService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthSigninService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // =================================================================
  // EVENT HANDLERS
  // =================================================================

  /// ログインボタンクリック処理
  Future<void> _onClickSignIn() async {
    // エラーメッセージをクリア
    setState(() {
      _errorMessage = null;
    });

    // フォームバリデーション
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ローディング状態開始
    setState(() {
      _isLoading = true;
    });

    try {
      // ログイン処理実行
      final result = await _authService.signin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
        context: context,
      );

      if (result != null) {
        // ログイン成功 - 駐車場検索画面へ遷移
        if (mounted) {
          debugPrint('ログイン成功 - 駐車場検索画面へ遷移');
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.PARKING_SEARCH, // Changed from '/parking_search'
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('ログイン処理エラー: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'ログイン処理中にエラーが発生しました';
        });
      }
    } finally {
      // ローディング状態終了
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ユーザー役割更新処理
  void _updateUserRole(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
    debugPrint('ユーザー役割変更: ${role.name}');
  }

  /// パスワード忘れ画面への遷移
  void _navigateToForgotPassword() {
    Navigator.of(context).pushNamed('/forgot-password');
  }

  /// 新規登録画面への遷移
  void _navigateToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignUpScreen()));
  }

  // =================================================================
  // VALIDATION HELPERS
  // =================================================================

  /// メールアドレス/電話番号のバリデーション
  String? _validateEmailOrPhone(String? value) {
    return _authService.validateEmail(value);
  }

  /// パスワードのバリデーション
  String? _validatePassword(String? value) {
    return _authService.validatePassword(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isSmallScreen ? double.infinity : 500,
              padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =================================================================
                    // HEADER SECTION
                    // =================================================================
                    _buildHeaderSection(),

                    // =================================================================
                    // USER ROLE SELECTION
                    // =================================================================
                    _buildRoleSelectionSection(),

                    // =================================================================
                    // TITLE
                    // =================================================================
                    _buildTitleSection(l10n),

                    // =================================================================
                    // FORM SECTION
                    // =================================================================
                    _buildFormSection(l10n, isSmallScreen),

                    // =================================================================
                    // DIVIDER SECTION
                    // =================================================================
                    _buildDividerSection(l10n),

                    // =================================================================
                    // REGISTRATION LINK SECTION
                    // =================================================================
                    _buildRegistrationSection(l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =================================================================
  // UI BUILDING METHODS
  // =================================================================

  /// ヘッダーセクション（アプリロゴ）
  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Image.asset(
        'assets/images/app_logo.png',
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.local_parking,
            size: 80.0,
            color: AppColors.primary,
          );
        },
      ),
    );
  }

  /// ユーザー役割選択セクション
  Widget _buildRoleSelectionSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              _buildRoleOption(UserRole.user, "ユーザー", Icons.person),
              _buildRoleOption(UserRole.owner, "オーナー", Icons.business),
            ],
          ),
        ),
      ),
    );
  }

  /// タイトルセクション
  Widget _buildTitleSection(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.login,
          style: TextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 28.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  /// フォームセクション
  Widget _buildFormSection(AppLocalizations l10n, bool isSmallScreen) {
    return Column(
      children: [
        // エラーメッセージ表示
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FormErrorText(text: _errorMessage),
          ),

        // メールアドレス/電話番号入力フィールド
        AppTextField(
          label: l10n.email,
          hintText: l10n.emailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmailOrPhone,
          focusNode: _emailFocusNode,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
        ),
        const SizedBox(height: 16.0),

        // パスワード入力フィールド
        AppTextField(
          label: l10n.password,
          hintText: l10n.passwordHint,
          controller: _passwordController,
          obscureText: true,
          validator: _validatePassword,
          focusNode: _passwordFocusNode,
          textInputAction: TextInputAction.done,
          showTogglePasswordVisibility: true,
          onFieldSubmitted: (_) => _onClickSignIn(),
        ),

        // ログイン保存とパスワード忘れセクション
        _buildRememberMeAndForgotPasswordSection(l10n, isSmallScreen),

        const SizedBox(height: 24.0),

        // ログインボタン
        PrimaryButton(
          text: l10n.login,
          onPressed: _onClickSignIn,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  /// ログイン保存とパスワード忘れセクション
  Widget _buildRememberMeAndForgotPasswordSection(
    AppLocalizations l10n,
    bool isSmallScreen,
  ) {
    return isSmallScreen
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Remember me checkbox - 小画面用に最適化
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                Flexible(
                  child: Text(
                    "ログイン情報を保存",
                    style: TextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // パスワード忘れリンク - 小画面用配置
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _navigateToForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.forgotPassword),
              ),
            ),
          ],
        )
        : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Remember me checkbox
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                Text("ログイン情報を保存", style: TextStyles.bodyMedium),
              ],
            ),

            // パスワード忘れリンク
            TextButton(
              onPressed: _navigateToForgotPassword,
              child: Text(l10n.forgotPassword),
            ),
          ],
        );
  }

  /// 区切り線セクション
  Widget _buildDividerSection(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 24.0),
        Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                l10n.or,
                style: TextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(thickness: 1)),
          ],
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  /// 新規登録リンクセクション
  Widget _buildRegistrationSection(AppLocalizations l10n) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: l10n.createAccount,
          style: TextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          children: [
            TextSpan(
              text: l10n.registerNow,
              style: TextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()..onTap = _navigateToRegister,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build each role option
  Widget _buildRoleOption(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => _updateUserRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.0,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
