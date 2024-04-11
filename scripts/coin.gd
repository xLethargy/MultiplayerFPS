extends RigidBody3D

var trajectory = "forward"
var boost_z = null
var count = 0

@onready var coin_hurtbox = $HurtboxComponent
@onready var mesh = $MeshInstance3D
@onready var muzzle_flash = $MuzzleFlash
@onready var clang_audio = $ClangAudio

func _on_body_entered(_body):
	self.position = Vector3(0, -100, 0)
	freeze = true
	queue_free()


func _integrate_forces(_state):
	apply_velocity()


func change_values(boost, movement):
	boost_z = boost
	trajectory = movement


func apply_velocity():
	if boost_z != null:
		if trajectory == "forward" and count < 0.3:
			linear_velocity = boost_z
			count += 0.1

@rpc ("call_local", "any_peer", "reliable")
func play_spatial_audio():
	clang_audio.play()
