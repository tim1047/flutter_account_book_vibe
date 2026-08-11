import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/network/app_exception.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/data/services/ai_report_service.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_format.dart';
import 'package:account_book_vibe/features/ai_report/metric_grid.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// 발행 완료된 회차 하나를 읽는 화면.
///
/// 발행이 끝난 리포트는 서버에서 스냅샷으로 굳어 변하지 않으므로 뷰모델 없이
/// [FutureBuilder]로 한 번만 읽는다.
class AiReportDetailScreen extends StatefulWidget {
  const AiReportDetailScreen({super.key, required this.period});

  final String period;

  @override
  State<AiReportDetailScreen> createState() => _AiReportDetailScreenState();
}

class _AiReportDetailScreenState extends State<AiReportDetailScreen> {
  late Future<ReportDetailResponse?> _future = _load();

  Future<ReportDetailResponse?> _load() =>
      AiReportService.instance.getReport(widget.period);

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: AppBar(
        backgroundColor: AppColors.colorBgMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.colorTextPrimary),
        title: Text(
          '${formatPeriod(widget.period)} 리포트',
          style: AppTextStyles.textHeadlineSm.copyWith(
            color: AppColors.colorTextPrimary,
          ),
        ),
      ),
      body: FutureBuilder<ReportDetailResponse?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.colorAccentTeal),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorView(
              message: error is AppException
                  ? error.message
                  : '리포트를 불러오지 못했습니다.',
              onRetry: _retry,
            );
          }

          final report = snapshot.data;
          // 목록과 서버 상태가 어긋난 경우의 방어. 정상 경로에서는 안 온다.
          if (report == null) {
            return const EmptyView(message: '이 회차 리포트가 없어.');
          }
          if (report.status != 'done') {
            return const EmptyView(message: '아직 발행이 끝나지 않았어.');
          }

          return _ReportBody(report: report);
        },
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final ReportDetailResponse report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (report.headline != null)
          Text(
            report.headline!,
            style: AppTextStyles.textHeadlineLg.copyWith(
              color: AppColors.colorTextPrimary,
              height: 1.4,
            ),
          ),
        const SizedBox(height: 20),
        MetricGrid(metrics: report.metrics),
        const SizedBox(height: 24),
        if (report.bodyMd != null)
          MarkdownBody(
            data: report.bodyMd!,
            styleSheet: _markdownStyle(),
          ),
        if (report.action != null) ...[
          const SizedBox(height: 24),
          _ActionBox(action: report.action!),
        ],
      ],
    );
  }

  /// 마크다운 본문을 앱 타이포/색에 맞춘다. 섹션 구성이 회차마다 달라지므로
  /// 특정 제목을 가정하지 않고 레벨별 스타일만 정의한다.
  MarkdownStyleSheet _markdownStyle() => MarkdownStyleSheet(
        p: AppTextStyles.textBodyLg.copyWith(
          color: AppColors.colorTextPrimary,
          height: 1.7,
        ),
        h1: AppTextStyles.textHeadlineMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        h2: AppTextStyles.textHeadlineSm.copyWith(
          color: AppColors.colorAccentTeal,
        ),
        h3: AppTextStyles.textTitleMd.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        listBullet: AppTextStyles.textBodyLg.copyWith(
          color: AppColors.colorTextSecondary,
        ),
        strong: AppTextStyles.textBodyLg.copyWith(
          color: AppColors.colorTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        blockquote: AppTextStyles.textBodyMd.copyWith(
          color: AppColors.colorTextSecondary,
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.colorBgSub,
          borderRadius: BorderRadius.circular(8),
        ),
        code: AppTextStyles.textBodySm.copyWith(
          color: AppColors.colorAccentTeal,
          backgroundColor: AppColors.colorBgCard,
        ),
        tableBody: AppTextStyles.textBodySm.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        tableBorder: TableBorder.all(color: AppColors.colorDivider),
        h2Padding: const EdgeInsets.only(top: 20, bottom: 4),
        h3Padding: const EdgeInsets.only(top: 12, bottom: 4),
      );
}

class _ActionBox extends StatelessWidget {
  const _ActionBox({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorHoverTeal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorAccentTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppColors.colorAccentTeal,
              ),
              const SizedBox(width: 6),
              Text(
                '이번 달에 할 일',
                style: AppTextStyles.textLabelMd.copyWith(
                  color: AppColors.colorAccentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action,
            style: AppTextStyles.textBodyLg.copyWith(
              color: AppColors.colorTextPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
