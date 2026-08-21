import 'package:account_book_vibe/features/account/account_form_screen.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/account/account_list_screen.dart';
import 'package:account_book_vibe/features/ai_report/ai_profile_screen.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_detail_screen.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_home_screen.dart';
import 'package:account_book_vibe/features/analysis/analysis_screen.dart';
import 'package:account_book_vibe/features/asset/asset_hub_screen.dart';
import 'package:account_book_vibe/features/asset/my_asset_form_screen.dart';
import 'package:account_book_vibe/features/event/event_form_screen.dart';
import 'package:account_book_vibe/features/event/event_screen.dart';
import 'package:account_book_vibe/features/home/home_screen.dart';
import 'package:account_book_vibe/features/shell/main_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Page<T> _slidePage<T>(Widget child, GoRouterState state) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          MainShellScreen(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            pageBuilder: (c, s) => _slidePage(const HomeScreen(), s),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/accountList',
            pageBuilder: (c, s) => _slidePage(
                AccountListScreen(extra: s.extra as AccountListExtra?), s),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/analysis',
            pageBuilder: (c, s) => _slidePage(const AnalysisScreen(), s),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/asset',
            pageBuilder: (c, s) => _slidePage(const AssetHubScreen(), s),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/aiReport',
            pageBuilder: (c, s) => _slidePage(const AiReportHomeScreen(), s),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/eventList',
            pageBuilder: (c, s) => _slidePage(const EventScreen(), s),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/account',
      pageBuilder: (c, s) => _slidePage(AccountFormScreen(extra: s.extra), s),
    ),
    GoRoute(
      path: '/event',
      pageBuilder: (c, s) => _slidePage(EventFormScreen(extra: s.extra), s),
    ),
    GoRoute(
      path: '/myAsset',
      pageBuilder: (c, s) => _slidePage(MyAssetFormScreen(extra: s.extra), s),
    ),
    GoRoute(
      path: '/aiReportDetail/:period',
      pageBuilder: (c, s) => _slidePage(
        AiReportDetailScreen(period: s.pathParameters['period']!),
        s,
      ),
    ),
    GoRoute(
      path: '/aiProfile',
      pageBuilder: (c, s) => _slidePage(const AiProfileScreen(), s),
    ),
  ],
);
