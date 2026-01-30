extends Node2D

var game_manager

func _ready():
	game_manager = get_tree().root.get_node("Main")
	# Add to spike group for collision detection
	add_to_group("spike")

func _process(delta):
	if game_manager and game_manager.is_game_active and not game_manager.is_game_over:
		position.x -= game_manager.scroll_speed * delta
		
		# Remove when off screen
		if position.x < -150:
			queue_free()
