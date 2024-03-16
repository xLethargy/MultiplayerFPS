extends Control

@onready var crosshair = $Crosshair
@onready var healthbar = $Healthbar

@onready var player = owner

func _on_player_change_health(health_value):
	healthbar.value = health_value
