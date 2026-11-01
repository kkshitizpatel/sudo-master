# ThemePaletteModal.gd
# Frame 7: Theme Palette Customizer (5 Color Themes, Dark Mode Toggle, Font Size Scale)
# Matches 3D Sudoku Master Theme Palette Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var btn_close: Button = $SafeArea/MainCard/ContentVBox/BtnClose

# Theme Rows
@onready var row_icy_blue: Button = $SafeArea/MainCard/ContentVBox/ThemesList/RowIcyBlue
@onready var row_midnight_dark: Button = $SafeArea/MainCard/ContentVBox/ThemesList/RowMidnightDark
@onready var row_nature_green: Button = $SafeArea/MainCard/ContentVBox/ThemesList/RowNatureGreen
@onready var row_sunset_amber: Button = $SafeArea/MainCard/ContentVBox/ThemesList/RowSunsetAmber
@onready var row_candy_pink: Button = $SafeArea/MainCard/ContentVBox/ThemesList/RowCandyPink

# Labels & Checks
@onready var lbl_icy_blue: Label = $SafeArea/MainCard/ContentVBox/ThemesList/RowIcyBlue/HBox/Label
@onready var chk_icy_blue: TextureRect = $SafeArea/MainCard/ContentVBox/ThemesList/RowIcyBlue/HBox/Check

@onready var lbl_midnight_dark: Label = $SafeArea/MainCard/ContentVBox/ThemesList/RowMidnightDark/HBox/Label
@onready var chk_midnight_dark: TextureRect = $SafeArea/MainCard/ContentVBox/ThemesList/RowMidnightDark/HBox/Check

@onready var lbl_nature_green: Label = $SafeArea/MainCard/ContentVBox/ThemesList/RowNatureGreen/HBox/Label
@onready var chk_nature_green: TextureRect = $SafeArea/MainCard/ContentVBox/ThemesList/RowNatureGreen/HBox/Check

@onready var lbl_sunset_amber: Label = $SafeArea/MainCard/ContentVBox/ThemesList/RowSunsetAmber/HBox/Label
@onready var chk_sunset_amber: TextureRect = $SafeArea/MainCard/ContentVBox/ThemesList/RowSunsetAmber/HBox/Check

@onready var lbl_candy_pink: Label = $SafeArea/MainCard/ContentVBox/ThemesList/RowCandyPink/HBox/Label
@onready var chk_candy_pink: TextureRect = $SafeArea/MainCard/ContentVBox/ThemesList/RowCandyPink/HBox/Check

# Preset Mode & Font Scale
@onready var toggle_dark_mode: CheckButton = $SafeArea/MainCard/ContentVBox/DarkModeRow/ToggleDarkMode
@onready var slider_font: HSlider = $SafeArea/MainCard/ContentVBox/FontSliderRow/HSliderFont

var _style_active: StyleBox = preload("res://assets/themes/theme_row_active.tres")
var _style_normal: StyleBox = preload("res://assets/themes/theme_row_normal.tres")

func _ready() -> void:
	_apply_safe_area()
	btn_close.pressed.connect(_on_close_pressed)
	
	# Connect Theme Rows
	row_icy_blue.pressed.connect(func(): _select_theme("theme_jk_games"))
	row_midnight_dark.pressed.connect(func(): _select_theme("theme_charcoal_dark"))
	row_nature_green.pressed.connect(func(): _select_theme("theme_mint_green"))
	row_sunset_amber.pressed.connect(func(): _select_theme("theme_sunset_amber"))
	row_candy_pink.pressed.connect(func(): _select_theme("theme_candy_pink"))
	
	# Connect Controls
	toggle_dark_mode.toggled.connect(_on_dark_mode_toggled)
	slider_font.value_changed.connect(_on_font_slider_changed)
	
	if ThemeManager:
		slider_font.value = ThemeManager.font_scale_factor
		
	_refresh_theme_ui()

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	if window_size.y > 0 and safe_area.size.y > 0:
		var margin_top: int = safe_area.position.y
		var margin_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		$SafeArea.add_theme_constant_override("margin_top", maxi(32, margin_top))
		$SafeArea.add_theme_constant_override("margin_bottom", maxi(32, margin_bottom))

func _select_theme(theme_id: String) -> void:
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(30)
	
	if ThemeManager:
		ThemeManager.set_active_theme(theme_id)
	if DatabaseManager:
		DatabaseManager.set_setting("theme", "active_theme_id", theme_id)
		
	_refresh_theme_ui()

func _refresh_theme_ui() -> void:
	var active_id: String = "theme_jk_games"
	if ThemeManager:
		active_id = ThemeManager.current_theme_id
		
	# Icy Blue
	var is_icy: bool = (active_id == "theme_jk_games")
	_set_row_state(row_icy_blue, lbl_icy_blue, chk_icy_blue, "Icy Blue", is_icy)
	
	# Midnight Dark
	var is_mid: bool = (active_id == "theme_charcoal_dark")
	_set_row_state(row_midnight_dark, lbl_midnight_dark, chk_midnight_dark, "Midnight Dark", is_mid)
	
	# Nature Green
	var is_nat: bool = (active_id == "theme_mint_green")
	_set_row_state(row_nature_green, lbl_nature_green, chk_nature_green, "Nature Green", is_nat)
	
	# Sunset Amber
	var is_sun: bool = (active_id == "theme_sunset_amber")
	_set_row_state(row_sunset_amber, lbl_sunset_amber, chk_sunset_amber, "Sunset Amber", is_sun)
	
	# Candy Pink
	var is_can: bool = (active_id == "theme_candy_pink")
	_set_row_state(row_candy_pink, lbl_candy_pink, chk_candy_pink, "Candy Pink", is_can)
	
	# Dark mode toggle reflects Midnight Dark
	toggle_dark_mode.set_pressed_no_signal(is_mid)

func _set_row_state(row: Button, lbl: Label, chk: TextureRect, base_name: String, is_active: bool) -> void:
	if is_active:
		row.add_theme_stylebox_override("normal", _style_active)
		row.add_theme_stylebox_override("hover", _style_active)
		row.add_theme_stylebox_override("pressed", _style_active)
		lbl.text = "%s (Current)" % base_name
		chk.visible = true
	else:
		row.add_theme_stylebox_override("normal", _style_normal)
		row.add_theme_stylebox_override("hover", _style_normal)
		row.add_theme_stylebox_override("pressed", _style_normal)
		lbl.text = base_name
		chk.visible = false

func _on_dark_mode_toggled(is_toggled: bool) -> void:
	SignalBus.play_sfx.emit("button_click")
	if is_toggled:
		_select_theme("theme_charcoal_dark")
	else:
		_select_theme("theme_jk_games")

func _on_font_slider_changed(value: float) -> void:
	if ThemeManager:
		ThemeManager.font_scale_factor = value
		ThemeManager.font_scale_applied.emit(value)
	if DatabaseManager:
		DatabaseManager.set_setting("gameplay", "font_scale", value)

func _on_close_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/05_home_main_menu_screen.tscn")
	)
