# Home Assistant Context

This file summarizes the Home Assistant setup and configuration from our session.

## Connection Details
- **URL:** `http://localhost:8124` (Port 8123 was initially used but conflicted with ClickHouse, so it was changed to 8124).
- **Token:** Stored in `~/.openclaw/workspace/.hass_token`. This is a Long-Lived Access Token.
- **Internal IP:** Your machine's local IP (Docker maps to `localhost`).

## Docker Container Details
- **Image:** `ghcr.io/home-assistant/home-assistant:stable`
- **Container Name:** `homeassistant`
- **Volume Mapping:** `/home/abacha/homeassistant:/config` (for persistent configuration)
- **Timezone:** `America/Sao_Paulo`
- **Restart Policy:** `--restart=unless-stopped`
- **Docker Run Command:**
  ```bash
  docker rm homeassistant || true && docker run -d \
    --name homeassistant \
    --privileged \
    --restart=unless-stopped \
    -e TZ=America/Sao_Paulo \
    -v /home/abacha/homeassistant:/config \
    -p 8124:8123 \
    ghcr.io/home-assistant/home-assistant:stable
  ```

## Discovered Entities (after Tuya integration)

### Cameras
- **`camera.camera_sala`** (Intelbras iM3-C-3381, IP 192.168.15.42)
  - **Status:** ✅ Working perfectly via FFmpeg platform
  - **Resolution:** 1920x1080
  - **Configuration:** Added to `configuration.yaml` (see Camera Setup below)
  - **Access:** Snapshot available via `http://localhost:8124/api/camera_proxy/camera.camera_sala`

#### Camera Setup (2026-02-28)
The camera was successfully configured after these steps:
1. **Added `stream:` to configuration.yaml** - Required for camera streaming support
2. **Removed ONVIF integration** - Was generating incorrect RTSP URLs with `&unicast=true&proto=Onvif` that caused timeouts
3. **Added camera via FFmpeg platform** with correct RTSP URL:
   ```yaml
   camera:
     - platform: ffmpeg
       name: Camera Sala
       input: -rtsp_transport tcp -i rtsp://admin:a1a2a3a4a5@192.168.15.42:554/cam/realmonitor?channel=1&subtype=0
   ```
4. **Key points:**
   - Use TCP transport (not UDP) for reliability
   - Correct Intelbras RTSP path: `/cam/realmonitor?channel=1&subtype=0`
   - No need for `&unicast=true&proto=Onvif` parameters
   - Camera supports H.264 main stream (1920x1080 @ 20fps)

### Lights (Tuya Integration)
- `light.led_sala_rack` (Status: `off`, available)
- `light.led_sala_tv` (Status: `unavailable`)
- `light.led_esc_prateleira_1` (Status: `unavailable`, located inside cabinet, prone to Wi-Fi/heat issues)
- `light.led_esc_prateleira_2` (Status: `unavailable`, located inside cabinet, prone to Wi-Fi/heat issues)
- `light.fita_pia` (Status: `unavailable`)

### Switches/Outlets (Tuya Integration)
- `switch.luz_sala_socket_1` to `switch.luz_sala_socket_6` (Status: `off`, available)
- `switch.luz_lavanderia_switch_1` (Status: `unavailable`)
- `switch.luz_quarto_switch_1` to `switch.luz_quarto_switch_3` (Status: `off`, available)
- `switch.luz_banheiro_bichos_switch_1` (Status: `unavailable`)
- `switch.cafeteira_switch_1` (Status: `unavailable`)
- `switch.luz_varanda_switch_1` (Status: `off`, available)
- `switch.cafeteira_switch_1_2` (Status: `on`, available - *caution advised*)
- `switch.chaleira_switch_1` (Status: `on`, available - *caution advised*)
- `switch.led_pia_cozinha_switch_1` (Status: `unavailable`)

### Select Entities (Tuya Integration)
- `select.luz_sala_ligar_os_modos` (State: `last`)
- `select.luz_sala_modo_de_luz_indicadora` (State: `relay`)
- `select.luz_lavanderia_ligar_os_modos` (State: `unavailable`)
- `select.luz_lavanderia_modo_de_luz_indicadora` (State: `unavailable`)
- `select.luz_quarto_ligar_os_modos` (State: `power_off`)
- `select.luz_quarto_modo_de_luz_indicadora` (State: `relay`)
- `select.luz_banheiro_bichos_ligar_os_modos` (State: `unavailable`)
- `select.luz_banheiro_bichos_modo_de_luz_indicadora` (State: `unavailable`)
- `select.cafeteira_ligar_os_modos` (State: `unavailable`)
- `select.luz_varanda_ligar_os_modos` (State: `power_off`)
- `select.luz_varanda_modo_de_luz_indicadora` (State: `relay`)
- `select.cafeteira_ligar_os_modos_2` (State: `2`)
- `select.chaleira_ligar_os_modos` (State: `2`)
- `select.led_pia_cozinha_ligar_os_modos` (State: `unavailable`, historical states show `unavailable` and `2`, indicating connection issues due to location in cabinet).

### Other Entities (Home Assistant defaults)
- `conversation.home_assistant`
- `zone.home`
- `sun.sun`
- `sensor.sun_next_dawn`, `sensor.sun_next_dusk`, `sensor.sun_next_midnight`, `sensor.sun_next_noon`, `sensor.sun_next_rising`, `sensor.sun_next_setting`
- `event.backup_automatic_backup`
- `sensor.backup_backup_manager_state`, `sensor.backup_next_scheduled_automatic_backup`, `sensor.backup_last_successful_automatic_backup`, `sensor.backup_last_attempted_automatic_backup`
- `person.adriano_bacha`
- `todo.lista_de_compras`
- `tts.google_translate_en_com`
- `weather.forecast_casa`
- `binary_sensor.multi_mode_gateway_problema` (Status: `unavailable`)

## Integration Notes
- **Tuya:** Successfully integrated. Many devices discovered.
- **Camera (FFmpeg):** ✅ Working perfectly via FFmpeg platform with TCP RTSP transport.
- **HACS:** Successfully installed and Home Assistant restarted. Requires activation in HA UI -> Integrations.
- **Dreame Vacuum:** Requires HACS, then install "Dreame Vacuum" integration via HACS. Login issues persist with `KB373026` as username. Recommendation is to use `abacha@gmail.com` as username and ensure "Account Type" is set to "Dreamehome" (or try `cn` as country). If still issues, consider re-pairing the robot with Xiaomi Mi Home app for better HA compatibility.

## Troubleshooting
- **LED Pia Cozinha:** Frequently `unavailable` due to placement inside a cabinet (Wi-Fi signal degradation, potential overheating). Recommendation: reposition outside cabinet or near an opening.
- **Dreame Vacuum Login:** `login_error` persists. Tried `KB373026` (Dreame Account ID) with various regions (`us`, `de`, `sg`, `cn`) without immediate API error, but UI shows `login_error`. Recommended to use email `abacha@gmail.com` or re-pair robot with Mi Home app.
- **Camera ONVIF Issues:** ONVIF integration generated incorrect RTSP URLs. Solution: Use FFmpeg platform directly with proper Intelbras RTSP path.

## New Devices (EBO Air & ROLA Fountain)
- **EBO Air (Y012YUMM):** Pet robot, uses proprietary app (not Tuya/Smart Life)
- **ROLA Fountain-01 (100AAJD24CK0561):** Pet water fountain, uses proprietary app
- **Status:** LocalTuya installed (2026-02-26), but devices not discovered via network scan
- **Next Steps (requires PC access):**
  1. Open `http://localhost:8124` in browser
  2. Go to Configuration → Devices & Services → Add Integration → "LocalTuya"
  3. Try automatic discovery or manual configuration
  4. If LocalTuya fails, check if devices have API documentation or MQTT support
  5. Alternative: Check if apps support Alexa/Google Home → integrate via HA cloud integration
