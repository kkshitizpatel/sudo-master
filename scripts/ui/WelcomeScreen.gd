# WelcomeScreen.gd
# Frame 2: Welcome, Terms Agreement & First-Time Onboarding
# Matches official 3D Sudoku Master Welcome Screen Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var hero_badge: Control = $SafeArea/MainVBox/HeroBadgeArea/BadgeWrapper
@onready var btn_accept: Button = $SafeArea/MainVBox/DialogCard/DialogVBox/BtnAccept
@onready var tile_5: Control = $FloatingDecorations/Tile5
@onready var tile_3: Control = $FloatingDecorations/Tile3
@onready var tile_8: Control = $FloatingDecorations/Tile8
@onready var tile_7: Control = $FloatingDecorations/Tile7
@onready var pencil: Control = $FloatingDecorations/PencilCenter

var _time_passed: float = 0.0
var _initial_badge_y: float = 0.0
var _initial_pencil_y: float = 0.0

func _ready() -> void:
	_apply_safe_area()
	btn_accept.pressed.connect(_on_accept_pressed)
	
	_initial_badge_y = hero_badge.position.y
	_initial_pencil_y = pencil.position.y

func _process(delta: float) -> void:
	_time_passed += delta * 2.0
	
	# Gentle breathing hover animation on central badge
	if hero_badge:
		hero_badge.position.y = _initial_badge_y + sin(_time_passed) * 6.0
	
	# Gentle hover on floating number tiles
	if tile_5:
		tile_5.rotation = -0.14 + sin(_time_passed * 0.8) * 0.04
	if tile_3:
		tile_3.rotation = 0.14 + cos(_time_passed * 0.8) * 0.04
	if pencil:
		pencil.position.y = _initial_pencil_y + sin(_time_passed * 1.2) * 5.0

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	if window_size.y > 0 and safe_area.size.y > 0:
		var margin_top: int = safe_area.position.y
		var margin_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		$SafeArea.add_theme_constant_override("margin_top", maxi(40, margin_top))
		$SafeArea.add_theme_constant_override("margin_bottom", maxi(48, margin_bottom))

func _on_accept_pressed() -> void:
	# Persist state flag in GameManager and config file
	if GameManager:
		GameManager.has_accepted_terms = true
	if DatabaseManager:
		DatabaseManager.set_setting("gameplay", "has_accepted_terms", true)
	
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(30)
	
	# Button bounce effect
	var pop_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	btn_accept.pivot_offset = btn_accept.size / 2.0
	pop_tween.tween_property(btn_accept, "scale", Vector2(0.96, 0.96), 0.08)
	pop_tween.tween_property(btn_accept, "scale", Vector2(1.0, 1.0), 0.12)
	
	# Smooth cross-fade to Frame 3: Claim Your Level
	var tween: Tween = create_tween()
	tween.tween_interval(0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/03_claim_your_level_screen.tscn")
	)
