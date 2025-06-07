import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/views/common/widgets/buttons.dart';

class ErrorMessageDisplay extends StatelessWidget {
  final String message;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;
  final IconData icon;

  const ErrorMessageDisplay({
    super.key,
    required this.message,
    this.actionButtonText,
    this.onActionPressed,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.error, size: 64.0),
            const SizedBox(height: 16.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyles.bodyLarge,
            ),
            if (actionButtonText != null && onActionPressed != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: PrimaryButton(
                  text: actionButtonText!,
                  onPressed: onActionPressed,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FormErrorText extends StatelessWidget {
  final String? text;
  final bool visible;

  const FormErrorText({super.key, this.text, this.visible = true});

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty || !visible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text!,
        style: TextStyles.bodyMedium.copyWith(color: AppColors.error),
      ),
    );
  }
}

class ErrorSnackbar {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class ErrorDialog {
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyles.titleMedium.copyWith(color: AppColors.error),
              ),
            ],
          ),
          content: Text(message, style: TextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
              child: Text(
                buttonText ?? 'OK',
                style: TextStyles.buttonText.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
