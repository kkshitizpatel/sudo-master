# Research & Technical Decisions: Godot 4 Mobile Sudoku

**Feature**: `001-mobile-sudoku-core`  
**Status**: Completed Baseline  
**Date**: 2026-11-01  

---

## 1. Engine & Rendering Architecture

### Decision: Godot Engine 4.7.2 with Mobile / Compatibility Renderer
- **Decision**: Target Godot 4.7.2 using `rendering/renderer/rendering_method="mobile"` (with fallback to `gl_compatibility` for ultra-low-end devices).
- **Rationale**:
  - `mobile` (Vulkan Mobile) supports custom canvas shaders with optimal fill-rate efficiency on modern mobile GPUs.
  - Compatibility renderer provides a lightweight fallback ensuring 100% Android device coverage without driver fragmentation.
  - Built-in touch emulation (`input_devices/pointing/emulate_touch_from_mouse=true`) allows immediate desktop visual inspection (F5/F6) matching phone interaction.
- **Alternatives Considered**:
  - *Godot 3.5*: Rejected due to deprecated GDScript syntax, older shader pipelines, and impending engine EOL.
  - *Forward+ Renderer*: Rejected because high-end desktop shadow cascades and 3D clustered lighting are unnecessary for 2D glassmorphic UI and severely drain mobile battery.

---

## 2. Dark Glassmorphism & Aurora Shader Pipeline

### Decision: Dual-Pass CanvasItem Shaders + `StyleBoxFlat` Border Composition
- **Decision**: Implement Dark Glassmorphism using two modular layers:
  1. **Background Canvas Shader (`aurora_glow.gdshader`)**: Generates dynamic floating dual-tone color blobs using smooth simplex noise and organic coordinate distortion.
  2. **Frosted Glass Blur (`glass_blur.gdshader`)**: Uses `hint_screen_texture` with a multi-tap box blur filter, blended over a deep translucent slate tint (`rgba(15, 23, 42, 0.72)`).
  3. **Luminous Border**: Managed directly via Godot 4 `StyleBoxFlat` (`border_width=1px`, `border_color=rgba(255, 255, 255, 0.12)`, `corner_radius=16px`).
- **Rationale**:
  - Offloading borders and corner radii to `StyleBoxFlat` dramatically simplifies shader code, preserves hardware antialiasing, and eliminates fragile pixel-discard math.
  - Screen texture blurs are strictly scoped to modals and the 9x9 board background container, minimizing texture-read bandwidth.
- **Alternatives Considered**:
  - *Full Procedural SDF Glass Shader*: Rejected because computing rounded boxes, borders, and blurs purely inside fragment shaders causes unnecessary fragment arithmetic on mobile GPUs.

---

## 3. High-Performance Backtracking Sudoku Math Engine

### Decision: WorkerThreadPool Backtracking Generator & Solver
- **Decision**: Decouple puzzle generation and unique solution validation into a headless GDScript class (`SudokuGenerator.gd`) executed asynchronously via `WorkerThreadPool`.
- **Rationale**:
  - Generating high-difficulty puzzles (SER 5.0+ with 17–25 clues) requires multiple backtracking passes with candidate elimination.
  - Running on `WorkerThreadPool` ensures zero main-thread hitching, guaranteeing the UI maintains locked 60/120 FPS during scene transitions or new game initialization.
- **Alternatives Considered**:
  - *Main Thread Coroutine with await*: Causes perceptible micro-stutters when digging clues on lower-end devices.
  - *C++ / Rust Native GDExtension*: Overkill for 9x9 Sudoku math; well-optimized GDScript integer bitmasks can solve a 9x9 grid in <5ms.

---

## 4. Persistence Architecture: Dual-Tier Offline Strategy

### Decision: SQLite GDExtension (`sudoku.db`) + Robust FileAccess JSON Fallback
- **Decision**: Implement a database wrapper (`DatabaseManager.gd`) that interfaces with `godot-sqlite` GDExtension, with an automatic transparent JSON/FileAccess fallback.
- **Rationale**:
  - `user://sudoku.db` provides ACID transactions, relational queries for 100 campaign levels, and structured streak indexing.
  - Including the fallback engine ensures desktop playtesting (F5) runs out-of-the-box even in environments where the Windows GDExtension binary has not yet been built.
- **Alternatives Considered**:
  - *Pure ConfigFile for Everything*: Lacks relational query support for complex level matrices, leaderboards, and move history stacks.

---

## 5. Motion & Polish: Native Godot 4 Tween System

### Decision: Method-Chained `create_tween()` with `TRANS_BACK` and `EASE_OUT`
- **Decision**: Avoid heavyweight AnimationPlayer nodes for basic UI feedback; standardize all tactile animations (tap squish, cell glow, error shake, star burst) using native `create_tween()`.
- **Rationale**:
  - Complies with `awesome-gamedev-agent-skills` (`godot-animation` skill standard).
  - Clean, leak-free memory management (`create_tween()` automatically binds to node lifecycle).
  - Error shake formula: 4 alternating rapid $x$-offsets ($\pm 12\text{px}$) over 0.22s with simultaneous red pulse color tint.
