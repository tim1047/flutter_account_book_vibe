class AccountListExtra {
  const AccountListExtra({
    this.divisionId,
    this.categoryId,
    this.categorySeq,
    this.memberId,
    this.date,
    this.year,
    this.month,
  });

  final String? divisionId;
  final String? categoryId;
  final String? categorySeq;
  final String? memberId;

  /// 'YYYYMMDD' — 특정 날짜 하루만 필터링할 때 사용 (기존 strtDt/endDt와 동일 포맷)
  final String? date;

  /// [month]와 함께 특정 월 전체를 필터링할 때 사용 (예: 대시보드 카드 클릭 이동)
  final int? year;
  final int? month;

  static ({int year, int month}) parseDateYearMonth(String date) => (
        year: int.parse(date.substring(0, 4)),
        month: int.parse(date.substring(4, 6)),
      );
}
