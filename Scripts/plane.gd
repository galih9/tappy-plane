extends CharacterBody2D

const GRAVITY = 900.0
const JUMP_FORCE = -400.0
const MAX_ROTATION = 25.0
const MIN_ROTATION = -25.0

@onready var animated_sprite = $AnimatedSprite2D
var game_manager

func _ready():
	game_manager = get_tree().root.get_node("Main")
	animated_sprite.play("flying")

func _physics_process(delta):
	if not game_manager:
		return
	
	# Don't process if game not started or game over
	if not game_manager.is_game_active or game_manager.is_game_over:
		if game_manager.is_game_over:
			animated_sprite.stop()
		return
		
	# Apply Gravity
	velocity.y += GRAVITY * delta
	
	# Rotation based on velocity
	if velocity.y < 0:
		rotation_degrees = move_toward(rotation_degrees, MIN_ROTATION, 200 * delta)
	else:
		rotation_degrees = move_toward(rotation_degrees, MAX_ROTATION, 150 * delta)
		
	move_and_slide()
	
	# Collision Check with ground, spikes, etc.
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider:
				# Check by group first (most reliable)
				if collider.is_in_group("ground") or collider.is_in_group("spike"):
					die()
					return
				
				# Fallback: check by name or parent name
				var collider_name = collider.name
				var parent_name = ""
				if collider.get_parent():
					parent_name = collider.get_parent().name
				
				# Check if it's ground/base level
				if "BaseLevel" in collider_name or "BaseLevel" in parent_name:
					die()
					return
				
				# Check if it's a spike/rock
				if "Spike" in collider_name or "Spike" in parent_name or "BaseSpike" in parent_name:
					die()
					return

func jump():
	velocity.y = JUMP_FORCE

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if game_manager and game_manager.is_game_active and not game_manager.is_game_over:
			jump()
	
	# Also handle keyboard/action
	if event.is_action_pressed("ui_accept"):
		if game_manager and game_manager.is_game_active and not game_manager.is_game_over:
			jump()

func die():
	print("Game Over - Distance: ", int(game_manager.distance), "m, Stars: ", game_manager.stars_collected)
	if game_manager:
		game_manager.end_game()
