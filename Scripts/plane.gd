extends CharacterBody2D

const GRAVITY = 900.0
const JUMP_FORCE = -400.0
const MAX_ROTATION = 25.0
const MIN_ROTATION = -25.0

# Puff effect textures
var puff_large_texture: Texture2D
var puff_small_texture: Texture2D

@onready var animated_sprite = $AnimatedSprite2D
var game_manager

func _ready():
	game_manager = get_tree().root.get_node("Main")
	animated_sprite.play("flying")
	
	# Load puff textures
	puff_large_texture = load("res://Assets/Sprites/puffLarge.png")
	puff_small_texture = load("res://Assets/Sprites/puffSmall.png")

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
	
	# Collision Check with ground, spikes, barriers etc.
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider:
				# Check by group first (most reliable)
				if collider.is_in_group("ground") or collider.is_in_group("spike") or collider.is_in_group("barrier"):
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
				
				# Check if it's a barrier
				if "Barrier" in collider_name or "Barrier" in parent_name:
					die()
					return

func jump():
	velocity.y = JUMP_FORCE
	_spawn_puff_effect()

func _spawn_puff_effect():
	# Spawn large puff
	var puff_large = Sprite2D.new()
	puff_large.texture = puff_large_texture
	puff_large.global_position = global_position + Vector2(-20, 10)
	puff_large.z_index = -1
	get_parent().add_child(puff_large)
	
	# Spawn small puff
	var puff_small = Sprite2D.new()
	puff_small.texture = puff_small_texture
	puff_small.global_position = global_position + Vector2(-30, 0)
	puff_small.z_index = -1
	get_parent().add_child(puff_small)
	
	# Animate puffs with tweens
	_animate_puff(puff_large, 0.4)
	_animate_puff(puff_small, 0.35)

func _animate_puff(puff: Sprite2D, duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out
	tween.tween_property(puff, "modulate:a", 0.0, duration)
	
	# Move down and left
	tween.tween_property(puff, "position:y", puff.position.y + 30, duration)
	tween.tween_property(puff, "position:x", puff.position.x - 40, duration)
	
	# Scale down slightly
	tween.tween_property(puff, "scale", Vector2(0.5, 0.5), duration)
	
	# Clean up after animation
	tween.chain().tween_callback(puff.queue_free)

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
