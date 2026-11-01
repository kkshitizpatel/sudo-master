# Quickstart & Verification Guide: Godot 4 Mobile Sudoku

**Feature**: `001-mobile-sudoku-core`  
**Status**: Completed Baseline  
**Date**: 2026-11-01  

---

## 1. Prerequisites
- **Godot Engine 4.7.2+** available on system PATH (`godot_console.exe`).
- Project root: `c:\Users\kkshi\Downloads\godot sudoku`
- Emulated touch from mouse enabled in `project.godot`.

---

## 2. Desktop Playtest Verification Scenarios (F5 / F6)

### Scenario 1: Initial Launch & Splash Screen (F5)
1. Run main project: `godot_console --path .` (or press **F5** in Godot Editor).
2. **Expected Outcome**:
   - Window opens at 1080x1920 (scaled to screen with `canvas_items` expand).
   - Dynamic Aurora ambient glow animates fluidly behind the JK Games hero card.
   - Frosted progress pill fills smoothly from 0% to 100% over ~1.5 seconds.
   - Transitions to Welcome/Onboarding on fresh launch.

### Scenario 2: Sudoku Gameplay Board (F6 on `06_sudoku_gameplay_board.tscn`)
1. Run scene: `godot_console --path . scenes/06_sudoku_gameplay_board.tscn` (or press **F6** in Godot Editor).
2. **Verification Steps**:
   - Board renders as a perfect 1:1 square centered on the screen.
   - Click cell (0, 0) ➔ Row 0, Column 0, and Box 0 highlight in frosted white; matching numbers across the board highlight in accent color.
   - Click number pad tile '5' ➔ Digit fills with primary accent glow; bottom capsule counter updates.
   - Click Pencil button ➔ Notes mode activates; clicking digits toggles candidate notes inside selected cell.
   - Make 3 intentional mistakes ➔ 3 hearts cross out, red pulse shake triggers, and Game Over Revive modal appears.

### Scenario 3: Theme Palette Live Transition (Frame 7)
1. In Gameplay or Settings, tap the Paint Palette button.
2. Select "Neon Emerald" (#10B981) then "Crimson Wine" (#F43F5E).
3. **Expected Outcome**:
   - Aurora shader background, cell glows, and luminous borders transition smoothly within <200ms.

---

## 3. Headless Verification Commands (CLI)
Automated checks can be run directly from PowerShell:
```powershell
# Validate project files and GDScript syntax
godot_console --headless --path . --check-only

# Verify scene hierarchy integrity
godot_console --headless --path . -s scripts/core/SudokuGenerator.gd
```
