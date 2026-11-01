# Feature Specification: Godot 4 Mobile Sudoku (Dark Glassmorphism & Aurora Edition)

**Feature Branch**: `001-mobile-sudoku-core`  
**Created**: 2026-11-01  
**Status**: Approved Baseline  
**Input**: Master Game Design & Technical Specification (v4.1) — Dark Glassmorphism & Aurora Ambient Glow Edition

---

## Clarifications

### Session 2026-11-01
- Q: How should the game handle the 3rd-mistake Game Over screen if the player is offline and a rewarded video ad cannot be loaded? (FR-023) → A: Option C: Allow coin expenditure (e.g., 50 coins) as an alternative offline revive mechanism.
- Q: How should the Rewarded Ad unlock progression work for Campaign Levels 21 through 50? (FR-003) → A: All 100 campaign levels unlock freely and sequentially upon completing previous level with any star count (1-3); zero ad paywalls or star gating.
- Q: In 1v1 Battle Mode (Live PvP), how should the 3rd-mistake condition be handled? (FR-003, FR-005) → A: Option A: Instant Knockout (Immediate match loss on 3rd mistake; opponent is awarded the victory).
- Q: When a player fills a correct digit into a cell, how should existing candidate pencil notes in that cell's row, column, and 3x3 box be updated? (FR-008) → A: Option A: Auto-erase matching notes automatically (Default ON, with toggle in Settings).
- Q: How should the Smart Hint counter replenish when depleted to 0? (FR-009) → A: Option A: 3 free hints reset on every new puzzle; watching an Ad or spending 20 coins grants +1 hint after 0.

---

## 1. User Scenarios & Testing *(mandatory)*

### User Story 1 - Core Sudoku Solving & Tactile Interaction (Priority: P1)
As a player opening a puzzle, I want a responsive, high-contrast 9x9 grid where tapping cells and numbers provides instantaneous visual highlights and subtle haptic feedback, so that I can solve puzzles smoothly without UI distraction or fatigue.

- **Why this priority**: Core game loop. Without interactive grid, input validation, and feedback, the app has no functional value.
- **Independent Test**: Load gameplay scene with an easy puzzle. Select cell (4,4), tap digit '5'. Cell fills with accent glow, remaining counter updates, and matching row/column/box highlight immediately.

**Acceptance Scenarios**:
1. **Given** an empty playable cell, **When** the user taps the cell, **Then** the cell shows an active primary accent border, its row, column, and 3x3 box show a luminous frosted highlight, and identical numbers across the board illuminate.
2. **Given** a selected empty cell, **When** the user taps a valid number on the pad, **Then** the digit is placed in vivid primary accent color, +50 points are awarded, combo multiplier advances, and a 30ms haptic tick triggers.
3. **Given** a selected empty cell, **When** the user taps an invalid number, **Then** a red pulse horizontal shake triggers on the cell, a 150ms rumble buzz triggers, score penalty (-20) applies, and mistake counter increments by 1.
4. **Given** Notes mode is toggled ON, **When** the user taps numbers, **Then** small candidate pencil digits toggle in the cell without committing a permanent move or triggering mistake penalties.
5. **Given** a digit has been placed 9 times on the board, **Then** its corresponding number tile in the bottom tray automatically shrinks slightly, dims, and disables further entry.

---

### User Story 2 - Onboarding & Skill Placement Test (Priority: P1)
As a first-time player, I want to review terms and optionally test into my appropriate Sudoku skill level, so that I am not forced to grind through trivial beginner levels if I am already an experienced solver.

- **Why this priority**: Crucial first-time user experience (FTUE) and user retention.
- **Independent Test**: Launch app with `has_accepted_terms = false`. Accept terms, select "Level 30 (Intermediate)", complete or test calibration. Verify levels 1–29 auto-unlock with 2 stars.

**Acceptance Scenarios**:
1. **Given** a fresh install, **When** splash screen finishes, **Then** the Welcome & Onboarding screen presents terms with a disabled Continue button until terms are explicitly checked.
2. **Given** terms accepted, **When** entering Claim Your Level, **Then** 4 distinct skill tiers are presented: Level 1 (Instant), Level 15 (Novice), Level 30 (Intermediate), and Level 50 (Pro/Expert).
3. **Given** the user selects Tier 2, 3, or 4, **When** the timed calibration board is solved without exceeding 3 mistakes, **Then** celebration wave triggers and all preceding campaign levels up to the target tier auto-unlock with default 2-star ratings.
4. **Given** the user fails calibration or taps Tier 1, **When** exiting, **Then** player starts fresh at Level 1 with no penalties.

---

### User Story 3 - Campaign Mode Progression (Priority: P2)
As a dedicated player, I want to progress through 100 hand-crafted campaign levels graded by Sudoku Explainer Rating (SER 1.0 to 11.5+), so that I can continually challenge myself with advanced solving techniques.

- **Why this priority**: Long-term player retention and single-player content depth.
- **Independent Test**: Complete Level 1. Verify Level 2 unlocks, star rating saves in SQLite database, and high score persists across sessions.

**Acceptance Scenarios**:
1. **Given** any campaign level $N$ is cleared (earning 1, 2, or 3 stars), **Then** level $N+1$ unlocks immediately without any star minimums, paywalls, or ad requirements.
2. **Given** all 100 campaign levels, **Then** progression is 100% free and sequential; players can advance immediately upon completing the preceding level regardless of star rating.

---

### User Story 4 - Visual Personalization & Theme Palette (Priority: P2)
As a player who values aesthetics, I want to customize the interface with dual-tone dark glassmorphic themes (Aero, AMOLED, Forest, Rose, etc.) and adjust typography, so that the game matches my visual preference and comfort.

- **Why this priority**: Delivers on the core Dark Glassmorphism & Aurora brand promise.
- **Independent Test**: Open Theme Palette, tap "Emerald". In under 0.2s, background aurora blobs, card luminous borders, and primary button accents transition smoothly to emerald & soft mint.

**Acceptance Scenarios**:
1. **Given** the theme palette modal is opened, **When** tapping any of the 17 dual-tone swatches, **Then** background canvas shaders and UI StyleBoxFlat accents interpolate immediately.
2. **Given** font size toggle ('A Small' | 'A Medium' | 'A Large'), **When** selected, **Then** grid cell font scales adjust dynamically without altering 1:1 board bounding box constraints.

---

### User Story 5 - Daily Challenge & Calendar Streak (Priority: P3)
As a daily player, I want a unique date-seeded puzzle every calendar day with streak tracking and calendar star stamps, so that I have a daily incentive to return.

- **Why this priority**: Daily active user (DAU) driver.
- **Independent Test**: Change date seed or launch on a new day. Verify puzzle matches date seed `YYYY-MM-DD`, and completion stamps the monthly calendar grid and increments the 7-day flame counter.

**Acceptance Scenarios**:
1. **Given** today's date, **When** tapping Daily Challenge, **Then** a deterministic mathematical seed generates today's puzzle.
2. **Given** puzzle is solved, **Then** a golden star stamp is recorded on the monthly calendar matrix, and the active flame streak counter increments.

---

### User Story 6 - Battle Mode (1v1 Live PvP Duel) (Priority: P3)
As a competitive player, I want to duel a friend or random opponent on identical puzzle seeds, seeing their live progress bar updated in real time, so that I can experience multiplayer Sudoku.

- **Why this priority**: Social engagement and competitive retention.
- **Independent Test**: Simulate two clients connecting with identical seed. Client A fills cells; Client B's screen reflects Client A's progress bar percentage in real time via REST sync.

**Acceptance Scenarios**:
1. **Given** matchmaking handshake completes, **Then** both players receive identical puzzle seeds and start synchronized timers.
2. **Given** opponent places valid digits, **Then** opponent's frosted progress pill advances smoothly across the screen header without revealing cell solutions.
3. **Given** either player accumulates 3 mistakes during the match, **Then** an instant knockout occurs immediately, terminating the match and declaring the surviving opponent the winner.

---

## 2. Detailed Frame Specifications (Frames 1 to 8)

### Frame 1: Splash Screen (`01_splash_screen_jk_games.tscn`)
* **Preconditions**:
  - Godot Engine initialization complete.
  - Display resolution locked to 1080x1920 portrait.
* **Postconditions**:
  - `sudoku.db` SQLite schema verified/created.
  - `user://settings.cfg` loaded into `GameManager` and `ThemeManager`.
  - Shader pre-warming executed to prevent runtime compilation stutter.
* **Input Triggers & Signals**:
  - Scene `_ready()` ➔ Initiates asset precaching and progress tween.
  - `signal splash_completed` ➔ Dispatched when progress bar reaches 100%.
* **State Machine**:
  - `STATE_INITIALIZING` ➔ Progress bar 0% to 50% (DB check, config read).
  - `STATE_PRECACHING` ➔ Progress bar 50% to 100% (shader compilation, font load).
  - Transition: If `GameManager.has_accepted_terms == false` ➔ Transition to Frame 2; else ➔ Transition to Frame 5 (Main Menu).

---

### Frame 2: Welcome & Onboarding (`02_welcome_onboarding_screen.tscn`)
* **Preconditions**:
  - Frame 1 completed with `has_accepted_terms == false`.
* **Postconditions**:
  - `has_accepted_terms = true` saved to `user://settings.cfg`.
* **Input Triggers & Signals**:
  - `CheckBox.toggled(is_checked: bool)` ➔ Emits `terms_toggled(is_checked)`; toggles `BtnAccept.disabled` and primary accent border glow.
  - `BtnAccept.pressed()` ➔ Emits `onboarding_accepted`; writes config and initiates cross-fade to Frame 3.
* **State Machine**:
  - `STATE_IDLE_UNCHECKED`: Accept button disabled, low alpha (0.4).
  - `STATE_READY_CHECKED`: Accept button glowing, pulsing primary accent.

---

### Frame 3: Claim Your Level (`03_claim_your_level_screen.tscn`)
* **Preconditions**:
  - User has completed Frame 2 or triggered placement test from Settings.
* **Postconditions**:
  - `has_completed_placement = true` saved.
  - Target level unlocks written to SQLite `campaign_levels`.
* **Input Triggers & Signals**:
  - `TierCard[1..4].gui_input(event)` ➔ Emits `tier_selected(tier_index)`.
  - `signal calibration_passed(target_level)` ➔ Awards 2 stars to preceding levels, triggers celebration wave, routes to Frame 5.
  - `signal calibration_failed` ➔ Displays friendly encouragement modal, resets to Level 1, routes to Frame 5.
* **State Machine**:
  - `STATE_TIER_SELECT`: Cards hoverable, displays clues/time metrics.
  - `STATE_CALIBRATING`: Timed gameplay mode (no hints allowed, 3 mistakes limit).

---

### Frame 4: Select Game Mode (`04_select_game_mode_screen.tscn`)
* **Preconditions**:
  - User profile, coins, level badge, and daily streak loaded in `GameManager`.
* **Postconditions**:
  - Selected mode and parameters passed to `GameManager.current_game_mode`.
* **Input Triggers & Signals**:
  - `BtnBack.pressed()` ➔ Emits `navigate_back`; transitions to Frame 5.
  - `CardClassic.pressed()` ➔ Opens sub-popup (Easy, Medium, Hard pills) ➔ Emits `start_classic_game(difficulty)`.
  - `CardCampaign.pressed()` ➔ Emits `start_campaign_level(next_level_id)`.
  - `CardBattle.pressed()` ➔ Emits `initiate_pvp_matchmaking`.
  - `CardDaily.pressed()` ➔ Emits `start_daily_challenge(date_seed)`.
* **State Machine**:
  - `STATE_DEFAULT`: 4 neon-bordered cards displayed with glow.
  - `STATE_DIFFICULTY_POPUP`: Frosted modal overlay with 3 segmented pills.

---

### Frame 5: Home / Main Menu (`05_home_main_menu_screen.tscn`)
* **Preconditions**:
  - Database queried for active saved game (`has_saved_game: bool`).
* **Postconditions**:
  - None (navigational hub).
* **Input Triggers & Signals**:
  - `BtnSettings.pressed()` ➔ Opens Frame 7 / 8 modal with slide-up tween.
  - `BtnContinue.pressed()` ➔ Emits `resume_saved_game` ➔ Transitions to Frame 6 with saved board state.
  - `BtnNewGame.pressed()` ➔ Transitions to Frame 4.
  - `DockTab[0..4].pressed()` ➔ Emits `tab_switched(tab_id)` (Home, Modes, Leaderboard, Stats, Profile).
* **State Machine**:
  - `STATE_IDLE`: Central glowing matrix slowly hovers (sine wave floating animation).
  - `STATE_MODAL_ACTIVE`: Background darkened, frosted glass sheet popped.

---

### Frame 6: Sudoku Gameplay Board (`06_sudoku_gameplay_board.tscn`)
* **Preconditions**:
  - `SudokuEngine` initialized with puzzle data, clues mask, and timer reference.
* **Postconditions**:
  - Board state auto-saved to SQLite `active_match_save` on every move or exit.
  - Match stats logged upon victory or defeat.
* **Input Triggers & Signals**:
  - Top Bar:
    - `BtnBack.pressed()` ➔ Auto-saves match state, routes to Frame 5.
    - `BtnShare.pressed()` ➔ Emits `share_puzzle_requested`.
    - `BtnFavorite.pressed()` ➔ Emits `toggle_favorite_requested`.
    - `BtnTheme.pressed()` ➔ Opens Frame 7 modal overlay without pausing timer.
    - `BtnSettings.pressed()` ➔ Opens Frame 8 modal overlay and pauses timer.
  - Grid:
    - `Cell[r, c].gui_input(event)` ➔ Emits `cell_selected(r, c)`.
  - Action Tools:
    - `BtnCounts.pressed()` ➔ Emits `toggle_remaining_counts`.
    - `BtnUndo.pressed()` ➔ Emits `undo_move_requested`.
    - `BtnErase.pressed()` ➔ Emits `erase_cell_requested`.
    - `BtnNotes.pressed()` ➔ Emits `toggle_notes_mode`.
    - `BtnHint.pressed()` ➔ Emits `smart_hint_requested`.
  - Number Pad:
    - `NumTile[1..9].pressed()` ➔ Emits `digit_entered(digit)`.
* **State Machine**:
  - `STATE_PLAYING`: Timer running, board interactive.
  - `STATE_PAUSED`: Frosted overlay over grid, monotonic timer offset tracked.
  - `STATE_GAME_OVER`: 3 mistakes reached, Game Over dialog displayed with Rewarded Ad revive option.
  - `STATE_VICTORY`: All 81 cells correctly filled; celebratory particle burst, score calculation, rating award dialog.

---

### Frame 7: Theme Palette Modal (`07_theme_palette.tscn`)
* **Preconditions**:
  - `ThemeManager` active palette list pre-loaded.
* **Postconditions**:
  - Selected theme ID written to `user://settings.cfg`.
* **Input Triggers & Signals**:
  - `BtnClose.pressed()` ➔ Closes modal via slide-out tween.
  - `SwatchItem[id].pressed()` ➔ Emits `theme_palette_selected(theme_id)`.
  - `FontPill[Small|Med|Large].pressed()` ➔ Emits `font_scale_changed(scale_factor)`.
  - `SyncToggle.toggled(enabled)` ➔ Emits `system_dark_mode_sync_toggled(enabled)`.
* **State Machine**:
  - `STATE_MODAL`: Vertical scroll container of 17 circular swatches; active theme displays 3D white checkmark (`✔`).

---

### Frame 8: Settings & Audio Palette Modal (`08_settings_palette.tscn`)
* **Preconditions**:
  - Current audio bus volumes (`SFX`, `BGM`) and haptics flag read from `AudioServer` and `GameManager`.
* **Postconditions**:
  - Volumes and haptics preferences saved to `user://settings.cfg`.
* **Input Triggers & Signals**:
  - `SliderSFX.value_changed(val)` ➔ Updates `AudioServer.set_bus_volume_db("SFX", val)`.
  - `SliderBGM.value_changed(val)` ➔ Updates `AudioServer.set_bus_volume_db("BGM", val)`.
  - `ToggleHaptics.toggled(enabled)` ➔ Updates `GameManager.haptics_enabled`.
  - `BtnBackupCloud.pressed()` ➔ Emits `cloud_save_sync_requested`.
* **State Machine**:
  - `STATE_MODAL`: Slide-up sheet with interactive controls and account status indicator.

---

## 3. UI & Design System Tokens (Dark Glassmorphism & Aurora)

### 3.1 Frosted Glass Component Tokens (`StyleBoxFlat`)
Every card, dialog, dock, and cell must adhere strictly to these token specifications:

| Token Name | Property | Value | Description |
|---|---|---|---|
| `glass_panel_bg` | `bg_color` | `rgba(15, 23, 42, 0.72)` | Deep slate translucent frosted surface |
| `glass_panel_radius` | `corner_radius_*` | `16px` | Smooth modern corner curvature |
| `glass_border_color` | `border_color` | `rgba(255, 255, 255, 0.12)`| Delicate 1px luminous specular line |
| `glass_border_width` | `border_width_*` | `1px` (all sides) | Minimal hairline border |
| `glass_pill_radius` | `corner_radius_*` | `999px` | Fully rounded pill container for toggles/counters |
| `cell_default_bg` | `bg_color` | `rgba(30, 41, 59, 0.45)` | Grid cell resting state |
| `cell_selected_bg` | `bg_color` | `rgba(var(--accent-rgb), 0.28)` | Selected cell filled glow |
| `cell_highlight_bg` | `bg_color` | `rgba(255, 255, 255, 0.06)`| Matching row, column, and box highlight |
| `cell_matching_digit`| `bg_color` | `rgba(var(--accent-rgb), 0.18)` | Identical digits on grid |
| `cell_border_selected`| `border_color`| `rgba(var(--accent-rgb), 0.95)` | 2px solid primary accent glow |

---

### 3.2 Dual-Tone Accent Theme Matrix (17 Swatches)
Themes are defined as a strict pairing: **Color 1 (Primary Accent)** drives active buttons, selected cells, and glowing toggles; **Color 2 (Secondary Glow)** drives ambient aurora blobs, luminous card borders, and combo badges.

| Theme ID | Display Name | Color 1: Primary Accent | Color 2: Secondary Glow | Base Canvas Mode |
|---|---|---|---|---|
| `theme_aero` | Aero | `#38BDF8` (Sky Cyan) | `#4338CA` (Deep Indigo) | Dark Frosted |
| `theme_default` | Neon Emerald | `#10B981` (Neon Mint) | `#065F46` (Deep Pine) | Dark Frosted |
| `theme_teal` | Mint Teal | `#14B8A6` (Mint Teal) | `#0F766E` (Deep Teal) | Dark Frosted |
| `theme_forest` | Forest Moss | `#22C55E` (Vivid Leaf) | `#14532D` (Dark Moss) | Dark Frosted |
| `theme_red` | Crimson Wine | `#F43F5E` (Rose Crimson) | `#881337` (Burgundy) | Dark Frosted |
| `theme_mocha` | Warm Mocha | `#D97706` (Warm Bronze) | `#451A03` (Espresso) | Dark Frosted |
| `theme_pink` | Neon Magenta | `#EC4899` (Hot Magenta) | `#701A75` (Soft Violet) | Dark Frosted |
| `theme_dark` | Charcoal Slate | `#94A3B8` (Silver Slate) | `#334155` (Deep Slate) | Dark Frosted |
| `theme_amoled` | Pure AMOLED | `#F8FAFC` (Pure White) | `#1E293B` (Pitch Void) | 100% Black |
| `theme_skyblue` | Ice Cyan | `#0284C7` (Sky Blue) | `#BAE6FD` (Ice Cyan) | Dark Frosted |
| `theme_emerald` | Soft Mint | `#059669` (Emerald) | `#A7F3D0` (Soft Mint) | Dark Frosted |
| `theme_tangerine`| Peach Orange | `#EA580C` (Tangerine) | `#FED7AA` (Warm Peach) | Dark Frosted |
| `theme_violet` | Lilac Violet | `#7C3AED` (Royal Violet) | `#DDD6FE` (Lilac Dream) | Dark Frosted |
| `theme_coral` | Coral Rose | `#E11D48` (Coral Rose) | `#FECDD3` (Pale Pink) | Dark Frosted |
| `theme_honey` | Buttercup Honey | `#D97706` (Golden Honey) | `#FEF08A` (Buttercup) | Dark Frosted |
| `theme_slate` | Pearl Slate | `#334155` (Deep Slate) | `#E2E8F0` (Pearl Gray) | Dark Frosted |
| `theme_cyber` | Cyberpunk Neon | `#06B6D4` (Electric Cyan) | `#D946EF` (Neon Fuchsia)| Dark Frosted |

---

### 3.3 Aurora Canvas Shader & Particle Parameters
* **Shader Uniforms (`aurora_glow.gdshader`)**:
  - `uniform vec4 color_primary : source_color` ➔ Bind to Theme Color 1.
  - `uniform vec4 color_secondary : source_color` ➔ Bind to Theme Color 2.
  - `uniform float speed : hint_range(0.05, 1.0) = 0.2` ➔ Slow organic fluid flow.
  - `uniform float intensity : hint_range(0.1, 1.0) = 0.45` ➔ Soft non-distracting background luminosity.
  - `uniform float blur_factor : hint_range(1.0, 8.0) = 4.0` ➔ Smooth gradient blur blending.
* **Ambient Cosmic Particles (`GPUParticles2D`)**:
  - `amount`: 35 particles (low overhead, battery-friendly).
  - `lifetime`: 8.0 seconds with random jitter.
  - `emission_shape`: Box (1080x1920 viewport coverage).
  - `gravity`: `Vector2(0, -6)` (subtle upward cosmic drift).
  - `scale_amount`: Random `0.5` to `2.5px`.
  - `color_ramp`: Subtle fade-in, hover at 40% alpha, slow fade-out.

---

## 4. Data & State Contracts

### 4.1 Autoload State Contracts

#### A. `GameManager.gd` (Master Autoload)
```gdscript
# Persistent Player Data
var player_name: String = "Guest_4821"
var player_level: int = 1
var coins_count: int = 100
var high_score: int = 0
var daily_streak_count: int = 0
var last_daily_date: String = ""

# Session & Onboarding Flags
var has_accepted_terms: bool = false
var has_completed_placement: bool = false
var has_saved_game: bool = false
var haptics_enabled: bool = true

# Active Match State
var current_game_mode: int = 0 # 0: Classic, 1: Campaign, 2: Battle, 3: Daily
var current_level_id: int = 1
var current_score: int = 0
var combo_multiplier: float = 1.0
var mistakes_count: int = 0 # 0 to 3 max
var hints_remaining: int = 3
var match_start_ticks: int = 0
var elapsed_seconds: int = 0
var is_game_paused: bool = false

# Signals
signal score_updated(new_score: int, combo: float)
signal mistake_occurred(current_mistakes: int, max_mistakes: int)
signal game_over_triggered(reason: String)
signal level_completed(level_id: int, stars: int, score: int, time_seconds: int)
signal timer_ticked(formatted_time: String)
```

#### B. `SudokuEngine.gd` (Board State & Logic Controller)
```gdscript
# Board Matrices
var board_solution: Array[int] = [] # 81 integers (1..9)
var initial_clues: Array[int] = []    # 81 integers (0 if empty)
var current_board: Array[int] = []    # 81 integers (current values)
var candidate_notes: Array = []       # 81 sub-arrays of candidate ints
var remaining_counts: Dictionary = {} # Key: 1..9, Value: remaining count (0..9)

# Interaction Modes
var is_notes_mode: bool = false
var is_digit_first_mode: bool = false
var selected_cell_index: int = -1 # 0 to 80, -1 if none
var selected_digit_lock: int = -1 # 1 to 9 if digit-first locked

# Undo History Stack
var move_history: Array[Dictionary] = [] # Records {cell, prev_val, new_val, prev_notes}

# Signals
signal cell_state_changed(cell_index: int, value: int, is_note: bool)
signal board_cleared_check_passed()
signal remaining_counts_updated(counts_dict: Dictionary)
signal hint_deduction_ready(cell_index: int, suggested_digit: int, explanation: String)
```

#### C. `ThemeManager.gd` (Styling & Shaders Controller)
```gdscript
var current_theme_id: String = "theme_default"
var font_scale_factor: float = 1.0 # 0.85 (Small), 1.0 (Med), 1.2 (Large)
var sync_with_os_dark_mode: bool = false

# Dictionary of all 17 dual-tone themes
var themes_catalog: Dictionary = {}

# Signals
signal theme_applied(theme_id: String, primary_color: Color, secondary_color: Color)
signal font_scale_applied(new_scale: float)
```

---

### 4.2 SQLite Database Schema (`user://sudoku.db`)

#### Table 1: `player_progress`
```sql
CREATE TABLE IF NOT EXISTS player_progress (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    player_name TEXT NOT NULL DEFAULT 'Guest_4821',
    user_level INTEGER NOT NULL DEFAULT 1,
    coins INTEGER NOT NULL DEFAULT 100,
    daily_streak INTEGER NOT NULL DEFAULT 0,
    last_daily_played TEXT DEFAULT '',
    has_completed_placement INTEGER NOT NULL DEFAULT 0,
    last_synced_timestamp INTEGER NOT NULL DEFAULT 0
);
```

#### Table 2: `campaign_levels`
```sql
CREATE TABLE IF NOT EXISTS campaign_levels (
    level_id INTEGER PRIMARY KEY, -- 1 to 100
    zone_name TEXT NOT NULL,
    ser_rating REAL NOT NULL,
    clues_count INTEGER NOT NULL,
    is_unlocked INTEGER NOT NULL DEFAULT 0, -- 1 = unlocked
    stars_earned INTEGER NOT NULL DEFAULT 0, -- 0 to 3
    best_time_seconds INTEGER NOT NULL DEFAULT 0,
    best_score INTEGER NOT NULL DEFAULT 0,
    completed_timestamp INTEGER DEFAULT 0
);
```

#### Table 3: `active_match_save`
```sql
CREATE TABLE IF NOT EXISTS active_match_save (
    slot_id INTEGER PRIMARY KEY CHECK (slot_id = 1),
    game_mode INTEGER NOT NULL, -- 0: Classic, 1: Campaign, 2: Battle, 3: Daily
    level_id INTEGER NOT NULL DEFAULT 1,
    elapsed_seconds INTEGER NOT NULL DEFAULT 0,
    mistakes_count INTEGER NOT NULL DEFAULT 0,
    hints_used INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    combo REAL NOT NULL DEFAULT 1.0,
    board_solution TEXT NOT NULL,  -- 81 comma-separated digits
    initial_clues TEXT NOT NULL,   -- 81 comma-separated digits
    current_board TEXT NOT NULL,   -- 81 comma-separated digits
    candidate_notes TEXT NOT NULL, -- JSON-serialized array of notes
    last_saved_timestamp INTEGER NOT NULL
);
```

#### Table 4: `daily_challenges`
```sql
CREATE TABLE IF NOT EXISTS daily_challenges (
    date_key TEXT PRIMARY KEY, -- YYYY-MM-DD
    is_completed INTEGER NOT NULL DEFAULT 0,
    stars_earned INTEGER NOT NULL DEFAULT 0,
    time_taken_seconds INTEGER NOT NULL DEFAULT 0,
    score_achieved INTEGER NOT NULL DEFAULT 0
);
```

#### Table 5: `favorites`
```sql
CREATE TABLE IF NOT EXISTS favorites (
    puzzle_id TEXT PRIMARY KEY,
    puzzle_seed TEXT NOT NULL,
    difficulty_name TEXT NOT NULL,
    date_favorited INTEGER NOT NULL
);
```

---

### 4.3 Local `user://settings.cfg` Schema
```ini
[graphics]
current_theme_id="theme_default"
font_scale=1.0
sync_os_dark=false

[audio]
sfx_volume_db=0.0
bgm_volume_db=-6.0
sfx_muted=false
bgm_muted=false

[gameplay]
haptics_enabled=true
show_remaining_counts=true
highlight_duplicates=true
highlight_scope=true
auto_remove_notes=true

[onboarding]
has_accepted_terms=false
has_completed_placement=false
```

---

## 5. Edge Cases, Failures & Boundary Conditions

### 5.1 Mistake Limit & AdMob Revive Flow
- **Boundary**: When `mistakes_count == 3`:
  1. `GameManager` immediately sets `is_game_paused = true`.
  2. The input grid locks to prevent any further interaction.
  3. A frosted modal overlay appears with options:
     - **Revive via Rewarded Ad (Online)**: Rewarded video ad plays. Upon completion callback, 1 life is restored (`mistakes_count` set to 2), board resumes without score penalty, and timer unpauses. If the ad fails to load or user skips before reward, state remains at Game Over.
     - **Revive via Coins (Offline / Alternative)**: If the player is offline or chooses not to watch an ad, they can spend 50 coins to restore 1 life (`mistakes_count` set to 2) and resume solving. If coins < 50, this option displays disabled.
     - **Restart Level**: Resets board to initial clues, clears timer, resets score to 0, and restores lives to 3/3.

### 5.2 Monotonic Timer & Background Suspension Integrity
- **Boundary**: Player minimizes the app, locks phone, or changes system clock during active solve:
  1. System clocks can be tampered with (forward-shifting to bypass timers or daily limits).
  2. The timer is measured strictly via `Time.get_ticks_msec()` differential while active.
  3. On `MainLoop.NOTIFICATION_APPLICATION_PAUSED` (app backgrounded):
     - Active tick accumulator freezes.
     - Board state auto-saves immediately to SQLite `active_match_save`.
  4. On `MainLoop.NOTIFICATION_APPLICATION_RESUMED` (app foregrounded):
     - Baseline tick resets to current `Time.get_ticks_msec()`.
     - The game enters a paused modal state ("Game Paused - Tap to Resume"), preventing rapid countdown loss while player is re-orienting.

### 5.3 Crash & Unexpected Termination Auto-Recovery
- **Boundary**: Device runs out of battery, OS kills process in background, or crash occurs:
  1. Every valid number entry and note commit immediately writes to `active_match_save`.
  2. Upon app launch, Frame 5 queries `active_match_save`.
  3. If a record exists, `BtnContinue` illuminates with a glowing "CONTINUE GAME ✔" badge.
  4. Tapping Continue reconstitutes the exact 81 cells, candidate notes, timer, score, and mistake counter in under 150ms.

### 5.4 PvP Opponent Disconnect & Seed Mismatch
- **Boundary**: 1v1 Battle Mode loses network connection or encounters seed desync:
  1. During match initiation, clients exchange CRC32 checksums of the generated puzzle board. If checksums mismatch, handshake aborts with a graceful "Matchmaking Retry" notification.
  2. If an opponent disconnects mid-game for >15 seconds:
     - Opponent's status displays "Reconnecting...".
     - If timer expires without reconnect, player is awarded a "Default Victory" with normal score and coin rewards.
  3. If a player commits their 3rd mistake, an instant knockout triggers: their screen displays defeat while the opponent receives an instant victory notification.

---

## 6. Functional Requirements (FR-001 to FR-025)

- **FR-001**: System MUST display an 81-cell Sudoku grid locked in a 1:1 square `AspectRatioContainer`.
- **FR-002**: System MUST generate valid 9x9 puzzles with guaranteed unique solutions via backtracking on `WorkerThreadPool`.
- **FR-003**: System MUST support 4 distinct gameplay modes: Classic, Campaign (Levels 1–100 with sequential unlock and zero ad/star paywalls), 1v1 Battle, and Daily Challenge.
- **FR-004**: System MUST calculate score dynamically based on moves (+50), mistakes (-20), hints (-50), and combo streak multipliers.
- **FR-005**: System MUST enforce a 3-mistake limit before triggering Game Over.
- **FR-006**: System MUST provide an Undo mechanism capable of reverting moves and restored notes sequentially.
- **FR-007**: System MUST provide an Erase tool to clear player-filled numbers and pencil notes on non-clue cells.
- **FR-008**: System MUST support candidate Pencil Notes mode with up to 9 sub-digits displayed per cell, and MUST automatically remove candidate notes from affected row, column, and 3x3 box cells upon placing a correct digit (default ON, configurable in Settings).
- **FR-009**: System MUST provide a Smart Hint engine (3 free hints initialized per puzzle) that highlights logical elimination steps without giving away the full board, allowing users to earn additional hints upon reaching 0 by watching a Rewarded Ad or spending 20 coins.
- **FR-010**: System MUST track and display remaining counts (1 to 9) beneath number pad tiles, dimming tiles with 0 remaining.
- **FR-011**: System MUST support both Cell-First and Digit-First input paradigms.
- **FR-012**: System MUST render all UI panels and cards with 16px rounded frosted glass StyleBoxFlat and 1px luminous white borders.
- **FR-013**: System MUST provide 17 dual-tone color swatches that live-update shaders and UI tints within 200ms.
- **FR-014**: System MUST render an organic animated aurora background with floating color blobs and 35 ambient particles.
- **FR-015**: System MUST measure game duration using CPU monotonic ticks (`Time.get_ticks_msec()`).
- **FR-016**: System MUST persist player progress, campaign unlocks, and auto-save state in an offline SQLite database (`sudoku.db`).
- **FR-017**: System MUST persist audio levels, theme choices, and haptics in a local configuration file (`settings.cfg`).
- **FR-018**: System MUST deliver 30ms subtle tactile tick on selection and 150ms rumble on error via `Input.vibrate_handheld()`.
- **FR-019**: System MUST provide a "Claim Your Level" placement test supporting calibration into Levels 1, 15, 30, or 50.
- **FR-020**: System MUST automatically unlock all preceding campaign levels with 2 stars upon passing placement calibration.
- **FR-021**: System MUST automatically adjust container margins for mobile camera cutouts using `DisplayServer.get_display_safe_area()`.
- **FR-022**: System MUST auto-save active gameplay state on every move and on application pause.
- **FR-023**: System MUST offer rewarded video ad revives upon reaching the 3rd mistake, with an alternative offline/coin-based revive mechanism allowing players to spend 50 coins to continue.
- **FR-024**: System MUST prohibit ads during active puzzle solving.
- **FR-025**: System MUST detect input cadence <200ms and flag potential automated bot interactions.

---

## 7. Key Entities & Domain Models

- **SudokuCell**: Represents one of 81 board units. Holds `index` (0..80), `row`, `col`, `box`, `correct_val`, `current_val`, `is_clue` (bool), `notes` (array of ints), `is_highlighted` (bool), `is_error` (bool).
- **SudokuBoard**: Aggregate of 81 `SudokuCell` objects, `difficulty_ser`, `seed_string`, and completion status.
- **PlayerProfile**: Represents user identity, `player_level`, `coins`, `campaign_stars`, `daily_streak`, and `high_score`.
- **CampaignLevel**: Definition for levels 1 to 100, including `level_id`, `zone_name`, `ser_rating`, `clue_count`, `unlock_status`, and `best_records`.
- **ThemePalette**: Holds `theme_id`, `name`, `primary_accent` (Color), `secondary_glow` (Color), and `is_dark`.

---

## 8. Success Criteria *(mandatory)*

- **SC-001**: 9x9 board generates with a guaranteed unique solution in under 350ms on mobile hardware without dropping UI frames.
- **SC-002**: UI renders consistently at 60 FPS minimum (120 FPS on supported high-refresh screens) with under 15 draw calls for UI elements.
- **SC-003**: Theme transitions complete across all shaders and UI panels in under 200ms with zero visual artifacts.
- **SC-004**: Cold app launch to playable Splash Screen occurs in under 1.2 seconds.
- **SC-005**: 100% of game moves, scores, and timer state are preserved and recoverable after sudden app termination.
- **SC-006**: Board layout maintains strict 1:1 square geometry across 16:9, 19.5:9, and 20:9 mobile aspect ratios without clipping controls.
- **SC-007**: Zero advertisements trigger during active puzzle solving.
- **SC-008**: First-time placement test enables advanced players to skip up to 49 levels in under 6 minutes.

---

## 9. Assumptions

- Target platform is mobile Android (Target SDK 34/35+), with PC desktop serving as playtest and inspection harness.
- Godot 4.x Mobile or Compatibility renderer is utilized for maximum device reach and battery efficiency.
- Godot SQLite GDExtension plugin handles database transactions; fallback JSON persistence contract is maintained if GDExtension is unavailable during desktop testing.
- Multiplayer PvP utilizes lightweight REST polling/handshakes over Firebase Realtime DB, requiring zero continuous server hosting cost.
- Touch emulation from mouse (`emulate_touch_from_mouse = true`) is enabled for seamless pair-programming inspection.
