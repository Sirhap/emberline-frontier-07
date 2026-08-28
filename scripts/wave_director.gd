class_name WaveDirector
extends RefCounted

signal prep_started(upcoming_wave: int)
signal combat_started(wave: int)
signal wave_cleared(wave: int)

const PREP := &"prep"
const COMBAT := &"combat"

var prep_duration := 50.0
var current_wave := 0
var phase: StringName = PREP
var prep_left := 50.0


func begin_run() -> void:
	current_wave = 0
	begin_prep()


func restore(cleared_wave: int) -> void:
	current_wave = maxi(cleared_wave, 0)
	begin_prep()


func begin_prep() -> void:
	phase = PREP
	prep_left = prep_duration
	prep_started.emit(current_wave + 1)


func start_wave() -> void:
	if phase == COMBAT:
		return
	prep_left = 0.0
	_enter_combat()


func tick(delta: float) -> void:
	if phase != PREP:
		return
	prep_left = maxf(prep_left - delta, 0.0)
	if prep_left <= 0.0:
		_enter_combat()


func notify_combat_cleared() -> void:
	if phase != COMBAT:
		return
	wave_cleared.emit(current_wave)
	begin_prep()


func is_prep() -> bool:
	return phase == PREP


func is_combat() -> bool:
	return phase == COMBAT


func upcoming_wave() -> int:
	return current_wave + 1


func _enter_combat() -> void:
	current_wave += 1
	phase = COMBAT
	prep_left = 0.0
	combat_started.emit(current_wave)
