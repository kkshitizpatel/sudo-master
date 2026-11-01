# Godot 4 Mobile Sudoku — Master Acceptance & Quality Assurance Checklist
**Version**: 1.0.0 (Dark Glassmorphism & Aurora Ambient Glow Edition)  
**Spec Reference**: [SPECIFICATION.md](SPECIFICATION.md) | [specs/001-mobile-sudoku-core/spec.md](specs/001-mobile-sudoku-core/spec.md)  
**Plan Reference**: [PLAN.md](PLAN.md) | [specs/001-mobile-sudoku-core/plan.md](specs/001-mobile-sudoku-core/plan.md)  
**Status**: 100% Passed Quality Gate  

---

## 1. Foundation & Engine Setup Checklist

- [x] **CHK001** - Are all 4 Autoload Singletons (`GameManager.gd`, `SudokuEngine.gd`, `ThemeManager.gd`, `SignalBus.gd` + `DatabaseManager.gd`) verified to initialize without script errors on boot? `[Spec §4.1, Plan §1.1]`
- [x] **CHK002** - Are SQLite database tables (`player_progress`, `campaign_levels`, `active_match_save`, `daily_challenges`, `favorites`) verified to generate correctly in `user://sudoku.db` with transparent fallback? `[Spec §4.2, Plan §1.3]`
- [x] **CHK003** - Are display settings locked to 1080x1920 base, `window/stretch/mode = 'canvas_items'`, `window/stretch/aspect = 'expand'`, and portrait orientation lock verified? `[Spec §IV, Plan §1.2]`
- [x] **CHK004** - Does the root UI layout container dynamically apply safe area margins using `DisplayServer.get_display_safe_area()` for camera cutouts and navigation bars? `[Spec §IV, FR-021]`
- [x] **CHK005** - Is mouse touch emulation (`emulate_touch_from_mouse = true`) verified to allow desktop F5/F6 inspection matching mobile behavior? `[Spec §9, Plan §2]`

---

## 2. Visual & Dark Glassmorphism Quality Gates

- [x] **CHK006** - Is the real-time frosted glass backdrop blur canvas shader (`glass_blur.gdshader`) verified to render smoothly without mobile fill-rate lag? `[Spec §3.3, Plan §2]`
- [x] **CHK007** - Do all cards, panels, and modal containers strictly conform to `StyleBoxFlat` frosted glass tokens (16px corner radius, translucent background `rgba(15, 23, 42, 0.72)`, 1px luminous white border `rgba(255, 255, 255, 0.12)`)? `[Spec §3.1, Constitution §III]`
- [x] **CHK008** - Does theme switching live-update primary accent and secondary ambient aurora glow across shaders and UI borders in under 0.2s? `[Spec §3.2, SC-003]`
- [x] **CHK009** - Are high-contrast legibility criteria verified across all 17 dual-tone themes, including pure AMOLED pitch black mode and light-accent modes? `[Spec §3.2, Plan §2]`
- [x] **CHK010** - Does the background Aurora shader (`aurora_glow.gdshader`) display organic floating color blobs with 35 subtle cosmic floating particles without visual stutter? `[Spec §3.3, Plan §2]`

---

## 3. Frame-by-Frame Acceptance Criteria (Frames 1 to 8)

- [x] **CHK011** - **Frame 1 (Splash Screen)**: Does progress bar interpolate smoothly from 0% to 100% via tween (~1.5s) and route first-time users to Frame 2 and returning users to Frame 5? `[Spec §2 (Frame 1), Plan §2]`
- [x] **CHK012** - **Frame 2 (Welcome / Onboarding)**: Is the "ACCEPT & CONTINUE" button disabled and dim until the Terms & Privacy checkbox is explicitly checked, saving `has_accepted_terms = true`? `[Spec §2 (Frame 2), Plan §2]`
- [x] **CHK013** - **Frame 3 (Claim Your Level)**: Do the 4 skill tiers (Level 1 Instant, Level 15 Novice, Level 30 Intermediate, Level 50 Pro) load pre-baked calibration boards and correctly unlock preceding levels with 2 stars upon passing? `[Spec §2 (Frame 3), FR-019, FR-020]`
- [x] **CHK014** - **Frame 3 (Bypass)**: Does tapping Tier 1 (Level 1) or failing calibration gracefully route to Frame 5 with Level 1 starting point? `[Spec §2 (Frame 3)]`
- [x] **CHK015** - **Frame 4 (Select Game Mode)**: Does the profile header sync user level, coins, and streak, and do all 4 mode cards (Classic, Campaign, Battle, Daily) route to their respective setups? `[Spec §2 (Frame 4)]`
- [x] **CHK016** - **Frame 4 (Daily Challenge)**: Is today's puzzle generated deterministically from the current date seed (`YYYY-MM-DD`) with 7-day flame streak counter integration? `[Spec §2 (Frame 4), Story 5]`
- [x] **CHK017** - **Frame 5 (Home / Main Menu)**: Does the center Sudoku matrix float with a gentle sine-wave hover animation, and does "CONTINUE GAME" activate only when an active match save exists in SQLite? `[Spec §2 (Frame 5)]`
- [x] **CHK018** - **Frame 5 (Bottom Dock)**: Does the floating translucent glass dock support active glow indicator switching across all 5 navigation tabs? `[Spec §2 (Frame 5)]`
- [x] **CHK019** - **Frame 6 (Top Bar Controls)**: Do the Back button (auto-save match), Share button, Favorite bookmarking button, Theme palette trigger, and Settings trigger function properly? `[Spec §2 (Frame 6)]`
- [x] **CHK020** - **Frame 6 (Gameplay Stats)**: Does the Pumpkin Score pill update (+50 per correct fill, combo multipliers), and does the digital timer drive from monotonic CPU ticks (`Time.get_ticks_msec()`)? `[Spec §2 (Frame 6), FR-004, FR-015]`
- [x] **CHK021** - **Frame 6 (Board Clamping & Highlights)**: Is the 9x9 board locked in a 1:1 square `AspectRatioContainer`, and does selecting a cell trigger luminous highlights for row, col, box, and identical digits? `[Spec §2 (Frame 6), FR-001]`
- [x] **CHK022** - **Frame 6 (Action Bar Tools)**: Do all 5 action tools (Counts toggle, Undo history stack, Erase tool, Notes candidate toggle, Smart Hint elimination) execute as specified? `[Spec §2 (Frame 6), FR-006, FR-007, FR-008, FR-009]`
- [x] **CHK023** - **Frame 6 (Number Pad Capsule Tray)**: Does the bottom 1-9 floating glass tray display live remaining digit counts beneath each tile, auto-shrinking and dimming once 9 instances are completed? `[Spec §2 (Frame 6), FR-010]`
- [x] **CHK024** - **Frame 7 (Theme Palette Modal)**: Do all 17 dual-tone swatches display active 3D checkmark selection, live-transition themes, and provide 3-step font scaling ('A Small' | 'A Medium' | 'A Large')? `[Spec §2 (Frame 7), FR-013]`
- [x] **CHK025** - **Frame 8 (Settings Modal)**: Do SFX and BGM sliders modulate `AudioServer` bus levels, does the haptic toggle control `Input.vibrate_handheld()`, and does Cloud Save status display sync timestamps? `[Spec §2 (Frame 8), FR-017, FR-018]`

---

## 4. Game Logic, Offline Edge Cases & Clarifications

- [x] **CHK026** - Does entering a correct number automatically remove that candidate digit from pencil notes in the affected row, column, and 3x3 box when `auto_remove_notes` is enabled (default ON)? `[Clarification #4, Spec §5.1, FR-008]`
- [x] **CHK027** - Upon committing the 3rd mistake, does the board immediately lock and present the Game Over Revive Modal with both Rewarded Ad (online) and 50-Coin expenditure (offline fallback) options? `[Clarification #1, Spec §5.1, FR-023]`
- [x] **CHK028** - In 1v1 Battle Mode, does committing a 3rd mistake trigger an instant knockout defeat, immediately awarding victory to the opponent? `[Clarification #3, Spec §5.4, Story 6]`
- [x] **CHK029** - Do all 100 Campaign Mode levels unlock sequentially upon clearing the prior level with any star rating (1–3), with zero ad paywalls or star locks? `[Clarification #2, Spec §Story 3, FR-003]`
- [x] **CHK030** - Does each new puzzle initialize with 3 free Smart Hints, and does reaching 0 allow earning +1 hint via Rewarded Ad or 20 coins? `[Clarification #5, Spec §FR-009]`
- [x] **CHK031** - Does algorithmic puzzle generation in `SudokuGenerator.gd` run on `WorkerThreadPool`, generating valid single-solution puzzles in <350ms without UI hitching? `[Spec §FR-002, SC-001]`
- [x] **CHK032** - Does closing the application mid-game auto-save state, enabling cold-restart resumption of exact 81 cells, notes, timer, and score in <150ms? `[Spec §5.3, SC-005]`
- [x] **CHK033** - Does backgrounding the app (`NOTIFICATION_APPLICATION_PAUSED`) freeze the monotonic timer and present a paused resume overlay upon return? `[Spec §5.2]`

---

## 5. Mobile Polish & Standards Compliance

- [x] **CHK034** - Does the codebase strictly comply with `awesome-gamedev-agent-skills` Godot 4 standards: `godot-ui-control` (Control anchors & AspectRatio), `godot-shaders` (screen texture & uniform interpolation), `godot-animation` (`create_tween()` method chains)? `[Plan §4, Constitution §I]`
- [x] **CHK035** - Are tactile haptics calibrated to non-blocking 30ms subtle ticks on cell/button selection and 150ms rumble on mistakes? `[Spec §FR-018, Constitution §V]`
- [x] **CHK036** - Does the rendering pipeline maintain locked 60 FPS minimum / 120 FPS high-refresh rate with <15 UI draw calls? `[Spec §SC-002]`
- [x] **CHK037** - Does `export_presets.cfg` validate against Target SDK 34/35+ for Google Play release bundling? `[Plan §2 (Phase 7)]`
- [x] **CHK038** - Are zero advertisements triggered during active puzzle solving, with ads restricted strictly to match transitions or user-initiated revives? `[Spec §FR-024, SC-007, Constitution §Technical Stack]`
