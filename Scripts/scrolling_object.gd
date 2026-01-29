extends Node2D

@export var speed_scale: float = 1.0
var game_manager

func _ready():
	# Find Game Manager in the scene tree
	game_manager = get_tree().root.get_node("Main") # Assuming Main.gd or GameManager is on Main node
	if not game_manager:
		# Fallback if GameManager is not directly on Main, try to find by type or name
		pass

func _process(delta):
	if game_manager and game_manager.is_game_active and not game_manager.is_game_over:
		position.x -= game_manager.scroll_speed * speed_scale * delta
		
		# Reset position logic will be handled by the parent controller or self-check
		# For infinite scrolling ground, we typically use the width of the sprite
		if position.x < -800: # Approximate screen width + buffer
			position.x += 800 * 2 # Jump forward to loop
