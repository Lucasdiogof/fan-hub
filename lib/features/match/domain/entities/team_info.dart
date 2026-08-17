import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TeamInfo extends Equatable {
  const TeamInfo({
    required this.name,
    required this.shortName,
    required this.color,
  });

  final String name;
  final String shortName;
  final Color color;

  @override
  List<Object?> get props => [name, shortName, color];
}
