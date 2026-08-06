import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/features/asset/asset_list_body.dart';
import 'package:account_book_vibe/features/asset/asset_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_drawer.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
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

  Future<void> _onEdit(MyAssetItemResponse item) async {
    final navContext = context;
    final result = await navContext.push<String>('/myAsset', extra: item);
    if (result == null || !navContext.mounted) return;
    AppToast.show(navContext, result);
    await _vm.loadAssets(strtDt: _todayDt, endDt: _todayDt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AssetListBody(vm: _vm, onRefresh: _onRefresh, onEdit: _onEdit),
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
