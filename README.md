# Hamster Simulator: Class Pet

Solo MVP for the Roblox experience **Hamster Simulator: Class Pet** — day quizzes → night buffs, latch escape, dog chase, phone win. Endless day/night until win; dog catch returns you to the cage for the **next day** (no same-night re-escape).

You **are** the hamster (tiny avatar). The cage is a desk-pet enclosure; the classroom stays human-scale.

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

4. Press **Play** (solo). Placeholder classroom + pet cage are created at runtime if missing (`CageVolume`, `Latch`, `LessonSpot`, `Phone`, `DogSpawn`, room shell, desks, set dressing). Player gets a lightweight `HamsterDress` silhouette on the scaled avatar.

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
| **RMB drag** | Orbit hamster camera (close over-shoulder) |
| **Replay** (win panel) | Restart day/night cycle after phone win |

## Module map

| Area | Module | Role |
|---|---|---|
| Server | `PhaseController` | Authoritative Day / Night / Won + Replay |
| Server | `CageService` | Day containment, latch escape, cage respawn |
| Server | `HamsterAvatar` | `ScaleTo(0.2)` hamster-sized player |
| Server | `QuizService` | Present + validate quizzes → buff grants |
| Server | `BuffService` | Day-earned night buff charges |
| Server | `DogAI` | Patrol/chase + readable dog placeholder |
| Server | `PhoneObjective` | Desk phone → win |
| Server | `LevelSetup` | POLYGON-style classroom + custom pet cage |
| Server | `SessionService` | Solo session wiring + snapshots |
| Client | `GoalUI` / `QuizUI` / `HamsterCam` | HUD, quiz, close third-person cam |
| Shared | `GameConfig`, `ArtPalette`, `Remotes`, `QuizBank`, `BuffDefs`, `Types` | Tunables + contracts |

CollectionService tags for level work: `CageVolume`, `Latch`, `Phone`, `DogSpawn`, `LessonSpot`, `HideSpot`.

## Design locks (do not contradict)

1. Solo MVP (no shared multiplayer classroom)
2. Day quizzes grant night buffs (not flavor-only; not a hard gate to night)
3. Dog catch ends the night → wait for next day
4. Endless retry until phone win
5. *99 Nights in the Forest*-style readable survival-nights energy (no IP copy)
6. **Overnight:** close hamster cam · win message + Replay · POLYGON bright classroom · buffs **QuietPaws / SugarDash / LessonLeftover**

## Art / Synty

Roblox-native placeholders match Synty **POLYGON** proportions/colors. Pack priority and import steps for spaceman: **[docs/art-pass.md](./docs/art-pass.md)**.

| Priority | Pack | Use |
|---|---|---|
| 1 | POLYGON Kids Pack | Classroom, desks, students |
| 2 | POLYGON Dog Pack | Night dog |
| 3 | POLYGON Office Pack | Teacher desk / interior |
| 4 | POLYGON Police Station | Desk phone + whiteboard |
| 5 | POLYGON Fantasy Village mouse | Hamster stand-in only |

**No Synty hamster cage** — custom plastic/wire cage + latch + wheel + food (see `PetCageVisual` in `LevelSetup`).

## Status

Playable loop + overnight visual pass (classroom shell, pet cage dressing, day/night lighting, dog/phone readability, hamster cam, win Replay). Still placeholders until Synty FBX import on Bob’s machine.
