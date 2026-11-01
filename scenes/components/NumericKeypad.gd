# NumericKeypad.gd
# Interactive Controls Tray & Remaining Digit Capsule Keypad (1..9)
# Matches 3D Sudoku Master Gameplay Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

signal digit_pressed(digit: int)
signal action_triggered(action_name: String)

@onready var btn_counts: Button = $VBox/ActionTray/BtnCounts
@onready var btn_undo: Button = $VBox/ActionTray/BtnUndo
@onready var btn_erase: Button = $VBox/ActionTray/BtnErase
@onready var btn_notes: Button = $VBox/ActionTray/BtnNotes
@onready var btn_hint: Button = $VBox/ActionTray/BtnHint
@onready var hint_badge: Label = $VBox/ActionTray/BtnHint/Badge

@onready var digits_container: HBoxContainer = $VBox/DigitTray

var digit_buttons: Array[Button] = []
var count_labels: Array[Label] = []

func _ready() -> void:
	# Connect Action Tray
	btn_counts.pressed.connect(_on_counts_pressed)
	btn_undo.pressed.connect(_on_undo_pressed)
	btn_erase.pressed.connect(_on_erase_pressed)
	btn_notes.pressed.connect(_on_notes_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	
	# Connect Digit Buttons (1..9)
	digit_buttons.clear()
	count_labels.clear()
	for i in range(1, 10):
		var btn: Button = digits_container.get_node_or_null("Btn%d" % i) as Button
		if btn:
			digit_buttons.append(btn)
			var d_val: int = i
			btn.pressed.connect(func(): _on_digit_button_pressed(d_val, btn))
			var c_label: Label = btn.get_node_or_null("VBox/CountLabel") as Label
			if c_label:
				count_labels.append(c_label)
				
	# Connect to theme and engine signals
	SignalBus.theme_changed.connect(_on_theme_changed)
	_apply_theme_styling()
	
	if SudokuEngine:
		SudokuEngine.remaining_counts_updated.connect(_update_remaining_counts)
		_update_remaining_counts(SudokuEngine.get_remaining_counts())
		_update_notes_button_state()
		
	if GameManager:
		_update_hint_count()

func _on_theme_changed(_id: String, _p: Color, _s: Color) -> void:
	_apply_theme_styling()
	if SudokuEngine:
		_update_remaining_counts(SudokuEngine.get_remaining_counts())

func _apply_theme_styling() -> void:
	if not ThemeManager:
		return
	_update_notes_button_state()

func _update_notes_button_state() -> void:
	if not btn_notes:
		return
	if SudokuEngine and SudokuEngine.is_note_mode:
		btn_notes.modulate = Color(0.2, 0.7, 1.0, 1.0)
	else:
		btn_notes.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _update_hint_count() -> void:
	if hint_badge and GameManager:
		hint_badge.text = str(GameManager.hints_remaining)

func _update_remaining_counts(counts: Dictionary) -> void:
	var success_col: Color = Color("#10B981")
	var notes_col: Color = Color("#64748B")
	if ThemeManager:
		success_col = ThemeManager.get_success_color()
		notes_col = ThemeManager.get_notes_text_color()
		
	for i in range(1, 10):
		var idx: int = i - 1
		if idx < count_labels.size() and idx < digit_buttons.size():
			var rem: int = counts.get(i, 0)
			var c_label: Label = count_labels[idx]
			var btn: Button = digit_buttons[idx]
			
			if rem <= 0:
				c_label.text = "✔"
				c_label.add_theme_color_override("font_color", success_col)
				btn.modulate.a = 0.35
			else:
				c_label.text = str(rem)
				c_label.add_theme_color_override("font_color", notes_col)
				btn.modulate.a = 1.0

func _pop_button(btn: Control) -> void:
	if btn:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		btn.pivot_offset = btn.size / 2.0
		tween.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.06)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

func _on_digit_button_pressed(digit: int, btn: Control) -> void:
	_pop_button(btn)
	digit_pressed.emit(digit)
	if SudokuEngine:
		SudokuEngine.input_digit(digit)

func _on_counts_pressed() -> void:
	_pop_button(btn_counts)
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(20)

func _on_undo_pressed() -> void:
	_pop_button(btn_undo)
	action_triggered.emit("undo")
	if SudokuEngine:
		SudokuEngine.undo_last_move()

func _on_erase_pressed() -> void:
	_pop_button(btn_erase)
	action_triggered.emit("erase")
	if SudokuEngine:
		SudokuEngine.erase_selected_cell()

func _on_notes_pressed() -> void:
	_pop_button(btn_notes)
	if SudokuEngine:
		var _mode: bool = SudokuEngine.toggle_note_mode()
		_update_notes_button_state()
		SignalBus.play_sfx.emit("note_tick")
		SignalBus.trigger_haptic.emit(20)

func _on_hint_pressed() -> void:
	_pop_button(btn_hint)
	if GameManager and GameManager.hints_remaining > 0:
		if SudokuEngine:
			SudokuEngine.request_smart_hint()
			_update_hint_count()
	else:
		SignalBus.play_sfx.emit("error")
		SignalBus.trigger_haptic.emit(80)
