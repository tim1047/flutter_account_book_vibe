import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 사용자 프로필 아바타 위젯.
///
/// [memberIndex]에 따라 [AppColors.memberColors] 팔레트에서 테두리 색상을 선택한다.
/// [imagePath]가 null이거나 로드 실패 시 이니셜 폴백을 표시한다.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.memberIndex,
    this.imagePath,
    this.name,
    this.size = 40,
  });

  final int memberIndex;
  final String? imagePath;
  final String? name;
  final double size;

  Color get _borderColor {
    const List<Color> palette = AppColors.memberColors;
    return palette[memberIndex % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final double inner = size - 4;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: imagePath != null
            ? Image.asset(
                imagePath!,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Fallback(
                  size: inner,
                  name: name,
                  color: _borderColor,
                ),
              )
            : _Fallback(size: inner, name: name, color: _borderColor),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.size,
    required this.color,
    this.name,
  });

  final double size;
  final Color color;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final String initial =
        (name != null && name!.isNotEmpty) ? name!.characters.first : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: Color.fromRGBO(
        color.red,
        color.green,
        color.blue,
        0.20,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
