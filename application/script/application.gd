## This is meant to be an abstract class representing the main application.
## The Application class is meant to be the main scene of the game and handles
## the entry point and exit points of the game.

class_name Application
extends Node


static var current_scene: Node:
	get:
		return _instance._current_scene
	set(p_val):
		push_error("Cannot set current scene. This property is read-only. Use " +
				"\'set_packed_scene_as_current\' instead.")
		return


static var cmd_args: Dictionary:
	get:
		return _instance._cmd_args
	set(p_val):
		push_error("Cannot set cmd_args. Property is read-only.")


static var _instance: Application
var _cmd_args: Dictionary
var _current_scene: Node


func _enter_tree() -> void:
	if is_instance_valid(_instance) and not is_same(_instance, self):
		push_error("Cannot initialize more than one application instance.")
		queue_free()
		return
	
	_instance = self
	_cmd_args = _get_cmd_args()
	get_tree().auto_accept_quit = false # so that we can define custom quit behaviour


func _ready() -> void:
	_main.call_deferred() # Call main to kick off the application.


func _notification(what) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_exit()


static func exit() -> void:
	assert(is_instance_valid(_instance))
	_instance._exit()


static func set_packed_scene_as_current(p_scene: PackedScene) -> void:
	assert(is_instance_valid(_instance))
	if not is_instance_valid(p_scene):
		push_error("Failed to set scene as current. Scene is not valid.")
		return
	
	if is_instance_valid(_instance._current_scene):
		_instance._current_scene.queue_free()
	
	var scene = p_scene.instantiate()
	_instance._current_scene = scene
	_instance.add_child(scene)


## Override this method to define your entry point. Should contian initialization code.
func _main() -> void:
	pass


## Override this method to define quit behaviour. Shoud contain cleanup code.
func _exit() -> void:
	get_tree().quit() # default behaviour


# NOTE: This is untested. Keep that in mind if you happen to pass arguments to the game.
func _get_cmd_args() -> Dictionary:
	var ret = {}
	
	var args: PackedStringArray = OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	
	for arg: String in args:
		if arg.find("=") > -1:
			var key_value: PackedStringArray = arg.split("=")
			ret[key_value[0].lstrip("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			ret[arg.lstrip("--")] = ""
	
	return ret
