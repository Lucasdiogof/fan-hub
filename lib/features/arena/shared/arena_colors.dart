import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';

class ArenaColors {
  const ArenaColors._();

  // O campo em si (grama/uniforme/bola) é sempre verde/branco/preto — realista,
  // universal, não é identidade do clube — fica const de propósito.
  static const goiasOutfield = Color(0xFF00521E);
  static const goiasShorts = Color(0xFFFFFFFF);
  static const goiasKeeper = Color(0xFFF3C218);
  // Nunca vermelho em nenhum componente do app — mesmo não usado hoje,
  // esse token fica âmbar/dourado pra não virar uma armadilha depois.
  static const opponentOutfield = Color(0xFFC79A3D);
  static const opponentKeeper = Color(0xFF15181B);
  static const skin = Color(0xFFE7B48B);

  // O FUNDO/degradê do "estádio" por trás dos minigames (Quiz, Perfil de
  // Jogador, Identidade Futebolística, cards da Arena) já foi verde fixo do
  // Goiás — resolvido pelo clube ativo agora (sempre a paleta ESCURA,
  // independente do tema claro/escuro do app em si, mesmo raciocínio do
  // fundo sempre-escuro do login). Pro Goiás, `brandDark`/`brandDeep` são
  // essencialmente os mesmos verdes de sempre (diferença de shade
  // imperceptível); pro Bragantino vira o azul-marinho da identidade dele,
  // nunca o verde herdado.
  static Color get arenaTop => sl<ClubConfig>().branding.dark.brandDark;
  static Color get arenaBottom => sl<ClubConfig>().branding.dark.brandDeep;

  static const pitch = Color(0xFF2E8B4E);
  static const pitchDark = Color(0xFF247A41);
  static const pitchLine = Color(0xFFEAF3EC);
  static const ball = Color(0xFFFFFFFF);
  static const ballShade = Color(0xFF1B1F22);
}
