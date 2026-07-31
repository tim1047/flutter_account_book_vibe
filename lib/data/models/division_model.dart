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

@JsonSerializable(createToJson: false)
class DailyChartItem {
  const DailyChartItem({
    required this.dt,
    required this.dailyAmount,
    required this.cumulativeAmount,
  });

  final String dt;
  final int dailyAmount;
  final int cumulativeAmount;

  factory DailyChartItem.fromJson(Map<String, dynamic> json) =>
      _$DailyChartItemFromJson(json);
}

@JsonSerializable(createToJson: false)
class DailyChartResponse {
  const DailyChartResponse({
    required this.divisionId,
    required this.strtDt,
    required this.endDt,
    required this.items,
  });

  final String divisionId;
  final String strtDt;
  final String endDt;
  final List<DailyChartItem> items;

  factory DailyChartResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyChartResponseFromJson(json);
}
