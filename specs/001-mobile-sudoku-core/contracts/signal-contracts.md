# Signal Contracts: Godot 4 Mobile Sudoku

**Feature**: `001-mobile-sudoku-core`  
**Status**: Completed Baseline  
**Date**: 2026-11-01  

---

## 1. Global Signal Bus (`SignalBus.gd`)

To ensure clean decoupling between UI components, math solvers, and audio engines, the following signals are registered on the global bus:

```gdscript
# Board & Interaction Signals
signal cell_selected(cell_index: int)
signal cell_digit_entered(cell_index: int, digit: int)
signal cell_cleared(cell_index: int)
signal candidate_note_toggled(cell_index: int, candidate_digit: int)
signal remaining_counts_changed(remaining_dict: Dictionary)

# Match Progress & Scoring
signal score_awarded(points: int, multiplier: float)
signal mistake_registered(current_mistakes: int, max_mistakes: int)
signal puzzle_completed(completion_stats: Dictionary)
signal game_over_opened(reason: String)
signal game_revived_with_life()

# Audio & Tactile Signals
signal play_sfx(sfx_name: String)
signal trigger_haptic(duration_ms: int)

# Theme & Visual Customization
signal theme_changed(theme_id: String, primary_color: Color, secondary_color: Color)
signal font_scale_updated(scale_factor: float)
```

---

## 2. Component-to-Parent Event Contracts

| Emitting Node | Signal Name | Arguments | Handling Node / Controller | Action |
|---|---|---|---|---|
| `SudokuCell.tscn` | `cell_clicked` | `(index: int)` | `SudokuBoard.gd` | Highlights active row/col/box and sets focus. |
| `NumberTile.tscn` | `number_pressed` | `(digit: int)` | `ActionBar.gd` / `SudokuBoard.gd` | Triggers digit insertion into active cell. |
| `PencilButton` | `toggled` | `(is_active: bool)`| `SudokuEngine.gd` | Switches between value fill and notes mode. |
| `UndoButton` | `pressed` | None | `SudokuEngine.gd` | Reverts last move from the move stack. |
| `ThemeSwatch.tscn`| `swatch_selected`| `(theme_id: String)`| `ThemeManager.gd` | Broadcasts theme update across shaders. |
