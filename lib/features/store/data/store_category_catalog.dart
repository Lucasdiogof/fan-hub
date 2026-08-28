import 'package:flutter/material.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';

/// Taxonomia fixa de categorias/coleções da loja — estrutural, não dado de
/// catálogo (por isso Dart, não JSON: precisa de `IconData`, que não tem
/// como vir de JSON sem um mapeamento à parte). Mesmo padrão de
/// `ArenaCatalog.games`/`mainNavItems`: lista const, nunca hardcoded
/// dentro de um widget. A UI decide sozinha quais entram na tela, sempre
/// filtrando pelas que têm pelo menos um produto (ver `StoreCatalogCubit`)
/// — a lista aqui é só o vocabulário completo, não o que está "ativo".
class StoreCategoryCatalog {
  const StoreCategoryCatalog._();

  static const mainCategories = <StoreCategory>[
    StoreCategory(
      id: 'launches',
      name: 'Lançamentos',
      icon: Icons.auto_awesome_rounded,
    ),
    StoreCategory(
      id: 'uniforms',
      name: 'Uniformes',
      icon: Icons.checkroom_rounded,
    ),
    StoreCategory(id: 'masculine', name: 'Masculino', icon: Icons.man_rounded),
    StoreCategory(id: 'feminine', name: 'Feminino', icon: Icons.woman_rounded),
    StoreCategory(id: 'kids', name: 'Infantil', icon: Icons.child_care_rounded),
    StoreCategory(
      id: 'training',
      name: 'Treino',
      icon: Icons.fitness_center_rounded,
    ),
    StoreCategory(
      id: 'personalizable',
      name: 'Personalizáveis',
      icon: Icons.edit_rounded,
    ),
    StoreCategory(
      id: 'accessories',
      name: 'Acessórios',
      icon: Icons.style_rounded,
    ),
    StoreCategory(
      id: 'souvenirs',
      name: 'Souvenires',
      icon: Icons.redeem_rounded,
    ),
  ];

  static const collections = <StoreCategory>[
    StoreCategory(
      id: 'kit_01',
      name: 'Uniforme 01',
      icon: Icons.shield_rounded,
      isCollection: true,
    ),
    StoreCategory(
      id: 'kit_02',
      name: 'Uniforme 02',
      icon: Icons.shield_rounded,
      isCollection: true,
    ),
    StoreCategory(
      id: 'kit_03',
      name: 'Uniforme 03',
      icon: Icons.shield_rounded,
      isCollection: true,
    ),
    StoreCategory(
      id: 'goalkeeper',
      name: 'Goleiro',
      icon: Icons.sports_handball_rounded,
      isCollection: true,
    ),
    StoreCategory(
      id: 'fan',
      name: 'Torcedor',
      icon: Icons.favorite_rounded,
      isCollection: true,
    ),
    StoreCategory(
      id: 'player',
      name: 'Jogador',
      icon: Icons.military_tech_rounded,
      isCollection: true,
    ),
    StoreCategory(
      id: 'casual',
      name: 'Casual',
      icon: Icons.weekend_rounded,
      isCollection: true,
    ),
    StoreCategory(
      id: 'training_travel',
      name: 'Treino, viagem e concentração',
      icon: Icons.luggage_rounded,
      isCollection: true,
    ),
    StoreCategory(
      id: 'socks_gloves',
      name: 'Meias e luvas',
      icon: Icons.back_hand_rounded,
      isCollection: true,
    ),
  ];

  static const all = [...mainCategories, ...collections];

  static StoreCategory? byId(String id) {
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }
}
