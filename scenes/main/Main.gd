extends Node2D

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	# Phase 7: replace with proper Game Over screen
	print("Game Over! Days survived: %d" % GameState.day_count)
	get_tree().reload_current_scene()
