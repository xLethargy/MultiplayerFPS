extends Area3D


func _on_area_entered(area):
	if area.owner.is_in_group("Player"):
		area.owner.position = owner.spawn_points.get_child(randi_range(0, 4)).position
