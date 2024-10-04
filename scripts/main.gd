extends Node

# preload obstacles
var stump_scene = preload("res://scenes/stump.tscn")
var bird_scene = preload("res://scenes/bird.tscn")
var rock_scene = preload("res://scenes/rock.tscn")
var barrel_scene = preload("res://scenes/barrel.tscn")
var obstacle_types := [stump_scene, rock_scene, barrel_scene]
var obstacles : Array
var bird_heights := [200, 390]

# game variables
const DINO_START_POSITION := Vector2i(150, 485)
const CAM_START_POSITION := Vector2i(576, 324)
const START_SPEED : float = 10
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000
const SCORE_MODIFIER : int = 10
const MAX_DIFFICULTY : int = 2
var speed : float
var screen_size : Vector2i
var ground_height : int
var score : int
var game_running : bool
var last_obstacle
var difficulty : int
var high_score : int

func _ready() -> void:
	screen_size = get_viewport().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()

func new_game() -> void:
	# reset variables
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0

	# remove obstacles
	for obstacle in obstacles:
		obstacle.queue_free()
	obstacles.clear()

	# reset nodes
	$Dino.position = DINO_START_POSITION
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POSITION
	$Ground.position = Vector2i(0, 0)

	# reset HUD
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

func _process(delta: float) -> void:
	if game_running:
		speed = START_SPEED + float(score) / SPEED_MODIFIER

		if speed > MAX_SPEED:
			speed = MAX_SPEED

		adjust_difficulty()

		# generate obstacles
		generate_obstacles()

		# move dino and camera
		$Dino.position.x += speed * delta * 60
		$Camera2D.position.x += speed * delta * 60

		# update score
		score += int(speed)
		show_score()

		# update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x

		# remove obstacles that are off screen
		for obstacle in obstacles:
			if obstacle.position.x < $Camera2D.position.x - screen_size.x:
				remove_obstacle(obstacle)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func show_score() -> void:
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(float(score) / SCORE_MODIFIER)

func generate_obstacles() -> void:
	# generate ground obstacles
	if obstacles.is_empty() or last_obstacle.position.x < score + randi_range(300, 500):
		var obstacle_type = obstacle_types[randi() % obstacle_types.size()]
		var obstacle
		var max_obstacles = difficulty + 1
		for i in range(randi() % max_obstacles + 1):
			obstacle = obstacle_type.instantiate()
			var obstacle_height = obstacle.get_node("Sprite2D").texture.get_height()
			var obstacle_scale = obstacle.get_node("Sprite2D").scale
			var obstacle_x : int = screen_size.x + score + 100 + (i * 100)
			var obstacle_y : int = screen_size.y - ground_height - (obstacle_height * obstacle_scale.y / 2) + 5
			last_obstacle = obstacle
			add_obstacle(obstacle, obstacle_x, obstacle_y)
			# chance to spawn bird
		if difficulty == MAX_DIFFICULTY:
			if randi() % 2 == 0:
				# spawn bird
				obstacle = bird_scene.instantiate()
				var obstacle_x : int = screen_size.x + score + 100
				var obstacle_y : int = bird_heights[randi() % bird_heights.size()]
				add_obstacle(obstacle, obstacle_x, obstacle_y)
	

func add_obstacle(obstacle, x, y) -> void:
	obstacle.position = Vector2(x, y)
	obstacle.body_entered.connect(hit_obstacle)
	add_child(obstacle)
	obstacles.append(obstacle)

func adjust_difficulty():
	difficulty = int(float(score) / SPEED_MODIFIER)

	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func remove_obstacle(obstacle) -> void:
	obstacle.queue_free()
	obstacles.erase(obstacle)

func hit_obstacle(body) -> void:
	if body.name == "Dino":
		game_over()

func game_over() -> void:
	check_high_score()
	get_tree().paused = true
	game_running = false
	$GameOver.show()

func check_high_score() -> void:
	if score > high_score:
		high_score = int(float(score) / SCORE_MODIFIER)
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score)
