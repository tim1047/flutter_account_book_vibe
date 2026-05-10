import 'package:json_annotation/json_annotation.dart';

part 'division_model.g.dart';

@JsonSerializable(createToJson: false)
class DivisionListResponse {
  const DivisionListResponse({
    required this.divisionId,
    required this.divisionNm,
  });

  final String divisionId;
  final String divisionNm;

  factory DivisionListResponse.fromJson(Map<String, dynamic> json) =>
      _$DivisionListResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class DivisionSumResponse {
  const DivisionSumResponse({
    required this.income,
    required this.interest,
    required this.expense,
    required this.invest,
    required this.investRate,
  });

  final int income;
  final int interest;
  final int expense;
  final int invest;
  final String investRate;

  factory DivisionSumResponse.fromJson(Map<String, dynamic> json) =>
      _$DivisionSumResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class SumGroupByMonthItem {
  const SumGroupByMonthItem({
    required this.divisionId,
    required this.divisionNm,
    required this.sumPrice,
    required this.month,
  });

  final String divisionId;
  final String divisionNm;
  final int sumPrice;
  final int month;

  factory SumGroupByMonthItem.fromJson(Map<String, dynamic> json) =>
      _$SumGroupByMonthItemFromJson(json);
}

@JsonSerializable(createToJson: false)
class SumGroupByMonthResponse {
  const SumGroupByMonthResponse({
    required this.avgSumPrice,
    required this.data,
  });

  final int avgSumPrice;
  final List<SumGroupByMonthItem> data;

  factory SumGroupByMonthResponse.fromJson(Map<String, dynamic> json) =>
      _$SumGroupByMonthResponseFromJson(json);
}

class DailyChartEntry {
  const DailyChartEntry({required this.day, required this.price});

  final int day;
  final int price;
}

class MonthDailyData {
  const MonthDailyData({
    required this.year,
    required this.month,
    required this.entries,
  });

  final int year;
  final int month;
  final List<DailyChartEntry> entries;
}
