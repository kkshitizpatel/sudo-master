# SplashScreen.gd
# Frame 1: JK Games Splash Screen & Pre-flight Asset Loader
# Matches official JK Games 3D Splash Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var hero_card: PanelContainer = $SafeArea/MainVBox/HeroContainer/HeroCard
@onready var logo_icon: TextureRect = $SafeArea/MainVBox/HeroContainer/HeroCard/LogoContainer/LogoIcon
@onready var spinner_icon: TextureRect = $SafeArea/MainVBox/BottomLoadingSection/StatusRow/StatusLeft/SpinnerIcon
@onready var status_label: Label = $SafeArea/MainVBox/BottomLoadingSection/StatusRow/StatusLeft/StatusLabel
@onready var percent_label: Label = $SafeArea/MainVBox/BottomLoadingSection/StatusRow/PercentLabel
@onready var progress_bar: ProgressBar = $SafeArea/MainVBox/BottomLoadingSection/ProgressBar

var _boot_tween: Tween = null
var _is_spinning: bool = true

func _ready() -> void:
	_apply_safe_area()
	
	# Initial visual states
	hero_card.modulate.a = 0.0
	hero_card.scale = Vector2(0.96, 0.96)
	hero_card.pivot_offset = hero_card.custom_minimum_size / 2.0
	
	progress_bar.value = 0.0
	percent_label.text = "0%"
	status_label.text = "Initializing engine..."
	
	_start_boot_sequence()

func _process(delta: float) -> void:
	if _is_spinning and spinner_icon:
		spinner_icon.rotation += delta * 4.5

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	if window_size.y > 0 and safe_area.size.y > 0:
		var margin_top: int = safe_area.position.y
		var margin_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		$SafeArea.add_theme_constant_override("margin_top", maxi(36, margin_top))
		$SafeArea.add_theme_constant_override("margin_bottom", maxi(40, margin_bottom))

func _start_boot_sequence() -> void:
	_boot_tween = create_tween()
	
	# 1. Hero Card Pop & Fade In
	var intro_tween: Tween = create_tween().set_parallel(true)
	intro_tween.tween_property(hero_card, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(hero_card, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. Stage 1: 0% -> 45%
	_boot_tween.tween_method(
		func(v: float):
			progress_bar.value = v
			percent_label.text = "%d%%" % int(v),
		0.0, 45.0, 0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_boot_tween.tween_callback(func(): status_label.text = "Loading visual assets & themes...")
	
	# 3. Stage 2: 45% -> 80%
	_boot_tween.tween_method(
		func(v: float):
			progress_bar.value = v
			percent_label.text = "%d%%" % int(v),
		45.0, 80.0, 0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_boot_tween.tween_callback(func(): status_label.text = "Preparing puzzle matrices...")
	
	# 4. Stage 3: 80% -> 100%
	_boot_tween.tween_method(
		func(v: float):
			progress_bar.value = v
			percent_label.text = "%d%%" % int(v),
		80.0, 100.0, 0.35
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_boot_tween.tween_callback(func():
		status_label.text = "Ready to Play!"
		percent_label.text = "100%"
	)
	
	# 5. Dwell time before smooth transition
	_boot_tween.tween_interval(0.3)
	_boot_tween.tween_callback(_on_boot_completed)

func _on_boot_completed() -> void:
	_is_spinning = false
	var terms_accepted: bool = GameManager.has_accepted_terms if GameManager else false
	
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_callback(func():
		if not terms_accepted:
			get_tree().change_scene_to_file("res://scenes/02_welcome_onboarding_screen.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/05_home_main_menu_screen.tscn")
	)
