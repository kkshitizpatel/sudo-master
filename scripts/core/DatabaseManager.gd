# DatabaseManager.gd
# Unified Persistence Service: SQLite & FileAccess JSON Engine with ConfigFile Settings Parser
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const DB_JSON_PATH: String = "user://sudoku_db.json"
const DB_SQLITE_PATH: String = "user://sudoku.db"

# Internal in-memory database store (matching relational tables)
var _db_tables: Dictionary = {
	"player_progress": {
		"id": 1,
		"player_name": "Guest_4821",
		"player_level": 1,
		"coins_count": 100,
		"high_score": 0,
		"daily_streak_count": 0,
		"last_daily_date": ""
	},
	"campaign_levels": {}, # level_id: { level_id, zone_name, is_unlocked, stars_earned, best_time, best_score }
	"active_match_save": {
		"has_active_match": false
	},
	"daily_challenges": {}, # date_str: { date_string, is_completed, stars, time_seconds }
	"favorites": {} # puzzle_id: { puzzle_id, difficulty, bookmarked_at }
}

var _config: ConfigFile = ConfigFile.new()
var _has_sqlite: bool = false
var _sqlite_instance: Variant = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_has_sqlite = ClassDB.class_exists("SQLite")
	initialize_db()
	load_settings()

# ------------------------------------------------------------------------------
# Database Initialization & Fallback Handler
# ------------------------------------------------------------------------------

func initialize_db() -> void:
	if _has_sqlite:
		_init_sqlite()
	else:
		_init_json_db()

func _init_sqlite() -> void:
	# GDExtension SQLite initialization
	_sqlite_instance = ClassDB.instantiate("SQLite")
	if _sqlite_instance:
		_sqlite_instance.path = DB_SQLITE_PATH
		_sqlite_instance.open_db()
		
		# Create relational tables
		_sqlite_instance.query("""
			CREATE TABLE IF NOT EXISTS player_progress (
				id INTEGER PRIMARY KEY,
				player_name TEXT,
				player_level INTEGER,
				coins_count INTEGER,
				high_score INTEGER,
				daily_streak_count INTEGER,
				last_daily_date TEXT
			);
		""")
		_sqlite_instance.query("""
			CREATE TABLE IF NOT EXISTS campaign_levels (
				level_id INTEGER PRIMARY KEY,
				zone_name TEXT,
				is_unlocked INTEGER,
				stars_earned INTEGER,
				best_time_seconds INTEGER,
				best_score INTEGER
			);
		""")
		_sqlite_instance.query("""
			CREATE TABLE IF NOT EXISTS active_match_save (
				id INTEGER PRIMARY KEY,
				has_active_match INTEGER,
				game_mode INTEGER,
				level_id INTEGER,
				score INTEGER,
				combo REAL,
				mistakes INTEGER,
				hints_remaining INTEGER,
				elapsed_seconds INTEGER,
				cells_data TEXT
			);
		""")
		_sqlite_instance.query("""
			CREATE TABLE IF NOT EXISTS daily_challenges (
				date_string TEXT PRIMARY KEY,
				is_completed INTEGER,
				stars INTEGER,
				time_seconds INTEGER
			);
		""")
		_sqlite_instance.query("""
			CREATE TABLE IF NOT EXISTS favorites (
				puzzle_id TEXT PRIMARY KEY,
				difficulty TEXT,
				bookmarked_at TEXT
			);
		""")
		_init_default_campaign_levels()
		_sync_from_sqlite_to_memory()
	else:
		_init_json_db()

func _init_json_db() -> void:
	if FileAccess.file_exists(DB_JSON_PATH):
		var file: FileAccess = FileAccess.open(DB_JSON_PATH, FileAccess.READ)
		if file:
			var json_text: String = file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(json_text)
			if parsed is Dictionary:
				_db_tables = parsed
				# Ensure all expected root keys exist
				if not _db_tables.has("campaign_levels") or _db_tables["campaign_levels"].is_empty():
					_init_default_campaign_levels()
					_save_json_db()
				return
	
	# New database file initialization
	_init_default_campaign_levels()
	_save_json_db()

func _init_default_campaign_levels() -> void:
	if not _db_tables.has("campaign_levels"):
		_db_tables["campaign_levels"] = {}
		
	if _db_tables["campaign_levels"].is_empty():
		for lvl in range(1, 101):
			var zone: String = "Novice"
			if lvl > 75:
				zone = "Master"
			elif lvl > 50:
				zone = "Expert"
			elif lvl > 25:
				zone = "Intermediate"
				
			_db_tables["campaign_levels"][str(lvl)] = {
				"level_id": lvl,
				"zone_name": zone,
				"is_unlocked": (lvl == 1), # Level 1 unlocked by default
				"stars_earned": 0,
				"best_time_seconds": 0,
				"best_score": 0
			}

func _save_json_db() -> void:
	var file: FileAccess = FileAccess.open(DB_JSON_PATH, FileAccess.WRITE)
	if file:
		var json_str: String = JSON.stringify(_db_tables, "\t")
		file.store_string(json_str)
		file.close()

func _sync_from_sqlite_to_memory() -> void:
	if not _sqlite_instance:
		return
	_sqlite_instance.query("SELECT * FROM player_progress WHERE id = 1;")
	var res: Array = _sqlite_instance.query_result
	if not res.is_empty():
		_db_tables["player_progress"] = res[0]
	else:
		_sqlite_instance.insert_row("player_progress", _db_tables["player_progress"])

# ------------------------------------------------------------------------------
# ConfigFile Settings Reader & Writer (`user://settings.cfg`)
# ------------------------------------------------------------------------------

func load_settings() -> void:
	var err: Error = _config.load(SETTINGS_PATH)
	if err != OK:
		# Write defaults
		set_setting("audio", "sfx_volume", 1.0)
		set_setting("audio", "bgm_volume", 0.7)
		set_setting("gameplay", "haptics_enabled", true)
		set_setting("gameplay", "auto_remove_notes", true)
		set_setting("gameplay", "has_accepted_terms", false)
		set_setting("gameplay", "has_completed_placement", false)
		set_setting("theme", "active_theme_id", "theme_jk_games")
		set_setting("theme", "font_scale", 1.0)
		save_settings()
	
	# Apply loaded values to autoload singletons
	if GameManager:
		GameManager.haptics_enabled = bool(get_setting("gameplay", "haptics_enabled", true))
		GameManager.has_accepted_terms = bool(get_setting("gameplay", "has_accepted_terms", false))
		GameManager.has_completed_placement = bool(get_setting("gameplay", "has_completed_placement", false))
		
	if SudokuEngine:
		SudokuEngine.auto_remove_notes = bool(get_setting("gameplay", "auto_remove_notes", true))
		
	if ThemeManager:
		var saved_theme: String = str(get_setting("theme", "active_theme_id", "theme_jk_games"))
		ThemeManager.set_active_theme(saved_theme)
		ThemeManager.set_font_scale(float(get_setting("theme", "font_scale", 1.0)))

func save_settings() -> void:
	_config.save(SETTINGS_PATH)

func get_setting(section: String, key: String, default_value: Variant = null) -> Variant:
	return _config.get_value(section, key, default_value)

func set_setting(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	save_settings()

# ------------------------------------------------------------------------------
# Active Match Save & Resume
# ------------------------------------------------------------------------------

func save_active_match(match_data: Dictionary) -> void:
	match_data["has_active_match"] = true
	_db_tables["active_match_save"] = match_data
	if _has_sqlite and _sqlite_instance:
		_sqlite_instance.query("DELETE FROM active_match_save;")
		var cells_str: String = JSON.stringify(match_data.get("cells", []))
		_sqlite_instance.insert_row("active_match_save", {
			"id": 1,
			"has_active_match": 1,
			"game_mode": match_data.get("game_mode", 0),
			"level_id": match_data.get("level_id", 1),
			"score": match_data.get("score", 0),
			"combo": match_data.get("combo", 1.0),
			"mistakes": match_data.get("mistakes", 0),
			"hints_remaining": match_data.get("hints_remaining", 3),
			"elapsed_seconds": match_data.get("elapsed_seconds", 0),
			"cells_data": cells_str
		})
	else:
		_save_json_db()
	
	if GameManager:
		GameManager.has_saved_game = true

func load_active_match() -> Dictionary:
	if _has_sqlite and _sqlite_instance:
		_sqlite_instance.query("SELECT * FROM active_match_save WHERE id = 1 AND has_active_match = 1;")
		var res: Array = _sqlite_instance.query_result
		if not res.is_empty():
			var row: Dictionary = res[0]
			var parsed_cells: Variant = JSON.parse_string(str(row.get("cells_data", "[]")))
			return {
				"has_active_match": true,
				"game_mode": row.get("game_mode", 0),
				"level_id": row.get("level_id", 1),
				"score": row.get("score", 0),
				"combo": row.get("combo", 1.0),
				"mistakes": row.get("mistakes", 0),
				"hints_remaining": row.get("hints_remaining", 3),
				"elapsed_seconds": row.get("elapsed_seconds", 0),
				"cells": parsed_cells if parsed_cells is Array else []
			}
			
	var save_data: Dictionary = _db_tables.get("active_match_save", {})
	if save_data.get("has_active_match", false):
		return save_data
	return {}

func clear_active_match() -> void:
	_db_tables["active_match_save"] = {"has_active_match": false}
	if _has_sqlite and _sqlite_instance:
		_sqlite_instance.query("DELETE FROM active_match_save;")
	else:
		_save_json_db()
		
	if GameManager:
		GameManager.has_saved_game = false

# ------------------------------------------------------------------------------
# Campaign Progression
# ------------------------------------------------------------------------------

func get_campaign_levels() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var levels_dict: Dictionary = _db_tables.get("campaign_levels", {})
	for lvl in range(1, 101):
		var k: String = str(lvl)
		if levels_dict.has(k):
			list.append(levels_dict[k])
	return list

func get_campaign_level(level_id: int) -> Dictionary:
	var k: String = str(level_id)
	var levels_dict: Dictionary = _db_tables.get("campaign_levels", {})
	if levels_dict.has(k):
		return levels_dict[k]
	return {}

func unlock_campaign_level(level_id: int, stars: int, score: int, time_sec: int) -> void:
	var k: String = str(level_id)
	var levels_dict: Dictionary = _db_tables.get("campaign_levels", {})
	if levels_dict.has(k):
		var rec: Dictionary = levels_dict[k]
		rec["is_unlocked"] = true
		rec["stars_earned"] = maxi(rec.get("stars_earned", 0), stars)
		rec["best_score"] = maxi(rec.get("best_score", 0), score)
		var prev_time: int = rec.get("best_time_seconds", 0)
		if prev_time == 0 or time_sec < prev_time:
			rec["best_time_seconds"] = time_sec
			
		# Automatically unlock subsequent level for free
		var next_k: String = str(level_id + 1)
		if levels_dict.has(next_k):
			levels_dict[next_k]["is_unlocked"] = true
			
		if not _has_sqlite:
			_save_json_db()

func batch_unlock_levels(target_level: int, default_stars: int = 2) -> void:
	var levels_dict: Dictionary = _db_tables.get("campaign_levels", {})
	for lvl in range(1, target_level + 1):
		var k: String = str(lvl)
		if levels_dict.has(k):
			var rec: Dictionary = levels_dict[k]
			rec["is_unlocked"] = true
			if lvl < target_level and rec.get("stars_earned", 0) == 0:
				rec["stars_earned"] = default_stars
				
	if not _has_sqlite:
		_save_json_db()

# ------------------------------------------------------------------------------
# Daily Challenge & Favorites
# ------------------------------------------------------------------------------

func record_daily_completion(date_str: String, stars: int, time_sec: int) -> void:
	_db_tables["daily_challenges"][date_str] = {
		"date_string": date_str,
		"is_completed": true,
		"stars": stars,
		"time_seconds": time_sec
	}
	if not _has_sqlite:
		_save_json_db()

func is_daily_completed(date_str: String) -> bool:
	var dailies: Dictionary = _db_tables.get("daily_challenges", {})
	if dailies.has(date_str):
		return dailies[date_str].get("is_completed", false)
	return false

func toggle_favorite(puzzle_id: String, difficulty: String = "Classic") -> bool:
	var favs: Dictionary = _db_tables.get("favorites", {})
	if favs.has(puzzle_id):
		favs.erase(puzzle_id)
		if not _has_sqlite:
			_save_json_db()
		return false
	else:
		favs[puzzle_id] = {
			"puzzle_id": puzzle_id,
			"difficulty": difficulty,
			"bookmarked_at": Time.get_datetime_string_from_system()
		}
		if not _has_sqlite:
			_save_json_db()
		return true

func is_favorite(puzzle_id: String) -> bool:
	return _db_tables.get("favorites", {}).has(puzzle_id)
