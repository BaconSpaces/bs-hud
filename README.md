

A lightweight, futuristic HUD suite for FiveM — speedometer, indicators/engine control, and a street/zone location display. Built as standalone resources so you can run all three together or pick just the ones you need.

## Modules

### `speedometer`
A circular MPH speedometer with an RPM arc, current gear, and turn-signal/hazard indicators built in.
- Shows/hides automatically based on whether you're in a vehicle
- Displays speed (MPH), gear (`P` / `R` / `N` / `1-N`), and a color-gradient RPM ring
- Reflects indicator/hazard state from the `indicators` resource
- **Depends on:** `indicators`

### `indicators`
Handles turn signals, hazards, and manual engine toggling. Runs standalone (no UI) and exposes state for other resources to consume.
- **Keybinds:**
  - `-` — left indicator
  - `=` — right indicator
  - `Backspace` — hazards
  - `G` — toggle engine on/off
- Instant toggles, no cooldown/debounce
- Broadcasts state via the `indicators:state` event and a `GetIndicatorState` export
- Syncs indicator state through a player state bag (`indicators`)

### `location`
An auto-starting street/zone HUD with a compass. No commands or ACE permissions needed — it just runs for every player.
- Shows the current street name and nearest cross street
- Live compass with cardinal direction and heading
- Hides the default GTA area/street name HUD components while active

## Installation

1. Copy the `speedometer`, `indicators`, and `location` folders into your server's `resources` directory.
2. Add the following to your `server.cfg` (order matters — `indicators` should start before `speedometer`):
   ```
   ensure indicators
   ensure speedometer
   ensure location
   ```
3. Restart your server, or run `refresh` followed by `ensure <resource>` for each in the console.

Each module can also be dropped in independently — `location` and `indicators` have no dependencies, while `speedometer` requires `indicators` to be running.

## Requirements

- FiveM server running the `cerulean` fx_version
- `gta5` game build

## Notes

- All HUD elements render with transparent backgrounds, styled for a dark/neon aesthetic.
- The `speedometer` and `location` UIs communicate via NUI messages (`SendNUIMessage`) and only push updates when the underlying data actually changes, to keep things efficient.


