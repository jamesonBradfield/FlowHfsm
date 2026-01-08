class_name HFSMTestHarness extends Node

## Test harness for HFSM stress testing and benchmarking.
## Provides instrumentation for state transitions, timing, and assertions.

signal test_completed(results: Dictionary)

var test_root: RecursiveState
var state_log: Array[StringName] = []
var transition_log: Array[Dictionary] = []
var entry_timestamps: Dictionary = {}
var exit_timestamps: Dictionary = {}

var start_time: int = 0
var frame_count: int = 0
var profiling_enabled: bool = false

# Performance metrics
var process_time_accum: int = 0
var max_process_time: int = 0
var transition_times: Array[int] = []

## Setup the harness with a root state
func setup(root: RecursiveState) -> void:
	test_root = root
	# Recursively connect signals
	_connect_signals_recursive(test_root)
	
	start_time = Time.get_ticks_msec()
	
	# Ensure the root is entered to start the machine
	# This mimics the runtime behavior where a parent enters its children
	if not test_root.active_child and test_root.get_child_count() > 0:
		test_root.enter(self, {})

func _connect_signals_recursive(state: RecursiveState) -> void:
	if not state.state_entered.is_connected(_on_state_entered):
		state.state_entered.connect(_on_state_entered)
	if not state.state_exited.is_connected(_on_state_exited):
		state.state_exited.connect(_on_state_exited)
	
	for child in state.get_children():
		if child is RecursiveState:
			_connect_signals_recursive(child)

## Start profiling to collect performance metrics
func start_profiling() -> void:
	profiling_enabled = true
	process_time_accum = 0
	max_process_time = 0
	transition_times.clear()

## Stop profiling and return metrics
func stop_profiling() -> Dictionary:
	profiling_enabled = false
	return {
		"avg_process_time_us": process_time_accum / max(1, frame_count),
		"max_process_time_us": max_process_time,
		"total_frames": frame_count,
		"transition_times_ms": transition_times
	}

## Process a frame with timing instrumentation
func process_frame(delta: float, actor: Node, blackboard: Dictionary) -> void:
	if not test_root:
		push_error("Test harness not initialized. Call setup() first.")
		return

	var frame_start := Time.get_ticks_usec()

	# Process the state machine
	test_root.process_state(delta, actor, blackboard)

	var frame_end := Time.get_ticks_usec()
	var frame_time := frame_end - frame_start

	if profiling_enabled:
		process_time_accum += frame_time
		max_process_time = max(max_process_time, frame_time)

	frame_count += 1

## State entered callback
func _on_state_entered(state: RecursiveState) -> void:
	var elapsed := float(Time.get_ticks_msec() - start_time) / 1000.0
	state_log.append(state.name)
	entry_timestamps[state.name] = Time.get_ticks_msec()

	print("[%7.3f] ENTER %s (path: %s)" % [
		elapsed,
		state.name,
		" > ".join(test_root.get_active_hierarchy_path())
	])

## State exited callback
func _on_state_exited(state: RecursiveState) -> void:
	var elapsed := float(Time.get_ticks_msec() - start_time) / 1000.0
	state_log.append(state.name + "_EXIT")
	exit_timestamps[state.name] = Time.get_ticks_msec()

	var time_in_state := 0
	# Calculate time spent in this state
	if entry_timestamps.has(state.name):
		time_in_state = exit_timestamps[state.name] - entry_timestamps[state.name]
		transition_times.append(time_in_state)

	print("[%7.3f] EXIT  %s (duration: %.2fms)" % [elapsed, state.name, float(time_in_state) / 1000.0])

## Assert the current state matches expected
func assert_state(expected: StringName) -> bool:
	var current := test_root.get_active_hierarchy_path()
	if current.is_empty() or current[-1] != expected:
		push_error("Expected state '%s', got '%s'" % [expected, current[-1] if not current.is_empty() else "none"])
		return false
	return true

## Assert states were entered in the expected order
func assert_entry_order(expected: Array[StringName]) -> bool:
	var entries := state_log.filter(func(s: StringName): return not s.ends_with("_EXIT"))

	if entries != expected:
		var got := str(entries)
		push_error("Entry order mismatch.\nExpected: %s\nGot:      %s" % [expected, got])
		return false
	return true

## Assert a state was never entered
func assert_never_entered(state_name: StringName) -> bool:
	var entries := state_log.filter(func(s: StringName): return not s.ends_with("_EXIT"))

	if state_name in entries:
		push_error("State '%s' was entered but should not have been" % state_name)
		return false
	return true

## Assert a state was entered at least once
func assert_entered(state_name: StringName) -> bool:
	var entries := state_log.filter(func(s: StringName): return not s.ends_with("_EXIT"))

	if state_name not in entries:
		push_error("State '%s' was never entered but should have been" % state_name)
		return false
	return true

## Generate comprehensive test report
func generate_report() -> Dictionary:
	var unique_states := _count_unique_states()

	return {
		"states_visited": unique_states,
		"total_transitions": transition_log.size(),
		"total_frames": frame_count,
		"state_log": state_log,
		"entry_timestamps": entry_timestamps.duplicate(),
		"exit_timestamps": exit_timestamps.duplicate(),
		"profiling": stop_profiling() if profiling_enabled else {}
	}

## Count unique states visited (excluding exits)
func _count_unique_states() -> int:
	var unique := {}
	for s in state_log:
		var name: String = s if not s.ends_with("_EXIT") else s.trim_suffix("_EXIT")
		unique[name] = true
	return unique.size()

## Reset all logs and counters
func reset() -> void:
	state_log.clear()
	transition_log.clear()
	entry_timestamps.clear()
	exit_timestamps.clear()
	start_time = Time.get_ticks_msec()
	frame_count = 0

## Print summary statistics
func print_summary() -> void:
	print("\n" + "=".repeat(60))
	print("HFSM TEST HARNESS SUMMARY")
	print("=".repeat(60))
	print("Total Frames:     %d" % frame_count)
	print("States Visited:   %d" % _count_unique_states())
	print("Total Transitions: %d" % (state_log.size() / 2))  # Each transition has enter + exit

	if profiling_enabled:
		var metrics := stop_profiling()
		print("\nPerformance Metrics:")
		print("Avg Process Time: %.3f μs" % metrics.avg_process_time_us)
		print("Max Process Time: %.3f μs" % metrics.max_process_time_us)
		print("Frame Time Budget: %.3f ms (16666 μs)" % (1000.0 / 60.0))
		print("Budget Used:     %.2f%%" % (metrics.avg_process_time_us * 100.0 / 16666.0))

	print("=".repeat(60))
	print("State Log:")
	for i in range(0, state_log.size(), 2):
		var entry: String = state_log[i]
		var exit: String = state_log[i + 1] if i + 1 < state_log.size() else "STILL ACTIVE"
		print("  [%2d] %s -> %s" % [i / 2, entry, exit])

	print("=".repeat(60) + "\n")

## Cleanup - disconnect signals
func cleanup() -> void:
	if test_root:
		test_root.state_entered.disconnect(_on_state_entered)
		test_root.state_exited.disconnect(_on_state_exited)
		test_root = null
