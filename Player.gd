extends CharacterBody3D

@onready var health_component = $HealthComponent
@onready var shoot_component = $ShootComponent
@onready var camera = $View/Camera3D
@onready var view = $View
@onready var mesh = $MeshInstance3D

var default_speed = 7.5
var current_speed = default_speed
var default_jump_velocity = 5.5
var current_jump_velocity = default_jump_velocity

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var input_dir

var weapon

var frozen = false

var current_colour = "Red"

func _ready():
	if !is_multiplayer_authority():
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())


func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		view.rotate_x(-event.relative.y * .005)
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
	if is_multiplayer_authority():
		current_speed = speed_effect
		current_jump_velocity = jump_height


@rpc ("call_local")
func increase_speed(speed_effect):
	current_speed += speed_effect


func update_current_class(new_weapon):
	if is_multiplayer_authority():
		var id = multiplayer.get_unique_id()
		if Global.players.has(id):
			if Global.players[id].Class != "" and weapon != null:
				view.remove_child(weapon)
			
			weapon = new_weapon
			view.add_child(new_weapon)
			
			change_material.rpc(current_colour)


@rpc ("any_peer", "call_local", "reliable")
func change_material(material):
	await get_tree().create_timer(0.01).timeout
	weapon = view.get_child(1)
	if material == "Blue":
		var blue = preload("res://materials/blue.tres")
		mesh.set_surface_override_material(0, blue)
		weapon.arm.set_surface_override_material(0, blue)
		current_colour = "Blue"
		change_layers.rpc(2)
	elif material == "Red":
		var red = preload("res://materials/red.tres")
		mesh.set_surface_override_material(0, red)
		weapon.arm.set_surface_override_material(0, red)
		change_layers.rpc(3)
		current_colour = "Red"

@rpc ("call_local", "any_peer")
func change_layers(team):
	if is_multiplayer_authority():
		mesh.visible = false
		
		self.set_collision_layer_value(team, true)
