import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/features/asset/asset_list_body.dart';
import 'package:account_book_vibe/features/asset/asset_viewmodel.dart';
import 'package:account_book_vibe/features/dashboard/tabs/asset_tab.dart';
import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart' as dashboard;
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:account_book_vibe/shared/widgets/main_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssetHubScreen extends StatefulWidget {
  const AssetHubScreen({super.key});

  @override
  State<AssetHubScreen> createState() => _AssetHubScreenState();
}

class _AssetHubScreenState extends State<AssetHubScreen> with SingleTickerProviderStateMixin {
  late final dashboard.DashboardAssetViewModel _overviewVm;
  late final AssetViewModel _listVm;
  late final TabController _tabController;

  String get _todayDt {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _overviewVm = dashboard.DashboardAssetViewModel()..load();
    _listVm = AssetViewModel()..loadAssets(strtDt: _todayDt, endDt: _todayDt);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _overviewVm.dispose();
    _listVm.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _isListTab => _tabController.index == 1;

  Future<void> _refreshList() => _listVm.refreshAssets(_todayDt);

  Future<void> _editAsset(MyAssetItemResponse item) async {
    final navContext = context;
    final result = await navContext.push<String>('/myAsset', extra: item);
    if (result == null || !navContext.mounted) return;
    AppToast.show(navContext, result);
    // The asset branch is never disposed (indexedStack keeps every branch
    // mounted), so the 현황 overview tab must be explicitly reloaded here too
    // — otherwise it keeps showing pre-edit totals/composition/history
    // indefinitely.
    await Future.wait([
      _listVm.loadAssets(strtDt: _todayDt, endDt: _todayDt),
      _overviewVm.load(),
    ]);
  }

  Future<void> _addAsset() async {
    final navContext = context;
    final result = await navContext.push<String>('/myAsset');
    if (result == null || !navContext.mounted) return;
    AppToast.show(navContext, result);
    // See _editAsset: reload the overview viewmodel as well, not just the list.
    await Future.wait([
      _listVm.loadAssets(strtDt: _todayDt, endDt: _todayDt),
      _overviewVm.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBgMain,
      appBar: MainAppBar(
        showMenuButton: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.colorAccentTeal,
            labelColor: AppColors.colorAccentTeal,
            unselectedLabelColor: AppColors.colorTextSecondary,
            labelStyle: AppTextStyles.textBodySm.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.textBodySm,
            tabs: const [Tab(text: '현황'), Tab(text: '목록')],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AssetTab(vm: _overviewVm),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AssetListBody(vm: _listVm, onRefresh: _refreshList, onEdit: _editAsset),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _isListTab ? GradientFAB(heroTag: 'addAsset', icon: Icons.add, onPressed: _addAsset) : null,
    );
  }
}
