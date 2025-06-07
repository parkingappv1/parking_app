import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A screen that displays error messages and provides actions to recover
class ErrorScreen extends StatelessWidget {
  /// The error message to display
  final String message;

  /// Optional action to perform when the retry button is pressed
  final VoidCallback? onRetry;

  /// Optional image asset path for the error illustration
  final String? imagePath;

  /// Controls whether to show a retry button
  final bool showRetry;

  /// Controls whether to show a back button
  final bool showBackButton;

  /// Creates an error screen with the given message
  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.imagePath,
    this.showRetry = true,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar:
          showBackButton
              ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.primary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
              : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error image or icon
              _buildErrorImage(screenHeight),

              const SizedBox(height: 32),

              // Error message
              Text(
                l10n.errorOccurred,
                style: TextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Error details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  message,
                  style: TextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              if (showRetry)
                ElevatedButton(
                  onPressed:
                      onRetry ??
                      () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    onRetry != null ? l10n.retry : l10n.backToHomeScreen,
                    style: TextStyles.titleMedium.copyWith(color: Colors.white),
                  ),
                ),

              // Additional help text
              const SizedBox(height: 24),
              Text(
                l10n.contactSupportIfPersists,
                style: TextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the error image or icon based on available assets
  Widget _buildErrorImage(double screenHeight) {
    // Use custom image if provided
    if (imagePath != null) {
      return Image.asset(imagePath!, height: screenHeight * 0.2);
    }

    // Default error icon
    return Icon(
      Icons.error_outline_rounded,
      size: 100,
      color: AppColors.primary.withOpacity(0.8),
    );
  }
}

/// A specialized error screen for network connectivity issues
class NetworkErrorScreen extends StatelessWidget {
  /// Action to perform when retry button is pressed
  final VoidCallback? onRetry;

  /// Creates a network error screen
  const NetworkErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ErrorScreen(
      message: l10n.networkErrorMessage,
      onRetry: onRetry,
      imagePath: 'assets/images/network_error.png',
      showBackButton: false,
    );
  }
}

/// A specialized error screen for unauthorized access
class UnauthorizedScreen extends StatelessWidget {
  /// Creates an unauthorized access error screen
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ErrorScreen(
      message: l10n.unauthorizedMessage,
      showRetry: true,
      onRetry: () {
        // Navigate to login screen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/signin', (route) => false);
      },
      imagePath: 'assets/images/unauthorized.png',
      showBackButton: false,
    );
  }
}
