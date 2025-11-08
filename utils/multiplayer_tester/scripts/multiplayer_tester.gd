@abstract
class_name MultiplayerTester
extends Node

## The port that either the client connects to the testing server on, or the server listens for
## a connection from a testing client.
@export var port: int:
	get:
		return _port
	set(p_val):
		_port = p_val

## The directory path containing all the scenario scripts. These are loaded on [method _ready]
@export var scenarios_directory_path: String:
	get:
		return _scenarios_directory_path
	set(p_val):
		_scenarios_directory_path = p_val

## A get-only property that returns the custom multiplayer API of this object
var custom_multiplayer: MultiplayerAPI:
	get:
		return _custom_multiplayer
	set(p_val):
		printerr("Cannot set custom_multiplayer. Property is read-only.")

static var instance: MultiplayerTester:
	get:
		return _instance
	set(p_val):
		push_error("Cannot set instance. Property is read-only.")

var _scenarios: Dictionary
var _custom_multiplayer := SceneMultiplayer.new()
var _scenarios_directory_path: String
var _port: int = 7777

static var _instance: MultiplayerTester

@abstract func shutdown() -> void

func _ready() -> void:
	_register_senarios()
	get_tree().set_multiplayer(_custom_multiplayer, get_path())
	
	if is_instance_valid(_instance) and is_same(self, _instance):
		push_error("Only one instance of MultiplayerTester is allowed to exist.")
		queue_free()
	else:
		_instance = self


func get_custom_multiplayer() -> SceneMultiplayer:
	return _custom_multiplayer


func get_scenario(p_senario: StringName) -> TestingScenario:
	if not _scenarios.has(p_senario):
		return null
	
	return _scenarios[p_senario]

 ##TODO: As of 4.4, add new code to ignore the .uid files. They're getting pulled in now...
func _register_senarios() -> void:
	print("Registering senarios")
	var scenario_paths: PackedStringArray = _load_scenarios_from_dir()
	for path in scenario_paths:
		var script: GDScript = load(path)
		var scenario = script.new()
		if not scenario is TestingScenario:
			push_error("Failed to register scenario '%s'." % path +
					"Script does not inherit from TestingScenario.")
			scenario.queue_free()
			continue
		
		var index: int = script.resource_path.get_slice_count("/")
		var scenario_name: String = script.resource_path.get_slice("/", index - 1)
		scenario_name = scenario_name.rstrip(".gd")
		scenario.name = scenario_name
		add_child(scenario, true)
		_scenarios[scenario_name] = scenario
		print("Registered scenario '%s'." % scenario_name)
	
	print("%s scenarios have been registered." % _scenarios.size())


func _load_scenarios_from_dir() -> PackedStringArray:
	var dir := DirAccess.open(_scenarios_directory_path)
	if not is_instance_valid(dir):
		push_error("Failed to open directory '%s'." % _scenarios_directory_path)
		return []
	
	var ret: PackedStringArray = []
	dir.list_dir_begin()
	while true:
		var result: String = dir.get_next()
		if result.is_empty():
			break # get_next() returns an empty string when the end of the directory's contents is reached.
		
		var pos: int = result.find("scn_")
		if not pos == 0:
			continue
		
		if not result.contains(".gd"):
			continue
		
		if result.contains(".uid"):
			continue
		
		ret.append(_scenarios_directory_path + result)
	dir.list_dir_end()
	
	return ret


@rpc("any_peer", "call_remote", "reliable")
func _signal_shutdown() -> void:
	get_tree().quit()

#func _set_connected_client_to_scenarios() -> void:
	#for scenario_name in _scenarios:
		#var scenario: TestingScenario = _scenarios[scenario_name]
		#scenario.set_connected_client(_connected_client)
