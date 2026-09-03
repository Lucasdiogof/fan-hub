import 'package:equatable/equatable.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';

enum ShippingSpeed { economy, standard, express }

enum FulfillmentMethod { delivery, pickup }

/// Uma opção de frete cotada — sempre vem do repository (mock hoje,
/// serviço real depois), nunca calculada no widget.
class ShippingOption extends Equatable {
  const ShippingOption({
    required this.speed,
    required this.label,
    required this.etaLabel,
    required this.price,
  });

  final ShippingSpeed speed;
  final String label;
  final String etaLabel;
  final double price;

  bool get isFree => price <= 0;

  Map<String, dynamic> toJson() => {
    'speed': speed.name,
    'label': label,
    'etaLabel': etaLabel,
    'price': price,
  };

  factory ShippingOption.fromJson(Map<String, dynamic> json) => ShippingOption(
    speed: ShippingSpeed.values.byName(json['speed'] as String),
    label: json['label'] as String,
    etaLabel: json['etaLabel'] as String,
    price: (json['price'] as num).toDouble(),
  );

  @override
  List<Object?> get props => [speed, label, etaLabel, price];
}

/// Endereço fixo da loja física do clube ativo — texto nunca inventado,
/// vem sempre de `ClubConfig.integrations.pickupAddress`, nunca hardcoded
/// aqui (ver `PickupInformation.forActiveClub`).
class PickupInformation extends Equatable {
  const PickupInformation({
    required this.storeName,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  factory PickupInformation.forActiveClub() {
    final pickup = sl<ClubConfig>().integrations.pickupAddress;
    return PickupInformation(
      storeName: pickup.storeName,
      street: pickup.street,
      neighborhood: pickup.neighborhood,
      city: pickup.city,
      state: pickup.state,
      zipCode: pickup.zipCode,
    );
  }

  final String storeName;
  final String street;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;

  String get fullAddress =>
      '$street — $neighborhood, $city - $state, CEP $zipCode';

  @override
  List<Object?> get props => [
    storeName,
    street,
    neighborhood,
    city,
    state,
    zipCode,
  ];
}
