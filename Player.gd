extends CharacterBody3D

@onready var health_component = $HealthComponent
@onready var shoot_component = $ShootComponent
@onready var camera = $View/Camera3D
@onready var view = $View
@onready var mesh = $MeshInstance3D
@onready var hurtbox = $HurtboxComponent

var default_speed = 6.5
var current_speed = default_speed
var default_jump_velocity = 6.5
var current_jump_velocity = default_jump_velocity

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var input_dir

var weapon

var frozen = false

var current_colour = "Red"

var sensitivity = 11

func _ready():
	if !is_multiplayer_authority():
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	var id = multiplayer.get_unique_id()
	if Global.players.has(id):
		sensitivity = Global.players[id].Sensitivity
	



func _enter_tree():
	set_multiplayer_authority(str(name).to_int())


func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity / 10000)
		view.rotate_x(-event.relative.y * sensitivity / 10000)
		view.rotation.x = clamp(view.rotation.x, -PI/2, PI/2)


func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = current_jump_velocity
	
	
	
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	if !frozen:
		move_and_slide()


func change_hud_health(health_value):
	$HUD/Healthbar.value = health_value


@rpc ("any_peer", "call_local")
func change_speed_and_jump(speed_effect = default_speed, jump_height = default_jump_velocity):
	current_speed = speed_effect
	current_jump_velocity = jump_height
	
	if speed_effect == default_speed:
		camera.fov = 90
	elif speed_effect == 1.5:
		camera.fov = 70


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
		current_colour = "Blue"
		change_layers.rpc()
	elif material == "Red":
		var red = preload("res://materials/red.tres")
		mesh.set_surface_override_material(0, red)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, red)
		change_layers.rpc()
		current_colour = "Red"
	elif material == "Green":
		var green = preload("res://materials/green.tres")
		mesh.set_surface_override_material(0, green)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, green)
		change_layers.rpc()
		current_colour = "Green"
	elif material == "Yellow":
		var yellow = preload("res://materials/yellow.tres")
		mesh.set_surface_override_material(0, yellow)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, yellow)
		change_layers.rpc()
		current_colour = "Yellow"


@rpc ("call_local", "any_peer")
func change_layers():
	if is_multiplayer_authority():
		mesh.visible = false
