# Implementation Plan: Godot 4 Mobile Sudoku (Dark Glassmorphism & Aurora Edition)

**Branch**: `001-mobile-sudoku-core` | **Date**: 2026-11-01 | **Spec**: [specs/001-mobile-sudoku-core/spec.md](spec.md)

**Input**: Feature specification from `/specs/001-mobile-sudoku-core/spec.md`

---

## 1. Summary
Architect and implement a high-performance, mobile-optimized Sudoku game for Android and Desktop in Godot 4.7.2. The visual identity features sleek Dark Glassmorphism (`StyleBoxFlat` with 16px corner radius and 1px luminous white borders) and real-time Aurora ambient glow shaders. The gameplay engine provides asynchronous 9x9 backtracking generation (SER 1.0 to 11.5+), candidate notes with automated cleanup, 100-level campaign progression with zero ad gating, an onboarding placement engine, offline coin revives, and 17 dual-tone customizable themes.

---

## 2. Technical Context

**Language/Version**: GDScript 2.0 (Godot Engine 4.7.2 Stable)  
**Primary Engine Modules**: 2D Control Nodes (`AspectRatioContainer`, `MarginContainer`, `PanelContainer`), 2D Canvas Shaders (`CanvasItem`), `WorkerThreadPool`  
**Storage**: Dual-tier: SQLite (`user://sudoku.db`) via `DatabaseManager.gd` with transparent JSON/FileAccess fallback; local preferences via `ConfigFile` (`user://settings.cfg`)  
**Audio Architecture**: Custom `default_bus_layout.tres` with `Master`, `SFX`, and `BGM` buses  
**Target Platform**: Android (Target SDK 34/35+, ARM64, Signed .aab) with Desktop PC (Windows 10/11) as visual inspection harness  
**Project Type**: 2D Mobile Native Game  
**Performance Goals**: Locked 60 FPS minimum / 120 FPS high-refresh rate; <15 UI draw calls; <350ms board generation  
**Constraints**: Zero claymorphic elements; 9:16 portrait viewport (1080x1920) with strict 1:1 square grid; monotonic CPU clock (`Time.get_ticks_msec()`); offline playability  

---

## 3. Constitution Check

*GATE: Must pass before implementation. Re-check after Phase 1 design.*

- [x] **Principle I: Antigravity-First Autonomous Architecture**: 100% of `.tscn`, `.gd`, `.gdshader`, and `project.godot` authored by agent. Developer writes zero code; Godot Engine used strictly for F5/F6 visual verification.
- [x] **Principle II: Pure Layered Separation**: Algorithmic puzzle generator and solver are completely headless and run asynchronously on `WorkerThreadPool`. UI nodes communicate via Autoloads and typed signals.
- [x] **Principle III: Dark Glassmorphism & Aurora Design System**: Prohibits claymorphism. Uses `StyleBoxFlat` frosted glass tokens (16px radius, 1px luminous white border) and canvas shaders (`glass_blur.gdshader`, `aurora_glow.gdshader`).
- [x] **Principle IV: Mobile-First 9:16 Portrait Layout**: Viewport locked to 1080x1920 with `AspectRatioContainer` 1:1 grid constraint and safe area notch offsets.
- [x] **Principle V: Fair Play, Monotonic Timing & Haptics**: Elapsed time driven by `Time.get_ticks_msec()`; non-blocking 30ms/150ms haptics via `Input.vibrate_handheld()`.
- [x] **Principle VI: Protocol Tag Safety Guardrails**: Follows `#exact`, `#logic`, `#change`, `#no_change`, `#lock`, etc.

---

## 4. Project Structure

### Documentation (this feature)
```text
specs/001-mobile-sudoku-core/
├── spec.md                  # Baseline feature specification
├── plan.md                  # This implementation plan
├── research.md              # Technical decisions & engine benchmarks
├── data-model.md            # Entity schemas, state transitions
├── quickstart.md            # Verification scenarios (F5/F6 runbook)
├── contracts/               # Signal & API contracts
│   ├── signal-contracts.md
│   └── api-contracts.md
├── checklists/
│   └── requirements.md      # Specification quality checklist
└── tasks.md                 # Actionable implementation tasks (/speckit-tasks)
```

### Source Code (repository root)
```text
c:\Users\kkshi\Downloads\godot sudoku\
├── project.godot                     # Core configuration, autoloads, display settings
├── default_bus_layout.tres           # Audio buses (Master, SFX, BGM)
├── export_presets.cfg                # Android export configuration
├── SPECIFICATION.md                  # Root copy of functional spec
├── PLAN.md                           # Root copy of master roadmap
├── scenes/
│   ├── 01_splash_screen_jk_games.tscn
│   ├── 02_welcome_onboarding_screen.tscn
│   ├── 03_claim_your_level_screen.tscn
│   ├── 04_select_game_mode_screen.tscn
│   ├── 05_home_main_menu_screen.tscn
│   ├── 06_sudoku_gameplay_board.tscn
│   ├── 07_theme_palette.tscn
│   ├── 08_settings_palette.tscn
│   ├── components/                   # Reusable UI elements
│   │   ├── SudokuCell.tscn
│   │   ├── NumberPadTray.tscn
│   │   ├── ActionToolButton.tscn
│   │   └── GlassCard.tscn
│   └── popups/                       # Modal dialogs
│       ├── GameOverModal.tscn
│       ├── VictoryModal.tscn
│       └── DifficultySelectModal.tscn
├── scripts/
│   ├── autoload/
│   │   ├── GameManager.gd            # Master state, scoring, monotonic timer, haptics
│   │   ├── SudokuEngine.gd           # Board state, notes, undo history, validation
│   │   ├── ThemeManager.gd           # 17 dual-tone palettes, shader uniforms, font scale
│   │   └── SignalBus.gd              # Decoupled global signal events
│   ├── core/
│   │   ├── SudokuGenerator.gd        # Backtracking puzzle generation & clue digging
│   │   ├── SudokuSolver.gd           # Elimination deduction solver (Smart Hints)
│   │   ├── SudokuValidator.gd        # Fast bitmask board rule checker
│   │   └── DatabaseManager.gd        # SQLite / JSON persistence service
│   └── ui/
│       ├── SudokuCell.gd
│       ├── NumberPadTray.gd
│       └── NavigationDock.gd
└── assets/
    ├── fonts/                        # Clean sans-serif TTF (Inter-Bold, Inter-Medium)
    ├── shaders/
    │   ├── aurora_glow.gdshader      # Ambient flowing dual-tone background blobs
    │   └── glass_blur.gdshader       # Frosted glass multi-tap blur & specular gloss
    ├── icons/                        # Clean SVG vector icons
    └── audio/                        # Sound FX (sfx_tick, sfx_error, sfx_complete, bgm)
```

---

## 5. Phased Implementation Roadmap

### Phase 1: Core Engine, Shaders & Foundational Scaffold
- [ ] Initialize `project.godot`: 1080x1920 portrait, `canvas_items` expand, mobile touch emulation.
- [ ] Create directory structure (`scenes/`, `scripts/autoload/`, `scripts/core/`, `assets/shaders/`, `assets/fonts/`).
- [ ] Setup `SignalBus.gd`, `GameManager.gd`, `ThemeManager.gd`, and `SudokuEngine.gd` autoloads.
- [ ] Author `aurora_glow.gdshader` and `glass_blur.gdshader`.
- [ ] Implement `ThemeManager.gd` with all 17 dual-tone palettes and shader uniform binding.

### Phase 2: Onboarding Flow (Frames 1 to 3)
- [ ] Frame 1: `01_splash_screen_jk_games.tscn` with hero glass card, crown/gamepad icons, and 0-100% tween loading track.
- [ ] Frame 2: `02_welcome_onboarding_screen.tscn` with terms checkbox and reactive glowing action button.
- [ ] Frame 3: `03_claim_your_level_screen.tscn` with 4 skill tier cards and pre-baked calibration test puzzles.

### Phase 3: Hub & Mode Selection (Frames 4 & 5)
- [ ] Frame 5: `05_home_main_menu_screen.tscn` with hovering glowing matrix, continue button, and floating bottom dock.
- [ ] Frame 4: `04_select_game_mode_screen.tscn` with 4 neon-bordered cards (Classic, Campaign, Battle PvP, Daily Challenge) and difficulty modal.

### Phase 4: Core Sudoku Loop (Frame 6)
- [ ] Component: `SudokuCell.tscn` with 3x3 candidate notes grid and dynamic highlight shaders.
- [ ] Component: `NumberPadTray.tscn` with 1-9 glass capsule tiles and remaining digit counters.
- [ ] Frame 6: `06_sudoku_gameplay_board.tscn` with strict 1:1 `AspectRatioContainer`, top stats bar, action bar, and number pad.
- [ ] Implement cell selection, row/column/box highlighting, candidate note toggling, and undo history stack.
- [ ] Wire tactile haptics (`Input.vibrate_handheld`) and error shake animations (`create_tween`).

### Phase 5: Personalization & System Modals (Frames 7 & 8)
- [ ] Frame 7: `07_theme_palette.tscn` with 17 circular dual-tone swatches and live shader interpolation (<200ms).
- [ ] Frame 8: `08_settings_palette.tscn` with SFX/BGM sliders, haptics toggle, and cloud backup trigger.
- [ ] Modals: `GameOverModal.tscn` and `VictoryModal.tscn`.

### Phase 6: Algorithmic Logic, Gating & AdMob
- [ ] Implement `SudokuGenerator.gd` with backtracking and unique-solution validation on `WorkerThreadPool`.
- [ ] Implement `SudokuSolver.gd` for step-by-step smart hints.
- [ ] Implement sequential campaign level unlocks (Levels 1–100 with zero ad/star paywalls).
- [ ] Implement 3-mistake limit with offline 50-coin revive fallback and AdMob rewarded revive.
- [ ] Implement candidate note auto-cleanup toggle.

### Phase 7: Mobile Optimization & Android Export
- [ ] Implement `DisplayServer.get_display_safe_area()` notch/gesture bar margins.
- [ ] Configure `export_presets.cfg` for Android release (Target SDK 34/35+).
- [ ] Execute 60/120 FPS performance audit and draw call optimization.
