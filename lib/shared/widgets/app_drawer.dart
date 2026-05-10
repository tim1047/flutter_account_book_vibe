import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: AppColors.colorBgSub,
      elevation: 0,
      child: Column(
        children: [
          _DrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _NavTile(
                  emoji: '🏠',
                  label: '가계부 홈',
                  path: '/',
                  currentPath: currentPath,
                ),
                _NavTile(
                  emoji: '📋',
                  label: '가계부 목록',
                  path: '/accountList',
                  currentPath: currentPath,
                ),
                _NavTile(
                  emoji: '💡',
                  label: '인사이트',
                  path: '/insight',
                  currentPath: currentPath,
                ),
                _AccordionSection(
                  emoji: '🛒',
                  label: '지출',
                  currentPath: currentPath,
                  children: [
                    _SubTile(
                      emoji: '🛒',
                      label: '지출',
                      path: '/expense',
                      currentPath: currentPath,
                    ),
                    _SubTile(
                      emoji: '📊',
                      label: '지출 상세',
                      path: '/expenseDtl',
                      currentPath: currentPath,
                    ),
                    _SubTile(
                      emoji: '👤',
                      label: '주체별 지출',
                      path: '/expense/member',
                      currentPath: currentPath,
                    ),
                    _SubTile(
                      emoji: '📈',
                      label: '지출 추이',
                      path: '/expense/chart',
                      currentPath: currentPath,
                    ),
                    _SubTile(
                      emoji: '📅',
                      label: '일별 지출 추이',
                      path: '/expense/dailyChart',
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _AccordionSection(
                  emoji: '💰',
                  label: '수입',
                  currentPath: currentPath,
                  children: [
                    _SubTile(
                      emoji: '💰',
                      label: '수입',
                      path: '/income',
                      currentPath: currentPath,
                    ),
                    _SubTile(
                      emoji: '📈',
                      label: '수입 추이',
                      path: '/income/chart',
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _AccordionSection(
                  emoji: '📈',
                  label: '투자',
                  currentPath: currentPath,
                  children: [
                    _SubTile(
                      emoji: '🏦',
                      label: '투자',
                      path: '/invest',
                      currentPath: currentPath,
                    ),
                    _SubTile(
                      emoji: '📊',
                      label: '투자 추이',
                      path: '/invest/chart',
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _AccordionSection(
                  emoji: '🏢',
                  label: '자산',
                  currentPath: currentPath,
                  children: [
                    _SubTile(
                      emoji: '🏢',
                      label: '자산',
                      path: '/asset',
                      currentPath: currentPath,
                    ),
                    _SubTile(
                      emoji: '🥧',
                      label: '자산 비율',
                      path: '/asset/chart',
                      currentPath: currentPath,
                    ),
                    _SubTile(
                      emoji: '📊',
                      label: '자산 추이',
                      path: '/asset/accum',
                      currentPath: currentPath,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: DrawerHeader(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/drawer.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.colorBgCard,
                child: const Center(
                  child: Text('🧡', style: TextStyle(fontSize: 48)),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.drawerHeaderOverlay,
              ),
            ),
            const Positioned(
              left: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '강원 🧡 정윤 가계부',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '함께 만드는 우리의 기록',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.emoji,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  final String emoji;
  final String label;
  final String path;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path;
    return _TileWrapper(
      isActive: isActive,
      onTap: () {
        Navigator.pop(context);
        if (!isActive) context.go(path);
      },
      child: Row(
        children: [
          if (isActive)
            Container(width: 3, height: 48, color: AppColors.colorAccentTeal)
          else
            const SizedBox(width: 3),
          Expanded(
            child: ListTile(
              leading: Text(emoji, style: const TextStyle(fontSize: 18)),
              title: Text(
                label,
                style: AppTextStyles.textBodyMd.copyWith(
                  color: isActive
                      ? AppColors.colorAccentTeal
                      : AppColors.colorTextSecondary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isActive,
              selectedTileColor: Colors.transparent,
              minVerticalPadding: 0,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              onTap: () {
                Navigator.pop(context);
                if (!isActive) context.go(path);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TileWrapper extends StatelessWidget {
  const _TileWrapper({
    required this.isActive,
    required this.child,
    required this.onTap,
  });

  final bool isActive;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: isActive
          ? const Color.fromRGBO(45, 212, 191, 0.08)
          : Colors.transparent,
      child: child,
    );
  }
}

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.emoji,
    required this.label,
    required this.currentPath,
    required this.children,
  });

  final String emoji;
  final String label;
  final String currentPath;
  final List<Widget> children;

  bool get _hasActiveChild =>
      children.whereType<_SubTile>().any((t) => currentPath == t.path);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: _hasActiveChild,
      iconColor: AppColors.colorAccentIndigo,
      collapsedIconColor: AppColors.colorAccentIndigo,
      collapsedBackgroundColor: Colors.transparent,
      backgroundColor: AppColors.colorBgCard,
      leading: Text(emoji, style: const TextStyle(fontSize: 18)),
      title: Text(
        label,
        style: AppTextStyles.textBodyMd.copyWith(
          color: _hasActiveChild
              ? AppColors.colorAccentTeal
              : AppColors.colorTextSecondary,
          fontWeight:
              _hasActiveChild ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      children: children,
    );
  }
}

class _SubTile extends StatelessWidget {
  const _SubTile({
    required this.emoji,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  final String emoji;
  final String label;
  final String path;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path;
    return Container(
      height: 48,
      color: isActive
          ? const Color.fromRGBO(45, 212, 191, 0.08)
          : Colors.transparent,
      child: Row(
        children: [
          if (isActive)
            Container(width: 3, height: 48, color: AppColors.colorAccentTeal)
          else
            const SizedBox(width: 3),
          Expanded(
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 44, right: 16),
              leading: Text(emoji, style: const TextStyle(fontSize: 15)),
              title: Text(
                label,
                style: AppTextStyles.textBodyMd.copyWith(
                  color: isActive
                      ? AppColors.colorAccentTeal
                      : AppColors.colorTextSecondary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isActive,
              selectedTileColor: Colors.transparent,
              minVerticalPadding: 0,
              onTap: () {
                Navigator.pop(context);
                if (!isActive) context.go(path);
              },
            ),
          ),
        ],
      ),
    );
  }
}
