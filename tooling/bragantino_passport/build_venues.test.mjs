// node --test tooling/bragantino_passport/build_venues.test.mjs
//
// O risco desta etapa não é ficar com uma linha a mais no catálogo — é
// FUNDIR duas casas diferentes e corromper "estádio mais visitado" pra
// sempre. Os testes abaixo cobrem os dois lados: agrupar o que é a mesma
// casa, e NÃO agrupar o que só parece.
import test from 'node:test';
import assert from 'node:assert/strict';

import { buildVenues } from './build_venues.mjs';

function match(stadium, extra = {}) {
  return {
    stadium,
    venue_city: 'Rio de Janeiro',
    venue_state: 'RJ',
    venue_country: 'BR',
    ...extra,
  };
}

function byDisplay(result, display) {
  return result.venues.find((v) => v.display_name === display);
}

test('grafias diferentes da mesma casa viram um venue só', () => {
  const result = buildVenues([
    match('Estádio Jornalista Mário Filho (Maracanã)'),
    match('Estadio Jornalista Mário Filho (Maracanã)'),
    match('Estádio Jornalista Mário Filho (Maracanã)'),
  ]);

  assert.equal(result.venues.length, 1);
  assert.equal(result.venues[0].display_name, 'Maracanã');
  assert.equal(result.venues[0].match_count, 3);
});

test('as grafias originais são preservadas como alias', () => {
  const result = buildVenues([
    match('Estádio Jornalista Mário Filho (Maracanã)'),
    match('Estadio Jornalista Mário Filho (Maracanã)'),
  ]);
  const aliases = [...result.venues[0].aliases];
  assert.equal(aliases.length, 2);
  assert.ok(aliases.includes('Estadio Jornalista Mário Filho (Maracanã)'));
});

test('nome comercial do patrocinador não vira estádio novo', () => {
  const result = buildVenues([
    match('Arena Fonte Nova', { venue_city: 'Salvador', venue_state: 'BA' }),
    match('Casa de Apostas Arena Fonte Nova', {
      venue_city: 'Salvador',
      venue_state: 'BA',
    }),
  ]);
  assert.equal(result.venues.length, 1);
  assert.equal(result.venues[0].display_name, 'Arena Fonte Nova');
});

test('espaço sobrando no fim não duplica o estádio', () => {
  const result = buildVenues([
    match('Arena do Grêmio', { venue_city: 'Porto Alegre', venue_state: 'RS' }),
    match('Arena do Grêmio ', { venue_city: 'Porto Alegre', venue_state: 'RS' }),
  ]);
  assert.equal(result.venues.length, 1);
  assert.equal(result.venues[0].match_count, 2);
  // Depois do trim as duas grafias são idênticas — nada a registrar.
  assert.equal(result.venues[0].aliases.size, 0);
});

test('estádios distintos que compartilham palavras NÃO são fundidos', () => {
  const result = buildVenues([
    match('Estadio Monumental Banco Pichincha', {
      venue_city: 'Guayaquil',
      venue_state: null,
      venue_country: 'EC',
    }),
    match('Estadio Monumental', {
      venue_city: 'Buenos Aires',
      venue_state: null,
      venue_country: 'AR',
    }),
  ]);
  assert.equal(result.venues.length, 2, 'Guayaquil e Buenos Aires são casas diferentes');
});

test('duas casas na mesma cidade continuam separadas', () => {
  const result = buildVenues([
    match('Nabi Abi Chedid', {
      venue_city: 'Bragança Paulista',
      venue_state: 'SP',
    }),
    match('Estádio Municipal Cícero de Souza Marques', {
      venue_city: 'Bragança Paulista',
      venue_state: 'SP',
    }),
  ]);
  assert.equal(result.venues.length, 2);
});

test('partida sem estádio confirmado não entra no catálogo', () => {
  const result = buildVenues([match(null), match('Arena MRV')]);
  assert.equal(result.venues.length, 1);
  assert.equal(result.mapping.length, 1);
});

test('cidade divergente pra mesma casa vira aviso, não escolha silenciosa', () => {
  const result = buildVenues([
    match('Arena MRV', { venue_city: 'Belo Horizonte', venue_state: 'MG' }),
    match('Arena MRV', { venue_city: 'Contagem', venue_state: 'MG' }),
  ]);
  assert.equal(result.venues.length, 1);
  assert.ok(result.warnings.some((w) => w.includes('city divergente')));
});

test('cidade sabidamente errada é descartada em vez de publicada', () => {
  const result = buildVenues([
    match('Estádio Dr. Alfredo de Castilho', {
      venue_city: 'Novo Horizonte',
      venue_state: 'SP',
    }),
  ]);
  const venue = byDisplay(result, 'Estádio Dr. Alfredo de Castilho');
  assert.equal(venue.city, null, 'melhor sem cidade do que com a errada');
  assert.ok(result.warnings.some((w) => w.includes('cidade descartada')));
});

test('cada partida com estádio recebe exatamente um venue_id', () => {
  const matches = [
    match('Arena MRV'),
    match('Estádio Jornalista Mário Filho (Maracanã)'),
    match('Estadio Jornalista Mário Filho (Maracanã)'),
  ];
  const result = buildVenues(matches);
  assert.equal(result.mapping.length, matches.length);
  const ids = new Set(result.venues.map((v) => v.id));
  for (const entry of result.mapping) assert.ok(ids.has(entry.venue_id));
});

test('ids são estáveis entre execuções', () => {
  const first = buildVenues([match('Arena MRV')]).venues[0].id;
  const second = buildVenues([match('Arena MRV')]).venues[0].id;
  assert.equal(first, second);
  assert.match(first, /^venue_[a-z0-9_]+$/, 'sem acento e sem espaço no id');
});
