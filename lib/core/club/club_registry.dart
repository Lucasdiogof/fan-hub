import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

/// Todo clube que este binário SABE resolver, indexado por
/// `ClubIdentity.code`. Nesta rodada (M1), SÓ `'goias'` — nenhum 2º clube
/// cadastrado, nem como placeholder, nem copiando a config do Goiás.
/// Cadastrar um 2º clube é decisão de produto de uma etapa própria, não
/// desta fundação.
const clubRegistry = <String, ClubConfig>{
  'goias': goiasClubConfig,
};
