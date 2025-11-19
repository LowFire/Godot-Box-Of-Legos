extends Node
class_name RangeFinder2D

@export_range(0, 10_000, 0.1) var max_range: float:
	get = _get_max_range,
	set = _set_max_range

@export var from_target: Node2D:
	get:
		return _from_target
	set(p_val):
		_from_target = p_val

var _max_range: float
var _from_target: Node2D


func is_within_range(p_pos: Vector2) -> bool:
	if not is_instance_valid(_from_target):
		push_error("Cannot get range. from_target is not valid.")
		return false
	
	var from_pos: Vector2 = _from_target.global_position
	var dist: float = from_pos.distance_to(p_pos)
	return dist <= _max_range


func _get_max_range() -> float:
	return _max_range


func _set_max_range(p_val: float) -> void:
	if p_val < 0:
		_max_range = 0
	else:
		_max_range = p_val
