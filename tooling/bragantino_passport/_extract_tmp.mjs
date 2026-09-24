import fs from 'fs';
const [,, inPath, outPath] = process.argv;
const raw = fs.readFileSync(inPath, 'utf8');
const arr = JSON.parse(raw);
let html = arr[0].text;
html = html.replace(/\\"/g, '"').replace(/\\n/g, '\n').replace(/\\\\/g, '\\');
fs.writeFileSync(outPath, html);
console.log('written', html.length, 'rows:', (html.match(/class="parent"/g) || []).length);
