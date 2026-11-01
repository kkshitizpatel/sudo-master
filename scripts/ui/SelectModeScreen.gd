# SelectModeScreen.gd
# Frame 4: Select Game Mode (Classic, Campaign, 1v1 Battle, Daily Challenge)
# Matches official 3D Sudoku Master Select Mode Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var label_player_name: Label = $SafeArea/MainVBox/TopHeaderRow/RightProfileStack/NameRow/NamePill/PlayerName
@onready var label_player_level: Label = $SafeArea/MainVBox/TopHeaderRow/RightProfileStack/LevelPill/HBox/LevelLabel
@onready var label_coins: Label = $SafeArea/MainVBox/TopHeaderRow/RightProfileStack/ScorePill/HBox/CoinsLabel
@onready var btn_back: Button = $SafeArea/MainVBox/TopHeaderRow/LeftCol/BtnBack

@onready var card_classic: Control = $SafeArea/MainVBox/CenterCard/CardVBox/ModeCardsVBox/CardClassic
@onready var card_campaign: Control = $SafeArea/MainVBox/CenterCard/CardVBox/ModeCardsVBox/CardCampaign
@onready var card_battle: Control = $SafeArea/MainVBox/CenterCard/CardVBox/ModeCardsVBox/CardBattle
@onready var card_daily: Control = $SafeArea/MainVBox/CenterCard/CardVBox/ModeCardsVBox/CardDaily

@onready var btn_mode_classic: Button = $SafeArea/MainVBox/CenterCard/CardVBox/ModeCardsVBox/CardClassic/BtnClassic
@onready var btn_mode_campaign: Button = $SafeArea/MainVBox/CenterCard/CardVBox/ModeCardsVBox/CardCampaign/BtnCampaign
@onready var btn_mode_battle: Button = $SafeArea/MainVBox/CenterCard/CardVBox/ModeCardsVBox/CardBattle/BtnBattle
@onready var btn_mode_daily: Button = $SafeArea/MainVBox/CenterCard/CardVBox/ModeCardsVBox/CardDaily/BtnDaily

@onready var difficulty_popup: Control = $DifficultyModal
@onready var btn_diff_easy: Button = $DifficultyModal/CenterContainer/ModalPanel/VBox/DiffList/BtnEasy
@onready var btn_diff_medium: Button = $DifficultyModal/CenterContainer/ModalPanel/VBox/DiffList/BtnMedium
@onready var btn_diff_hard: Button = $DifficultyModal/CenterContainer/ModalPanel/VBox/DiffList/BtnHard
@onready var btn_diff_close: Button = $DifficultyModal/CenterContainer/ModalPanel/VBox/BtnCloseModal

@onready var tile_8: Control = $FloatingBackground/Tile8
@onready var tile_7: Control = $FloatingBackground/Tile7
@onready var pencil: Control = $FloatingBackground/PencilCenter

var _time_passed: float = 0.0
var _initial_pencil_y: float = 0.0

func _ready() -> void:
	_apply_safe_area()
	_update_header_stats()
	
	if pencil:
		_initial_pencil_y = pencil.position.y
	
	# Connect mode card signals
	btn_back.pressed.connect(_on_back_pressed)
	btn_mode_classic.pressed.connect(func(): _animate_card_and_run(card_classic, _open_difficulty_popup))
	btn_mode_campaign.pressed.connect(func(): _animate_card_and_run(card_campaign, _start_campaign_mode))
	btn_mode_battle.pressed.connect(func(): _animate_card_and_run(card_battle, _start_battle_mode))
	btn_mode_daily.pressed.connect(func(): _animate_card_and_run(card_daily, _start_daily_mode))
	
	# Connect difficulty modal signals
	btn_diff_easy.pressed.connect(func(): _start_classic_game("easy"))
	btn_diff_medium.pressed.connect(func(): _start_classic_game("medium"))
	btn_diff_hard.pressed.connect(func(): _start_classic_game("hard"))
	btn_diff_close.pressed.connect(_close_difficulty_popup)
	
	difficulty_popup.visible = false

func _process(delta: float) -> void:
	_time_passed += delta * 2.0
	
	# Gentle hover on background elements
	if tile_8:
		tile_8.rotation = -0.1 + sin(_time_passed * 0.8) * 0.03
	if tile_7:
		tile_7.rotation = 0.12 + cos(_time_passed * 0.8) * 0.03
	if pencil:
		pencil.position.y = _initial_pencil_y + sin(_time_passed * 1.2) * 5.0

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	if window_size.y > 0 and safe_area.size.y > 0:
		var margin_top: int = safe_area.position.y
		var margin_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		$SafeArea.add_theme_constant_override("margin_top", maxi(36, margin_top))
		$SafeArea.add_theme_constant_override("margin_bottom", maxi(40, margin_bottom))

func _update_header_stats() -> void:
	if GameManager:
		label_player_name.text = GameManager.player_name
		label_player_level.text = "Lv. %d" % GameManager.player_level
		label_coins.text = "Score: %d" % GameManager.high_score

func _animate_card_and_run(card: Control, callback: Callable) -> void:
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(30)
	
	if card:
		var pop_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card.pivot_offset = card.size / 2.0
		pop_tween.tween_property(card, "scale", Vector2(0.97, 0.97), 0.08)
		pop_tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.12)
		pop_tween.tween_callback(callback)
	else:
		callback.call()

func _on_back_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	get_tree().change_scene_to_file("res://scenes/05_home_main_menu_screen.tscn")

# ------------------------------------------------------------------------------
# Mode Selection Handlers
# ------------------------------------------------------------------------------

func _open_difficulty_popup() -> void:
	difficulty_popup.visible = true
	difficulty_popup.modulate.a = 0.0
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(difficulty_popup, "modulate:a", 1.0, 0.2)

func _close_difficulty_popup() -> void:
	SignalBus.play_sfx.emit("button_click")
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(difficulty_popup, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): difficulty_popup.visible = false)

func _start_classic_game(diff_key: String) -> void:
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(30)
	
	var diff_id: int = 1
	if diff_key == "medium":
		diff_id = 2
	elif diff_key == "hard":
		diff_id = 3
		
	GameManager.start_new_game(0, diff_id)
	SudokuEngine.load_sample_puzzle(diff_key)
	_navigate_to_board()

func _start_campaign_mode() -> void:
	var lvl: int = GameManager.current_level_id if GameManager else 1
	GameManager.start_new_game(1, lvl)
	SudokuEngine.load_sample_puzzle("easy" if lvl <= 15 else "medium")
	_navigate_to_board()

func _start_battle_mode() -> void:
	GameManager.start_new_game(2, 1)
	SudokuEngine.load_sample_puzzle("medium")
	_navigate_to_board()

func _start_daily_mode() -> void:
	var date_dict: Dictionary = Time.get_date_dict_from_system()
	var date_str: String = "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]
	GameManager.last_daily_date = date_str
	GameManager.start_new_game(3, 1)
	SudokuEngine.load_sample_puzzle("medium")
	_navigate_to_board()

func _navigate_to_board() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/06_sudoku_gameplay_board.tscn")
	)
