extends Area3D

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.position = owner.spawn_points.get_child(randi_range(0, 4)).position
