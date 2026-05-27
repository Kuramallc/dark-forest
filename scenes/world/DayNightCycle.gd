extends Node
class_name DayNightCycle

signal day_started
signal night_started
signal phase_changed(phase_name: String)

enum Phase { DAWN, DAY, DUSK, NIGHT }

const FULL_CYCLE  := 600.0   # seconds per full day
const PHASE_FRAC  := { 0: 0.2, 1: 0.4, 2: 0.2, 3: 0.2 }   # fraction of FULL_CYCLE

const PHASE_COLOR := {
	0: Color(0.35, 0.22, 0.28, 1),   # DAWN  — cool purple-rose
	1: Color(0.50, 0.48, 0.42, 1),   # DAY   — muted daylight
	2: Color(0.28, 0.16, 0.12, 1),   # DUSK  — deep amber
	3: Color(0.03, 0.03, 0.06, 1),   # NIGHT — near-black
}

const PHASE_NAMES := { 0: "Dawn", 1: "Day", 2: "Dusk", 3: "Night" }

var elapsed      := 120.0   # start mid-day
var day_count    := 1
var current_phase: int = Phase.DAY

var _canvas_mod: CanvasModulate

func _ready() -> void:
	_canvas_mod = get_parent().get_node_or_null("CanvasModulate") as CanvasModulate
	if not _canvas_mod:
		push_warning("DayNightCycle: CanvasModulate not found in parent.")
	# Relay our signals to the global EventBus
	phase_changed.connect(func(p: String) -> void: EventBus.phase_changed.emit(p))
	day_started.connect(func() -> void:   EventBus.day_changed.emit(day_count))

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= FULL_CYCLE:
		elapsed -= FULL_CYCLE
		day_count += 1
		day_started.emit()

	_check_phase_transition()
	_blend_ambient()

func _check_phase_transition() -> void:
	var new_phase := _phase_at(elapsed)
	if new_phase != current_phase:
		current_phase = new_phase
		phase_changed.emit(PHASE_NAMES[current_phase])
		if current_phase == Phase.NIGHT:
			night_started.emit()

func _blend_ambient() -> void:
	if not _canvas_mod:
		return
	var cumulative := 0.0
	for i in range(4):
		var dur: float = PHASE_FRAC[i] * FULL_CYCLE
		if elapsed <= cumulative + dur:
			var next := (i + 1) % 4
			var blend := (elapsed - cumulative) / dur
			_canvas_mod.color = PHASE_COLOR[i].lerp(PHASE_COLOR[next], blend)
			return
		cumulative += dur

func _phase_at(t: float) -> int:
	var frac := t / FULL_CYCLE
	var cumulative := 0.0
	for i in range(4):
		cumulative += PHASE_FRAC[i]
		if frac < cumulative:
			return i
	return Phase.NIGHT

func is_night() -> bool:
	return current_phase == Phase.NIGHT

func get_phase_name() -> String:
	return PHASE_NAMES[current_phase]
