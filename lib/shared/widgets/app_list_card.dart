import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_shadows.dart';
import 'package:flutter/material.dart';

/// 가계부/자산 목록에서 공용으로 쓰는 리스트 카드.
///
/// leading(아바타/아이콘), title, subtitle, badges, trailing 슬롯으로
/// 내용을 주입받는 순수 UI 컴포넌트. 모델이나 비즈니스 로직은 모른다.
class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.badges = const [],
    this.trailing,
    required this.onTap,
    this.onLongPress,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget> badges;
  final Widget? trailing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.colorBgSub,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        subtitle!,
                      ],
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: badges,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
