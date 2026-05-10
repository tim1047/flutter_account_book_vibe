import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

@JsonSerializable(createToJson: false)
class PaymentListResponse {
  const PaymentListResponse({
    required this.paymentId,
    required this.paymentNm,
  });

  final String paymentId;
  final String paymentNm;

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentListResponseFromJson(json);
}
