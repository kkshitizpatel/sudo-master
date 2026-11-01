# SudokuBoardGrid.gd
# 9x9 Sudoku Board Controller with 1:1 AspectRatio locking and 81 Cell Views
# Integrated with ThemeManager for live board frame and grid styling
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends GridContainer

signal cell_clicked(cell_index: int)

@export var cell_scene: PackedScene = preload("res://scenes/components/SudokuCellView.tscn")

var cell_views: Array[Control] = []
var _selected_index: int = -1

func _ready() -> void:
	columns = 9
	_build_grid_cells()
	
	SignalBus.theme_changed.connect(_on_theme_changed)
	
	# Connect to SudokuEngine signals
	if SudokuEngine:
		SudokuEngine.board_initialized.connect(_on_board_initialized)
		SudokuEngine.cell_state_updated.connect(_on_cell_state_updated)
		SudokuEngine.cell_selection_changed.connect(_on_cell_selection_changed)
		
		# If board already populated, refresh immediately
		if not SudokuEngine.cells.is_empty():
			_refresh_entire_board()

func _on_theme_changed(_id: String, _p: Color, _s: Color) -> void:
	if _selected_index >= 0:
		var sel_val: int = SudokuEngine.get_cell_value(_selected_index) if SudokuEngine else 0
		_apply_highlights(_selected_index, sel_val)

func _build_grid_cells() -> void:
	for child in get_children():
		child.queue_free()
	cell_views.clear()
	cell_views.resize(81)
	
	for i in range(81):
		var r: int = i / 9
		var c: int = i % 9
		var box_idx: int = (r / 3) * 3 + (c / 3)
		
		var cell_view: Control = cell_scene.instantiate() as Control
		cell_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell_view.set("cell_index", i)
		cell_view.set("row", r)
		cell_view.set("col", c)
		cell_view.set("box", box_idx)
		cell_view.connect("cell_tapped", _on_cell_tapped)
		
		add_child(cell_view)
		cell_views[i] = cell_view

func _on_cell_tapped(index: int) -> void:
	cell_clicked.emit(index)
	if SudokuEngine:
		SudokuEngine.select_cell(index)

func _on_board_initialized() -> void:
	_refresh_entire_board()

func _refresh_entire_board() -> void:
	if not SudokuEngine:
		return
	for i in range(81):
		if i >= cell_views.size():
			continue
		var cell_data: Dictionary = SudokuEngine.get_cell(i)
		var view: Control = cell_views[i]
		if view and is_instance_valid(view) and view.has_method("update_cell"):
			view.call(
				"update_cell",
				cell_data.get("current_val", 0),
				cell_data.get("is_clue", false),
				cell_data.get("is_error", false),
				SudokuEngine.get_candidate_notes(i)
			)

func _on_cell_state_updated(index: int, value: int, clue: bool, error: bool, notes: Array[int]) -> void:
	if index >= 0 and index < cell_views.size():
		var view: Control = cell_views[index]
		if view and is_instance_valid(view) and view.has_method("update_cell"):
			view.call("update_cell", value, clue, error, notes)
			
	# Re-evaluate highlights for matching numbers
	if _selected_index >= 0 and SudokuEngine:
		var sel_val: int = SudokuEngine.get_cell_value(_selected_index)
		_apply_highlights(_selected_index, sel_val)

func _on_cell_selection_changed(index: int, selected_digit: int) -> void:
	_selected_index = index
	_apply_highlights(index, selected_digit)

func _apply_highlights(selected_idx: int, selected_val: int) -> void:
	if selected_idx < 0 or selected_idx >= 81:
		for view in cell_views:
			if view and is_instance_valid(view) and view.has_method("set_highlight_state"):
				view.call("set_highlight_state", "default")
		return
		
	var sel_row: int = selected_idx / 9
	var sel_col: int = selected_idx % 9
	var sel_box: int = (sel_row / 3) * 3 + (sel_col / 3)
	
	for i in range(81):
		if i >= cell_views.size():
			continue
		var view: Control = cell_views[i]
		if not view or not is_instance_valid(view) or not view.has_method("set_highlight_state"):
			continue
			
		var r: int = i / 9
		var c: int = i % 9
		var b: int = (r / 3) * 3 + (c / 3)
		var val: int = SudokuEngine.get_cell_value(i) if SudokuEngine else 0
		
		if i == selected_idx:
			view.call("set_highlight_state", "selected")
		elif selected_val > 0 and val == selected_val:
			view.call("set_highlight_state", "match")
		elif r == sel_row or c == sel_col or b == sel_box:
			view.call("set_highlight_state", "scope")
		else:
			view.call("set_highlight_state", "default")
