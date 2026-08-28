import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Categoria principal (Lançamentos, Uniformes, Masculino...) ou coleção
/// (Uniforme 01, Goleiro, Torcedor...) — mesma entidade, diferenciadas por
/// [isCollection]; uma tela de listagem trata as duas igual (filtra
/// produtos por id de categoria/coleção).
class StoreCategory extends Equatable {
  const StoreCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.isCollection = false,
  });

  final String id;
  final String name;
  final IconData icon;
  final bool isCollection;

  @override
  List<Object?> get props => [id, name, icon, isCollection];
}
