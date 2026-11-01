# SudokuEngine.gd
# Core Sudoku 9x9 Board State, Validation, Candidate Notes, and Undo Engine
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Node

# Signals
signal board_initialized()
signal cell_state_updated(cell_index: int, value: int, is_clue: bool, is_error: bool, notes: Array[int])
signal cell_selection_changed(cell_index: int, selected_digit: int)
signal remaining_counts_updated(remaining_dict: Dictionary)
signal move_undone(cell_index: int, restored_value: int, restored_notes: Array[int])
signal hint_provided(cell_index: int, correct_digit: int, explanation: String)

# Internal Cell Data Structure (81 elements)
# Each entry is a Dictionary:
# {
#   "index": int (0..80),
#   "row": int (0..8),
#   "col": int (0..8),
#   "box": int (0..8),
#   "solution_val": int (1..9),
#   "current_val": int (0..9),
#   "is_clue": bool,
#   "is_error": bool,
#   "candidate_notes": Array[int]
# }
var cells: Array[Dictionary] = []
var selected_cell_index: int = -1
var is_note_mode: bool = false
var auto_remove_notes: bool = true
var remaining_counts: Dictionary = {1: 9, 2: 9, 3: 9, 4: 9, 5: 9, 6: 9, 7: 9, 8: 9, 9: 9}

# Undo History Stack
# Stores MoveRecord Dictionaries:
# {
#   "cell_index": int,
#   "previous_val": int,
#   "new_val": int,
#   "previous_notes": Array[int],
#   "new_notes": Array[int],
#   "was_error": bool,
#   "removed_candidate_backup": Array[Dictionary] # Backup of candidate notes wiped across row/col/box
# }
var move_history: Array[Dictionary] = []

# Pre-baked Valid Sudoku Puzzles (81-character strings, 0 represents empty)
const SAMPLE_PUZZLES: Dictionary = {
	"easy": {
		"clues": "530070000600195000098000060800060003400803001700020006060000280000419005000080079",
		"solution": "534678912672195348198342567859761423426853791713924856961537284287419635345286179"
	},
	"medium": {
		"clues": "000000000000003085001020000000507000004000100090000000500000073002010000000040009",
		"solution": "987654321246173985351928746128537694634892157795416832519280473872315060463749219"
	},
	"hard": {
		"clues": "000000012000000003002300400001800005060070800000009000008500000900040500470006000",
		"solution": "683457912147298653592361487321845769265973841784129356819532174936741528475816239"
	}
}

func _ready() -> void:
	_init_empty_grid()

func _init_empty_grid() -> void:
	cells.clear()
	for i in range(81):
		var r: int = i / 9
		var c: int = i % 9
		var b: int = (r / 3) * 3 + (c / 3)
		cells.append({
			"index": i,
			"row": r,
			"col": c,
			"box": b,
			"solution_val": 0,
			"current_val": 0,
			"is_clue": false,
			"is_error": false,
			"candidate_notes": []
		})

# ------------------------------------------------------------------------------
# Board Initialization & Loading
# ------------------------------------------------------------------------------

func initialize_board(solution_array: Array[int], clues_array: Array[int]) -> void:
	_init_empty_grid()
	move_history.clear()
	selected_cell_index = -1
	
	# Reset counts
	for d in range(1, 10):
		remaining_counts[d] = 9
		
	for i in range(81):
		var sol: int = solution_array[i] if i < solution_array.size() else 0
		var clue: int = clues_array[i] if i < clues_array.size() else 0
		
		cells[i]["solution_val"] = sol
		cells[i]["current_val"] = clue
		cells[i]["is_clue"] = (clue > 0)
		cells[i]["is_error"] = false
		cells[i]["candidate_notes"] = []
		
		if clue > 0:
			remaining_counts[clue] -= 1
			
	remaining_counts_updated.emit(remaining_counts.duplicate())
	SignalBus.remaining_counts_changed.emit(remaining_counts.duplicate())
	board_initialized.emit()

func load_puzzle_from_strings(clues_str: String, solution_str: String) -> void:
	var clues_arr: Array[int] = []
	var sol_arr: Array[int] = []
	for i in range(min(81, clues_str.length())):
		clues_arr.append(clues_str[i].to_int())
	for i in range(min(81, solution_str.length())):
		sol_arr.append(solution_str[i].to_int())
	initialize_board(sol_arr, clues_arr)

func load_sample_puzzle(difficulty_key: String = "easy") -> void:
	if SAMPLE_PUZZLES.has(difficulty_key):
		var p: Dictionary = SAMPLE_PUZZLES[difficulty_key]
		load_puzzle_from_strings(p["clues"], p["solution"])
	else:
		var p: Dictionary = SAMPLE_PUZZLES["easy"]
		load_puzzle_from_strings(p["clues"], p["solution"])

# ------------------------------------------------------------------------------
# Cell Selection & Queries
# ------------------------------------------------------------------------------

func select_cell(index: int) -> void:
	if index < 0 or index >= 81:
		selected_cell_index = -1
		cell_selection_changed.emit(-1, 0)
		SignalBus.cell_selected.emit(-1)
		return
		
	selected_cell_index = index
	var cur_val: int = cells[index]["current_val"]
	cell_selection_changed.emit(index, cur_val)
	SignalBus.cell_selected.emit(index)

func get_selected_cell() -> Dictionary:
	if selected_cell_index >= 0 and selected_cell_index < 81:
		return cells[selected_cell_index]
	return {}

func get_cell(index: int) -> Dictionary:
	if index >= 0 and index < 81:
		return cells[index]
	return {}

func get_cell_value(index: int) -> int:
	if index >= 0 and index < 81:
		return cells[index]["current_val"]
	return 0

func get_candidate_notes(index: int) -> Array[int]:
	if index >= 0 and index < 81:
		var raw_notes: Array = cells[index]["candidate_notes"]
		var notes: Array[int] = []
		for n in raw_notes:
			notes.append(int(n))
		return notes
	return []

func get_remaining_counts() -> Dictionary:
	return remaining_counts.duplicate()

# ------------------------------------------------------------------------------
# Input Handling (Digits, Notes, Erase, Undo)
# ------------------------------------------------------------------------------

func set_note_mode(enabled: bool) -> void:
	is_note_mode = enabled

func toggle_note_mode() -> bool:
	is_note_mode = not is_note_mode
	return is_note_mode

func input_digit(digit: int) -> bool:
	if selected_cell_index < 0 or selected_cell_index >= 81:
		return false
	if digit < 1 or digit > 9:
		return false
		
	var cell: Dictionary = cells[selected_cell_index]
	if cell["is_clue"]:
		# Pre-filled clues cannot be modified
		return false
		
	if is_note_mode:
		toggle_candidate_note(digit)
		return true
		
	# Normal Digit Placement Mode
	var prev_val: int = cell["current_val"]
	var prev_notes: Array[int] = get_candidate_notes(selected_cell_index)
	var was_error: bool = cell["is_error"]
	var is_correct: bool = (digit == cell["solution_val"])
	
	# Don't re-input the same correct digit
	if prev_val == digit and not was_error:
		return true
		
	# Deduct / refund remaining count for previous valid value
	if prev_val > 0 and not was_error:
		remaining_counts[prev_val] = mini(9, remaining_counts[prev_val] + 1)
		
	cell["current_val"] = digit
	cell["is_error"] = not is_correct
	cell["candidate_notes"] = [] # Clear notes on the cell itself
	
	var removed_notes_backup: Array[Dictionary] = []
	if is_correct:
		remaining_counts[digit] = maxi(0, remaining_counts[digit] - 1)
		remaining_counts_updated.emit(remaining_counts.duplicate())
		SignalBus.remaining_counts_changed.emit(remaining_counts.duplicate())
		
		# Auto-remove candidate notes in row, col, and box if enabled
		if auto_remove_notes:
			removed_notes_backup = _auto_remove_candidate_notes(cell["row"], cell["col"], cell["box"], digit)
			
		GameManager.record_valid_move()
		SignalBus.play_sfx.emit("place_number")
	else:
		GameManager.register_mistake()
		SignalBus.play_sfx.emit("error")
		
	# Push to Undo Stack
	move_history.append({
		"cell_index": selected_cell_index,
		"previous_val": prev_val,
		"new_val": digit,
		"previous_notes": prev_notes,
		"new_notes": [],
		"was_error": was_error,
		"removed_candidate_backup": removed_notes_backup
	})
	
	_notify_cell_updated(selected_cell_index)
	SignalBus.cell_digit_entered.emit(selected_cell_index, digit)
	
	if is_correct and is_board_completed():
		GameManager.complete_puzzle()
		
	return is_correct

func toggle_candidate_note(digit: int) -> void:
	if selected_cell_index < 0 or selected_cell_index >= 81:
		return
	var cell: Dictionary = cells[selected_cell_index]
	if cell["is_clue"] or cell["current_val"] > 0:
		return
		
	var prev_notes: Array[int] = get_candidate_notes(selected_cell_index)
	var new_notes: Array[int] = prev_notes.duplicate()
	
	if new_notes.has(digit):
		new_notes.erase(digit)
	else:
		new_notes.append(digit)
		new_notes.sort()
		
	cell["candidate_notes"] = new_notes
	
	# Push note toggle to Undo Stack
	move_history.append({
		"cell_index": selected_cell_index,
		"previous_val": 0,
		"new_val": 0,
		"previous_notes": prev_notes,
		"new_notes": new_notes,
		"was_error": false,
		"removed_candidate_backup": []
	})
	
	_notify_cell_updated(selected_cell_index)
	SignalBus.candidate_note_toggled.emit(selected_cell_index, digit)
	SignalBus.play_sfx.emit("note_tick")

func erase_selected_cell() -> void:
	if selected_cell_index < 0 or selected_cell_index >= 81:
		return
	var cell: Dictionary = cells[selected_cell_index]
	if cell["is_clue"]:
		return
		
	var prev_val: int = cell["current_val"]
	var prev_notes: Array[int] = get_candidate_notes(selected_cell_index)
	var was_error: bool = cell["is_error"]
	
	if prev_val == 0 and prev_notes.is_empty():
		return
		
	if prev_val > 0 and not was_error:
		remaining_counts[prev_val] = mini(9, remaining_counts[prev_val] + 1)
		remaining_counts_updated.emit(remaining_counts.duplicate())
		SignalBus.remaining_counts_changed.emit(remaining_counts.duplicate())
		
	cell["current_val"] = 0
	cell["is_error"] = false
	cell["candidate_notes"] = []
	
	move_history.append({
		"cell_index": selected_cell_index,
		"previous_val": prev_val,
		"new_val": 0,
		"previous_notes": prev_notes,
		"new_notes": [],
		"was_error": was_error,
		"removed_candidate_backup": []
	})
	
	_notify_cell_updated(selected_cell_index)
	SignalBus.cell_cleared.emit(selected_cell_index)
	SignalBus.play_sfx.emit("erase")

func undo_last_move() -> bool:
	if move_history.is_empty():
		return false
		
	var last_move: Dictionary = move_history.pop_back()
	var idx: int = last_move["cell_index"]
	var prev_val: int = last_move["previous_val"]
	var new_val: int = last_move["new_val"]
	var prev_notes: Array[int] = last_move["previous_notes"]
	var cell: Dictionary = cells[idx]
	
	# Revert count updates
	if new_val > 0 and not last_move.get("was_error", false):
		remaining_counts[new_val] = mini(9, remaining_counts[new_val] + 1)
	if prev_val > 0:
		remaining_counts[prev_val] = maxi(0, remaining_counts[prev_val] - 1)
		
	remaining_counts_updated.emit(remaining_counts.duplicate())
	SignalBus.remaining_counts_changed.emit(remaining_counts.duplicate())
	
	# Restore cell state
	cell["current_val"] = prev_val
	cell["is_error"] = last_move.get("was_error", false)
	cell["candidate_notes"] = prev_notes
	
	# Restore wiped neighbor candidate notes
	var removed_backup: Array = last_move.get("removed_candidate_backup", [])
	for item in removed_backup:
		var n_idx: int = item["index"]
		var restored_digit: int = item["digit"]
		var target_cell: Dictionary = cells[n_idx]
		if not target_cell["candidate_notes"].has(restored_digit):
			target_cell["candidate_notes"].append(restored_digit)
			target_cell["candidate_notes"].sort()
			_notify_cell_updated(n_idx)
			
	_notify_cell_updated(idx)
	move_undone.emit(idx, prev_val, prev_notes)
	SignalBus.play_sfx.emit("undo")
	return true

# ------------------------------------------------------------------------------
# Smart Hint Deduction Hook
# ------------------------------------------------------------------------------

func request_smart_hint() -> Dictionary:
	if GameManager.hints_remaining <= 0:
		return {}
		
	# 1. Search for empty cell with solution
	var candidate_indices: Array[int] = []
	for i in range(81):
		if cells[i]["current_val"] == 0 or cells[i]["is_error"]:
			candidate_indices.append(i)
			
	if candidate_indices.is_empty():
		return {}
		
	# Select currently highlighted cell if valid, otherwise pick first empty
	var target_idx: int = candidate_indices[0]
	if candidate_indices.has(selected_cell_index):
		target_idx = selected_cell_index
		
	var cell: Dictionary = cells[target_idx]
	var correct_num: int = cell["solution_val"]
	
	# Apply hint to cell
	select_cell(target_idx)
	set_note_mode(false)
	input_digit(correct_num)
	GameManager.record_hint_used()
	
	var explanation: String = "Placed %d in Row %d, Col %d based on unique elimination." % [correct_num, cell["row"] + 1, cell["col"] + 1]
	hint_provided.emit(target_idx, correct_num, explanation)
	
	return {
		"cell_index": target_idx,
		"suggested_digit": correct_num,
		"explanation": explanation
	}

# ------------------------------------------------------------------------------
# Helpers & Rules Validation
# ------------------------------------------------------------------------------

func is_board_completed() -> bool:
	for i in range(81):
		var cell: Dictionary = cells[i]
		if cell["current_val"] == 0 or cell["current_val"] != cell["solution_val"] or cell["is_error"]:
			return false
	return true

func _auto_remove_candidate_notes(row: int, col: int, box: int, digit: int) -> Array[Dictionary]:
	var removed_notes: Array[Dictionary] = []
	for i in range(81):
		var c: Dictionary = cells[i]
		if c["row"] == row or c["col"] == col or c["box"] == box:
			var notes: Array = c["candidate_notes"]
			if notes.has(digit):
				notes.erase(digit)
				removed_notes.append({"index": i, "digit": digit})
				_notify_cell_updated(i)
	return removed_notes

func _notify_cell_updated(index: int) -> void:
	var cell: Dictionary = cells[index]
	cell_state_updated.emit(
		index,
		cell["current_val"],
		cell["is_clue"],
		cell["is_error"],
		get_candidate_notes(index)
	)

func get_cells_in_row(row: int) -> Array[int]:
	var indices: Array[int] = []
	for i in range(81):
		if cells[i]["row"] == row:
			indices.append(i)
	return indices

func get_cells_in_col(col: int) -> Array[int]:
	var indices: Array[int] = []
	for i in range(81):
		if cells[i]["col"] == col:
			indices.append(i)
	return indices

func get_cells_in_box(box: int) -> Array[int]:
	var indices: Array[int] = []
	for i in range(81):
		if cells[i]["box"] == box:
			indices.append(i)
	return indices
