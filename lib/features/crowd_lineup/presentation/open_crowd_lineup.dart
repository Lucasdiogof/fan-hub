import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';

/// Carrega a escalação salva do usuário ANTES de navegar, pra "Escalação da
/// Torcida" já abrir com jogadores/formação restaurados — usado tanto pelo
/// card da Arena quanto pelo card dinâmico da Home, pra nunca duplicar a
/// construção do `CrowdLineupCubit` em dois lugares.
Future<void> openCrowdLineup(BuildContext context, Match match) async {
  final cubit = CrowdLineupCubit(
    repository: sl<CrowdLineupRepository>(),
    matchId: match.id,
    votingOpen: true,
  );
  await GlobalLoading.run(context, cubit.load);
  if (!context.mounted) return;
  unawaited(context.push('/crowd-lineup', extra: (match: match, cubit: cubit)));
}
