extends Area2D
class_name HitBox

signal hitted(data: HitData)

var active: bool:
	get:
		return _active
	set(p_val):
		_active = p_val

@export var target: Node:
	get:
		return _target
	set(p_val):
		_target = p_val

var hitted_function: Callable

var _target: Node
var _active: bool = true


func _ready() -> void:
	hitted_function = _default_hitted


func hit(p_hitdata: HitData) -> void:
	if not _active:
		return
	
	var final_hitdata: HitData = hitted_function.call(p_hitdata)
	
	# If hitdata is null, then we can assume we don't want to apply any of the effects.
	if not is_instance_valid(final_hitdata):
		return
	
	if is_instance_valid(_target):
		for effect: Effect in final_hitdata.effects:
			effect.afflict(_target)
	
	hitted.emit(final_hitdata)


func _default_hitted(p_data: HitData) -> HitData:
	return p_data
