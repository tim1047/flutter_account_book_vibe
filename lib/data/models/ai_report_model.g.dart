// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportListItem _$ReportListItemFromJson(Map<String, dynamic> json) =>
    ReportListItem(
      period: json['period'] as String,
      headline: json['headline'] as String?,
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
    );

ReportStatusResponse _$ReportStatusResponseFromJson(
        Map<String, dynamic> json) =>
    ReportStatusResponse(
      publishablePeriod: json['publishablePeriod'] as String,
      published: json['published'] as bool,
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      pendingQuestions: json['pendingQuestions'] as String,
      running: json['running'] as bool,
    );

ReportDetailResponse _$ReportDetailResponseFromJson(
        Map<String, dynamic> json) =>
    ReportDetailResponse(
      period: json['period'] as String,
      status: json['status'] as String,
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      headline: json['headline'] as String?,
      metrics: (json['metrics'] as List<dynamic>?)
              ?.map((e) => MetricItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bodyMd: json['bodyMd'] as String?,
      action: json['action'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );

MetricItem _$MetricItemFromJson(Map<String, dynamic> json) => MetricItem(
      key: json['key'] as String,
      label: json['label'] as String,
      value: json['value'] as num,
      delta: json['delta'] as num,
      verdict: json['verdict'] as String,
      format: json['format'] as String,
    );

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    ProfileResponse(
      userConfirmed: json['userConfirmed'] as String,
      pendingQuestions: json['pendingQuestions'] as String,
      observations: json['observations'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
