<!--
Sync Impact Report:
- Version change: Uninitialized template -> v1.0.0
- Ratification Date: 2026-11-01
- Principles established:
  1. I. Antigravity-First Autonomous Architecture (Zero-Code Developer Authority)
  2. II. Decoupled Layered Architecture (Headless Math vs Presentation)
  3. III. Dark Glassmorphism & Aurora Design System (Anti-Claymorphism Mandate)
  4. IV. Mobile-First 9:16 Portrait Layout & Safe Area Integrity
  5. V. Fair Play, Monotonic Timing & Subtle Haptic Polish
  6. VI. Protocol Tag Safety Guardrails & Operational Meta-Rules
- Added Sections: Technical Stack & Persistence Standards, Quality Gates & Playtest Workflow
- Removed Sections: None
- Follow-up TODOs: None
-->

# Godot 4 Mobile Sudoku Constitution
<!-- Dark Glassmorphism & Aurora Ambient Glow Edition (v4.1) | Antigravity-First Autonomous Codebase -->

## Core Principles

### I. Antigravity-First Autonomous Architecture (Zero-Code Developer Authority)
100% of application code, scene hierarchies (`.tscn`), scripts (`.gd`), shaders (`.gdshader`), audio configurations, and engine settings (`project.godot`) MUST be authored, updated, and refactored by the Antigravity Agent.
- The human developer is strictly non-coding: Godot Engine serves exclusively as a Visual Inspector, Scene Player (F5/F6 test harness), and release export runner.
- Zero-Code Feedback Loop: Any visual, structural, or logical refinement requested in chat MUST be implemented directly on the filesystem by Antigravity, triggering Godot's instant hot-reload.

### II. Decoupled Layered Architecture (Headless Math vs Presentation)
Game logic and mathematical computations MUST remain completely isolated from UI presentation nodes.
- Layer 1 (Rules, dynamic backtracking 9x9 board generation, unique solution validation, and SER difficulty rating) MUST operate headless.
- Algorithmic puzzle generation MUST run asynchronously via `WorkerThreadPool` to eliminate main-thread stutter and maintain locked 60/120 FPS.
- UI components communicate with game state strictly through Autoload singletons (`GameManager`, `ThemeManager`, `SudokuEngine`) and typed Godot Signals.

### III. Dark Glassmorphism & Aurora Design System (Anti-Claymorphism Mandate)
The visual identity MUST adhere strictly to modern Dark Glassmorphism and Aurora Ambient Glow aesthetics.
- Chunky, bubbly claymorphic UI elements are permanently prohibited.
- All cards, modal sheets, and tool docks MUST utilize translucent frosted glass (`StyleBoxFlat` with 16px corner radius, 1px luminous white border `rgba(255, 255, 255, 0.12)`, and background `rgba(15, 23, 42, 0.72)`).
- Visual enhancements MUST utilize hardware-efficient 2D canvas shaders (`glass_blur.gdshader`, `aurora_glow.gdshader`) and the Dual-Tone Accent Swatch Engine (Primary Accent + Secondary Ambient Aura).

### IV. Mobile-First 9:16 Portrait Layout & Safe Area Integrity
The display viewport MUST be locked to 1080x1920 (9:16 Portrait) with `window/stretch/mode = 'canvas_items'` and `window/stretch/aspect = 'expand'`.
- The 9x9 puzzle grid MUST reside within an `AspectRatioContainer` (strict 1:1 ratio) to guarantee that numbers and controls never truncate across diverse mobile screen ratios.
- Cutout camera notches and system navigation bars MUST dynamically offset root UI containers using `DisplayServer.get_display_safe_area()`.

### V. Fair Play, Monotonic Timing & Subtle Haptic Polish
User progress, timer fidelity, and tactical interaction MUST be reliably governed:
- Game timers MUST be driven by CPU monotonic counters (`Time.get_ticks_msec()`), prohibiting manipulation via OS clock modifications.
- Anti-cheat rules (bot detection via <200ms tap cadence checks and move-history checksum validation) MUST be enforced before recording high scores or level clears.
- Tactile feedback MUST use non-blocking haptic pulses via `Input.vibrate_handheld()` (30ms subtle tick for cell/number selection, 150ms rumble for illegal entries).

### VI. Protocol Tag Safety Guardrails & Operational Meta-Rules
Development instructions MUST obey prompt protocol tags (`#exact`, `#logic`, `#change`, `#no_change`, `#lock`, `#unlock`, `#working`, `#not_working`, `#problem`, `#stop`, `#skip`, `#visual`, `#drag`, `#size`, `#add`, `#remove`, `#online`, `#offline`).
- Meta-Rule: If any incoming prompt or automated modification threatens to violate a `#lock` directive or destabilize established architecture, Antigravity MUST immediately HALT, alert the user, and await explicit approval.

## Technical Stack & Persistence Standards

- **Engine & Language**: Godot Engine 4.x (Mobile / GL Compatibility Renderer), GDScript 2.0 with strict static typing adhering to `awesome-gamedev-agent-skills` Godot guidelines.
- **Local Persistence**:
  - `user://sudoku.db` (Godot SQLite Plugin): Stores match state auto-save, campaign progression (Levels 1 to 100), placement ratings, streak calendar records, and bookmarked favorites.
  - `user://settings.cfg` (ConfigFile): Stores user theme selection, audio bus levels, haptics configuration, and onboarding flags (`has_accepted_terms`, `has_completed_placement`).
- **Cloud & Network Services**:
  - 1v1 PvP Battle Mode: Firebase Realtime DB synchronized seed exchange via lightweight GDScript `HTTPRequest` REST calls.
  - Cloud Backup: Google Play Games Services Cloud Save integration.
- **Monetization Safeguards**:
  - Active puzzle solving MUST NEVER be interrupted by ads.
  - Ad placements (Poing Studios AdMob) are strictly restricted to match transitions (smart interstitials) or explicit user opt-ins (rewarded video for revives, extra hints, or placement skips).

## Quality Gates & Playtest Workflow

- **Algorithmic Correctness**: Backtracking generator MUST guarantee single-solution validity across all SER difficulty scales (Warmup 1.0–1.4 through Inhuman 9.0–11.5+).
- **Playtest Validation**: Development builds MUST maintain desktop touch emulation (`emulate_touch_from_mouse = true`) to enable instant visual inspection via Godot F5/F6.
- **Frame Rate Target**: 60 FPS minimum / 120 FPS high-refresh rate on target mobile devices with battery-optimized rendering.

## Governance

This Constitution supersedes all informal coding suggestions, conventions, and ad-hoc practices.
- Every architecture change, scene file layout, or GDScript implementation MUST strictly conform to these principles.
- Amendments require a documented pull-request or specification revision with a corresponding version increment:
  - **MAJOR**: Structural changes altering the autonomous Antigravity authority model or core engine choice.
  - **MINOR**: Addition of new game modes, monetization partners, or major architectural layers.
  - **PATCH**: Non-breaking refinements, clarification of prompt tags, or performance optimizations.

**Version**: 1.0.0 | **Ratified**: 2026-11-01 | **Last Amended**: 2026-11-01
