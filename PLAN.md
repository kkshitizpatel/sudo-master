# Godot 4 Mobile Sudoku — Master Technical Implementation Plan
**Version**: 1.0.0 (Dark Glassmorphism & Aurora Ambient Glow Edition)  
**Spec Reference**: [SPECIFICATION.md](SPECIFICATION.md) | [specs/001-mobile-sudoku-core/spec.md](specs/001-mobile-sudoku-core/spec.md)  
**Status**: Approved Execution Roadmap  

---

## 1. System Architecture & Foundational Scaffold

### 1.1 Autoload Singletons Architecture
To preserve strict separation of concerns, 4 global Autoload singletons will govern the engine:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                              SignalBus.gd                              │
│       (Global event broadcaster: input, audio, score, themes, ui)      │
└────────────▲───────────────────────────────▲───────────────────────────┘
             │                               │
┌────────────┴─────────────┐   ┌─────────────┴─────────────┐
│      GameManager.gd      │   │      SudokuEngine.gd      │
│  - Player profile & level│   │  - 81 cells board matrix  │
│  - Monotonic clock       │   │  - Candidate notes grid   │
│  - Mistakes limit (0..3) │   │  - Move history (Undo)    │
│  - Scoring & multipliers │   │  - Remaining digit counts │
│  - Haptics controller    │   │  - Rule validation engine │
└────────────┬─────────────┘   └─────────────┬─────────────┘
             │                               │
┌────────────┴─────────────┐   ┌─────────────┴─────────────┐
│     ThemeManager.gd      │   │    DatabaseManager.gd     │
│  - 17 Dual-Tone palettes │   │  - SQLite sudoku.db       │
│  - Canvas shader uniforms│   │  - Transparent JSON fallbk│
│  - Font scale controller │   │  - Active match save/load │
└──────────────────────────┘   └───────────────────────────┘
```

- **`SignalBus.gd`**: Decoupled mediator pattern. Eliminates direct node coupling across scenes.
- **`GameManager.gd`**: Manages session state, scoring formulas (+50 move, combo streaks), 3-mistake lives system, monotonic clock (`Time.get_ticks_msec()`), and tactile haptics (`Input.vibrate_handheld()`).
- **`SudokuEngine.gd`**: Manages the 81-cell board matrix, candidate notes grid, undo history stack, remaining digit counts (1..9), and cell-first vs digit-first input paradigms.
- **`ThemeManager.gd`**: Holds 17 dual-tone color palettes; broadcasts uniform changes to `aurora_glow.gdshader` and UI `StyleBoxFlat` tokens within <200ms.
- **`DatabaseManager.gd`**: Manages persistence via `godot-sqlite` (`user://sudoku.db`) with a robust FileAccess JSON fallback ensuring seamless desktop F5 playtesting.

---

### 1.2 Core Directory Structure
```text
godot sudoku/
├── project.godot                     # 1080x1920 portrait, canvas_items, touch emulation
├── default_bus_layout.tres           # Master, SFX, BGM audio buses
├── export_presets.cfg                # Android release build configuration
├── SPECIFICATION.md                  # Master functional specification
├── PLAN.md                           # Master implementation roadmap
├── scenes/
│   ├── 01_splash_screen_jk_games.tscn
│   ├── 02_welcome_onboarding_screen.tscn
│   ├── 03_claim_your_level_screen.tscn
│   ├── 04_select_game_mode_screen.tscn
│   ├── 05_home_main_menu_screen.tscn
│   ├── 06_sudoku_gameplay_board.tscn
│   ├── 07_theme_palette.tscn
│   ├── 08_settings_palette.tscn
│   ├── components/                   # SudokuCell, NumberPadTray, GlassCard
│   └── popups/                       # GameOverModal, VictoryModal, DifficultyModal
├── scripts/
│   ├── autoload/                     # GameManager, SudokuEngine, ThemeManager, SignalBus
│   ├── core/                         # SudokuGenerator, SudokuSolver, DatabaseManager
│   └── ui/                           # Component controllers (Cell, Pad, Header)
└── assets/
    ├── fonts/                        # Clean sans-serif TTF (Inter-Bold, Inter-Medium)
    ├── shaders/                      # aurora_glow.gdshader, glass_blur.gdshader
    ├── icons/                        # Clean SVG vector graphics
    └── audio/                        # Sound FX (sfx_tick, sfx_error, sfx_complete)
```

---

### 1.3 Persistence & Database Initialization Workflow
1. **On Boot (`01_splash_screen`)**:
   - `DatabaseManager.gd` initializes `user://sudoku.db`.
   - Creates tables if not present: `player_progress`, `campaign_levels` (1–100 seeded), `active_match_save`, `daily_challenges`, `favorites`.
   - Reads `user://settings.cfg`: verifies `has_accepted_terms`, `has_completed_placement`, volume sliders, and `current_theme_id`.
2. **On Every Move in Board**:
   - Board state, candidate notes, elapsed monotonic ticks, and mistake counter automatically write to `active_match_save`.
3. **On Application Pause / Minimize**:
   - `NOTIFICATION_APPLICATION_PAUSED` triggers an emergency flush to disk.

---

## 2. Phased Implementation Roadmap

```text
Phase 1: Core Engine, Shaders & Foundational Scaffold
  ├── project.godot + Mobile Settings + Bus Layout
  ├── Autoloads: SignalBus, GameManager, ThemeManager, SudokuEngine
  └── Shaders: aurora_glow.gdshader, glass_blur.gdshader + 17 Palettes
           │
           ▼
Phase 2: Onboarding Flow (Frames 1 to 3)
  ├── Frame 1: Splash Screen (Hero card + 0-100% tween)
  ├── Frame 2: Welcome / Terms of Service Modal
  └── Frame 3: Claim Your Level (4 Skill Tiers + Calibration Logic)
           │
           ▼
Phase 3: Hub & Mode Selection (Frames 4 & 5)
  ├── Frame 5: Home Main Menu (Hovering matrix + Continue + Dock)
  └── Frame 4: Select Game Mode (Classic, Campaign, Battle PvP, Daily)
           │
           ▼
Phase 4: Core Sudoku Loop (Frame 6)
  ├── 1:1 AspectRatio 9x9 Grid + 81 SudokuCell instances
  ├── 3x3 Candidate notes grid + Remaining count capsule tray
  ├── Move History stack (Undo) + Erase tool + Smart Hint
  └── Combo scoring (+50) + Monotonic timer + Haptics (30ms/150ms)
           │
           ▼
Phase 5: Personalization & System Modals (Frames 7 & 8)
  ├── Frame 7: Dual-Tone Theme Palette (17 Swatches with <200ms tween)
  ├── Frame 8: Settings Modal (Audio sliders, Haptics, Cloud backup)
  └── Popups: GameOverModal (Ad/Coin revive) + VictoryModal (3-Star award)
           │
           ▼
Phase 6: Algorithmic Logic, Gating & AdMob
  ├── Backtracking Generator & Unique-Solution Validator on WorkerThreadPool
  ├── Sequential 1-100 Campaign unlocks (Zero ad/star gating)
  ├── Offline 50-Coin Revive logic + Notes auto-cleanup toggle
  └── Interstitial ad safe-slots (Match transitions only)
           │
           ▼
Phase 7: Mobile Optimization & Android Export
  ├── DisplayServer.get_display_safe_area() notch padding
  ├── 60/120 FPS performance audit & draw call batching
  └── export_presets.cfg (Signed Android .aab bundle, Target SDK 34/35+)
```

---

## 3. Technical Verification & Milestone Gates

| Milestone | Target Deliverable | F5 / F6 Verification Criteria | State Persistence Check |
|:---:|---|---|---|
| **Gate 1** | Scaffold & Shaders | F5 launches 1080x1920 window; Aurora shader animates smoothly; Theme palette changes background colors without lag. | `settings.cfg` writes and restores active theme ID. |
| **Gate 2** | Onboarding Flow | Frame 1 plays 0-100% progress tween; Frame 2 enforces checkbox before continuing; Frame 3 tests level calibration. | `has_accepted_terms` and `has_completed_placement` flags persist across restarts. |
| **Gate 3** | Hub & Menus | Frame 5 displays floating glowing matrix; Continue button activates only if saved game exists; Mode cards route to correct setups. | Level count and coins count load from DB. |
| **Gate 4** | Gameplay Loop | Frame 6 board renders strict 1:1 square; cell selection highlights row/col/box; valid numbers update score; 3 errors trigger game over; Undo reverts moves. | Exiting mid-match and pressing Continue restores exact 81 cells, notes, and timer in <150ms. |
| **Gate 5** | Personalization | Tapping swatches updates shaders live (<200ms); audio sliders adjust bus volumes; font scale expands cell digits. | Volume and font scale persist in `settings.cfg`. |
| **Gate 6** | Sudoku Engine | High-difficulty puzzles generate in <350ms on WorkerThreadPool without UI frame drops; Smart hints point out naked/hidden singles. | Campaign level progression (1–100) unlocks sequentially. |
| **Gate 7** | Mobile Release | Safe areas automatically pad notch on Android; touch inputs register reliably; 60/120 FPS maintained. | Android `.aab` builds cleanly via Godot CLI export. |

---

## 4. Skills & Standards Compliance

To guarantee modern, clean, zero-deprecated Godot 4 codebase architecture, implementation will strictly adhere to the installed **`awesome-gamedev-agent-skills`**:

1. **`godot-ui-control` Compliance**:
   - `AspectRatioContainer` (ratio=1.0) MUST strictly house the 9x9 Sudoku board.
   - Root scenes MUST use `MarginContainer` with dynamic anchors and safe-area offsets rather than hardcoded pixel positions.
   - Styling MUST utilize modular `StyleBoxFlat` resources (16px corner radius, 1px luminous borders) to minimize draw calls.
2. **`godot-shaders` Compliance**:
   - Canvas shaders MUST use `hint_screen_texture` for backdrop blurs and avoid expensive per-pixel loops.
   - Background Aurora shader MUST expose uniforms (`color_primary`, `color_secondary`, `speed`, `intensity`) that interpolate smoothly without pipeline stalls.
3. **`godot-animation` Compliance**:
   - All interactive UI feedback (button taps, cell glows, error shakes, modal slide-ins) MUST be authored via `create_tween()` with `TRANS_BACK` / `TRANS_CUBIC` and `EASE_OUT`.
   - Node tween lifecycles MUST be automatically bound to their parent controls to prevent memory leaks.
4. **`godot-export` Compliance**:
   - `export_presets.cfg` MUST configure headless Android export compliance matching Google Play target API requirements (Target SDK 34/35+).
