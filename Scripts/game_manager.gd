extends Node

signal game_over
signal game_started
signal restart_game
signal star_collected
signal biome_changed(biome_name: String)

var is_game_active = false
var is_game_over = false
var score = 0
var scroll_speed = 200.0
var distance: float = 0.0
var stars_collected: int = 0

# Spawn control
var spike_spawn_timer: float = 0.0
var star_spawn_timer: float = 0.0
var ceiling_spike_spawn_timer: float = 0.0
var spike_spawn_interval: float = 2.5
var star_spawn_interval: float = 3.5

# Cave mode (after 200m)
var cave_mode_enabled: bool = false
const CAVE_MODE_DISTANCE: float = 200.0

# Biome system
const BIOME_CHANGE_DISTANCE: float = 250.0
var current_biome_index: int = 0
var last_biome_distance: float = 0.0

# Biome configurations: [name, ground_texture, spike_up_texture, spike_down_texture]
var biomes: Array = [
	{
		"name": "dirt",
		"ground": "res://Assets/Sprites/groundDirt.png",
		"spike_up": "res://Assets/Sprites/rock.png",
		"spike_down": "res://Assets/Sprites/rockDown.png"
	},
	{
		"name": "rock",
		"ground": "res://Assets/Sprites/groundRock.png",
		"spike_up": "res://Assets/Sprites/rock.png",
		"spike_down": "res://Assets/Sprites/rockDown.png"
	},
	{
		"name": "grass",
		"ground": "res://Assets/Sprites/groundGrass.png",
		"spike_up": "res://Assets/Sprites/rockGrass.png",
		"spike_down": "res://Assets/Sprites/rockGrassDown.png"
	},
	{
		"name": "ice",
		"ground": "res://Assets/Sprites/groundIce.png",
		"spike_up": "res://Assets/Sprites/rockIce.png",
		"spike_down": "res://Assets/Sprites/rockIceDown.png"
	},
	{
		"name": "snow",
		"ground": "res://Assets/Sprites/groundSnow.png",
		"spike_up": "res://Assets/Sprites/rockSnow.png",
		"spike_down": "res://Assets/Sprites/rockSnowDown.png"
	}
]

# Cursor textures
var cursor_tap: Texture2D
var cursor_tap_tick: Texture2D
var cursor_timer: Timer

# Preloaded scenes
var spike_scene = preload("res://Scenes/base_spike.tscn")
var star_scene = preload("res://Scenes/stars.tscn")

@onready var ui_canvas = $CanvasLayer
@onready var game_over_screen = $CanvasLayer/GameOverControl
@onready var restart_button = $CanvasLayer/GameOverControl/RestartButton
@onready var start_game_screen = $CanvasLayer/StartGameControl
@onready var play_button = $CanvasLayer/StartGameControl/PlayButton
@onready var hud_label = $CanvasLayer/HUD/Label
@onready var parallax_bg = $Parallax2D
@onready var base_level_1 = $BaseLevel
@onready var base_level_2 = $BaseLevel2
@onready var ceiling_barrier = $CeilingBarrier

# Game Over UI labels
@onready var game_over_distance_label: Label = null
@onready var game_over_stars_label: Label = null

func _ready():
	# Configure custom cursor
	cursor_tap = load("res://Assets/Sprites/UI/tap.png")
	cursor_tap_tick = load("res://Assets/Sprites/UI/tapTick.png")
	Input.set_custom_mouse_cursor(cursor_tap)
	
	# Setup cursor timer
	cursor_timer = Timer.new()
	cursor_timer.one_shot = true
	cursor_timer.wait_time = 0.5
	cursor_timer.timeout.connect(_on_cursor_timer_timeout)
	add_child(cursor_timer)
	
	restart_button.pressed.connect(_on_restart_pressed)
	play_button.pressed.connect(_on_play_pressed)
	
	# Create game over UI labels if they don't exist
	_setup_game_over_labels()
	
	# Initial state - show start menu, hide game over
	game_over_screen.visible = false
	start_game_screen.visible = true
	is_game_active = false
	is_game_over = false
	
	# Hide ceiling barrier initially and disable collision
	if ceiling_barrier:
		ceiling_barrier.visible = false
		var shape = ceiling_barrier.get_node_or_null("StaticBody2D/CollisionShape2D")
		if shape:
			shape.disabled = true
	
	# Update HUD
	_update_hud()

func _setup_game_over_labels():
	# Check if labels already exist
	var distance_label_node = game_over_screen.get_node_or_null("FinalDistanceLabel")
	var stars_label_node = game_over_screen.get_node_or_null("FinalStarsLabel")
	
	if distance_label_node == null:
		# Create distance label
		game_over_distance_label = Label.new()
		game_over_distance_label.name = "FinalDistanceLabel"
		game_over_distance_label.text = "Distance: 0m"
		game_over_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over_distance_label.anchors_preset = Control.PRESET_CENTER
		game_over_distance_label.position = Vector2(-50, 30)
		game_over_distance_label.size = Vector2(200, 30)
		
		# Style the label
		var label_settings = LabelSettings.new()
		label_settings.font_size = 22
		label_settings.outline_size = 3
		label_settings.outline_color = Color.BLACK
		game_over_distance_label.label_settings = label_settings
		
		game_over_screen.add_child(game_over_distance_label)
	else:
		game_over_distance_label = distance_label_node
	
	if stars_label_node == null:
		# Create stars label
		game_over_stars_label = Label.new()
		game_over_stars_label.name = "FinalStarsLabel"
		game_over_stars_label.text = "Stars: 0"
		game_over_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over_stars_label.anchors_preset = Control.PRESET_CENTER
		game_over_stars_label.position = Vector2(-50, 60)
		game_over_stars_label.size = Vector2(200, 30)
		
		# Style the label
		var label_settings = LabelSettings.new()
		label_settings.font_size = 22
		label_settings.outline_size = 3
		label_settings.outline_color = Color.BLACK
		game_over_stars_label.label_settings = label_settings
		
		game_over_screen.add_child(game_over_stars_label)
	else:
		game_over_stars_label = stars_label_node

func _input(event):
	# Handle cursor click animation
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_trigger_click_cursor()

func _trigger_click_cursor():
	Input.set_custom_mouse_cursor(cursor_tap_tick)
	cursor_timer.start()

func _on_cursor_timer_timeout():
	Input.set_custom_mouse_cursor(cursor_tap)

func _process(delta):
	if is_game_active and not is_game_over:
		# Update distance (10m per second)
		distance += 10.0 * delta
		_update_hud()
		
		# Check for biome change
		_check_biome_change()
		
		# Enable cave mode after 200m
		if not cave_mode_enabled and distance >= CAVE_MODE_DISTANCE:
			_enable_cave_mode()
		
		# Spike spawning (after 50m)
		if distance >= 50.0:
			spike_spawn_timer -= delta
			if spike_spawn_timer <= 0:
				_spawn_spike(false) # Ground spike
				spike_spawn_timer = randf_range(1.5, 3.5)
		
		# Ceiling spike spawning (after cave mode enabled)
		if cave_mode_enabled:
			ceiling_spike_spawn_timer -= delta
			if ceiling_spike_spawn_timer <= 0:
				_spawn_spike(true) # Ceiling spike
				ceiling_spike_spawn_timer = randf_range(2.0, 4.0)
		
		# Star spawning (after 100m)
		if distance >= 100.0:
			star_spawn_timer -= delta
			if star_spawn_timer <= 0:
				_spawn_star()
				star_spawn_timer = randf_range(2.5, 5.0)

func _enable_cave_mode():
	cave_mode_enabled = true
	ceiling_spike_spawn_timer = 1.5
	
	# Show ceiling barrier
	if ceiling_barrier:
		ceiling_barrier.visible = true
		var shape = ceiling_barrier.get_node_or_null("StaticBody2D/CollisionShape2D")
		if shape:
			shape.disabled = false
	
	print("Cave mode enabled at ", int(distance), "m!")

func _check_biome_change():
	var distance_since_last_change = distance - last_biome_distance
	if distance_since_last_change >= BIOME_CHANGE_DISTANCE:
		last_biome_distance = distance
		current_biome_index = (current_biome_index + 1) % biomes.size()
		_apply_biome_change()

func _apply_biome_change():
	var biome = biomes[current_biome_index]
	var ground_texture = load(biome["ground"])
	
	# Update base level textures
	if base_level_1:
		var sprite1 = base_level_1.get_node_or_null("Sprite2D")
		if sprite1:
			sprite1.texture = ground_texture
	
	if base_level_2:
		var sprite2 = base_level_2.get_node_or_null("Sprite2D")
		if sprite2:
			sprite2.texture = ground_texture
	
	emit_signal("biome_changed", biome["name"])
	print("Biome changed to: ", biome["name"], " at ", int(distance), "m")

func get_current_biome() -> Dictionary:
	return biomes[current_biome_index]

func _update_hud():
	if hud_label:
		hud_label.text = "Distance: %dm | Stars: %d" % [int(distance), stars_collected]

func _spawn_spike(is_ceiling: bool):
	var spike = spike_scene.instantiate()
	var biome = get_current_biome()
	
	if is_ceiling:
		# Ceiling spike - spawn at top, rotated
		var spawn_y = randf_range(30, 100)
		spike.position = Vector2(600, spawn_y)
		spike.rotation_degrees = 180
		
		# Set ceiling spike texture
		var spike_texture = load(biome["spike_down"])
		var sprite = spike.get_node_or_null("Sprite2D")
		
		if sprite:
			sprite.texture = spike_texture
			# Reset rotation for down texture since it's already flipped
			spike.rotation_degrees = 0
			
			# Rotate the collision body to match the visual orientation
			# User requested a flip, so we use scale.y = -1 to flip vertical
			var body = spike.get_node_or_null("StaticBody2D")
			if body:
				body.scale.y = -1
				body.rotation_degrees = 0
	else:
		# Ground spike - normal spawn
		var spawn_y = randf_range(350, 450)
		spike.position = Vector2(600, spawn_y)
		
		# Set ground spike texture
		var spike_texture = load(biome["spike_up"])
		var sprite = spike.get_node_or_null("Sprite2D")
		if sprite:
			sprite.texture = spike_texture
	
	# Ensure spike renders behind the ground (ground usually has z_index 0)
	spike.z_index = -1
	
	add_child(spike)

func _spawn_star():
	var star = star_scene.instantiate()
	# Spawn on the right side of screen, random Y position
	# Adjust range based on cave mode
	var min_y = 80
	var max_y = 320 if not cave_mode_enabled else 280
	var spawn_y = randf_range(min_y, max_y)
	star.position = Vector2(650, spawn_y)
	add_child(star)

func collect_star():
	stars_collected += 1
	emit_signal("star_collected")
	_update_hud()

func _on_play_pressed():
	start_game()

func start_game():
	is_game_active = true
	is_game_over = false
	score = 0
	distance = 0.0
	stars_collected = 0
	spike_spawn_timer = 2.0
	star_spawn_timer = 3.0
	ceiling_spike_spawn_timer = 2.0
	cave_mode_enabled = false
	current_biome_index = 0
	last_biome_distance = 0.0
	
	# Hide ceiling barrier at start and disable collision
	if ceiling_barrier:
		ceiling_barrier.visible = false
		var shape = ceiling_barrier.get_node_or_null("StaticBody2D/CollisionShape2D")
		if shape:
			shape.disabled = true
	
	# Reset biome to initial
	_apply_biome_change()
	
	start_game_screen.visible = false
	game_over_screen.visible = false
	
	# Resume parallax if it was stopped
	if parallax_bg:
		parallax_bg.autoscroll = Vector2(-50, 0)
	
	_update_hud()
	emit_signal("game_started")

func end_game():
	if is_game_over: return
	is_game_over = true
	is_game_active = false
	
	# Stop parallax scrolling
	if parallax_bg:
		parallax_bg.autoscroll = Vector2.ZERO
	
	# Update game over labels with final stats
	if game_over_distance_label:
		game_over_distance_label.text = "Distance: %dm" % int(distance)
	if game_over_stars_label:
		game_over_stars_label.text = "Stars: %d" % stars_collected
	
	game_over_screen.visible = true
	emit_signal("game_over")

func _on_restart_pressed():
	get_tree().reload_current_scene()
