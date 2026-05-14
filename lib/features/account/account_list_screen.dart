import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/division.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/features/account/account_list_extra.dart';
import 'package:account_book_vibe/features/account/account_list_viewmodel.dart';
import 'package:account_book_vibe/shared/viewmodels/date_filter_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_badge.dart';
import 'package:account_book_vibe/shared/widgets/app_dialogs.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/date_filter_bar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key, this.extra});

  final AccountListExtra? extra;

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  late final AccountListViewModel _vm;
  late final DateFilterViewModel _dateFilter;
  final _scrollController = ScrollController();
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _dateFilter = DateFilterViewModel();
    _vm = AccountListViewModel();
    if (widget.extra != null) {
      _vm.setFilter(
        divisionId: widget.extra!.divisionId,
        categoryId: widget.extra!.categoryId,
        categorySeq: widget.extra!.categorySeq,
        memberId: widget.extra!.memberId,
      );
    }
    _load();
  }

  void _load() => _vm.load(_dateFilter.strtDt, _dateFilter.endDt);

  @override
  void dispose() {
    _vm.dispose();
    _dateFilter.dispose();
    _scrollController.dispose();
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
              _SortToggleBar(
                sortDescending: _sortDescending,
                onToggle: () =>
                    setState(() => _sortDescending = !_sortDescending),
              ),
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
                    if (_vm.grouped.isEmpty) {
                      return const EmptyView();
                    }
                    return _buildList();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmallFAB(
            heroTag: 'scrollTop',
            icon: Icons.keyboard_arrow_up,
            onPressed: () => _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
          const SizedBox(height: 8),
          GradientFAB(
            heroTag: 'addAccount',
            icon: Icons.add,
            onPressed: () async {
              final result = await context.push<String>('/account');
              if (!mounted) return;
              _load();
              if (result != null) {
                AppToast.show(context, '$result 완료!!!', type: ToastType.success);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final sortedDates = _vm.grouped.keys.toList()
      ..sort((a, b) => _sortDescending ? b.compareTo(a) : a.compareTo(b));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = _vm.grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateHeader(date: date),
            ...items.map(
              (item) => _AccountCard(
                item: item,
                onTap: () async {
                  final result =
                      await context.push<String>('/account', extra: item);
                  if (!mounted) return;
                  _load();
                  if (result != null) {
                    AppToast.show(
                      context,
                      '$result 완료!!!',
                      type:
                          result == '삭제' ? ToastType.info : ToastType.success,
                    );
                  }
                },
                onLongPress: () => _confirmDelete(item),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(AccountListResponse item) async {
    final confirmed = await AppAlertDialog.confirm(
      context,
      title: '삭제 확인',
      message: '정말 삭제하시겠습니까?',
      confirmText: '삭제',
    );
    if (!confirmed || !mounted) return;
    AppLoadingDialog.show(context);
    try {
      await _vm.deleteAccount(item.accountId);
      if (mounted) {
        AppLoadingDialog.hide(context);
        AppToast.show(context, '삭제 완료!!!', type: ToastType.info);
      }
    } on Exception catch (_) {
      if (mounted) {
        AppLoadingDialog.hide(context);
        AppToast.show(context, '삭제 실패', type: ToastType.error);
      }
    }
  }
}

// ── Sort Toggle Bar ───────────────────────────────────────────────────────────

class _SortToggleBar extends StatelessWidget {
  const _SortToggleBar({required this.sortDescending, required this.onToggle});

  final bool sortDescending;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        color: AppColors.colorBgSub,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14,
              color: AppColors.colorTextDisabled,
            ),
            const SizedBox(width: 2),
            Text(
              sortDescending ? '최신순' : '오래된순',
              style: AppTextStyles.textCaption.copyWith(
                color: AppColors.colorTextDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date Header ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.colorBgSub,
      child: Text(
        FormatUtil.formatDate(date),
        style: AppTextStyles.textLabelSm.copyWith(
          color: AppColors.colorTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  final AccountListResponse item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const _memberImages = {
    '강원': 'assets/images/kangwon.png',
    '정윤': 'assets/images/jungyoon.png',
    '아인': 'assets/images/ain.png',
    '함께': 'assets/images/family.png',
  };

  String? get _memberImagePath => _memberImages[item.memberNm];

  int get _memberIndex =>
      item.memberId.codeUnits.fold(0, (a, b) => a + b) %
      AppColors.memberColors.length;

  Color get _divisionColor =>
      AppColors.divisionColor[item.divisionId] ?? AppColors.colorTextSecondary;

  bool get _hasPoint => item.pointPrice > 0;
  bool get _isSeoulLove =>
      item.paymentNm.contains('서울사랑') || item.paymentType == 'SEOUL_LOVE';
  bool get _isFirstMeeting =>
      item.paymentNm.contains('첫만남') || item.paymentType == 'FIRST_MEETING';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: AppColors.colorBgSub,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                memberIndex: _memberIndex,
                imagePath: _memberImagePath,
                name: item.memberNm,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceRow(),
                    const SizedBox(height: 4),
                    _buildCategoryRow(),
                    const SizedBox(height: 6),
                    _buildBadgeRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pricePrefix(int price) =>
      item.divisionId == Division.expense ? '-' : '+';

  Widget _buildPriceRow() {
    final prefix = _pricePrefix(item.price);
    if (_hasPoint) {
      return Row(
        children: [
          Text(
            '${FormatUtil.formatPrice(item.price)}원',
            style: AppTextStyles.moneyStrikethrough,
          ),
          const SizedBox(width: 6),
          Text(
            '$prefix${FormatUtil.formatPrice(item.price - item.pointPrice)}원',
            style: AppTextStyles.moneySmall.copyWith(color: _divisionColor),
          ),
        ],
      );
    }
    return Text(
      '$prefix${FormatUtil.formatPrice(item.price)}원',
      style: AppTextStyles.moneySmall.copyWith(color: _divisionColor),
    );
  }

  Widget _buildCategoryRow() {
    final desc = FormatUtil.formatCategoryDesc(
        item.categoryNm, item.categorySeqNm, item.remark);
    return Text(
      desc,
      style: AppTextStyles.textBodySm.copyWith(
        color: AppColors.colorTextSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBadgeRow() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (_isSeoulLove)
          const AppBadge(type: BadgeType.seoulLove, label: '서울사랑'),
        if (_isFirstMeeting)
          const AppBadge(type: BadgeType.firstMeeting, label: '첫만남'),
        if (_hasPoint) const AppBadge(type: BadgeType.point, label: '포인트'),
        if (item.impulseYn == 'Y')
          const AppBadge(type: BadgeType.impulse, label: '충동'),
        _buildDivisionBadge(),
      ],
    );
  }

  Widget _buildDivisionBadge() {
    switch (item.divisionId) {
      case Division.income:
        return AppBadge(type: BadgeType.income, label: item.divisionNm);
      case Division.expense:
        return AppBadge(type: BadgeType.expense, label: item.divisionNm);
      case Division.invest:
        return AppBadge(type: BadgeType.invest, label: item.divisionNm);
      default:
        return _FallbackBadge(label: item.divisionNm, color: _divisionColor);
    }
  }
}

// ── Fallback Badge (알 수 없는 구분 처리용) ───────────────────────────────────

class _FallbackBadge extends StatelessWidget {
  const _FallbackBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color.fromRGBO(color.red, color.green, color.blue, 0.20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color: color,
        ),
      ),
    );
  }
}
