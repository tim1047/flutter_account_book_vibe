import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    this.bottom,
    this.showMenuButton = true,
  });

  final PreferredSizeWidget? bottom;

  /// false면 좌측 햄버거(드로어 열기) 버튼을 렌더하지 않는다.
  /// 바텀 네비게이션 셸 화면들(목록/분석/홈/자산)에서 사용.
  final bool showMenuButton;

  @override
  Size get preferredSize => Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

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
      leading: showMenuButton
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      bottom: bottom,
    );
  }
}
