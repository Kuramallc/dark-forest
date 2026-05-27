extends Node

# Player
signal stats_changed(health: float, stamina: float, hunger: float, max_health: float, max_stamina: float, max_hunger: float)
signal player_died
signal player_entered_home
signal player_left_home

# World / time
signal day_changed(day_number: int)
signal phase_changed(phase_name: String)
# Emitted once after procedural generation finishes; minimap listens for this
signal map_ready(tile_map: Dictionary, fog_tex: ImageTexture, player: Node2D)

# Items / combat
signal item_picked_up(item_id: String, quantity: int)
signal enemy_killed(enemy_type: String, xp: int)
signal xp_gained(amount: int)
