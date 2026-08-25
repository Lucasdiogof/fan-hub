import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/crowd_tab.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/escale_tab.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

/// Duas abas: "Escale" (o torcedor monta a própria escalação) e "Escalação
/// da torcida" (o consolidado — formação mais votada + jogador mais
/// escalado em cada slot). Sempre abre em "Escale" primeiro — mesmo que o
/// torcedor já tenha votado nessa partida antes, é essa a aba que ele quer
/// ver de cara (e pode ir pra "Escalação da torcida" com um toque).
class CrowdLineupPage extends StatelessWidget {
  const CrowdLineupPage({required this.match, super.key});

  final Match match;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CrowdLineupCubit(
        repository: sl<CrowdLineupRepository>(),
        matchId: match.id,
        votingOpen: true,
      )..load(),
      child: _CrowdLineupView(match: match),
    );
  }
}

class _CrowdLineupView extends StatefulWidget {
  const _CrowdLineupView({required this.match});

  final Match match;

  @override
  State<_CrowdLineupView> createState() => _CrowdLineupViewState();
}

class _CrowdLineupViewState extends State<_CrowdLineupView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Mesma heurística usada no card da Home (não existe um id de time
  /// oficial "Goiás" cadastrado no app) — se o Goiás está listado como
  /// mandante, uniforme principal; senão, reserva.
  bool get _isGoiasHome =>
      widget.match.homeTeam.name.toLowerCase().contains('goi');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESCALAÇÃO DA TORCIDA',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          '${widget.match.homeTeam.name} x ${widget.match.awayTeam.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textHint,
              indicatorColor: colors.primary,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
              tabs: const [
                Tab(text: 'ESCALE'),
                Tab(text: 'ESCALAÇÃO DA TORCIDA'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  EscaleTab(
                    isHome: _isGoiasHome,
                    onConfirm: () => _submit(context),
                  ),
                  CrowdTab(isHome: _isGoiasHome),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<CrowdLineupCubit>();
    final ok = await cubit.submit();
    if (!ok || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Escalação enviada!')));
    _tabController.animateTo(1);
  }
}
