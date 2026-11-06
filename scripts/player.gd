extends CharacterBody3D

# Nopeutta voi muuttaa myös Godot-editorin Inspectorissa.
@export var speed: float = 6.0
@export var puck_hit_speed: float = 7.0

@onready var game_camera: Camera3D = get_node("../Camera3D")
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	# Input.get_vector yhdistää neljä näppäintä yhdeksi 2D-suunnaksi.
	# W on eteenpäin (-Z) ja S taaksepäin (+Z).
	var input_direction := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var move_direction := Vector3(input_direction.x, 0.0, input_direction.y)
	var move_speed := speed

	# Hiiren vasenta painiketta pidettäessä seurataan osoitinta kentän tasossa.
	# Näppäimistö saa etusijan, jos sitä käytetään samaan aikaan.
	if move_direction.is_zero_approx() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_position := get_viewport().get_mouse_position()
		var ray_origin := game_camera.project_ray_origin(mouse_position)
		var ray_direction := game_camera.project_ray_normal(mouse_position)
		var target: Variant = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)
		if target is Vector3:
			var offset: Vector3 = target - global_position
			offset.y = 0.0
			if offset.length() > 0.15:
				move_direction = offset.normalized()
				move_speed = minf(speed, offset.length() * 5.0)

	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed

	# Painovoima pitää CharacterBody3D-pelaajan kiinni lattiassa.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	# Osuma antaa kiekolle nopean alkukiihdytyksen. Jatkuva työntö ei
	# lisää vauhtia rajatta, koska huomioimme kiekon nykyisen nopeuden.
	if move_direction.length_squared() > 0.0:
		for index in get_slide_collision_count():
			var collision := get_slide_collision(index)
			var body := collision.get_collider() as RigidBody3D
			if body != null and body.is_in_group("puck"):
				var direction := move_direction.normalized()
				var current_speed := body.linear_velocity.dot(direction)
				var extra_speed := maxf(puck_hit_speed - current_speed, 0.0)
				body.apply_central_impulse(direction * extra_speed * body.mass)
