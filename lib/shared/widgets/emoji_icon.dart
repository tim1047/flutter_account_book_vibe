import 'package:flutter/material.dart';

class EmojiIcon extends StatelessWidget {
  const EmojiIcon({
    super.key,
    required this.emoji,
    required this.backgroundColor,
    this.size = 46,
    this.fontSize = 20,
  });

  final String emoji;
  final Color backgroundColor;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}
