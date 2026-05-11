// lib/features/insight/insight_screen.dart
import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/insight/insight_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/category_anomaly_card.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/transaction_anomaly_card.dart';
import 'package:flutter/material.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  late final InsightViewModel _vm;
  late final DateFilterViewModel _dateFilter;

  @override
  void initState() {
    super.initState();
    _dateFilter = DateFilterViewModel(); // 싱글턴 반환
    _vm = InsightViewModel();
    _load();
  }

  void _load() => _vm.load(_dateFilter.selectedYear, _dateFilter.selectedMonth);

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
                    return _buildBody();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _SectionHeader(
          title: '📊 카테고리 이상 감지',
          subtitle: '최근 3개월 평균 대비',
        ),
        if (_vm.categoryAnomalies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: EmptyView(message: '이번 달은 이상 지출이 없어요 👍'),
          )
        else
          ..._vm.categoryAnomalies
              .map((item) => CategoryAnomalyCard(item: item)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Divider(color: AppColors.colorDivider),
        ),
        const _SectionHeader(
          title: '🔍 단일 이상 거래 TOP 10',
          subtitle: '카테고리 평균 단가 대비',
        ),
        if (_vm.transactionAnomalies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: EmptyView(message: '이번 달은 이상 거래가 없어요 👍'),
          )
        else
          ..._vm.transactionAnomalies
              .map((item) => TransactionAnomalyCard(item: item)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.textBodyLg.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.colorTextPrimary,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
