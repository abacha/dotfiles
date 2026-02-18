import http from 'node:http';
import crypto from 'node:crypto';
import { URL } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import dotenv from 'dotenv';

dotenv.config();

const clientId = process.env.SPOTIFY_CLIENT_ID;
const clientSecret = process.env.SPOTIFY_CLIENT_SECRET;
const redirectUri = process.env.SPOTIFY_REDIRECT_URI || 'http://127.0.0.1:8888/callback';
const envPath = path.resolve('.env');

if (!clientId || !clientSecret) {
  console.error('Missing SPOTIFY_CLIENT_ID or SPOTIFY_CLIENT_SECRET in .env');
  process.exit(1);
}

const state = crypto.randomBytes(12).toString('hex');
const scope = [
  'user-modify-playback-state',
  'user-read-playback-state',
  'user-library-read'
].join(' ');

const authUrl = new URL('https://accounts.spotify.com/authorize');
authUrl.searchParams.set('response_type', 'code');
authUrl.searchParams.set('client_id', clientId);
authUrl.searchParams.set('scope', scope);
authUrl.searchParams.set('redirect_uri', redirectUri);
authUrl.searchParams.set('state', state);

function saveRefreshToken(token) {
  if (!token) return;

  let content = '';
  if (fs.existsSync(envPath)) {
    content = fs.readFileSync(envPath, 'utf8');
  }

  if (!content) {
    content = [
      `SPOTIFY_CLIENT_ID=${clientId || ''}`,
      `SPOTIFY_CLIENT_SECRET=${clientSecret || ''}`,
      `SPOTIFY_REDIRECT_URI=${redirectUri}`,
      `SPOTIFY_REFRESH_TOKEN=${token}`,
      ''
    ].join('\n');
  } else if (/^SPOTIFY_REFRESH_TOKEN=/m.test(content)) {
    content = content.replace(/^SPOTIFY_REFRESH_TOKEN=.*$/m, `SPOTIFY_REFRESH_TOKEN=${token}`);
  } else {
    content = content.trimEnd() + `\nSPOTIFY_REFRESH_TOKEN=${token}\n`;
  }

  fs.writeFileSync(envPath, content, 'utf8');
}

function openBrowser(url) {
  const urlStr = url.toString();

  // WSL: prefer Windows Chrome to avoid Google secure-browser blocks
  const isWsl = Boolean(process.env.WSL_DISTRO_NAME) ||
    (fs.existsSync('/proc/version') && /microsoft/i.test(fs.readFileSync('/proc/version', 'utf8')));

  if (isWsl) {
    const winChrome = '/mnt/c/Program Files/Google/Chrome/Application/chrome.exe';
    if (fs.existsSync(winChrome)) {
      spawn(winChrome, [urlStr], { detached: true, stdio: 'ignore' }).unref();
      return 'windows-chrome';
    }
  }

  // Fallback: xdg-open/open/start via shell
  const opener = process.platform === 'darwin' ? 'open' : (process.platform === 'win32' ? 'start' : 'xdg-open');
  spawn(opener, [urlStr], { detached: true, stdio: 'ignore', shell: true }).unref();
  return opener;
}

console.log('\nAuth URL:\n');
console.log(authUrl.toString());
const openedBy = openBrowser(authUrl);
console.log(`\nOpened automatically via: ${openedBy}`);
console.log('\nWaiting for callback...\n');

const server = http.createServer(async (req, res) => {
  const reqUrl = new URL(req.url, 'http://127.0.0.1:8888');
  if (reqUrl.pathname !== '/callback') {
    res.writeHead(404); res.end('Not found'); return;
  }

  const code = reqUrl.searchParams.get('code');
  const returnedState = reqUrl.searchParams.get('state');
  const err = reqUrl.searchParams.get('error');

  if (err) {
    res.end(`Auth error: ${err}`);
    server.close();
    process.exit(1);
  }

  if (!code || returnedState !== state) {
    res.end('Invalid callback state/code.');
    server.close();
    process.exit(1);
  }

  const tokenRes = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: 'Basic ' + Buffer.from(`${clientId}:${clientSecret}`).toString('base64')
    },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri
    })
  });

  const json = await tokenRes.json();
  if (!tokenRes.ok) {
    res.end('Failed to get token. Check terminal.');
    console.error(json);
    server.close();
    process.exit(1);
  }

  const refreshToken = json.refresh_token || '';
  if (refreshToken) {
    saveRefreshToken(refreshToken);
  }

  res.end('Spotify auth done. Token captured and .env updated.');
  console.log('\nRefresh token captured and saved to .env as SPOTIFY_REFRESH_TOKEN.\n');
  console.log('\nAccess token (short-lived):\n');
  console.log(json.access_token);
  server.close();
});

server.listen(8888, '127.0.0.1');
