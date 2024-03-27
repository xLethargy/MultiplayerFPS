extends Label

var score = 0
@onready var id = name.to_int()

func _ready():
	#_update_colour()
	pass

func _process(_delta):
	_update_score()


#@rpc ("any_peer", "call_local")
func _update_score():
	if Global.players != {}:
		if Global.players.has(id):
			if Global.players[id].Score != score:
				self.text = Global.players[id].Name + ": " + str(Global.players[id].Score)


@rpc("any_peer", "call_local", "reliable")
func _update_colour():
	if Global.players.has(id):
		if Global.players != {}:
			match Global.players[id].Team:
				1:
					label_settings.font_color = Color("2273e0")
				2:
					label_settings.font_color = Color("8e000e")
				3:
					label_settings.font_color = Color("439158")
				4:
					label_settings.font_color = Color("e3bf42")
