extends VBoxContainer

@onready var multiplayer_menu = $"../../../.."
@onready var server_joiner = $"../ServerJoiner"
@onready var choose_class = $"../ChooseClass"

var last_menu

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer_menu.connect("warning_signal", warning_prompt_menu)


func warning_prompt_menu(menu):
	match menu:
		"ChooseClass":
			last_menu = choose_class
		"ServerJoiner":
			last_menu = server_joiner


func _on_yes_pressed():
	if last_menu == server_joiner:
		get_tree().quit()
	elif last_menu == choose_class:
		if multiplayer.is_server():
			get_tree().current_scene.send_to_main_menu.rpc()
			get_tree().quit()
		else:
			get_tree().current_scene._on_multiplayer_menu_remove_player(multiplayer.get_unique_id())
			get_tree().quit()


func _on_no_pressed():
	self.hide()
	last_menu.show()
