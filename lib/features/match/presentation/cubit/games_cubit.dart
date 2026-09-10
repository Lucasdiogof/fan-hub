import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/data/selected_competition_storage.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/games_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Centraliza o fetch de dados esportivos da aba Jogos: rodada atual,
/// snapshot do Goiás (próximo jogo + últimos resultados) e classificação
/// vêm de endpoints independentes — cada um com seu próprio estado, pra
/// uma falha em um não esconder os outros.
///
/// Classificação por competição (Parte 3 da spec de multi-competição,
/// 2026-09-09): prioridade preferência manual salva pro clube ativo →
/// competição principal → primeira disponível — "competição do próximo
/// jogo" (item 2 da spec original) fica de fora por ora: o próximo jogo só
/// carrega o NOME da competição, não o id que o seletor usa, e casar os
/// dois por texto seria frágil (nomes com/sem patrocinador, "Betano" vs
/// "Brasileirão Série A"); não implementado até existir uma correspondência
/// confiável, nunca um match de string chutado.
class GamesCubit extends Cubit<GamesState> {
  GamesCubit(this._footballRepository, this._selectedCompetitionStorage)
    : super(const GamesState()) {
    loadCurrentRound();
    loadSnapshot();
    _loadCompetitionsThenStandings();
  }

  final FootballRepository _footballRepository;
  final SelectedCompetitionStorage _selectedCompetitionStorage;

  /// Cache em memória por offset dentro desta sessão de tela. Rodada passada
  /// (resultados) e futura (agenda) não mudam, então navegar pra uma rodada
  /// já vista não refaz a rede — aparece na hora. Vive só enquanto o cubit
  /// vive: como ele é `registerFactory` (instância nova a cada entrada na
  /// aba Jogos), sair e voltar recria o cubit, o cache zera e a rodada atual
  /// é buscada de novo — que é o único dado que pode ter mudado. O
  /// pull-to-refresh limpa o cache explicitamente (ver `refresh`).
  final Map<int, _RoundSnapshot> _roundCache = {};

  /// [offset] relativo à rodada atual (0) — negativo pra rodadas
  /// anteriores. Sempre reseta pra 0 quando chamado sem argumento (recarga
  /// normal/pull-to-refresh); só `previousRound()`/`nextRound()` passam um
  /// offset explícito, preservando o que já estava sendo mostrado.
  Future<void> loadCurrentRound({int offset = 0}) async {
    final cached = _roundCache[offset];
    if (cached != null) {
      emit(_stateForRound(offset, cached));
      return;
    }
    emit(state.copyWith(currentRoundStatus: LoadStatus.loading));
    final result = await _footballRepository.getCurrentRound(offset: offset);
    switch (result) {
      case Success(:final data):
        final snapshot = _RoundSnapshot(
          matches: MatchOrdering.chronological(data.matches),
          roundLabel: data.roundLabel,
          hasPrevious: data.hasPrevious,
          hasNext: data.hasNext,
        );
        _roundCache[offset] = snapshot;
        emit(_stateForRound(offset, snapshot));
      case Error(:final failure):
        emit(
          state.copyWith(
            currentRoundStatus: LoadStatus.error,
            currentRoundErrorMessage: failure.message,
          ),
        );
    }
  }

  GamesState _stateForRound(int offset, _RoundSnapshot snapshot) {
    return state.copyWith(
      currentRoundStatus: snapshot.matches.isEmpty
          ? LoadStatus.empty
          : LoadStatus.success,
      currentRoundMatches: snapshot.matches,
      roundOffset: offset,
      roundLabel: snapshot.roundLabel,
      clearRoundLabel: snapshot.roundLabel == null,
      hasPreviousRound: snapshot.hasPrevious,
      hasNextRound: snapshot.hasNext,
    );
  }

  Future<void> previousRound() async {
    if (!state.hasPreviousRound) return;
    await loadCurrentRound(offset: state.roundOffset - 1);
  }

  Future<void> nextRound() async {
    if (!state.hasNextRound) return;
    await loadCurrentRound(offset: state.roundOffset + 1);
  }

  Future<void> loadSnapshot() async {
    emit(state.copyWith(snapshotStatus: LoadStatus.loading));
    final result = await _footballRepository.getActiveClubSnapshot();
    switch (result) {
      case Success(:final data):
        final nextMatch =
            data.nextMatch != null && MatchOrdering.isOpen(data.nextMatch!)
            ? data.nextMatch
            : null;
        emit(
          state.copyWith(
            snapshotStatus: nextMatch == null
                ? LoadStatus.empty
                : LoadStatus.success,
            nextMatch: nextMatch,
            clearNextMatch: nextMatch == null,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            snapshotStatus: LoadStatus.error,
            snapshotErrorMessage: failure.message,
          ),
        );
    }
  }

  /// Busca a lista de competições, resolve qual mostrar primeiro
  /// (preferência salva → principal) e só então busca a classificação —
  /// evita buscar a principal pra, um instante depois, trocar pra
  /// secundária se havia preferência salva (sem "pisca" de tabela errada).
  Future<void> _loadCompetitionsThenStandings() async {
    emit(state.copyWith(standingsStatus: LoadStatus.loading));
    final competitionsResult = await _footballRepository.getCompetitions();
    final competitions = switch (competitionsResult) {
      Success(:final data) => data,
      Error() => const <CompetitionRef>[],
    };
    // `getCompetitions` falhando não impede ver a classificação principal
    // — só o seletor fica vazio (a UI já esconde o seletor com 0/1 opção).
    final saved = await _selectedCompetitionStorage.read();
    final initialId =
        saved != null && competitions.any((c) => c.id == saved)
        ? saved
        : null;
    if (competitions.isNotEmpty) {
      emit(state.copyWith(competitions: competitions));
    }
    await loadStandings(competitionId: initialId);
  }

  Future<void> loadStandings({String? competitionId}) async {
    emit(state.copyWith(standingsStatus: LoadStatus.loading));
    final result = await _footballRepository.getStandings(
      competitionId: competitionId,
    );
    switch (result) {
      case Success(:final data):
        final isEmpty = data.table.isEmpty && data.groups.isEmpty;
        emit(
          state.copyWith(
            standingsStatus: isEmpty ? LoadStatus.empty : LoadStatus.success,
            standings: data.table,
            standingGroups: data.groups,
            selectedCompetition: data.competition,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            standingsStatus: LoadStatus.error,
            standingsErrorMessage: failure.message,
          ),
        );
    }
  }

  /// Chamado pelo seletor de competição na aba Classificação — salva a
  /// escolha (isolada por clube) e recarrega a tabela/grupos pra ela.
  Future<void> selectCompetition(String competitionId) async {
    await _selectedCompetitionStorage.save(competitionId);
    await loadStandings(competitionId: competitionId);
  }

  /// Pull-to-refresh: refaz as três buscas. Limpa o cache de rodadas
  /// primeiro — é o gesto explícito do usuário pedindo dados novos, então a
  /// rodada atual (e as demais já vistas) volta a ser buscada de verdade. O
  /// Cloudflare continua no caminho — isso não ignora o cache server-side,
  /// só força uma nova leitura no lado do Flutter.
  Future<void> refresh() async {
    _roundCache.clear();
    // Preserva a competição que já estava sendo mostrada — pull-to-refresh
    // é "atualiza o que eu vejo agora", nunca "volta pra principal".
    final competitionId = state.selectedCompetition?.id;
    await Future.wait([
      loadCurrentRound(),
      loadSnapshot(),
      loadStandings(competitionId: competitionId),
    ]);
  }
}

class _RoundSnapshot {
  const _RoundSnapshot({
    required this.matches,
    required this.roundLabel,
    required this.hasPrevious,
    required this.hasNext,
  });

  final List<Match> matches;
  final String? roundLabel;
  final bool hasPrevious;
  final bool hasNext;
}
