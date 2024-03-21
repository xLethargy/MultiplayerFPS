extends CharacterBody3D

@onready var health_component = $HealthComponent
@onready var shoot_component = $ShootComponent
@onready var camera = $Camera3D
@onready var spawner = $MultiplayerSpawner

var speed = 7.5
var jump_velocity = 5.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var input_dir

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
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)


func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()


func change_hud_health(health_value):
	$HUD/Healthbar.value = health_value


@rpc ("any_peer")
func change_speed_and_jump(speed_effect, jump_height):
	speed = speed_effect
	jump_velocity = jump_height

