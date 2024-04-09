extends Label

var score = 0
@onready var id = name.to_int()

func _ready():
	_update_colour()
	for player in get_tree().get_nodes_in_group("Player"):
		player.hurtbox.connect("change_score", _update_score_rpc)


func _update_score_rpc():
	_update_score.rpc()


@rpc ("any_peer", "call_local")
func _update_score():
	if Global.players != {}:
		if Global.players.has(id):
			if Global.players[id].Score != score:
				self.text = Global.players[id].Name + ": " + str(Global.players[id].Score)


func _update_colour():
	if Global.players != {}:
		if Global.players.has(id):
			match Global.players[id].Team:
				1:
					add_theme_color_override("font_color", Color("2273e0"))
				2:
					add_theme_color_override("font_color", Color("a90013"))
				3:
					add_theme_color_override("font_color", Color("439158"))
				4:
					add_theme_color_override("font_color", Color("e3bf42"))
				_:
					add_theme_color_override("font_color", Color("c2a3cf"))
