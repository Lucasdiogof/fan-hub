import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Travas de identidade dos ídolos históricos (auditoria de 2026-10-01):
/// nomes parecidos nunca são fundidos e identidade sem prova nunca vira
/// certeza.
void main() {
  final braga = bragantinoClubConfig.institutionalContent.idols;
  final vila = vilaNovaClubConfig.institutionalContent.idols;
  final goias = goiasClubConfig.institutionalContent.idols;
  ClubIdol byName(List<ClubIdol> idols, String name) =>
      idols.firstWhere((i) => i.name == name);

  group('Bragantino', () {
    test('Nivaldo de 1965 é distinto do goleiro Nivaldo Penafiel', () {
      final nivaldo = byName(braga, 'Nivaldo "Queixo-de-mula"');
      expect(nivaldo.position, isNot('Goleiro'));
      expect(nivaldo.period, startsWith('1965'));
      expect(braga.where((i) => i.name.contains('Penafiel')), isEmpty);
    });

    test('o Marcelo da geração 1989–1992 é o Marcelo Martelotte, nunca o '
        'técnico Marcelo Veiga', () {
      final marcelo = byName(braga, 'Marcelo Martelotte');
      expect(marcelo.position, 'Goleiro');
      expect(braga.where((i) => i.name == 'Marcelo'), isEmpty);
      expect(braga.where((i) => i.name.contains('Veiga')), isEmpty);
    });

    test('Carlos Alberto Seixas não é tratado como passagem confirmada', () {
      expect(braga.where((i) => i.name.contains('Seixas')), isEmpty);
    });

    test('Alberto Félix sem a frase "maior craque" como fato', () {
      final alberto = byName(braga, 'Alberto Félix');
      expect(
        alberto.description.toLowerCase(),
        isNot(contains('maior craque')),
      );
    });
  });

  group('Goiás', () {
    test(
      'Josué não volta a ser "revelado pelo Goiás" (formador: Porto de Caruaru)',
      () {
        final josue = byName(goias, 'Josué');
        expect(josue.description, isNot(contains('revelado pelo Goiás')));
        expect(josue.description, contains('Porto'));
      },
    );

    test(
      'Cacau: atacante revelado pelo Goiás, SEM total geral (105/18 eram recorte do Brasileiro)',
      () {
        final cacau = byName(goias, 'Cacau');
        expect(cacau.position, 'Atacante');
        expect(cacau.description, contains('revelado pelo Goiás'));
        expect(cacau.matches, isNull);
        expect(cacau.goals, isNull);
      },
    );

    test(
      'Marquinhos é o lateral-esquerdo Marcos José Franklin Macena de Melo, 1997-2002',
      () {
        final marquinhos = byName(goias, 'Marquinhos');
        expect(marquinhos.fullName, 'Marcos José Franklin Macena de Melo');
        expect(marquinhos.position, 'Lateral-esquerdo');
        expect(marquinhos.period, '1997-2002');
        // Sem total de jogos/gols: nenhuma fonte do clube que feche.
        expect(marquinhos.matches, isNull);
        expect(marquinhos.goals, isNull);
      },
    );

    test('Araújo: maior artilheiro, 145 gols e 391 jogos (fonte oficial)', () {
      final araujo = byName(goias, 'Araújo');
      expect(
        araujo.description,
        contains('Maior artilheiro da história do Goiás'),
      );
      expect(araujo.goals, 145);
      expect(araujo.matches, 391);
    });

    test(
      'Dill: 135 gols (press kits 2026), sem total de jogos e sem "revelado"',
      () {
        final dill = byName(goias, 'Dill');
        expect(dill.goals, 135);
        expect(dill.matches, isNull);
        expect(dill.description.toLowerCase(), isNot(contains('revelado')));
        expect(dill.description, contains('Chegou ao Goiás em 1994'));
      },
    );

    test(
      'Ernando: 405 jogos (press kit oficial), gols sem fonte específica',
      () {
        final ernando = byName(goias, 'Ernando');
        expect(ernando.matches, 405);
        expect(ernando.goals, isNull);
      },
    );

    group('auditoria de 06/10/2026: recorte não vira total, divergência fica', () {
      test(
        'Walter: 97 jogos e 48 gols somando as duas passagens (ge 81/45 + 10/3 + 6/0)',
        () {
          final walter = byName(goias, 'Walter');
          expect(walter.goals, 48);
          expect(walter.matches, 97);
          expect(walter.statsScope, contains('duas passagens'));
          expect(walter.highlights.join(' '), contains('81 jogos e 45 gols'));
        },
      );

      test('Lúcio Bala: Lucenilde Pereira da Silva e Goiano 1996', () {
        final lucio = byName(goias, 'Lúcio Bala');
        expect(lucio.fullName, 'Lucenilde Pereira da Silva');
        expect(lucio.titles, ['Campeonato Goiano 1996']);
      });

      test('títulos individuais da rodada de 06/10/2026', () {
        expect(byName(goias, 'Kléber Guerra').titles, [
          for (final y in [1989, 1990, 1991, 1994, 1996, 1997, 1998])
            'Campeonato Goiano $y',
        ]);
        expect(
          byName(goias, 'Vítor').titles,
          containsAll([
            'Campeonato Goiano 2006',
            'Campeonato Goiano 2009',
            'Campeonato Goiano 2012',
            'Campeonato Goiano 2013',
            'Campeonato Brasileiro Série B 2012',
          ]),
        );
        final ernando = byName(goias, 'Ernando').titles;
        expect(
          ernando,
          containsAll([
            'Campeonato Goiano 2009',
            'Campeonato Goiano 2012',
            'Campeonato Goiano 2013',
            'Campeonato Brasileiro Série B 2012',
          ]),
        );
        // Goiano 2006 do Ernando: DIVERGENTE (2013 lista três) — não gravar.
        expect(ernando, isNot(contains('Campeonato Goiano 2006')));
        final marq = byName(goias, 'Marquinhos').titles;
        expect(
          marq,
          containsAll([
            'Copa Centro-Oeste 2000',
            'Copa Centro-Oeste 2001',
            'Copa Centro-Oeste 2002',
            'Campeonato Goiano 1997',
            'Campeonato Goiano 2000',
          ]),
        );
        // Goiano 2002 do Marquinhos: PENDENTE de prova nominal.
        expect(marq, isNot(contains('Campeonato Goiano 2002')));
      });

      test('rankings sempre datados (Lincoln 2021, Josué press kit 2026)', () {
        expect(
          byName(goias, 'Lincoln').highlights.join(' '),
          contains('16/08/2021'),
        );
        expect(
          byName(goias, 'Josué').highlights.join(' '),
          contains('press kit oficial do Goiás de 2026'),
        );
      });

      test(
        'Cacau e Ernando seguem sem gols; Paulo Baier 78 gols e sem jogos totais',
        () {
          expect(byName(goias, 'Cacau').goals, isNull);
          expect(byName(goias, 'Paulo Baier').goals, 78);
          expect(byName(goias, 'Paulo Baier').matches, isNull);
          expect(byName(goias, 'Ernando').goals, isNull);
        },
      );

      test('Brasileiro de 1983: colocação divergente (5º x 7º) fica fora', () {
        for (final name in ['Zé Teodoro', 'Luvanor']) {
          final texto = byName(goias, name).highlights.join(' ');
          expect(texto, contains('1983'), reason: name);
          expect(texto, isNot(contains('Quinto')), reason: name);
          expect(texto, isNot(contains('Sétimo')), reason: name);
        }
      });

      test('Iarley: 173 jogos e 47 gols (soma das quatro temporadas)', () {
        final iarley = byName(goias, 'Iarley');
        expect(iarley.matches, 173);
        expect(iarley.goals, 47);
      });

      test('Túlio: gols seguem com o escopo da fonte (93 x 96 divergem)', () {
        final tulio = byName(goias, 'Túlio Maravilha');
        expect(tulio.goals, 93);
        expect(tulio.statsScope, isNotNull);
      });

      test('totais confirmados pela auditoria', () {
        expect(byName(goias, 'Amaral').goals, 44);
        // 312 (Goiás) x 465 (ge/O Popular): divergência — sem total.
        expect(byName(goias, 'Kléber Guerra').matches, isNull);
        expect(byName(goias, 'Rafael Moura').goals, isNull);
        expect(byName(goias, 'Rafael Moura').matches, isNull);
      });

      test('recortes de uma competição nunca viram total', () {
        for (final name in [
          'Luvanor',
          'Dimba',
          'Matinha',
          'Carlos Alberto Santos',
        ]) {
          final idol = byName(goias, name);
          expect(idol.matches, isNull, reason: name);
          expect(idol.goals, isNull, reason: name);
        }
      });
    });

    test('nenhum ídolo repete nome', () {
      final names = goias.map((i) => i.name).toList();
      expect(names.toSet(), hasLength(names.length));
    });
  });

  group('Vila Nova', () {
    test('Gibrair é da geração do fim dos anos 1950/anos 1960', () {
      final gibrair = byName(vila, 'Gibrair Caetano');
      expect(gibrair.period, startsWith('195'));
      expect(gibrair.period, isNot(contains('197')));
      expect(gibrair.period, isNot(contains('198')));
    });

    test(
      'Luciano só entra como Luciano Goiano (fonte própria: O Popular '
      'o chama de ídolo), nunca como "Luciano" solto nem Luciano Mineiro',
      () {
        final lucianos = vila.where((i) => i.name.contains('Luciano'));
        expect(lucianos.map((i) => i.name), ['Luciano Goiano']);
        expect(lucianos.single.description, contains('25 gols'));
      },
    );

    test('Moisés: os dois goleadores da Série C 2015 são Frontini (9) e '
        'Moisés (8), nunca um trio com Robston', () {
      final moises = byName(vila, 'Moisés');
      expect(moises.description, contains('8 gols'));
      expect(moises.description, contains('Frontini'));
      expect(moises.description, isNot(contains('Robston')));
    });
  });
}
