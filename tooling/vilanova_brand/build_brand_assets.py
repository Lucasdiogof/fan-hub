"""Gera os assets de marca do flavor `vilanova` a partir do material OFICIAL do clube.

Fontes (baixar em `--src`, ver `docs/vila_nova_data/data/branding.json`):
  - vetor-escudo-vila-nova-fc-oficial-pdf-713650.pdf  (3 páginas: colorido sobre
    vermelho, monocromático sobre branco, branco vazado sobre vermelho)
  - manual-de-identidade-visual-vila-nova-fc-136400.pdf (pág. 9: cor oficial
    C0 M93 Y73 K0 / RGB 195,61,65 / #C33D41 / PANTONE 18-1563 TPG)

Nada aqui é redesenhado: os SVGs são as próprias formas vetoriais do PDF
oficial (só o retângulo de fundo da página é descartado) e todo raster é
renderizado desses SVGs.

Uso:  python tooling/vilanova_brand/build_brand_assets.py --src <pasta_com_os_pdfs>
"""

import argparse
import json
import pathlib

import pymupdf
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[2]
BRANDING = ROOT / "lib/assets/branding/vilanova"

# Vermelho de FUNDO da "aplicação principal" do manual (retângulo da pág. 1 do
# vetor oficial) — é o fundo que o próprio clube usa atrás do escudo.
CREST_BG = (0xD3, 0x26, 0x29)
# Vinhos do fundo de login (derivados da cor oficial #C33D41, escurecidos).
LOGIN_TOP = (0x4A, 0x10, 0x13)
LOGIN_BOTTOM = (0x1C, 0x05, 0x06)
LOGIN_GLOW = (0xC3, 0x3D, 0x41)


def _hex(rgb):
    return "#%02x%02x%02x" % tuple(round(c * 255) for c in rgb)


def page_to_svg(page, pad=2.0):
    """SVG com as formas do escudo (sem o retângulo de fundo), viewBox justo."""
    drawings = page.get_drawings()[1:]  # [0] = fundo da página
    x0 = min(d["rect"].x0 for d in drawings) - pad
    y0 = min(d["rect"].y0 for d in drawings) - pad
    x1 = max(d["rect"].x1 for d in drawings) + pad
    y1 = max(d["rect"].y1 for d in drawings) + pad
    paths = []
    for d in drawings:
        cmds = []
        last = None
        for item in d["items"]:
            op = item[0]
            if op == "l":
                a, b = item[1], item[2]
                if last is None or (abs(last.x - a.x) > 1e-3 or abs(last.y - a.y) > 1e-3):
                    cmds.append(f"M{a.x - x0:.3f} {a.y - y0:.3f}")
                cmds.append(f"L{b.x - x0:.3f} {b.y - y0:.3f}")
                last = b
            elif op == "c":
                a, c1, c2, b = item[1:5]
                if last is None or (abs(last.x - a.x) > 1e-3 or abs(last.y - a.y) > 1e-3):
                    cmds.append(f"M{a.x - x0:.3f} {a.y - y0:.3f}")
                cmds.append(
                    f"C{c1.x - x0:.3f} {c1.y - y0:.3f} {c2.x - x0:.3f} {c2.y - y0:.3f} "
                    f"{b.x - x0:.3f} {b.y - y0:.3f}"
                )
                last = b
            elif op == "re":
                r = item[1]
                cmds.append(
                    f"M{r.x0 - x0:.3f} {r.y0 - y0:.3f}H{r.x1 - x0:.3f}V{r.y1 - y0:.3f}"
                    f"H{r.x0 - x0:.3f}Z"
                )
                last = None
            elif op == "qu":
                q = item[1]
                pts = [q.ul, q.ur, q.lr, q.ll]
                cmds.append(
                    "M" + "L".join(f"{p.x - x0:.3f} {p.y - y0:.3f}" for p in pts) + "Z"
                )
                last = None
            else:
                raise ValueError(f"operador de path não suportado: {op}")
        if d.get("closePath"):
            cmds.append("Z")
        rule = "evenodd" if d.get("even_odd") else "nonzero"
        paths.append(
            f'<path fill="{_hex(d["fill"])}" fill-rule="{rule}" d="{"".join(cmds)}"/>'
        )
    w, h = x1 - x0, y1 - y0
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.3f} {h:.3f}">'
        + "".join(paths)
        + "</svg>\n"
    )


def render_svg(svg_text, height):
    doc = pymupdf.open(stream=svg_text.encode(), filetype="svg")
    page = doc[0]
    zoom = height / page.rect.height
    pix = page.get_pixmap(matrix=pymupdf.Matrix(zoom, zoom), alpha=True)
    return Image.frombytes("RGBA", (pix.width, pix.height), pix.samples)


def fit_on_canvas(crest, size, fill_ratio, bg=None):
    """Escudo centralizado num quadrado `size`, ocupando `fill_ratio` da altura."""
    canvas = Image.new("RGBA", (size, size), bg + (255,) if bg else (0, 0, 0, 0))
    target_h = int(size * fill_ratio)
    c = crest.resize(
        (max(1, round(crest.width * target_h / crest.height)), target_h), Image.LANCZOS
    )
    canvas.alpha_composite(c, ((size - c.width) // 2, (size - c.height) // 2))
    return canvas


def login_background(crest):
    w, h = 1170, 2532
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        draw.line(
            [(0, y), (w, y)],
            fill=tuple(round(a + (b - a) * t) for a, b in zip(LOGIN_TOP, LOGIN_BOTTOM)),
        )
    cy = int(h * 0.30)
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((w * 0.5 - 520, cy - 520, w * 0.5 + 520, cy + 520), fill=150)
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    img = Image.composite(Image.new("RGB", (w, h), LOGIN_GLOW), img, glow)
    img = img.convert("RGBA")
    c = crest.resize((round(crest.width * 560 / crest.height), 560), Image.LANCZOS)
    img.alpha_composite(c, ((w - c.width) // 2, cy - c.height // 2))
    return img.convert("RGB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, type=pathlib.Path)
    args = ap.parse_args()

    vector = pymupdf.open(args.src / "vetor-escudo-vila-nova-fc-oficial-pdf-713650.pdf")
    color_svg = page_to_svg(vector[0])  # escudo colorido (#EF3746 + branco)
    white_svg = page_to_svg(vector[2])  # escudo branco vazado (só branco)

    BRANDING.mkdir(parents=True, exist_ok=True)
    (BRANDING / "crest.svg").write_text(color_svg, encoding="utf-8")
    # Selo do cadastro é tingido de branco (`ColorFilter.mode(white, srcIn)`):
    # precisa das formas brancas sobre transparente pra manter os vazados.
    (BRANDING / "crest_seal.svg").write_text(white_svg, encoding="utf-8")

    crest = render_svg(color_svg, 2048)
    fit_on_canvas(crest, 512, 0.92).save(BRANDING / "crest_badge.png", optimize=True)
    login_background(crest).save(BRANDING / "login_background.png", optimize=True)

    # Ícones = "aplicação principal" do manual: escudo colorido sobre o vermelho.
    def app_icon(size, ratio=0.72):
        return fit_on_canvas(crest, size, ratio, bg=CREST_BG).convert("RGB")

    web = BRANDING / "web_icons"
    web.mkdir(exist_ok=True)
    for s in (192, 512):
        app_icon(s).save(web / f"Icon-{s}.png", optimize=True)
        app_icon(s, 0.60).save(web / f"Icon-maskable-{s}.png", optimize=True)
    app_icon(16, 0.90).save(web / "favicon.png", optimize=True)

    res = ROOT / "android/app/src/vilanova/res"
    for dpi, legacy, fg in (
        ("mdpi", 48, 108),
        ("hdpi", 72, 162),
        ("xhdpi", 96, 216),
        ("xxhdpi", 144, 324),
        ("xxxhdpi", 192, 432),
    ):
        app_icon(legacy).save(res / f"mipmap-{dpi}/ic_launcher.png", optimize=True)
        # Foreground adaptativo: o XML já aplica inset de 16%.
        fit_on_canvas(crest, fg, 0.80).save(
            res / f"drawable-{dpi}/ic_launcher_foreground.png", optimize=True
        )
    (res / "values/colors.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        "    <!-- Vermelho de fundo da aplicação principal do manual oficial. -->\n"
        '    <color name="ic_launcher_background">#D32629</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )

    appicon = ROOT / "ios/Runner/Assets.xcassets/AppIcon-VilaNova.appiconset"
    contents = json.loads((appicon / "Contents.json").read_text(encoding="utf-8"))
    for img in contents["images"]:
        if "filename" not in img:
            continue
        base = float(img["size"].split("x")[0])
        px = round(base * int(img["scale"].rstrip("x")))
        app_icon(px).save(appicon / img["filename"], optimize=True)  # iOS: sem alpha

    print("ok:", BRANDING)


if __name__ == "__main__":
    main()
