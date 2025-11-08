@tool
extends Node2D
class_name ProjectileLauncher2D
## Creates instances of [Projectile2D] that can be fired as if it were a gun. Has several firing modes
## that determine how projectiles are fired. (See [enum FiringModes])


## Emitted when [ProjectileLauncher2D] fires a projectile
signal projectile_fired(p_projectile: Projectile2D)
## Emitted when [ProjectileLauncher2D] changes the node that projectiles are parented to.
signal projectile_parent_changed(p_parent: Node)
## Emitted when the spawned projectile is changed.
signal spawning_projectile_changed(p_projectile_scene: PackedScene)
## Emitted when [ProjectileLauncher2D] begins firing.
signal firing()
## Emitted when [ProjectileLauncher2D] stops firing.
signal held_fire()


## All the firing modes for the launcher. Determines how the launcher fires.
## [enum FiringMode.SEMI_AUTO]: Launcher fires only 1 projectile when [method fire] is called and will not 
## fire another until [method hold_fire] is called.
## [enum FiringMode.FULL_AUTO]: Launcher continuously fires projectiles until [method hold_fire] is called.
## Rate of fire is determined by [member fire_rate].
## [enum FiringMode.SEMI_AUTO_BURST] Fires a predetermined number of projectiles dictacted by 
## [member burst_count] in a row and does so only once when [method fire] is called. Time between each
## projectile fired is determined by [member burst_time].
## [enum FiringMode.FULL_AUTO_BURST] Same as previous, but now continuously fires bursts of projectiles
## until [method hold_fire] is called. Rate of fire is determined by [member fire_rate].
enum FiringMode {
	SEMI_AUTO,
	FULL_AUTO,
	SEMI_AUTO_BURST,
	FULL_AUTO_BURST,
}


## The packed scene of the projectile that will be instantiated when the launcher is fired. The
## packed scene must have [Projectile2D] set as it's root for it to be valid.
@export var projectile: PackedScene:
	get:
		return _projectile
	set(p_val):
		_projectile = p_val
		spawning_projectile_changed.emit(_projectile)

## Sets the firing mode of the launcher. See [enum FiringMode] for all the different possible modes.
@export var firing_mode: FiringMode:
	get:
		return _firing_mode
	set(p_val):
		_firing_mode = p_val

## The parent the projectiles will be parented to when they are created. If this is null, projetiles
## are not parented to any node.
@export var projectile_parent: Node:
	get:
		return _projectile_parent
	set(p_val):
		if not is_instance_valid(p_val):
			printerr("Failed to set projectile parent. Value is not valid.")
			return
		_projectile_parent = p_val
		projectile_parent_changed.emit(_projectile_parent)


## How many projectiles are launched at once when this launcher is fired.
@export var projectile_count: int:
	get:
		return _projectile_count
	set(p_val):
		if p_val < 1:
			_projectile_count = 1
		else:
			_projectile_count = p_val

## How many times launcher shoots when it is fired in burst mode.
@export var burst_count: int:
	get:
		return _burst_count
	set(p_val):
		if p_val < 1:
			_burst_count = 1
		else:
			_burst_count = p_val

## The time in milliseconds between each projectile fired while bursting.
@export_range(1, 10_000, 1, "suffix:milliseconds") var burst_time: int:
	get:
		@warning_ignore("narrowing_conversion")
		return _burst_time * 1000
	set(p_val):
		if p_val < 1:
			_burst_time = 0.001
		elif p_val > 10_000:
			_burst_time = 10_000 / 1000.0
		else:
			_burst_time = p_val / 1000.0

## The angle in degrees of the launcher's spread.
@export_range(0, 360, 0.1, "degrees") var spread_angle: float:
	get:
		return rad_to_deg(_spread_angle)
	set(p_val):
		_spread_angle = deg_to_rad(wrapf(p_val, 0, 360))

## Sets if projectile's direction's are randomized within the spread range of the launcher. If not,
## projectile's spread are evened out and deterministic.
@export var randomized_spread: bool:
	get:
		return _randomized_spread
	set(p_val):
		_randomized_spread = p_val

## The rate which the launcher is fired, measured in shots per minute.
@export_range(0.1, 10_000, 0.1, "suffix:shots per minute") var fire_rate: float:
	get:
		return 60.0 / _cooldown_time
	set(p_val):
		if p_val < 0.1:
			_cooldown_time = 600
		elif p_val > 10_000:
			_cooldown_time = 0.006
		else:
			_cooldown_time = 60.0 / p_val

## The buffer time in which the launcher will queue up for the next shot before the cooldown time
## expires. Useful mainly for the semi-auto firing modes.
@export_range(0, 1000, 1, "suffix:milliseconds") var fire_buffer_time: int:
	get:
		@warning_ignore("narrowing_conversion")
		return _fire_buffer_time * 1000
	set(p_val):
		if p_val < 0:
			_fire_buffer_time = 0
		elif p_val > 1000:
			_fire_buffer_time = 1
		else:
			_fire_buffer_time = p_val / 1000.0


var _projectile: PackedScene
var _projectile_parent: Node
var _firing_mode: FiringMode
var _spread_angle: float
var _randomized_spread: bool
var _current_cooldown_time: float
var _firing: bool
var _current_burst_count: int
var _bursting: bool
var _hold_fire: bool
var _projectile_count: int = 1
var _burst_count: int = 1
var _burst_time: float = 0.1
var _cooldown_time: float = 0.5
var _fire_buffer_time: float = 0.1


func _process(p_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if not _bursting:
		_current_cooldown_time -= p_delta

## Tells the launcher to start firing. Firing behaviour of the lancher depends on the 
## [enum FiringMode].
func fire() -> void:
	if not is_instance_valid(_projectile):
		return
	
	if _current_cooldown_time < _fire_buffer_time and not _firing:
		match _firing_mode:
			FiringMode.SEMI_AUTO:
				_semi_auto()
			FiringMode.FULL_AUTO:
				_full_auto()
			FiringMode.SEMI_AUTO_BURST:
				_semi_auto_burst()
			FiringMode.FULL_AUTO_BURST:
				_full_auto_burst()
		
		firing.emit()

## Tells the launcher to stop firing.
func hold_fire() -> void:
	_hold_fire = true
	held_fire.emit()

## Returns if this launcher is currently firing
func is_firing() -> bool:
	return _firing

## Returns if this launcher is currently bursting. Only applicable to modes 
## [enum FiringMode.SEMI_AUTO_BURST] and [enum FiringMode.FULL_AUTO_BURST]. Returns false in all
## other cases
func is_bursting() -> bool:
	return _bursting


func _fire_projectile() -> void:
	for i in _projectile_count:
		var new_projectile: Projectile2D = _projectile.instantiate()
		var rand_rot: float = _calc_spread(i)
		new_projectile.direction_angle = rad_to_deg(global_rotation + rand_rot)
		new_projectile.position = global_position
		
		if is_instance_valid(_projectile_parent):
			_projectile_parent.add_child(new_projectile, true)
	
		projectile_fired.emit(new_projectile)


func _semi_auto() -> void:
	_firing = true
	await _wait_for_cooldown()
	
	_fire_projectile()
	_firing = false
	_hold_fire = false
	_current_cooldown_time = _cooldown_time


func _full_auto() -> void:
	_firing = true
	while _firing:
		_fire_projectile()
		_current_cooldown_time = _cooldown_time
		await _wait_for_cooldown()
		
		if _hold_fire:
			_firing = false
			_hold_fire = false


func _semi_auto_burst() -> void:
	_firing = true
	_current_burst_count = 0
	await _wait_for_cooldown()
	await _burst()
	_firing = false
	_hold_fire = false
	_current_cooldown_time = _cooldown_time


func _full_auto_burst() -> void:
	_firing = true
	while _firing:
		_current_burst_count = 0
		await _burst()
		_current_cooldown_time = _cooldown_time
		await _wait_for_cooldown()
		
		if _hold_fire:
			_firing = false
			_hold_fire = false


func _burst() -> void:
	_bursting = true
	while _current_burst_count < _burst_count:
		_fire_projectile()
		_current_burst_count += 1
		await get_tree().create_timer(_burst_time).timeout
	_bursting = false


func _wait_for_cooldown() -> void:
	while _current_cooldown_time > 0:
		await get_tree().process_frame


func _calc_spread(p_index: int) -> float:
	var ret: float
	
	if _randomized_spread:
		ret = randf_range(-(_spread_angle / 2), _spread_angle / 2)
	elif _projectile_count == 1:
		ret = 0
	else:
		ret = ((_spread_angle / _projectile_count) * p_index) - (_spread_angle / 2)
	
	return ret
