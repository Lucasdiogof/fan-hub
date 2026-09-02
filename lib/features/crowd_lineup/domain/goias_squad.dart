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
    personId: 'e2507d62-8cb5-5152-af56-f67464196ac6',
    name: 'Tadeu',
    shirtNumber: 23,
    allowedPositions: _pos(['gol']),
  ),
  SquadPlayer(
    id: 'ezequiel',
    personId: '66cd616b-9b5d-56f9-879e-1b171a8a33d0',
    name: 'Ezequiel',
    shirtNumber: 12,
    allowedPositions: _pos(['gol']),
  ),
  SquadPlayer(
    id: 'murillo_victorio',
    personId: 'e590ad99-16d4-52a1-88fd-2fbb064444b6',
    name: 'Murillo Victorio',
    shirtNumber: 32,
    allowedPositions: _pos(['gol']),
  ),
  SquadPlayer(
    id: 'thiago_rodrigues',
    personId: '0b374c05-3edd-5cbb-9ddf-71b1b37e79ba',
    name: 'Thiago Rodrigues',
    shirtNumber: 1,
    allowedPositions: _pos(['gol']),
  ),
  SquadPlayer(
    id: 'luisao',
    personId: '91e2722f-6fce-535e-9bd9-d2420889b1af',
    name: 'Luisão',
    shirtNumber: 25,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'lucas_ribeiro',
    personId: '36ed37b5-02be-5117-91d6-a62d5236505f',
    name: 'Lucas Ribeiro',
    shirtNumber: 14,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'luiz_felipe',
    personId: '83765e63-a9f9-584e-aef1-bf11c3324b5e',
    name: 'Luiz Felipe',
    shirtNumber: 3,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'ramon_menezes',
    personId: 'd30dc008-4189-58bf-9823-8e8ab93dd7e0',
    name: 'Ramon Menezes',
    shirtNumber: 4,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'murilo_camara',
    personId: 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae',
    name: 'Murilo Câmara',
    shirtNumber: 29,
    allowedPositions: _pos(['zag']),
  ),
  SquadPlayer(
    id: 'rodrigo_soares',
    personId: '2bd4e578-4739-5f93-b5db-8ecf6ba44393',
    name: 'Rodrigo Soares',
    shirtNumber: 2,
    allowedPositions: _pos(['ld', 'ald', 'le']),
  ),
  SquadPlayer(
    id: 'marcos_vinicius',
    personId: 'a7ba5544-1384-5830-94a6-632f1c9e8414',
    name: 'Marcos Vinicius',
    shirtNumber: 63,
    allowedPositions: _pos(['ld', 'ald']),
  ),
  SquadPlayer(
    id: 'nicolas',
    personId: 'a597dae2-6ca9-5588-b1e3-a3532dd36f0e',
    name: 'Nicolas',
    shirtNumber: 6,
    allowedPositions: _pos(['le', 'ale']),
  ),
  SquadPlayer(
    id: 'danilo',
    personId: '34d6fed1-6282-564a-bcb0-5be7d705760a',
    name: 'Danilo',
    shirtNumber: 66,
    allowedPositions: _pos(['le', 'ale']),
  ),
  SquadPlayer(
    id: 'djalma',
    personId: '54e8cc38-7ac7-5927-b7a5-ca11a372a545',
    name: 'Djalma',
    shirtNumber: 54,
    allowedPositions: _pos(['le', 'ale', 'pe']),
  ),
  SquadPlayer(
    id: 'lourenco',
    personId: 'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb',
    name: 'Lourenço',
    shirtNumber: 97,
    allowedPositions: _pos(['vol', 'mc', 'mei']),
  ),
  SquadPlayer(
    id: 'filipe_machado',
    personId: 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f',
    name: 'Filipe Machado',
    shirtNumber: 5,
    allowedPositions: _pos(['vol', 'mc']),
  ),
  SquadPlayer(
    id: 'baldoria',
    personId: '747cb968-a339-586c-94cf-583a3e0c3296',
    name: 'Baldória',
    shirtNumber: 55,
    allowedPositions: _pos(['vol']),
  ),
  SquadPlayer(
    id: 'juninho',
    personId: 'b9d994d7-3605-5e6e-89ca-7d223f87d14a',
    name: 'Juninho',
    shirtNumber: 8,
    allowedPositions: _pos(['vol', 'mc']),
  ),
  SquadPlayer(
    id: 'lucas_rodrigues',
    personId: 'af92cda1-aeba-5f69-a354-2928d8677c6f',
    name: 'Lucas Rodrigues',
    shirtNumber: 35,
    allowedPositions: _pos(['vol', 'mc', 'mei']),
  ),
  SquadPlayer(
    id: 'gege',
    personId: '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd',
    name: 'Gegê',
    shirtNumber: 28,
    allowedPositions: _pos(['mc', 'mei']),
  ),
  SquadPlayer(
    id: 'lucas_lima',
    personId: 'd58d5ae2-85c7-5336-80b6-0f4c0ed0a24b',
    name: 'Lucas Lima',
    shirtNumber: 10,
    allowedPositions: _pos(['mei', 'mc', 'pd']),
  ),
  SquadPlayer(
    id: 'brayann',
    personId: '75723744-c847-55e8-acf2-d8ee0d75c7a1',
    name: 'Brayann',
    shirtNumber: 88,
    allowedPositions: _pos(['mei', 'mc', 'pd']),
  ),
  SquadPlayer(
    id: 'wellington_rato',
    personId: '4dd73b43-f2ac-536a-8b22-ab4f7c125c68',
    name: 'Wellington Rato',
    shirtNumber: 27,
    allowedPositions: _pos(['mei', 'pd', 'pe']),
  ),
  SquadPlayer(
    id: 'pedrinho',
    personId: '879326ba-8353-5fc8-ab0f-c6ca4646a143',
    name: 'Pedrinho',
    shirtNumber: 17,
    allowedPositions: _pos(['pe', 'pd', 'ata', 'sa']),
  ),
  SquadPlayer(
    id: 'anselmo_ramon',
    personId: 'e277edea-70b1-5092-ad39-48be1a5297d6',
    name: 'Anselmo Ramon',
    shirtNumber: 9,
    allowedPositions: _pos(['ata', 'sa']),
  ),
  SquadPlayer(
    id: 'cadu',
    personId: '6702c943-0b4e-5041-8cd4-76991b85633d',
    name: 'Cadu',
    shirtNumber: 18,
    allowedPositions: _pos(['ata', 'sa', 'pe', 'pd']),
  ),
  SquadPlayer(
    id: 'felipe_clemente',
    personId: '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4',
    name: 'Felipe Clemente',
    shirtNumber: 11,
    allowedPositions: _pos(['ata', 'sa', 'pd', 'pe']),
  ),
  SquadPlayer(
    id: 'jean_carlos',
    personId: '424f8724-6855-58d6-ad36-24e2d9bdd7f6',
    name: 'Jean Carlos',
    shirtNumber: 21,
    allowedPositions: _pos(['mei', 'pd', 'pe']),
  ),
  SquadPlayer(
    id: 'halerrandrio',
    personId: '140ba628-c222-53a5-8621-a774092a125b',
    name: 'Halerrandrio',
    shirtNumber: 77,
    allowedPositions: _pos(['pd', 'pe', 'sa']),
  ),
  SquadPlayer(
    id: 'esli_garcia',
    personId: '10f6579f-1bc4-5b2a-ab9f-0a1a262519a1',
    name: 'Esli Garcia',
    shirtNumber: 15,
    allowedPositions: _pos(['pe', 'pd', 'sa']),
  ),
  SquadPlayer(
    id: 'kadu_sousa',
    personId: '6bc585a3-1b56-58c3-8ba7-6f208151ae47',
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
