import 'package:account_book_vibe/features/dashboard/viewmodels/asset_viewmodel.dart';
import 'package:flutter/material.dart';

class AssetTab extends StatelessWidget {
  const AssetTab({super.key, required this.vm});
  final DashboardAssetViewModel vm;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
