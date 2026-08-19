"""Rasteriza lib/assets/logo.svg em PNGs pra usar como fonte de ícone/splash
(flutter_launcher_icons / flutter_native_splash). PyMuPDF abre SVG nativamente
e devolve o alpha certinho, então dá pra recolorir só usando esse canal.

Uso: python scripts/generate_icon_assets.py
"""

import os

import pymupdf
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SVG_PATH = os.path.join(ROOT, "lib", "assets", "logo.svg")
OUT_DIR = os.path.join(ROOT, "assets_gen")

PRIMARY_GREEN = (0x00, 0x4C, 0x1B)


def rasterize_white_silhouette(size: int) -> Image.Image:
    doc = pymupdf.open(SVG_PATH)
    page = doc[0]
    zoom = size / max(page.rect.width, page.rect.height)
    pix = page.get_pixmap(matrix=pymupdf.Matrix(zoom, zoom), alpha=True)
    mode = "RGBA" if pix.alpha else "RGB"
    img = Image.frombytes(mode, (pix.width, pix.height), pix.samples).convert("RGBA")
    doc.close()
    return img


def recolor(silhouette: Image.Image, rgb: tuple[int, int, int]) -> Image.Image:
    """Troca a cor mantendo o alpha — equivalente ao ColorFilter.mode srcIn do Flutter."""
    alpha = silhouette.split()[3]
    solid = Image.new("RGBA", silhouette.size, rgb + (255,))
    solid.putalpha(alpha)
    return solid


def centered_on(canvas_size: int, content: Image.Image, scale_factor: float) -> Image.Image:
    content_size = int(canvas_size * scale_factor)
    resized = content.resize((content_size, content_size), Image.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = (canvas_size - content_size) // 2
    canvas.paste(resized, (offset, offset), resized)
    return canvas


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    white = rasterize_white_silhouette(1024)

    # Ícone completo: fundo verde sólido + logo branco com respiro.
    icon_bg = Image.new("RGBA", (1024, 1024), PRIMARY_GREEN + (255,))
    icon_fg = centered_on(1024, white, 0.62)
    icon = Image.alpha_composite(icon_bg, icon_fg)
    icon.convert("RGB").save(os.path.join(OUT_DIR, "app_icon.png"))

    # Foreground do ícone adaptativo Android: transparente, na safe zone central.
    foreground = centered_on(1024, white, 0.5)
    foreground.save(os.path.join(OUT_DIR, "app_icon_foreground.png"))

    # Logo pra splash: transparente, tingido de verde.
    green = recolor(white, PRIMARY_GREEN)
    splash = centered_on(512, green, 0.8)
    splash.save(os.path.join(OUT_DIR, "splash_logo.png"))

    print("Gerado:")
    for name in ("app_icon.png", "app_icon_foreground.png", "splash_logo.png"):
        path = os.path.join(OUT_DIR, name)
        with Image.open(path) as img:
            print(f"  {name}: {img.size} {img.mode}")


if __name__ == "__main__":
    main()
