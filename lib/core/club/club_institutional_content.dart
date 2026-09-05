import 'package:goias_app/features/club/domain/entities/club_history_section.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/features/club/domain/entities/club_timeline_event.dart';
import 'package:goias_app/features/club/domain/entities/club_title_group.dart';
import 'package:goias_app/features/partners/domain/entities/partner.dart';

/// História/títulos/hino/parceiros de UM clube — o conteúdo estático e
/// editorial de `/clube` e `/partners` (nunca vem de banco, ao contrário
/// de diretoria/transparência, que já são `ClubBoardRepository`/
/// `ClubTransparencyRepository` de verdade). Existe pra que cada clube
/// tenha os PRÓPRIOS dados sem nenhuma classe estática global só do Goiás
/// no meio do caminho — cada `ClubConfig` carrega o seu.
///
/// Todo campo tem default vazio: um clube sem conteúdo ainda (ex.:
/// Bragantino, enquanto uma seção específica não tiver dado real) só
/// passa listas vazias — nunca herda/reaproveita o conteúdo de outro
/// clube por omissão. As páginas que leem isto já tratam lista vazia como
/// "nada aqui" (títulos sem [ClubTitleGroup.images] já escondiam só o
/// carrossel; história/hino/parceiros vazios mostram nada, nunca quebram).
class ClubInstitutionalContent {
  const ClubInstitutionalContent({
    this.history = const [],
    this.timeline = const [],
    this.titles = const [],
    this.historicalCampaigns = const [],
    this.songs = const [],
    this.partners = const [],
    this.idols = const [],
  });

  final List<ClubHistorySection> history;
  final List<ClubTimelineEvent> timeline;

  /// Títulos DE VERDADE — nunca vice/3º lugar/campanha de destaque (isso é
  /// [historicalCampaigns]).
  final List<ClubTitleGroup> titles;
  final List<ClubHistoricalCampaign> historicalCampaigns;
  final List<ClubSong> songs;
  final List<Partner> partners;

  /// Sem página própria ainda em nenhum clube (nem o Goiás tem) — só o
  /// dado, preparado como pool inicial pro futuro jogo de identidade de
  /// jogador (ver `ClubIdol`).
  final List<ClubIdol> idols;
}
