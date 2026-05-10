import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.colorBgMain,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Text(
        '강원 🧡 정윤 가계부',
        style: AppTextStyles.textHeadlineMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.colorTextPrimary,
        size: 24,
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
    );
  }
}
