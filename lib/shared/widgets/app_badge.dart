import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 거래/자산에 표시되는 배지 종류.
enum BadgeType {
  income,
  expense,
  invest,
  seoulLove,
  firstMeeting,
  point,
  impulse,
  fixed,
}

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.type,
    required this.label,
  });

  final BadgeType type;
  final String label;

  Color get _bg {
    switch (type) {
      case BadgeType.income:
        return AppColors.badgeIncomeBg;
      case BadgeType.expense:
        return AppColors.badgeExpenseBg;
      case BadgeType.invest:
        return AppColors.badgeInvestBg;
      case BadgeType.seoulLove:
        return AppColors.badgeSeoulLoveBg;
      case BadgeType.firstMeeting:
        return AppColors.badgeFirstMeetingBg;
      case BadgeType.point:
        return AppColors.badgePointBg;
      case BadgeType.impulse:
        return AppColors.badgeImpulseBg;
      case BadgeType.fixed:
        return AppColors.badgeFixedBg;
    }
  }

  Color get _fg {
    switch (type) {
      case BadgeType.income:
        return AppColors.badgeIncomeText;
      case BadgeType.expense:
        return AppColors.badgeExpenseText;
      case BadgeType.invest:
        return AppColors.badgeInvestText;
      case BadgeType.seoulLove:
        return AppColors.badgeSeoulLoveText;
      case BadgeType.firstMeeting:
        return AppColors.badgeFirstMeetingText;
      case BadgeType.point:
        return AppColors.badgePointText;
      case BadgeType.impulse:
        return AppColors.badgeImpulseText;
      case BadgeType.fixed:
        return AppColors.badgeFixedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color: _fg,
        ),
      ),
    );
  }
}
