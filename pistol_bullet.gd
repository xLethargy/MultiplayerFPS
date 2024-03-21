extends RigidBody3D

var speed : float = 4
var damage : float = 50

@onready var direction_facing : Vector3 = get_global_transform().basis.z

var parent_shooter

func _process(_delta):
	linear_velocity = direction_facing * speed


func _on_collision_detector_body_entered(body):
	if body == parent_shooter:
		return
	
	if "receive_damage" in body:
		if body.is_in_group("Player"):
			body.receive_damage.rpc_id(body.get_multiplayer_authority(), damage)
	
	queue_free()
