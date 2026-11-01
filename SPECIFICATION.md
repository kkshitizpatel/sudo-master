# Godot 4 Mobile Sudoku — Master Functional & Technical Specification
**Version**: 1.0.0 (Dark Glassmorphism & Aurora Ambient Glow Edition)  
**Spec Link**: [specs/001-mobile-sudoku-core/spec.md](file:///c:/Users/kkshi/Downloads/godot%20sudoku/specs/001-mobile-sudoku-core/spec.md)  
**Status**: Approved Baseline for Planning & Implementation

---

## 1. Executive Summary & Architecture Overview
This specification defines the functional, technical, and visual requirements for **Godot 4 Mobile Sudoku (Dark Glassmorphism & Aurora Edition)**. The game is architected around the **Antigravity-First Autonomous Codebase** workflow, where 100% of code, scenes, and shaders are agent-generated, and Godot 4 serves as the Visual Inspector and test runner.

---

## 2. Frame Specifications (Frames 1 to 8)

### Frame 1: Splash Screen (`01_splash_screen_jk_games.tscn`)
- **Preconditions**: Display settings loaded (1080x1920 portrait), OpenGL/Vulkan pipeline ready.
- **Postconditions**: SQLite DB verified (`sudoku.db`), `settings.cfg` loaded into `GameManager` and `ThemeManager`, shaders pre-warmed.
- **Input Triggers & Signals**:
  - `_ready()` ➔ Initiates asset pre-caching and progress bar tween (0.0 to 1.0).
  - `splash_completed` ➔ Fired when progress hits 100%. If `has_accepted_terms == false`, transitions to Frame 2; else transitions to Frame 5.
- **States**: `STATE_INITIALIZING`, `STATE_PRECACHING`, `STATE_COMPLETED`.

### Frame 2: Welcome & Onboarding (`02_welcome_onboarding_screen.tscn`)
- **Preconditions**: Fresh install with `has_accepted_terms == false`.
- **Postconditions**: `has_accepted_terms = true` saved in `settings.cfg`.
- **Input Triggers & Signals**:
  - `CheckBox.toggled(is_checked)` ➔ `terms_toggled(is_checked)`; enables/disables `BtnAccept` with primary accent border glow.
  - `BtnAccept.pressed()` ➔ `onboarding_accepted`; transitions to Frame 3.
- **States**: `STATE_IDLE_UNCHECKED`, `STATE_READY_CHECKED`.

### Frame 3: Claim Your Level (`03_claim_your_level_screen.tscn`)
- **Preconditions**: Terms accepted, first-time onboarding or manual trigger from Settings.
- **Postconditions**: `has_completed_placement = true` saved; target levels unlocked in SQLite.
- **Input Triggers & Signals**:
  - `TierCard[1..4].tap` ➔ `tier_selected(tier_index)`.
  - `calibration_passed(target_level)` ➔ Unlocks prior levels with 2 stars, triggers celebration wave, transitions to Frame 5.
  - `calibration_failed` ➔ Encouraging dialogue, resets to Level 1, routes to Frame 5.
  - Tier 1 (Level 1) tap ➔ Bypasses test, immediately enters Level 1.
- **States**: `STATE_TIER_SELECT`, `STATE_CALIBRATING`.

### Frame 4: Select Game Mode (`04_select_game_mode_screen.tscn`)
- **Preconditions**: Profile data, coins, and streak loaded.
- **Postconditions**: Selected game mode passed to `GameManager`.
- **Input Triggers & Signals**:
  - `BtnBack.tap` ➔ Returns to Frame 5.
  - `ClassicCard.tap` ➔ Sub-popup for Easy/Med/Hard segmented pill selector ➔ Starts game.
  - `CampaignCard.tap` ➔ Loads current uncompleted campaign level ➔ Starts game.
  - `BattleCard.tap` ➔ Matchmaking handshake ➔ Synchronized seed ➔ Starts game.
  - `DailyCard.tap` ➔ Today's date seed `YYYY-MM-DD` ➔ Starts game.
- **States**: `STATE_DEFAULT`, `STATE_DIFFICULTY_POPUP`.

### Frame 5: Home / Main Menu (`05_home_main_menu_screen.tscn`)
- **Preconditions**: DB queried for saved in-progress match (`has_saved_game`).
- **Postconditions**: None (navigation hub).
- **Input Triggers & Signals**:
  - `BtnSettings.tap` ➔ Opens Frame 7/8 modal with slide-up tween.
  - `BtnContinue.tap` ➔ Restores saved board state ➔ Enters Frame 6.
  - `BtnNewGame.tap` ➔ Opens Frame 4 (Select Mode).
  - `DockTab[0..4].tap` ➔ Switches views (Home, Modes, Leaderboard, Stats, Profile).
- **States**: `STATE_IDLE`, `STATE_MODAL_ACTIVE`.

### Frame 6: Sudoku Gameplay Board (`06_sudoku_gameplay_board.tscn`)
- **Preconditions**: `SudokuEngine` loaded with board solution, clues mask, and monotonic timer reference.
- **Postconditions**: Auto-save record written on every move; statistics saved on win/loss.
- **Input Triggers & Signals**:
  - Top Bar: `BtnBack` (saves & exits), `BtnShare` (puzzle link), `BtnFavorite` (bookmarks in DB), `BtnTheme` (opens Frame 7 overlay), `BtnSettings` (opens Frame 8 overlay & pauses timer).
  - Grid: `Cell[r,c].tap` ➔ `cell_selected(r,c)`; highlights row/col/box and identical digits.
  - Action Bar: `BtnCounts` (toggles remaining counts), `BtnUndo` (pops move stack), `BtnErase` (clears value/notes), `BtnNotes` (toggles pencil mode; correct fills auto-clear affected notes), `BtnHint` (smart hint elimination; 3 free per puzzle, +1 via Ad or 20 coins).
  - Pad: `NumTile[1..9].tap` ➔ Fills cell (correct: +50 score; error: red shake + mistake + rumble).
- **States**: `STATE_PLAYING`, `STATE_PAUSED`, `STATE_GAME_OVER`, `STATE_VICTORY`.

### Frame 7: Theme Palette Modal (`07_theme_palette.tscn`)
- **Preconditions**: Theme list loaded.
- **Postconditions**: Theme ID saved in `settings.cfg`.
- **Input Triggers & Signals**:
  - `CloseButton.tap` ➔ Closes modal.
  - `Swatch[id].tap` ➔ Sets active theme ➔ Live transitions shaders & borders in <0.2s.
  - `FontScalePill.tap` ➔ Adjusts grid digit scale (Small/Medium/Large).
- **States**: `STATE_MODAL`.

### Frame 8: Settings & Audio Palette Modal (`08_settings_palette.tscn`)
- **Preconditions**: Audio bus levels and haptic flag loaded.
- **Postconditions**: Volume and haptic preferences persisted.
- **Input Triggers & Signals**:
  - `SliderSFX`, `SliderBGM` ➔ Changes audio bus volume.
  - `ToggleHaptics` ➔ Toggles `GameManager.haptics_enabled`.
  - `BtnBackupCloud` ➔ Triggers Google Play Games Cloud Save.
- **States**: `STATE_MODAL`.

---

## 3. UI & Design System Tokens (Dark Glassmorphism & Aurora)

### 3.1 StyleBoxFlat Component Tokens
- **Frosted Panels**: `bg_color = rgba(15, 23, 42, 0.72)`, `corner_radius = 16px`, `border_color = rgba(255, 255, 255, 0.12)`, `border_width = 1px`.
- **Pills**: `corner_radius = 999px`.
- **Selected Cell**: `border_color = Primary Accent (0.95 alpha)`, `bg_color = Primary Accent (0.28 alpha)`.
- **Matching Row/Col/Box**: `bg_color = rgba(255, 255, 255, 0.06)`.
- **Identical Digits**: `bg_color = Primary Accent (0.18 alpha)`.

### 3.2 17 Dual-Tone Accent Palettes
1. **Aero**: `#38BDF8` (Sky Cyan) + `#4338CA` (Deep Indigo)
2. **Neon Emerald**: `#10B981` (Mint) + `#065F46` (Deep Pine)
3. **Mint Teal**: `#14B8A6` (Teal) + `#0F766E` (Deep Teal)
4. **Forest Moss**: `#22C55E` (Vivid Leaf) + `#14532D` (Dark Moss)
5. **Crimson Wine**: `#F43F5E` (Rose Crimson) + `#881337` (Burgundy)
6. **Warm Mocha**: `#D97706` (Bronze) + `#451A03` (Espresso)
7. **Neon Magenta**: `#EC4899` (Hot Magenta) + `#701A75` (Soft Violet)
8. **Charcoal Slate**: `#94A3B8` (Silver) + `#334155` (Deep Slate)
9. **Pure AMOLED**: `#F8FAFC` (Pure White) + `#1E293B` (Pitch Void, 100% Black canvas)
10. **Ice Cyan**: `#0284C7` (Sky Blue) + `#BAE6FD` (Ice Cyan)
11. **Soft Mint**: `#059669` (Emerald) + `#A7F3D0` (Soft Mint)
12. **Peach Orange**: `#EA580C` (Tangerine) + `#FED7AA` (Warm Peach)
13. **Lilac Violet**: `#7C3AED` (Royal Violet) + `#DDD6FE` (Lilac Dream)
14. **Coral Rose**: `#E11D48` (Coral Rose) + `#FECDD3` (Pale Pink)
15. **Buttercup Honey**: `#D97706` (Golden Honey) + `#FEF08A` (Buttercup)
16. **Pearl Slate**: `#334155` (Deep Slate) + `#E2E8F0` (Pearl Gray)
17. **Cyberpunk Neon**: `#06B6D4` (Electric Cyan) + `#D946EF` (Neon Fuchsia)

### 3.3 Shaders & Particles
- **`aurora_glow.gdshader`**: Dynamic uniforms `color_primary`, `color_secondary`, `speed = 0.2`, `intensity = 0.45`, `blur_factor = 4.0`.
- **`glass_blur.gdshader`**: Sample-based screen texture blur with specular surface gloss and 1px luminous border.
- **Particles (`GPUParticles2D`)**: 35 particles, 8.0s lifetime, box emission (1080x1920), upward drift `gravity = Vector2(0, -6)`.

---

## 4. Data & State Contracts

### 4.1 Autoload Contracts
- **`GameManager.gd`**:
  - `player_name`: String, `player_level`: int, `coins_count`: int, `high_score`: int, `daily_streak_count`: int
  - `has_accepted_terms`: bool, `has_completed_placement`: bool, `has_saved_game`: bool, `haptics_enabled`: bool
  - `current_game_mode`: int, `current_level_id`: int, `current_score`: int, `combo_multiplier`: float, `mistakes_count`: int (0..3), `hints_remaining`: int
  - `match_start_ticks`: int, `elapsed_seconds`: int, `is_game_paused`: bool
- **`SudokuEngine.gd`**:
  - `board_solution`: Array[int] (81), `initial_clues`: Array[int] (81), `current_board`: Array[int] (81), `candidate_notes`: Array[Array[int]] (81), `remaining_counts`: Dictionary (1..9)
  - `is_notes_mode`: bool, `is_digit_first_mode`: bool, `selected_cell_index`: int, `selected_digit_lock`: int
  - `move_history`: Array[Dictionary] (stack of moves for undo)
- **`ThemeManager.gd`**:
  - `current_theme_id`: String, `font_scale_factor`: float, `sync_with_os_dark_mode`: bool, `themes_catalog`: Dictionary

### 4.2 SQLite Database (`user://sudoku.db`)
- Tables:
  1. `player_progress`: ID, name, level, coins, daily_streak, last_daily_played, has_completed_placement.
  2. `campaign_levels`: level_id (1..100), zone_name, ser_rating, clues_count, is_unlocked (freely unlocked sequentially upon clearing previous level with any star rating), stars_earned, best_time, best_score.
  3. `active_match_save`: slot_id=1, game_mode, level_id, elapsed_seconds, mistakes_count, hints_used, score, combo, board_solution, initial_clues, current_board, candidate_notes, timestamp.
  4. `daily_challenges`: date_key (YYYY-MM-DD), is_completed, stars_earned, time_taken, score.
  5. `favorites`: puzzle_id, puzzle_seed, difficulty_name, date_favorited.

### 4.3 ConfigFile (`user://settings.cfg`)
- Sections: `[graphics]`, `[audio]`, `[gameplay]`, `[onboarding]`.

---

## 5. Edge Cases & Boundary Conditions
1. **3-Mistake Limit**: Pauses game immediately, disables grid interaction, opens Revive modal. Players can revive via online Rewarded Video Ad or spend 50 coins (offline fallback) to restore 1 life (`mistakes = 2`) and unpause. Restart restores 3 lives and resets board.
2. **Monotonic Timing Integrity**: Uses `Time.get_ticks_msec()` differential. On backgrounding (`NOTIFICATION_APPLICATION_PAUSED`), timer freezes and match auto-saves. On resume, paused modal is presented to prevent unfair countdown loss.
3. **Mid-Game Auto-Resume**: Every move and note change writes to `active_match_save`. Cold restart detects saved match, illuminates "CONTINUE GAME", and reconstitutes state in <150ms.
4. **PvP Desync / Network Drop**: Seed CRC32 checksum exchanged at start. 15-second grace period on disconnect, after which the remaining player receives a Default Victory.
5. **PvP Instant Knockout**: Accumulating 3 mistakes in 1v1 Battle Mode results in an instant knockout loss, immediately awarding the win to the opponent.
