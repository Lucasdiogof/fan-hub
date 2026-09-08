/// Fotos dos jogadores HISTÓRICOS do Goiás no "Quem Vestiu o Manto?" —
/// padronizadas em fundo branco e todas `.png` (o lote anterior misturava
/// `.jpg` e `.png` e fundos diferentes).
///
/// Separado de `squadPhotoAssets` de propósito: aquele é o elenco ATUAL, em
/// `lib/assets/squad/`, com o tratamento visual da aba Elenco. Os dois
/// conjuntos são disjuntos hoje (nenhum id em comum) e o clube junta os dois
/// em `goiasClubConfig.assets.guessPlayerPhotos`.
///
/// O nome traz o clube porque este mapa é do GOIÁS e de mais ninguém: até
/// 2026-09-08 ele era consultado como fallback global pelo repositório do
/// jogo, o que fazia qualquer clube sem foto própria herdar o rosto de um
/// jogador do Goiás. Não chegou a acontecer (nenhum id batia), mas `cleiton`
/// já é card do Bragantino e é nome comum o bastante pra colidir a qualquer
/// momento.
const goiasGuessPlayerPhotos = {
  'alex_dias': 'lib/assets/games/guess_player/goias/alex_dias.png',
  'apodi': 'lib/assets/games/guess_player/goias/apodi.png',
  'bruno_melo': 'lib/assets/games/guess_player/goias/bruno_melo.png',
  'caio_vinicius': 'lib/assets/games/guess_player/goias/caio_vinicius.png',
  'david': 'lib/assets/games/guess_player/goias/david.png',
  'david_duarte': 'lib/assets/games/guess_player/goias/david_duarte.png',
  'diego_caito': 'lib/assets/games/guess_player/goias/diego_caito.png',
  'dill': 'lib/assets/games/guess_player/goias/dill.png',
  'dudu_cearense': 'lib/assets/games/guess_player/goias/dudu_cearense.png',
  'eduardo_sasha': 'lib/assets/games/guess_player/goias/eduardo_sasha.png',
  'egidio': 'lib/assets/games/guess_player/goias/egidio.png',
  'elvis': 'lib/assets/games/guess_player/goias/elvis.png',
  'erik': 'lib/assets/games/guess_player/goias/erik.png',
  'ernando': 'lib/assets/games/guess_player/goias/ernando.png',
  'everton_morelli': 'lib/assets/games/guess_player/goias/everton_morelli.png',
  'fellipe_bastos': 'lib/assets/games/guess_player/goias/fellipe_bastos.png',
  'fernandao': 'lib/assets/games/guess_player/goias/fernandao.png',
  'harlei': 'lib/assets/games/guess_player/goias/harlei.png',
  'jadilson': 'lib/assets/games/guess_player/goias/jadilson.png',
  'julian_palacios': 'lib/assets/games/guess_player/goias/julian_palacios.png',
  'lucas_halter': 'lib/assets/games/guess_player/goias/lucas_halter.png',
  'lucas_lovat': 'lib/assets/games/guess_player/goias/lucas_lovat.png',
  'maguinho': 'lib/assets/games/guess_player/goias/maguinho.png',
  'marcelo_rangel': 'lib/assets/games/guess_player/goias/marcelo_rangel.png',
  'matheus_peixoto': 'lib/assets/games/guess_player/goias/matheus_peixoto.png',
  'michael': 'lib/assets/games/guess_player/goias/michael.png',
  'otacilio_neto': 'lib/assets/games/guess_player/goias/otacilio_neto.png',
  'rafael_moura': 'lib/assets/games/guess_player/goias/rafael_moura.png',
  'rafael_toloi': 'lib/assets/games/guess_player/goias/rafael_toloi.png',
  'renan': 'lib/assets/games/guess_player/goias/renan.png',
  'renan_oliveira': 'lib/assets/games/guess_player/goias/renan_oliveira.png',
  'ricardo_goulart': 'lib/assets/games/guess_player/goias/ricardo_goulart.png',
  'rodrigo_andrade': 'lib/assets/games/guess_player/goias/rodrigo_andrade.png',
  'romerito': 'lib/assets/games/guess_player/goias/romerito.png',
  'souza': 'lib/assets/games/guess_player/goias/souza.png',
  'thiago_mendes': 'lib/assets/games/guess_player/goias/thiago_mendes.png',
  'titi': 'lib/assets/games/guess_player/goias/titi.png',
  'tulio_maravilha': 'lib/assets/games/guess_player/goias/tulio_maravilha.png',
  'vitor': 'lib/assets/games/guess_player/goias/vitor.png',
  'walter': 'lib/assets/games/guess_player/goias/walter.png',
  'willean_lepo': 'lib/assets/games/guess_player/goias/willean_lepo.png',
  'william_matheus': 'lib/assets/games/guess_player/goias/william_matheus.png',
  'willian_oliveira': 'lib/assets/games/guess_player/goias/willian_oliveira.png',
  'ze_hugo': 'lib/assets/games/guess_player/goias/ze_hugo.png',
  'ze_ricardo': 'lib/assets/games/guess_player/goias/ze_ricardo.png',
};
