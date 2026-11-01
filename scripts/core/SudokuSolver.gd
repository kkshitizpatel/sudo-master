# SudokuSolver.gd
# High-Performance Deterministic Sudoku Backtracking Solver & Uniqueness Verifier
# Compliant with Godot 4.7 GDScript 2.0 static typing
class_name SudokuSolver
extends RefCounted

# Solves the 81-element grid using recursive backtracking.
# Returns solved Array[int] if solvable, or empty array if invalid.
static func solve(grid: Array[int]) -> Array[int]:
	var board: Array[int] = grid.duplicate()
	if _backtrack_solve(board):
		return board
	return []

# Counts solutions up to `limit` (useful to verify uniqueness: count == 1)
static func count_solutions(grid: Array[int], limit: int = 2) -> int:
	var board: Array[int] = grid.duplicate()
	var count_ref: Array[int] = [0]
	_backtrack_count(board, count_ref, limit)
	return count_ref[0]

# Checks if `digit` can be legally placed at `index` in `board`
static func is_valid(board: Array[int], index: int, digit: int) -> bool:
	var row: int = index / 9
	var col: int = index % 9
	var box_r: int = (row / 3) * 3
	var box_c: int = (col / 3) * 3
	
	# Check row and col
	for i in range(9):
		var r_idx: int = row * 9 + i
		if r_idx != index and board[r_idx] == digit:
			return false
		var c_idx: int = i * 9 + col
		if c_idx != index and board[c_idx] == digit:
			return false
			
	# Check 3x3 box
	for r in range(3):
		for c in range(3):
			var b_idx: int = (box_r + r) * 9 + (box_c + c)
			if b_idx != index and board[b_idx] == digit:
				return false
				
	return true

# Finds empty cell with Minimum Remaining Values (MRV heuristic for speed)
static func _find_best_empty_cell(board: Array[int]) -> int:
	var best_idx: int = -1
	var min_candidates: int = 10
	
	for i in range(81):
		if board[i] == 0:
			var candidates: int = 0
			for d in range(1, 10):
				if is_valid(board, i, d):
					candidates += 1
			if candidates < min_candidates:
				min_candidates = candidates
				best_idx = i
				if min_candidates == 1:
					break # Can't get better than 1 choice
	return best_idx

static func _backtrack_solve(board: Array[int]) -> bool:
	var empty_idx: int = _find_best_empty_cell(board)
	if empty_idx == -1:
		return true # Solved!
		
	for digit in range(1, 10):
		if is_valid(board, empty_idx, digit):
			board[empty_idx] = digit
			if _backtrack_solve(board):
				return true
			board[empty_idx] = 0
			
	return false

static func _backtrack_count(board: Array[int], count_ref: Array[int], limit: int) -> void:
	if count_ref[0] >= limit:
		return
		
	var empty_idx: int = _find_best_empty_cell(board)
	if empty_idx == -1:
		count_ref[0] += 1
		return
		
	for digit in range(1, 10):
		if is_valid(board, empty_idx, digit):
			board[empty_idx] = digit
			_backtrack_count(board, count_ref, limit)
			board[empty_idx] = 0
			if count_ref[0] >= limit:
				return
