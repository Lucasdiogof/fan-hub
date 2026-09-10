import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/data/selected_competition_storage.dart';
import 'package:goias_app/features/match/domain/competition_alias_matcher.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/games_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Centraliza o fetch de dados esportivos da aba Jogos: rodada atual,
/// snapshot do clube ativo (próximo jogo + últimos resultados) e
/// classificação vêm de endpoints independentes — cada um com seu próprio
/// estado, pra uma falha em um não esconder os outros.
///
/// Competição inicial da Classificação (spec multi-competição, item 1),
/// nesta ordem: preferência manual salva pro clube ativo (se ainda existir
/// no catálogo) → competição do PRÓXIMO JOGO (casada por nome via
/// [CompetitionAliasMatcher] — nunca um match de string chutado, só quando
/// há correspondência real com o catálogo) → `null` (o Worker resolve pra
/// principal do clube). Isso é sempre independente da competição "principal"
/// configurada no flavor — ver `_resolveInitialCompetitionId`.
class GamesCubit extends Cubit<GamesState> {
  GamesCubit(this._footballRepository, this._selectedCompetitionStorage)
    : super(const GamesState()) {
    loadCurrentRound();
    _loadSnapshotThenCompetitions();
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

  /// Busca o snapshot (próximo jogo) e o catálogo de competições em
  /// paralelo, resolve qual competição mostrar primeiro (ver
  /// `_resolveInitialCompetitionId`) e só então busca a classificação —
  /// evita buscar a principal pra, um instante depois, trocar de competição
  /// (sem "pisca" de tabela errada).
  Future<void> _loadSnapshotThenCompetitions() async {
    emit(
      state.copyWith(
        snapshotStatus: LoadStatus.loading,
        standingsStatus: LoadStatus.loading,
      ),
    );
    final snapshotFuture = _footballRepository.getActiveClubSnapshot();
    final competitionsFuture = _footballRepository.getCompetitions();
    final snapshotResult = await snapshotFuture;
    final competitionsResult = await competitionsFuture;

    Match? nextMatch;
    switch (snapshotResult) {
      case Success(:final data):
        nextMatch =
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

    // `getCompetitions` falhando não impede ver a classificação principal
    // — só o seletor/catálogo ficam vazios.
    final competitions = switch (competitionsResult) {
      Success(:final data) => data,
      Error() => const <CompetitionRef>[],
    };
    if (competitions.isNotEmpty) {
      emit(state.copyWith(competitions: competitions));
    }

    final saved = await _selectedCompetitionStorage.read();
    final initialId = _resolveInitialCompetitionId(
      saved: saved,
      nextMatch: nextMatch,
      competitions: competitions,
    );
    await loadStandings(competitionId: initialId);
  }

  /// Preferência salva (se ainda existir no catálogo) → competição do
  /// próximo jogo (casada por nome, nunca inventada) → `null` (principal).
  String? _resolveInitialCompetitionId({
    required String? saved,
    required Match? nextMatch,
    required List<CompetitionRef> competitions,
  }) {
    if (saved != null && competitions.any((c) => c.id == saved)) return saved;
    final nextMatchCompetition = nextMatch?.competition;
    if (nextMatchCompetition != null && nextMatchCompetition.isNotEmpty) {
      final matched = CompetitionAliasMatcher.matchId(
        nextMatchCompetition,
        competitions,
      );
      if (matched != null) return matched;
    }
    return null;
  }

  Future<void> loadStandings({String? competitionId}) async {
    emit(state.copyWith(standingsStatus: LoadStatus.loading));
    final result = await _footballRepository.getStandings(
      competitionId: competitionId,
    );
    switch (result) {
      case Success(:final data):
        final isEmpty = data.table.isEmpty && data.groups.isEmpty;
        // O catálogo já carregado (`state.competitions`) tem region/
        // isClubParticipating reais — a resposta de `/standings` sozinha
        // não carrega isso. Usa a entrada do catálogo quando existe, cai
        // pro que veio da resposta só se o catálogo não tiver essa
        // competição (ex.: `getCompetitions` falhou).
        var selected = data.competition;
        for (final c in state.competitions) {
          if (c.id == data.competition.id) {
            selected = c;
            break;
          }
        }
        emit(
          state.copyWith(
            standingsStatus: isEmpty ? LoadStatus.empty : LoadStatus.success,
            standings: data.table,
            standingGroups: data.groups,
            selectedCompetition: selected,
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

  /// Só o próximo jogo/últimos resultados — usado pelo pull-to-refresh, que
  /// já preserva a competição mostrada separadamente (não recalcula
  /// competição inicial, isso só faz sentido na primeira carga).
  Future<void> _loadSnapshot() async {
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
      _loadSnapshot(),
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
