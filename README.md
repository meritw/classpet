# Hamster Simulator: Class Pet

Solo MVP scaffold for the Roblox experience **Hamster Simulator: Class Pet** — day quizzes → night buffs, latch escape, dog chase, phone win. Endless day/night until win; dog catch returns you to the cage for the **next day** (no same-night re-escape).

## Stack

- **Rojo** syncs `src/` into a Studio place (`default.project.json`)
- **Rokit** pins Rojo **7.7.0** (`rokit.toml`) — keep the CLI and Studio plugin on the same version to avoid `protocolVersion` connect errors
- Layout: `src/server` · `src/client` · `src/shared`

## Open / sync the place

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then from this repo:

   ```bash
   rokit install
   ```

   If `rojo --version` is not 7.7.0, Aftman (or another manager) may be shadowing PATH — prefer `~/.rokit/bin` first, or run `~/.rokit/bin/rojo` directly.

2. Start the Rojo server:

   ```bash
   rojo serve
   ```

3. In Roblox Studio: install the [Rojo plugin](https://rojo.space/docs/v7/getting-started/installation/) **7.7.0** → **Connect** to the default address (`localhost:34872`).

4. Press **Play** (solo). Placeholder classroom parts are created at runtime if missing (`CageVolume`, `Latch`, `LessonSpot`, `Phone`, `DogSpawn`).

### Build a place file (optional)

```bash
rojo build -o ClassPet.rbxlx
```

Open `ClassPet.rbxlx` in Studio, or keep using live sync.

## Controls (scaffold)

| Input | Action |
|---|---|
| **E** | Interact — lesson quiz (day), latch (night), phone (night) |
| **Q** | Request Sugar Dash (consumes math buff charge at night) |

## Module map

| Area | Module | Role |
|---|---|---|
| Server | `PhaseController` | Authoritative Day / Night / Won |
| Server | `CageService` | Day containment, latch escape, cage respawn |
| Server | `QuizService` | Present + validate quizzes → buff grants |
| Server | `BuffService` | Day-earned night buff charges |
| Server | `DogAI` | Patrol/chase stub; catch → next day |
| Server | `PhoneObjective` | Desk phone → win |
| Server | `SessionService` | Solo session wiring + snapshots |
| Client | `GoalUI` / `QuizUI` | Phase, goal, buffs, quiz panel |
| Shared | `GameConfig`, `Remotes`, `QuizBank`, `BuffDefs`, `Types` | Tunables + contracts |

CollectionService tags for level work: `CageVolume`, `Latch`, `Phone`, `DogSpawn`, `LessonSpot`, `HideSpot`.

## Design locks (do not contradict)

1. Solo MVP (no shared multiplayer classroom)
2. Day quizzes grant night buffs (not flavor-only; not a hard gate to night)
3. Dog catch ends the night → wait for next day
4. Endless retry until phone win
5. *99 Nights in the Forest*-style readable survival-nights energy (no IP copy)

Buff ids (`QuietPaws`, `SugarDash`, `LessonLeftover`) are **proposals** until finalized.

## Status

Working skeleton: phase clock, remotes, quiz → buff, latch, dog catch → next day, phone win. Not polished gameplay, art, or audio.
