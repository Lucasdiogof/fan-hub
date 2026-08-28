import sys
from collections import deque

from PIL import Image, ImageFilter

def remove_white_background(src_path, dst_path, tolerance=28, feather=1.5):
    img = Image.open(src_path).convert("RGBA")
    w, h = img.size
    px = img.load()

    visited = bytearray(w * h)
    mask = bytearray(w * h)  # 1 = background

    def is_bg(r, g, b):
        # distancia ao branco puro
        return (255 - r) + (255 - g) + (255 - b) <= tolerance

    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            idx = y * w + x
            if not visited[idx]:
                r, g, b, a = px[x, y]
                if is_bg(r, g, b):
                    visited[idx] = 1
                    mask[idx] = 1
                    q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            idx = y * w + x
            if not visited[idx]:
                r, g, b, a = px[x, y]
                if is_bg(r, g, b):
                    visited[idx] = 1
                    mask[idx] = 1
                    q.append((x, y))

    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                nidx = ny * w + nx
                if not visited[nidx]:
                    visited[nidx] = 1
                    r, g, b, a = px[nx, ny]
                    if is_bg(r, g, b):
                        mask[nidx] = 1
                        q.append((nx, ny))

    alpha_img = Image.new("L", (w, h), 255)
    apx = alpha_img.load()
    for y in range(h):
        for x in range(w):
            if mask[y * w + x]:
                apx[x, y] = 0

    # A borda entre o fundo branco e a camisa tem alguns pixels
    # "contaminados" pela cor branca (antialiasing/JPEG) — cortar exatamente
    # no limite deixa um halo claro. Encolhe a região opaca 2px antes de
    # suavizar, removendo esse anel contaminado.
    alpha_img = alpha_img.filter(ImageFilter.MinFilter(9))
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(feather))

    out = img.copy()
    out.putalpha(alpha_img)

    bbox = out.getbbox()
    if bbox:
        l, t, r, b = bbox
        pad = 12
        l = max(0, l - pad)
        t = max(0, t - pad)
        r = min(w, r + pad)
        b = min(h, b + pad)
        out = out.crop((l, t, r, b))

    out.save(dst_path, "PNG")
    print(f"saved {dst_path} ({out.size[0]}x{out.size[1]})")


if __name__ == "__main__":
    src = sys.argv[1]
    dst = sys.argv[2]
    remove_white_background(src, dst)
