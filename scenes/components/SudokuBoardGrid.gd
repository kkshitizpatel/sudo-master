# SudokuBoardGrid.gd
# 9x9 Sudoku Board Controller with 1:1 AspectRatio locking and 81 Cell Views
# Integrated with ThemeManager for live board frame and grid styling
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

signal cell_clicked(cell_index: int)

@export var cell_scene: PackedScene = preload("res://scenes/components/SudokuCellView.tscn")

@onready var board_panel: PanelContainer = $BoardPanel
@onready var grid_container: GridContainer = $BoardPanel/OuterGrid

var cell_views: Array[Control] = []
var _selected_index: int = -1
var _box_styles: Array[StyleBoxFlat] = []

func _ready() -> void:
	_apply_board_panel_theme()
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
	_apply_board_panel_theme()

func _apply_board_panel_theme() -> void:
	if not ThemeManager or not board_panel:
		return
	board_panel.add_theme_stylebox_override("panel", ThemeManager.get_style_board_panel())
	
	var major_color: Color = ThemeManager.get_major_grid_color()
	for sb in _box_styles:
		sb.border_color = major_color

func _build_grid_cells() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	cell_views.resize(81)
	_box_styles.clear()
	
	var major_color: Color = Color("#242D3D")
	if ThemeManager:
		major_color = ThemeManager.get_major_grid_color()
		
	# Create 9 3x3 Box Sub-Grids
	for box_idx in range(9):
		var box_box: PanelContainer = PanelContainer.new()
		box_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# 3x3 Major Grid divider border
		var box_style: StyleBoxFlat = StyleBoxFlat.new()
		box_style.bg_color = Color(0, 0, 0, 0.0) # Transparent so cell backgrounds display cleanly
		box_style.border_width_left = 2
		box_style.border_width_top = 2
		box_style.border_width_right = 2
		box_style.border_width_bottom = 2
		box_style.border_color = major_color
		box_style.corner_radius_top_left = 6
		box_style.corner_radius_top_right = 6
		box_style.corner_radius_bottom_right = 6
		box_style.corner_radius_bottom_left = 6
		box_style.content_margin_left = 2.0
		box_style.content_margin_top = 2.0
		box_style.content_margin_right = 2.0
		box_style.content_margin_bottom = 2.0
		box_box.add_theme_stylebox_override("panel", box_style)
		_box_styles.append(box_style)
		
		var sub_grid: GridContainer = GridContainer.new()
		sub_grid.columns = 3
		sub_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sub_grid.add_theme_constant_override("h_separation", 2)
		sub_grid.add_theme_constant_override("v_separation", 2)
		box_box.add_child(sub_grid)
		
		grid_container.add_child(box_box)
		
		var box_row_start: int = (box_idx / 3) * 3
		var box_col_start: int = (box_idx % 3) * 3
		
		for local_r in range(3):
			for local_c in range(3):
				var r: int = box_row_start + local_r
				var c: int = box_col_start + local_c
				var global_idx: int = r * 9 + c
				
				var cell_view: Control = cell_scene.instantiate() as Control
				cell_view.set("cell_index", global_idx)
				cell_view.set("row", r)
				cell_view.set("col", c)
				cell_view.set("box", box_idx)
				cell_view.connect("cell_tapped", _on_cell_tapped)
				
				sub_grid.add_child(cell_view)
				cell_views[global_idx] = cell_view

func _on_cell_tapped(index: int) -> void:
	cell_clicked.emit(index)
	if SudokuEngine:
		SudokuEngine.select_cell(index)

func _on_board_initialized() -> void:
	_refresh_entire_board()

func _refresh_entire_board() -> void:
	for i in range(81):
		var cell_data: Dictionary = SudokuEngine.get_cell(i)
		var view: Control = cell_views[i]
		if view and view.has_method("update_cell"):
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
		if view and view.has_method("update_cell"):
			view.call("update_cell", value, clue, error, notes)
			
	# Re-evaluate highlights for matching numbers
	if _selected_index >= 0:
		var sel_val: int = SudokuEngine.get_cell_value(_selected_index)
		_apply_highlights(_selected_index, sel_val)

func _on_cell_selection_changed(index: int, selected_digit: int) -> void:
	_selected_index = index
	_apply_highlights(index, selected_digit)

func _apply_highlights(selected_idx: int, selected_val: int) -> void:
	if selected_idx < 0 or selected_idx >= 81:
		for view in cell_views:
			if view and view.has_method("set_highlight_state"):
				view.call("set_highlight_state", "default")
		return
		
	var sel_row: int = selected_idx / 9
	var sel_col: int = selected_idx % 9
	var sel_box: int = (sel_row / 3) * 3 + (sel_col / 3)
	
	for i in range(81):
		var view: Control = cell_views[i]
		if not view or not view.has_method("set_highlight_state"):
			continue
			
		var r: int = i / 9
		var c: int = i % 9
		var b: int = (r / 3) * 3 + (c / 3)
		var val: int = SudokuEngine.get_cell_value(i)
		
		if i == selected_idx:
			view.call("set_highlight_state", "selected")
		elif selected_val > 0 and val == selected_val:
			view.call("set_highlight_state", "match")
		elif r == sel_row or c == sel_col or b == sel_box:
			view.call("set_highlight_state", "scope")
		else:
			view.call("set_highlight_state", "default")
