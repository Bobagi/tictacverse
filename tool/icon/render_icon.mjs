// Renderiza tool/icon/icon.svg no Chrome headless e gera:
//   assets/icon/app_icon.png (1024, ícone completo, também vira o 512 da loja)
//   assets/icon/icon_bg.png  (1024, só o fundo, camada de trás do adaptativo)
//   assets/icon/icon_fg.png  (1024, só as peças, encolhidas para 72% (dentro da zona segura do adaptativo))
// Uso: PATH=/opt/node-v22/bin:$PATH node tool/icon/render_icon.mjs
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import os from 'node:os'; import path from 'node:path';
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../..');
const m = await import(path.join(os.homedir(), '.claude/skills/frontend-review/node_modules/puppeteer-core/lib/puppeteer/puppeteer-core.js'));
const puppeteer = m.default || m;
const chrome = execSync(`ls -1 ${os.homedir()}/.cache/puppeteer/chrome/*/chrome-linux*/chrome | head -1`, { encoding: 'utf8' }).trim();
const svg = readFileSync(path.join(root, 'tool/icon/icon.svg'), 'utf8');
const b = await puppeteer.launch({ executablePath: chrome, headless: true, args: ['--no-sandbox'] });
const p = await b.newPage();
await p.setViewport({ width: 1024, height: 1024, deviceScaleFactor: 1 });
async function shot(file, mode) {
  const html = `<html><body style="margin:0;background:transparent">${svg}</body></html>`;
  await p.setContent(html);
  await p.evaluate((mode) => {
    const s = document.querySelector('svg');
    if (mode === 'bg') s.querySelector('#pieces').remove();
    if (mode === 'fg') {
      s.querySelector('#background').remove();
      // Zona segura do adaptativo: encolhe as peças para 72% em torno do centro.
      s.querySelector('#pieces').setAttribute('transform', 'translate(512,512) scale(0.72) translate(-512,-512)');
    }
  }, mode);
  await p.screenshot({ path: path.join(root, file), omitBackground: mode === 'fg', clip: { x: 0, y: 0, width: 1024, height: 1024 } });
}
await shot('assets/icon/app_icon.png', 'full');
await shot('assets/icon/icon_bg.png', 'bg');
await shot('assets/icon/icon_fg.png', 'fg');
await b.close();
console.log('ok');
