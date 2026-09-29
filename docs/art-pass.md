# Art Pass — POLYGON placeholders → Synty import

**Overnight visual pass (2026-09-29):** Play should read as a bright elementary classroom + pet hamster cage, not a baseplate with blue boxes. Geometry in `LevelSetup` is **Roblox-native placeholder** art matching Synty POLYGON proportions/colors until FBX lands.

## Pack priority (from Dex shortlist)

| # | Pack | Use in Class Pet |
|---|---|---|
| 1 | **POLYGON Kids Pack** | Classroom shell, student desks/chairs, kid NPCs, stationery clutter |
| 2 | **POLYGON Dog Pack** | Night dog (Labrador / Golden / Shiba — friendly). Carrier = optional prop only |
| 3 | **POLYGON Office Pack** | Teacher desk, modular interior fill, adult teacher stand-in |
| 4 | **POLYGON Police Station** | Desk **phone**, whiteboard, lamps / night mood FX |
| 5 | **POLYGON Fantasy Village** | Rigged **mouse** as hamster stand-in only (no Synty hamster) |

Full rationale + gaps: Project store `docs/synty-asset-shortlist.md`. Dex: https://dex.syntystore.com/

## Custom-build (no Synty equivalent)

- **Hamster cage** + unreliable **latch** + **wheel** + food bowl — always custom (or kitbash carrier mesh scraps later).
- **Hamster player mesh** — custom POLYGON-style preferred; Fantasy Village mouse only temporary.

## Placeholder ↔ future mesh map

| Runtime name / tag | Placeholder today | Replace with |
|---|---|---|
| `Classroom` shell (Floor, Walls, Windows, Door, Ceiling) | Part kit, Kids-palette walls | Kids Pack classroom demo / modular walls |
| `StudentDesk_*` / `StudentChair_*` | Desk + chair parts | Kids Pack school desks/chairs |
| `TeacherDesk` | Office-brown desk | Office Pack desk |
| `Whiteboard` / `BulletinBoard` | Flat boards | Police Station whiteboard / Kids boards |
| `Phone` (tag `Phone`) | Black desk phone + green ready light | Police Station phone on teacher desk |
| `HamsterDesk` + `PetCageVisual` / `CageVolume` / `Latch` | Custom plastic tray + wire bars + green latch (CageSize **4×2.5×3**) | Keep custom; optional Dog Pack carrier scrap |
| `ClassDog` | Blocky Labrador-ish parts + collar | Dog Pack animated dog |
| Player character | `HamsterAvatar` ScaleTo(**0.2**) + close hamster cam | Custom hamster or Fantasy Village mouse |

## Import steps for spaceman / Studio later

Cloud agents cannot push FBX into the live Roblox place. On a machine with Studio + Bob’s Synty downloads:

1. Confirm owned packs in Synty downloads: **Kids**, **Dog**, **Office**, **Police Station** (phone), optional **Fantasy Village** (mouse).
2. Export / copy FBX (and textures) from each pack. Prefer low-poly POLYGON hero props first.
3. In Studio: **Import 3D** each FBX → check scale against placeholder bounds (cage stays pet-scale; classroom human-scale).
4. Parent imported models under `Workspace.Classroom`, matching names above when possible.
5. Re-apply CollectionService tags on the interactable part (or a primary part): `CageVolume`, `Latch`, `Phone`, `DogSpawn`, `LessonSpot`, `HideSpot`.
6. Hide or delete the Part placeholders once the mesh reads correctly (keep tags on the mesh primary).
7. Retarget Dog Pack walk/run if needed; mouse/hamster idle-walk for player.
8. Re-test day lighting (bright) vs night (dim + phone/dog readable) and latch/phone proximity.

## Palette reference

Colors live in `src/shared/ArtPalette.lua` — keep mesh recolors near those values so day/night contrast stays intentional.
