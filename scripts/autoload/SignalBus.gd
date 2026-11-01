# SignalBus.gd
# Global decoupled event broker for Godot Sudoku
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Node

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
