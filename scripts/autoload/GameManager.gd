# GameManager.gd
# Core State, Scoring Engine, Monotonic Timer, and Haptics Manager
# Compliant with Godot 4.7 GDScript 2.0 static typing
extends Node

# Persistent Player Profile
var player_name: String = "Guest_4821"
var player_level: int = 1
var coins_count: int = 100
var high_score: int = 0
var daily_streak_count: int = 0
var last_daily_date: String = ""

# Onboarding & Session Flags
var has_accepted_terms: bool = false
var has_completed_placement: bool = false
var has_saved_game: bool = false
var haptics_enabled: bool = true

# Active Match State
var current_game_mode: int = 0 # 0: Classic, 1: Campaign, 2: Battle, 3: Daily
var current_level_id: int = 1
var current_difficulty: int = 1 # 1: Easy, 2: Medium, 3: Hard
var current_score: int = 0
var combo_multiplier: float = 1.0
var mistakes_count: int = 0 # Max 3
var hints_remaining: int = 3
var is_game_active: bool = false
var is_game_paused: bool = false

# Monotonic Timer Precision State
var active_accumulated_ms: int = 0
var last_resume_tick: int = 0
var last_valid_move_tick: int = 0

# Signals
signal score_updated(new_score: int, combo: float)
signal mistake_occurred(current_mistakes: int, max_mistakes: int)
signal game_over_triggered(reason: String)
signal level_completed(level_id: int, stars: int, score: int, time_seconds: int)
signal timer_ticked(formatted_time: String)
signal game_paused_changed(is_paused: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if is_game_active and not is_game_paused:
		var current_tick: int = Time.get_ticks_msec()
		var total_ms: int = active_accumulated_ms + (current_tick - last_resume_tick)
		var total_seconds: int = int(total_ms / 1000.0)
		var minutes: int = int(total_seconds / 60.0)
		var seconds: int = total_seconds % 60
		var formatted: String = "%02d:%02d" % [minutes, seconds]
		timer_ticked.emit(formatted)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			pause_timer()
			# Trigger auto-save if in active match
			if is_game_active:
				SignalBus.play_sfx.emit("pause")
		NOTIFICATION_APPLICATION_RESUMED:
			# Keep paused until player taps resume modal to avoid unfair time loss
			if is_game_active:
				set_paused(true)

# ------------------------------------------------------------------------------
# Match Lifecycle & Timer Controls
# ------------------------------------------------------------------------------

func start_new_game(mode: int = 0, level_id: int = 1, diff: int = 1) -> void:
	current_game_mode = mode
	current_level_id = level_id
	current_difficulty = diff
	current_score = 0
	combo_multiplier = 1.0
	mistakes_count = 0
	hints_remaining = 3
	active_accumulated_ms = 0
	last_resume_tick = Time.get_ticks_msec()
	last_valid_move_tick = last_resume_tick
	is_game_active = true
	is_game_paused = false
	
	score_updated.emit(current_score, combo_multiplier)
	mistake_occurred.emit(mistakes_count, 3)

func pause_timer() -> void:
	if is_game_active and not is_game_paused:
		var current_tick: int = Time.get_ticks_msec()
		active_accumulated_ms += (current_tick - last_resume_tick)
		is_game_paused = true
		game_paused_changed.emit(true)

func resume_timer() -> void:
	if is_game_active and is_game_paused:
		last_resume_tick = Time.get_ticks_msec()
		is_game_paused = false
		game_paused_changed.emit(false)

func set_paused(paused: bool) -> void:
	if paused:
		pause_timer()
	else:
		resume_timer()

func get_elapsed_seconds() -> int:
	if not is_game_active:
		return int(active_accumulated_ms / 1000.0)
	var current_tick: int = Time.get_ticks_msec()
	var total_ms: int = active_accumulated_ms
	if not is_game_paused:
		total_ms += (current_tick - last_resume_tick)
	return int(total_ms / 1000.0)

func get_elapsed_time_string() -> String:
	var total_sec: int = get_elapsed_seconds()
	return "%02d:%02d" % [int(total_sec / 60.0), total_sec % 60]

# ------------------------------------------------------------------------------
# Scoring, Combo, and Mistakes
# ------------------------------------------------------------------------------

func record_valid_move() -> void:
	var now: int = Time.get_ticks_msec()
	var time_diff: int = now - last_valid_move_tick
	last_valid_move_tick = now
	
	# Combo bonus if placed within 4 seconds of last move
	if time_diff <= 4000:
		combo_multiplier = minf(combo_multiplier + 0.5, 3.0)
	else:
		combo_multiplier = 1.0
	
	var points_earned: int = int(50 * combo_multiplier)
	current_score += points_earned
	
	score_updated.emit(current_score, combo_multiplier)
	SignalBus.score_awarded.emit(points_earned, combo_multiplier)
	trigger_haptic(30) # Subtle tactile tick

func register_mistake() -> void:
	mistakes_count += 1
	combo_multiplier = 1.0
	current_score = maxi(0, current_score - 20)
	
	score_updated.emit(current_score, combo_multiplier)
	mistake_occurred.emit(mistakes_count, 3)
	SignalBus.mistake_registered.emit(mistakes_count, 3)
	trigger_haptic(150) # Error rumble buzz
	
	if mistakes_count >= 3:
		pause_timer()
		is_game_active = false
		game_over_triggered.emit("3_mistakes")
		SignalBus.game_over_opened.emit("3_mistakes")

func revive_player_with_life() -> void:
	# Restores 1 life: mistakes_count drops back to 2, unpauses
	mistakes_count = 2
	is_game_active = true
	is_game_paused = false
	last_resume_tick = Time.get_ticks_msec()
	
	mistake_occurred.emit(mistakes_count, 3)
	SignalBus.mistake_registered.emit(mistakes_count, 3)
	SignalBus.game_revived_with_life.emit()

func record_hint_used() -> void:
	if hints_remaining > 0:
		hints_remaining -= 1
		current_score = maxi(0, current_score - 50)
		score_updated.emit(current_score, combo_multiplier)

func add_hint(amount: int = 1) -> void:
	hints_remaining += amount

func complete_puzzle() -> Dictionary:
	is_game_active = false
	pause_timer()
	
	var final_time: int = get_elapsed_seconds()
	var stars: int = 1
	if mistakes_count == 0 and final_time < 300:
		stars = 3
	elif mistakes_count <= 1 and final_time < 600:
		stars = 2
	
	if current_score > high_score:
		high_score = current_score
	
	var summary: Dictionary = {
		"level_id": current_level_id,
		"game_mode": current_game_mode,
		"stars": stars,
		"score": current_score,
		"time_seconds": final_time,
		"formatted_time": get_elapsed_time_string(),
		"mistakes": mistakes_count
	}
	
	level_completed.emit(current_level_id, stars, current_score, final_time)
	SignalBus.puzzle_completed.emit(summary)
	return summary

# ------------------------------------------------------------------------------
# Haptics Helper
# ------------------------------------------------------------------------------

func trigger_haptic(duration_ms: int = 30) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms)
		SignalBus.trigger_haptic.emit(duration_ms)
