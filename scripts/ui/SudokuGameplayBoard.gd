# SudokuGameplayBoard.gd
# Frame 6: Master Sudoku Gameplay Screen with Timer, Scoring, Mistakes, and Modals
# Matches 3D Sudoku Master Gameplay Board Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var btn_back: Button = $SafeArea/ContentVBox/TopBar/BtnBack
@onready var btn_share: Button = $SafeArea/ContentVBox/TopBar/BtnShare
@onready var btn_favorite: Button = $SafeArea/ContentVBox/TopBar/BtnFavorite
@onready var btn_theme: Button = $SafeArea/ContentVBox/TopBar/BtnTheme
@onready var btn_settings: Button = $SafeArea/ContentVBox/TopBar/BtnSettings

# Stats Bar
@onready var label_score: Label = $SafeArea/ContentVBox/StatsBar/ScoreHBox/ScoreLabel
@onready var label_level: Label = $SafeArea/ContentVBox/StatsBar/LevelLabel
@onready var label_timer: Label = $SafeArea/ContentVBox/StatsBar/TimerLabel

# Status Row
@onready var label_mistakes: Label = $SafeArea/ContentVBox/StatusRow/MistakesHBox/MistakesLabel
@onready var heart_1: TextureRect = $SafeArea/ContentVBox/StatusRow/MistakesHBox/HeartsBox/Heart1
@onready var heart_2: TextureRect = $SafeArea/ContentVBox/StatusRow/MistakesHBox/HeartsBox/Heart2
@onready var heart_3: TextureRect = $SafeArea/ContentVBox/StatusRow/MistakesHBox/HeartsBox/Heart3
@onready var diff_label: Label = $SafeArea/ContentVBox/StatusRow/DifficultyBadge/DiffLabel

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
		
		# Resume timer if active
		if not GameManager.is_game_active:
			GameManager.start_new_game(GameManager.current_game_mode, GameManager.current_level_id)
		else:
			GameManager.resume_timer()
			
	if SudokuEngine and SudokuEngine.cells.is_empty():
		SudokuEngine.load_sample_puzzle("easy")

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	if window_size.y > 0 and safe_area.size.y > 0:
		var margin_top: int = safe_area.position.y
		var margin_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		$SafeArea.add_theme_constant_override("margin_top", maxi(24, margin_top))
		$SafeArea.add_theme_constant_override("margin_bottom", maxi(20, margin_bottom))

func _update_header_info() -> void:
	if not GameManager:
		return
		
	# Level Label
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
		
	# Heart 1
	if mistakes >= 1:
		heart_1.texture = _heart_empty
	else:
		heart_1.texture = _heart_dark
		
	# Heart 2
	if mistakes >= 2:
		heart_2.texture = _heart_empty
	else:
		heart_2.texture = _heart_dark
		
	# Heart 3
	if mistakes >= 3:
		heart_3.texture = _heart_empty
	else:
		heart_3.texture = _heart_dark

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
