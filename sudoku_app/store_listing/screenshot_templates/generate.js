const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const LANGUAGES = [
  'en-US', 'tr-TR', 'zh-CN', 'hi-IN', 'es-ES',
  'fr-FR', 'ar', 'bn-BD', 'pt-BR', 'ru-RU', 'ja-JP'
];

const SCREENSHOT_IDS = [1, 2, 3, 4, 5, 6];

const WIDTH = 1440;
const HEIGHT = 2560;

async function generateScreenshots(targetLangs) {
  const htmlPath = path.resolve(__dirname, 'index.html');
  const outputBase = path.resolve(__dirname, '..', 'screenshots');

  const browser = await puppeteer.launch({
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-web-security',
      '--allow-file-access-from-files',
    ],
  });

  let totalGenerated = 0;
  const totalExpected = targetLangs.length * SCREENSHOT_IDS.length;

  for (const lang of targetLangs) {
    const langDir = path.join(outputBase, lang);
    if (!fs.existsSync(langDir)) {
      fs.mkdirSync(langDir, { recursive: true });
    }

    const page = await browser.newPage();
    await page.setViewport({ width: WIDTH, height: HEIGHT, deviceScaleFactor: 1 });

    const fileUrl = `file:///${htmlPath.replace(/\\/g, '/')}?lang=${lang}`;
    await page.goto(fileUrl, { waitUntil: 'networkidle0', timeout: 30000 });

    await page.waitForFunction(() => {
      const imgs = document.querySelectorAll('.phone-screen img');
      return Array.from(imgs).every(img => img.complete && img.naturalHeight > 0);
    }, { timeout: 15000 }).catch(() => {
      console.warn(`  [warn] Some images may not have loaded for ${lang}`);
    });

    for (const id of SCREENSHOT_IDS) {
      const selector = `#screenshot-${id}`;
      const element = await page.$(selector);

      if (!element) {
        console.error(`  [error] Element ${selector} not found`);
        continue;
      }

      const box = await element.boundingBox();
      if (!box) {
        console.error(`  [error] No bounding box for ${selector}`);
        continue;
      }

      const outputPath = path.join(langDir, `screenshot_${String(id).padStart(2, '0')}.png`);

      await page.screenshot({
        path: outputPath,
        type: 'png',
        clip: {
          x: box.x,
          y: box.y,
          width: WIDTH,
          height: HEIGHT,
        },
      });

      totalGenerated++;
      const pct = Math.round((totalGenerated / totalExpected) * 100);
      console.log(`  [${pct}%] ${lang}/screenshot_${String(id).padStart(2, '0')}.png`);
    }

    await page.close();
  }

  await browser.close();
  console.log(`\nDone! Generated ${totalGenerated} screenshots.`);
}

async function main() {
  const args = process.argv.slice(2);
  let targetLangs;

  if (args.length > 0) {
    targetLangs = args.filter(lang => LANGUAGES.includes(lang));
    if (targetLangs.length === 0) {
      console.error(`Invalid language(s). Available: ${LANGUAGES.join(', ')}`);
      process.exit(1);
    }
  } else {
    targetLangs = LANGUAGES;
  }

  console.log(`Generating screenshots for: ${targetLangs.join(', ')}`);
  console.log(`Output: 1440x2560px PNG (9:16 ratio)`);
  console.log(`Total: ${targetLangs.length * SCREENSHOT_IDS.length} files\n`);

  await generateScreenshots(targetLangs);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
