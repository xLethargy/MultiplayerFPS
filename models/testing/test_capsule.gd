extends RigidBody3D

@onready var mesh = $Meshes/MeshInstance3D
@onready var despawn_timer = $DespawnTimer
@onready var freeze_timer = $FreezeTimer


func add_force_to_test(given_force):
	linear_velocity = given_force
	despawn_timer.start()
	freeze_timer.start()


func _on_despawn_timer_timeout():
	queue_free()


func _on_freeze_timer_timeout():
	freeze = true
