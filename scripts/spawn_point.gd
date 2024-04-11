extends Marker3D

@onready var player_detector : Area3D = $PlayerDetector

func check_for_players():
	if player_detector.has_overlapping_areas():
		for area in player_detector.get_overlapping_areas():
			if area.owner.is_in_group("Enemy"):
				return true
		return false
	else:
		return false
