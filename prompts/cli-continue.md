# Continue master prompt in Claude Code CLI (handoff 2026-10-02)

Read and follow `Claude outputs/chop-a-tree-master-prompt.md` (tracks A–J, iron rules §0). Then read `docs/HANDOFF.md` (top section "Master prompt run 2026-10-02"), `SKILL.md`, `docs/plan.md`.

## Done (do not redo)
- §1 survey → HANDOFF. Commit 05f2084.
- Track B Sword Pack 380 + lossless migration (DATA_VERSION 2, LegacyWeaponMap, WeaponCatalog, retro WeaponVisual + trail, data.migratetest). Studio verified. Commit 0b62eaa. Table: docs/sword-pack-migration.md.

## Remaining, in this order (master prompt §10)
1. ~~**A** circular island map~~ (done, see HANDOFF) — concept image: `assets/reference/map-concept.png` (concentric rings rising to the centre: 1 Meadow outermost → 8 Lumora golden tree plateau on top; stairs/arches/torii on the south axis; south hub = dock at the bottom, Chest Altar in the plaza, axe shop left, wood shop right, 7 player houses around the hub; rocky cliff coast). Rebuild through `ServerStorage.MapTools.MapBuilder` (repo `tools/map/MapBuilder.luau`) + `Config/Zones.luau`; keep every tag/attribute (SKILL "Map rework rules"); TreeKit ≥24 retro trees; check every reader of Zones positions; ValidateRoutes Edit+Play; captures; plan §3. Studio's Zones.luau currently holds an abandoned "flat continent" WIP (differs from repo) — replace it.
2. **D + E** ChestBuilder (5 levels, hinge, part budgets §9.7-F), ChestIconRenderer, props; elements-v3 assets.
3. **H** Sprint (Config.Movement, flag `Sprint` already exists in Config/Features = true but nothing uses it yet).
4. **I** Locale/T() EN+TH, Thai font, strings.csv, glossary, missing-key checker = 0.
5. **C** UI/UX audit (3 viewports + gamepad). 6. **J** chest opening cinematic. 7. **F + G** tuning + docs. 8. Final regression + Thai report (§13).

## Working notes learned this session
- Studio MCP: place "Chop a Tree" 93479990217075. `execute_luau` cannot parent NEW instances under ReplicatedStorage/ServerScriptService (Capabilities) — create scripts with `multi_edit` + className; setting `.Source` on existing scripts via execute_luau works. Tests: put a temporary Script in ServerScriptService, Play, read console, Stop, delete it.
- Verify sync after every push: dump `FullName|hash` from Studio (hash of Source with CRLF→LF and trailing whitespace stripped, h=(h*31+byte)%2147483647) and run `python3 tools/studio_sync_check.py < dump`. Expected known diff: ProfileStore (never overwrite).
- **Studio Play uses the live DataStore for the owner's account** — any new DATA_VERSION migration runs on it. Test with synthetic saves (data.migratetest pattern) before Play.
- Compile check: `luau-compile --null <file>` for all `src/**/*.luau`.
- Repo files must be LF; commit only files you changed (worktree has CRLF-only noise in ~30 files and untouched assets/monetization changes — do not commit those). Commit per track, message prefix `feat(A):` etc. Never Publish.
