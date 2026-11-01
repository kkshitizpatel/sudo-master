# ThemeManager.gd
# Dynamic Theme Engine & Palette Customizer for Godot Sudoku
# JK Games Sky Blue (Default) and 5 Selectable Mode Themes
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Node

signal theme_applied(theme_id: String, primary_color: Color, secondary_color: Color)
signal font_scale_applied(new_scale: float)

var current_theme_id: String = "theme_jk_games"
var font_scale_factor: float = 1.0 # 0.85 (Small), 1.0 (Medium), 1.2 (Large)
var sync_with_os_dark_mode: bool = false

# Cached runtime StyleBoxes for zero-allocation instant theme switching
var _style_cell_normal: StyleBoxFlat = StyleBoxFlat.new()
var _style_cell_clue: StyleBoxFlat = StyleBoxFlat.new()
var _style_cell_selected: StyleBoxFlat = StyleBoxFlat.new()
var _style_cell_match: StyleBoxFlat = StyleBoxFlat.new()
var _style_cell_peer: StyleBoxFlat = StyleBoxFlat.new()
var _style_cell_error: StyleBoxFlat = StyleBoxFlat.new()
var _style_board_panel: StyleBoxFlat = StyleBoxFlat.new()

var themes_catalog: Dictionary = {
	"theme_jk_games": {
		"id": "theme_jk_games",
		"name": "Icy Blue",
		"is_dark": false,
		"primary_accent": Color("#1D4ED8"),      # Royal Vibrant Blue
		"secondary_glow": Color("#38BDF8"),      # Sky Cyan Glow
		"bg_canvas": Color("#CDE5FA"),          # Fresh Crystal Sky Blue (Top)
		"bg_canvas_bottom": Color("#EDF5FE"),   # Soft Off-White Ice Blue (Bottom)
		"board_frame": Color("#242D3D"),        # Deep Charcoal Navy
		"major_grid": Color("#242D3D"),         # 3x3 Major Grid Lines (3.5 dp)
		"minor_grid": Color("#5B6980"),         # 1x1 Minor Cell Lines (1.2 dp)
		"cell_bg": Color("#FFFFFF"),            # Pure Soft White
		"cell_clue_bg": Color("#F1F5F9"),       # Pre-filled Locked Clues
		"cell_selected": Color("#BFDBFE"),      # Active Selected Cell
		"cell_match": Color("#DBEAFE"),         # Matching Number Cells
		"cell_peer": Color("#EFF6FF"),          # Row / Col / Box Peers
		"cell_error": Color("#FEE2E2"),         # Soft Rose Mistake
		"clue_text": Color("#111827"),          # Given Puzzle Clues (Charcoal Bubble Black)
		"user_text": Color("#1D4ED8"),          # User Correct Digits (Royal Vibrant Blue)
		"error_text": Color("#DC2626"),         # Mistake / Error Digits (Crimson Error Red)
		"notes_text": Color("#6B7280"),         # Candidate Pencil Notes (Medium Slate Gray)
		"score_orange": Color("#F97316"),       # Score & Daily Streak (Pumpkin Orange)
		"success_green": Color("#10B981"),      # Level Victory & Pass (Success Emerald Green)
		"hints_amber": Color("#F59E0B"),        # Smart Hints Badge (Golden Amber)
		"heart_red": Color("#EF4444"),          # 3-Mistakes Hearts (Vivid Heart Red)
		"pill_bg": Color("#1E293B"),            # Controls Pill Background (Deep Slate Pill)
		"text_primary": Color("#111827"),
		"text_secondary": Color("#4B5563")
	},
	"theme_charcoal_dark": {
		"id": "theme_charcoal_dark",
		"name": "Midnight Dark",
		"is_dark": true,
		"primary_accent": Color("#60A5FA"),      # Neon Sky Blue
		"secondary_glow": Color("#3B82F6"),      # Electric Indigo
		"bg_canvas": Color("#1E293B"),          # Dark Slate Top
		"bg_canvas_bottom": Color("#0F172A"),   # Dark Slate Bottom
		"board_frame": Color("#020617"),        # Pure Dark Navy Frame
		"major_grid": Color("#020617"),
		"minor_grid": Color("#334155"),
		"cell_bg": Color("#334155"),
		"cell_clue_bg": Color("#1E293B"),
		"cell_selected": Color("#1E3A8A"),
		"cell_match": Color("#172554"),
		"cell_peer": Color("#0F172A"),
		"cell_error": Color("#7F1D1D"),
		"clue_text": Color("#F8FAFC"),
		"user_text": Color("#60A5FA"),
		"error_text": Color("#EF4444"),
		"notes_text": Color("#94A3B8"),
		"score_orange": Color("#F97316"),
		"success_green": Color("#10B981"),
		"hints_amber": Color("#F59E0B"),
		"heart_red": Color("#EF4444"),
		"pill_bg": Color("#0F172A"),
		"text_primary": Color("#F8FAFC"),
		"text_secondary": Color("#94A3B8")
	},
	"theme_mint_green": {
		"id": "theme_mint_green",
		"name": "Nature Green",
		"is_dark": false,
		"primary_accent": Color("#059669"),      # Fresh Emerald Green
		"secondary_glow": Color("#10B981"),      # Mint Leaf
		"bg_canvas": Color("#EDF7F2"),          # Sage Relax Top
		"bg_canvas_bottom": Color("#E0F2E9"),   # Sage Relax Bottom
		"board_frame": Color("#1E3A2F"),        # Deep Forest Frame
		"major_grid": Color("#1E3A2F"),
		"minor_grid": Color("#527869"),
		"cell_bg": Color("#FAFCFA"),
		"cell_clue_bg": Color("#E8F3ED"),
		"cell_selected": Color("#A7F3D0"),
		"cell_match": Color("#C6F6D5"),
		"cell_peer": Color("#F0FDF4"),
		"cell_error": Color("#FEE2E2"),
		"clue_text": Color("#132A20"),
		"user_text": Color("#059669"),
		"error_text": Color("#DC2626"),
		"notes_text": Color("#4B7361"),
		"score_orange": Color("#F97316"),
		"success_green": Color("#10B981"),
		"hints_amber": Color("#F59E0B"),
		"heart_red": Color("#EF4444"),
		"pill_bg": Color("#1E3A2F"),
		"text_primary": Color("#132A20"),
		"text_secondary": Color("#3E6152")
	},
	"theme_sunset_amber": {
		"id": "theme_sunset_amber",
		"name": "Sunset Amber",
		"is_dark": false,
		"primary_accent": Color("#F97316"),
		"secondary_glow": Color("#FBBF24"),
		"bg_canvas": Color("#FFFBEB"),
		"bg_canvas_bottom": Color("#FEF3C7"),
		"board_frame": Color("#78350F"),
		"major_grid": Color("#78350F"),
		"minor_grid": Color("#B45309"),
		"cell_bg": Color("#FFFFFF"),
		"cell_clue_bg": Color("#FEF3C7"),
		"cell_selected": Color("#FED7AA"),
		"cell_match": Color("#FFEDD5"),
		"cell_peer": Color("#FFFBEB"),
		"cell_error": Color("#FEE2E2"),
		"clue_text": Color("#451A03"),
		"user_text": Color("#C2410C"),
		"error_text": Color("#DC2626"),
		"notes_text": Color("#9A3412"),
		"score_orange": Color("#F97316"),
		"success_green": Color("#10B981"),
		"hints_amber": Color("#F59E0B"),
		"heart_red": Color("#EF4444"),
		"pill_bg": Color("#78350F"),
		"text_primary": Color("#451A03"),
		"text_secondary": Color("#9A3412")
	},
	"theme_candy_pink": {
		"id": "theme_candy_pink",
		"name": "Candy Pink",
		"is_dark": false,
		"primary_accent": Color("#F43F5E"),
		"secondary_glow": Color("#FECDD3"),
		"bg_canvas": Color("#FFF1F2"),
		"bg_canvas_bottom": Color("#FFE4E6"),
		"board_frame": Color("#881337"),
		"major_grid": Color("#881337"),
		"minor_grid": Color("#BE123C"),
		"cell_bg": Color("#FFFFFF"),
		"cell_clue_bg": Color("#FFE4E6"),
		"cell_selected": Color("#FECDD3"),
		"cell_match": Color("#FFE4E6"),
		"cell_peer": Color("#FFF1F2"),
		"cell_error": Color("#FEE2E2"),
		"clue_text": Color("#4C0519"),
		"user_text": Color("#E11D48"),
		"error_text": Color("#DC2626"),
		"notes_text": Color("#9F1239"),
		"score_orange": Color("#F97316"),
		"success_green": Color("#10B981"),
		"hints_amber": Color("#F59E0B"),
		"heart_red": Color("#EF4444"),
		"pill_bg": Color("#881337"),
		"text_primary": Color("#4C0519"),
		"text_secondary": Color("#9F1239")
	},
	"theme_warm_cream": {
		"id": "theme_warm_cream",
		"name": "Warm Cream Paper",
		"is_dark": false,
		"primary_accent": Color("#8D5B4C"),      # Warm Espresso Brown
		"secondary_glow": Color("#D4A373"),      # Warm Sand
		"bg_canvas": Color("#FDFBF7"),          # Cozy Paper Top
		"bg_canvas_bottom": Color("#F4EFE6"),   # Cozy Paper Bottom
		"board_frame": Color("#4A3E39"),        # Warm Dark Brown Frame
		"major_grid": Color("#4A3E39"),
		"minor_grid": Color("#8C7E75"),
		"cell_bg": Color("#FFFDF9"),
		"cell_clue_bg": Color("#F5EFEB"),
		"cell_selected": Color("#EAD7C5"),
		"cell_match": Color("#F2E5D5"),
		"cell_peer": Color("#FAF5EE"),
		"cell_error": Color("#FDE2E2"),
		"clue_text": Color("#2D211C"),
		"user_text": Color("#8D5B4C"),
		"error_text": Color("#DC2626"),
		"notes_text": Color("#7D6F66"),
		"score_orange": Color("#F97316"),
		"success_green": Color("#10B981"),
		"hints_amber": Color("#F59E0B"),
		"heart_red": Color("#EF4444"),
		"pill_bg": Color("#4A3E39"),
		"text_primary": Color("#2D211C"),
		"text_secondary": Color("#695B53")
	},
	"theme_slate_purple": {
		"id": "theme_slate_purple",
		"name": "Slate Purple Violet",
		"is_dark": false,
		"primary_accent": Color("#7C3AED"),      # Royal Purple
		"secondary_glow": Color("#A855F7"),      # Neon Violet
		"bg_canvas": Color("#F3E8FF"),          # Royal Lilac Top
		"bg_canvas_bottom": Color("#EDE9FE"),   # Royal Lilac Bottom
		"board_frame": Color("#3B185F"),        # Deep Violet Frame
		"major_grid": Color("#3B185F"),
		"minor_grid": Color("#6D488C"),
		"cell_bg": Color("#FAF5FF"),
		"cell_clue_bg": Color("#EFE4FD"),
		"cell_selected": Color("#DDD6FE"),
		"cell_match": Color("#E9D5FF"),
		"cell_peer": Color("#F5EEFE"),
		"cell_error": Color("#FEE2E2"),
		"clue_text": Color("#240F3B"),
		"user_text": Color("#7C3AED"),
		"error_text": Color("#DC2626"),
		"notes_text": Color("#7C5C9E"),
		"score_orange": Color("#F97316"),
		"success_green": Color("#10B981"),
		"hints_amber": Color("#F59E0B"),
		"heart_red": Color("#EF4444"),
		"pill_bg": Color("#3B185F"),
		"text_primary": Color("#240F3B"),
		"text_secondary": Color("#6B478B")
	},
	"theme_aero": {
		"id": "theme_aero",
		"name": "Aero Indigo Dark",
		"is_dark": true,
		"primary_accent": Color("#38bdf8"),
		"secondary_glow": Color("#4338ca"),
		"bg_canvas": Color("#0b0f19"),
		"bg_canvas_bottom": Color("#06080e"),
		"board_frame": Color("#0f172a"),
		"major_grid": Color("#0f172a"),
		"minor_grid": Color("#1e293b"),
		"cell_bg": Color("#111827"),
		"cell_clue_bg": Color("#0b0f19"),
		"cell_selected": Color("#1e3a8a"),
		"cell_match": Color("#1e293b"),
		"cell_peer": Color("#0d1527"),
		"cell_error": Color("#7f1d1d"),
		"clue_text": Color("#f8fafc"),
		"user_text": Color("#38bdf8"),
		"error_text": Color("#ef4444"),
		"notes_text": Color("#94a3b8"),
		"score_orange": Color("#F97316"),
		"success_green": Color("#10B981"),
		"hints_amber": Color("#F59E0B"),
		"heart_red": Color("#EF4444"),
		"pill_bg": Color("#1e293b"),
		"text_primary": Color("#f8fafc"),
		"text_secondary": Color("#94a3b8")
	},
	"theme_cyber": {
		"id": "theme_cyber",
		"name": "Cyberpunk Neon",
		"is_dark": true,
		"primary_accent": Color("#06b6d4"),
		"secondary_glow": Color("#d946ef"),
		"bg_canvas": Color("#0b0816"),
		"bg_canvas_bottom": Color("#05030a"),
		"board_frame": Color("#120c24"),
		"major_grid": Color("#120c24"),
		"minor_grid": Color("#2e1c4a"),
		"cell_bg": Color("#160d2e"),
		"cell_clue_bg": Color("#0b0816"),
		"cell_selected": Color("#4a154b"),
		"cell_match": Color("#2a1245"),
		"cell_peer": Color("#1f0f38"),
		"cell_error": Color("#7f1d1d"),
		"clue_text": Color("#ffffff"),
		"user_text": Color("#06b6d4"),
		"error_text": Color("#f43f5e"),
		"notes_text": Color("#c084fc"),
		"score_orange": Color("#F97316"),
		"success_green": Color("#10B981"),
		"hints_amber": Color("#F59E0B"),
		"heart_red": Color("#EF4444"),
		"pill_bg": Color("#2e1c4a"),
		"text_primary": Color("#ffffff"),
		"text_secondary": Color("#c084fc")
	}
}

func _ready() -> void:
	_init_cached_styles()
	_update_cached_styles()
	call_deferred("_apply_initial_theme")

func _init_cached_styles() -> void:
	for sb in [_style_cell_normal, _style_cell_clue, _style_cell_selected, _style_cell_match, _style_cell_peer, _style_cell_error]:
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		
	_style_cell_selected.border_width_left = 2
	_style_cell_selected.border_width_top = 2
	_style_cell_selected.border_width_right = 2
	_style_cell_selected.border_width_bottom = 2
	_style_cell_selected.shadow_size = 4
	
	_style_board_panel.corner_radius_top_left = 14
	_style_board_panel.corner_radius_top_right = 14
	_style_board_panel.corner_radius_bottom_right = 14
	_style_board_panel.corner_radius_bottom_left = 14
	_style_board_panel.content_margin_left = 8.0
	_style_board_panel.content_margin_top = 8.0
	_style_board_panel.content_margin_right = 8.0
	_style_board_panel.content_margin_bottom = 8.0
	_style_board_panel.border_width_left = 3
	_style_board_panel.border_width_top = 3
	_style_board_panel.border_width_right = 3
	_style_board_panel.border_width_bottom = 3
	_style_board_panel.shadow_size = 10
	_style_board_panel.shadow_color = Color(0, 0, 0, 0.25)

func _update_cached_styles() -> void:
	var t: Dictionary = get_active_theme()
	var minor_border: Color = t.get("minor_grid", Color("#5B6980"))
	var p_accent: Color = t.get("primary_accent", Color("#1D4ED8"))
	var err_color: Color = t.get("error_text", Color("#DC2626"))
	var frame_color: Color = t.get("board_frame", Color("#242D3D"))
	
	# Normal Cell
	_style_cell_normal.bg_color = t.get("cell_bg", Color("#FFFFFF"))
	_style_cell_normal.border_color = minor_border
	
	# Clue Cell (locked given numbers)
	_style_cell_clue.bg_color = t.get("cell_clue_bg", Color("#F1F5F9"))
	_style_cell_clue.border_color = minor_border
	
	# Active Selected Cell
	_style_cell_selected.bg_color = t.get("cell_selected", Color("#BFDBFE"))
	_style_cell_selected.border_color = p_accent
	_style_cell_selected.shadow_color = Color(p_accent.r, p_accent.g, p_accent.b, 0.35)
	
	# Matching Numbers
	_style_cell_match.bg_color = t.get("cell_match", Color("#DBEAFE"))
	_style_cell_match.border_color = minor_border
	
	# Peer Highlight (Row / Col / Box)
	_style_cell_peer.bg_color = t.get("cell_peer", Color("#EFF6FF"))
	_style_cell_peer.border_color = minor_border
	
	# Error Cell
	_style_cell_error.bg_color = t.get("cell_error", Color("#FEE2E2"))
	_style_cell_error.border_color = err_color
	
	# Outer 9x9 Board Frame
	_style_board_panel.bg_color = frame_color
	_style_board_panel.border_color = frame_color

func _apply_initial_theme() -> void:
	var t: Dictionary = get_active_theme()
	_update_cached_styles()
	theme_applied.emit(current_theme_id, t["primary_accent"], t["secondary_glow"])
	SignalBus.theme_changed.emit(current_theme_id, t["primary_accent"], t["secondary_glow"])

func set_active_theme(theme_id: String) -> void:
	if not themes_catalog.has(theme_id):
		push_warning("ThemeManager: Unknown theme ID '%s', defaulting to 'theme_jk_games'" % theme_id)
		theme_id = "theme_jk_games"
	
	current_theme_id = theme_id
	var t: Dictionary = themes_catalog[current_theme_id]
	_update_cached_styles()
	theme_applied.emit(current_theme_id, t["primary_accent"], t["secondary_glow"])
	SignalBus.theme_changed.emit(current_theme_id, t["primary_accent"], t["secondary_glow"])

func get_active_theme() -> Dictionary:
	return themes_catalog.get(current_theme_id, themes_catalog["theme_jk_games"])

# --- Semantic Color Getters ---

func get_primary_accent() -> Color:
	return get_active_theme().get("primary_accent", Color("#1D4ED8"))

func get_secondary_glow() -> Color:
	return get_active_theme().get("secondary_glow", Color("#38BDF8"))

func get_bg_canvas() -> Color:
	return get_active_theme().get("bg_canvas", Color("#EBF3FA"))

func get_bg_canvas_bottom() -> Color:
	return get_active_theme().get("bg_canvas_bottom", Color("#F8FAFC"))

func get_board_frame_color() -> Color:
	return get_active_theme().get("board_frame", Color("#242D3D"))

func get_major_grid_color() -> Color:
	return get_active_theme().get("major_grid", Color("#242D3D"))

func get_minor_grid_color() -> Color:
	return get_active_theme().get("minor_grid", Color("#5B6980"))

func get_cell_bg_color() -> Color:
	return get_active_theme().get("cell_bg", Color("#FFFFFF"))

func get_cell_clue_bg_color() -> Color:
	return get_active_theme().get("cell_clue_bg", Color("#F1F5F9"))

func get_cell_selected_color() -> Color:
	return get_active_theme().get("cell_selected", Color("#BFDBFE"))

func get_cell_match_color() -> Color:
	return get_active_theme().get("cell_match", Color("#DBEAFE"))

func get_cell_peer_color() -> Color:
	return get_active_theme().get("cell_peer", Color("#EFF6FF"))

func get_cell_error_color() -> Color:
	return get_active_theme().get("cell_error", Color("#FEE2E2"))

func get_clue_text_color() -> Color:
	return get_active_theme().get("clue_text", Color("#111827"))

func get_user_text_color() -> Color:
	return get_active_theme().get("user_text", Color("#1D4ED8"))

func get_error_text_color() -> Color:
	return get_active_theme().get("error_text", Color("#DC2626"))

func get_notes_text_color() -> Color:
	return get_active_theme().get("notes_text", Color("#6B7280"))

func get_score_color() -> Color:
	return get_active_theme().get("score_orange", Color("#F97316"))

func get_success_color() -> Color:
	return get_active_theme().get("success_green", Color("#10B981"))

func get_hints_color() -> Color:
	return get_active_theme().get("hints_amber", Color("#F59E0B"))

func get_heart_color() -> Color:
	return get_active_theme().get("heart_red", Color("#EF4444"))

func get_pill_bg_color() -> Color:
	return get_active_theme().get("pill_bg", Color("#1E293B"))

func is_current_theme_dark() -> bool:
	return bool(get_active_theme().get("is_dark", false))

# --- Cached StyleBox Getters ---

func get_style_cell_normal() -> StyleBoxFlat:
	return _style_cell_normal

func get_style_cell_clue() -> StyleBoxFlat:
	return _style_cell_clue

func get_style_cell_selected() -> StyleBoxFlat:
	return _style_cell_selected

func get_style_cell_match() -> StyleBoxFlat:
	return _style_cell_match

func get_style_cell_peer() -> StyleBoxFlat:
	return _style_cell_peer

func get_style_cell_error() -> StyleBoxFlat:
	return _style_cell_error

func get_style_board_panel() -> StyleBoxFlat:
	return _style_board_panel

func get_all_themes() -> Array:
	return themes_catalog.values()

func set_font_scale(scale_multiplier: float) -> void:
	font_scale_factor = clampf(scale_multiplier, 0.75, 1.4)
	font_scale_applied.emit(font_scale_factor)
	SignalBus.font_scale_updated.emit(font_scale_factor)

func get_font_scale() -> float:
	return font_scale_factor
