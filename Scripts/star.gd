extends Node2D

var game_manager
var collected = false

func _ready():
	game_manager = get_tree().root.get_node("Main")
	add_to_group("star")
	
	# Connect the Area2D body_entered signal
	var area = $Area2D
	if area:
		area.body_entered.connect(_on_body_entered)

func _process(delta):
	if game_manager and game_manager.is_game_active and not game_manager.is_game_over:
		position.x -= game_manager.scroll_speed * delta
		
		# Remove when off screen
		if position.x < -100:
			queue_free()

func _on_body_entered(body):
	if collected:
		return
	
	# Check if it's the plane
	if body.name == "Plane" or body.is_in_group("player"):
		collected = true
		if game_manager:
			game_manager.collect_star()
		queue_free()
