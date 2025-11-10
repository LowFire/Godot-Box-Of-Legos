extends ShapeCast2D
class_name HurtBox

signal hitbox_hit(hitbox: HitBox, hitdata: HitData)

enum CollisionProcessMode {
	PHYSICS_PROCESS,
	PROCESS,
}

@export var effects: Array[Effect]:
	get:
		return _effects
	set(p_val):
		_effects = p_val

@export var active: bool:
	get:
		return _active
	set(p_val):
		_active = p_val

@export var hit_continuously: bool:
	get:
		return _hit_continuously
	set(p_val):
		_hit_continuously = p_val

@export_range(1, 1200, 1, "suffix:hits/min") var hit_rate: int:
	get:
		@warning_ignore("narrowing_conversion")
		return 60 / _hit_time
	set(p_val):
		_hit_time = 60.0 / p_val

@export var collision_process_mode: CollisionProcessMode:
	get:
		return _collision_process_mode
	set(p_val):
		if (p_val != CollisionProcessMode.PHYSICS_PROCESS and
			p_val != CollisionProcessMode.PHYSICS_PROCESS):
			_collision_process_mode = CollisionProcessMode.PHYSICS_PROCESS # Default
		_collision_process_mode = p_val
		

var hit_function: Callable

var _effects: Array[Effect]
var _active: bool
var _hit_continuously: bool
var _hit_time: float
var _hitting_hitboxes: Dictionary
var _collision_process_mode := CollisionProcessMode.PHYSICS_PROCESS


func _ready() -> void:
	hit_function = _default_hit


func _process(p_delta: float) -> void:
	_tick_hit_timers(p_delta)
	if _collision_process_mode == CollisionProcessMode.PROCESS:
		_handle_collisions()


func _physics_process(_p_delta: float) -> void:
	if _collision_process_mode == CollisionProcessMode.PHYSICS_PROCESS:
		_handle_collisions()


func add_effects(p_effects: Array[Effect]) -> void:
	_effects.append_array(p_effects)


func clear_effects() -> void:
	_effects.clear()


func remove_effect(p_index: int) -> void:
	if p_index >= _effects.size():
		push_error("Failed to remove effect at index %s. Index does not exist." % p_index)
		return
	if p_index < 0:
		push_error("Failed to remove effect. Index must be non-negative.")
		return
	
	_effects.remove_at(p_index)


func get_effects() -> Array[Effect]:
	return _effects


func _handle_collisions() -> void:
	if not _active:
		return
	
	var collision_count: int = get_collision_count()
	var hitboxes_being_hit: Array[HitBox]
	
	for index: int in collision_count:
		var object: Object = get_collider(index)
		if not object is HitBox:
			continue
		
		var hitbox := object as HitBox
		hitboxes_being_hit.append(hitbox)
		if _hitting_hitboxes.has(hitbox) and _hitting_hitboxes[hitbox] > 0:
			continue
		
		if not _hitting_hitboxes.has(hitbox):
			_hitting_hitboxes[hitbox] = 0.0
		
		var hitdata := HitData.new()
		hitdata.hit_by = self
		hitdata.collision_normal = get_collision_normal(index)
		hitdata.collision_point = get_collision_point(index)
		hitdata.collision_direction = Vector2.from_angle(global_rotation)
		hitdata.effects = _effects.duplicate(true)
		var final_hitdata: HitData = hit_function.call(hitdata, hitbox)
		
		# If it's null, we can assume that we don't want to hit the hitbox.
		if not is_instance_valid(final_hitdata):
			return
		
		while _hitting_hitboxes[hitbox] <= 0:
			hitbox.hit(final_hitdata)
			hitbox_hit.emit(hitbox, final_hitdata)
			_hitting_hitboxes[hitbox] += _hit_time
	
	_remove_non_colliding_hitboxes(hitboxes_being_hit)


func _default_hit(p_data: HitData, p_hitbox: HitBox) -> HitData:
	return p_data


func _tick_hit_timers(p_delta: float) -> void:
	if not _hit_continuously:
		return
	
	for hitbox: HitBox in _hitting_hitboxes:
		if _hitting_hitboxes[hitbox] > 0:
			_hitting_hitboxes[hitbox] -= p_delta


func _remove_non_colliding_hitboxes(p_still_being_hit: Array[HitBox]) -> void:
	var erase: Array
	for hitbox in _hitting_hitboxes:
		if not is_instance_valid(hitbox):
			erase.append(hitbox)
			continue
		if not p_still_being_hit.has(hitbox):
			if not _hit_continuously or _hitting_hitboxes[hitbox] <= 0:
				erase.append(hitbox)
	
	for hitbox in erase:
		_hitting_hitboxes.erase(hitbox)
