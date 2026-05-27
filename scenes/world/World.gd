extends Node2D

## World orchestrator — builds tilemap, spawns trees, items, and fog-of-war.
## Phase 2: all map data driven by MapGenerator (procedural noise).

const TILE_PX := MapGenerator.TILE_PX   # 64

@onready var ground:     TileMapLayer   = $Ground
@onready var objects:    Node2D         = $Objects
@onready var entities:   Node2D         = $Entities
@onready var canvas_mod: CanvasModulate = $CanvasModulate
@onready var day_night:  DayNightCycle  = $DayNightCycle
@onready var fog:        FogOfWar       = $FogOfWar
@onready var player:     CharacterBody2D = $Entities/Player

func _ready() -> void:
	var seed_val := randi()   # random seed each run

	# 1. Tileset (palette, generated once)
	_build_tileset()

	# 2. Procedural map data
	var gen  := MapGenerator.new()
	var data := gen.generate(seed_val)
	var tile_map: Dictionary = data["tiles"]
	var trees:    Array       = data["trees"]

	# 3. Paint tiles
	for tile_pos: Vector2i in tile_map.keys():
		var atlas_x: int = tile_map[tile_pos]
		ground.set_cell(tile_pos, 0, Vector2i(atlas_x, 0))

	# 4. Spawn trees
	for wpos: Vector2 in trees:
		objects.add_child(_make_tree(wpos))

	# 5. Foliage details
	_spawn_foliage(tile_map)

	# 6. Scatter ground resources
	var spawner := EntitySpawner.new()
	spawner.spawn_all(tile_map, entities)

	# 7. Fog of war
	fog.setup(player)

	# 8. Ensure player torch uses correct item_mask
	var torch := player.get_node_or_null("Torch") as PointLight2D
	if torch:
		torch.item_mask = 1

	# 9. Notify minimap (and any other listeners) that the map is ready
	#    Defer by one frame so all _ready() calls in the HUD finish first
	call_deferred("_emit_map_ready", tile_map)

func _emit_map_ready(tile_map: Dictionary) -> void:
	EventBus.map_ready.emit(tile_map, fog.fog_tex, player)

# ── Tileset (programmatic, no asset files needed) ────────────────────────────
func _build_tileset() -> void:
	var ts     := TileSet.new()
	ts.tile_size = Vector2i(TILE_PX, TILE_PX)
	var source := TileSetAtlasSource.new()
	var img    := Image.create(TILE_PX * 4, TILE_PX, false, Image.FORMAT_RGBA8)

	_paint_tile(img, MapGenerator.T_GRASS, Color(0.11, 0.20, 0.08))
	_paint_tile(img, MapGenerator.T_DIRT,  Color(0.30, 0.22, 0.12))
	_paint_tile(img, MapGenerator.T_DEEP,  Color(0.04, 0.07, 0.03))
	_paint_tile(img, MapGenerator.T_STONE, Color(0.33, 0.32, 0.30))

	source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(TILE_PX, TILE_PX)
	for i in range(4):
		source.create_tile(Vector2i(i, 0))
	ts.add_source(source, 0)
	ground.tile_set = ts

func _paint_tile(img: Image, col: int, base: Color) -> void:
	var bx := col * TILE_PX
	for x in range(TILE_PX):
		for y in range(TILE_PX):
			var j := randf_range(-0.025, 0.025)
			img.set_pixel(bx + x, y, Color(
				clampf(base.r + j, 0.0, 1.0),
				clampf(base.g + j, 0.0, 1.0),
				clampf(base.b + j, 0.0, 1.0)
			))

# ── Tree factory ──────────────────────────────────────────────────────────────
func _make_tree(pos: Vector2) -> StaticBody2D:
	var body       := StaticBody2D.new()
	body.position       = pos
	body.collision_layer = 2
	body.collision_mask  = 0

	# Collision circle
	var col   := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape    = shape
	body.add_child(col)

	# Canopy polygon (irregular circle)
	var r      := randf_range(22.0, 34.0)
	var canopy := Polygon2D.new()
	var pts    := PackedVector2Array()
	for i in 14:
		var a  := TAU * i / 14.0
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
		Vector2(-5, 8),  Vector2(5, 8),
		Vector2(4,  26), Vector2(-4, 26),
	])
	trunk.color = Color(0.32, 0.20, 0.09)
	body.add_child(trunk)

	# LightOccluder2D — casts real shadows from player torch
	var occ_node := LightOccluder2D.new()
	var occ      := OccluderPolygon2D.new()
	var occ_pts  := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		occ_pts.append(Vector2(cos(a) * r * 0.78, sin(a) * r * 0.78 - 10.0))
	occ.polygon       = occ_pts
	occ_node.occluder = occ
	body.add_child(occ_node)

	return body

# ── Foliage details (non-blocking undergrowth polygons) ───────────────────────
func _spawn_foliage(tile_map: Dictionary) -> void:
	var foliage_count := 600   # more variety on the larger map
	var r             := MapGenerator.MAP_RADIUS

	for _i in range(foliage_count):
		var tx := randf_range(-r, r) * TILE_PX
		var ty := randf_range(-r, r) * TILE_PX
		if Vector2(tx, ty).length() < 5.5 * TILE_PX:
			continue
		var bush := Polygon2D.new()
		var pts  := PackedVector2Array()
		var br   := randf_range(5.0, 13.0)
		for i in 6:
			var a := TAU * i / 6.0
			pts.append(Vector2(cos(a) * br, sin(a) * br))
		bush.polygon  = pts
		bush.color    = Color(
			randf_range(0.04, 0.16),
			randf_range(0.16, 0.34),
			randf_range(0.02, 0.10),
			0.80
		)
		bush.position = Vector2(tx, ty)
		bush.z_index  = -1
		objects.add_child(bush)
