import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

/// Todo clube REAL que este binário sabe resolver, indexado por
/// `ClubIdentity.code`. Onboarding M4: além do Goiás, o Red Bull Bragantino
/// (config mínima, capabilities desligadas até haver dado real — ver
/// [bragantinoClubConfig]). O clube sintético `club-b`/`clubb` foi removido.
const clubRegistry = <String, ClubConfig>{
  'goias': goiasClubConfig,
  'bragantino': bragantinoClubConfig,
};
