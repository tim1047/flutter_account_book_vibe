import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:account_book_vibe/features/event/event_card.dart';
import 'package:account_book_vibe/features/event/event_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/year_month_picker_dialog.dart';
import 'package:flutter/material.dart';

const List<String> _weekdayLabels = <String>['월', '화', '수', '목', '금', '토', '일'];

/// 시간순 목록. 여러 날 일정은 시작일에 한 번만 나오고, 카드가 기간을 적는다.
class EventTimelineTab extends StatelessWidget {
  const EventTimelineTab({
    super.key,
    required this.vm,
    required this.onEditEvent,
  });

  final EventViewModel vm;
  final ValueChanged<EventListResponse> onEditEvent;

  Future<void> _pickMonth(BuildContext context) async {
    final selected = await YearMonthPickerDialog.show(
      context,
      year: vm.year,
      month: vm.month,
    );
    if (selected == null) return;
    vm.setMonth(selected.year, selected.month);
    vm.load();
  }

  void _shiftMonth(int delta) {
    final target = DateTime(vm.year, vm.month + delta);
    vm.setMonth(target.year, target.month);
    vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Column(
          children: [
            _MonthBar(
              year: vm.year,
              month: vm.month,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
              onTapTitle: () => _pickMonth(context),
            ),
            const Divider(height: 1, color: AppColors.colorDivider),
            Expanded(child: _buildBody()),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (vm.errorMessage != null) {
      return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
    }
    if (vm.isLoading && vm.timelineGroups.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.colorAccentTeal),
      );
    }
    if (vm.timelineGroups.isEmpty) {
      return const EmptyView(message: '등록된 일정이 없습니다.');
    }

    final groups = vm.timelineGroups;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateHeader(day: group.day),
            for (final event in group.events)
              _TimelineRow(
                event: event,
                onTap: () => onEditEvent(event),
              ),
          ],
        );
      },
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onTapTitle,
  });

  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left,
              color: AppColors.colorAccentTeal),
          onPressed: onPrev,
        ),
        GestureDetector(
          onTap: onTapTitle,
          child: Text('$year년 $month월', style: AppTextStyles.textHeadlineSm),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right,
              color: AppColors.colorAccentTeal),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.colorBgSub,
      child: Text(
        '${day.year}.${day.month.toString().padLeft(2, '0')}.'
        '${day.day.toString().padLeft(2, '0')} '
        '(${_weekdayLabels[day.weekday - 1]})',
        style: AppTextStyles.textLabelSm.copyWith(
          color: AppColors.colorTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.onTap});

  final EventListResponse event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                event.isAllDay ? '종일' : event.strtTm,
                textAlign: TextAlign.center,
                style: AppTextStyles.textBodySm.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24, child: _Rail()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: EventCard(event: event, onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 11,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: AppColors.colorDivider),
        ),
        Positioned(
          left: 6,
          top: 14,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.colorBgMain,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.colorAccentTeal, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
