extends Node3D

const FIELD_WIDTH := 22.0
const FIELD_LENGTH := 26.0
const HOLE_SIZE := 3.4
const HOLES := [Vector2(0, -6), Vector2(-5, -5), Vector2(5, -5), Vector2(0, 8)]
const GOAL_POSITION := Vector2(0, -8)
const START_PLAYER := Vector3(0, 0.55, 4)
const START_PUCK := Vector3(0, 0.22, 0)
const BEST_TIME_FILE := "user://best_time.cfg"

@onready var ground: StaticBody3D = $Ground
@onready var ground_collision: CollisionShape3D = $Ground/CollisionShape3D
@onready var player: CharacterBody3D = $Player
@onready var puck: RigidBody3D = $Puck
@onready var level_geometry: Node3D = $LevelGeometry
@onready var level_label: Label = $Interface/LevelLabel
@onready var timer_label: Label = $Interface/TimerLabel
@onready var result_label: Label = $Interface/ResultLabel

var level := 1
var start_time_ms := 0
var finished := false
var changing_level := false
var best_time := INF


func _ready() -> void:
	var saved := ConfigFile.new()
	if saved.load(BEST_TIME_FILE) == OK:
		best_time = float(saved.get_value("scores", "best_seconds", INF))
	start_time_ms = Time.get_ticks_msec()
	_load_level()


func _process(_delta: float) -> void:
	if not finished:
		timer_label.text = "Aika: %.2f s" % _elapsed_seconds()


func _physics_process(_delta: float) -> void:
	if finished or changing_level:
		return
	if level < 5 and puck.global_position.y < -0.65:
		changing_level = true
		call_deferred("_advance_level")
	elif player.global_position.y < -2.0:
		# Pelaajan oma putoaminen palauttaa hänet kentälle.
		player.global_position = START_PLAYER
		player.velocity = Vector3.ZERO


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		level = 1
		finished = false
		changing_level = false
		start_time_ms = Time.get_ticks_msec()
		_load_level()
		get_viewport().set_input_as_handled()


func _elapsed_seconds() -> float:
	return (Time.get_ticks_msec() - start_time_ms) / 1000.0


func _advance_level() -> void:
	level += 1
	_load_level()
	changing_level = false


func _load_level() -> void:
	for child in level_geometry.get_children():
		level_geometry.remove_child(child)
		child.queue_free()

	var has_hole := level < 5
	ground.visible = not has_hole
	ground_collision.disabled = has_hole
	level_label.text = "Kenttä %d / 5" % level
	result_label.visible = false
	player.set_physics_process(true)
	player.global_position = START_PLAYER
	player.velocity = Vector3.ZERO
	puck.freeze = true
	puck.global_position = START_PUCK
	puck.linear_velocity = Vector3.ZERO
	puck.angular_velocity = Vector3.ZERO
	puck.freeze = false

	if has_hole:
		_build_hole_level(HOLES[level - 1])
	else:
		_build_goal()


func _build_hole_level(hole: Vector2) -> void:
	var half_hole := HOLE_SIZE / 2.0
	var left_edge := hole.x - half_hole
	var right_edge := hole.x + half_hole
	var top_edge := hole.y - half_hole
	var bottom_edge := hole.y + half_hole
	_add_floor(Vector2((-FIELD_WIDTH / 2.0 + left_edge) / 2.0, 0),
		Vector2(left_edge + FIELD_WIDTH / 2.0, FIELD_LENGTH))
	_add_floor(Vector2((right_edge + FIELD_WIDTH / 2.0) / 2.0, 0),
		Vector2(FIELD_WIDTH / 2.0 - right_edge, FIELD_LENGTH))
	_add_floor(Vector2(hole.x, (-FIELD_LENGTH / 2.0 + top_edge) / 2.0),
		Vector2(HOLE_SIZE, top_edge + FIELD_LENGTH / 2.0))
	_add_floor(Vector2(hole.x, (bottom_edge + FIELD_LENGTH / 2.0) / 2.0),
		Vector2(HOLE_SIZE, FIELD_LENGTH / 2.0 - bottom_edge))

	# Tumma pohja on alempana kuin jää, joten kiekko näkyy putoavan.
	var pit := MeshInstance3D.new()
	var pit_mesh := BoxMesh.new()
	pit_mesh.size = Vector3(HOLE_SIZE, 0.1, HOLE_SIZE)
	var pit_material := StandardMaterial3D.new()
	pit_material.albedo_color = Color(0.025, 0.045, 0.09)
	pit_mesh.material = pit_material
	pit.mesh = pit_mesh
	pit.position = Vector3(hole.x, -1.4, hole.y)
	level_geometry.add_child(pit)


func _add_floor(center: Vector2, size: Vector2) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(center.x, -0.1, center.y)
	body.physics_material_override = ground.physics_material_override
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(size.x, 0.2, size.y)
	box_mesh.material = $Ground/Mesh.mesh.material
	mesh_instance.mesh = box_mesh
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box_mesh.size
	collision.shape = box_shape
	body.add_child(collision)
	level_geometry.add_child(body)


func _build_goal() -> void:
	var marker := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.6
	disc.bottom_radius = 1.6
	disc.height = 0.04
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.68, 0.08)
	gold.emission_enabled = true
	gold.emission = Color(0.5, 0.18, 0.01)
	disc.material = gold
	marker.mesh = disc
	marker.position = Vector3(GOAL_POSITION.x, 0.025, GOAL_POSITION.y)
	level_geometry.add_child(marker)

	var goal := Area3D.new()
	goal.position = Vector3(GOAL_POSITION.x, 0.2, GOAL_POSITION.y)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.3
	shape.height = 0.5
	collision.shape = shape
	goal.add_child(collision)
	level_geometry.add_child(goal)
	goal.body_entered.connect(_on_goal_body_entered)


func _on_goal_body_entered(body: Node3D) -> void:
	if body != puck or finished:
		return
	finished = true
	var final_time := _elapsed_seconds()
	timer_label.text = "Aika: %.2f s" % final_time
	if final_time < best_time:
		best_time = final_time
		var saved := ConfigFile.new()
		saved.set_value("scores", "best_seconds", best_time)
		saved.save(BEST_TIME_FILE)
	result_label.text = "MAALI!\nAikasi: %.2f s\nParas aika: %.2f s\nPaina R aloittaaksesi uudelleen" % [final_time, best_time]
	result_label.visible = true
	player.set_physics_process(false)
	puck.set_deferred("freeze", true)
