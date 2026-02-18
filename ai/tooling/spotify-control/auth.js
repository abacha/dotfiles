import http from 'node:http';
import crypto from 'node:crypto';
import { URL, fileURLToPath } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import dotenv from 'dotenv';

dotenv.config();

const clientId = process.env.SPOTIFY_CLIENT_ID;
const clientSecret = process.env.SPOTIFY_CLIENT_SECRET;
const defaultRedirectUri = process.env.SPOTIFY_REDIRECT_URI || 'http://127.0.0.1:8888/callback';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const envPath = path.join(scriptDir, '.env');

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

function buildAuthUrl(redirectUri) {
  const authUrl = new URL('https://accounts.spotify.com/authorize');
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('client_id', clientId);
  authUrl.searchParams.set('scope', scope);
  authUrl.searchParams.set('redirect_uri', redirectUri);
  authUrl.searchParams.set('state', state);
  return authUrl;
}

function saveRefreshToken(token, redirectUri) {
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
  } else {
    if (/^SPOTIFY_REFRESH_TOKEN=/m.test(content)) {
      content = content.replace(/^SPOTIFY_REFRESH_TOKEN=.*$/m, `SPOTIFY_REFRESH_TOKEN=${token}`);
    } else {
      content = content.trimEnd() + `\nSPOTIFY_REFRESH_TOKEN=${token}\n`;
    }

    if (/^SPOTIFY_REDIRECT_URI=/m.test(content)) {
      content = content.replace(/^SPOTIFY_REDIRECT_URI=.*$/m, `SPOTIFY_REDIRECT_URI=${redirectUri}`);
    }
  }

  fs.writeFileSync(envPath, content, 'utf8');
}

function openBrowser(url) {
  const urlStr = url.toString();

  const isWsl = Boolean(process.env.WSL_DISTRO_NAME) ||
    (fs.existsSync('/proc/version') && /microsoft/i.test(fs.readFileSync('/proc/version', 'utf8')));

  if (isWsl) {
    const winChrome = '/mnt/c/Program Files/Google/Chrome/Application/chrome.exe';
    if (fs.existsSync(winChrome)) {
      try {
        spawn(winChrome, [urlStr], { detached: true, stdio: 'ignore' }).unref();
        return 'windows-chrome';
      } catch (err) {
        console.warn(`Failed to open Windows Chrome: ${err.message}`);
      }
    }
  }

  try {
    if (process.platform === 'win32') {
      spawn('cmd', ['/c', 'start', '', urlStr], { detached: true, stdio: 'ignore' }).unref();
      return 'cmd-start';
    }

    const opener = process.platform === 'darwin' ? 'open' : 'xdg-open';
    spawn(opener, [urlStr], { detached: true, stdio: 'ignore' }).unref();
    return opener;
  } catch (err) {
    console.warn(`Failed to auto-open browser: ${err.message}`);
    return 'manual';
  }
}

function createServerWithFallback(parsedUri, maxTries = 5) {
  return new Promise((resolve, reject) => {
    let attempt = 0;

    const tryListen = (port) => {
      const redirectUri = `${parsedUri.protocol}//${parsedUri.hostname}:${port}${parsedUri.pathname}`;
      const authUrl = buildAuthUrl(redirectUri);

      const server = http.createServer(async (req, res) => {
        const reqUrl = new URL(req.url, `${parsedUri.protocol}//${parsedUri.hostname}:${port}`);
        if (reqUrl.pathname !== parsedUri.pathname) {
          res.writeHead(404);
          res.end('Not found');
          return;
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
          saveRefreshToken(refreshToken, redirectUri);
        }

        res.end('Spotify auth done. Token captured and .env updated.');
        console.log('\nRefresh token captured and saved to .env as SPOTIFY_REFRESH_TOKEN.\n');
        console.log('\nAccess token (short-lived):\n');
        console.log(json.access_token);
        server.close();
      });

      server.once('error', (err) => {
        if (err.code === 'EADDRINUSE' && attempt < maxTries) {
          attempt += 1;
          tryListen(port + 1);
        } else {
          reject(err);
        }
      });

      server.listen(port, parsedUri.hostname, () => {
        resolve({ server, redirectUri, authUrl });
      });
    };

    tryListen(Number(parsedUri.port || 8888));
  });
}

async function main() {
  const parsedUri = new URL(defaultRedirectUri);
  const timeoutMs = Number(process.env.SPOTIFY_AUTH_TIMEOUT_MS || 300000);

  let session;
  try {
    session = await createServerWithFallback(parsedUri, 5);
  } catch (err) {
    console.error(`Failed to start callback server: ${err.message}`);
    process.exit(1);
  }

  const { server, redirectUri, authUrl } = session;

  if (redirectUri !== defaultRedirectUri) {
    console.log(`\nCallback port busy. Switched redirect URI to: ${redirectUri}`);
    console.log('Ensure this redirect URI is also allowed in your Spotify app settings.\n');
  }

  console.log('\nAuth URL:\n');
  console.log(authUrl.toString());
  const openedBy = openBrowser(authUrl);
  console.log(`\nOpened automatically via: ${openedBy}`);
  if (openedBy === 'manual') {
    console.log('Please open the Auth URL manually in your browser.');
  }
  console.log('\nWaiting for callback...\n');

  const timer = setTimeout(() => {
    console.error(`Auth timed out after ${Math.round(timeoutMs / 1000)}s.`);
    console.error('Run npm run auth again when ready.');
    server.close(() => process.exit(1));
  }, timeoutMs);

  server.on('close', () => clearTimeout(timer));
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
