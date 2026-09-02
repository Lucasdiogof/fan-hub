// Normalização de alias pra lookup — Unicode-aware (v2). `person_aliases`
// é uma entidade GLOBAL (jogadores de qualquer país eventualmente), então
// a normalização NÃO pode assumir ASCII/português como universo — a v1
// desta função (`replace(/[^a-z0-9\s]/g, ' ')`) apagava qualquer letra
// fora de a-z, o que destruiria "Søren"/"Łukasz" (ø/ł não são combining
// marks, são LETRAS próprias do alfabeto — NFKD não as decompõe, e
// filtrar por [a-z0-9] as removeria silenciosamente).
//
// O QUE FAZ, exatamente nesta ordem:
//   1. Unicode NFKD (decomposição de COMPATIBILIDADE, mais abrangente que
//      NFD — decompõe também formas de compatibilidade, ex. ligaduras).
//   2. Remove os combining marks resultantes (\p{M}+, categoria Unicode
//      "Mark" — é isso que tira o acento de "á"→"a"+´, nunca a letra
//      base em si).
//   3. minúsculas.
//   4. Qualquer caractere que NÃO seja letra Unicode (\p{L}) nem número
//      Unicode (\p{N}) vira ESPAÇO — cobre hífen, apóstrofo, ponto etc.
//      como separador (nunca removido silenciosamente), mas PRESERVA
//      qualquer letra de qualquer alfabeto (ø, ł, ñ, ç depois de perder
//      cedilha seria "c" via NFKD+mark removal — mas ø/ł não têm mark
//      pra remover, ficam intactos).
//   5. Colapsa espaços múltiplos em 1 só.
//   6. trim.
//
// GARANTIDO (testado em test_person_aliases.mjs):
//   "Rafael Tolói" / "rafael toloi" / "RAFAEL TOLÓI" -> "rafael toloi"
//   "João-Paulo" / "João Paulo" -> "joao paulo" (hífen vira espaço)
//   "D'Angelo" -> "d angelo" (apóstrofo vira espaço)
//   "Søren" -> "søren" (ø É letra, fica intacto — NUNCA "s ren"/"soren")
//   "Łukasz Piszczek" -> "łukasz piszczek" (ł É letra, fica intacto)
//   "Müller" -> "muller" (ü tem combining mark sob NFKD, essa sim remove)
//
// DELIBERADAMENTE NÃO FEITO (transliteração seria inventar equivalência
// sem evidência — mesma regra usada em toda a reconciliação):
//   "søren" != "soren" — se um dia precisarmos da forma ASCII, ela entra
//   como alias EXPLÍCITO (linha própria em person_aliases), nunca como
//   normalização automática que colapsa as duas strings numa só.
export function normalizeAlias(value) {
  return String(value)
    .normalize('NFKD')
    .replace(/\p{M}+/gu, '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}
