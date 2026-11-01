# SudokuGenerator.gd
# Asynchronous Background Sudoku Puzzle Generator running on WorkerThreadPool
# Produces symmetric 9x9 puzzles with guaranteed unique solutions
# Compliant with Godot 4.7 GDScript 2.0 static typing
class_name SudokuGenerator
extends RefCounted

# Generates a valid puzzle synchronously
static func generate_puzzle(difficulty: String = "medium") -> Dictionary:
	var target_clues: int = 36
	match difficulty:
		"easy":
			target_clues = 38
		"medium":
			target_clues = 30
		"hard":
			target_clues = 26
			
	var full_solution: Array[int] = _generate_full_board()
	var clues_board: Array[int] = full_solution.duplicate()
	
	# Create list of cell indices 0..40 for 180-degree symmetric removal
	var indices: Array[int] = []
	for i in range(41):
		indices.append(i)
	indices.shuffle()
	
	var current_clues: int = 81
	for idx in indices:
		if current_clues <= target_clues:
			break
			
		var sym_idx: int = 80 - idx
		var val_a: int = clues_board[idx]
		var val_b: int = clues_board[sym_idx]
		
		# Tentatively remove symmetric pair
		clues_board[idx] = 0
		clues_board[sym_idx] = 0
		
		# Verify uniqueness
		if SudokuSolver.count_solutions(clues_board, 2) == 1:
			current_clues -= (1 if idx == sym_idx else 2)
		else:
			# Restore if solution became ambiguous
			clues_board[idx] = val_a
			clues_board[sym_idx] = val_b
			
	return {
		"clues": clues_board,
		"solution": full_solution,
		"clues_count": current_clues,
		"difficulty": difficulty
	}

# Dispatches puzzle generation to WorkerThreadPool for zero-stutter background generation
static func generate_puzzle_async(difficulty: String, on_completed: Callable) -> int:
	var task_id: int = WorkerThreadPool.add_task(func():
		var result: Dictionary = generate_puzzle(difficulty)
		on_completed.call_deferred(result)
	)
	return task_id

# ------------------------------------------------------------------------------
# Full Valid Board Generation
# ------------------------------------------------------------------------------

static func _generate_full_board() -> Array[int]:
	var board: Array[int] = []
	board.resize(81)
	board.fill(0)
	
	# Fill diagonal independent 3x3 boxes (Box 0, Box 4, Box 8)
	_fill_box_randomly(board, 0, 0)
	_fill_box_randomly(board, 3, 3)
	_fill_box_randomly(board, 6, 6)
	
	# Solve the rest using randomized backtracking
	_solve_randomized(board)
	return board

static func _fill_box_randomly(board: Array[int], start_row: int, start_col: int) -> void:
	var digits: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	digits.shuffle()
	
	var idx: int = 0
	for r in range(3):
		for c in range(3):
			var global_idx: int = (start_row + r) * 9 + (start_col + c)
			board[global_idx] = digits[idx]
			idx += 1

static func _solve_randomized(board: Array[int]) -> bool:
	var empty_idx: int = -1
	for i in range(81):
		if board[i] == 0:
			empty_idx = i
			break
			
	if empty_idx == -1:
		return true
		
	var digits: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	digits.shuffle()
	
	for d in digits:
		if SudokuSolver.is_valid(board, empty_idx, d):
			board[empty_idx] = d
			if _solve_randomized(board):
				return true
			board[empty_idx] = 0
			
	return false
