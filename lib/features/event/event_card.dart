import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_shadows.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/event_type.dart';
import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:flutter/material.dart';

/// 일정 1건 카드. 타임라인과 캘린더 날짜 시트가 같이 쓴다.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final EventListResponse event;
  final VoidCallback onTap;

  /// 기간·시각을 한 줄로. 종일 하루짜리면 굳이 보여줄 게 없어 빈 문자열.
  String get _rangeLabel {
    final parts = <String>[];
    if (event.isMultiDay) {
      parts.add('${_md(event.startDate)} ~ ${_md(event.endDate)}');
    }
    if (!event.isAllDay) {
      parts.add('${event.strtTm} ~ ${event.endTm}');
    }
    return parts.join('  ');
  }

  static String _md(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = EventType.colorOf(event.eventTypeCd);
    final range = _rangeLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.colorBgCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.eventNm,
                                  style: AppTextStyles.textHeadlineSm,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _TypeChip(code: event.eventTypeCd),
                            ],
                          ),
                          if (range.isNotEmpty || event.memberNm.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              <String>[
                                if (range.isNotEmpty) range,
                                if (event.memberNm.isNotEmpty) event.memberNm,
                              ].join('  ·  '),
                              style: AppTextStyles.textBodySm.copyWith(
                                color: AppColors.colorTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (event.contents.isNotEmpty) ...[
              const Divider(height: 1, color: AppColors.colorDivider),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Text(
                  event.contents,
                  style: AppTextStyles.textBodyLg.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final color = EventType.colorOf(code);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        EventType.nameOf(code),
        style: AppTextStyles.textLabelSm.copyWith(color: color),
      ),
    );
  }
}
