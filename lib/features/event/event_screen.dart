import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:account_book_vibe/features/event/event_calendar_tab.dart';
import 'package:account_book_vibe/features/event/event_timeline_tab.dart';
import 'package:account_book_vibe/features/event/event_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 일정 탭. 캘린더·타임라인이 같은 [EventViewModel]을 보므로 한쪽에서 달을
/// 바꾸거나 일정을 고치면 다른 쪽도 같이 갱신된다.
class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen>
    with SingleTickerProviderStateMixin {
  late final EventViewModel _vm;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _vm = EventViewModel()..load();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _vm.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openForm([EventListResponse? event]) async {
    final result = await context.push<String>('/event', extra: event);
    if (!mounted) return;
    if (result == null) return;
    await _vm.load();
    if (!mounted) return;
    AppToast.show(
      context,
      '$result 완료!!!',
      type: result == '삭제' ? ToastType.info : ToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.colorAccentTeal,
            labelColor: AppColors.colorAccentTeal,
            unselectedLabelColor: AppColors.colorTextSecondary,
            labelStyle: AppTextStyles.textBodySm
                .copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.textBodySm,
            tabs: const [Tab(text: '캘린더'), Tab(text: '타임라인')],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EventCalendarTab(vm: _vm, onEditEvent: _openForm),
          EventTimelineTab(vm: _vm, onEditEvent: _openForm),
        ],
      ),
      // 두 탭 모두에서 항상 보이도록 TabBarView 바깥에 둔다.
      floatingActionButton: GradientFAB(
        heroTag: 'addEvent',
        icon: Icons.add,
        onPressed: _openForm,
      ),
    );
  }
}
