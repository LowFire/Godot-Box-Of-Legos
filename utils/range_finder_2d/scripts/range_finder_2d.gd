extends Node
class_name RangeFinder2D
## Used to find the distance between two nodes and then determines if they are within a predetermined
## range. Useful for things that need to have a set range to them, like interacting, building,
## ect.

## The max range of this [RangeFinder2D]
@export_range(0, 10_000, 0.1) var max_range: float:
	get = _get_max_range,
	set = _set_max_range

## The target node that we are measuring from. This is required for the range finder to work.
@export var from_target: Node2D:
	get:
		return _from_target
	set(p_val):
		_from_target = p_val

## The target we are measuring to. If this is null, [method is_within_range] will always return
## false
@export var to_target: Node2D:
	get:
		return _to_target
	set(p_val):
		_to_target = p_val

var _max_range: float
var _from_target: Node2D
var _to_target: Node2D


## Tests if the distance between [member from_target] and [member to_target] is within the range
## set by [member max_range]. If either targets are not valid, this will always return false.
func is_within_range() -> bool:
	if not is_instance_valid(_from_target):
		push_error("Cannot get range. from_target is not valid.")
		return false
	if not is_instance_valid(_to_target):
		return false
	
	var from_pos: Vector2 = _from_target.global_position
	var to_pos: Vector2 = _to_target.global_position
	var dist: float = from_pos.distance_to(to_pos)
	return dist <= _max_range


func _get_max_range() -> float:
	return _max_range


func _set_max_range(p_val: float) -> void:
	if p_val < 0:
		_max_range = 0
	else:
		_max_range = p_val
