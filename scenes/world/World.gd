extends Node2D

const TILE_SIZE  := 64
const MAP_RADIUS := 20   # tiles from center; full map = 40x40

# Atlas column per tile type
const T_GRASS := 0
const T_DIRT  := 1
const T_DEEP  := 2
const T_STONE := 3

@onready var ground:     TileMapLayer  = $Ground
@onready var objects:    Node2D        = $Objects
@onready var canvas_mod: CanvasModulate = $CanvasModulate
@onready var day_night:  DayNightCycle  = $DayNightCycle

func _ready() -> void:
	_build_tileset()
	_draw_map()
	_spawn_trees()
	_spawn_foliage_details()

# ── Tileset (generated at runtime, no asset files needed) ────────────────────
func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source := TileSetAtlasSource.new()
	var img := Image.create(TILE_SIZE * 4, TILE_SIZE, false, Image.FORMAT_RGBA8)

	_paint_tile(img, 0, Color(0.11, 0.20, 0.08))   # grass
	_paint_tile(img, 1, Color(0.30, 0.22, 0.12))   # dirt
	_paint_tile(img, 2, Color(0.04, 0.07, 0.03))   # deep forest
	_paint_tile(img, 3, Color(0.33, 0.32, 0.30))   # stone

	source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in range(4):
		source.create_tile(Vector2i(i, 0))

	ts.add_source(source, 0)
	ground.tile_set = ts

func _paint_tile(img: Image, col: int, base: Color) -> void:
	var bx := col * TILE_SIZE
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var jitter := randf_range(-0.025, 0.025)
			img.set_pixel(bx + x, y, Color(
				clampf(base.r + jitter, 0, 1),
				clampf(base.g + jitter, 0, 1),
				clampf(base.b + jitter, 0, 1)
			))

# ── Map layout ────────────────────────────────────────────────────────────────
func _draw_map() -> void:
	for tx in range(-MAP_RADIUS, MAP_RADIUS + 1):
		for ty in range(-MAP_RADIUS, MAP_RADIUS + 1):
			var dist := Vector2(tx, ty).length()
			var atlas_x: int
			if dist < 5.5:
				atlas_x = T_DIRT
			elif dist < 9.0:
				atlas_x = T_GRASS
			elif dist < 14.0:
				atlas_x = T_GRASS if randf() > 0.25 else T_DEEP
			else:
				atlas_x = T_DEEP
			ground.set_cell(Vector2i(tx, ty), 0, Vector2i(atlas_x, 0))

# ── Tree spawning ─────────────────────────────────────────────────────────────
func _spawn_trees() -> void:
	for tx in range(-MAP_RADIUS, MAP_RADIUS + 1):
		for ty in range(-MAP_RADIUS, MAP_RADIUS + 1):
			var dist := Vector2(tx, ty).length()
			if dist < 6.5:
				continue
			var density := clampf((dist - 6.5) / 12.0, 0.0, 1.0)
			if randf() < density * 0.38:
				var wpos := Vector2(tx * TILE_SIZE + TILE_SIZE * 0.5,
									ty * TILE_SIZE + TILE_SIZE * 0.5)
				# Random offset so trees aren't grid-locked
				wpos += Vector2(randf_range(-20, 20), randf_range(-20, 20))
				objects.add_child(_make_tree(wpos))

func _make_tree(pos: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 2
	body.collision_mask  = 0

	# Collision
	var col   := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	body.add_child(col)

	# Canopy
	var r := randf_range(22.0, 34.0)
	var canopy := Polygon2D.new()
	var pts    := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		var rr := r + randf_range(-5.0, 5.0)
		pts.append(Vector2(cos(a) * rr, sin(a) * rr - 10.0))
	canopy.polygon = pts
	canopy.color   = Color(
		randf_range(0.04, 0.14),
		randf_range(0.14, 0.28),
		randf_range(0.03, 0.10)
	)
	body.add_child(canopy)

	# Trunk
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-5,  8), Vector2(5,  8),
		Vector2(4,  26), Vector2(-4, 26),
	])
	trunk.color = Color(0.32, 0.20, 0.09)
	body.add_child(trunk)

	# Shadow occluder (8-sided polygon matching canopy roughly)
	var occ_node := LightOccluder2D.new()
	var occ      := OccluderPolygon2D.new()
	var occ_pts  := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		occ_pts.append(Vector2(cos(a) * r * 0.8, sin(a) * r * 0.8 - 10.0))
	occ.polygon      = occ_pts
	occ_node.occluder = occ
	body.add_child(occ_node)

	return body

# ── Foliage detail sprites (non-blocking undergrowth) ────────────────────────
func _spawn_foliage_details() -> void:
	for _i in range(200):
		var tx := randf_range(-MAP_RADIUS, MAP_RADIUS) * TILE_SIZE
		var ty := randf_range(-MAP_RADIUS, MAP_RADIUS) * TILE_SIZE
		if Vector2(tx, ty).length() < 5.0 * TILE_SIZE:
			continue
		var bush := Polygon2D.new()
		var pts  := PackedVector2Array()
		var br   := randf_range(6.0, 14.0)
		for i in 6:
			var a := TAU * i / 6.0
			pts.append(Vector2(cos(a) * br, sin(a) * br))
		bush.polygon  = pts
		bush.color    = Color(randf_range(0.05, 0.18), randf_range(0.18, 0.35), randf_range(0.03, 0.12), 0.85)
		bush.position = Vector2(tx, ty)
		bush.z_index  = -1
		objects.add_child(bush)
