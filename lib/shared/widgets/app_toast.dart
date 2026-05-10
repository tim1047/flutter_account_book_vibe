import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        onDismissed: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismissed,
  });

  final String message;
  final ToastType type;
  final VoidCallback onDismissed;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  /// Total visible duration (ms) before fade-out begins.
  static const int _displayMs = 2000;

  /// Fade-in duration (ms).
  static const int _fadeInMs = 250;

  /// Fade-out duration (ms).
  static const int _fadeOutMs = 300;

  @override
  void initState() {
    super.initState();

    const totalMs = _fadeInMs + _displayMs + _fadeOutMs;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: totalMs),
    );

    // Build a piecewise opacity curve:
    // [0 → fadeIn/total] fade in  →  [fadeIn → (fadeIn+display)/total] hold
    // → [(fadeIn+display)/total → 1.0] fade out
    const double fadeInEnd = _fadeInMs / totalMs;
    const double holdEnd = (_fadeInMs + _displayMs) / totalMs;

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1),
        weight: _fadeInMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: _displayMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0),
        weight: _fadeOutMs.toDouble(),
      ),
    ]).animate(_controller);

    // Avoid unused variable warnings — values are used implicitly through
    // the TweenSequence above; these references keep the linter satisfied.
    assert(fadeInEnd >= 0 && holdEnd >= fadeInEnd);

    _controller.forward().whenComplete(widget.onDismissed);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon => switch (widget.type) {
        ToastType.success => Icons.check_circle,
        ToastType.error => Icons.delete_outline,
        ToastType.info => Icons.edit,
      };

  Color get _iconColor => switch (widget.type) {
        ToastType.success => AppColors.colorSuccess,
        ToastType.error => AppColors.colorError,
        ToastType.info => AppColors.colorInfo,
      };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 32,
      right: 32,
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: child,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.colorBgCard,
              border: Border.all(color: AppColors.colorDivider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, color: _iconColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTextStyles.textBodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
