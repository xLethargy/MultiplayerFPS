extends Control

@onready var crosshair = $Crosshair
@onready var healthbar = $Healthbar
@onready var sniper_ads = $SniperADS
@onready var wounded_screen = $WoundedScreen
@onready var animation_player = $AnimationPlayer
@onready var server_address = $ServerAddress


func _unhandled_input(event):
	if event.is_action_pressed("show_ip") and multiplayer.is_server():
		server_address.visible = !server_address.visible
