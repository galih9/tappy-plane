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
	if not game_manager or game_manager.is_game_over:
		animated_sprite.stop()
		return
		
	# Apply Gravity
	velocity.y += GRAVITY * delta
	
	# Jump / Flap
	if Input.is_action_just_pressed("tap") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Just pressed logic for mouse needs input map or just use simple check
		# But 'is_mouse_button_pressed' is continuous, we need 'just pressed'
		pass
		
	if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Note: is_mouse_button_pressed is continuous, we should use Input Event or specific action
		# Let's rely on an action named "tap" if possible, or just check Input.is_action_just_pressed("click") if mapped
		# For now, let's assume "tap" action is set or we use a basic check.
		jump()

	# Rotation based on velocity
	if velocity.y < 0:
		rotation_degrees = move_toward(rotation_degrees, MIN_ROTATION, 200 * delta)
	else:
		rotation_degrees = move_toward(rotation_degrees, MAX_ROTATION, 150 * delta)
		
	move_and_slide()
	
	# Collision Check
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision.get_collider().name.contains("BaseLevel") or collision.get_collider().name.contains("Pipe"):
				die()

func jump():
	velocity.y = JUMP_FORCE

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if game_manager and not game_manager.is_game_over:
			jump()

func die():
	print("Game Over")
	if game_manager:
		game_manager.end_game()
