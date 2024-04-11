extends Marker3D

@onready var player_detector : Area3D = $PlayerDetector

func check_for_players():
	if player_detector.has_overlapping_areas():
		print (player_detector.get_overlapping_areas())
		for area in player_detector.get_overlapping_areas():
			print (area, " ", area.is_in_group("Hurtbox"))
			if area.is_in_group("Hurtbox"):
				return true
		return false
	else:
		return false
