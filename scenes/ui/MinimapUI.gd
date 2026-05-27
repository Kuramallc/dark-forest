extends Control
class_name MinimapUI

## Bottom-right HUD minimap.
## Terrain colours are baked into a 128×128 texture once after map generation.
## The live fog ImageTexture (updated by FogOfWar each reveal) is passed as a
## shader uniform, so the minimap always reflects current exploration state
## with zero extra CPU work per frame.
## Player and home dots are drawn via _draw() each frame.

const MINIMAP_PX := 160                       # on-screen size in pixels
const MAP_TILES  := 128                       # must match FogOfWar / MapGenerator
const BORDER_PX  :=   2.0
const LABEL_H    :=  20                       # height reserved for the status label

# Terrain colours — must match World._build_tileset() palette
const TILE_COLORS := {
	0: Color(0.11, 0.20, 0.08),   # T_GRASS
	1: Color(0.30, 0.22, 0.12),   # T_DIRT
	2: Color(0.04, 0.07, 0.03),   # T_DEEP
	3: Color(0.33, 0.32, 0.30),   # T_STONE
}

var _player_ref: Node2D
var _map_rect:   TextureRect
var _mat:        ShaderMaterial
var _ready_flag: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(MINIMAP_PX, MINIMAP_PX + LABEL_H)

	# Dark background drawn in _draw(); we just need a clip rect
	clip_contents = true

	# Shader material
	var shader := load("res://shaders/minimap.gdshader") as Shader
	_mat = ShaderMaterial.new()
	_mat.shader = shader

	# TextureRect fills the lower MINIMAP_PX × MINIMAP_PX area
	_map_rect = TextureRect.new()
	_map_rect.position       = Vector2(0, LABEL_H)
	_map_rect.size           = Vector2(MINIMAP_PX, MINIMAP_PX)
	_map_rect.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	_map_rect.stretch_mode   = TextureRect.STRETCH_SCALE
	_map_rect.material       = _mat
	add_child(_map_rect)

	# Listen for the map being generated
	EventBus.map_ready.connect(_on_map_ready)

# Called by EventBus after World finishes generating
func _on_map_ready(tile_map: Dictionary, fog_tex: ImageTexture, player: Node2D) -> void:
	_player_ref = player

	# Bake terrain colours into a 128×128 texture (one-time operation)
	var terrain_img := Image.create(MAP_TILES, MAP_TILES, false, Image.FORMAT_RGB8)
	terrain_img.fill(Color.BLACK)
	for tile_pos: Vector2i in tile_map.keys():
		var px := tile_pos.x + MAP_TILES / 2
		var py := tile_pos.y + MAP_TILES / 2
		if px >= 0 and px < MAP_TILES and py >= 0 and py < MAP_TILES:
			terrain_img.set_pixel(px, py, TILE_COLORS.get(tile_map[tile_pos], Color.BLACK))

	_map_rect.texture = ImageTexture.create_from_image(terrain_img)
	_mat.set_shader_parameter("fog_tex", fog_tex)   # live reference — auto-updates
	_ready_flag = true

func _process(_delta: float) -> void:
	if _ready_flag:
		queue_redraw()   # redraw dots and border every frame

func _draw() -> void:
	var full_h := MINIMAP_PX + LABEL_H

	# ── Background panel ──────────────────────────────────────────────────
	draw_rect(Rect2(0, 0, MINIMAP_PX, full_h), Color(0.06, 0.06, 0.08, 0.92))

	# ── Status label (day + phase) ────────────────────────────────────────
	var label_text := "Day %d  ·  %s" % [GameState.day_count, _get_phase()]
	draw_string(
		ThemeDB.fallback_font,
		Vector2(6, LABEL_H - 5),
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		MINIMAP_PX - 8,
		10,
		Color(0.85, 0.82, 0.70)
	)

	# ── Border ────────────────────────────────────────────────────────────
	draw_rect(Rect2(0, 0, MINIMAP_PX, full_h), Color(0.22, 0.18, 0.12, 1.0), false, BORDER_PX)
	# Inner separator below label
	draw_line(Vector2(0, LABEL_H), Vector2(MINIMAP_PX, LABEL_H), Color(0.22, 0.18, 0.12, 1.0), 1.0)

	if not _ready_flag or not _player_ref:
		return

	# ── Home marker (orange diamond) ─────────────────────────────────────
	var home_mm := _world_to_mm(Vector2.ZERO)
	_draw_diamond(home_mm, 4.5, Color(0.0, 0.0, 0.0, 0.7))
	_draw_diamond(home_mm, 3.0, Color(1.0, 0.55, 0.15))

	# ── Player marker (yellow dot + tiny direction tick) ──────────────────
	var pmm := _world_to_mm(_player_ref.global_position)
	draw_circle(pmm, 4.5, Color(0.0, 0.0, 0.0, 0.7))   # shadow
	draw_circle(pmm, 3.0, Color(1.0, 0.95, 0.30))        # yellow dot

	# Direction tick — use player visual rotation
	var visual := _player_ref.get_node_or_null("PlayerVisual") as Node2D
	if visual:
		var dir := Vector2.RIGHT.rotated(visual.rotation)
		draw_line(pmm, pmm + dir * 6.0, Color(1.0, 1.0, 1.0, 0.9), 1.5)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _world_to_mm(world_pos: Vector2) -> Vector2:
	# World: -4096 .. +4096  →  minimap: 0 .. MINIMAP_PX
	# Add LABEL_H offset so dots land in the map area, not the label strip
	var total := float(MAP_TILES * 64)   # 8192 px
	var uv    := world_pos / total + Vector2(0.5, 0.5)
	return uv * Vector2(MINIMAP_PX, MINIMAP_PX) + Vector2(0.0, LABEL_H)

func _draw_diamond(center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -r),
		center + Vector2(r,  0),
		center + Vector2(0,  r),
		center + Vector2(-r, 0),
	])
	draw_colored_polygon(pts, col)

func _get_phase() -> String:
	# Read phase name from EventBus-connected DayNightCycle via GameState day
	# DayNightCycle updates EventBus.phase_changed; we keep a local copy:
	return _last_phase

var _last_phase := "Day"

func _enter_tree() -> void:
	EventBus.phase_changed.connect(func(p: String) -> void: _last_phase = p)
