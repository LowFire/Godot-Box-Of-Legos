extends SceneTree

var server_tester_scene: PackedScene  = preload("uid://dfll8ruucci3")

func _init() -> void:
	var max_iter = 20
	var iter = 0

	# Not seen this wait more than 1.
	while(Engine.get_main_loop() == null and iter < max_iter):
		await create_timer(.01).timeout
		iter += 1

	if(Engine.get_main_loop() == null):
		push_error('Main loop did not start in time.')
		quit(0)
		return
	
	# set up multiplayer tester.
	var server_tester = server_tester_scene.instantiate()
	if not server_tester is ServerTester:
		push_error("Failed to initialize test server. Invalid server tester.")
		return
	root.add_child(server_tester, true)
