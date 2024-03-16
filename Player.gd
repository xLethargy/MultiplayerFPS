extends CharacterBody3D

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var hud = $HUD
@onready var audio_player = $AudioStreamPlayer

var max_health = 100
var current_health = max_health

var weapon

const SPEED = 7.5
const JUMP_VELOCITY = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

signal change_health(health_value)
signal weapon_signal(weapon)

func _ready():
	if !is_multiplayer_authority():
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapon = camera.get_child(0)
	camera.current = true


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())


func _unhandled_input(event):
	if !is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	if Input.is_action_just_pressed("shoot") and weapon.animation_player.current_animation != "shoot":
		weapon.play_shoot_effects.rpc()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("Player"):
				weapon.play_local_shoot_effects()
				audio_player.play()
				collider.receive_damage.rpc_id(collider.get_multiplayer_authority(), weapon.damage)
		


func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if !weapon.animation_player.current_animation == "shoot":
		if input_dir != Vector2.ZERO and is_on_floor():
			weapon.animation_player.play("move")
		else:
			weapon.animation_player.play("idle")
	
	move_and_slide()


@rpc ("any_peer")
func receive_damage(damage):
	current_health -= damage
	if current_health <= 0:
		current_health = max_health
		position = Vector3.ZERO
	
	change_health.emit(current_health)



