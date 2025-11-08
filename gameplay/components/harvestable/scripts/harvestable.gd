extends Node
class_name Harvestable
## Class that provides gameplay mechanics that emulate an object that can be "harvested" by another
## object. The idea is that the harvestable object will provide the harvestor something in return
## once it is completely harvested. What that 'something' is and how it is distributed back to the
## harvestor has to be determined by you.

## Emitted when this harvestable has been sucessfully harvested. Returns an array of "harvested"
## objects that can then be used to determine logic of what will happen to those objects next. 
## (like maybe it will go into an inventory, or be dropped on the ground, ect.)
signal harvested(p_objects: Array[Resource])
## Emitted when this harvestable has been hit. [param p_amount] is the amound of harvest damage done.
signal hit(p_amount: int)
## Emitted when either [member current_hp] or [member max_hp] has changed. [param p_current] is the
## new current hp and [param p_max] is the new max hp.
signal hp_changed(p_current: int, p_max: int)
## Emitted when the state of this harvestable is reset.
signal resetted()


## The objects that are "dropped" by this harvestable when it is harvested. (Although, what it means 
## for it to be "dropped" is not determined by this class.)
@export var dropped_objects: Dictionary[Resource, int]:
	get = _get_dropped_objects,
	set = _set_dropped_objects

## The max hp of this harvistable. [member current_hp] is not allowed to go above this limit.
@export_range(1, 500) var max_hp: int:
	get:
		return _max_hp
	set(p_val):
		if p_val < 1:
			_max_hp = 1
		else:
			_max_hp = p_val
		
		if _current_hp > _max_hp:
			_current_hp = _max_hp
		
		hp_changed.emit(_current_hp, _max_hp)

## The current hp of this harvestable. If this value reaches 0, the harvestable is considered
## "harvested". This value not allowed to be more than [member max_hp].
@export var current_hp: int:
	get:
		return _current_hp
	set(p_val):
		if p_val > _max_hp:
			_current_hp = _max_hp
		else:
			_current_hp = p_val
		hp_changed.emit(_current_hp, _max_hp)


var _dropped_objects: Dictionary[Resource, int]
var _max_hp: int = 1
var _current_hp: int = 1
var _harvested: bool


func _ready() -> void:
	_current_hp = _max_hp
	hp_changed.emit(_current_hp, _max_hp)


## Attempts to harvest this harvestable once, causing [param p_damage] points of damage to it.
## If [member current_hp] reaches zero when calling this, the harvestable is "harvested".
func harvest(p_damage: int) -> void:
	if _harvested:
		return
	
	_current_hp -= p_damage
	
	if _current_hp <= 0:
		_complete_harvest()
	
	hp_changed.emit(_current_hp, _max_hp)
	hit.emit(p_damage)


## Returns whether or not this harverstable has already been harvested.
func is_harvested() -> bool:
	return _harvested


## Resets this harvestable, restoring [member current_hp] to max and resetting it's harvested state.
func reset() -> void:
	_current_hp = _max_hp
	_harvested = false
	hp_changed.emit(_current_hp, _max_hp)
	resetted.emit()


func _complete_harvest() -> void:
	assert(_current_hp <= 0, "Hp should be at or lower than 0")
	assert(not _harvested, "Should not been harvested already.")
	
	var replicated: Array[Resource]
	for resource: Resource in _dropped_objects:
		assert(is_instance_valid(resource), "Should be a valid resource.")
		replicated.append_array(_replicate_resource(resource, _dropped_objects[resource]))
	
	_harvested = true
	harvested.emit(replicated)


func _replicate_resource(p_resource: Resource, p_count: int) -> Array:
	var ret: Array[Resource]
	
	for i: int in p_count:
		var dup := p_resource.duplicate()
		ret.append(dup)
	
	return ret


func _set_dropped_objects(p_val: Dictionary[Resource, int]) -> void:
	_dropped_objects.clear()
	
	for resource: Resource in p_val:
		if not is_instance_valid(resource):
			continue
		_dropped_objects[resource] = p_val[resource]


func _get_dropped_objects() -> Dictionary:
	return _dropped_objects.duplicate()
