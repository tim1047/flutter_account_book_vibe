import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/features/ai_report/ai_home_viewmodel.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_format.dart';
import 'package:account_book_vibe/features/ai_report/publish_card.dart';
import 'package:account_book_vibe/shared/widgets/app_list_card.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AI 탭 루트. 발행 카드 하나 + 지난 리포트 목록.
class AiReportHomeScreen extends StatefulWidget {
  const AiReportHomeScreen({super.key});

  @override
  State<AiReportHomeScreen> createState() => _AiReportHomeScreenState();
}

class _AiReportHomeScreenState extends State<AiReportHomeScreen> {
  final _vm = AiHomeViewModel();

  @override
  void initState() {
    super.initState();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final failure = await _vm.publish();
    if (!mounted || failure == null) return;
    AppToast.show(context, failure, type: ToastType.error);
  }

  Future<void> _openProfile() async {
    await context.push('/aiProfile');
    // 프로필을 고치면 미답변 질문 표시가 달라질 수 있다.
    await _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '내 프로필',
            onPressed: _openProfile,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.colorAccentTeal),
            );
          }

          final status = _vm.status;
          if (_vm.errorMessage != null || status == null) {
            return ErrorView(
              message: _vm.errorMessage ?? '리포트 상태를 불러오지 못했습니다.',
              onRetry: _vm.load,
            );
          }

          return RefreshIndicator(
            color: AppColors.colorAccentTeal,
            backgroundColor: AppColors.colorBgSub,
            onRefresh: _vm.load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                PublishCard(
                  state: resolvePublishCard(status, _vm.publishableDetail),
                  status: status,
                  failureReason: _vm.publishableDetail?.errorMessage,
                  isPublishing: _vm.isPublishing,
                  onPublish: _publish,
                  onOpenReport: () =>
                      context.push('/aiReportDetail/${status.publishablePeriod}'),
                  onOpenProfile: _openProfile,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    '지난 리포트',
                    style: AppTextStyles.textTitleMd.copyWith(
                      color: AppColors.colorTextPrimary,
                    ),
                  ),
                ),
                if (_vm.reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyView(message: '아직 발행된 리포트가 없어.'),
                  )
                else
                  for (final report in _vm.reports)
                    _ReportRow(
                      report: report,
                      onTap: () =>
                          context.push('/aiReportDetail/${report.period}'),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onTap});

  final ReportListItem report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      onTap: onTap,
      title: Text(
        formatPeriod(report.period),
        style: AppTextStyles.textTitleSm.copyWith(
          color: AppColors.colorTextPrimary,
        ),
      ),
      subtitle: Text(
        report.headline ?? '요약 없음',
        style: AppTextStyles.textBodySm.copyWith(
          color: AppColors.colorTextSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.colorTextDisabled,
        size: 20,
      ),
    );
  }
}
