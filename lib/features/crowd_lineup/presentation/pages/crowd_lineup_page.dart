import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_state.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/crowd_tab.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/escale_tab.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/share_field_image.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

/// Duas abas: "Escalação da torcida" (o consolidado — formação mais votada
/// + jogador mais escalado em cada slot; primeira aba, é a que mais gente
/// abre) e "Escale" (o torcedor monta a própria escalação). Abre direto na
/// aba certa conforme [cubit.state.
/// hasVoted] (já resolvido antes da navegação — ver `GlobalLoading.run` no
/// ponto de entrada): quem ainda não votou cai em "Escale"; quem já votou
/// cai direto em "Escalação da torcida", sem passar visualmente pela outra
/// aba antes.
///
/// [cubit] já vem construído e carregado por quem navegou pra cá (ver
/// `GlobalLoading.run` no ponto de entrada) — a tela nunca cria/carrega o
/// próprio Cubit, só o reaproveita via `BlocProvider.value`, pra nunca
/// abrir vazia esperando a escalação salva aparecer.
class CrowdLineupPage extends StatelessWidget {
  const CrowdLineupPage({required this.match, required this.cubit, super.key});

  final Match match;
  final CrowdLineupCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
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

  /// Um `RepaintBoundary` por aba — as duas abas ficam montadas ao mesmo
  /// tempo (`TabBarView` constrói a vizinha pra transição suave), então o
  /// botão de compartilhar no cabeçalho sempre alcança a chave certa
  /// independente de qual aba está visível no momento.
  final _crowdFieldKey = GlobalKey();
  final _escaleFieldKey = GlobalKey();

  /// Mesma heurística usada no card da Home (não existe um id de time
  /// oficial "Goiás" cadastrado no app) — se o Goiás está listado como
  /// mandante, uniforme principal; senão, reserva.
  bool get _isGoiasHome =>
      widget.match.homeTeam.name.toLowerCase().contains('goi');

  @override
  void initState() {
    super.initState();
    // "Escalação da torcida" agora é a primeira aba (índice 0) — é a que
    // mais gente abre. Quem já votou cai direto nela; quem ainda não votou
    // cai em "Escale" (índice 1) pra completar a própria escalação.
    final hasVoted = context.read<CrowdLineupCubit>().state.hasVoted;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: hasVoted ? 0 : 1,
    );
    // O botão de compartilhar no cabeçalho depende de qual aba está ativa
    // (campo + texto diferentes) — precisa re-renderizar a cada troca.
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() => setState(() {});

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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
                          context.l10n.crowdTitle,
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
                  BlocBuilder<CrowdLineupCubit, CrowdLineupState>(
                    builder: (context, state) => _buildShareButton(state),
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
              tabs: [
                Tab(text: context.l10n.crowdTitle),
                Tab(text: context.l10n.crowdTabEscale),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CrowdTab(isHome: _isGoiasHome, fieldKey: _crowdFieldKey),
                  EscaleTab(
                    isHome: _isGoiasHome,
                    fieldKey: _escaleFieldKey,
                    onConfirm: () => _submit(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aba 0 = "Escalação da torcida" (`_crowdFieldKey`), aba 1 = "Escale"
  /// (`_escaleFieldKey`) — mesmo texto/nome de arquivo que cada aba usava
  /// quando o botão ainda ficava embutido acima do campo.
  Widget _buildShareButton(CrowdLineupState state) {
    final onCrowdTab = _tabController.index == 0;
    final canShare = onCrowdTab ? state.crowd.hasVotes : state.filledCount > 0;
    if (!canShare) return const SizedBox(width: 38);

    return _HeaderIconButton(
      icon: Icons.share_rounded,
      onTap: () => shareFieldImage(
        onCrowdTab ? _crowdFieldKey : _escaleFieldKey,
        text: onCrowdTab
            ? 'Confira a escalação da torcida pro Goiás! 💚'
            : 'Essa é a minha escalação pro Goiás! 💚',
        fileName: onCrowdTab
            ? 'escalacao_da_torcida.png'
            : 'minha_escalacao.png',
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
    // "Escalação da torcida" é a aba 0 agora.
    _tabController.animateTo(0);
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: colors.textPrimary),
      ),
    );
  }
}
