extends Area3D

var damage

func _ready():
	damage = owner.current_damage


func play_hit_effects():
	owner.on_hit_effect()
