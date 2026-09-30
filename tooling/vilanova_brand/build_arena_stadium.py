"""Gera `lib/assets/branding/vilanova/arena_stadium.png` — a marca d'água de
estádio do card "Arena Vila Nova" na Home (ver `ArenaSpotlightCard`).

NÃO é o estádio oficial do Vila (OBA) nem nenhum estádio real específico —
é o MESMO render 3D genérico já usado por Goiás (verde,
`lib/assets/branding/goias/arena_stadium.png`) e Bragantino (azul,
`lib/assets/branding/bragantino/arena_stadium.png`), reconvertido em duotone
com a cor oficial do Vila (#C33D41). Cada clube só recolore a mesma imagem
de origem — nunca redesenha, nunca finge ser uma foto do estádio de verdade.

Uso:  python tooling/vilanova_brand/build_arena_stadium.py
"""

import pathlib

from PIL import Image, ImageOps

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "lib/assets/branding/bragantino/arena_stadium.png"
OUT = ROOT / "lib/assets/branding/vilanova/arena_stadium.png"

# Sombra quase-preta com leve matiz vermelho; highlight um pouco mais claro
# que o vermelho oficial (#C33D41) pra dar a sensação de "brilho" no ponto
# mais claro do render — mesmo espírito das versões verde/azul.
SHADOW = (10, 3, 4)
HIGHLIGHT = (211, 85, 90)


def main() -> None:
    img = Image.open(SRC).convert("L")
    # A imagem de origem nunca usa a faixa 0-255 inteira (o pixel mais claro
    # do render do Bragantino é ~117 de luminância) — sem isso a versão
    # recolorida fica visivelmente mais apagada que Goiás/Bragantino.
    img = ImageOps.autocontrast(img, cutoff=0)

    lut_r = [SHADOW[0] + (HIGHLIGHT[0] - SHADOW[0]) * i // 255 for i in range(256)]
    lut_g = [SHADOW[1] + (HIGHLIGHT[1] - SHADOW[1]) * i // 255 for i in range(256)]
    lut_b = [SHADOW[2] + (HIGHLIGHT[2] - SHADOW[2]) * i // 255 for i in range(256)]

    r = img.point(lut_r)
    g = img.point(lut_g)
    b = img.point(lut_b)
    out = Image.merge("RGB", (r, g, b))
    out.save(OUT)
    print(f"saved {OUT} {out.size}")


if __name__ == "__main__":
    main()
