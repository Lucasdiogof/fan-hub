import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/features/crowd_lineup/domain/position_compatibility.dart';
import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';

List<PlayerPosition> _pos(List<String> codes) =>
    codes.map((code) => playerPositionFromCode(code)!).toList(growable: false);

/// Elenco profissional atual do Goiás — fonte da verdade fornecida pelo
/// usuário (nome, número e posições permitidas). `allowedPositions` define
/// onde o atleta PODE ser escalado no jogo (não a categoria do site), e é o
/// que manda na elegibilidade dos slots. Nunca sobrescrever com dados
/// externos.
final List<SquadPlayer> goiasSquad = [
  SquadPlayer(
    id: 'tadeu',
    name: 'Tadeu',
    shirtNumber: 23,
    allowedPositions: _pos(['gol']),
  ),
  SquadPlayer(
    id: 'ezequiel',
    name: 'Ezequiel',
    shirtNumber: 12,
    allowedPositions: _pos(['gol']),
  ),
  SquadPlayer(
    id: 'murillo_victorio',
    name: 'Murillo Victorio',
    shirtNumber: 32,
    allowedPositions: _pos(['gol']),
  ),
  SquadPlayer(
    id: 'thiago_rodrigues',
    name: 'Thiago Rodrigues',
    shirtNumber: 1,
    allowedPositions: _pos(['gol']),
  ),
  SquadPlayer(
    id: 'luisao',
    name: 'Luisão',
    shirtNumber: 25,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'lucas_ribeiro',
    name: 'Lucas Ribeiro',
    shirtNumber: 14,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'luiz_felipe',
    name: 'Luiz Felipe',
    shirtNumber: 3,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'ramon_menezes',
    name: 'Ramon Menezes',
    shirtNumber: 4,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'murilo_camara',
    name: 'Murilo Câmara',
    shirtNumber: 29,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'rodrigo_soares',
    name: 'Rodrigo Soares',
    shirtNumber: 2,
    allowedPositions: _pos(['ld', 'ald', 'le']),
  ),
  SquadPlayer(
    id: 'marcos_vinicius',
    name: 'Marcos Vinicius',
    shirtNumber: 63,
    allowedPositions: _pos(['ld', 'ald']),
  ),
  SquadPlayer(
    id: 'nicolas',
    name: 'Nicolas',
    shirtNumber: 6,
    allowedPositions: _pos(['le', 'ale']),
  ),
  SquadPlayer(
    id: 'danilo',
    name: 'Danilo',
    shirtNumber: 66,
    allowedPositions: _pos(['le', 'ale']),
  ),
  SquadPlayer(
    id: 'djalma',
    name: 'Djalma',
    shirtNumber: 54,
    allowedPositions: _pos(['le', 'ale', 'pe']),
  ),
  SquadPlayer(
    id: 'lourenco',
    name: 'Lourenço',
    shirtNumber: 97,
    allowedPositions: _pos(['vol', 'mc', 'mei']),
  ),
  SquadPlayer(
    id: 'filipe_machado',
    name: 'Filipe Machado',
    shirtNumber: 5,
    allowedPositions: _pos(['vol', 'mc']),
  ),
  SquadPlayer(
    id: 'baldoria',
    name: 'Baldória',
    shirtNumber: 55,
    allowedPositions: _pos(['vol']),
  ),
  SquadPlayer(
    id: 'juninho',
    name: 'Juninho',
    shirtNumber: 8,
    allowedPositions: _pos(['vol', 'mc']),
  ),
  SquadPlayer(
    id: 'lucas_rodrigues',
    name: 'Lucas Rodrigues',
    shirtNumber: 35,
    allowedPositions: _pos(['vol', 'mc', 'mei']),
  ),
  SquadPlayer(
    id: 'gege',
    name: 'Gegê',
    shirtNumber: 28,
    allowedPositions: _pos(['mc', 'mei']),
  ),
  SquadPlayer(
    id: 'lucas_lima',
    name: 'Lucas Lima',
    shirtNumber: 10,
    allowedPositions: _pos(['mei', 'mc', 'pd']),
  ),
  SquadPlayer(
    id: 'brayann',
    name: 'Brayann',
    shirtNumber: 88,
    allowedPositions: _pos(['mei', 'mc', 'pd']),
  ),
  SquadPlayer(
    id: 'wellington_rato',
    name: 'Wellington Rato',
    shirtNumber: 27,
    allowedPositions: _pos(['mei', 'pd', 'pe']),
  ),
  SquadPlayer(
    id: 'pedrinho',
    name: 'Pedrinho',
    shirtNumber: 17,
    allowedPositions: _pos(['pe', 'pd', 'ata', 'sa']),
  ),
  SquadPlayer(
    id: 'anselmo_ramon',
    name: 'Anselmo Ramon',
    shirtNumber: 9,
    allowedPositions: _pos(['ata', 'sa']),
  ),
  SquadPlayer(
    id: 'cadu',
    name: 'Cadu',
    shirtNumber: 18,
    allowedPositions: _pos(['ata', 'sa', 'pe', 'pd']),
  ),
  SquadPlayer(
    id: 'felipe_clemente',
    name: 'Felipe Clemente',
    shirtNumber: 11,
    allowedPositions: _pos(['ata', 'sa', 'pd', 'pe']),
  ),
  SquadPlayer(
    id: 'jean_carlos',
    name: 'Jean Carlos',
    shirtNumber: 21,
    allowedPositions: _pos(['mei', 'pd', 'pe']),
  ),
  SquadPlayer(
    id: 'halerrandrio',
    name: 'Halerrandrio',
    shirtNumber: 77,
    allowedPositions: _pos(['pd', 'pe', 'sa']),
  ),
  SquadPlayer(
    id: 'esli_garcia',
    name: 'Esli Garcia',
    shirtNumber: 15,
    allowedPositions: _pos(['pe', 'pd', 'sa']),
  ),
  SquadPlayer(
    id: 'kadu_sousa',
    name: 'Kadu Sousa',
    shirtNumber: 40,
    allowedPositions: _pos(['pe', 'sa', 'pd', 'ata']),
  ),
];

final Map<String, SquadPlayer> squadById = {
  for (final player in goiasSquad) player.id: player,
};

const _compatibility = PositionCompatibilityService();

/// Candidatos a um slot, do melhor encaixe pro pior (posição primária exata
/// > secundária exata > adaptação natural) — nunca em ordem de cadastro.
/// Quem é incompatível nem aparece.
List<SquadPlayer> playersForPosition(PlayerPosition position) {
  final scored = <(SquadPlayer, int)>[
    for (final player in goiasSquad)
      if (_compatibility.scoreFor(player, position) case final score?)
        (player, score),
  ];
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final entry in scored) entry.$1];
}
