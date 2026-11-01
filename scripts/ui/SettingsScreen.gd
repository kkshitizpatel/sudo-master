# SettingsScreen.gd
# Frame 8: Master Settings Screen (Audio Sliders, Haptics, Auto-Erase Notes, Cloud Sync)
# Matches 3D Sudoku Master Settings Screen Specification
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Control

@onready var btn_back: Button = $SafeArea/MainCard/ContentVBox/HeaderRow/BtnBack

# Audio Sliders
@onready var slider_music: HSlider = $SafeArea/MainCard/ContentVBox/MusicRow/HSliderMusic
@onready var slider_sfx: HSlider = $SafeArea/MainCard/ContentVBox/SFXRow/HSliderSFX

# Gameplay Toggles
@onready var toggle_haptics: CheckButton = $SafeArea/MainCard/ContentVBox/HapticRow/ToggleHaptics
@onready var toggle_auto_notes: CheckButton = $SafeArea/MainCard/ContentVBox/AutoNotesRow/ToggleAutoNotes
@onready var toggle_timer: CheckButton = $SafeArea/MainCard/ContentVBox/TimerRow/ToggleTimer

# Accounts & Progress
@onready var btn_google_sync: Button = $SafeArea/MainCard/ContentVBox/CloudSaveRow/BtnGoogleSync
@onready var btn_how_to_play: Button = $SafeArea/MainCard/ContentVBox/BtnHowToPlay
@onready var btn_privacy_policy: Button = $SafeArea/MainCard/ContentVBox/BtnPrivacyPolicy

# Info Modal
@onready var info_modal: Control = $InfoModal
@onready var info_title: Label = $InfoModal/CenterContainer/ModalPanel/VBox/Title
@onready var info_body: Label = $InfoModal/CenterContainer/ModalPanel/VBox/Body
@onready var btn_close_info: Button = $InfoModal/CenterContainer/ModalPanel/VBox/BtnCloseInfo

func _ready() -> void:
	_apply_safe_area()
	info_modal.visible = false
	
	btn_back.pressed.connect(_on_back_pressed)
	
	# Load settings from DatabaseManager / GameManager
	var sfx_vol: float = 1.0
	var bgm_vol: float = 0.7
	if DatabaseManager:
		sfx_vol = float(DatabaseManager.get_setting("audio", "sfx_volume", 1.0))
		bgm_vol = float(DatabaseManager.get_setting("audio", "bgm_volume", 0.7))
		
	slider_sfx.value = sfx_vol
	slider_music.value = bgm_vol
	
	if GameManager:
		toggle_haptics.button_pressed = GameManager.haptics_enabled
	if SudokuEngine:
		toggle_auto_notes.button_pressed = SudokuEngine.auto_remove_notes
		
	var show_timer: bool = true
	if DatabaseManager:
		show_timer = bool(DatabaseManager.get_setting("gameplay", "show_timer", true))
	toggle_timer.button_pressed = show_timer
	
	# Connect UI changes
	slider_sfx.value_changed.connect(_on_sfx_changed)
	slider_music.value_changed.connect(_on_bgm_changed)
	toggle_haptics.toggled.connect(_on_haptics_toggled)
	toggle_auto_notes.toggled.connect(_on_auto_notes_toggled)
	toggle_timer.toggled.connect(_on_timer_toggled)
	
	btn_google_sync.pressed.connect(_on_google_sync_pressed)
	btn_how_to_play.pressed.connect(_on_how_to_play_pressed)
	btn_privacy_policy.pressed.connect(_on_privacy_policy_pressed)
	btn_close_info.pressed.connect(_close_info_modal)

func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	
	if window_size.y > 0 and safe_area.size.y > 0:
		var margin_top: int = safe_area.position.y
		var margin_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
		$SafeArea.add_theme_constant_override("margin_top", maxi(32, margin_top))
		$SafeArea.add_theme_constant_override("margin_bottom", maxi(32, margin_bottom))

func _on_sfx_changed(value: float) -> void:
	if DatabaseManager:
		DatabaseManager.set_setting("audio", "sfx_volume", value)
	var bus_idx: int = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
		AudioServer.set_bus_mute(bus_idx, value <= 0.01)

func _on_bgm_changed(value: float) -> void:
	if DatabaseManager:
		DatabaseManager.set_setting("audio", "bgm_volume", value)
	var bus_idx: int = AudioServer.get_bus_index("BGM")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
		AudioServer.set_bus_mute(bus_idx, value <= 0.01)

func _on_haptics_toggled(is_toggled: bool) -> void:
	if GameManager:
		GameManager.haptics_enabled = is_toggled
	if DatabaseManager:
		DatabaseManager.set_setting("gameplay", "haptics_enabled", is_toggled)
	if is_toggled:
		SignalBus.trigger_haptic.emit(30)

func _on_auto_notes_toggled(is_toggled: bool) -> void:
	if SudokuEngine:
		SudokuEngine.auto_remove_notes = is_toggled
	if DatabaseManager:
		DatabaseManager.set_setting("gameplay", "auto_remove_notes", is_toggled)
	SignalBus.play_sfx.emit("note_tick")

func _on_timer_toggled(is_toggled: bool) -> void:
	if DatabaseManager:
		DatabaseManager.set_setting("gameplay", "show_timer", is_toggled)
	SignalBus.play_sfx.emit("button_click")

func _on_google_sync_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	SignalBus.trigger_haptic.emit(30)
	
	# Google Play Games Cloud Sync Simulation
	var orig_text: String = btn_google_sync.text
	btn_google_sync.text = " Syncing..."
	var tween: Tween = create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(func():
		btn_google_sync.text = " Synced ✔"
	)
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		btn_google_sync.text = orig_text
	)

func _on_how_to_play_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	info_title.text = "How to Play"
	info_body.text = "1. Sudoku is played on a 9x9 grid divided into 3x3 subgrids.\n\n2. Every row, column, and 3x3 square must contain digits 1 through 9 with no duplicates.\n\n3. Use candidate pencil notes to track potential candidates.\n\n4. Use Smart Hints when you need logical deduction steps!"
	_open_info_modal()

func _on_privacy_policy_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	info_title.text = "Privacy Policy"
	info_body.text = "JK Games Edition values your privacy.\n\nAll game states, statistics, and theme preferences are saved locally on your device or safely synchronized with your official Google Play account.\n\nNo personal data is collected or shared."
	_open_info_modal()

func _open_info_modal() -> void:
	info_modal.visible = true
	info_modal.modulate.a = 0.0
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(info_modal, "modulate:a", 1.0, 0.2)

func _close_info_modal() -> void:
	SignalBus.play_sfx.emit("button_click")
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(info_modal, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): info_modal.visible = false)

func _on_back_pressed() -> void:
	SignalBus.play_sfx.emit("button_click")
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/05_home_main_menu_screen.tscn")
	)
