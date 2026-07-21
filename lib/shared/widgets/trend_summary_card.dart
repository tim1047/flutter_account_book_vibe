import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 추이 화면 상단에 쓰이는 아이콘 + 한 줄 요약 카드.
class TrendSummaryCard extends StatelessWidget {
  const TrendSummaryCard({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.colorBgSub,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.colorTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
