const path = require('path');
const { chromium } = require('playwright');

const root = __dirname;
const htmlPath = path.join(root, 'store_screenshots.html');
const outputRoot = path.join(root, 'output');

const targets = [
  { name: 'play_store', width: 1080, height: 1920 },
  { name: 'app_store', width: 1242, height: 2688 },
];

async function renderTarget(browser, target) {
  const page = await browser.newPage({
    viewport: { width: target.width, height: target.height },
    deviceScaleFactor: 1,
  });

  const htmlUrl = `file:///${htmlPath.replace(/\\/g, '/')}`;
  await page.goto(htmlUrl, { waitUntil: 'load' });

  await page.addStyleTag({
    content: `:root{--canvas-w:${target.width}px;--canvas-h:${target.height}px;}`,
  });

  const outDir = path.join(outputRoot, target.name);
  const fs = require('fs');
  fs.mkdirSync(outDir, { recursive: true });

  for (let i = 1; i <= 6; i += 1) {
    await page.evaluate((index) => {
      document.querySelectorAll('.shot').forEach((el) => {
        el.classList.toggle('active', el.dataset.index === String(index));
      });
    }, i);

    await page.locator(`.shot[data-index="${i}"]`).screenshot({
      path: path.join(outDir, `${String(i).padStart(2, '0')}-${target.name}.png`),
      animations: 'disabled',
    });
  }

  await page.close();
}

(async () => {
  const browser = await chromium.launch();
  try {
    for (const target of targets) {
      await renderTarget(browser, target);
    }
  } finally {
    await browser.close();
  }
})();
