import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/category_emojis.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/features/asset/asset_ratio_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/empty_view.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:account_book_vibe/shared/widgets/progress_row.dart';
import 'package:flutter/material.dart';

class AssetRatioScreen extends StatefulWidget {
  const AssetRatioScreen({super.key});

  @override
  State<AssetRatioScreen> createState() => _AssetRatioScreenState();
}

class _AssetRatioScreenState extends State<AssetRatioScreen> {
  late final AssetRatioViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AssetRatioViewModel();
    _load();
  }

  void _load() => _vm.loadData();

  @override
  void dispose() {
    _vm.dispose();
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
                return ErrorView(message: _vm.errorMessage!, onRetry: _load);
              }
              final data = _vm.data;
              if (data == null || data.data.isEmpty) {
                return const EmptyView();
              }
              final groups = data.data.entries.toList();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index].value;
                  final color = AppColors.assetChartColors[
                      index % AppColors.assetChartColors.length];
                  return _AssetGroupRatioTile(
                    group: group,
                    totalPrice: data.totSumPrice,
                    color: color,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Group Ratio Tile ──────────────────────────────────────────────────────────

class _AssetGroupRatioTile extends StatelessWidget {
  const _AssetGroupRatioTile({
    required this.group,
    required this.totalPrice,
    required this.color,
  });

  final MyAssetGroupResponse group;
  final int totalPrice;
  final Color color;

  double get _groupPct =>
      FormatUtil.percentageOf(group.assetTotSumPrice, totalPrice) / 100;

  String get _groupPctStr => FormatUtil.formatPercentage(
        FormatUtil.percentageOf(group.assetTotSumPrice, totalPrice),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: AppColors.colorBgSub,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Text(
            CategoryEmojis.getEmoji(group.assetNm),
            style: const TextStyle(fontSize: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  group.assetNm,
                  style: const TextStyle(
                    color: AppColors.colorTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${FormatUtil.formatPrice(group.assetTotSumPrice)}원  $_groupPctStr',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: _groupPct,
                color: color,
                backgroundColor: AppColors.colorProgressTrack,
                minHeight: 4,
              ),
            ),
          ),
          children: group.allItems.map((item) {
            final itemPct = FormatUtil.percentageOf(
                  item.sumPrice, group.assetTotSumPrice) /
                100;
            final itemPctStr = FormatUtil.formatPercentage(
              FormatUtil.percentageOf(item.sumPrice, group.assetTotSumPrice),
            );
            return ProgressRow(
              emoji: CategoryEmojis.getEmoji(item.myAssetNm),
              label: item.myAssetNm,
              value: '${FormatUtil.formatPrice(item.sumPrice)}원 ($itemPctStr)',
              percentage: itemPct,
              color: color,
            );
          }).toList(),
        ),
      ),
    );
  }
}
