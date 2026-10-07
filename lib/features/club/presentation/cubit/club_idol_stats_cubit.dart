import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/club/domain/entities/active_idol_tracking.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/features/club/domain/repositories/active_idol_stats_repository.dart';

/// Números de UM ídolo ativo na tela de detalhe. Começa SEMPRE no baseline
/// auditado (a tela nunca fica vazia nem em zero) e, quando o cálculo sobre
/// as partidas posteriores termina, troca pelo valor atualizado. Se o
/// carregamento falhar, o baseline continua na tela.
class ClubIdolStatsCubit extends Cubit<IdolStats> {
  ClubIdolStatsCubit(this._repository, this._idol)
    : assert(_idol.tracking != null, 'ídolo sem tracking não tem cálculo'),
      super(
        _repository.lastCompleteFor(_idol) ??
            IdolStats.fromBaseline(_idol.tracking!.baseline),
      );

  final ActiveIdolStatsRepository _repository;
  final ClubIdol _idol;

  Future<void> load() async {
    try {
      final stats = (await _repository.loadStats([_idol]))[_idol.name];
      if (stats != null && !isClosed) emit(stats);
    } catch (_) {
      // Mantém o baseline: erro de rede/provedor nunca piora a tela.
    }
  }
}
