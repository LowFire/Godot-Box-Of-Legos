extends MultiplayerTester
class_name ClientTester

signal connected()

## The ip address of the server to connect to.
@export var remote_ip: StringName:
	get:
		return _remote_ip
	set(p_val):
		_remote_ip = p_val

var _remote_ip: StringName = "127.0.0.1"


func is_connected_to_server() -> bool:
	var state: MultiplayerPeer.ConnectionStatus = \
			_custom_multiplayer.multiplayer_peer.get_connection_status()
	return state == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED


func connect_to_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	var result: Error = peer.create_client(_remote_ip, _port)
	if result != OK:
		push_error("Client tester has failed to connect to test server.")
		return
	_custom_multiplayer.multiplayer_peer = peer


func disconnect_from_server() -> void:
	_custom_multiplayer.multiplayer_peer.close()


func shutdown() -> void:
	if _custom_multiplayer.multiplayer_peer.get_connection_status() ==\
			MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		_signal_shutdown.rpc_id(1)


func _on_peer_connected(p_id: int) -> void:
	if p_id == 1:
		print("Connected to test server.")
		_set_connected_peer_on_scenarios_to_server()
		connected.emit()


func _on_peer_disconnected(_p_id: int) -> void:
	print("Disconnected from test server.")
	_reset_connected_peer_on_scenarios()


func _set_connected_peer_on_scenarios_to_server() -> void:
	for scenario: TestingScenario in _scenarios.values():
		scenario.connected_peer = 1


func _reset_connected_peer_on_scenarios() -> void:
	for scenario: TestingScenario in _scenarios.values():
		scenario.connected_peer = 0
