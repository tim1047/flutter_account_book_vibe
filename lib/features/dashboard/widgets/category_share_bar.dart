import 'package:flutter/material.dart';

/// 카테고리별 지출 비중을 하나의 가로 스택 바로 보여준다.
class CategoryShareBar extends StatelessWidget {
  const CategoryShareBar({super.key, required this.segments, this.height = 20});

  final List<({Color color, double ratio})> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                flex: (segments[i].ratio * 1000).round().clamp(1, 1000),
                child: ColoredBox(color: segments[i].color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
