import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';

/// Mantém um card "ao vivo" atualizado sozinho, sem depender do Cubit da
/// tela inteira (`HomeCubit`/`GamesCubit`) — só este widget refaz a busca e
/// só ele reconstrói quando o placar/minuto muda. Nunca dispara um reload
/// de página inteira a cada tick; quando a partida termina de verdade
/// (deixa de ser a `nextMatch` retornada pela fonte), avisa [onMatchEnded]
/// UMA vez pra quem criou este widget decidir o que fazer (normalmente
/// recarregar a tela pra sair do estado "ao vivo" de vez).
///
/// Respeita o ciclo de vida do app: para de fazer polling quando o app vai
/// pra segundo plano, retoma ao voltar — nunca continua batendo no backend
/// com a tela invisível.
class LiveMatchPoller extends StatefulWidget {
  const LiveMatchPoller({
    required this.match,
    required this.builder,
    this.onMatchEnded,
    this.interval = const Duration(seconds: 45),
    super.key,
  });

  final Match match;
  final Widget Function(BuildContext context, Match match) builder;
  final VoidCallback? onMatchEnded;
  final Duration interval;

  @override
  State<LiveMatchPoller> createState() => _LiveMatchPollerState();
}

class _LiveMatchPollerState extends State<LiveMatchPoller>
    with WidgetsBindingObserver {
  late Match _match;
  Timer? _timer;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant LiveMatchPoller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.id != widget.match.id) {
      _match = widget.match;
      _ended = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      unawaited(_poll());
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_ended) return;
    _timer = Timer.periodic(widget.interval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_ended || !mounted) return;
    final result = await sl<FootballRepository>().getActiveClubSnapshot();
    if (!mounted || _ended) return;
    switch (result) {
      case Success(:final data):
        final current = data.nextMatch;
        if (current != null &&
            current.id == _match.id &&
            MatchOrdering.isOpen(current)) {
          setState(() => _match = current);
        } else {
          _ended = true;
          _timer?.cancel();
          widget.onMatchEnded?.call();
        }
      case Error():
        // Falha pontual — mantém o último placar conhecido e tenta de novo
        // no próximo tick, sem derrubar o card por um erro passageiro.
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _match);
}
