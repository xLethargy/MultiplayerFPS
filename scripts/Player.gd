extends CharacterBody3D

@onready var health_component = $HealthComponent
@onready var camera = $View/Camera3D
@onready var hat_node = $Meshes/Hat
@onready var hurtbox = $HurtboxComponent
@onready var footstep_audio = $FootstepAudio
@onready var in_air_timer = $InAirTimer
@onready var slow_timer = $SlowTimer
@onready var animation_player = $AnimationPlayer

@onready var spawn_audio = $SpawnAudio

@onready var freeze_count_timer = $FreezeCountTimer

@onready var footsteps = [
	preload("res://sounds/footsteps/footstep1.wav"), 
preload("res://sounds/footsteps/footstep2.wav"), 
preload("res://sounds/footsteps/footstep3.wav"), 
preload("res://sounds/footsteps/footstep4.wav"), 
preload("res://sounds/footsteps/footstep5.wav")
]

@onready var meshes = [$"Meshes/frog/RightLeg/right leg", $"Meshes/frog/RightLeg/right foot lets stomp_001", $"Meshes/frog/LeftLeg/left foot lets stomp", $"Meshes/frog/LeftLeg/left leg", $"Meshes/frog/nerd head", $"Meshes/frog/strong body"]
@onready var outlines = [$"Meshes/frog/strong body/BodyOutline", $"Meshes/frog/nerd head/HeadOutline", $"Meshes/frog/LeftLeg/left leg/LeftLegOutline", $"Meshes/frog/LeftLeg/left foot lets stomp/LeftFootOutline", $"Meshes/frog/RightLeg/right foot lets stomp_001/RightFootOutline", $"Meshes/frog/RightLeg/right leg/RightLegOutline"]
var default_speed = 15
var current_speed = default_speed
var old_speed = current_speed
var speed_cut = false

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

var current_colour

var sensitivity : float = 11
var sens_to_sway : float = 10

var in_dash = false
var in_air = false
var charging_dash = false

var flinch = false
var flinch_amount

var collided = false

var hat : Node3D = null

var count = 0
var charge_amount = 2.5

var movement_reduction : float = 1.5

signal remove_freeze_count

func _ready():
	if !is_multiplayer_authority():
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	var id = multiplayer.get_unique_id()
	if Global.players.has(id):
		sensitivity = Global.players[id].Sensitivity
	
	health_component.connect("flinch", _begin_flinch)
	health_component.connect("death", _play_positional_audio_rpc.bind(spawn_audio.get_path()))
	
	change_layers.rpc()
	_play_positional_audio.rpc(spawn_audio.get_path())


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
		var sensitivity_ratio : float = 1
		
		if camera.fov < 90:
			sensitivity_ratio = tan(90 / 2.0) / tan(camera.fov / 2.0)
		
		rotate_y(-event.relative.x * (sensitivity / sensitivity_ratio) / 10000)
		camera.rotate_x(-event.relative.y * (sensitivity / sensitivity_ratio) / 10000)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		mouse_input = event.relative


func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	
	if !is_on_floor():
		velocity.y -= current_gravity * delta
		in_air = true
		if (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")) and !speed_cut and !frozen:
			speed_cut = true
			old_speed = current_speed
			current_speed /= movement_reduction
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and !charging_dash:
		velocity.y = current_jump_velocity
		if (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")) and !speed_cut and !frozen:
			speed_cut = true
			old_speed = current_speed
			current_speed /= movement_reduction
	
	
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if (in_air and is_on_floor() and !in_dash):
		in_air = false
		current_gravity = default_gravity
		play_footstep_audio.rpc()
		if !frozen:
			current_speed = old_speed
			speed_cut = false
	
	
	if !in_dash:
		if direction and !charging_dash:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
	
	if in_dash:
		if !charging_dash:
			var boost = -get_global_transform().basis.z * charge_amount
			boost.y = 3
			count += 0.1
			boost.y -= count
			velocity =  boost * current_speed
	
	
	if in_dash and in_air and is_on_floor():
		count = 0
		in_dash = false
		in_air = false
		current_gravity = default_gravity
		play_footstep_audio.rpc()
		if !frozen:
			current_speed = old_speed
			speed_cut = false
	
	
	move_and_slide()
	camera_tilt.rpc(input_dir.x, delta)
	weapon_tilt.rpc(input_dir.x, delta)
	weapon_sway.rpc(delta)
	
	if flinch:
		var flinch_adjustment = camera.rotation.x + flinch_amount * delta
		if flinch_adjustment > deg_to_rad(90):
			flinch_adjustment = deg_to_rad(90)
		camera.rotation.x = flinch_adjustment
	
	if input_dir != Vector2.ZERO and is_on_floor() and !charging_dash:
		_play_animation.rpc("move", animation_player.get_path())
	elif (input_dir == Vector2.ZERO or !is_on_floor()) and !weapon.aiming:
		_play_animation.rpc("idle", animation_player.get_path())


@rpc ("any_peer", "call_local", "reliable")
func change_speed_and_jump(speed_effect = default_speed, jump_height = default_jump_velocity, effect = null):
	if effect == null:
		old_speed = speed_effect
	
	if !frozen:
		current_speed = speed_effect
		current_jump_velocity = jump_height
		
	if effect != null:
		match effect:
			"frozen":
				frozen = true
			"unfreeze":
				frozen = false
				current_speed = speed_effect
				current_jump_velocity = jump_height


@rpc ("any_peer", "call_local", "reliable")
func increase_speed(speed_effect):
	current_speed += speed_effect
	old_speed += speed_effect


func update_current_class(new_weapon):
	if is_multiplayer_authority():
		var id = multiplayer.get_unique_id()
		sensitivity = Global.players[id].Sensitivity
		if Global.players.has(id):
			if Global.players[id].Class != "" and weapon != null:
				camera.remove_child(weapon)
			
			weapon = new_weapon
			camera.add_child(new_weapon)
			
			change_material.rpc(current_colour, false)

@rpc ("any_peer", "call_local", "reliable")
func change_material(material, want_timer = true):
	if want_timer:
		await get_tree().create_timer(0.1).timeout
	
	for mesh in meshes:
		if material == Global.BLUE:
			var blue = load(Global.BLUE)
			mesh.set_surface_override_material(0, blue)
			if weapon != null:
				for arm_mesh in weapon.arm.get_children():
					arm_mesh.set_surface_override_material(0, blue)
					for arm_mesh_two in weapon.arm_two.get_children():
						arm_mesh_two.set_surface_override_material(0, blue)
			current_colour = Global.BLUE
			
		elif material == Global.RED:
			var red = load(Global.RED)
			mesh.set_surface_override_material(0, red)
			if weapon != null:
				for arm_mesh in weapon.arm.get_children():
					arm_mesh.set_surface_override_material(0, red)
					for arm_mesh_two in weapon.arm_two.get_children():
						arm_mesh_two.set_surface_override_material(0, red)
			current_colour = Global.RED
		elif material == Global.GREEN:
			var green = load(Global.GREEN)
			mesh.set_surface_override_material(0, green)
			if weapon != null:
				for arm_mesh in weapon.arm.get_children():
					arm_mesh.set_surface_override_material(0, green)
					for arm_mesh_two in weapon.arm_two.get_children():
						arm_mesh_two.set_surface_override_material(0, green)
			current_colour = Global.GREEN
		elif material == Global.YELLOW:
			var yellow = load(Global.YELLOW)
			mesh.set_surface_override_material(0, yellow)
			if weapon != null:
				for arm_mesh in weapon.arm.get_children():
					arm_mesh.set_surface_override_material(0, yellow)
					for arm_mesh_two in weapon.arm_two.get_children():
						arm_mesh_two.set_surface_override_material(0, yellow)
			current_colour = Global.YELLOW
		else:
			var pink = load(Global.PINK)
			mesh.set_surface_override_material(0, pink)
			if weapon != null:
				for arm_mesh in weapon.arm.get_children():
					arm_mesh.set_surface_override_material(0, pink)
					for arm_mesh_two in weapon.arm_two.get_children():
						arm_mesh_two.set_surface_override_material(0, pink)
			current_colour = Global.PINK


@rpc ("call_local", "any_peer", "reliable")
func change_layers():
	if is_multiplayer_authority():
		for child in $Meshes/frog.get_children():
			if child is MeshInstance3D:
				child.cast_shadow = 3
			elif child is Node3D:
				for child_two in child.get_children():
					if child_two is MeshInstance3D:
						child_two.cast_shadow = 3
		
		for outline in outlines:
			outline.visible = false
		
		for collider in hurtbox.get_children():
			if collider is CollisionShape3D:
				collider.disabled = true
		
		if hat != null:
			hat.get_child(0).cast_shadow = 3
			hat.get_child(0).get_child(0).cast_shadow = 3


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


@rpc ("any_peer", "call_local", "reliable")
func add_hat(given_given_hat):
	add_hat_for_all.rpc(given_given_hat)
	
	hat_node.add_child(hat, true)
	change_layers.rpc()


@rpc ("any_peer", "call_local", "reliable")
func add_hat_for_all(given_hat):
	match given_hat:
		"Cowboy":
			hat = load(Global.COWBOY_HAT).instantiate()


@rpc ("any_peer", "call_local", "reliable")
func remove_hat():
	if hat != null:
		hat.queue_free()


func _on_slow_timer_timeout():
	frozen = false
	change_speed_and_jump.rpc(old_speed, default_jump_velocity, "unfreeze")


func _on_freeze_count_timer_timeout():
	remove_freeze_count.emit()


func _play_positional_audio_rpc(audio_stream_path):
	_play_positional_audio.rpc(audio_stream_path)


@rpc ("any_peer", "call_local", "reliable")
func _play_positional_audio(audio_stream_path):
	var audio_stream = get_node_or_null(audio_stream_path)
	
	if audio_stream != null:
		audio_stream.play()


@rpc ("call_local", "any_peer", "reliable")
func _play_animation(animation_string, given_player_path = animation_player.get_path()):
	var given_player = get_node_or_null(given_player_path)
	
	if given_player != null:
		given_player.play(animation_string)
