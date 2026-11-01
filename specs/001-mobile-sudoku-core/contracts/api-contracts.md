# Autoload & Service API Contracts: Godot 4 Mobile Sudoku

**Feature**: `001-mobile-sudoku-core`  
**Status**: Completed Baseline  
**Date**: 2026-11-01  

---

## 1. `GameManager.gd` (Autoload)

```gdscript
# Core State Query
func get_current_score() -> int
func get_elapsed_time_string() -> String
func is_placement_completed() -> bool

# Match Lifecycle Operations
func start_new_game(mode: int, difficulty_level: int, seed_string: String = "") -> void
func resume_saved_game() -> bool
func register_mistake() -> void
func record_score_points(base_points: int) -> void
func revive_player_with_life() -> void
func finish_match(is_victory: bool) -> Dictionary

# Haptics & System
func trigger_vibration(duration_ms: int = 30) -> void
```

---

## 2. `SudokuEngine.gd` (Autoload / Controller)

```gdscript
# Board Setup & Query
func initialize_board(solution_array: Array[int], clues_array: Array[int]) -> void
func get_cell_value(index: int) -> int
func get_candidate_notes(index: int) -> Array[int]
func get_remaining_counts() -> Dictionary

# Input Actions
func select_cell(index: int) -> void
func input_digit(digit: int) -> bool # Returns true if valid move, false if mistake
func toggle_candidate_note(digit: int) -> void
func erase_selected_cell() -> void
func undo_last_move() -> bool
func request_smart_hint() -> Dictionary # Returns {cell_index, suggested_digit, explanation}
```

---

## 3. `ThemeManager.gd` (Autoload)

```gdscript
# Theme Operations
func set_active_theme(theme_id: String) -> void
func get_primary_accent() -> Color
func get_secondary_glow() -> Color
func get_all_themes() -> Array[Dictionary]
func set_font_scale(scale_multiplier: float) -> void
```

---

## 4. `DatabaseManager.gd` (Persistence Service)

```gdscript
# Match Auto-Save
func save_active_match(match_data: Dictionary) -> void
func load_active_match() -> Dictionary
func clear_active_match() -> void

# Campaign & Progression
func get_campaign_levels() -> Array[Dictionary]
func unlock_campaign_level(level_id: int, stars: int, score: int, time_sec: int) -> void
func batch_unlock_levels(target_level: int, default_stars: int = 2) -> void
```
