extends RigidBody3D

var trajectory = "forward"
var boost_z = null
var count = 0

@onready var mesh = $MeshInstance3D
@onready var muzzle_flash = $MuzzleFlash

func _on_body_entered(_body):
	self.position = Vector3(0, -100, 0)
	freeze = true
	queue_free()


func _integrate_forces(state):
	apply_velocity()


func change_values(boost, movement):
	boost_z = boost
	trajectory = movement


func apply_velocity():
	if boost_z != null:
		if trajectory == "forward" and count < 0.3:
			linear_velocity = boost_z
			count += 0.1


@rpc ("any_peer", "call_local")
func remove_coin_for_all():
	queue_free()
