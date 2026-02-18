import dotenv from 'dotenv';

dotenv.config();

const clientId = process.env.SPOTIFY_CLIENT_ID;
const clientSecret = process.env.SPOTIFY_CLIENT_SECRET;
const refreshToken = process.env.SPOTIFY_REFRESH_TOKEN;

if (!clientId || !clientSecret || !refreshToken) {
  console.error('Missing SPOTIFY_CLIENT_ID / SPOTIFY_CLIENT_SECRET / SPOTIFY_REFRESH_TOKEN in .env');
  process.exit(1);
}

async function getAccessToken() {
  const res = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: 'Basic ' + Buffer.from(`${clientId}:${clientSecret}`).toString('base64')
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken
    })
  });

  const json = await res.json();
  if (!res.ok) throw new Error(`Token refresh failed: ${JSON.stringify(json)}`);
  return json.access_token;
}

async function api(accessToken, method, path, body) {
  const res = await fetch(`https://api.spotify.com/v1${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    },
    body: body ? JSON.stringify(body) : undefined
  });

  if (res.status === 204) return null;
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text}`);
  return text ? JSON.parse(text) : null;
}

async function main() {
  const [cmd, arg] = process.argv.slice(2);
  const token = await getAccessToken();

  switch (cmd) {
    case 'devices': {
      const data = await api(token, 'GET', '/me/player/devices');
      console.log(JSON.stringify(data, null, 2));
      break;
    }
    case 'play':
      await api(token, 'PUT', '/me/player/play');
      console.log('OK: play');
      break;
    case 'pause':
      await api(token, 'PUT', '/me/player/pause');
      console.log('OK: pause');
      break;
    case 'next':
      await api(token, 'POST', '/me/player/next');
      console.log('OK: next');
      break;
    case 'prev':
      await api(token, 'POST', '/me/player/previous');
      console.log('OK: prev');
      break;
    case 'volume': {
      const v = Number(arg);
      if (Number.isNaN(v) || v < 0 || v > 100) throw new Error('volume must be 0-100');
      await api(token, 'PUT', `/me/player/volume?volume_percent=${v}`);
      console.log(`OK: volume ${v}`);
      break;
    }
    case 'transfer': {
      if (!arg) throw new Error('transfer requires device id');
      await api(token, 'PUT', '/me/player', { device_ids: [arg], play: false });
      console.log(`OK: transfer -> ${arg}`);
      break;
    }
    default:
      console.log('Usage:');
      console.log('  node control.js devices');
      console.log('  node control.js play|pause|next|prev');
      console.log('  node control.js volume <0-100>');
      console.log('  node control.js transfer <device_id>');
  }
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
