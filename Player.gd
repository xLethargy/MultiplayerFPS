extends CharacterBody3D

@onready var animation_player = $AnimationPlayer
@onready var health_component = $HealthComponent
@onready var shoot_component = $ShootComponent
@onready var camera = $View/Camera3D
@onready var view = $View
@onready var mesh = $MeshInstance3D
@onready var hurtbox = $HurtboxComponent
@onready var in_air_timer = Timer.new()

var default_speed = 6.5
var current_speed = default_speed
var default_jump_velocity = 6.5
var current_jump_velocity = default_jump_velocity

var player_rotation_amount = 0
var weapon_rotation_amount = 0.25

var weapon_sway_amount : float = 0.01

var mouse_input : Vector2

var default_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_gravity = default_gravity

var input_dir

var weapon

var frozen = false

var current_colour = "Red"

var sensitivity = 11

var in_dash = false
var in_air = false
var charging_dash = false

func _ready():
	if !is_multiplayer_authority():
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	var id = multiplayer.get_unique_id()
	if Global.players.has(id):
		sensitivity = Global.players[id].Sensitivity
	
	in_air_timer.wait_time = 0.3
	in_air_timer.connect("timeout", _on_in_air_timer_timeout)
	add_child(in_air_timer, true)


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())


func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity / 10000)
		view.rotate_x(-event.relative.y * sensitivity / 10000)
		view.rotation.x = clamp(view.rotation.x, -PI/2, PI/2)
		mouse_input = event.relative


func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= current_gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and !charging_dash:
		velocity.y = current_jump_velocity
	
	
	
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if !in_dash:
		if direction and !charging_dash:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
	elif in_dash and !in_air and is_on_floor():
		in_dash = false
		current_gravity = default_gravity
	
	if !frozen:
		move_and_slide()
		camera_tilt.rpc(input_dir.x, delta)
		weapon_tilt.rpc(input_dir.x, delta)
		weapon_sway.rpc(delta)


func change_hud_health(health_value):
	$HUD/Healthbar.value = health_value


@rpc ("any_peer", "call_local")
func change_speed_and_jump(speed_effect = default_speed, jump_height = default_jump_velocity):
	current_speed = speed_effect
	current_jump_velocity = jump_height


@rpc ("call_local")
func increase_speed(speed_effect):
	current_speed += speed_effect


func update_current_class(new_weapon):
	if is_multiplayer_authority():
		var id = multiplayer.get_unique_id()
		sensitivity = Global.players[id].Sensitivity
		if Global.players.has(id):
			if Global.players[id].Class != "" and weapon != null:
				view.remove_child(weapon)
			
			weapon = new_weapon
			view.add_child(new_weapon)
			
			change_material.rpc(current_colour, false)

@rpc ("any_peer", "call_local", "reliable")
func change_material(material, want_timer = true):
	#need to connect signal for when player loads
	if want_timer:
		await get_tree().create_timer(0.1).timeout
	weapon = view.get_child(1)
	if material == "Blue":
		var blue = preload("res://materials/blue.tres")
		mesh.set_surface_override_material(0, blue)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, blue)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, blue)
		current_colour = "Blue"
		change_layers.rpc()
	elif material == "Red":
		var red = preload("res://materials/red.tres")
		mesh.set_surface_override_material(0, red)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, red)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, red)
		change_layers.rpc()
		current_colour = "Red"
	elif material == "Green":
		var green = preload("res://materials/green.tres")
		mesh.set_surface_override_material(0, green)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, green)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, green)
		change_layers.rpc()
		current_colour = "Green"
	elif material == "Yellow":
		var yellow = preload("res://materials/yellow.tres")
		mesh.set_surface_override_material(0, yellow)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, yellow)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, yellow)
		change_layers.rpc()
		current_colour = "Yellow"


@rpc ("call_local", "any_peer")
func change_layers():
	if is_multiplayer_authority():
		mesh.visible = false


@rpc ("call_local", "any_peer")
func camera_tilt(input_x, delta):
	self.rotation.z = lerp(self.rotation.z, -input_x * player_rotation_amount, 5 * delta)


@rpc ("call_local", "any_peer")
func weapon_tilt(input_x, delta):
	if weapon:
		if weapon.weapon_sway_node:
			weapon.weapon_sway_node.rotation.z = lerp(weapon.weapon_sway_node.rotation.z, -input_x * weapon_rotation_amount, 5 * delta)


@rpc ("call_local", "any_peer")
func weapon_sway(delta):
	mouse_input = lerp(mouse_input, Vector2.ZERO, 10 * delta)
	if weapon:
		if weapon.weapon_sway_node:
			weapon.weapon_sway_node.rotation.x = lerp(weapon.weapon_sway_node.rotation.x, mouse_input.y * weapon_sway_amount, 10 * delta)
			weapon.weapon_sway_node.rotation.y = lerp(weapon.weapon_sway_node.rotation.y, mouse_input.x * weapon_sway_amount, 10 * delta)


func _on_in_air_timer_timeout():
	in_air = false
