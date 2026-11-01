# MainMenuScreen.gd
# Frame 5: Home / Main Menu Screen & Central Hub
# Matches official 3D Sudoku Master Home Screen Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var label_player_level: Label = $SafeArea/MainVBox/TopBar/LevelPill/HBox/LevelLabel
@onready var label_score: Label = $SafeArea/MainVBox/TopBar/ScorePill/HBox/ScoreLabel
@onready var btn_settings: Button = $SafeArea/MainVBox/TopBar/BtnSettings

@onready var btn_continue: Button = $SafeArea/MainVBox/ActionCard/ActionVBox/BtnContinue
@onready var btn_new_game: Button = $SafeArea/MainVBox/ActionCard/ActionVBox/BtnNewGame

# Dock navigation buttons
@onready var dock_btn_home: Button = $BottomDock/HBox/BtnDockHome
@onready var dock_btn_leaderboard: Button = $BottomDock/HBox/BtnDockLeaderboard
@onready var dock_btn_stats: Button = $BottomDock/HBox/BtnDockStats
@onready var dock_btn_profile: Button = $BottomDock/HBox/BtnDockProfile

# Floating background elements
@onready var tile_5: Control = $FloatingBackground/Tile5
@onready var tile_3: Control = $FloatingBackground/Tile3
@onready var tile_8: Control = $FloatingBackground/Tile8
@onready var tile_7: Control = $FloatingBackground/Tile7

var _time_passed: float = 0.0

func _ready() -> void:
	_apply_safe_area()
	_update_profile_stats()
	_check_saved_match_state()
	
	# Connect buttons
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_settings.pressed.connect(_open_settings)
	
	dock_btn_home.pressed.connect(_on_home_tab_pressed)
	dock_btn_leaderboard.pressed.connect(_open_leaderboard)
	dock_btn_stats.pressed.connect(_open_stats)
	dock_btn_profile.pressed.connect(_open_profile)

func _process(delta: float) -> void:
	_time_passed += delta * 2.0
	
	# Gentle hover on background elements
	if tile_5:
		tile_5.rotation = -0.12 + sin(_time_passed * 0.8) * 0.03
	if tile_3:
		tile_3.rotation = 0.14 + cos(_time_passed * 0.8) * 0.03
	if tile_8:
		tile_8.rotation = -0.1 + sin(_time_passed * 0.7 + 1.0) * 0.03
	if tile_7:
		tile_7.rotation = 0.12 + cos(_time_passed * 0.7 + 1.0) * 0.03

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	if window_size.y > 0 and safe_area.size.y > 0:
		var margin_top: int = safe_area.position.y
		var margin_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		$SafeArea.add_theme_constant_override("margin_top", maxi(56, margin_top))
		$SafeArea.add_theme_constant_override("margin_bottom", maxi(200, margin_bottom))

func _update_profile_stats() -> void:
	if GameManager:
		label_player_level.text = "Level %d" % GameManager.player_level
		label_score.text = "Score: %d" % GameManager.high_score

func _check_saved_match_state() -> void:
	var saved_match: Dictionary = {}
	if DatabaseManager:
		saved_match = DatabaseManager.load_active_match()
	
	var has_saved: bool = saved_match.get("has_active_match", false)
	# Both buttons are always active and interactive
	if has_saved:
		btn_continue.modulate.a = 1.0
	else:
		btn_continue.modulate.a = 0.95

func _animate_press(node: Control, callback: Callable) -> void:
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(30)
	
	if node:
		var pop_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		node.pivot_offset = node.size / 2.0
		pop_tween.tween_property(node, "scale", Vector2(0.96, 0.96), 0.08)
		pop_tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.12)
		pop_tween.tween_callback(callback)
	else:
		callback.call()

func _on_continue_pressed() -> void:
	_animate_press(btn_continue, func():
		var saved_match: Dictionary = {}
		if DatabaseManager:
			saved_match = DatabaseManager.load_active_match()
		
		if not saved_match.is_empty() and saved_match.get("has_active_match", false):
			GameManager.current_game_mode = saved_match.get("game_mode", 0)
			GameManager.current_level_id = saved_match.get("level_id", 1)
			GameManager.current_score = saved_match.get("score", 0)
			GameManager.combo_multiplier = saved_match.get("combo", 1.0)
			GameManager.mistakes_count = saved_match.get("mistakes", 0)
			GameManager.hints_remaining = saved_match.get("hints_remaining", 3)
			GameManager.active_accumulated_ms = saved_match.get("elapsed_seconds", 0) * 1000
			GameManager.is_game_active = true
			GameManager.is_game_paused = false
			GameManager.last_resume_tick = Time.get_ticks_msec()
			SudokuEngine.load_sample_puzzle("medium")
			_transition_to_scene("res://scenes/06_sudoku_gameplay_board.tscn")
		else:
			# If no saved match, start fresh Classic game
			GameManager.start_new_game(0, 1)
			SudokuEngine.load_sample_puzzle("easy")
			_transition_to_scene("res://scenes/06_sudoku_gameplay_board.tscn")
	)

func _on_new_game_pressed() -> void:
	_animate_press(btn_new_game, func():
		_transition_to_scene("res://scenes/04_select_game_mode_screen.tscn")
	)

func _on_home_tab_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	# Already on Home screen

func _open_leaderboard() -> void:
	SignalBus.play_sfx.emit("button_click")
	# Future Leaderboard modal / view

func _open_stats() -> void:
	SignalBus.play_sfx.emit("button_click")
	# Future Stats modal / view

func _open_profile() -> void:
	SignalBus.play_sfx.emit("button_click")
	# Future Profile view

func _open_settings() -> void:
	_animate_press(btn_settings, func():
		_transition_to_scene("res://scenes/08_settings_screen.tscn")
	)

func _transition_to_scene(target_path: String) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(target_path)
	)
