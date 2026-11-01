# Acceptance & Quality Assurance Checklist: Godot 4 Mobile Sudoku

**Feature**: `001-mobile-sudoku-core`  
**Purpose**: Rigorous testable verification criteria across foundational architecture, visual design system, frame flows, game logic, and mobile standards.  
**Created**: 2026-11-01  
**Spec Reference**: [SPECIFICATION.md](../../../SPECIFICATION.md) | [specs/001-mobile-sudoku-core/spec.md](../spec.md)  
**Plan Reference**: [PLAN.md](../../../PLAN.md) | [specs/001-mobile-sudoku-core/plan.md](../plan.md)  

**Review Ownership**: Reviewer-owned quality assurance artifact. Mark `[x]` only when the specific acceptance criterion is verified during implementation testing (via Godot F5/F6 or headless CLI).  

---

## 1. Foundation & Engine Setup Checklist

- [ ] CHK001 - Are all 4 Autoload Singletons (`GameManager.gd`, `SudokuEngine.gd`, `ThemeManager.gd`, `SignalBus.gd`) verified to initialize without script errors on boot? `[Spec §4.1, Plan §1.1]`
- [ ] CHK002 - Are SQLite database tables (`player_progress`, `campaign_levels`, `active_match_save`, `daily_challenges`, `favorites`) verified to generate correctly in `user://sudoku.db` with transparent fallback? `[Spec §4.2, Plan §1.3]`
- [ ] CHK003 - Are display settings locked to 1080x1920 base, `window/stretch/mode = 'canvas_items'`, `window/stretch/aspect = 'expand'`, and portrait orientation lock verified? `[Spec §IV, Plan §1.2]`
- [ ] CHK004 - Does the root UI layout container dynamically apply safe area margins using `DisplayServer.get_display_safe_area()` for camera cutouts and navigation bars? `[Spec §IV, FR-021]`
- [ ] CHK005 - Is mouse touch emulation (`emulate_touch_from_mouse = true`) verified to allow desktop F5/F6 inspection matching mobile behavior? `[Spec §9, Plan §2]`

---

## 2. Visual & Dark Glassmorphism Quality Gates

- [ ] CHK006 - Is the real-time frosted glass backdrop blur canvas shader (`glass_blur.gdshader`) verified to render smoothly without mobile fill-rate lag? `[Spec §3.3, Plan §2]`
- [ ] CHK007 - Do all cards, panels, and modal containers strictly conform to `StyleBoxFlat` frosted glass tokens (16px corner radius, translucent background `rgba(15, 23, 42, 0.72)`, 1px luminous white border `rgba(255, 255, 255, 0.12)`)? `[Spec §3.1, Constitution §III]`
- [ ] CHK008 - Does theme switching live-update primary accent and secondary ambient aurora glow across shaders and UI borders in under 0.2s? `[Spec §3.2, SC-003]`
- [ ] CHK009 - Are high-contrast legibility criteria verified across all 17 dual-tone themes, including pure AMOLED pitch black mode and light-accent modes? `[Spec §3.2, Plan §2]`
- [ ] CHK010 - Does the background Aurora shader (`aurora_glow.gdshader`) display organic floating color blobs with 35 subtle cosmic floating particles without visual stutter? `[Spec §3.3, Plan §2]`

---

## 3. Frame-by-Frame Acceptance Criteria (Frames 1 to 8)

- [ ] CHK011 - **Frame 1 (Splash Screen)**: Does progress bar interpolate smoothly from 0% to 100% via tween (~1.5s) and route first-time users to Frame 2 and returning users to Frame 5? `[Spec §2 (Frame 1), Plan §2]`
- [ ] CHK012 - **Frame 2 (Welcome / Onboarding)**: Is the "ACCEPT & CONTINUE" button disabled and dim until the Terms & Privacy checkbox is explicitly checked, saving `has_accepted_terms = true`? `[Spec §2 (Frame 2), Plan §2]`
- [ ] CHK013 - **Frame 3 (Claim Your Level)**: Do the 4 skill tiers (Level 1 Instant, Level 15 Novice, Level 30 Intermediate, Level 50 Pro) load pre-baked calibration boards and correctly unlock preceding levels with 2 stars upon passing? `[Spec §2 (Frame 3), FR-019, FR-020]`
- [ ] CHK014 - **Frame 3 (Bypass)**: Does tapping Tier 1 (Level 1) or failing calibration gracefully route to Frame 5 with Level 1 starting point? `[Spec §2 (Frame 3)]`
- [ ] CHK015 - **Frame 4 (Select Game Mode)**: Does the profile header sync user level, coins, and streak, and do all 4 mode cards (Classic, Campaign, Battle, Daily) route to their respective setups? `[Spec §2 (Frame 4)]`
- [ ] CHK016 - **Frame 4 (Daily Challenge)**: Is today's puzzle generated deterministically from the current date seed (`YYYY-MM-DD`) with 7-day flame streak counter integration? `[Spec §2 (Frame 4), Story 5]`
- [ ] CHK017 - **Frame 5 (Home / Main Menu)**: Does the center Sudoku matrix float with a gentle sine-wave hover animation, and does "CONTINUE GAME" activate only when an active match save exists in SQLite? `[Spec §2 (Frame 5)]`
- [ ] CHK018 - **Frame 5 (Bottom Dock)**: Does the floating translucent glass dock support active glow indicator switching across all 5 navigation tabs? `[Spec §2 (Frame 5)]`
- [ ] CHK019 - **Frame 6 (Top Bar Controls)**: Do the Back button (auto-save match), Share button, Favorite bookmarking button, Theme palette trigger, and Settings trigger function properly? `[Spec §2 (Frame 6)]`
- [ ] CHK020 - **Frame 6 (Gameplay Stats)**: Does the Pumpkin Score pill update (+50 per correct fill, combo multipliers), and does the digital timer drive from monotonic CPU ticks (`Time.get_ticks_msec()`)? `[Spec §2 (Frame 6), FR-004, FR-015]`
- [ ] CHK021 - **Frame 6 (Board Clamping & Highlights)**: Is the 9x9 board locked in a 1:1 square `AspectRatioContainer`, and does selecting a cell trigger luminous highlights for row, col, box, and identical digits? `[Spec §2 (Frame 6), FR-001]`
- [ ] CHK022 - **Frame 6 (Action Bar Tools)**: Do all 5 action tools (Counts toggle, Undo history stack, Erase tool, Notes candidate toggle, Smart Hint elimination) execute as specified? `[Spec §2 (Frame 6), FR-006, FR-007, FR-008, FR-009]`
- [ ] CHK023 - **Frame 6 (Number Pad Capsule Tray)**: Does the bottom 1-9 floating glass tray display live remaining digit counts beneath each tile, auto-shrinking and dimming once 9 instances are completed? `[Spec §2 (Frame 6), FR-010]`
- [ ] CHK024 - **Frame 7 (Theme Palette Modal)**: Do all 17 dual-tone swatches display active 3D checkmark selection, live-transition themes, and provide 3-step font scaling ('A Small' | 'A Medium' | 'A Large')? `[Spec §2 (Frame 7), FR-013]`
- [ ] CHK025 - **Frame 8 (Settings Modal)**: Do SFX and BGM sliders modulate `AudioServer` bus levels, does the haptic toggle control `Input.vibrate_handheld()`, and does Cloud Save status display sync timestamps? `[Spec §2 (Frame 8), FR-017, FR-018]`

---

## 4. Game Logic, Offline Edge Cases & Clarifications

- [ ] CHK026 - Does entering a correct number automatically remove that candidate digit from pencil notes in the affected row, column, and 3x3 box when `auto_remove_notes` is enabled (default ON)? `[Clarification #4, Spec §5.1, FR-008]`
- [ ] CHK027 - Upon committing the 3rd mistake, does the board immediately lock and present the Game Over Revive Modal with both Rewarded Ad (online) and 50-Coin expenditure (offline fallback) options? `[Clarification #1, Spec §5.1, FR-023]`
- [ ] CHK028 - In 1v1 Battle Mode, does committing a 3rd mistake trigger an instant knockout defeat, immediately awarding victory to the opponent? `[Clarification #3, Spec §5.4, Story 6]`
- [ ] CHK029 - Do all 100 Campaign Mode levels unlock sequentially upon clearing the prior level with any star rating (1–3), with zero ad paywalls or star locks? `[Clarification #2, Spec §Story 3, FR-003]`
- [ ] CHK030 - Does each new puzzle initialize with 3 free Smart Hints, and does reaching 0 allow earning +1 hint via Rewarded Ad or 20 coins? `[Clarification #5, Spec §FR-009]`
- [ ] CHK031 - Does algorithmic puzzle generation in `SudokuGenerator.gd` run on `WorkerThreadPool`, generating valid single-solution puzzles in <350ms without UI hitching? `[Spec §FR-002, SC-001]`
- [ ] CHK032 - Does closing the application mid-game auto-save state, enabling cold-restart resumption of exact 81 cells, notes, timer, and score in <150ms? `[Spec §5.3, SC-005]`
- [ ] CHK033 - Does backgrounding the app (`NOTIFICATION_APPLICATION_PAUSED`) freeze the monotonic timer and present a paused resume overlay upon return? `[Spec §5.2]`

---

## 5. Mobile Polish & Standards Compliance

- [ ] CHK034 - Does the codebase strictly comply with `awesome-gamedev-agent-skills` Godot 4 standards: `godot-ui-control` (Control anchors & AspectRatio), `godot-shaders` (screen texture & uniform interpolation), `godot-animation` (`create_tween()` method chains)? `[Plan §4, Constitution §I]`
- [ ] CHK035 - Are tactile haptics calibrated to non-blocking 30ms subtle ticks on cell/button selection and 150ms rumble on mistakes? `[Spec §FR-018, Constitution §V]`
- [ ] CHK036 - Does the rendering pipeline maintain locked 60 FPS minimum / 120 FPS high-refresh rate with <15 UI draw calls? `[Spec §SC-002]`
- [ ] CHK037 - Does `export_presets.cfg` validate against Target SDK 34/35+ for Google Play release bundling? `[Plan §2 (Phase 7)]`
- [ ] CHK038 - Are zero advertisements triggered during active puzzle solving, with ads restricted strictly to match transitions or user-initiated revives? `[Spec §FR-024, SC-007, Constitution §Technical Stack]`
