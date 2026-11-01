# ClaimLevelScreen.gd
# Frame 3: Claim Your Level (Skill Placement & Instant Calibration)
# Matches official 3D Sudoku Master Claim Level Screen Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var btn_tier_1: Button = $SafeArea/MainVBox/CenterCard/TiersVBox/Tier1Card/BtnSelectTier1
@onready var btn_tier_2: Button = $SafeArea/MainVBox/CenterCard/TiersVBox/Tier2Card/BtnSelectTier2
@onready var btn_tier_3: Button = $SafeArea/MainVBox/CenterCard/TiersVBox/Tier3Card/BtnSelectTier3
@onready var btn_tier_4: Button = $SafeArea/MainVBox/CenterCard/TiersVBox/Tier4Card/BtnSelectTier4

@onready var tile_8: Control = $FloatingBackground/Tile8
@onready var tile_7: Control = $FloatingBackground/Tile7
@onready var pencil: Control = $FloatingBackground/PencilCenter

var _time_passed: float = 0.0
var _initial_pencil_y: float = 0.0

func _ready() -> void:
	_apply_safe_area()
	
	btn_tier_1.pressed.connect(func(): _select_tier(1, $SafeArea/MainVBox/CenterCard/TiersVBox/Tier1Card))
	btn_tier_2.pressed.connect(func(): _select_tier(15, $SafeArea/MainVBox/CenterCard/TiersVBox/Tier2Card))
	btn_tier_3.pressed.connect(func(): _select_tier(30, $SafeArea/MainVBox/CenterCard/TiersVBox/Tier3Card))
	btn_tier_4.pressed.connect(func(): _select_tier(50, $SafeArea/MainVBox/CenterCard/TiersVBox/Tier4Card))
	
	if pencil:
		_initial_pencil_y = pencil.position.y

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

func _select_tier(target_level: int, card_node: Control) -> void:
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(30)
	
	# Card bounce pop animation
	if card_node:
		var pop_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_node.pivot_offset = card_node.size / 2.0
		pop_tween.tween_property(card_node, "scale", Vector2(0.97, 0.97), 0.08)
		pop_tween.tween_property(card_node, "scale", Vector2(1.0, 1.0), 0.12)
	
	# Mark placement completed
	if GameManager:
		GameManager.has_completed_placement = true
	if DatabaseManager:
		DatabaseManager.set_setting("gameplay", "has_completed_placement", true)
	
	if target_level > 1:
		# Unlock all levels up to target level with default 2 stars
		if DatabaseManager:
			DatabaseManager.batch_unlock_levels(target_level, 2)
		if GameManager:
			GameManager.current_level_id = target_level
	else:
		if GameManager:
			GameManager.current_level_id = 1
		
	# Transition smoothly to Frame 5: Main Menu
	var tween: Tween = create_tween()
	tween.tween_interval(0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/05_home_main_menu_screen.tscn")
	)
