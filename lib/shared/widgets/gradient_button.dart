import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Teal→Indigo 그래디언트 CTA 버튼.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled && widget.onPressed != null;

    return Opacity(
      opacity: active ? 1.0 : 0.5,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: active ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.appGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, size: 18, color: AppColors.colorBgMain),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.textTitleSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorBgMain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Teal→Indigo 그래디언트 FAB.
class GradientFAB extends StatelessWidget {
  const GradientFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.heroTag,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.appGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(45, 212, 191, 0.35),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        splashColor: AppColors.colorHoverTeal,
        child: Icon(icon, color: AppColors.colorBgMain),
      ),
    );
  }
}

/// 스크롤 TOP 등 보조 FAB (small).
class SmallFAB extends StatelessWidget {
  const SmallFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.heroTag,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: AppColors.colorBgSub,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.colorBgCard),
      ),
      child: Icon(icon, color: AppColors.colorTextSecondary, size: 18),
    );
  }
}

/// 삭제 등 위험 동작 전용 버튼.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.badgeExpenseBg,
          foregroundColor: AppColors.colorError,
          side: const BorderSide(color: AppColors.colorError),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.textTitleSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: AppColors.colorError),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
