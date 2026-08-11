import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_shadows.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/ai_report_model.dart';
import 'package:account_book_vibe/features/ai_report/ai_report_format.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';

/// 발행 카드가 그릴 수 있는 네 가지 상태.
enum PublishCardState { notPublished, running, done, failed }

/// 상태 응답과 전월 상세를 카드 상태 하나로 접는다.
///
/// `published:false, running:false` 조합만으로는 "한 번도 시도 안 함"과
/// "시도했다가 실패함"이 구분되지 않아서(API 스펙 §5.2) 상세 응답이 필요하다.
/// 상세가 null이면 서버에 행 자체가 없다는 뜻, 즉 미시도다.
///
/// 좁비(10분 초과 running) 판정은 서버가 조회 시점에 적용해 이미 `failed`로
/// 내려주므로 여기서 경과 시간을 계산하지 않는다.
PublishCardState resolvePublishCard(
  ReportStatusResponse status,
  ReportDetailResponse? detail,
) {
  if (status.published) return PublishCardState.done;
  if (status.running) return PublishCardState.running;
  if (detail?.status == 'failed') return PublishCardState.failed;
  return PublishCardState.notPublished;
}

/// 발행 가능 회차 하나를 다루는 카드. 상태에 따라 몸통과 버튼이 바뀐다.
class PublishCard extends StatelessWidget {
  const PublishCard({
    super.key,
    required this.state,
    required this.status,
    required this.failureReason,
    required this.isPublishing,
    required this.onPublish,
    required this.onOpenReport,
    required this.onOpenProfile,
  });

  final PublishCardState state;
  final ReportStatusResponse status;

  /// 실패 회차의 예외 타입명. 서버가 원본 데이터 유출을 막으려고 타입명만 준다.
  final String? failureReason;
  final bool isPublishing;
  final VoidCallback onPublish;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBgSub,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatPeriod(status.publishablePeriod)} 회차',
            style: AppTextStyles.textHeadlineSm.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _statusLine(),
          if (status.pendingQuestions.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _PendingQuestionsRow(
              questions: status.pendingQuestions,
              onTap: onOpenProfile,
            ),
          ],
          const SizedBox(height: 16),
          _actionButton(),
        ],
      ),
    );
  }

  Widget _statusLine() {
    final (String text, Color color) = switch (state) {
      PublishCardState.notPublished => ('아직 발행하지 않았어', AppColors.colorTextSecondary),
      PublishCardState.running => ('리포트를 만들고 있어', AppColors.colorAccentTeal),
      PublishCardState.done => ('발행 완료', AppColors.colorSuccess),
      PublishCardState.failed => (
          '지난번 생성이 실패했어${failureReason == null ? '' : ' ($failureReason)'}',
          AppColors.colorError,
        ),
    };

    return Row(
      children: [
        if (state == PublishCardState.running) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.colorAccentTeal,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.textBodyMd.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _actionButton() {
    if (state == PublishCardState.done) {
      return GradientButton(
        label: '리포트 보기',
        icon: Icons.article_outlined,
        onPressed: onOpenReport,
      );
    }

    if (state == PublishCardState.running) {
      // 서버가 백그라운드에서 만드는 중이고 완료 알림 채널이 없다.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientButton(
            label: '생성 중…',
            onPressed: null,
            enabled: false,
          ),
          const SizedBox(height: 8),
          Text(
            '몇 분 걸려. 다 되면 화면을 아래로 당겨서 새로고침해줘.',
            style: AppTextStyles.textBodyXs.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
        ],
      );
    }

    return GradientButton(
      label: state == PublishCardState.failed ? '다시 시도' : '리포트 발행하기',
      icon: Icons.auto_awesome,
      onPressed: isPublishing ? null : onPublish,
      enabled: !isPublishing,
    );
  }
}

class _PendingQuestionsRow extends StatelessWidget {
  const _PendingQuestionsRow({required this.questions, required this.onTap});

  final String questions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 질문은 서버가 주는 자유 텍스트(마크다운 목록 관례)라 줄 수만 센다.
    final count = questions
        .split('\n')
        .where((line) => line.trimLeft().startsWith('-'))
        .length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.colorHoverTeal,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.help_outline,
              size: 18,
              color: AppColors.colorAccentTeal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count > 0 ? 'AI가 물어본 게 $count개 있어' : 'AI가 물어본 게 있어',
                style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorAccentTeal,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.colorAccentTeal,
            ),
          ],
        ),
      ),
    );
  }
}
