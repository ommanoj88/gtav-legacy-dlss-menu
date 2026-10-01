# GTA V Legacy — Clarity / "DLSS-style" Menu

A **Story Mode only** graphics menu for the **Legacy** (2015) PC build of GTA V, plus an
honest explanation of what's actually possible around "DLSS" on it.

## Before anything else

- **Story Mode / offline only.** Do not use this, ReShade, or any file/overlay injection
  while playing GTA Online. Rockstar's anti-cheat can't tell a cosmetic graphics mod
  apart from a cheat menu's injection technique, and permanent bans have been issued for
  exactly that. This repo has zero GTA Online features, on purpose.
- **"Legacy"** here means the original 2015 PC build (what you have unless you bought
  Rockstar's 2025 **Enhanced** upgrade). Enhanced is a different executable with official
  Rockstar + NVIDIA DLSS/FSR3/XeSS support built in — if that's what you own, just enable
  DLSS in its video settings; you don't need this repo at all.

## The DLSS 5 reality check (October 2026)

- NVIDIA **DLSS 5** ("3D-Guided Neural Rendering") shipped September 3, 2026. It's an AI
  lighting/materials pass, **not** a generic resolution upscaler — NVIDIA's own material
  says developers must tune it per game. It's officially RTX 50-series only, lives in
  exactly one launch title (NBA 2K27) plus GeForce NOW, costs roughly 50–60% performance,
  and has had a rough critical reception (IGN, The Verge and Engadget all panned it).
- GTA V Legacy's 2015 build has **no NVIDIA NGX / DLSS / FSR2 / XeSS hook of any kind**.
  Tools like OptiScaler or DLSS Swapper only *swap the version* of an upscaler a game
  **already** calls into — they can't invent that hook from nothing.
- Nobody in the modding community has published a working DLSS injector (any version) for
  GTA V Legacy. Since DLSS 5 is brand new and needs first-party tuning even in games built
  for it, treat anything online claiming to "activate DLSS 5 in GTA V Legacy" as fake or
  malware.

So this repo does **not** inject real DLSS — nothing can, today. It gives you the closest
legitimate, working alternative: a sharpening/clarity pass through the well-established
open-source **ReShade** framework, managed by a small menu, plus pointers to the two
things that get you genuinely closer to "DLSS-like" results than ReShade alone.

## What's in this repo

- [`menu/dlss-menu.ps1`](menu/dlss-menu.ps1) — interactive PowerShell menu: locate your
  game, back up original files, apply/adjust the sharpening preset, launch the game.
- This README, with full setup steps below.

## Requirements

- Windows 10/11
- GTA V Legacy installed (Steam / Epic / Rockstar Games Launcher)
- Any GPU for the sharpening pass itself; an NVIDIA RTX card only matters for Tier 1 below
- [ReShade](https://reshade.me) (free, open source) — you install this yourself, see steps
- PowerShell 5.1+ (already included in Windows)

## Setup steps

1. **Install ReShade**
   - Download the installer from the official site: <https://reshade.me>
   - Run it, click "Select a game", browse to your `GTA5.exe`:
     - Steam: `...\Steam\steamapps\common\Grand Theft Auto V\GTA5.exe`
     - Rockstar Games Launcher: `...\Rockstar Games\Grand Theft Auto V\GTA5.exe`
     - Epic Games: `...\Epic Games\GTAV\GTA5.exe`
   - Choose **Direct3D 10/11/12** as the rendering API (GTA V Legacy runs on DX11 on most
     systems).
   - When asked which shaders to install, tick **"Standard effects"** — this includes
     `CAS.fx` (AMD's Contrast Adaptive Sharpening), which is what gives the clarity boost.
2. **Clone this repo** onto the same PC (or just copy the `menu` folder).
3. **Run the menu**: double-click [`menu/Start-Menu.bat`](menu/Start-Menu.bat).
   - Don't use Explorer's "Run with PowerShell" on the `.ps1` directly — it launches
     non-interactively and the window closes the instant it hits a prompt (see
     Troubleshooting). The `.bat` forces a proper interactive window.
4. Choose **[1] Locate GTA V install** — it checks common install paths, or you can paste
   your own.
5. Choose **[2] Backup original files** before touching anything else.
6. Launch the game once (option **[5]**, or normally through Steam/Epic/Rockstar).
7. In-game, press **Home** to open the ReShade overlay → **Add-on/Effects** list → tick
   **CAS** → drag "Sharpness" to taste (0.4–0.7 is a good start) → close the overlay. This
   one-time step saves everything into `ReShadePreset.ini` next to `GTA5.exe`.
8. From then on, use **[3] Adjust sharpness** in the menu to tweak it without reopening
   the in-game overlay.
9. *(Optional)* Lower in-game **Resolution Scale** a notch (Settings → Graphics →
   Advanced), then raise CAS sharpness slightly to compensate. This is the non-AI
   analogue of DLSS's Quality/Performance trade-off: render fewer pixels, sharpen to
   recover perceived detail.

## Tier options (beyond this repo)

| Tier | What | Cost | Needs RTX | Notes |
|---|---|---|---|---|
| 1 | NVIDIA App → Filters → **Image Scaling (NIS)** + sharpening | Free | No (any NVIDIA GPU) | Driver-level, zero install, works on GTA V Legacy today, no AI involved |
| 2 | **This repo** — ReShade + CAS sharpening menu | Free | No | What's documented above |
| 3 | [Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/) (Steam) | ~$7 | No | Real frame generation + AI-ish scaling, vendor-agnostic, has its own menu/overlay |

Real DLSS (any version) **cannot** be added to GTA V Legacy by any of the above — only
Rockstar could do that, by shipping an NGX-integrated build the way they did for Enhanced.

## Troubleshooting

- **The window opens and closes in about a second** — this happens if you launched the
  `.ps1` via Explorer's "Run with PowerShell" instead of `menu/Start-Menu.bat`. That verb
  runs non-interactively and/or Windows blocked the script because it was downloaded from
  the internet, so it errors out on the first prompt and the window closes with it. Use
  `Start-Menu.bat` instead — it opens a normal window and stays open.
- **Overlay doesn't open (Home key does nothing)** — confirm you picked the right
  rendering API during ReShade install.
- **Game won't launch / black screen** — run menu option **[4] Restore original files**,
  then reinstall ReShade choosing the other DirectX option.
- **Rockstar Games Launcher / Social Club login loop** — unrelated to ReShade; verify game
  files through your store client.
- **Steam/Epic overlay conflicts** — disable one of the overlays (Steam/Epic/ReShade) if
  you see visual glitches.

## Safety notes

- Only ever use this in **Story Mode**.
- Everything here only touches files inside your own GTA V install folder, and the menu
  always backs them up first.
- This repo contains no network code and does not download or execute anything
  automatically — you install ReShade yourself from the official site.

## Credits / license

- Built on top of [ReShade](https://reshade.me) (separately licensed — install it from
  the official site yourself).
- This repo's own script is MIT licensed — see [LICENSE](LICENSE).
