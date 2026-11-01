# Godot 4 Mobile Sudoku — Master Actionable Task Breakdown (Execution Queue)
**Version**: 1.0.0 (Dark Glassmorphism & Aurora Ambient Glow Edition)  
**Spec Reference**: [SPECIFICATION.md](SPECIFICATION.md) | [specs/001-mobile-sudoku-core/spec.md](specs/001-mobile-sudoku-core/spec.md)  
**Plan Reference**: [PLAN.md](PLAN.md) | [specs/001-mobile-sudoku-core/plan.md](specs/001-mobile-sudoku-core/plan.md)  
**Checklist Reference**: [CHECKLIST.md](CHECKLIST.md) | [specs/001-mobile-sudoku-core/checklists/acceptance.md](specs/001-mobile-sudoku-core/checklists/acceptance.md)  
**Status**: Ready for Autonomous Implementation  

---

## Phase 1: Project Setup & Core Autoloads (Foundation)

- [x] **TASK-101** Configure project settings in `project.godot`
  - **Objective**: Base resolution 1080x1920 (9:16 portrait), `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"`, `input_devices/pointing/emulate_touch_from_mouse=true`, audio buses `Master`, `SFX`, `BGM` in `default_bus_layout.tres`.
  - **Target Files**: `project.godot`, `default_bus_layout.tres`
  - **Acceptance Criteria**: Launching via `godot_console --path .` opens 1080x1920 window with zero warnings.
  - **Dependencies**: None.

- [x] **TASK-102** [P] Scaffold core directory structure
  - **Objective**: Create `scenes/components/`, `scenes/popups/`, `scripts/autoload/`, `scripts/core/`, `scripts/ui/`, `assets/fonts/`, `assets/shaders/`, `assets/icons/`, `assets/audio/`, `data/`.
  - **Target Files**: Project directory tree.
  - **Acceptance Criteria**: All directory paths exist on disk.
  - **Dependencies**: TASK-101.

- [x] **TASK-103** Implement core Autoload singletons scaffolding
  - **Objective**: Author `SignalBus.gd` (events broker), `ThemeManager.gd` (palette state), `GameManager.gd` (session & score), `SudokuEngine.gd` (board state), and register them in `project.godot` `[autoload]`.
  - **Target Files**: `scripts/autoload/SignalBus.gd`, `scripts/autoload/ThemeManager.gd`, `scripts/autoload/GameManager.gd`, `scripts/autoload/SudokuEngine.gd`, `project.godot`
  - **Acceptance Criteria**: Godot boots headless (`godot_console --headless --check-only`) with 0 errors and all singletons globally accessible.
  - **Dependencies**: TASK-101, TASK-102.

- [x] **TASK-104** [P] Implement `DatabaseManager.gd` & SQLite schema initialization
  - **Objective**: Create `DatabaseManager.gd` with table creation DDL (`player_progress`, `campaign_levels`, `active_match_save`, `daily_challenges`, `favorites`) in `user://sudoku.db`, including FileAccess JSON fallback. Setup `user://settings.cfg` read/write parser.
  - **Target Files**: `scripts/core/DatabaseManager.gd`
  - **Acceptance Criteria**: Running `DatabaseManager.initialize_db()` creates database file and tables; read/write operations pass.
  - **Dependencies**: TASK-103.

---

## Phase 2: Visual Engine & Shaders (Dark Glassmorphism)

- [x] **TASK-201** [P] Author real-time backdrop blur shader `glass_blur.gdshader`
  - **Objective**: Implement 2D CanvasItem shader using `hint_screen_texture` multi-tap box blur with surface specular sheen and 1px luminous white border line.
  - **Target Files**: `assets/shaders/glass_blur.gdshader`
  - **Acceptance Criteria**: Assigning shader to a ColorRect blurs background content smoothly at 60/120 FPS.
  - **Dependencies**: TASK-102.

- [x] **TASK-202** [P] Author Aurora ambient glow shader `aurora_glow.gdshader` & cosmic particles
  - **Objective**: Implement dynamic flowing dual-tone gradient simplex shader with `color_primary`, `color_secondary`, `speed`, and `intensity` uniforms. Configure `GPUParticles2D` node with 35 slow upward-floating cosmic dust particles.
  - **Target Files**: `assets/shaders/aurora_glow.gdshader`, `scenes/components/AuroraBackground.tscn`
  - **Acceptance Criteria**: Background renders fluid organic color blobs that dynamically react to uniform color updates.
  - **Dependencies**: TASK-102.

- [x] **TASK-203** Implement 17 Dual-Tone Theme Palette engine in `ThemeManager.gd`
  - **Objective**: Populate dictionary of 17 curated themes (Aero, Neon Emerald, Mint Teal, Forest, Crimson, Mocha, Magenta, Slate, AMOLED, Ice Cyan, Soft Mint, Peach, Violet, Coral, Honey, Pearl, Cyberpunk). Bind color transitions via `create_tween()` to shader uniforms in <200ms.
  - **Target Files**: `scripts/autoload/ThemeManager.gd`
  - **Acceptance Criteria**: Calling `ThemeManager.set_active_theme("theme_emerald")` smoothly interpolates background and accent colors in 0.2s.
  - **Dependencies**: TASK-103, TASK-202.

- [x] **TASK-204** [P] Create global `StyleBoxFlat` glass component resources
  - **Objective**: Generate `.tres` resources for Frosted Glass Panel (16px corner radius, `rgba(15,23,42,0.72)` bg, 1px `rgba(255,255,255,0.12)` border), Frosted Pill (999px radius), and Glass Button interactive states (normal, pressed, hover, focus).
  - **Target Files**: `assets/themes/glass_panel.tres`, `assets/themes/glass_pill.tres`, `assets/themes/glass_button.tres`
  - **Acceptance Criteria**: Panels and buttons render with crisp translucent frosted styling without claymorphic gradients.
  - **Dependencies**: TASK-102.

---

## Phase 3: Onboarding & Calibration Frames

- [x] **TASK-301** Implement Frame 1: Splash Screen (`01_splash_screen_jk_games.tscn`)
  - **Objective**: Build scene layout with Aurora background, center frosted hero card, Golden Crown & Gamepad SVG icons, 'JK GAMES' typography, and slim frosted pill progress track tweening from 0% to 100% (~1.5s). Route to Frame 2 (first-time) or Frame 5 (returning).
  - **Target Files**: `scenes/01_splash_screen_jk_games.tscn`, `scripts/ui/SplashScreen.gd`
  - **Acceptance Criteria**: F6 on scene plays loading tween and triggers scene transition upon reaching 100%.
  - **Dependencies**: TASK-103, TASK-104, TASK-202, TASK-204.

- [x] **TASK-302** Implement Frame 2: Welcome & Onboarding Screen (`02_welcome_onboarding_screen.tscn`)
  - **Objective**: Build header with glowing mini-Sudoku grid, scrollable Terms card, frosted checkbox, and chunky pill button 'ACCEPT & CONTINUE ➔'. Button is disabled until checkbox is checked; persists `has_accepted_terms = true` in `settings.cfg`.
  - **Target Files**: `scenes/02_welcome_onboarding_screen.tscn`, `scripts/ui/WelcomeScreen.gd`
  - **Acceptance Criteria**: Button activates only when checked; clicking routes smoothly to Frame 3 and sets config flag.
  - **Dependencies**: TASK-103, TASK-204, TASK-301.

- [x] **TASK-303** Implement Frame 3: Claim Your Level Screen (`03_claim_your_level_screen.tscn`)
  - **Objective**: Build vertical list of 4 frosted glass skill tier cards (Lvl 1 Instant, Lvl 15 Novice, Lvl 30 Intermediate, Lvl 50 Pro) with clue/time badges. Tapping Tiers 2–4 loads pre-baked calibration test puzzle; completion auto-unlocks prior campaign levels with 2 stars. Tapping Tier 1 skips directly to Frame 5.
  - **Target Files**: `scenes/03_claim_your_level_screen.tscn`, `scripts/ui/ClaimLevelScreen.gd`
  - **Acceptance Criteria**: Calibration pass unlocks levels 1–29 in SQLite; Tier 1 tap routes to Main Menu with Level 1 starting point.
  - **Dependencies**: TASK-104, TASK-204, TASK-302.

---

## Phase 4: Main Hub & Mode Navigation

- [x] **TASK-401** Implement Frame 4: Select Game Mode (`04_select_game_mode_screen.tscn`)
  - **Objective**: Build top profile header (avatar, username, coins pill), title, and 4 frosted cards with distinct neon borders (Classic Mode, Campaign Levels 1–100, Battle 1v1 PvP, Daily Challenge). Include Easy/Med/Hard sub-popup for Classic Mode.
  - **Target Files**: `scenes/04_select_game_mode_screen.tscn`, `scripts/ui/SelectModeScreen.gd`
  - **Acceptance Criteria**: Tapping mode cards sets game mode in `GameManager` and initiates puzzle load.
  - **Dependencies**: TASK-103, TASK-204.

- [x] **TASK-402** Implement Frame 5: Home / Main Menu Screen (`05_home_main_menu_screen.tscn`)
  - **Objective**: Build top bar (level badge, pumpkin score pill, settings gear), center hovering glowing Sudoku matrix visual, glowing 'CONTINUE GAME ✔' button (active only if saved game exists in SQLite), 'NEW GAME' button, and floating bottom navigation dock (Home, Modes, Leaderboard, Stats, Profile).
  - **Target Files**: `scenes/05_home_main_menu_screen.tscn`, `scripts/ui/MainMenuScreen.gd`
  - **Acceptance Criteria**: Central matrix hovers gently via sine-wave tween; Continue button reflects SQLite save state.
  - **Dependencies**: TASK-104, TASK-204, TASK-401.

---

## Phase 5: Core Sudoku Gameplay Board (Frame 6)

- [x] **TASK-501** Build Frame 6 layout tree in `06_sudoku_gameplay_board.tscn`
  - **Objective**: Construct root `MarginContainer` with safe area offsets, Top Controls Header (Back, Share, Favorite, Theme, Settings), Gameplay Stats Bar (Pumpkin Score pill, Level label, Digital Timer pill), center `AspectRatioContainer` (ratio=1.0), Action Tools Bar, and bottom Number Pad Tray.
  - **Target Files**: `scenes/06_sudoku_gameplay_board.tscn`, `scripts/ui/SudokuBoardView.gd`
  - **Acceptance Criteria**: Viewport displays a perfectly clamped 1:1 square board with top controls and bottom tray on any device ratio.
  - **Dependencies**: TASK-103, TASK-204.

- [x] **TASK-502** Implement `SudokuCell.tscn` component & 81-cell grid generation
  - **Objective**: Create `SudokuCell.tscn` with main value label and 3x3 candidate notes grid. Script `SudokuCell.gd` handles cell visual states (resting, selected border glow, row/col/box highlight, matching digit glow, error red). Instantiate 81 cells inside a 9x9 `GridContainer`.
  - **Target Files**: `scenes/components/SudokuCell.tscn`, `scripts/ui/SudokuCell.gd`, `scenes/06_sudoku_gameplay_board.tscn`
  - **Acceptance Criteria**: Clicking any cell highlights row, column, 3x3 box, and matching digits across all 81 cells.
  - **Dependencies**: TASK-501.

- [x] **TASK-503** Implement Action Tools Bar (Counts, Undo, Erase, Notes, Smart Hint)
  - **Objective**: Build 5 frosted action buttons with icons: Counts toggle (toggles bottom rem labels), Undo (pops `move_history` stack), Erase (clears selected cell and notes), Notes toggle (toggles pencil mode with on/off pill indicator), and Smart Hint (glowing bulb with hint counter badge).
  - **Target Files**: `scenes/components/ActionBar.tscn`, `scripts/ui/ActionBar.gd`
  - **Acceptance Criteria**: Tapping Undo restores previous move; Notes button toggles candidate entry mode.
  - **Dependencies**: TASK-501, TASK-502.

- [x] **TASK-504** Implement floating Number Pad Capsule Tray with remaining counts
  - **Objective**: Build floating glass capsule tray with digits 1 through 9. Each tile features a small remaining count label (e.g. 'rem: 4'). When a digit reaches 0 unplaced instances, auto-shrink button by 10% and dim to disabled state via `create_tween()`.
  - **Target Files**: `scenes/components/NumberPadTray.tscn`, `scripts/ui/NumberPadTray.gd`
  - **Acceptance Criteria**: Entering numbers updates bottom remaining count labels; reaching 9 instances dims the tile.
  - **Dependencies**: TASK-501, TASK-502.

- [x] **TASK-505** Implement Dual Input Paradigms (Cell-First & Digit-First)
  - **Objective**: Support Cell-First (select cell ➔ tap number) and Digit-First (tap number to lock ➔ tap cells in rapid succession to fill).
  - **Target Files**: `scripts/autoload/SudokuEngine.gd`, `scripts/ui/SudokuBoardView.gd`
  - **Acceptance Criteria**: Both input sequences accurately place numbers and update board matrices.
  - **Dependencies**: TASK-502, TASK-504.

- [x] **TASK-506** Implement error shake tween, 150ms rumble haptic, and 3-Mistakes counter
  - **Objective**: When an invalid digit is entered: trigger horizontal red pulse shake ($\pm 12\text{px}$ over 0.22s via `create_tween()`), trigger `Input.vibrate_handheld(150)`, decrement life counter (cross out heart icon), and deduct 20 points.
  - **Target Files**: `scripts/ui/SudokuBoardView.gd`, `scripts/autoload/GameManager.gd`
  - **Acceptance Criteria**: 3rd mistake locks board input and pops Game Over Revive modal.
  - **Dependencies**: TASK-502, TASK-505.

- [x] **TASK-507** Implement monotonic CPU timer (`Time.get_ticks_msec()`) & combo scoring
  - **Objective**: Track elapsed solving time using monotonic ticks differential. Award +50 points per correct move; increment combo multiplier (1.5x, 2.0x, 3.0x) when valid moves are executed within 4 seconds of each other.
  - **Target Files**: `scripts/autoload/GameManager.gd`, `scripts/ui/SudokuBoardView.gd`
  - **Acceptance Criteria**: Monotonic timer string updates every second ('00:03'); combo multiplier badge glows and resets after 4s idle.
  - **Dependencies**: TASK-501, TASK-506.

- [x] **TASK-508** Implement candidate notes auto-cleanup on valid digit fill
  - **Objective**: When a correct number $D$ is placed into cell $(r, c)$, query `settings.cfg` for `auto_remove_notes`. If true, automatically delete candidate $D$ from all cells in row $r$, column $c$, and box $b$.
  - **Target Files**: `scripts/autoload/SudokuEngine.gd`
  - **Acceptance Criteria**: Placing digit 5 automatically removes '5' from notes in the same row/col/box.
  - **Dependencies**: TASK-503, TASK-505.

- [x] **TASK-509** Implement mid-game match auto-save to SQLite on scene pause/exit
  - **Objective**: On every move and on `MainLoop.NOTIFICATION_APPLICATION_PAUSED`, serialize current board, solution, candidate notes, elapsed time, mistakes, and score into `active_match_save`.
  - **Target Files**: `scripts/core/DatabaseManager.gd`, `scripts/ui/SudokuBoardView.gd`
  - **Acceptance Criteria**: Quitting during a solve and relaunching app activates 'CONTINUE GAME' and restores exact board in <150ms.
  - **Dependencies**: TASK-104, TASK-501.

---

## Phase 6: System Modals, Algorithmic Engine & Gating

- [x] **TASK-601** Implement Frame 7: Dual-Tone Theme Palette Modal (`07_theme_palette.tscn`)
  - **Objective**: Build frosted slide-in modal with vertical scroll of 17 circular dual-tone swatches. Tapping swatch marks active item with 3D white checkmark (`✔`), calls `ThemeManager.set_active_theme()`, updates shaders live in <0.2s, and provides 3-step font size scale ('A Small' | 'A Medium' | 'A Large').
  - **Target Files**: `scenes/07_theme_palette.tscn`, `scripts/ui/ThemePaletteModal.gd`
  - **Acceptance Criteria**: Selecting any swatch updates background aurora and cell glows in real time; font scale modifies cell text size.
  - **Dependencies**: TASK-203, TASK-501.

- [x] **TASK-602** Implement Frame 8: Settings & Audio Palette Modal (`08_settings_palette.tscn`)
  - **Objective**: Build frosted slide-up modal with SFX volume slider, BGM volume slider, Haptics toggle (`GameManager.haptics_enabled`), notes auto-cleanup toggle, and 'Backup Now' Google Play Cloud Save trigger. Persist values to `user://settings.cfg`.
  - **Target Files**: `scenes/08_settings_palette.tscn`, `scripts/ui/SettingsModal.gd`
  - **Acceptance Criteria**: Adjusting sliders modifies `AudioServer` bus volume immediately and persists to config.
  - **Dependencies**: TASK-101, TASK-104.

- [x] **TASK-603** Implement Game Over Modal (`GameOverModal.tscn`) with Ad & Coin revives
  - **Objective**: Construct modal triggered on 3rd mistake:
    - **Online**: Rewarded Video Ad button. Upon callback, restores 1 life (`mistakes = 2`) and unpauses board.
    - **Offline / Alternative**: Spend 50 Coins button. Deducts 50 coins, restores 1 life, and unpauses. Disabled if coins < 50.
    - **Restart**: Resets board to initial clues, clears timer, resets score, restores 3 lives.
  - **Target Files**: `scenes/popups/GameOverModal.tscn`, `scripts/ui/GameOverModal.gd`
  - **Acceptance Criteria**: Spending 50 coins offline revives the player with 2/3 mistakes; restart clears board.
  - **Dependencies**: TASK-104, TASK-506.

- [x] **TASK-604** Implement `SudokuGenerator.gd` & `SudokuSolver.gd` on `WorkerThreadPool`
  - **Objective**: Author backtracking algorithm capable of generating symmetric 9x9 grids with unique solutions matching SER difficulty scales (Warmup 1.0–1.4 to Nightmare 9.0–11.5+). Dispatch generation tasks on `WorkerThreadPool` to guarantee zero main-thread UI stutter.
  - **Target Files**: `scripts/core/SudokuGenerator.gd`, `scripts/core/SudokuSolver.gd`
  - **Acceptance Criteria**: Generating any puzzle completes in <350ms in the background without dropping UI frames.
  - **Dependencies**: TASK-103, TASK-502.

---

## Phase 7: Polish, Safe Areas & Production Export

- [x] **TASK-701** Implement dynamic notch and navigation bar safe area padding
  - **Objective**: In root UI controllers, query `DisplayServer.get_display_safe_area()`, calculate insets, and adjust root `MarginContainer` theme overrides dynamically.
  - **Target Files**: `scripts/ui/SafeAreaContainer.gd`
  - **Acceptance Criteria**: On devices with camera punch-holes or notches, top and bottom bars never collide with hardware cutouts.
  - **Dependencies**: TASK-301, TASK-402, TASK-501.

- [x] **TASK-702** [P] Execute `awesome-gamedev-agent-skills` compliance audit & headless validation
  - **Objective**: Run `godot_console --headless --check-only` across all `.gd` and `.tscn` files to verify zero deprecated syntax, correct static typing, leak-free tweens, and adherence to `godot-ui-control`, `godot-shaders`, and `godot-animation`.
  - **Target Files**: Complete project codebase.
  - **Acceptance Criteria**: CLI check exits with code 0 and zero compilation warnings.
  - **Dependencies**: TASK-101 through TASK-604.

- [x] **TASK-703** Configure Android release build presets in `export_presets.cfg`
  - **Objective**: Generate `export_presets.cfg` targeting Android SDK 34/35+, ARM64 architecture, signed `.aab` output settings, and application permissions (`VIBRATE`, `INTERNET`).
  - **Target Files**: `export_presets.cfg`
  - **Acceptance Criteria**: Project exports valid signed Android package via Godot headless CLI.
  - **Dependencies**: TASK-701, TASK-702.
