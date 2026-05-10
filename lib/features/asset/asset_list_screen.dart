import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/features/asset/asset_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
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
                value:
                    FormatUtil.formatPrice(data.totCashableSumPrice),
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
                value: (data.jpyKrwRate * 100).toStringAsFixed(2),
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
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  group.assetNm,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${FormatUtil.formatPrice(group.assetTotSumPrice)}원',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.colorAccentTeal,
                    fontFeatures: [FontFeature.tabularFigures()],
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 2),
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.colorTextDisabled,
                ),
              ),
            ),
            Text(
              '${FormatUtil.formatPrice(subGroup.sumPrice)}원',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.colorTextDisabled,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        children: subGroup.items
            .map((item) => _AssetItemTile(item: item, onTap: () => onEdit(item)))
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.colorBgSub,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.myAssetNm,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colorTextPrimary,
                          ),
                        ),
                      ),
                      if (isCashable)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(250, 204, 21, 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '현금성',
                            style: TextStyle(
                              color: AppColors.colorRate,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$qtyStr개',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.colorTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${FormatUtil.formatPrice(item.sumPrice)}원',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.colorTextPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
