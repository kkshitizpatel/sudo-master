# SudokuCellView.gd
# Individual Sudoku Cell Component (0..80) with dynamic state styling & candidate notes
# Integrated with ThemeManager for live palette switching
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

signal cell_tapped(index: int)

@export var cell_index: int = 0
@export var row: int = 0
@export var col: int = 0
@export var box: int = 0

@onready var panel: PanelContainer = $CellPanel
@onready var main_label: Label = $CellPanel/MainLabel
@onready var notes_grid: GridContainer = $CellPanel/NotesGrid
@onready var btn_touch: Button = $BtnTouch

var current_val: int = 0
var is_clue: bool = false
var is_error: bool = false
var current_highlight_state: String = "default"

var _shake_tween: Tween = null
var _notes_labels: Array[Label] = []

func _ready() -> void:
	btn_touch.pressed.connect(_on_touch_pressed)
	
	# Cache candidate notes labels
	_notes_labels.clear()
	for i in range(1, 10):
		var n_label: Label = notes_grid.get_node_or_null("N%d" % i) as Label
		if n_label:
			_notes_labels.append(n_label)
			
	SignalBus.theme_changed.connect(_on_theme_changed)
	_apply_theme_styling()

func _on_touch_pressed() -> void:
	cell_tapped.emit(cell_index)

func _on_theme_changed(_theme_id: String, _p: Color, _s: Color) -> void:
	_apply_theme_styling()
	set_highlight_state(current_highlight_state)

func _apply_theme_styling() -> void:
	if not ThemeManager or not is_inside_tree():
		return
		
	# Apply font colors
	if is_error:
		main_label.add_theme_color_override("font_color", ThemeManager.get_error_text_color())
	elif is_clue:
		main_label.add_theme_color_override("font_color", ThemeManager.get_clue_text_color())
	else:
		main_label.add_theme_color_override("font_color", ThemeManager.get_user_text_color())
		
	var notes_color: Color = ThemeManager.get_notes_text_color()
	for n_lbl in _notes_labels:
		n_lbl.add_theme_color_override("font_color", notes_color)

func update_cell(value: int, clue: bool, error: bool, notes: Array[int]) -> void:
	current_val = value
	is_clue = clue
	is_error = error
	
	if current_val > 0:
		main_label.visible = true
		notes_grid.visible = false
		main_label.text = str(current_val)
		
		if is_error:
			main_label.add_theme_color_override("font_color", ThemeManager.get_error_text_color())
			set_highlight_state("error")
			play_error_shake()
		elif is_clue:
			main_label.add_theme_color_override("font_color", ThemeManager.get_clue_text_color())
		else:
			# Player placed digit: Royal Vibrant Blue
			main_label.add_theme_color_override("font_color", ThemeManager.get_user_text_color())
			play_place_pop()
	else:
		main_label.visible = false
		main_label.text = ""
		
		# Display candidate notes
		if notes.is_empty():
			notes_grid.visible = false
		else:
			notes_grid.visible = true
			var notes_col: Color = ThemeManager.get_notes_text_color()
			for i in range(1, 10):
				var idx: int = i - 1
				if idx < _notes_labels.size():
					var n_lbl: Label = _notes_labels[idx]
					n_lbl.text = str(i) if notes.has(i) else ""
					n_lbl.add_theme_color_override("font_color", notes_col)
					
	set_highlight_state(current_highlight_state)

func set_highlight_state(state: String) -> void:
	current_highlight_state = state
	if not ThemeManager or not panel:
		return
		
	if is_error or state == "error":
		panel.add_theme_stylebox_override("panel", ThemeManager.get_style_cell_error())
		return
		
	match state:
		"selected":
			panel.add_theme_stylebox_override("panel", ThemeManager.get_style_cell_selected())
		"match":
			panel.add_theme_stylebox_override("panel", ThemeManager.get_style_cell_match())
		"scope":
			panel.add_theme_stylebox_override("panel", ThemeManager.get_style_cell_peer())
		_:
			if is_clue:
				panel.add_theme_stylebox_override("panel", ThemeManager.get_style_cell_clue())
			else:
				panel.add_theme_stylebox_override("panel", ThemeManager.get_style_cell_normal())

func play_error_shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		
	var orig_x: float = position.x
	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_shake_tween.tween_property(self, "position:x", orig_x - 6.0, 0.05)
	_shake_tween.tween_property(self, "position:x", orig_x + 6.0, 0.05)
	_shake_tween.tween_property(self, "position:x", orig_x - 4.0, 0.05)
	_shake_tween.tween_property(self, "position:x", orig_x + 4.0, 0.05)
	_shake_tween.tween_property(self, "position:x", orig_x, 0.05)

func play_place_pop() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pivot_offset = size / 2.0
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
