# AuroraBackground.gd
# Dynamic Aurora Ambient Glow background component
# Smoothly interpolates shader parameters on theme switches
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var background_rect: ColorRect = $BackgroundRect
var _current_tween: Tween = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	SignalBus.theme_changed.connect(_on_theme_changed)
	call_deferred("_apply_initial_theme")

func _apply_initial_theme() -> void:
	_apply_theme_from_manager(0.0)

func _on_theme_changed(_theme_id: String, _primary: Color, _secondary: Color) -> void:
	_apply_theme_from_manager(0.25)

func _apply_theme_from_manager(duration: float = 0.25) -> void:
	if not background_rect or not background_rect.material:
		return
		
	var mat: ShaderMaterial = background_rect.material as ShaderMaterial
	if not mat:
		return
		
	if not ThemeManager:
		return
		
	var t: Dictionary = ThemeManager.get_active_theme()
	var bg_top: Color = t.get("bg_canvas", Color("#ebf3fa"))
	var bg_bottom: Color = t.get("bg_canvas_bottom", Color("#f8fafc"))
	var primary: Color = t.get("primary_accent", Color("#1d4ed8"))
	var secondary: Color = t.get("secondary_glow", Color("#38bdf8"))
	var is_dark: bool = t.get("is_dark", false)
	
	mat.set_shader_parameter("is_dark", is_dark)
	
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		
	if duration <= 0.0:
		mat.set_shader_parameter("color_bg", bg_top)
		mat.set_shader_parameter("color_bg_bottom", bg_bottom)
		mat.set_shader_parameter("color_primary", primary)
		mat.set_shader_parameter("color_secondary", secondary)
		return
		
	var cur_bg_top_val: Variant = mat.get_shader_parameter("color_bg")
	var cur_bg_top: Color = cur_bg_top_val if cur_bg_top_val is Color else bg_top
	
	var cur_bg_bot_val: Variant = mat.get_shader_parameter("color_bg_bottom")
	var cur_bg_bot: Color = cur_bg_bot_val if cur_bg_bot_val is Color else bg_bottom
	
	var cur_p_val: Variant = mat.get_shader_parameter("color_primary")
	var cur_p: Color = cur_p_val if cur_p_val is Color else primary
	
	var cur_s_val: Variant = mat.get_shader_parameter("color_secondary")
	var cur_s: Color = cur_s_val if cur_s_val is Color else secondary
	
	_current_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_current_tween.tween_method(func(c: Color): mat.set_shader_parameter("color_bg", c), cur_bg_top, bg_top, duration)
	_current_tween.tween_method(func(c: Color): mat.set_shader_parameter("color_bg_bottom", c), cur_bg_bot, bg_bottom, duration)
	_current_tween.tween_method(func(c: Color): mat.set_shader_parameter("color_primary", c), cur_p, primary, duration)
	_current_tween.tween_method(func(c: Color): mat.set_shader_parameter("color_secondary", c), cur_s, secondary, duration)
