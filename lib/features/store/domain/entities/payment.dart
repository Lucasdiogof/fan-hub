import 'package:equatable/equatable.dart';

enum PaymentMethod { pix, creditCard }

enum PaymentStatus { pending, approved, rejected, cancelled }

/// Resumo do cartão pra exibir no pedido — NUNCA guarda número completo,
/// CVV ou validade (ver `CheckoutCubit`/`CreditCardForm`, que descartam
/// esses campos assim que o resumo é montado).
class CardBillingSummary extends Equatable {
  const CardBillingSummary({
    required this.holderName,
    required this.lastFourDigits,
    required this.installments,
  });

  final String holderName;
  final String lastFourDigits;
  final int installments;

  Map<String, dynamic> toJson() => {
    'holderName': holderName,
    'lastFourDigits': lastFourDigits,
    'installments': installments,
  };

  factory CardBillingSummary.fromJson(Map<String, dynamic> json) =>
      CardBillingSummary(
        holderName: json['holderName'] as String,
        lastFourDigits: json['lastFourDigits'] as String,
        installments: json['installments'] as int,
      );

  @override
  List<Object?> get props => [holderName, lastFourDigits, installments];
}

class PaymentSimulation extends Equatable {
  const PaymentSimulation({
    required this.method,
    required this.status,
    this.cardSummary,
    required this.simulatedAt,
  });

  final PaymentMethod method;
  final PaymentStatus status;
  final CardBillingSummary? cardSummary;
  final DateTime simulatedAt;

  Map<String, dynamic> toJson() => {
    'method': method.name,
    'status': status.name,
    'cardSummary': cardSummary?.toJson(),
    'simulatedAt': simulatedAt.toIso8601String(),
  };

  factory PaymentSimulation.fromJson(Map<String, dynamic> json) =>
      PaymentSimulation(
        method: PaymentMethod.values.byName(json['method'] as String),
        status: PaymentStatus.values.byName(json['status'] as String),
        cardSummary: json['cardSummary'] != null
            ? CardBillingSummary.fromJson(
                json['cardSummary'] as Map<String, dynamic>,
              )
            : null,
        simulatedAt: DateTime.parse(json['simulatedAt'] as String),
      );

  @override
  List<Object?> get props => [method, status, cardSummary, simulatedAt];
}
