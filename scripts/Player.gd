extends CharacterBody3D

@onready var health_component = $HealthComponent
@onready var shoot_component = $ShootComponent
@onready var camera = $View/Camera3D
@onready var view = $View
@onready var mesh = $Meshes/MeshInstance3D
@onready var mesh_outline = $Meshes/MeshInstance3D/Outline
@onready var hurtbox = $HurtboxComponent
@onready var mesh_eyes = $Meshes/Eyes
@onready var footstep_audio = $FootstepAudio
@onready var in_air_timer = $InAirTimer

@onready var footsteps = [
	preload("res://sounds/footsteps/footstep1.wav"), 
preload("res://sounds/footsteps/footstep2.wav"), 
preload("res://sounds/footsteps/footstep3.wav"), 
preload("res://sounds/footsteps/footstep4.wav"), 
preload("res://sounds/footsteps/footstep5.wav")
]

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

var sensitivity : float = 11
var sens_to_sway : float = 10

var in_dash = false
var in_air = false
var charging_dash = false

var flinch = false
var flinch_amount

var collided = false

#COLOURS

const BLUE = preload("res://materials/blue.tres")
const RED = preload("res://materials/red.tres")
const GREEN = preload("res://materials/green.tres")
const YELLOW = preload("res://materials/yellow.tres")
const PINK = preload("res://materials/pink.tres")

func _ready():
	if !is_multiplayer_authority():
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	var id = multiplayer.get_unique_id()
	if Global.players.has(id):
		sensitivity = Global.players[id].Sensitivity
	
	health_component.connect("flinch", _begin_flinch)
	
	change_layers.rpc()


func _begin_flinch(damage):
	flinch = true
	
	if damage <= 10:
		flinch_amount = 0.1
	elif damage <= 20:
		flinch_amount = 0.25
	elif damage <= 40:
		flinch_amount = 0.75
	elif damage <= 101:
		flinch_amount = 1.5
	else:
		flinch_amount = 0.1
	
	await get_tree().create_timer(0.1).timeout
	flinch = false

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
	
	if !is_on_floor():
		velocity.y -= current_gravity * delta
		in_air = true
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and !charging_dash:
		velocity.y = current_jump_velocity
		in_air_timer.start()
	
	
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if (in_air and is_on_floor() and !in_dash):
		in_air = false
		current_gravity = default_gravity
		play_footstep_audio.rpc()
	
	
	if !in_dash:
		if direction and !charging_dash:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
	elif in_dash and in_air and is_on_floor():
		in_dash = false
		in_air = false
		current_gravity = default_gravity
		play_footstep_audio.rpc()
	
	
	if !frozen:
		move_and_slide()
		camera_tilt.rpc(input_dir.x, delta)
		weapon_tilt.rpc(input_dir.x, delta)
		weapon_sway.rpc(delta)
	
	if flinch:
		var flinch_adjustment = view.rotation.x + flinch_amount * delta
		if flinch_adjustment > deg_to_rad(90):
			flinch_adjustment = deg_to_rad(90)
		view.rotation.x = flinch_adjustment


func change_hud_health(health_value):
	$HUD/Healthbar.value = health_value


@rpc ("any_peer", "call_local", "reliable")
func change_speed_and_jump(speed_effect = default_speed, jump_height = default_jump_velocity):
	current_speed = speed_effect
	current_jump_velocity = jump_height


@rpc ("call_local", "reliable")
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
	if want_timer:
		await get_tree().create_timer(0.1).timeout
	weapon = view.get_child(1)
	if material == "Blue":
		mesh.set_surface_override_material(0, BLUE)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, BLUE)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, BLUE)
		current_colour = "Blue"
		
	elif material == "Red":
		mesh.set_surface_override_material(0, RED)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, RED)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, RED)
		current_colour = "Red"
	elif material == "Green":
		mesh.set_surface_override_material(0, GREEN)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, GREEN)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, GREEN)
		current_colour = "Green"
	elif material == "Yellow":
		mesh.set_surface_override_material(0, YELLOW)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, YELLOW)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, YELLOW)
		current_colour = "Yellow"
	else:
		mesh.set_surface_override_material(0, PINK)
		if weapon != null:
			weapon.arm.set_surface_override_material(0, PINK)
			if weapon.arm_two != null:
				weapon.arm_two.set_surface_override_material(0, PINK)
		current_colour = "Pink"


@rpc ("call_local", "any_peer", "reliable")
func change_layers():
	if is_multiplayer_authority():
		mesh.cast_shadow = 3
		mesh_outline.cast_shadow = 3
		
		for eye in mesh_eyes.get_children():
			eye.cast_shadow = 3


@rpc ("call_local", "any_peer", "unreliable")
func camera_tilt(input_x, delta):
	self.rotation.z = lerp(self.rotation.z, -input_x * player_rotation_amount, sens_to_sway / 2 * delta)


@rpc ("call_local", "any_peer", "unreliable")
func weapon_tilt(input_x, delta):
	if weapon:
		if weapon.weapon_sway_node:
			if input_x != null:
				weapon.weapon_sway_node.rotation.z = lerp(weapon.weapon_sway_node.rotation.z, -input_x * weapon_rotation_amount, sens_to_sway / 2 * delta)


@rpc ("call_local", "any_peer", "unreliable")
func weapon_sway(delta):
	mouse_input = lerp(mouse_input, Vector2.ZERO, sens_to_sway * delta)
	if weapon:
		if weapon.weapon_sway_node:
			weapon.weapon_sway_node.rotation.x = lerp(weapon.weapon_sway_node.rotation.x, mouse_input.y * weapon_sway_amount, sens_to_sway * delta)
			weapon.weapon_sway_node.rotation.y = lerp(weapon.weapon_sway_node.rotation.y, mouse_input.x * weapon_sway_amount, sens_to_sway * delta)


func _on_in_air_timer_timeout():
	in_air = true


@rpc("any_peer", "call_local")
func play_footstep_audio():
	footstep_audio.stream = footsteps.pick_random()
	
	footstep_audio.pitch_scale = randf_range(0.8, 1.2)
	footstep_audio.play()
