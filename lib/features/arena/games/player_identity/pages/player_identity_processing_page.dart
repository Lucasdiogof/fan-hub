import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_reference_sets.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// Transição curta entre a última pergunta e o resultado — só efeito
/// visual, o cálculo (`PlayerIdentityEngine.computeResult`) é síncrono e
/// instantâneo. Nunca um loading artificial longo.
class PlayerIdentityProcessingPage extends StatefulWidget {
  const PlayerIdentityProcessingPage({required this.answers, super.key});

  final List<PlayerIdentityOption> answers;

  @override
  State<PlayerIdentityProcessingPage> createState() =>
      _PlayerIdentityProcessingPageState();
}

class _PlayerIdentityProcessingPageState
    extends State<PlayerIdentityProcessingPage> {
  late final _engine = playerIdentityEngineForClub(sl<ClubConfig>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  Future<void> _process() async {
    final result = _engine.computeResult(widget.answers);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    context.pushReplacement('/arena/player-identity/result', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.arenaBottom,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ArenaColors.arenaTop, ArenaColors.arenaBottom],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GoiasLoadingIndicator(),
              const SizedBox(height: 20),
              Text(
                context.l10n.playerProcessingTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
