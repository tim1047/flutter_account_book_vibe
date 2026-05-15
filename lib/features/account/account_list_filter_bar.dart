import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/member_images.dart';
import 'package:account_book_vibe/features/account/account_list_filter_state.dart';
import 'package:account_book_vibe/features/account/account_list_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

class AccountListFilterBar extends StatefulWidget {
  const AccountListFilterBar({
    super.key,
    required this.viewModel,
    required this.sortDescending,
    required this.onSortToggle,
  });

  final AccountListViewModel viewModel;
  final bool sortDescending;
  final VoidCallback onSortToggle;

  @override
  State<AccountListFilterBar> createState() => _AccountListFilterBarState();
}

class _AccountListFilterBarState extends State<AccountListFilterBar> {
  bool _expanded = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilter() {
    widget.viewModel.clearFilter();
    _searchController.clear();
  }

  void _onSearchChanged(String text) {
    widget.viewModel.updateFilter(
      widget.viewModel.filterState.copyWith(searchText: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final filterState = vm.filterState;
        final isActive = filterState.isActive;
        final activeCount = filterState.activeCount;
        final filterColor =
            isActive ? AppColors.colorAccentTeal : AppColors.colorTextDisabled;

        return Container(
          color: AppColors.colorBgSub,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggleBar(filterColor, activeCount, isActive),
              if (_expanded) _buildPanel(vm, filterState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleBar(Color filterColor, int activeCount, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, size: 14, color: filterColor),
                const SizedBox(width: 4),
                Text(
                  '상세 검색',
                  style:
                      AppTextStyles.textCaption.copyWith(color: filterColor),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  _ActiveBadge(count: activeCount),
                ],
              ],
            ),
          ),
          const Spacer(),
          if (_expanded && isActive) ...[
            GestureDetector(
              onTap: _clearFilter,
              child: Text(
                '초기화',
                style: AppTextStyles.textCaption.copyWith(
                  color: AppColors.colorError,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          GestureDetector(
            onTap: widget.onSortToggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.sortDescending
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 14,
                  color: AppColors.colorTextDisabled,
                ),
                const SizedBox(width: 2),
                Text(
                  widget.sortDescending ? '최신순' : '오래된순',
                  style: AppTextStyles.textCaption.copyWith(
                    color: AppColors.colorTextDisabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(AccountListViewModel vm, AccountFilterState filterState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: '카테고리, 메모 검색',
              hintStyle: AppTextStyles.textBodySm.copyWith(
                color: AppColors.colorTextDisabled,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.colorTextDisabled,
              ),
              filled: true,
              fillColor: AppColors.colorBgCard,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          const _SectionLabel(label: '구분'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vm.availableDivisions.map((div) {
              final selected = filterState.divisionIds.contains(div.id);
              final divColor = AppColors.divisionColor[div.id] ??
                  AppColors.colorTextSecondary;
              return _FilterChip(
                label: div.nm,
                selected: selected,
                selectedBg: Color.fromRGBO(
                    (divColor.r * 255.0).round().clamp(0, 255),
                    (divColor.g * 255.0).round().clamp(0, 255),
                    (divColor.b * 255.0).round().clamp(0, 255),
                    0.20),
                selectedText: divColor,
                onTap: () {
                  final ids = Set<String>.from(filterState.divisionIds);
                  selected ? ids.remove(div.id) : ids.add(div.id);
                  vm.updateFilter(filterState.copyWith(divisionIds: ids));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const _SectionLabel(label: '카테고리'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vm.availableCategories.map((cat) {
              final selected = filterState.categoryIds.contains(cat.id);
              return _FilterChip(
                label: cat.nm,
                selected: selected,
                selectedBg: const Color.fromRGBO(129, 140, 248, 0.20),
                selectedText: AppColors.colorAccentIndigo,
                onTap: () {
                  final ids = Set<String>.from(filterState.categoryIds);
                  selected ? ids.remove(cat.id) : ids.add(cat.id);
                  vm.updateFilter(filterState.copyWith(categoryIds: ids));
                },
              );
            }).toList(),
          ),
          if (vm.availableCategorySeqs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SectionLabel(label: '카테고리 상세'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: vm.availableCategorySeqs.map((seq) {
                final selected = filterState.categorySeqs.contains(seq.seq);
                return _FilterChip(
                  label: seq.nm,
                  selected: selected,
                  selectedBg: const Color.fromRGBO(129, 140, 248, 0.20),
                  selectedText: AppColors.colorAccentIndigo,
                  onTap: () {
                    final seqs = Set<String>.from(filterState.categorySeqs);
                    selected ? seqs.remove(seq.seq) : seqs.add(seq.seq);
                    vm.updateFilter(filterState.copyWith(categorySeqs: seqs));
                  },
                );
              }).toList(),
            ),
          ],
          if (vm.availableMembers.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SectionLabel(label: '멤버'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vm.availableMembers.map((member) {
                final selected = filterState.memberIds.contains(member.id);
                final memberIndex =
                    member.id.hashCode.abs() % AppColors.memberColors.length;
                final imagePath = MemberImages.paths[member.nm];
                return GestureDetector(
                  onTap: () {
                    final ids = Set<String>.from(filterState.memberIds);
                    selected ? ids.remove(member.id) : ids.add(member.id);
                    vm.updateFilter(filterState.copyWith(memberIds: ids));
                  },
                  child: Container(
                    decoration: selected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.colorAccentTeal,
                              width: 2,
                            ),
                          )
                        : null,
                    padding: selected
                        ? const EdgeInsets.all(2)
                        : EdgeInsets.zero,
                    child: UserAvatar(
                      memberIndex: memberIndex,
                      imagePath: imagePath,
                      name: member.nm,
                      size: 36,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.colorAccentTeal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.textBodySm.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.colorBgMain,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.textCaption.copyWith(
        color: AppColors.colorTextDisabled,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.selectedBg,
    required this.selectedText,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedBg;
  final Color selectedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? selectedBg : AppColors.colorBgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTextStyles.textCaption.copyWith(
            color:
                selected ? selectedText : AppColors.colorTextSecondary,
          ),
        ),
      ),
    );
  }
}
