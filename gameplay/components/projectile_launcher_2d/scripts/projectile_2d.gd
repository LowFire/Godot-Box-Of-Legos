@abstract
extends Node2D
class_name Projectile2D

@export_range(-180, 180, 1, "degrees") var direction_angle: float:
	get:
		return rad_to_deg(_direction_angle)
	set(p_val):
		_direction_angle = deg_to_rad(wrapf(p_val, -180, 180))


var _direction_angle: float
