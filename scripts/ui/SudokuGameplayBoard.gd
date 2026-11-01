# SudokuGameplayBoard.gd
# Frame 6: Master Sudoku Gameplay Screen with Timer, Scoring, Mistakes, and Modals
# Matches 3D Sudoku Master Gameplay Board Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

# Top Bar
@onready var btn_back: Button = $SafeMarginContainer/MainVBox/TopBar/BtnBack
@onready var btn_share: Button = $SafeMarginContainer/MainVBox/TopBar/BtnShare
@onready var btn_favorite: Button = $SafeMarginContainer/MainVBox/TopBar/BtnFavorite
@onready var btn_theme: Button = $SafeMarginContainer/MainVBox/TopBar/BtnTheme
@onready var btn_settings: Button = $SafeMarginContainer/MainVBox/TopBar/BtnSettings

# Stats Bar
@onready var label_score: Label = $SafeMarginContainer/MainVBox/StatsBar/ScoreHBox/ScoreLabel
@onready var label_level: Label = $SafeMarginContainer/MainVBox/StatsBar/LevelLabel
@onready var label_timer: Label = $SafeMarginContainer/MainVBox/StatsBar/TimerLabel

# Board
@onready var sudoku_grid: GridContainer = $SafeMarginContainer/MainVBox/BoardWrapper/BoardAspect/SudokuGrid

# Mistakes Row
@onready var label_mistakes: Label = $SafeMarginContainer/MainVBox/MistakesRow/MistakesHBox/MistakesLabel
@onready var heart_1: TextureRect = $SafeMarginContainer/MainVBox/MistakesRow/MistakesHBox/HeartsBox/Heart1
@onready var heart_2: TextureRect = $SafeMarginContainer/MainVBox/MistakesRow/MistakesHBox/HeartsBox/Heart2
@onready var heart_3: TextureRect = $SafeMarginContainer/MainVBox/MistakesRow/MistakesHBox/HeartsBox/Heart3
@onready var diff_label: Label = $SafeMarginContainer/MainVBox/MistakesRow/DifficultyBadge/DiffLabel

# Action Buttons
@onready var btn_counts: Button = $SafeMarginContainer/MainVBox/ActionButtonsRow/BtnCounts
@onready var btn_undo: Button = $SafeMarginContainer/MainVBox/ActionButtonsRow/BtnUndo
@onready var btn_erase: Button = $SafeMarginContainer/MainVBox/ActionButtonsRow/BtnErase
@onready var btn_notes: Button = $SafeMarginContainer/MainVBox/ActionButtonsRow/BtnNotes
@onready var btn_hint: Button = $SafeMarginContainer/MainVBox/ActionButtonsRow/BtnHint
@onready var hint_badge: Label = $SafeMarginContainer/MainVBox/ActionButtonsRow/BtnHint/Badge

# Number Pad Tray
@onready var number_pad_tray: HBoxContainer = $SafeMarginContainer/MainVBox/NumberPadTray

# Modals
@onready var revive_modal: Control = $ReviveModal
@onready var btn_revive_coins: Button = $ReviveModal/CenterContainer/ModalPanel/VBox/BtnReviveCoins
@onready var btn_revive_ad: Button = $ReviveModal/CenterContainer/ModalPanel/VBox/BtnReviveAd
@onready var btn_give_up: Button = $ReviveModal/CenterContainer/ModalPanel/VBox/BtnGiveUp

@onready var victory_modal: Control = $VictoryModal
@onready var label_victory_stars: Label = $VictoryModal/CenterContainer/ModalPanel/VBox/StarsLabel
@onready var label_victory_time: Label = $VictoryModal/CenterContainer/ModalPanel/VBox/TimeLabel
@onready var label_victory_score: Label = $VictoryModal/CenterContainer/ModalPanel/VBox/FinalScoreLabel
@onready var btn_next_level: Button = $VictoryModal/CenterContainer/ModalPanel/VBox/BtnNextLevel
@onready var btn_victory_home: Button = $VictoryModal/CenterContainer/ModalPanel/VBox/BtnVictoryHome

var _heart_dark: Texture2D = preload("res://assets/icons/heart_dark.svg")
var _heart_empty: Texture2D = preload("res://assets/icons/heart_empty.svg")

var digit_buttons: Array[Button] = []
var count_labels: Array[Label] = []

func _ready() -> void:
	_apply_safe_area()
	_update_header_info()
	_update_hearts(GameManager.mistakes_count if GameManager else 0)
	
	revive_modal.visible = false
	victory_modal.visible = false
	
	# Connect Top Bar
	btn_back.pressed.connect(_on_back_pressed)
	btn_share.pressed.connect(_on_share_pressed)
	btn_favorite.pressed.connect(_on_favorite_pressed)
	btn_theme.pressed.connect(_on_theme_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	
	# Connect Action Buttons
	btn_counts.pressed.connect(_on_counts_pressed)
	btn_undo.pressed.connect(_on_undo_pressed)
	btn_erase.pressed.connect(_on_erase_pressed)
	btn_notes.pressed.connect(_on_notes_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	
	# Connect Number Pad (1..9)
	digit_buttons.clear()
	count_labels.clear()
	for i in range(1, 10):
		var btn: Button = number_pad_tray.get_node_or_null("Btn%d" % i) as Button
		if btn:
			digit_buttons.append(btn)
			var d_val: int = i
			btn.pressed.connect(func(): _on_digit_button_pressed(d_val, btn))
			var c_label: Label = btn.get_node_or_null("VBox/CountLabel") as Label
			if c_label:
				count_labels.append(c_label)
	
	# Connect Modals
	btn_revive_coins.pressed.connect(_on_revive_coins_pressed)
	btn_revive_ad.pressed.connect(_on_revive_ad_pressed)
	btn_give_up.pressed.connect(_on_give_up_pressed)
	btn_next_level.pressed.connect(_on_next_level_pressed)
	btn_victory_home.pressed.connect(_on_give_up_pressed)
	
	# Connect Engine & Manager Signals
	if GameManager:
		GameManager.timer_ticked.connect(_on_timer_ticked)
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.mistake_occurred.connect(_on_mistake_occurred)
		GameManager.level_completed.connect(_on_level_completed)
		GameManager.game_over_triggered.connect(_on_game_over)
		_update_hint_count()
		
		# Resume or start game
		if not GameManager.is_game_active:
			GameManager.start_new_game(GameManager.current_game_mode, GameManager.current_level_id)
		else:
			GameManager.resume_timer()
			
	if SudokuEngine:
		SudokuEngine.remaining_counts_updated.connect(_update_remaining_counts)
		_update_notes_button_state()
		if SudokuEngine.cells.is_empty():
			SudokuEngine.load_sample_puzzle("easy")
		else:
			_update_remaining_counts(SudokuEngine.get_remaining_counts())
			
	SignalBus.theme_changed.connect(_on_theme_changed)

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	if window_size.y > 0 and safe_area.size.y > 0:
		var margin_top: int = safe_area.position.y
		var margin_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		$SafeMarginContainer.add_theme_constant_override("margin_top", maxi(40, margin_top))
		$SafeMarginContainer.add_theme_constant_override("margin_bottom", maxi(40, margin_bottom))

func _update_header_info() -> void:
	if not GameManager:
		return
		
	match GameManager.current_game_mode:
		0:
			label_level.text = "Level %d" % GameManager.current_level_id
			diff_label.text = "Easy" if GameManager.current_difficulty <= 1 else ("Medium" if GameManager.current_difficulty == 2 else "Hard")
		1:
			label_level.text = "Level %d" % GameManager.current_level_id
			diff_label.text = "Campaign"
		2:
			label_level.text = "Battle 1v1"
			diff_label.text = "PvP"
		3:
			label_level.text = "Daily"
			diff_label.text = "Challenge"
			
	label_score.text = "Score: %d" % GameManager.current_score

func _on_timer_ticked(formatted_time: String) -> void:
	label_timer.text = formatted_time

func _on_score_updated(new_score: int, _combo: float) -> void:
	label_score.text = "Score: %d" % new_score

func _on_mistake_occurred(current_mistakes: int, _max_mistakes: int) -> void:
	_update_hearts(current_mistakes)

func _update_hearts(mistakes: int) -> void:
	if label_mistakes:
		label_mistakes.text = "Mistakes: %d/3" % mini(3, mistakes)
		
	if mistakes >= 1:
		heart_1.texture = _heart_empty
	else:
		heart_1.texture = _heart_dark
		
	if mistakes >= 2:
		heart_2.texture = _heart_empty
	else:
		heart_2.texture = _heart_dark
		
	if mistakes >= 3:
		heart_3.texture = _heart_empty
	else:
		heart_3.texture = _heart_dark

# ------------------------------------------------------------------------------
# Action Tools & Digits Handling
# ------------------------------------------------------------------------------

func _pop_button(btn: Control) -> void:
	if btn:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		btn.pivot_offset = btn.size / 2.0
		tween.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.06)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

func _on_digit_button_pressed(digit: int, btn: Control) -> void:
	_pop_button(btn)
	if SudokuEngine:
		SudokuEngine.input_digit(digit)

func _on_counts_pressed() -> void:
	_pop_button(btn_counts)
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(20)

func _on_undo_pressed() -> void:
	_pop_button(btn_undo)
	if SudokuEngine:
		SudokuEngine.undo_last_move()

func _on_erase_pressed() -> void:
	_pop_button(btn_erase)
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

func _on_theme_changed(_id: String, _p: Color, _s: Color) -> void:
	_update_notes_button_state()
	if SudokuEngine:
		_update_remaining_counts(SudokuEngine.get_remaining_counts())

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
		
	var key_event: InputEventKey = event as InputEventKey
	var keycode: Key = key_event.keycode
	
	# Digits 1..9
	if keycode >= KEY_1 and keycode <= KEY_9:
		var d: int = int(keycode) - int(KEY_0)
		if SudokuEngine:
			SudokuEngine.input_digit(d)
	elif keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		var d: int = int(keycode) - int(KEY_KP_0)
		if SudokuEngine:
			SudokuEngine.input_digit(d)
	elif keycode == KEY_BACKSPACE or keycode == KEY_DELETE:
		_on_erase_pressed()
	elif keycode == KEY_N:
		_on_notes_pressed()
	elif keycode == KEY_H:
		_on_hint_pressed()
	elif keycode == KEY_Z and key_event.ctrl_pressed:
		_on_undo_pressed()

# ------------------------------------------------------------------------------
# Navigation & Top Bar
# ------------------------------------------------------------------------------

func _on_back_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	_auto_save_active_game()
	if GameManager:
		GameManager.pause_timer()
	get_tree().change_scene_to_file("res://scenes/05_home_main_menu_screen.tscn")

func _auto_save_active_game() -> void:
	if not GameManager or not GameManager.is_game_active:
		return
	var save_dict: Dictionary = {
		"game_mode": GameManager.current_game_mode,
		"level_id": GameManager.current_level_id,
		"score": GameManager.current_score,
		"combo": GameManager.combo_multiplier,
		"mistakes": GameManager.mistakes_count,
		"hints_remaining": GameManager.hints_remaining,
		"elapsed_seconds": GameManager.get_elapsed_seconds(),
		"cells": SudokuEngine.cells if SudokuEngine else []
	}
	if DatabaseManager:
		DatabaseManager.save_active_match(save_dict)

func _on_share_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(30)

func _on_favorite_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	var p_id: String = "puzzle_%d_%d" % [GameManager.current_game_mode if GameManager else 0, GameManager.current_level_id if GameManager else 1]
	var is_fav: bool = false
	if DatabaseManager:
		is_fav = DatabaseManager.toggle_favorite(p_id)
	btn_favorite.modulate = Color(1.0, 0.85, 0.2, 1.0) if is_fav else Color(1, 1, 1, 1)

func _on_theme_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	var cycle: Array[String] = [
		"theme_jk_games",
		"theme_warm_cream",
		"theme_mint_green",
		"theme_charcoal_dark",
		"theme_slate_purple"
	]
	var cur_idx: int = cycle.find(ThemeManager.current_theme_id) if ThemeManager else 0
	var next_idx: int = (cur_idx + 1) % cycle.size() if cur_idx >= 0 else 0
	var next_theme: String = cycle[next_idx]
	if ThemeManager:
		ThemeManager.set_active_theme(next_theme)
	if DatabaseManager:
		DatabaseManager.set_setting("theme", "active_theme_id", next_theme)

func _on_settings_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	_auto_save_active_game()
	get_tree().change_scene_to_file("res://scenes/08_settings_screen.tscn")

# ------------------------------------------------------------------------------
# Game Over & Revive
# ------------------------------------------------------------------------------

func _on_game_over(_reason: String) -> void:
	revive_modal.visible = true
	revive_modal.modulate.a = 0.0
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(revive_modal, "modulate:a", 1.0, 0.2)

func _on_revive_coins_pressed() -> void:
	if GameManager and GameManager.coins_count >= 50:
		GameManager.coins_count -= 50
		GameManager.revive_player_with_life()
		_update_hearts(GameManager.mistakes_count)
		_close_revive_modal()
	else:
		SignalBus.play_sfx.emit("error")
		SignalBus.trigger_haptic.emit(100)

func _on_revive_ad_pressed() -> void:
	if GameManager:
		GameManager.revive_player_with_life()
		_update_hearts(GameManager.mistakes_count)
	_close_revive_modal()

func _close_revive_modal() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(revive_modal, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): revive_modal.visible = false)

func _on_give_up_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	if DatabaseManager:
		DatabaseManager.clear_active_match()
	get_tree().change_scene_to_file("res://scenes/05_home_main_menu_screen.tscn")

# ------------------------------------------------------------------------------
# Victory
# ------------------------------------------------------------------------------

func _on_level_completed(level_id: int, stars: int, score: int, time_seconds: int) -> void:
	if DatabaseManager:
		DatabaseManager.clear_active_match()
		DatabaseManager.unlock_campaign_level(level_id, stars, score, time_seconds)
	if GameManager:
		GameManager.coins_count += 50
	
	var star_str: String = "★★★" if stars == 3 else ("★★☆" if stars == 2 else "★☆☆")
	label_victory_stars.text = star_str
	label_victory_time.text = "Time: %02d:%02d" % [int(time_seconds / 60.0), time_seconds % 60]
	label_victory_score.text = "Score: %d (+50 Coins)" % score
	
	victory_modal.visible = true
	victory_modal.modulate.a = 0.0
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(victory_modal, "modulate:a", 1.0, 0.25)
	SignalBus.play_sfx.emit("victory")

func _on_next_level_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	if GameManager:
		GameManager.current_level_id += 1
		GameManager.start_new_game(GameManager.current_game_mode, GameManager.current_level_id)
	if SudokuEngine:
		SudokuEngine.load_sample_puzzle("medium")
	_update_header_info()
	_update_hearts(0)
	victory_modal.visible = false
