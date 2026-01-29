extends Node

signal game_over
signal game_started
signal restart_game

var is_game_active = false
var is_game_over = false
var score = 0
var scroll_speed = 200.0

@onready var ui_canvas = $CanvasLayer
@onready var game_over_screen = $CanvasLayer/GameOverControl
@onready var restart_button = $CanvasLayer/GameOverControl/RestartButton

func _ready():
	# Configure custom cursor
	var arrow = load("res://Assets/Sprites/UI/tap.png")
	Input.set_custom_mouse_cursor(arrow)
	
	restart_button.pressed.connect(_on_restart_pressed)
	game_over_screen.visible = false
	start_game()

func start_game():
	is_game_active = true
	is_game_over = false
	score = 0
	game_over_screen.visible = false
	emit_signal("game_started")

func end_game():
	if is_game_over: return
	is_game_over = true
	is_game_active = false
	game_over_screen.visible = true
	emit_signal("game_over")

func _on_restart_pressed():
	get_tree().reload_current_scene()
