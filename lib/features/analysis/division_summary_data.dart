class DivisionCategoryItem {
  const DivisionCategoryItem({
    required this.categoryId,
    required this.categoryNm,
    required this.amount,
    required this.ratio,
    this.prevPeriodAmount = 0,
  });

  final String categoryId;
  final String categoryNm;
  final int amount;
  final double ratio;
  final int prevPeriodAmount;

  double get changeRate {
    if (prevPeriodAmount == 0) return 0;
    return (amount - prevPeriodAmount) / prevPeriodAmount;
  }
}

class DivisionSummaryData {
  const DivisionSummaryData({
    required this.totalAmount,
    required this.prevPeriodAmount,
    required this.monthlyAmounts,
    required this.categoryBreakdown,
    required this.changeLabel,
    this.chartHighlightMonth,
  });

  final int totalAmount;
  final int prevPeriodAmount;
  final List<({String month, int amount})> monthlyAmounts;
  final List<DivisionCategoryItem> categoryBreakdown;
  final String changeLabel;
  final String? chartHighlightMonth;

  double get changeRate {
    if (prevPeriodAmount == 0) return 0;
    return (totalAmount - prevPeriodAmount) / prevPeriodAmount;
  }
}
