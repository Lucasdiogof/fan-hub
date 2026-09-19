"""Gera lib/assets/branding/goias/new_logo_splash.png a partir de new_logo.png
— mesmo mascote, com a MOLDURA de fundo (o degradê/vinheta verde ao redor)
puxada pra um verde CHAPADO #004C1B, pra eliminar o retangulo visivel
quando a imagem e centralizada sobre `ColoredBox(color: Color(0xFF004C1B))`
na SplashScreen. Nunca sobrescreve new_logo.png (continua intocado, usado
como app icon).

Método: flood-fill por similaridade de cor falhou (fundo e pelagem do
mascote sao tons de verde continuos, sem borda dura o bastante pra
separar) — ver histórico do script. Em vez de CLASSIFICAR pixel a pixel
como "fundo" ou "mascote", isto aplica uma CORREÇÃO ADITIVA suave: puxa
cada pixel em direção ao alvo (#004C1B), com força PROPORCIONAL À
DISTÂNCIA até o pixel mais próximo marcado como "conteúdo protegido"
(branco quase puro dos olhos/pelagem, amarelo do bico) — nunca um corte
binário, então nenhuma borda serrilhada, e a arte nunca é tocada de
verdade perto de qualquer marcador protegido.

Uso: python scripts/generate_splash_logo.py
"""

import os

import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "lib", "assets", "branding", "goias", "new_logo.png")
OUT = os.path.join(ROOT, "lib", "assets", "branding", "goias", "new_logo_splash.png")

TARGET = np.array([0, 76, 27], dtype=np.float64)  # #004C1B

# Raio (em px, na resolução original 1254x1254) a partir de qualquer pixel
# "protegido" (branco/amarelo — olhos, pelagem clara, bico) dentro do qual
# a correção fica sempre zero — nunca mexe perto da arte de verdade.
PROTECT_RADIUS = 20.0
# Transição de PROTECT_RADIUS até +PROTECT_FEATHER: 0 -> 1 suave.
PROTECT_FEATHER = 45.0

# Força baseada na distância até a BORDA da imagem — cheia (1.0) bem perto
# da borda, decaindo até 0 num raio maior, pra achatar toda a moldura ao
# redor do mascote (degradê + faixas de luz decorativas), não só um filete
# fino de 1px. A força final é o MENOR dos dois fatores (borda × proteção)
# — nunca mexe forte perto de um marcador protegido, mesmo bem na borda
# (cobre o caso da pena que chega a 19px da borda).
EDGE_FULL_RADIUS = 60.0
EDGE_FEATHER = 320.0


def smoothstep(t: np.ndarray) -> np.ndarray:
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3 - 2 * t)


def main() -> None:
    img = Image.open(SRC).convert("RGB")
    rgb = np.array(img).astype(np.float64)
    h, w, _ = rgb.shape

    white = (rgb[:, :, 0] > 185) & (rgb[:, :, 1] > 185) & (rgb[:, :, 2] > 185)
    yellow = (rgb[:, :, 0] > 140) & (rgb[:, :, 1] > 90) & (rgb[:, :, 2] < 90)
    protected = white | yellow
    print(f"pixels protegidos (branco+amarelo): {int(protected.sum())}")

    # distance_transform_edt mede, pra cada pixel, a distância até o pixel
    # MAIS PRÓXIMO onde `protected` é True (input invertido: ele mede
    # distância até `False`, por isso `~protected`).
    dist_to_protected = distance_transform_edt(~protected)
    protect_factor = smoothstep((dist_to_protected - PROTECT_RADIUS) / PROTECT_FEATHER)

    yy, xx = np.mgrid[0:h, 0:w]
    dist_edge = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))
    edge_factor = 1.0 - smoothstep((dist_edge - EDGE_FULL_RADIUS) / EDGE_FEATHER)

    strength = np.minimum(protect_factor, edge_factor)

    out = rgb + strength[:, :, None] * (TARGET[None, None, :] - rgb)
    out = np.clip(out, 0, 255).astype(np.uint8)

    Image.fromarray(out, mode="RGB").save(OUT)

    avg_strength = float(strength.mean())
    print(f"força média da correção: {avg_strength:.3f}")
    print(f"escrito: {os.path.relpath(OUT, ROOT)}")

    # Conferência específica: os pixels na borda literal da imagem (onde o
    # retângulo aparecia) devem ficar bem perto do alvo agora.
    border = np.concatenate(
        [out[0, :, :], out[-1, :, :], out[:, 0, :], out[:, -1, :]]
    ).astype(np.float64)
    err = np.sqrt(((border - TARGET) ** 2).sum(axis=1))
    print(
        f"erro de cor na borda literal — média {err.mean():.2f}, "
        f"máximo {err.max():.2f} (0 = idêntico ao alvo)"
    )


if __name__ == "__main__":
    main()
