class AccountListExtra {
  const AccountListExtra({
    this.divisionId,
    this.categoryId,
    this.categorySeq,
    this.memberId,
    this.date,
  });

  final String? divisionId;
  final String? categoryId;
  final String? categorySeq;
  final String? memberId;

  /// 'YYYYMMDD' — 특정 날짜만 필터링할 때 사용 (기존 strtDt/endDt와 동일 포맷)
  final String? date;

  static ({int year, int month}) parseDateYearMonth(String date) => (
        year: int.parse(date.substring(0, 4)),
        month: int.parse(date.substring(4, 6)),
      );
}
