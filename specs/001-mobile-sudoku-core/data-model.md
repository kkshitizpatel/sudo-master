# Data Model: Godot 4 Mobile Sudoku

**Feature**: `001-mobile-sudoku-core`  
**Status**: Completed Baseline  
**Date**: 2026-11-01  

---

## 1. Domain Entities & Schemas

### 1.1 `SudokuCell`
Represents an individual square in the 9x9 matrix (81 instances total).
- `index`: `int` (0 to 80, calculated as $9 \times \text{row} + \text{col}$)
- `row`: `int` (0 to 8)
- `col`: `int` (0 to 8)
- `box_index`: `int` (0 to 8, calculated as $3 \times \lfloor\text{row} / 3\rfloor + \lfloor\text{col} / 3\rfloor$)
- `solution_val`: `int` (1 to 9, correct solved value)
- `current_val`: `int` (0 if empty, 1 to 9 if filled)
- `is_clue`: `bool` (true if pre-filled, immutable by player)
- `is_error`: `bool` (true if user placed value violates Sudoku rules)
- `candidate_notes`: `Array[int]` (subset of [1..9])
- `visual_state`: `enum` (`DEFAULT`, `SELECTED`, `HIGHLIGHT_SCOPE`, `HIGHLIGHT_MATCH`, `ERROR`)

### 1.2 `SudokuBoardState`
Encapsulates runtime puzzle data.
- `board_id`: `String` (UUID or deterministic seed string)
- `game_mode`: `int` (0: Classic, 1: Campaign, 2: Battle, 3: Daily)
- `difficulty_ser`: `float` (1.0 to 11.5+)
- `cells`: `Array[SudokuCell]` (length 81)
- `remaining_counts`: `Dictionary` `{1: int, 2: int, ..., 9: int}` (remaining instances needed to clear digit)
- `mistakes_count`: `int` (0 to 3)
- `hints_used`: `int`
- `current_score`: `int`
- `combo_multiplier`: `float` (1.0x to 3.0x)
- `elapsed_seconds`: `int`
- `is_completed`: `bool`

### 1.3 `MoveRecord` (Undo Stack Item)
- `cell_index`: `int`
- `previous_val`: `int`
- `new_val`: `int`
- `previous_notes`: `Array[int]`
- `new_notes`: `Array[int]`
- `was_error`: `bool`

### 1.4 `CampaignLevelRecord`
- `level_id`: `int` (1 to 100)
- `zone_name`: `String` (e.g. "Beginner", "Novice", "Expert")
- `ser_rating`: `float`
- `clues_count`: `int`
- `is_unlocked`: `bool` (Level 1 unlocked by default; subsequent unlocked upon completing previous level)
- `stars_earned`: `int` (0 to 3)
- `best_time_seconds`: `int`
- `best_score`: `int`

### 1.5 `ThemePaletteRecord`
- `id`: `String` (e.g., `"theme_aero"`, `"theme_emerald"`)
- `display_name`: `String`
- `primary_accent`: `Color` (active elements, glowing borders)
- `secondary_glow`: `Color` (ambient aurora blobs, soft halos)
- `is_dark`: `bool`

---

## 2. State Lifecycle & Transitions

```text
       ┌──────────────┐
       │   App Boot   │
       └──────┬───────┘
              │ [Load settings.cfg & sudoku.db]
              ▼
       ┌──────────────┐
       │ SplashScreen │
       └──────┬───────┘
              ├─────────────────────────────────────────┐
              │ [has_accepted_terms == false]           │ [has_accepted_terms == true]
              ▼                                         ▼
       ┌──────────────┐                          ┌──────────────┐
       │  Onboarding  │                          │  Main Menu   │
       └──────┬───────┘                          └──────┬───────┘
              │ [Terms Accepted]                        │ [Select Mode]
              ▼                                         ▼
       ┌──────────────┐                          ┌──────────────┐
       │ Claim Level  │                          │ Mode Select  │
       └──────┬───────┘                          └──────┬───────┘
              │ [Pass or Skip]                          │ [Start / Resume]
              └────────────────────┬────────────────────┘
                                   ▼
                         ┌──────────────────┐
                         │  Gameplay Board  │
                         └────────┬─────────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            │ [3 Mistakes]        │ [Board Cleared]     │ [Back / Minimize]
            ▼                     ▼                     ▼
     ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
     │  Game Over   │      │   Victory    │      │  Auto-Save   │
     │ (Revive/Ret) │      │ (3-Star Calc)│      │  to DB/Disk  │
     └──────────────┘      └──────────────┘      └──────────────┘
```
