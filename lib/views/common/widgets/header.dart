import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';

class CommonHeader extends StatefulWidget implements PreferredSizeWidget {
  final String barText;

  const CommonHeader({
    super.key,
    required this.barText,
  });

  @override
  State<CommonHeader> createState() => _CommonHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CommonHeaderState extends State<CommonHeader> {
  Future<void> _handleLogout() async {
    try {
      // 在这里调用你的登出服务
      // 例如：
      // final authService = Provider.of<AuthSignInService>(context, listen: false);
      // await authService.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        widget.barText,
        style: TextStyles.titleLarge.copyWith(color: Colors.white),
      ),
      backgroundColor: AppColors.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _handleLogout,
          tooltip: 'ログアウト',
        ),
      ],
    );
  }
}
