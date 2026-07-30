import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/features/asset/asset_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_badge.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/app_list_card.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/asset_avatar.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssetListScreen extends StatefulWidget {
  final String? toastMessage;

  const AssetListScreen({super.key, this.toastMessage});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  late final AssetViewModel _vm;

  String get _todayDt {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _vm = AssetViewModel();
    _vm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.toastMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppToast.show(context, widget.toastMessage!);
      });
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _vm.refreshAssets(_todayDt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
                  onRetry: _onRefresh,
                );
              }
              final data = _vm.assetData;
              if (data == null) return const EmptyView();
              return _AssetBody(
                data: data,
                onRefresh: _onRefresh,
                onEdit: (item) async {
                  final result =
                      await context.push<String>('/myAsset', extra: item);
                  if (result != null && context.mounted) {
                    AppToast.show(context, result);
                    await _vm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
                  }
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: GradientFAB(
        heroTag: 'addAsset',
        icon: Icons.add,
        onPressed: () async {
          final result = await context.push<String>('/myAsset');
          if (result != null && context.mounted) {
            AppToast.show(context, result);
            await _vm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
          }
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _AssetBody extends StatelessWidget {
  const _AssetBody({
    required this.data,
    required this.onRefresh,
    required this.onEdit,
  });

  final MyAssetListResponse data;
  final Future<void> Function() onRefresh;
  final Future<void> Function(MyAssetItemResponse item) onEdit;

  @override
  Widget build(BuildContext context) {
    final groups = data.data.entries.toList();

    if (groups.isEmpty) {
      return Column(
        children: [
          _SummaryCard(data: data, onRefresh: onRefresh),
          const Expanded(child: EmptyView(message: '자산 데이터가 없습니다.')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SummaryCard(data: data, onRefresh: onRefresh);
        }
        final entry = groups[index - 1];
        return _AssetGroupSection(
          group: entry.value,
          onEdit: onEdit,
        );
      },
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, required this.onRefresh});

  final MyAssetListResponse data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorBgSub,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatCell(
                label: '총 자산',
                value: FormatUtil.formatPrice(data.totSumPrice),
                color: AppColors.colorIncome,
              ),
              _StatCell(
                label: '순자산',
                value: FormatUtil.formatPrice(data.totNetWorthSumPrice),
                color: AppColors.colorProfit,
              ),
              _StatCell(
                label: '현금성',
                value: FormatUtil.formatPrice(data.totCashableSumPrice),
                color: AppColors.colorTextPrimary,
              ),
              GestureDetector(
                onTap: onRefresh,
                child: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.colorTextSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.colorDivider),
          Row(
            children: [
              _StatCell(
                label: 'USD/KRW',
                value: FormatUtil.formatPrice(data.usdKrwRate),
                color: AppColors.colorTextPrimary,
              ),
              _StatCell(
                label: 'JPY/KRW',
                value: FormatUtil.formatPrice(data.jpyKrwRate),
                color: AppColors.colorTextPrimary,
              ),
              _StatCell(
                label: '기준일',
                value: data.myAssetAccumDts,
                color: AppColors.colorTextSecondary,
              ),
              const SizedBox(width: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.textBodySm.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.textBodyLg.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Asset Group Section ───────────────────────────────────────────────────────

class _AssetGroupSection extends StatelessWidget {
  const _AssetGroupSection({
    required this.group,
    required this.onEdit,
  });

  final MyAssetGroupResponse group;
  final Future<void> Function(MyAssetItemResponse item) onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  group.assetNm,
                  style: AppTextStyles.textLabelSm.copyWith(
                    color: AppColors.colorTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${FormatUtil.formatPrice(group.assetTotSumPrice)}원',
                  style: AppTextStyles.textLabelSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorAccentTeal,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          ...group.items.map(
            (item) => _AssetItemTile(item: item, onTap: () => onEdit(item)),
          ),
          ...group.subGroups.map(
            (sub) => _AssetSubGroupSection(subGroup: sub, onEdit: onEdit),
          ),
        ],
      ),
    );
  }
}

// ── Asset Sub-Group Section ───────────────────────────────────────────────────

class _AssetSubGroupSection extends StatelessWidget {
  const _AssetSubGroupSection({
    required this.subGroup,
    required this.onEdit,
  });

  final MyAssetSubGroupResponse subGroup;
  final Future<void> Function(MyAssetItemResponse item) onEdit;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        minTileHeight: 36,
        leading: const Icon(
          Icons.folder_outlined,
          size: 13,
          color: AppColors.colorTextDisabled,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                subGroup.myAssetGroupNm,
                style: AppTextStyles.textTitleSm.copyWith(
                  color: AppColors.colorTextDisabled,
                ),
              ),
            ),
            Text(
              '${FormatUtil.formatPrice(subGroup.sumPrice)}원',
              style: AppTextStyles.textTitleSm.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.colorTextDisabled,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        children: subGroup.items
            .map(
                (item) => _AssetItemTile(item: item, onTap: () => onEdit(item)))
            .toList(),
      ),
    );
  }
}

// ── Asset Item Tile ───────────────────────────────────────────────────────────

class _AssetItemTile extends StatelessWidget {
  const _AssetItemTile({required this.item, required this.onTap});

  final MyAssetItemResponse item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCashable = item.cashableYn == 'Y';
    final qtyStr = item.qty == item.qty.roundToDouble()
        ? item.qty.toInt().toString()
        : item.qty.toStringAsFixed(4);
    final hasLogo = (item.logoUrl != null && item.logoUrl!.isNotEmpty) ||
        AssetAvatar.isSupported(item.logoKey);

    return AppListCard(
      leading: hasLogo
          ? AssetAvatar(
              logoUrl: item.logoUrl,
              logoKey: item.logoKey,
              size: 28,
            )
          : null,
      title: Text(
        item.myAssetNm,
        style: AppTextStyles.textHeadlineSm,
      ),
      subtitle: Text(
        '$qtyStr개',
        style: AppTextStyles.textBodySm.copyWith(
          color: AppColors.colorTextSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCashable) ...[
            const AppBadge(type: BadgeType.cashable, label: '현금성'),
            const SizedBox(width: 6),
          ],
          Text(
            '${FormatUtil.formatPrice(item.sumPrice)}원',
            style: AppTextStyles.moneySmall,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
