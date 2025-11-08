extends Node2D
class_name Spawner2D

## Emits when a node is spawned. [param p_spawned] is the node that was spawned.
signal spawned(p_spawned: Node2D)
## Emits when a node is despawned, which is after [method Node.queue_free] is called on it. [param p_despawned]
## is the node that is despawned.
signal despawned(p_despawned: Node2D)
## Emits when the spawnable scene is changed. [param p_scene_path_or_uid] is the resource uid 
## of the resource.
signal scene_changed(p_scene_uid: String)

@export var scene_uid: String:
	get:
		return ResourceUID.path_to_uid(_scene.resource_path)
	set(p_val):
		if not ResourceLoader.exists(p_val):
			push_error("Failed to set spawning scene to '%s'. Does not exist." % p_val)
			return
		_scene = load(p_val)
		scene_changed.emit(p_val)

## The path to the node where nodes spawned by this [Spawner2D] will be parented to.
@export var spawn_path: NodePath:
	get:
		if not is_instance_valid(_spawn_node):
			return NodePath()
		
		return _spawn_node.get_path()
	set(p_val):
		if not is_instance_valid(get_node(p_val)):
			push_error("Failed to set spawn path. Path does not point to a valid node.")
			return
		
		_spawn_node = get_node(p_val)

## A custom callback that will be called everytime a node is spawned. Callback must take a Node2D
## and a generic variant as parameters.
var spawn_callback: Callable:
	get:
		return _spawn_callback
	set(p_val):
		if not _callback_is_valid(p_val):
			push_error("Failed to set spawn callback. Callback is not valid.")
			return
		
		_spawn_callback = p_val

var _scene: PackedScene
var _spawn_node: Node
var _spawn_callback: Callable
var _spawned: Dictionary[int, Node2D]
var _next_id: int


## Spawns [member scene] into the world at this [Spawner2D]'s global location. [param p_data]
## is optional data that is passed to the spawn callback.
func spawn(p_data = null) -> Node2D:
	if not is_instance_valid(_spawn_node):
		push_error("Cannot spawn node. Spawn path has not been set.")
		return null
	
	var ret: Node2D = _scene.instantiate()
	_spawn_node.add_child(ret)
	ret.global_position = global_position
	ret.tree_exited.connect(_on_node_exit_tree)
	
	if spawn_callback != null and not spawn_callback.is_null():
		spawn_callback.call(ret, p_data)
	
	var new_id: int = _generate_id()
	_spawned[new_id] = ret
	
	spawned.emit(ret)
	return ret


## Despawns the node with id [param p_id]. Does nothing if a node with that id does not exist.
func despawn(p_id: int) -> void:
	if not _spawned.has(p_id):
		return
	
	var despawn_node: Node2D = _spawned[p_id]
	if not is_instance_valid(despawn_node):
		return
	
	despawn_node.queue_free()


## Returns a reference to a node with id [param p_id]. Returns null if no node has that id.
func get_spawned(p_id: int) -> Node2D:
	if not _spawned.has(p_id):
		return null
	return _spawned[p_id]


## Finds the id for [param p_node]. If the node could not be found, then -1 is returned.
func get_id(p_node: Node2D) -> int:
	var key: Variant = _spawned.find_key(p_node)
	if key == null:
		return -1
	
	return key


func _scene_is_valid(p_scene: PackedScene) -> bool:
	if not is_instance_valid(p_scene):
		return false
	
	var state: SceneState = p_scene.get_state()
	if not state.get_node_type(0) == "Node2D":
		return false
	
	return true


func _callback_is_valid(p_callback: Callable) -> bool:
	if p_callback == null:
		return false
	
	if p_callback.is_null():
		return false
	
	return true


func _generate_id() -> int:
	while _spawned.has(_next_id):
		_next_id += 1
	return _next_id


func _on_node_exit_tree() -> void:
	# need to find out which node is exiting.
	for node: Node2D in _spawned.values():
		assert(node != null, "Node reference should still be valid.")
		if not node.is_inside_tree():
			var id: int = _spawned.find_key(node)
			_spawned.erase(id)
			despawned.emit(node)
