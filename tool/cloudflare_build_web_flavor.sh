#!/usr/bin/env bash
# Build command real do Cloudflare Workers Builds (Git integration) pra
# qualquer flavor web deste projeto — 1 script genérico + argumento do
# clube, nunca um script por clube (goias/bragantino usam o MESMO).
#
# Causa raiz confirmada pelo log real da Cloudflare em 2026-09-04:
#   "/bin/sh: 1: flutter: not found"
# O ambiente de build da Cloudflare Workers Builds clona o repo e roda npm
# normalmente, mas NÃO tem o Flutter SDK pré-instalado — só Node. Este
# script existe pra resolver exatamente isso, sem depender de nada manual
# no dashboard.
#
# Uso:
#   bash tool/cloudflare_build_web_flavor.sh goias
#   bash tool/cloudflare_build_web_flavor.sh bragantino
set -euo pipefail

CLUB="${1:-}"
if [ -z "$CLUB" ]; then
  echo "error: uso: bash tool/cloudflare_build_web_flavor.sh <goias|bragantino>" >&2
  exit 1
fi
if [ "$CLUB" != "goias" ] && [ "$CLUB" != "bragantino" ]; then
  echo "error: clube desconhecido \"$CLUB\" -- esperado exatamente \"goias\" ou \"bragantino\", nunca resolvido por fallback." >&2
  exit 1
fi

# Versão FIXA, nunca "latest" -- derivada do ambiente real usado pra
# desenvolver/testar este projeto (`flutter --version` local em
# 2026-09-04: Flutter 3.44.1 stable, Dart 3.12.1 -- bate com o
# `environment.sdk: ^3.12.1` de pubspec.yaml). Atualize as duas linhas
# abaixo junto, deliberadamente, se o projeto migrar de versão -- nunca
# deixe a máquina de build escolher sozinha.
FLUTTER_VERSION="3.44.1"
FLUTTER_CHANNEL="stable"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Cache entre builds quando o ambiente persistir o diretório (Cloudflare
# Workers Builds cacheia certos paths de um build pro próximo, mas o
# mecanismo exato de opt-in pra caches customizados não está documentado
# aqui de forma confirmada nesta sessão -- por isso o script SEMPRE checa
# se o SDK já existe antes de baixar, funcionando corretamente com ou sem
# persistência: melhor caso, reaproveita; pior caso, baixa nesta build e
# seria reaproveitado numa futura se o ambiente vier a persistir /tmp.
# Nunca dentro do repo, nunca versionado -- só um cache de máquina.
CACHE_ROOT="${FLUTTER_SDK_CACHE_DIR:-/tmp/flutter-sdk-cache}"
FLUTTER_INSTALL_DIR="${CACHE_ROOT}/${FLUTTER_VERSION}-${FLUTTER_CHANNEL}"

if command -v flutter >/dev/null 2>&1; then
  echo "flutter já está no PATH ($(command -v flutter)) -- usando o existente, nunca baixando por cima (é o caso normal pra build local/CI que já tem o SDK)."
else
  if [ -x "${FLUTTER_INSTALL_DIR}/flutter/bin/flutter" ]; then
    echo "Flutter ${FLUTTER_VERSION} (${FLUTTER_CHANNEL}) já em cache em ${FLUTTER_INSTALL_DIR} -- reaproveitando, sem baixar de novo."
  else
    echo "flutter não encontrado no PATH -- baixando Flutter ${FLUTTER_VERSION} (${FLUTTER_CHANNEL}) linux em ${FLUTTER_INSTALL_DIR}..."
    mkdir -p "${FLUTTER_INSTALL_DIR}"
    ARCHIVE_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
    curl -fsSL "$ARCHIVE_URL" -o "${FLUTTER_INSTALL_DIR}/flutter.tar.xz"
    tar -xJf "${FLUTTER_INSTALL_DIR}/flutter.tar.xz" -C "${FLUTTER_INSTALL_DIR}"
    rm -f "${FLUTTER_INSTALL_DIR}/flutter.tar.xz"
  fi
  export PATH="${FLUTTER_INSTALL_DIR}/flutter/bin:${PATH}"
fi

# Nunca precisa de Android SDK/Xcode -- só o build web usa este script, e
# `flutter config` desliga a checagem de toolchains que este ambiente não
# tem (evita warnings/tempo perdido detectando Android/iOS que não existem
# aqui).
flutter config --no-analytics >/dev/null 2>&1 || true

echo "=== flutter --version ==="
flutter --version

echo "=== flutter pub get ==="
cd "$ROOT_DIR"
flutter pub get

echo "=== node tool/build_web_flavor.mjs ${CLUB} ==="
node tool/build_web_flavor.mjs "${CLUB}"
