extends VBoxContainer

@onready var choose_class = $"../ChooseClass"
@onready var multiplayer_menu = $"../../../.."

func _on_two_pressed():
	multiplayer_menu._play_ui_audio(multiplayer_menu.click_audio, multiplayer_menu.min_click_audio_pitch, multiplayer_menu.max_click_audio_pitch)
	
	_update_teams(2)


func _on_three_pressed():
	multiplayer_menu._play_ui_audio(multiplayer_menu.click_audio, multiplayer_menu.min_click_audio_pitch, multiplayer_menu.max_click_audio_pitch)
	
	_update_teams(3)
	


func _on_four_pressed():
	multiplayer_menu._play_ui_audio(multiplayer_menu.click_audio, multiplayer_menu.min_click_audio_pitch, multiplayer_menu.max_click_audio_pitch)
	
	_update_teams(4)

func _on_no_team_pressed():
	multiplayer_menu._play_ui_audio(multiplayer_menu.click_audio, multiplayer_menu.min_click_audio_pitch, multiplayer_menu.max_click_audio_pitch)
	
	_update_teams(10)

func _update_teams(team_amount):
	Global.teams = team_amount
	
	multiplayer_menu.setup_server()



