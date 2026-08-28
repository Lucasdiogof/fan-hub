import 'package:equatable/equatable.dart';

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

/// Endereço fixo da loja física — texto nunca inventado, vem só daqui.
class PickupInformation extends Equatable {
  const PickupInformation({
    this.storeName = 'Goiás Store',
    this.street = 'Av. 85, 3277',
    this.neighborhood = 'Setor Bela Vista',
    this.city = 'Goiânia',
    this.state = 'GO',
    this.zipCode = '74823-310',
  });

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
