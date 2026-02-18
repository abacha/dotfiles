# Spotify Control (minimal)

## 1) Create Spotify app
- Go to Spotify Developer Dashboard
- Create app
- Add Redirect URI: `http://127.0.0.1:8888/callback`

## 2) Setup
```bash
cd ~/dotfiles/ai/tooling/spotify-control
cp .env.example .env
npm install
```

Fill `.env` with:
- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`
- `SPOTIFY_REDIRECT_URI` (default already set)

## 3) Get refresh token (auto-saved)
```bash
npm run auth
```
- On WSL, it auto-opens the auth URL in Windows Chrome.
- Authorize.
- The script captures the callback token and updates `.env` automatically.
- No manual token copy/paste needed.
- Fallback: you can still manually update token with `./save-token.sh "<refresh_token>"`.
- Auth session timeout is 5 minutes by default (`SPOTIFY_AUTH_TIMEOUT_MS` to customize).
- If callback port is busy, it tries nearby ports (register those redirect URIs in Spotify app settings if needed).

## 4) Control playback
```bash
npm run control -- devices
npm run control -- status
npm run control -- current-volume
npm run control -- play
npm run control -- pause
npm run control -- next
npm run control -- prev
npm run control -- volume 40
npm run control -- transfer <device_id>
```

## Notes
- Requires Spotify Premium for playback control.
- You need an active Spotify Connect device.
- If you want commands that use Liked Songs, auth must include `user-library-read` (already configured in `auth.js`; re-run `npm run auth` after scope changes).
