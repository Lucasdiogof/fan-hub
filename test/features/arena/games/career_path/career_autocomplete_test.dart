import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/career_path/career_autocomplete.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/career_players.dart';
import 'package:goias_app/features/arena/games/career_path/goias_players.dart';

CareerPlayer _career(
  String id,
  String answer, {
  List<String>? acceptedAnswers,
  String? personId,
}) => CareerPlayer(
  id: id,
  answer: answer,
  acceptedAnswers: acceptedAnswers ?? [answer],
  clubCareer: const [],
  personId: personId,
);

GoiasPlayer _goias(
  String name, {
  String? personId,
  List<String> aliases = const [],
}) => GoiasPlayer(name: name, personId: personId, aliases: aliases);

void main() {
  group('buildCareerAutocompleteIndex — dado real', () {
    final index = buildCareerAutocompleteIndex(
      careerPlayers: careerPlayers,
      goiasPlayers: goiasPlayers,
    );

    test(
      '30 career_players + 215 goiasPlayers, 0 colisões reais -> 245 sugestões visíveis',
      () {
        expect(careerPlayers.length, 30);
        expect(goiasPlayers.length, 215);
        expect(index.suggestions.length, 245);
        expect(index.collisions, isEmpty);
        expect(index.samePersonCollisions, 0);
        expect(index.crossPersonCollisions, 0);
        expect(index.unknownIdentityCollisions, 0);
      },
    );

    test(
      'sugestões continuam ordenadas alfabeticamente, igual ao comportamento anterior',
      () {
        final labels = index.suggestions.map((s) => s.label).toList();
        final sorted = [...labels]..sort();
        expect(labels, sorted);
      },
    );

    test(
      '21 career_players resolvidos carregam o personId real do modelo (nunca re-identificados pelo answer)',
      () {
        final resolvedCareer = careerPlayers.where((p) => p.personId != null);
        expect(resolvedCareer.length, 21);
        for (final p in resolvedCareer) {
          final suggestion = index.suggestions.firstWhere(
            (s) => s.label == p.answer,
          );
          expect(suggestion.personId, p.personId);
        }
      },
    );

    test(
      '9 career_players ainda sem personId continuam sem personId na sugestão (F6 não resolve isso)',
      () {
        const stillUnresolved = [
          'Grafite',
          'Bruno Henrique',
          'Pedro Raul',
          'Jadílson',
          'Souza',
          'Rôni',
          'Vítor',
          'Marcelo Rangel',
          'Apodi',
        ];
        expect(stillUnresolved.length, 9);
        for (final answer in stillUnresolved) {
          final suggestion = index.suggestions.firstWhere(
            (s) => s.label == answer,
          );
          expect(suggestion.personId, isNull);
        }
      },
    );

    test('41 goiasPlayers resolvidos carregam personId', () {
      final resolvedGoias = goiasPlayers.where((p) => p.personId != null);
      expect(resolvedGoias.length, 41);
    });

    test(
      'personId nunca aparece como texto de sugestão (nunca vira label/UI)',
      () {
        final uuidLike = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-');
        for (final s in index.suggestions) {
          expect(uuidLike.hasMatch(s.label), isFalse, reason: s.label);
        }
      },
    );
  });

  group('resolução do texto digitado (acceptedText) segue igual à F5/pré-F6', () {
    final index = buildCareerAutocompleteIndex(
      careerPlayers: careerPlayers,
      goiasPlayers: goiasPlayers,
    );

    test(
      'acceptedAnswers do Danilo (career_players) continuam resolvendo pro texto correto',
      () {
        expect(index.resolveMap['danilo'], 'Danilo');
        expect(index.resolveMap['danilo gabriel de andrade'], 'Danilo');
      },
    );

    test(
      'alias de goiasPlayers (ex.: Túlio -> Túlio Maravilha) continua resolvendo',
      () {
        expect(index.resolveMap['tulio'], 'Túlio Maravilha');
      },
    );

    test(
      'goiasPlayers "Nicolas" bare (índice 178, ambíguo entre Vichiatto e Godinho, sem personId) '
      'aparece como sugestão mas nunca é uma resposta aceita por nenhum career_player real',
      () {
        expect(index.suggestions.any((s) => s.label == 'Nicolas'), isTrue);
        final nicolasSuggestion = index.suggestions.firstWhere(
          (s) => s.label == 'Nicolas',
        );
        expect(nicolasSuggestion.personId, isNull);
        expect(
          careerPlayers.any(
            (p) => p.acceptedAnswers.any((a) => a.toLowerCase() == 'nicolas'),
          ),
          isFalse,
        );
      },
    );
  });

  group('classificação semântica de colisão — endurecimento pós-revisão', () {
    test(
      'SAME_PERSON_COLLISION: mesmo personId nos 2 lados -> tipo samePerson, seguro deduplicar',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: [
            _career('paulo_baier', 'Paulo Baier', personId: 'person-a'),
          ],
          goiasPlayers: [_goias('Paulo Baier', personId: 'person-a')],
        );
        expect(index.collisions, hasLength(1));
        expect(index.collisions.single.type, CareerCollisionType.samePerson);
        expect(index.samePersonCollisions, 1);
        expect(index.crossPersonCollisions, 0);
        expect(index.unknownIdentityCollisions, 0);
        expect(index.suggestions, hasLength(1));
        expect(index.suggestions.single.personId, 'person-a');
      },
    );

    test(
      'CROSS_PERSON_COLLISION: 2 personId não-nulos e diferentes -> tipo crossPerson, nunca escondido',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: [_career('danilo_a', 'Danilo', personId: 'person-a')],
          goiasPlayers: [_goias('Danilo', personId: 'person-b')],
        );
        expect(index.collisions, hasLength(1));
        expect(index.collisions.single.type, CareerCollisionType.crossPerson);
        expect(index.crossPersonCollisions, 1);
        expect(index.samePersonCollisions, 0);
        expect(index.unknownIdentityCollisions, 0);
        // DISPLAY_PRIORITY ainda escolhe 1 texto pra mostrar — mas isso
        // NUNCA prova que são a mesma pessoa (type continua crossPerson).
        expect(index.suggestions.single.personId, 'person-a');
      },
    );

    test(
      'CROSS_PERSON_COLLISION independe da ordem: trocar QUAL personId está do lado goias/career não muda a regra (career sempre é o texto exibido)',
      () {
        final scenario1 = buildCareerAutocompleteIndex(
          careerPlayers: [_career('danilo_a', 'Danilo', personId: 'person-a')],
          goiasPlayers: [_goias('Danilo', personId: 'person-b')],
        );
        final scenario2 = buildCareerAutocompleteIndex(
          careerPlayers: [_career('danilo_b', 'Danilo', personId: 'person-b')],
          goiasPlayers: [_goias('Danilo', personId: 'person-a')],
        );
        for (final index in [scenario1, scenario2]) {
          expect(index.collisions.single.type, CareerCollisionType.crossPerson);
          expect(index.suggestions.single.label, 'Danilo');
        }
        // o personId exibido muda de acordo com QUAL personId estava do
        // lado career_players — prova que a prioridade é por FONTE, nunca
        // por valor de personId nem por posição nos arrays.
        expect(scenario1.suggestions.single.personId, 'person-a');
        expect(scenario2.suggestions.single.personId, 'person-b');
      },
    );

    test(
      'CROSS_PERSON_COLLISION independe da posição dentro de cada lista (embaralhar não muda o resultado)',
      () {
        final withDaniloFirst = buildCareerAutocompleteIndex(
          careerPlayers: [
            _career('danilo_a', 'Danilo', personId: 'person-a'),
            _career('outro', 'Outro Jogador', personId: 'person-z'),
          ],
          goiasPlayers: [
            _goias('Danilo', personId: 'person-b'),
            _goias('Ping'),
          ],
        );
        final withDaniloLast = buildCareerAutocompleteIndex(
          careerPlayers: [
            _career('outro', 'Outro Jogador', personId: 'person-z'),
            _career('danilo_a', 'Danilo', personId: 'person-a'),
          ],
          goiasPlayers: [
            _goias('Ping'),
            _goias('Danilo', personId: 'person-b'),
          ],
        );
        for (final index in [withDaniloFirst, withDaniloLast]) {
          final danilo = index.suggestions.firstWhere(
            (s) => s.label == 'Danilo',
          );
          expect(danilo.personId, 'person-a');
          expect(
            index.collisions
                .where((c) => c.normalizedText == 'danilo')
                .single
                .type,
            CareerCollisionType.crossPerson,
          );
        }
      },
    );

    test(
      'UNKNOWN_IDENTITY_COLLISION (1 nullable): career_players "Nicolas"->UUID Vichiatto, goias_players "Nicolas"->null -> tipo unknownIdentity, NUNCA samePerson',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: [
            _career('nicolas', 'Nicolas', personId: 'uuid-vichiatto'),
          ],
          goiasPlayers: [
            _goias('Nicolas'),
          ], // personId null — igual ao índice 178 real
        );
        expect(index.collisions, hasLength(1));
        expect(
          index.collisions.single.type,
          CareerCollisionType.unknownIdentity,
        );
        expect(index.unknownIdentityCollisions, 1);
        expect(
          index.samePersonCollisions,
          0,
          reason:
              'texto igual + 1 lado desconhecido NUNCA vira same-person só por inferência textual',
        );
        expect(index.crossPersonCollisions, 0);
        // DISPLAY_PRIORITY: career_players ainda vence a exibição.
        expect(index.suggestions.single.personId, 'uuid-vichiatto');
        expect(index.collisions.single.displayedPersonId, 'uuid-vichiatto');
        expect(index.collisions.single.otherPersonId, isNull);
      },
    );

    test(
      'UNKNOWN_IDENTITY_COLLISION (2 nullables): "Carlos Eduardo" nos 2 lados sem personId nenhum -> unknownIdentity, nunca afirma que são a mesma pessoa',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: [_career('carlos_eduardo', 'Carlos Eduardo')],
          goiasPlayers: [_goias('Carlos Eduardo')],
        );
        expect(index.collisions, hasLength(1));
        expect(
          index.collisions.single.type,
          CareerCollisionType.unknownIdentity,
        );
        expect(index.unknownIdentityCollisions, 1);
        expect(index.samePersonCollisions, 0);
        expect(index.suggestions.single.personId, isNull);
      },
    );

    test(
      'colisão entre 2 career_players DIFERENTES pro mesmo texto também é crossPerson, nunca escondida',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: [
            _career('x', 'Fulano', personId: 'person-x'),
            _career('y', 'Fulano', personId: 'person-y'),
          ],
          goiasPlayers: const [],
        );
        expect(index.crossPersonCollisions, 1);
        expect(index.suggestions, hasLength(1));
      },
    );

    test(
      'mesma pessoa em 2 datasets (mesmo personId) nunca é reportada como crossPerson/unknown — é samePerson',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: [_career('x', 'Fulano', personId: 'shared-id')],
          goiasPlayers: [_goias('Fulano', personId: 'shared-id')],
        );
        expect(index.crossPersonCollisions, 0);
        expect(index.unknownIdentityCollisions, 0);
        expect(index.samePersonCollisions, 1);
        expect(index.suggestions, hasLength(1));
        expect(index.suggestions.single.personId, 'shared-id');
      },
    );

    test(
      '1 lado sem personId (goiasPlayers ainda não resolvido) é unknownIdentity, nunca samePerson nem crossPerson',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: [_career('x', 'Fulano', personId: 'person-x')],
          goiasPlayers: [_goias('Fulano')],
        );
        expect(index.samePersonCollisions, 0);
        expect(index.crossPersonCollisions, 0);
        expect(index.unknownIdentityCollisions, 1);
        expect(index.suggestions.single.personId, 'person-x');
      },
    );
  });

  group('homônimos obrigatórios — nunca fundidos por texto reduzido', () {
    test(
      'Nicolas Godinho e Nicolas Vichiatto nunca colapsam numa única sugestão "Nicolas" com personId (dado real)',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: careerPlayers,
          goiasPlayers: goiasPlayers,
        );
        final nicolas = index.suggestions.where(
          (s) => s.normalizedLabel == 'nicolas',
        );
        expect(nicolas, hasLength(1));
        expect(
          nicolas.single.personId,
          isNull,
          reason:
              'ambíguo entre 2 pessoas reais — nunca resolvido sozinho por texto',
        );
      },
    );

    test(
      'Danilo (career_players, resolvido pra Danilo Gabriel de Andrade) nunca se mistura com Danilo Portugal/Danilo Dias (goiasPlayers, textos diferentes)',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: careerPlayers,
          goiasPlayers: goiasPlayers,
        );
        final danilo = index.suggestions.firstWhere((s) => s.label == 'Danilo');
        expect(danilo.personId, 'c628f9d8-6719-5506-acbd-adfb683fcf9b');
        final daniloPortugal = index.suggestions.firstWhere(
          (s) => s.label == 'Danilo Portugal',
        );
        final daniloDias = index.suggestions.firstWhere(
          (s) => s.label == 'Danilo Dias',
        );
        expect(daniloPortugal.personId, isNot(danilo.personId));
        expect(daniloDias.personId, isNot(danilo.personId));
      },
    );
  });

  group('gameplay permanece intocado', () {
    test(
      'personId nunca é usado como acceptedText — resolveMap sempre aponta pro texto real do jogo',
      () {
        final index = buildCareerAutocompleteIndex(
          careerPlayers: careerPlayers,
          goiasPlayers: goiasPlayers,
        );
        final uuidLike = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-');
        for (final value in index.resolveMap.values) {
          expect(uuidLike.hasMatch(value), isFalse, reason: value);
        }
      },
    );
  });
}
