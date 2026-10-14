extends RefCounted
class_name Angle

static func normalize_angle_rad(angle: float) -> float:
	while (angle >= 2 * PI): 
		angle -= 2 * PI
	while (angle < 0):
		angle += 2 * PI
	return angle

static func normalize_angle_deg(angle: float) -> float:
	while (angle >= 360): 
		angle -= 360
	while (angle < 0):
		angle += 360
	return angle
