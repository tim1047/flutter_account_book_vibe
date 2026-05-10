import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ProgressRow extends StatelessWidget {
  const ProgressRow({
    super.key,
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
    this.emoji,
    this.badge,
    this.badgeColor,
    this.onTap,
  });

  final String label;
  final String value;

  /// 0.0 ~ 1.0
  final double percentage;
  final Color color;
  final String? emoji;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.colorTextPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        _Badge(
                          text: badge!,
                          color: badgeColor ?? AppColors.colorWarning,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _AnimatedProgress(value: percentage, color: color),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AnimatedProgress extends StatefulWidget {
  const _AnimatedProgress({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  State<_AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<_AnimatedProgress>
    with SingleTickerProviderStateMixin {
  static List<Color>? _gradientFor(Color color) {
    if (color == AppColors.colorExpense) {
      return [AppColors.colorExpense, AppColors.colorInvest];
    }
    if (color == AppColors.colorInvest) {
      return [AppColors.colorInvest, AppColors.colorRate];
    }
    if (color == AppColors.colorProfit) {
      return [AppColors.colorProfit, AppColors.colorIncome];
    }
    if (color == AppColors.colorRate) {
      return [AppColors.colorRate, AppColors.colorInvest];
    }
    if (color == AppColors.colorUser2) {
      return [AppColors.colorUser2, AppColors.colorInvest];
    }
    // colorIncome == colorAccentTeal == colorUser1 (모두 0xFF2DD4BF)
    if (color == AppColors.colorIncome) {
      return [AppColors.colorIncome, AppColors.colorProfit];
    }
    return null;
  }

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgress old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _gradientFor(widget.color);
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: SizedBox(
          height: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.colorProgressTrack),
              FractionallySizedBox(
                widthFactor: _animation.value.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: gradientColors != null
                      ? BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                        )
                      : BoxDecoration(color: widget.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
