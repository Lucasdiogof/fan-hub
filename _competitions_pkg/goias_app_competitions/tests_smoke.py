from collector.parser import parse_scorers, parse_statistics, parse_standings_tables, parse_match_page

edition = {"id":"brasileirao_a_2025_1599"}

scorer_html = '''
<html><body><h2>Campeonato Brasileiro - Série A 2025 Masculino</h2>
<ul><li>Tabela</li><li>Estatísticas</li><li>Artilharia</li><li>Classificação final</li><li>Outras edições</li></ul>
<div class="scorer"><div>1</div><div>Kaio Jorge</div><a href="/clubes/1/clube">Cruzeiro</a><div>21</div></div>
</body></html>'''
rows = parse_scorers(scorer_html, edition, "https://x.test/campeonatos/1599/edicao?aba=at")
assert rows and rows[0]["player_name_raw"] == "Kaio Jorge" and rows[0]["goals"] == 21, rows

stats_html = '''<html><body><div>380 jogos, 959 gols, média de 2,52 gols por jogo.</div>
<div>Melhor ataque Flamengo (78)</div><div>Melhor defesa Flamengo (27)</div>
<div>Maior invencibilidade Cruzeiro (12)</div></body></html>'''
st = parse_statistics(stats_html, edition, "https://x.test/stats")
assert st["matches"] == 380 and st["goals"] == 959 and abs(st["goals_per_match"]-2.52) < 0.001, st

stand_html = '''<table><tr><th></th><th>Time</th><th>P</th><th>J</th><th>V</th><th>E</th><th>D</th><th>GP</th><th>GC</th><th>S</th><th>%</th></tr>
<tr><td>1º</td><td><a href="/clubes/10/clube">Flamengo</a></td><td>79</td><td>38</td><td>23</td><td>10</td><td>5</td><td>78</td><td>27</td><td>51</td><td>69</td></tr></table>'''
stand = parse_standings_tables(stand_html, edition, "https://x.test/table")
assert stand and stand[0]["points"] == 79 and stand[0]["played"] == 38, stand

match_html = '''<html><body><h2>Copa X 2026</h2><div>Final</div><div>23/07/2026 20:00</div>
<a href="/clubes/1/clube">Brasil de Pelotas</a><span>2 (4) x (5) 1</span><a href="/clubes/2/clube">Gramadense</a></body></html>'''
m = parse_match_page(match_html, "https://x.test/partidas/999/partida", "ed_1")
assert m["score"] == {"home":2,"away":1,"penalties_home":4,"penalties_away":5,"raw":"2 (4) x (5) 1"}, m
print("smoke tests: OK")
