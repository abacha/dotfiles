import path from 'node:path';
import dotenv from 'dotenv';
import { chromium } from 'playwright';

dotenv.config();

const args = process.argv.slice(2);
const command = args[0];

function getArg(flag, def = '') {
  const i = args.indexOf(flag);
  if (i === -1 || i + 1 >= args.length) return def;
  return args[i + 1];
}

function hasFlag(flag) {
  return args.includes(flag);
}

async function wait(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function findAndClickChat(page, title) {
  const escaped = title.replace(/"/g, '\\"').toLowerCase();
  const clicked = await page.evaluate((needle) => {
    const candidates = [...document.querySelectorAll('a,button,div')]
      .filter((el) => {
        const t = (el.textContent || '').trim().toLowerCase();
        if (!t) return false;
        if (t.length > 200) return false;
        return t.includes(needle);
      });
    const target = candidates.find((el) => {
      const r = el.getBoundingClientRect();
      return r.width > 0 && r.height > 0;
    });
    if (!target) return false;
    target.click();
    return true;
  }, escaped);
  return clicked;
}

async function typeAndSend(page, message) {
  const ta = page.locator('#prompt-textarea');
  await ta.waitFor({ timeout: 20000 });
  await ta.click();
  await ta.fill(message);
  await ta.press('Enter');
}

async function waitAssistantDone(page) {
  let lastText = '';
  let stableCount = 0;
  for (let i = 0; i < 240; i++) {
    const stopVisible = await page.locator('button:has-text("Stop")').isVisible().catch(() => false);
    const text = await page.evaluate(() => {
      const nodes = [...document.querySelectorAll('[data-message-author-role="assistant"]')];
      const last = nodes[nodes.length - 1];
      return (last?.innerText || '').trim();
    });

    if (text && text === lastText) stableCount += 1;
    else stableCount = 0;

    lastText = text || lastText;

    if (!stopVisible && stableCount >= 3 && lastText) return lastText;
    await wait(1500);
  }
  return lastText;
}

function streamline(text) {
  const cleaned = text.replace(/\n{3,}/g, '\n\n').trim();
  if (cleaned.length <= 1200) return cleaned;
  return cleaned.slice(0, 1200) + '\n\n...[truncated]';
}

async function sendFlow() {
  const chat = getArg('--chat');
  const message = getArg('--message');
  const raw = hasFlag('--raw');

  if (!chat || !message) {
    console.log('Usage: node bridge.mjs send --chat "<title>" --message "<text>" [--raw]');
    process.exit(1);
  }

  const baseUrl = process.env.CHATGPT_BRIDGE_BASE_URL || 'https://chatgpt.com';
  const profileDir = process.env.CHATGPT_BRIDGE_PROFILE_DIR || './.profile';
  const waitMs = Number(process.env.CHATGPT_BRIDGE_MODEL_WAIT_MS || '1500');

  const forceLocal = hasFlag('--local');
  const cdpUrl = forceLocal ? '' : (process.env.CHATGPT_BRIDGE_CDP_URL || '');
  const userDataDir = path.resolve(profileDir);

  let context;
  let browser;
  if (cdpUrl) {
    browser = await chromium.connectOverCDP(cdpUrl);
    context = browser.contexts()[0] || await browser.newContext();
  } else {
    context = await chromium.launchPersistentContext(userDataDir, {
      headless: false,
      channel: 'chrome',
      args: ['--start-minimized'],
      viewport: { width: 1280, height: 900 }
    });
  }

  const page = context.pages()[0] || await context.newPage();
  await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });
  await wait(waitMs);

  let hasPrompt = await page.locator('#prompt-textarea').isVisible().catch(() => false);
  if (!hasPrompt) {
    console.log('Login required. I will keep the browser open for up to 5 minutes.');
    console.log('After logging in, come back to terminal and press Enter to continue.');
    await new Promise((resolve) => {
      process.stdin.resume();
      process.stdin.once('data', () => resolve());
    });
    hasPrompt = await page.locator('#prompt-textarea').isVisible().catch(() => false);
    if (!hasPrompt) {
      console.log('Still not logged in. Leaving browser open; aborting command.');
      return;
    }
  }

  const found = await findAndClickChat(page, chat);
  if (!found) {
    const hints = await page.evaluate(() => {
      return [...document.querySelectorAll('a,button')]
        .map((el) => (el.textContent || '').trim())
        .filter((t) => t && t.length < 120)
        .slice(0, 25);
    });
    console.log(`Chat not found in sidebar: ${chat}`);
    console.log('Visible sidebar/button hints (sample):');
    hints.forEach((h) => console.log(`- ${h}`));
    // Fail instead of hanging
    throw new Error(`Chat "${chat}" not found. Please rename a chat or update the title.`);
  }

  await wait(1200);
  await typeAndSend(page, message);
  const answer = await waitAssistantDone(page);

  console.log('--- CHATGPT RESPONSE START ---');
  console.log(raw ? answer : streamline(answer));
  console.log('--- CHATGPT RESPONSE END ---');

  if (browser) {
    await browser.close();
  } else {
    await context.close();
  }
}

async function loginFlow() {
  const baseUrl = process.env.CHATGPT_BRIDGE_BASE_URL || 'https://chatgpt.com';
  const profileDir = process.env.CHATGPT_BRIDGE_PROFILE_DIR || './.profile';
  const forceLocal = hasFlag('--local');
  const cdpUrl = forceLocal ? '' : (process.env.CHATGPT_BRIDGE_CDP_URL || '');
  const userDataDir = path.resolve(profileDir);

  let context;
  let browser;
  if (cdpUrl) {
    browser = await chromium.connectOverCDP(cdpUrl);
    context = browser.contexts()[0] || await browser.newContext();
  } else {
    context = await chromium.launchPersistentContext(userDataDir, {
      headless: false,
      channel: 'chrome',
      args: ['--start-minimized'],
      viewport: { width: 1280, height: 900 }
    });
  }

  const page = context.pages()[0] || await context.newPage();
  await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });

  console.log('Chrome opened for login. Complete login in browser, then press Enter here.');
  await new Promise((resolve) => {
    process.stdin.resume();
    process.stdin.once('data', () => resolve());
  });

  const hasPrompt = await page.locator('#prompt-textarea').isVisible().catch(() => false);
  if (!hasPrompt) {
    console.log('Login not detected yet. You can run login again, then send.');
  } else {
    console.log('Login detected. You can now run send command.');
  }

  if (browser) await browser.close();
  else await context.close();
}

if (command === 'send') {
  sendFlow().catch((e) => {
    console.error(e?.message || e);
    process.exit(1);
  });
} else if (command === 'login') {
  loginFlow().catch((e) => {
    console.error(e?.message || e);
    process.exit(1);
  });
} else {
  console.log('Commands:');
  console.log('  node bridge.mjs login [--local]');
  console.log('  node bridge.mjs send --chat "<title>" --message "<text>" [--raw] [--local]');
}
