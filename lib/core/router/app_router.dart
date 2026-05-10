import 'package:account_book_vibe/features/account/account_form_screen.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/account/account_list_screen.dart';
import 'package:account_book_vibe/features/asset/asset_accum_screen.dart';
import 'package:account_book_vibe/features/asset/asset_list_screen.dart';
import 'package:account_book_vibe/features/asset/asset_ratio_screen.dart';
import 'package:account_book_vibe/features/asset/my_asset_form_screen.dart';
import 'package:account_book_vibe/features/expense/expense_category_screen.dart';
import 'package:account_book_vibe/features/expense/expense_daily_chart_screen.dart';
import 'package:account_book_vibe/features/expense/expense_dtl_screen.dart';
import 'package:account_book_vibe/features/expense/expense_member_screen.dart';
import 'package:account_book_vibe/features/expense/expense_monthly_chart_screen.dart';
import 'package:account_book_vibe/features/home/home_screen.dart';
import 'package:account_book_vibe/features/income/income_category_screen.dart';
import 'package:account_book_vibe/features/income/income_monthly_chart_screen.dart';
import 'package:account_book_vibe/features/invest/invest_category_screen.dart';
import 'package:account_book_vibe/features/invest/invest_monthly_chart_screen.dart';
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
    GoRoute(
      path: '/',
      pageBuilder: (c, s) => _slidePage(const HomeScreen(), s),
    ),
    GoRoute(
      path: '/accountList',
      pageBuilder: (c, s) =>
          _slidePage(AccountListScreen(extra: s.extra as AccountListExtra?), s),
    ),
    GoRoute(
      path: '/account',
      pageBuilder: (c, s) => _slidePage(AccountFormScreen(extra: s.extra), s),
    ),
    GoRoute(
      path: '/expense',
      pageBuilder: (c, s) => _slidePage(const ExpenseCategoryScreen(), s),
    ),
    GoRoute(
      path: '/expenseDtl',
      pageBuilder: (c, s) => _slidePage(const ExpenseDtlScreen(), s),
    ),
    GoRoute(
      path: '/expense/member',
      pageBuilder: (c, s) => _slidePage(const ExpenseMemberScreen(), s),
    ),
    GoRoute(
      path: '/expense/chart',
      pageBuilder: (c, s) => _slidePage(const ExpenseMonthlyChartScreen(), s),
    ),
    GoRoute(
      path: '/expense/dailyChart',
      pageBuilder: (c, s) => _slidePage(const ExpenseDailyChartScreen(), s),
    ),
    GoRoute(
      path: '/income',
      pageBuilder: (c, s) => _slidePage(const IncomeCategoryScreen(), s),
    ),
    GoRoute(
      path: '/income/chart',
      pageBuilder: (c, s) => _slidePage(const IncomeMonthlyChartScreen(), s),
    ),
    GoRoute(
      path: '/invest',
      pageBuilder: (c, s) => _slidePage(const InvestCategoryScreen(), s),
    ),
    GoRoute(
      path: '/invest/chart',
      pageBuilder: (c, s) => _slidePage(const InvestMonthlyChartScreen(), s),
    ),
    GoRoute(
      path: '/asset',
      pageBuilder: (c, s) => _slidePage(const AssetListScreen(), s),
    ),
    GoRoute(
      path: '/myAsset',
      pageBuilder: (c, s) => _slidePage(MyAssetFormScreen(extra: s.extra), s),
    ),
    GoRoute(
      path: '/asset/chart',
      pageBuilder: (c, s) => _slidePage(const AssetRatioScreen(), s),
    ),
    GoRoute(
      path: '/asset/accum',
      pageBuilder: (c, s) => _slidePage(const AssetAccumScreen(), s),
    ),
  ],
);
