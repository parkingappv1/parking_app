/// パーキングアプリ - ユーザー・オーナー新規登録画面
///
/// このファイルは以下の機能を提供します：
/// - ユーザー/オーナーの新規登録フォーム
/// - 入力データの検証とバリデーション
/// - 登録タイプ別のフォーム切り替え
/// - 認証サービスとの統合
/// - エラーハンドリングと成功時のナビゲーション
///
/// 作成者: Parking App Development Team
/// 最終更新: 2025-05-28
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/core/services/auth_signup_service.dart';
import 'package:parking_app/core/api/auth/auth_signup_api.dart';
import 'package:parking_app/core/utils/validators.dart';
import 'package:parking_app/core/utils/dialog_helper.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/views/common/widgets/buttons.dart';
import 'package:parking_app/views/common/widgets/input_fields.dart';
import 'package:parking_app/views/common/widgets/loading.dart';

/// ユーザーロール列挙型
/// ユーザーとオーナーの登録タイプを定義
enum UserRole {
  /// 一般ユーザー
  user,

  /// 駐車場オーナー
  owner,
}

/// 新規登録画面ウィジェット
///
/// ユーザーとオーナーの新規登録を処理するStatefulWidget
/// フォームの状態管理と入力検証を行う
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

/// 新規登録画面の状態管理クラス
///
/// フォームコントローラー、バリデーション、UI状態を管理
class _SignUpScreenState extends State<SignUpScreen> {
  // =================================================================
  // FORM KEYS & CONTROLLERS
  // =================================================================
  final _userFormKey = GlobalKey<FormState>();
  final _ownerFormKey = GlobalKey<FormState>();

  // User role tracking
  UserRole _selectedRole = UserRole.user;

  // Service instances - created directly instead of using Provider
  late final AuthSignUpService _signupService;

  // Common field controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthdayController = TextEditingController();

  // Owner-specific field controllers
  final _fullNameKanaController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _remarksController = TextEditingController();

  // =================================================================
  // STATE VARIABLES
  // =================================================================
  String _selectedGender = 'male';
  String _selectedRegistrantType = 'individual';
  bool _promotionalEmailOptIn = false;
  bool _serviceEmailOptIn = true;
  bool _isLoading = false;

  // Password visibility states
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // TODO: Remove mock data functionality before production
  final bool _showMockDataButton = true;

  // =================================================================
  // LIFECYCLE METHODS
  // =================================================================
  @override
  void initState() {
    super.initState();

    // Initialize service with simplified constructor
    final authSignUpApi = AuthSignUpApi();
    _signupService = AuthSignUpService(authSignUpApi);
  }

  @override
  void dispose() {
    // Common field controllers cleanup
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _birthdayController.dispose();

    // Owner-specific field controllers cleanup
    _fullNameKanaController.dispose();
    _postalCodeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // =================================================================
  // BUILD METHOD
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? const LoadingWidget() : _buildBody(),
    );
  }

  /// アプリバーの構築
  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      title: Text(l10n.signup, style: TextStyles.titleLarge),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// メインボディの構築
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Mock data button (development only)
            if (_showMockDataButton) _buildMockDataButton(),

            // Role selection segment
            _buildRoleSelector(),
            const SizedBox(height: 32),

            // Form content based on selected role
            _selectedRole == UserRole.user
                ? _buildUserSignupForm()
                : _buildOwnerSignupForm(),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // UI COMPONENT BUILDERS
  // =================================================================

  /// モックデータボタンの構築（開発用）
  Widget _buildMockDataButton() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: OutlinedButton.icon(
        onPressed: _fillMockData,
        icon: const Icon(Icons.auto_fix_high, size: 18),
        label: Text(l10n.testDataFill),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  /// ロール選択セグメントの構築
  Widget _buildRoleSelector() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            _buildRoleOption(UserRole.user, l10n.user, Icons.person),
            _buildRoleOption(UserRole.owner, l10n.owner, Icons.business),
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
        onTap: () => setState(() => _selectedRole = role),
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

  Widget _buildUserSignupForm() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _userFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.user}${l10n.signup}',
            style: TextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Email field
          AppTextField(
            label: l10n.email,
            hintText: l10n.emailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.validateEmail(context, value),
          ),
          const SizedBox(height: 16),

          // Password field
          AppTextField(
            label: l10n.password,
            hintText: l10n.passwordHint,
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: (value) => Validators.validatePassword(context, value),
            showTogglePasswordVisibility: true,
            onToggleVisibility:
                () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 16),

          // Confirm password field
          AppTextField(
            label: l10n.confirmPassword,
            hintText: l10n.confirmPasswordHint,
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator:
                (value) => Validators.validatePasswordMatch(
                  context,
                  value,
                  _passwordController.text,
                ),
            showTogglePasswordVisibility: true,
            onToggleVisibility:
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
          ),
          const SizedBox(height: 16),

          // Phone field
          AppTextField(
            label: l10n.phone,
            hintText: l10n.phoneHint,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) => Validators.validatePhone(context, value),
          ),
          const SizedBox(height: 16),

          // Full name field
          AppTextField(
            label: l10n.name,
            hintText: l10n.nameHint,
            controller: _fullNameController,
            validator: (value) => Validators.validateRequired(context, value),
          ),
          const SizedBox(height: 16),

          // Address field
          AppTextField(
            label: l10n.address,
            hintText: l10n.addressHint,
            controller: _addressController,
            validator: (value) => Validators.validateRequired(context, value),
          ),
          const SizedBox(height: 16),

          // Birthday field
          _buildBirthdayField(),
          const SizedBox(height: 16),

          // Gender selection
          _buildGenderSelection(),
          const SizedBox(height: 24),

          // Email preferences
          _buildEmailPreferences(),
          const SizedBox(height: 32),

          // Register button
          PrimaryButton(
            text: '${l10n.user}${l10n.signup}',
            onPressed: () => _handleSignUp('user'),
          ),
          const SizedBox(height: 16),

          // Login link
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildOwnerSignupForm() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _ownerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.owner}${l10n.signup}',
            style: TextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Registrant type selection
          _buildRegistrantTypeSelection(),
          const SizedBox(height: 16),

          // Email field
          AppTextField(
            label: l10n.email,
            hintText: l10n.emailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.validateEmail(context, value),
          ),
          const SizedBox(height: 16),

          // Password field
          AppTextField(
            label: l10n.password,
            hintText: l10n.passwordHint,
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: (value) => Validators.validatePassword(context, value),
            showTogglePasswordVisibility: true,
            onToggleVisibility:
                () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 16),

          // Confirm password field
          AppTextField(
            label: l10n.confirmPassword,
            hintText: l10n.confirmPasswordHint,
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator:
                (value) => Validators.validatePasswordMatch(
                  context,
                  value,
                  _passwordController.text,
                ),
            showTogglePasswordVisibility: true,
            onToggleVisibility:
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
          ),
          const SizedBox(height: 16),

          // Phone field
          AppTextField(
            label: l10n.phone,
            hintText: l10n.phoneHint,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) => Validators.validatePhone(context, value),
          ),
          const SizedBox(height: 16),

          // Full name field
          AppTextField(
            label: l10n.name,
            hintText: l10n.nameHint,
            controller: _fullNameController,
            validator: (value) => Validators.validateRequired(context, value),
          ),
          const SizedBox(height: 16),

          // Full name kana field
          AppTextField(
            label: l10n.nameKana,
            hintText: l10n.nameKanaHint,
            controller: _fullNameKanaController,
            validator: (value) => Validators.validateRequired(context, value),
          ),
          const SizedBox(height: 16),

          // Postal code field
          AppTextField(
            label: l10n.postalCode,
            hintText: l10n.postalCodeHint,
            controller: _postalCodeController,
            keyboardType: TextInputType.number,
            validator: (value) => Validators.validateRequired(context, value),
          ),
          const SizedBox(height: 16),

          // Address field
          AppTextField(
            label: l10n.address,
            hintText: l10n.addressHint,
            controller: _addressController,
            validator: (value) => Validators.validateRequired(context, value),
          ),
          const SizedBox(height: 16),

          // Remarks field
          AppTextField(
            label: l10n.remarks,
            hintText: l10n.remarksHint,
            controller: _remarksController,
          ),
          const SizedBox(height: 16),

          // Birthday field
          _buildBirthdayField(),
          const SizedBox(height: 16),

          // Gender selection
          _buildGenderSelection(),
          const SizedBox(height: 32),

          // Register button
          PrimaryButton(
            text: '${l10n.owner}${l10n.signup}',
            onPressed: () => _handleSignUp('owner'),
          ),
          const SizedBox(height: 16),

          // Login link
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildRegistrantTypeSelection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.registrantType, style: TextStyles.bodyMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRegistrantType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'individual',
              child: Text(l10n.registrantTypeIndividual),
            ),
            DropdownMenuItem(
              value: 'corporation',
              child: Text(l10n.registrantTypeCorporation),
            ),
            DropdownMenuItem(
              value: 'sole_proprietor',
              child: Text(l10n.registrantTypeSoleProprietor),
            ),
            DropdownMenuItem(
              value: 'voluntary_organization',
              child: Text(l10n.registrantTypeVoluntaryOrganization),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedRegistrantType = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBirthdayField() {
    final l10n = AppLocalizations.of(context);
    return AppTextField(
      label: l10n.birthday,
      hintText: l10n.birthdayHint,
      controller: _birthdayController,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(
            const Duration(days: 6570),
          ), // 18 years ago
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          _birthdayController.text = date.toString().split(' ')[0];
        }
      },
    );
  }

  Widget _buildGenderSelection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.gender, style: TextStyles.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(l10n.genderMale),
                value: 'male',
                groupValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(l10n.genderFemale),
                value: 'female',
                groupValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailPreferences() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.emailPreferences, style: TextStyles.bodyMedium),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(l10n.promotionalEmail),
          value: _promotionalEmailOptIn,
          onChanged: (value) => setState(() => _promotionalEmailOptIn = value),
        ),
        SwitchListTile(
          title: Text(l10n.serviceEmail),
          value: _serviceEmailOptIn,
          onChanged: (value) => setState(() => _serviceEmailOptIn = value),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: RichText(
        text: TextSpan(
          text: l10n.alreadyHaveAccount,
          style: TextStyles.bodyMedium,
          children: [
            const TextSpan(text: ' '),
            TextSpan(
              text: l10n.login,
              style: TextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap =
                        () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignUp(String role) async {
    final formKey = role == 'user' ? _userFormKey : _ownerFormKey;

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use the local service instance instead of Provider
      final l10n = AppLocalizations.of(context);

      final response = await _signupService.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        role: role,
        fullName: _fullNameController.text.trim(),
        address: _addressController.text.trim(),
        promotionalEmailOptIn: _promotionalEmailOptIn,
        serviceEmailOptIn: _serviceEmailOptIn,
        registrantType: role == 'owner' ? _selectedRegistrantType : null,
        fullNameKana:
            role == 'owner' ? _fullNameKanaController.text.trim() : null,
        postalCode: role == 'owner' ? _postalCodeController.text.trim() : null,
        remarks:
            role == 'owner' && _remarksController.text.isNotEmpty
                ? _remarksController.text.trim()
                : null,
        birthday:
            _birthdayController.text.isNotEmpty
                ? _birthdayController.text
                : null,
        gender: _selectedGender,
      );

      if (response.isSuccess) {
        if (mounted) {
          await DialogHelper.showSuccessDialog(
            context,
            l10n.registrationComplete,
            l10n.verificationEmailSent,
          );
          Navigator.of(context).pushReplacementNamed(
            '/verify-code',
            arguments: _emailController.text.trim(),
          );
        }
      } else {
        if (mounted) {
          await DialogHelper.showErrorDialog(
            context,
            l10n.registrationError,
            response.message ?? l10n.registrationFailed,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          l10n.errorOccurred,
          '${l10n.unexpectedError}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // TODO: Remove mock data methods before production
  void _fillMockData() {
    setState(() {
      // Common mock data
      _emailController.text =
          _selectedRole == UserRole.user
              ? 'test.user@example.com'
              : 'test.owner@example.com';
      _passwordController.text = 'TestPass123!';
      _confirmPasswordController.text = 'TestPass123!';
      _phoneController.text = '09012345678';
      _fullNameController.text = '山田太郎';
      _addressController.text = '東京都渋谷区渋谷1-1-1 渋谷ビル101';
      _birthdayController.text = '1990-05-15';
      _selectedGender = 'male';
      _promotionalEmailOptIn = true;
      _serviceEmailOptIn = true;

      // Owner-specific mock data
      if (_selectedRole == UserRole.owner) {
        _fullNameKanaController.text = 'ヤマダタロウ';
        _postalCodeController.text = '1500001';
        _remarksController.text = 'テスト用の駐車場オーナーです。問い合わせはメールでお願いします。';
        _selectedRegistrantType = 'individual';
      } else {
        // Clear owner-specific fields and reset related state when user is selected
        _fullNameKanaController.clear();
        _postalCodeController.clear();
        _remarksController.clear();
        _selectedRegistrantType = 'individual'; // Reset to default
      }
    });

    // Show confirmation snackbar
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedRole == UserRole.user ? l10n.user : l10n.owner}${l10n.testDataFilled}',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
