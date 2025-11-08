extends Node
class_name ProjectileLauncher2DMultiplayer

## The targeted [ProjectileLauncher2D]. When targeted, multiplayer capabilities will be enabled for
## the launcher.
@export var launcher: ProjectileLauncher2D:
	get = _get_launcher,
	set = _set_launcher

var _launcher: ProjectileLauncher2D

@onready var _spawner: MultiplayerSpawner = $MultiplayerSpawner


func _ready() -> void:
	_set_launcher(_launcher)
	
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	set_multiplayer_authority(peer.get_unique_id())


func _set_launcher(p_launcher: ProjectileLauncher2D) -> void:
	if not is_instance_valid(multiplayer):
		return
	
	if instance_is_valid(_launcher):
		_launcher.projectile_parent_changed.disconnect(_on_projectile_parent_changed)
		_launcher.spawning_projectile_changed.disconnect(_on_projectile_parent_changed)
	
	_launcher = p_launcher
	
	if is_instance_valid(_launcher):
		_set_spawn_node(_launcher.projectile_parent)
		_set_spawning_projectile(_launcher.projectile.resource_path)
		_launcher.projectile_parent_changed.connect(_on_projectile_parent_changed)
		_launcher.spawning_projectile_changed.connect(_on_projectile_parent_changed)


func _get_launcher() -> ProjectileLauncher2D:
	return _launcher


func _on_projectile_parent_changed(p_parent: Node) -> void:
	_set_spawn_node(p_parent)


func _on_spawning_projectile_changed(p_scene: PackedScene) -> void:
	


func _set_spawn_node(p_node: Node) -> void:
	if not _multplayer_peer_active():
		_print_inactive_peer_err()
		return
	if not is_instance_valid(p_node):
		return
	
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	p_node.set_multiplayer_authority(peer.get_unique_id())
	_spawner.spawn_path = p_node.get_path()
	
	if not multiplayer.is_server():
		_set_spawning_node_server.rpc_id(1, p_node.get_path(), peer.get_unique_id())


func _set_spawning_projectile(p_projectile_path: String) -> void:
	if not _multplayer_peer_active():
		_print_inactive_peer_err()
		return
	if not ResourceLoader.exists(p_projectile_path):
		printerr("Failed to set projectile spawnable scene. Scene at '%s' doesn't exist" % p_projectile_path)
		return
	
	_spawner.clear_spawnable_scenes()
	_spawner.add_spawnable_scene(p_projectile_path)
	
	if not multiplayer.is_server():
		_set_spawning_projectile_server.rpc_id(1, p_projectile_path)


func _multplayer_peer_active() -> bool:
	return is_instance_valid(multiplayer.multiplayer_peer)


func _print_inactive_peer_err() -> void:
	printerr("ProjectileLauncher2DMultiplayer cannot be used without an active multiplayer peer.")


@rpc("authority", "call_remote", "reliable")
func _set_spawning_projectile_server(p_projectile_path: String) -> void:
	_spawner.clear_spawnable_scenes()
	_spawner.add_spawnable_scene(p_projectile_path)


@rpc("authority", "call_remote", "reliable")
func _set_spawning_node_server(p_node_path: StringName, p_authority: int) -> void:
	var node: Node = get_node(NodePath(p_node_path))
	node.set_multiplayer_authority(p_authority)
	_spawner.spawn_path = NodePath(p_node_path)
