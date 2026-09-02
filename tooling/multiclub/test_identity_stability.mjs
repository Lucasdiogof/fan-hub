// Testes de ESTABILIDADE DE IDENTIDADE (pedidos explicitamente após o bug
// encontrado: UUIDv5 calculado a partir da composição de fontes MUDA de
// UUID quando uma pessoa ganha uma fonte nova — inaceitável depois de FK).
// Roda contra person_registry.mjs com um registry SINTÉTICO em memória —
// nunca toca em tooling/multiclub/people_registry.json (o registry real).
import assert from 'assert';
import { emptyRegistry, resolvePersonId, registerNewPerson } from './person_registry.mjs';

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('1) Adicionar nova fonte não muda person_id');
test('pessoa registrada com [source1, source2] mantém o mesmo id ao ganhar source3', () => {
  const registry = emptyRegistry();
  const entry = registerNewPerson(registry, ['squad_members:tadeu', 'career_players:tadeu']);
  const idBefore = entry.personId;

  // "amanhã" alguém sincroniza uma fonte nova (cbf/official_site) pra essa
  // MESMA pessoa — o conjunto de membros ATUAL cresce, mas as founding keys
  // continuam sendo subconjunto.
  const resolved = resolvePersonId(registry, ['squad_members:tadeu', 'career_players:tadeu', 'cbf:12345', 'official_site:tadeu-antonio']);
  assert.strictEqual(resolved.status, 'matched');
  assert.strictEqual(resolved.personId, idBefore, 'person_id mudou ao ganhar uma fonte nova — exatamente o bug que este teste existe pra prevenir');
});

console.log('\n2) Corrigir nome não muda person_id');
test('nome canônico não faz parte da chave de identidade — id é só função dos member keys', () => {
  const registry = emptyRegistry();
  const entry = registerNewPerson(registry, ['goias_players_dart:9']);
  const idBefore = entry.personId;
  // "Lincoln" -> nome completo descoberto depois (ex.: pesquisa externa) —
  // NADA na chamada de resolvePersonId depende de nome, só de member keys.
  const resolved = resolvePersonId(registry, ['goias_players_dart:9']);
  assert.strictEqual(resolved.status, 'matched');
  assert.strictEqual(resolved.personId, idBefore);
});

console.log('\n3) Adicionar alias não muda person_id');
test('aliases não entram na chave de identidade — mesmo member set, id igual', () => {
  const registry = emptyRegistry();
  const entry = registerNewPerson(registry, ['goias_players_dart:9']);
  // alias "Leão da Serra" é dado de CONTEÚDO (canonical_name/aliases), não
  // de identidade (member keys) — resolvePersonId nunca recebe alias.
  const resolved = resolvePersonId(registry, ['goias_players_dart:9']);
  assert.strictEqual(resolved.personId, entry.personId);
});

console.log('\n4) Split verdadeiro gera IDs separados e ambos ficam estáveis depois');
test('Danilo/Nicolas/Michael continuam com IDs independentes após os splits, em runs futuros', () => {
  const registry = emptyRegistry();
  const danilo1 = registerNewPerson(registry, ['squad_members:danilo', 'guess_players:danilo_cunha_da_silva']);
  const danilo2 = registerNewPerson(registry, ['career_players:danilo', 'lineup_matches:danilo#2003_juventude_brA_reacao,2003_santos_brA_reacao']);
  assert.notStrictEqual(danilo1.personId, danilo2.personId);

  // run futuro: cada um ganha mais evidência, mas continuam resolvendo pro
  // id CERTO, nunca colidem um com o outro.
  const r1 = resolvePersonId(registry, ['squad_members:danilo', 'guess_players:danilo_cunha_da_silva', 'cbf:danilo-cunha-2026']);
  const r2 = resolvePersonId(registry, ['career_players:danilo', 'lineup_matches:danilo#2003_juventude_brA_reacao,2003_santos_brA_reacao', 'official_site:danilo-gabriel']);
  assert.strictEqual(r1.personId, danilo1.personId);
  assert.strictEqual(r2.personId, danilo2.personId);
  assert.notStrictEqual(r1.personId, r2.personId);
});

console.log('\n5) Registry vazio: pessoa nunca vista antes é sempre "new", nunca inventa match');
test('resolvePersonId contra registry vazio sempre retorna status=new', () => {
  const registry = emptyRegistry();
  const resolved = resolvePersonId(registry, ['squad_members:qualquer']);
  assert.strictEqual(resolved.status, 'new');
});

console.log('\n6) Match ambíguo (2+ entradas casam) nunca escolhe sozinho');
test('duas entradas cujas founding keys são subconjunto do mesmo cluster atual -> status=ambiguous', () => {
  const registry = emptyRegistry();
  registerNewPerson(registry, ['lineup_matches:x']);
  registerNewPerson(registry, ['lineup_matches:x', 'guess_players:x']);
  // um cluster atual que contém as founding keys das DUAS entradas ao mesmo
  // tempo — cenário degenerado, mas a resolução precisa recusar decidir.
  const resolved = resolvePersonId(registry, ['lineup_matches:x', 'guess_players:x', 'squad_members:x']);
  assert.strictEqual(resolved.status, 'ambiguous');
  assert.strictEqual(resolved.matches.length, 2);
});

console.log('\n7) canonicalPersonKey é sequencial e nunca reaproveitado');
test('duas pessoas novas seguidas recebem chaves sequenciais distintas', () => {
  const registry = emptyRegistry();
  const a = registerNewPerson(registry, ['x:1']);
  const b = registerNewPerson(registry, ['x:2']);
  assert.strictEqual(a.canonicalPersonKey, 'goias-app:multiclub:person:1');
  assert.strictEqual(b.canonicalPersonKey, 'goias-app:multiclub:person:2');
  assert.strictEqual(registry.nextSequence, 3);
});

console.log('\n8) UUIDv5 é determinístico a partir do canonicalPersonKey (não do member set)');
test('mesmo canonicalPersonKey sempre produz o mesmo personId, mesmo recomputado do zero', () => {
  const registryA = emptyRegistry();
  const entryA = registerNewPerson(registryA, ['x:1']);
  const registryB = emptyRegistry();
  const entryB = registerNewPerson(registryB, ['completamente diferente:999']); // member keys DIFERENTES
  // mas o PRIMEIRO registro de cada registry usa canonicalPersonKey
  // "...:person:1" — o personId é função do KEY, nunca dos member keys.
  assert.strictEqual(entryA.canonicalPersonKey, entryB.canonicalPersonKey);
  assert.strictEqual(entryA.personId, entryB.personId, 'personId deveria depender só do canonicalPersonKey, não dos member keys — se isso falhar, a regressão do UUID-por-composição voltou');
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length > 0) {
  console.log('\nFALHAS:');
  for (const f of failures) console.log(` - ${f.name}: ${f.err.message}`);
  process.exit(1);
}
