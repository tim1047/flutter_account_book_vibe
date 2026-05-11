import 'package:account_book_vibe/features/dashboard/viewmodels/expense_viewmodel.dart';
import 'package:flutter/material.dart';

class ExpenseTab extends StatelessWidget {
  const ExpenseTab({super.key, required this.vm});
  final DashboardExpenseViewModel vm;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
