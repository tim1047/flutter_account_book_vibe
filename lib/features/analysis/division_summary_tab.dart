import 'package:account_book_vibe/features/analysis/division_summary_content.dart';
import 'package:account_book_vibe/features/analysis/division_summary_data.dart';
import 'package:account_book_vibe/features/analysis/division_summary_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';

class DivisionSummaryTab extends StatelessWidget {
  const DivisionSummaryTab({
    super.key,
    required this.vm,
    required this.title,
    required this.accentColor,
    required this.heroGradient,
    this.onCategoryTap,
  });

  final DivisionSummaryViewModel vm;
  final String title;
  final Color accentColor;
  final Gradient heroGradient;
  final void Function(DivisionCategoryItem item)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (vm.errorMessage != null) {
          return ErrorView(message: vm.errorMessage!, onRetry: vm.load);
        }
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DivisionSummaryContent(
              data: data,
              title: title,
              accentColor: accentColor,
              heroGradient: heroGradient,
              onCategoryTap: onCategoryTap,
            ),
          ],
        );
      },
    );
  }
}
