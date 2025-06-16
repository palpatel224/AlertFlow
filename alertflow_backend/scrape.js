const puppeteer = require('puppeteer');
const { queryGemini } = require('./geminiResponse');

async function runScraping() {
  console.log('🔍 Starting earthquake data scraping...');
  const browser = await puppeteer.launch({ 
    headless: true, 
    defaultViewport: null,
    args: ['--no-sandbox']
  });
  const page = await browser.newPage();

  try {
    await page.goto('https://earthquake.usgs.gov/earthquakes/map', { waitUntil: 'networkidle2' });

    await page.waitForSelector('.mat-list-item.mat-focus-indicator.ng-star-inserted', { timeout: 20000 });

    const earthquakeHandles = await page.$$('.mat-list-item.mat-focus-indicator.ng-star-inserted');
    const earthquakes = [];

    for (let i = 0; i < Math.min(5, earthquakeHandles.length); i++) {
      const item = earthquakeHandles[i];

      await item.evaluate(el => el.scrollIntoView());

      const { magnitude, summaryLocation, datetime } = await page.evaluate(el => ({
        magnitude: el.querySelector('.callout > span.ng-star-inserted')?.textContent?.trim() || '',
        summaryLocation: el.querySelector('h6.header')?.textContent?.trim() || '',
        datetime: el.querySelector('.subheader .time')?.textContent?.trim() || ''
      }), item);

      await item.click();

      await page.waitForSelector('dl.properties', { timeout: 10000 });

      const latLon = await page.evaluate(() => {
        const dtNodes = Array.from(document.querySelectorAll('dl.properties dt'));
        for (let i = 0; i < dtNodes.length; i++) {
          if (dtNodes[i].textContent.trim().toLowerCase() === 'location') {
            const dd = dtNodes[i].nextElementSibling;
            if (dd) return dd.textContent.trim();
          }
        }
        return '';
      });

      earthquakes.push(`${magnitude},${summaryLocation},${datetime},${latLon}`);

      await page.evaluate(() => {
        const buttons = Array.from(document.querySelectorAll('button.mat-button, button.mat-focus-indicator'));
        const closeBtn = buttons.find(btn => btn.textContent.trim().toUpperCase() === 'CLOSE');
        if (closeBtn) closeBtn.click();
      });
      await new Promise(res => setTimeout(res, 500));
    }

    earthquakes.forEach((eq, i) => {
      console.log(`${i + 1}. ${eq}`);
    });
    console.log("📡 Sending to Gemini...");
    await queryGemini(earthquakes.join('\n'));
    console.log("✅ Scraping completed successfully!");

  } catch (err) {
    console.error('❌ Scraping error:', err);
    throw err;
  } finally {
    await browser.close();
  }
}

// Export the function for use in other modules
module.exports = { runScraping };

// If this file is run directly, execute the scraping
if (require.main === module) {
  runScraping().catch(console.error);
}
