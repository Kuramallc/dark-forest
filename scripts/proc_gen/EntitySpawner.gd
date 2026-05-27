extends Node
class_name EntitySpawner

## Scatters GroundItem pickups across the map using tile data from MapGenerator.

const GROUND_ITEM_SCENE := "res://scenes/items/GroundItem.tscn"

# Spawn rules: [ tile_types, min_dist, max_dist, item_id, qty_min, qty_max, chance ]
const SPAWN_RULES := [
	# Wood piles — grass/deep tiles, anywhere outside home
	[[ MapGenerator.T_GRASS, MapGenerator.T_DEEP ], 7.0, 999.0, "wood",         2, 5,  0.028],
	# Stone clusters — stone tiles only
	[[ MapGenerator.T_STONE ],                       5.0, 999.0, "stone",        1, 3,  0.18 ],
	# Berries — grass, mid range
	[[ MapGenerator.T_GRASS ],                       8.0,  28.0, "berries",      1, 4,  0.018],
	# Mushrooms — deep forest
	[[ MapGenerator.T_DEEP ],                       14.0, 999.0, "mushroom",     1, 2,  0.012],
	# Healing herbs — rare, anywhere beyond home
	[[ MapGenerator.T_GRASS, MapGenerator.T_DEEP ], 10.0, 999.0, "healing_herb", 1, 1,  0.004],
	# Iron ore — stone tiles far from home
	[[ MapGenerator.T_STONE ],                      22.0, 999.0, "iron_ore",     1, 2,  0.10 ],
]

func spawn_all(tile_map: Dictionary, entities_node: Node2D) -> void:
	var scene := load(GROUND_ITEM_SCENE) as PackedScene
	if not scene:
		push_error("EntitySpawner: could not load GroundItem scene.")
		return

	for tile_pos: Vector2i in tile_map.keys():
		var tile_id: int = tile_map[tile_pos]
		var dist    := Vector2(tile_pos).length()
		var wpos    := MapGenerator.tile_to_world_center(tile_pos)

		for rule in SPAWN_RULES:
			var types: Array   = rule[0]
			var min_d: float   = rule[1]
			var max_d: float   = rule[2]
			var item:  String  = rule[3]
			var q_min: int     = rule[4]
			var q_max: int     = rule[5]
			var chance: float  = rule[6]

			if tile_id not in types:
				continue
			if dist < min_d or dist > max_d:
				continue
			if randf() > chance:
				continue

			var item_node := scene.instantiate() as Node2D
			var jitter    := Vector2(randf_range(-24, 24), randf_range(-24, 24))
			item_node.position = wpos + jitter
			if item_node.has_method("setup"):
				item_node.setup(item, randi_range(q_min, q_max))
			entities_node.add_child(item_node)
			break   # one item per tile at most
