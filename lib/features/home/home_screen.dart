import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/features/home/home_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _dateFilter = DateFilterViewModel();
    _vm = HomeViewModel();
    _load();
  }

  void _load() => _vm.load(_dateFilter.strtDt, _dateFilter.endDt);

  @override
  void dispose() {
    _vm.dispose();
    _dateFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              DateFilterBar(viewModel: _dateFilter, onRefresh: _load),
              Expanded(
                child: ListenableBuilder(
                  listenable: _vm,
                  builder: (context, _) {
                    if (_vm.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.colorAccentTeal,
                        ),
                      );
                    }
                    if (_vm.errorMessage != null) {
                      return ErrorView(
                        message: _vm.errorMessage!,
                        onRetry: _load,
                      );
                    }
                    return _buildCards(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    final d = _vm.data;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        SummaryCard(
          emoji: '💰',
          value: '${FormatUtil.formatPrice(d?.income ?? 0)}원',
          label: '소득',
          color: AppColors.colorIncome,
          onTap: () => context.go('/income'),
        ),
        const SizedBox(height: 8),
        SummaryCard(
          emoji: '🛒',
          value: '${FormatUtil.formatPrice(d?.expense ?? 0)}원',
          label: '지출',
          color: AppColors.colorExpense,
          onTap: () => context.go('/expense'),
        ),
        const SizedBox(height: 8),
        SummaryCard(
          emoji: '📈',
          value: '${FormatUtil.formatPrice(d?.invest ?? 0)}원',
          label: '투자',
          color: AppColors.colorInvest,
          onTap: () => context.go('/invest'),
        ),
        const SizedBox(height: 8),
        SummaryCard(
          emoji: '👛',
          value: '${FormatUtil.formatPrice(d?.interest ?? 0)}원',
          label: '순수익 (수입-지출)',
          color: AppColors.colorProfit,
        ),
        const SizedBox(height: 8),
        SummaryCard(
          emoji: '%',
          value: d?.investRate ?? '0',
          label: '투자율',
          color: AppColors.colorRate,
          onTap: () => context.go('/invest/chart'),
        ),
      ],
    );
  }
}
