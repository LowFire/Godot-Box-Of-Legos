extends MultiplayerTester
class_name ServerTester

var connected_client: int:
	get:
		return _connected_client
	set(p_val):
		printerr("Cannot set connected_client. Property is read-only.")


var _connected_client: int


func _ready() -> void:
	super._ready()
	
	var peer := ENetMultiplayerPeer.new()
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("Starting testing server.")
	
	var result: Error = peer.create_server(_port, 1)
	if result != OK:
		push_error("Failed to create server.")
		return
	_custom_multiplayer.multiplayer_peer = peer
	
	print_rich("[color=green]Test server started successfully[/color]")


func shutdown() -> void:
	get_tree().quit()


func _on_peer_connected(p_id) -> void:
	if p_id != 1 and connected_client == 0:
		_connected_client = p_id
		_update_connected_peer_to_scenarios()
		print("Test client has connected with id '%s'" % p_id)


func _on_peer_disconnected(p_id: int) -> void:
	if p_id == _connected_client:
		_connected_client = 0
		_update_connected_peer_to_scenarios()
		print("Test client has disconnected.")


func _exit_tree() -> void:
	print_rich("[color=yellow]Test server shutting down.[/color]")


func _update_connected_peer_to_scenarios() -> void:
	for scenario: TestingScenario in _scenarios.values():
		scenario.connected_peer = _connected_client
