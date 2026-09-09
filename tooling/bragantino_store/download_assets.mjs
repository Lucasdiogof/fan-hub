// Baixa as imagens reais dos 143 produtos coletados e reescreve
// images/thumbnail para paths locais (mesmo padrão do Goiás:
// lib/assets/store/products/<id>/thumbnail.jpg, front.jpg, ...). Roda uma
// vez, offline — nunca chamado pelo app em runtime.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RAW_DIR = path.join(__dirname, 'raw');
const ASSETS_DIR = path.join(ROOT, 'lib', 'assets', 'store', 'products', 'bragantino');

const products = JSON.parse(fs.readFileSync(path.join(RAW_DIR, 'products_remote_images.json'), 'utf8'));

const NAMES = ['thumbnail', 'front', 'back', 'detail', 'detail_2', 'detail_3', 'detail_4', 'detail_5', 'detail_6'];

async function download(url, destPath) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${res.status} ${url}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(destPath, buf);
  return buf.length;
}

async function main() {
  fs.mkdirSync(ASSETS_DIR, { recursive: true });
  let totalBytes = 0;
  let totalFiles = 0;
  const failures = [];
  const finalProducts = [];

  for (const p of products) {
    const productDir = path.join(ASSETS_DIR, p.id.replace(/^bragantino_/, ''));
    fs.mkdirSync(productDir, { recursive: true });
    const localImages = [];
    for (let i = 0; i < p.images.length; i++) {
      const url = p.images[i];
      const name = NAMES[i] || `extra_${i}`;
      const destFile = `${name}.jpg`;
      const destPath = path.join(productDir, destFile);
      const relPath = `lib/assets/store/products/bragantino/${p.id.replace(/^bragantino_/, '')}/${destFile}`;
      try {
        if (fs.existsSync(destPath) && fs.statSync(destPath).size > 0) {
          totalBytes += fs.statSync(destPath).size;
        } else {
          const size = await download(url, destPath);
          totalBytes += size;
        }
        totalFiles++;
        localImages.push(relPath);
      } catch (err) {
        failures.push({ id: p.id, url, error: String(err) });
      }
    }
    finalProducts.push({
      ...p,
      images: localImages,
      thumbnail: localImages[0] || null,
      _gid: undefined,
    });
  }

  fs.writeFileSync(
    path.join(RAW_DIR, 'download_report.json'),
    JSON.stringify({ totalFiles, totalBytes, totalMB: (totalBytes / 1024 / 1024).toFixed(2), failures }, null, 2),
  );

  const OUT_JSON_DIR = path.join(ROOT, 'lib', 'assets', 'content', 'bragantino');
  fs.mkdirSync(OUT_JSON_DIR, { recursive: true });
  const cleaned = finalProducts.map(({ _gid, ...rest }) => rest);
  fs.writeFileSync(path.join(OUT_JSON_DIR, 'store_products.json'), JSON.stringify(cleaned, null, 2));

  console.log(JSON.stringify({ totalFiles, totalBytes, totalMB: (totalBytes / 1024 / 1024).toFixed(2), failuresCount: failures.length, failures }, null, 2));
}

main().catch(err => { console.error(err); process.exit(1); });
