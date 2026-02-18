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

function explainApiError(method, path, status, text) {
  if (status === 401) {
    return `${method} ${path} -> 401 Unauthorized. Refresh token may be invalid/expired. Run: npm run auth`;
  }
  if (status === 403) {
    return `${method} ${path} -> 403 Forbidden. Missing Spotify scope for this action. Re-auth with required scopes via: npm run auth`;
  }
  if (status === 404 && path.startsWith('/me/player')) {
    return `${method} ${path} -> 404 No active Spotify device/session. Open Spotify on a device and play once.`;
  }
  return `${method} ${path} -> ${status} ${text}`;
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
  if (!res.ok) throw new Error(explainApiError(method, path, res.status, text));
  return text ? JSON.parse(text) : null;
}

async function getActiveDevice(token) {
  const data = await api(token, 'GET', '/me/player/devices');
  const devices = data?.devices || [];
  return devices.find((d) => d.is_active) || null;
}

async function status(token) {
  const [playback, devicesData] = await Promise.all([
    api(token, 'GET', '/me/player').catch(() => null),
    api(token, 'GET', '/me/player/devices').catch(() => ({ devices: [] }))
  ]);

  const activeDevice = (devicesData.devices || []).find((d) => d.is_active) || null;
  const track = playback?.item;

  console.log(JSON.stringify({
    isPlaying: playback?.is_playing ?? false,
    activeDevice: activeDevice
      ? {
          id: activeDevice.id,
          name: activeDevice.name,
          type: activeDevice.type,
          volume: activeDevice.volume_percent
        }
      : null,
    track: track
      ? {
          name: track.name,
          artists: (track.artists || []).map((a) => a.name),
          album: track.album?.name
        }
      : null
  }, null, 2));
}

async function currentVolume(token) {
  const active = await getActiveDevice(token);
  if (!active) throw new Error('No active device. Open Spotify and play on a device first.');
  console.log(active.volume_percent);
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
    case 'status':
      await status(token);
      break;
    case 'current-volume':
      await currentVolume(token);
      break;
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
      console.log('  node control.js status');
      console.log('  node control.js current-volume');
      console.log('  node control.js play|pause|next|prev');
      console.log('  node control.js volume <0-100>');
      console.log('  node control.js transfer <device_id>');
  }
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
