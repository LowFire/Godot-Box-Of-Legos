@abstract
class_name TestingScenario
extends Node

enum AuthorityType {
	SERVER,
	CLIENT,
}

signal subject_added(p_subject: Node)
signal subject_removed(p_subject: Node)

var connected_peer: int:
	get:
		return _connected_peer
	set(p_val):
		_connected_peer = p_val


var _awaiter := _Awaiter.new()
var _subjects: Array
var _results: Variant
var _retrieved_results: bool
var _server_ready: bool
var _client_ready: bool
var _connected_peer: int 

## Runs before a test is executed. Contains initialization code. Override this.
@abstract func _before_test() -> void
## Runs after a test is executed. This can contain cleanup code. Override this.
@abstract func _after_test() -> void


func _process(p_delta: float) -> void:
	_awaiter.update(p_delta)


## Begins the test indicated by [param p_method] on the test server. Throws an error if the test
## does not exist or if the tester is not connected to a test server.
func run_test(p_method: StringName) -> void:
	if not has_method(p_method):
		push_error("Failed to run response '%s'. Method does not exist." % p_method)
		return
	if _connected_peer != 1:
		push_error("Cannot run test. Not connected to a server.")
	
	_before_test()
	_run_test_on_server.rpc_id(1, p_method)


## Awaits [param p_signal] until it emits, or until [param p_max_wait] expires.
func wait_for_signal(p_signal: Signal, p_max_wait: float) -> void:
	_awaiter.wait_on_signal(p_signal, p_max_wait)
	await _awaiter.expired


## Awaits for [param p_time].
func wait_seconds(p_time: float) -> void:
	_awaiter.wait_seconds(p_time)
	await _awaiter.expired


func wait_until(p_callable: Callable, p_max_wait: float) -> void:
	_awaiter.wait_until(p_callable, p_max_wait)
	await _awaiter.expired


## Adds [param p_subject] to the testing scenario. You can also await this method, which will await
## until [param p_subject]'s _ready function has been called. [param p_authority] sets the
## multilayer authority of the subject when it is added.
func add_subject(p_subject: Node, p_authority := AuthorityType.SERVER) -> void:
	if _connected_peer == 0:
		push_error("Cannot add subjects when there is no connection present.")
		return
	if _subjects.has(p_subject):
		push_error("Cannot add subject. Subject has already been added.")
		return
	
	match p_authority:
		AuthorityType.SERVER:
			p_subject.set_multiplayer_authority(1)
		AuthorityType.CLIENT:
			if _connected_peer == 1: # we are a client connected to a server.
				p_subject.set_multiplayer_authority(multiplayer.multiplayer_peer.get_unique_id())
			else: # we are a server with a client connected.
				p_subject.set_multiplayer_authority(_connected_peer)
	
	_subjects.append(p_subject)
	_awaiter.register_subject_signals(p_subject)
	add_child(p_subject, true)
	
	if not p_subject.is_node_ready():
		await p_subject.ready
	
	subject_added.emit(p_subject)


## Removed [param p_subject] from the testing scenario. You can also await this method, which will
## await until [param p_subject]'s _tree_exited function has been called.
func remove_subject(p_subject: Node) -> void:
	if not _subjects.has(p_subject):
		push_error("Failed to remove subject. Subject was not added to the scenario.")
		return
	
	_awaiter.remove_subject_signals(p_subject)
	_subjects.erase(p_subject)
	remove_child(p_subject)
	if p_subject.is_inside_tree():
		await p_subject.tree_exited
	subject_removed.emit(p_subject)


## Checks if this tester has recieved a notification from the test server that it is ready. Resets the
## server ready state when this returns true.
func check_server_ready() -> bool:
	if _server_ready:
		_server_ready = false
		return true
	return false


## Checks if this tester has recieved a notification from the test client that it is ready. Resets
## the client ready state when this returns true.
func check_client_ready() -> bool:
	if _client_ready:
		_client_ready = false
		return true
	return false


## Signals to the remote tester that this tester is ready.
func signal_ready() -> void:
	if _connected_peer == 1:
		print("Signaled to server that client is ready")
		_signal_ready_server.rpc_id(1)
	else:
		print("Signaled to client '%s' that server is ready" % _connected_peer)
		_signal_ready_client.rpc_id(_connected_peer)


## Returns whether or not this tester has recieved results from the test server.
func has_results() -> bool:
	return _retrieved_results


## Returns the results retrieved from the server. Resets retreived results state.
func get_results() -> Variant:
	_retrieved_results = false
	return _results


@rpc("any_peer", "call_remote", "reliable")
func _signal_ready_server() -> void:
	_client_ready = true


@rpc("any_peer", "call_remote", "reliable")
func _signal_ready_client() -> void:
	_server_ready = true


@rpc("any_peer", 'call_remote', "reliable")
func _run_test_on_server(p_test: StringName) -> void:
	if not has_method(p_test):
		push_error("Failed to run test '%s'. Test does not exist." % p_test)
		return
	
	print_rich("[color=yellow]** --Running test '%s'-- **[/color]" % p_test)
	@warning_ignore("redundant_await")
	await _before_test()
	signal_ready()
	var final_results: Variant = await call(p_test)
	@warning_ignore("redundant_await")
	await _after_test()
	_send_results_to_client.rpc_id(_connected_peer, final_results)
	print_rich("[color=green]** -- Test '%s' has completed. -- **[/color]" % p_test)


@rpc("authority", "call_remote", "reliable")
func _send_results_to_client(p_results: Variant) -> void:
	_after_test()
	_results = p_results
	_retrieved_results = true


class _Awaiter:
	extends  RefCounted
	
	const ARG_NOT_SET = null
	
	signal expired()
	
	var _wait_time: float
	var _waiting_on_signal: bool
	var _checking_signal: Signal
	var _running: bool
	var _subject_signals: Dictionary[Node, Dictionary]
	
	
	func update(p_delta: float) -> void:
		if not _running:
			return
		
		if _has_signal_emitted():
			_expire()
		
		_wait_time -= p_delta
		if _wait_time <= 0:
			_expire()
	
	
	func register_subject_signals(p_subject: Node) -> void:
		_subject_signals[p_subject] = {}
		var subject_signals: Array = p_subject.get_signal_list()
		for entry: Dictionary in subject_signals:
			_subject_signals[p_subject][entry.name] = false
			p_subject.connect(entry.name, Callable(self, "_signal_callback"). \
					bind(p_subject, entry.name))
	
	
	func remove_subject_signals(p_subject: Node) -> void:
		assert(is_instance_valid(p_subject))
		assert(_subject_signals.has(p_subject))
		
		for signal_name: StringName in _subject_signals[p_subject].keys():
			p_subject.disconnect(signal_name, _signal_callback)
		_subject_signals.erase(p_subject)
	
	
	func wait_on_signal(p_signal: Signal, p_time: float) -> void:
		assert(p_signal != null and not p_signal.is_null(), "passed signal is valid.")
		
		print("Awaiting signal '%s' until %s seconds." % [p_signal.get_name(), p_time])
		
		_wait_time = p_time
		_checking_signal = p_signal
		_waiting_on_signal = true
		_running = true
	
	
	func wait_seconds(p_time: float) -> void:
		if _waiting_on_signal:
			_waiting_on_signal = false
		
		print("Awaiting until %s seconds." %  p_time)
		
		_wait_time = p_time
		_running = true
	
	
	func _has_signal_emitted() -> bool:
		if not _waiting_on_signal:
			return false
		
		assert(_checking_signal != null and not _checking_signal.is_null(), 
				"_checking_signal should be valid.")
		assert(_subject_signals.has(_checking_signal.get_object()), "The object assosiated with " +
				"the signal being checked should be registered.")
		assert(_subject_signals[_checking_signal.get_object() as Node].has(_checking_signal.get_name()),
				"The signal should be registered with the subject.")
		
		var subject = _checking_signal.get_object() as Node
		var signal_name: StringName = _checking_signal.get_name()
		return _subject_signals[subject][signal_name]
	
	
	func has_subject(p_subject: Node) -> void:
		return _subject_signals.has(p_subject)
	
	
	func _signal_callback(
	arg1=ARG_NOT_SET, arg2=ARG_NOT_SET, arg3=ARG_NOT_SET,
	arg4=ARG_NOT_SET, arg5=ARG_NOT_SET, arg6=ARG_NOT_SET,
	arg7=ARG_NOT_SET, arg8=ARG_NOT_SET, arg9=ARG_NOT_SET,
	arg10=ARG_NOT_SET, arg11=ARG_NOT_SET) -> void:
		var args = [arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11]
		
		# strip off any unused vars.
		var idx: int = args.size() - 1
		while(args[idx] == ARG_NOT_SET):
			args.remove_at(idx)
			idx -= 1
		
		# retrieve object and signal name from the array and remove_at them.  These
		# will always be at the end since they are added when the connect happens.
		var signal_name = args[args.size() -1]
		args.pop_back()
		var object = args[args.size() -1]
		args.pop_back()
		
		assert(_subject_signals.has(object), "Object was registered.")
		
		if(_subject_signals.has(object)):
			_subject_signals[object][signal_name] = true
		
		print("Signal '%s' has emitted from subject '%s'" % [signal_name, object])
	
	
	func _expire() -> void:
		if _waiting_on_signal:
			assert(_checking_signal != null and not _checking_signal.is_null(), 
					"_checking_signal should be valid.")
			assert(_subject_signals.has(_checking_signal.get_object()), "The object assosiated with " +
					"the signal being checked should be registered.")
			assert(_subject_signals[_checking_signal.get_object() as Node].has(_checking_signal.get_name()),
					"The signal should be registered with the subject.")
			
			_waiting_on_signal = false
			var subject = _checking_signal.get_object() as Node
			var signal_name: StringName = _checking_signal.get_name()
			_subject_signals[subject][signal_name] = false
		
		_running = false
		expired.emit()
