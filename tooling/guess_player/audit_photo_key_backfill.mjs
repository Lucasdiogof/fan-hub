#!/usr/bin/env node
// Auditoria 2026-09-05 (achado no Bloco 4 do fechamento do Goiás): o
// `photo_key` de `supabase/guess_players.sql` só é resolvido em produção
// contra `squadPhotoAssets` OU `guessPlayerPhotoAssets` (ver
// guess_player_repository.dart) — mas o seed original nunca escreveu
// photo_key pros jogadores do 2º mapa. Este script cruza os 3 arquivos
// (mapa de fotos, catálogo Dart, seed SQL) e reporta: quantos assets
// existem, quantos jogadores os usam, quantos já estão corretos no seed,
// órfãos e referências quebradas — nunca lê/escreve o Supabase real.
import { readFileSync } from 'node:fs';

const PHOTOS_PATH = 'lib/features/arena/games/guess_player/domain/guess_player_photos.dart';
const SQUAD_PHOTOS_PATH = 'lib/features/squad/domain/squad_photos.dart';
const CATALOG_PATH = 'lib/features/arena/games/guess_player/data/guess_player_catalog.dart';
const SEED_PATH = 'supabase/guess_players.sql';

function extractAssetKeys(path) {
  const src = readFileSync(path, 'utf8');
  return new Set([...src.matchAll(/'([a-z0-9_]+)':\s*'lib\/assets/g)].map((m) => m[1]));
}

function extractCatalogPlayers(path) {
  const src = readFileSync(path, 'utf8');
  const blocks = src.split(/(?=(?:const )?GuessPlayer\()/);
  const players = [];
  for (const block of blocks) {
    const idMatch = block.match(/id: '([a-z0-9_]+)'/);
    if (!idMatch) continue;
    const statusMatch = block.match(/dataStatus: GuessPlayerDataStatus\.(\w+)/);
    const guessKeyMatch = block.match(/imageUrl: guessPlayerPhotoAssets\['([a-z0-9_]+)'\]/);
    players.push({
      id: idMatch[1],
      status: statusMatch ? statusMatch[1] : null,
      guessKey: guessKeyMatch ? guessKeyMatch[1] : null,
    });
  }
  return players;
}

function extractSeedIds(path) {
  const src = readFileSync(path, 'utf8');
  return new Set([...src.matchAll(/^\('([a-z0-9_]+)',/gm)].map((m) => m[1]));
}

export function runAudit() {
  const guessPhotoKeys = extractAssetKeys(PHOTOS_PATH);
  const squadPhotoKeys = extractAssetKeys(SQUAD_PHOTOS_PATH);
  const players = extractCatalogPlayers(CATALOG_PATH);
  const seedIds = extractSeedIds(SEED_PATH);

  const usedGuessKeys = new Set(players.map((p) => p.guessKey).filter(Boolean));

  const orphanAssets = [...guessPhotoKeys].filter((k) => !usedGuessKeys.has(k));
  const brokenRefs = [...usedGuessKeys].filter((k) => !guessPhotoKeys.has(k));
  const playersUsingGuessPhotos = players.filter((p) => p.guessKey);
  const missingFromSeed = playersUsingGuessPhotos.filter((p) => !seedIds.has(p.id)).map((p) => p.id);
  const presentInSeed = playersUsingGuessPhotos.filter((p) => seedIds.has(p.id)).map((p) => p.id);

  return {
    totalGuessPhotoAssets: guessPhotoKeys.size,
    totalSquadPhotoAssets: squadPhotoKeys.size,
    totalCatalogPlayers: players.length,
    playersUsingGuessPhotos: playersUsingGuessPhotos.length,
    orphanAssets,
    brokenRefs,
    missingFromSeed,
    presentInSeedIds: presentInSeed,
  };
}

import { pathToFileURL } from 'node:url';

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const result = runAudit();
  console.log(JSON.stringify(result, null, 2));
}
