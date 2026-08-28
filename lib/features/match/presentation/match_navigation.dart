import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_cubit.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';

/// Abre a central da partida — mesmo fluxo usado pela aba Jogos e, agora,
/// pelo card de "ao vivo" da Home: busca os detalhes antes de navegar (pra
/// já abrir com dado, nunca com um loading vazio dentro da própria tela).
Future<void> openMatchDetails(BuildContext context, Match match) async {
  final cubit = MatchDetailsCubit(sl<FootballRepository>(), match.id);
  await GlobalLoading.run(context, cubit.load);
  if (!context.mounted) return;
  unawaited(context.push('/match/${match.id}', extra: cubit));
}
