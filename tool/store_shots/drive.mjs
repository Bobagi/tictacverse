// Dirige a build web do Tic Tac Verse (Flutter) com toques reais e salva
// screenshots 2x e, opcionalmente, todos os quadros via CDP screencast.
// Uso: node drive.mjs <cenario.json> <outDir>
// Cenario: { lang, progress:{...}, extra:{chave:valor}, viewport:"390x844",
//            record:false, steps:[ {tap:[x,y], wait:ms} | {wait:ms} | {shot:"nome"} |
//            {swipe:[x1,y1,x2,y2], wait:ms} | {mark:"texto"} ] }
// BASE (env) = URL da build servida (padrao http://127.0.0.1:8931/).
import { execSync, execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const skillDir = path.join(os.homedir(), '.claude/skills/frontend-review');
const m = await import(path.join(skillDir, 'node_modules/puppeteer-core/lib/puppeteer/puppeteer-core.js'));
const puppeteer = m.default || m;
const chrome = execSync(`ls -1 ${os.homedir()}/.cache/puppeteer/chrome/*/chrome-linux*/chrome | head -1`, { encoding: 'utf8' }).trim();
const [,, scenFile, outDir] = process.argv;
const sc = JSON.parse(readFileSync(scenFile, 'utf8'));
mkdirSync(outDir, { recursive: true });
const base = process.env.BASE || 'http://127.0.0.1:8931/';
const SLOW = Number(process.env.SLOW || 1); // multiplica as esperas em maquina carregada
const sleep = (ms) => new Promise(r => setTimeout(r, ms * SLOW));
const [w, h] = (sc.viewport || '390x844').split('x').map(Number);

const b = await puppeteer.launch({ executablePath: chrome, headless: true,
  args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-gl=angle', '--use-angle=swiftshader'] });
const p = await b.newPage();
const errs = []; p.on('pageerror', e => errs.push(String(e).slice(0, 200)));
await p.setViewport({ width: w, height: h, deviceScaleFactor: 2, hasTouch: true, isMobile: true });
await p.goto(base, { waitUntil: 'domcontentloaded' });
await p.evaluate((sc) => {
  localStorage.clear();
  localStorage.setItem('flutter.settings.locale', JSON.stringify(sc.lang));
  localStorage.setItem('flutter.settings.langSuggested', 'true');
  localStorage.setItem('flutter.progress.v1', JSON.stringify(JSON.stringify(sc.progress)));
  for (const [k, v] of Object.entries(sc.extra || {})) localStorage.setItem(k, v);
}, sc);
await p.reload({ waitUntil: 'domcontentloaded' });
await sleep(sc.boot || 8000);

let cdp = null; let n = 0; const t0 = Date.now(); const index = []; const marks = [];
if (sc.record) {
  const fdir = path.join(outDir, 'frames'); mkdirSync(fdir, { recursive: true });
  cdp = await p.createCDPSession();
  cdp.on('Page.screencastFrame', async (ev) => {
    const file = path.join(fdir, `f${String(n).padStart(5, '0')}.jpg`);
    writeFileSync(file, Buffer.from(ev.data, 'base64'));
    index.push(`${n}\t${Date.now() - t0}`); n++;
    try { await cdp.send('Page.screencastFrameAck', { sessionId: ev.sessionId }); } catch {}
  });
  await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 92, maxWidth: w * 2, maxHeight: h * 2, everyNthFrame: 1 });
}
let k = 0;
for (const s of sc.steps || []) {
  if (s.tap) { marks.push(`${Date.now() - t0}\ttap ${s.tap}`); await p.touchscreen.tap(s.tap[0], s.tap[1]); await sleep(s.wait ?? 1500); }
  else if (s.swipe) {
    const [x1, y1, x2, y2] = s.swipe;
    await p.touchscreen.touchStart(x1, y1);
    const steps = 12;
    for (let i = 1; i <= steps; i++) { await p.touchscreen.touchMove(x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps); await sleep(16); }
    await p.touchscreen.touchEnd();
    await sleep(s.wait ?? 1200);
  }
  else if (s.auto === 'ult') {
    // Partida contra a CPU: le a tela e toca uma celula livre do tabuleiro aceso.
    for (let i = 0; i < s.n; i++) {
      const tmp = path.join(outDir, '_auto.png');
      await p.screenshot({ path: tmp });
      const out = execFileSync('python3', [path.join(here, 'ult_pick.py'), tmp, String(s.top)], { encoding: 'utf8' });
      const pick = JSON.parse(out).tap;
      if (!pick) break;
      marks.push(`${Date.now() - t0}\tauto ${pick}`);
      await p.touchscreen.tap(pick[0], pick[1]);
      await sleep(s.wait ?? 2500);
    }
  }
  else if (s.wait) await sleep(s.wait);
  else if (s.mark) marks.push(`${Date.now() - t0}\t${s.mark}`);
  else if (s.shot) { await p.screenshot({ path: path.join(outDir, `${s.shot}.png`) }); }
  if (sc.shotEach) await p.screenshot({ path: path.join(outDir, `step-${String(k).padStart(2, '0')}.png`) });
  k++;
}
if (cdp) {
  await sleep(300);
  await cdp.send('Page.stopScreencast');
  writeFileSync(path.join(outDir, 'index.tsv'), index.join('\n') + '\n');
  writeFileSync(path.join(outDir, 'marks.tsv'), marks.join('\n') + '\n');
}
if (errs.length) console.log('ERR', errs.join(' | '));
console.log(`ok ${sc.lang} ${outDir} frames=${n}`);
await b.close();
