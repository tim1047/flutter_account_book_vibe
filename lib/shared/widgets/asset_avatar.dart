import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 자산 로고/아이콘 아바타 위젯.
///
/// [logoUrl]이 있으면 네트워크 이미지를 우선 사용하고, 없으면 [logoKey]에
/// 매핑된 아이콘/글리프로 대체한다. [logoKey]가 없거나 매핑되지 않으면
/// (그리고 [logoUrl]도 없으면) 아바타를 아예 표시하지 않는다 —
/// [isSupported]로 미리 확인하고 leading 슬롯 자체를 비워야 한다.
class AssetAvatar extends StatelessWidget {
  const AssetAvatar({
    super.key,
    this.logoUrl,
    this.logoKey,
    this.size = 40,
  });

  final String? logoUrl;
  final String? logoKey;
  final double size;

  static const Map<String, IconData> _icons = <String, IconData>{
    'currency_usd': Icons.attach_money,
    'currency_jpy': Icons.currency_yen,
    'etf': Icons.candlestick_chart,
    'real_estate': Icons.home_work,
  };

  // Material Icons엔 원화 기호가 없어 텍스트 글리프로 대체.
  static const String _wonGlyphKey = 'currency_krw';
  static const String _wonGlyph = '₩';

  /// [logoKey]가 아이콘/글리프로 표현 가능한지 여부.
  static bool isSupported(String? logoKey) =>
      logoKey != null && (_icons.containsKey(logoKey) || logoKey == _wonGlyphKey);

  Color get _backgroundColor =>
      AppColors.assetLogoBackgroundColors[logoKey] ?? Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: (logoUrl != null && logoUrl!.isNotEmpty)
          ? Image.network(
              logoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _buildFallback(),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    if (!isSupported(logoKey)) {
      // logoUrl 로드도 실패했고 logoKey도 매칭 안 되는 경우 — 빈 상태로 둔다.
      return const SizedBox.shrink();
    }

    final IconData? icon = _icons[logoKey];
    final Widget glyph = icon != null
        ? Icon(icon, size: size * 0.55, color: AppColors.colorBgMain)
        : Text(
            _wonGlyph,
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w700,
              color: AppColors.colorBgMain,
            ),
          );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: _backgroundColor,
      child: glyph,
    );
  }
}
