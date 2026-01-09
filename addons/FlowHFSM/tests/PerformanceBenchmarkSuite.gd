class_name PerformanceBenchmarkSuite
extends Node

## Performance Benchmark Suite for HFSM
##
## Measures CPU usage, memory overhead, and transition times under various loads.

var test_harness: HFSMTestHarness
var blackboard: Dictionary = {}
var test_actor: Node3D

## Benchmark results storage
var benchmark_results: Dictionary = {}

## Run all performance benchmarks
func run_all_benchmarks() -> Dictionary:
	print("\n" + "#".repeat(70))
	print("HFSM PERFORMANCE BENCHMARK SUITE")
	print("#".repeat(70) + "\n")

	_setup_environment()

	# Warmup
	print("[WARMUP] Running warmup cycles...")
	_warmup()

	# Baseline benchmark
	benchmark_results["baseline_single_state"] = benchmark_baseline_single_state()
	_reset_environment()

	# Small hierarchy
	benchmark_results["small_hierarchy_5_states"] = benchmark_small_hierarchy()
	_reset_environment()

	# Medium hierarchy
	benchmark_results["medium_hierarchy_20_states"] = benchmark_medium_hierarchy()
	_reset_environment()

	# Large hierarchy
	benchmark_results["large_hierarchy_100_states"] = benchmark_large_hierarchy()
	_reset_environment()

	# Deep hierarchy
	benchmark_results["deep_hierarchy_15_levels"] = benchmark_deep_hierarchy()
	_reset_environment()

	# Wide hierarchy
	benchmark_results["wide_hierarchy_20_children"] = benchmark_wide_hierarchy()
	_reset_environment()

	# Resource loading
	benchmark_results["resource_loading"] = benchmark_resource_loading()
	_reset_environment()

	# Blackboard access
	benchmark_results["blackboard_access"] = benchmark_blackboard_access()
	_reset_environment()

	_cleanup()

	# Print summary
	_print_benchmark_summary()

	return benchmark_results

## Benchmark 1: Baseline - Single state
func benchmark_baseline_single_state() -> Dictionary:
	print("\n[BENCHMARK] Baseline - Single State")
	print("-".repeat(40))

	var root := RecursiveState.new()
	root.name = "Root"

	test_harness.setup(root)
	test_harness.start_profiling()

	var frames := 5000
	for i in range(frames):
		test_harness.process_frame(0.016, test_actor, blackboard)

	var metrics := test_harness.stop_profiling()
	var result := _format_benchmark_result("Single State", frames, metrics)

	print("✓ Avg: %.3f μs | Max: %.3f μs | Budget: %.2f%%" %
		[result.avg_time_us, result.max_time_us, result.budget_used_pct])

	return result

## Benchmark 2: Small hierarchy (5 states)
func benchmark_small_hierarchy() -> Dictionary:
	print("\n[BENCHMARK] Small Hierarchy (5 states)")
	print("-".repeat(40))

	var root := _create_flat_hierarchy(5)
	test_harness.setup(root)
	test_harness.start_profiling()

	var frames := 5000
	for i in range(frames):
		test_harness.process_frame(0.016, test_actor, blackboard)

	var metrics := test_harness.stop_profiling()
	var result := _format_benchmark_result("Small Hierarchy (5)", frames, metrics)

	print("✓ Avg: %.3f μs | Max: %.3f μs | Budget: %.2f%%" %
		[result.avg_time_us, result.max_time_us, result.budget_used_pct])

	return result

## Benchmark 3: Medium hierarchy (20 states)
func benchmark_medium_hierarchy() -> Dictionary:
	print("\n[BENCHMARK] Medium Hierarchy (20 states)")
	print("-".repeat(40))

	var root := _create_flat_hierarchy(20)
	test_harness.setup(root)
	test_harness.start_profiling()

	var frames := 5000
	for i in range(frames):
		test_harness.process_frame(0.016, test_actor, blackboard)

	var metrics := test_harness.stop_profiling()
	var result := _format_benchmark_result("Medium Hierarchy (20)", frames, metrics)

	print("✓ Avg: %.3f μs | Max: %.3f μs | Budget: %.2f%%" %
		[result.avg_time_us, result.max_time_us, result.budget_used_pct])

	return result

## Benchmark 4: Large hierarchy (100 states)
func benchmark_large_hierarchy() -> Dictionary:
	print("\n[BENCHMARK] Large Hierarchy (100 states)")
	print("-".repeat(40))

	var root := _create_flat_hierarchy(100)
	test_harness.setup(root)
	test_harness.start_profiling()

	var frames := 5000
	for i in range(frames):
		test_harness.process_frame(0.016, test_actor, blackboard)

	var metrics := test_harness.stop_profiling()
	var result := _format_benchmark_result("Large Hierarchy (100)", frames, metrics)

	print("✓ Avg: %.3f μs | Max: %.3f μs | Budget: %.2f%%" %
		[result.avg_time_us, result.max_time_us, result.budget_used_pct])

	return result

## Benchmark 5: Deep hierarchy (15 levels)
func benchmark_deep_hierarchy() -> Dictionary:
	print("\n[BENCHMARK] Deep Hierarchy (15 levels)")
	print("-".repeat(40))

	var root := _create_deep_hierarchy(15)
	test_harness.setup(root)
	test_harness.start_profiling()

	var frames := 5000
	for i in range(frames):
		test_harness.process_frame(0.016, test_actor, blackboard)

	var metrics := test_harness.stop_profiling()
	var result := _format_benchmark_result("Deep Hierarchy (15)", frames, metrics)

	print("✓ Avg: %.3f μs | Max: %.3f μs | Budget: %.2f%%" %
		[result.avg_time_us, result.max_time_us, result.budget_used_pct])

	return result

## Benchmark 6: Wide hierarchy (20 children at one level)
func benchmark_wide_hierarchy() -> Dictionary:
	print("\n[BENCHMARK] Wide Hierarchy (20 children)")
	print("-".repeat(40))

	var root := _create_wide_hierarchy(20)
	test_harness.setup(root)
	test_harness.start_profiling()

	var frames := 5000
	for i in range(frames):
		# Simulate different inputs to trigger different children
		blackboard["input_select"] = i % 20
		test_harness.process_frame(0.016, test_actor, blackboard)

	var metrics := test_harness.stop_profiling()
	var result := _format_benchmark_result("Wide Hierarchy (20)", frames, metrics)

	print("✓ Avg: %.3f μs | Max: %.3f μs | Budget: %.2f%%" %
		[result.avg_time_us, result.max_time_us, result.budget_used_pct])

	return result

## Benchmark 7: Resource loading performance
func benchmark_resource_loading() -> Dictionary:
	print("\n[BENCHMARK] Resource Loading")
	print("-".repeat(40))

	var resource_count := 100
	var resources: Array[Resource] = []

	# Time loading 100 StateBehavior resources
	var load_start := Time.get_ticks_usec()
	for i in range(resource_count):
		var behavior := StateBehavior.new()
		behavior.resource_name = "Behavior_%d" % i
		resources.append(behavior)
	var load_end := Time.get_ticks_usec()

	var load_time_ms: float = (load_end - load_start) / 1000.0
	var avg_load_us: float = float(load_end - load_start) / resource_count

	# Time accessing these resources
	var access_start := Time.get_ticks_usec()
	for i in range(10000):
		var _r = resources[i % resource_count]
	var access_end := Time.get_ticks_usec()

	var avg_access_us: float = float(access_end - access_start) / 10000.0

	print("✓ Loaded %d resources in %.2f ms" % [resource_count, load_time_ms])
	print("✓ Avg load time: %.3f μs per resource" % avg_load_us)
	print("✓ Avg access time: %.3f μs" % avg_access_us)

	return {
		"benchmark_name": "Resource Loading",
		"resource_count": resource_count,
		"load_time_ms": load_time_ms,
		"avg_load_us": avg_load_us,
		"avg_access_us": avg_access_us,
		"acceptable": load_time_ms < 100  # Should load 100 resources in < 100ms
	}

## Benchmark 8: Blackboard access performance
func benchmark_blackboard_access() -> Dictionary:
	print("\n[BENCHMARK] Blackboard Access")
	print("-".repeat(40))

	# Setup blackboard with typical data
	blackboard = {
		"input_dir": Vector2.ZERO,
		"is_grounded": true,
		"velocity": Vector3.ZERO,
		"health": 100,
		"position": Vector3.ZERO
	}

	var iterations := 100000

	# Benchmark read access
	var read_start := Time.get_ticks_usec()
	for i in range(iterations):
		var _v1 = blackboard.get("input_dir", Vector2.ZERO)
		var _v2 = blackboard.get("is_grounded", false)
		var _v3 = blackboard.get("health", 0)
	var read_end := Time.get_ticks_usec()

	var avg_read_us: float = float(read_end - read_start) / (iterations * 3.0)

	# Benchmark write access
	var write_start := Time.get_ticks_usec()
	for i in range(iterations):
		blackboard["input_dir"] = Vector2(1.0, 0.0)
		blackboard["is_grounded"] = true
		blackboard["health"] = 100
	var write_end := Time.get_ticks_usec()

	var avg_write_us: float = float(write_end - write_start) / (iterations * 3.0)

	print("✓ Read access (%d lookups): %.3f μs" % [iterations * 3, avg_read_us])
	print("✓ Write access (%d writes): %.3f μs" % [iterations * 3, avg_write_us])

	return {
		"benchmark_name": "Blackboard Access",
		"iterations": iterations * 3,
		"avg_read_us": avg_read_us,
		"avg_write_us": avg_write_us,
		"acceptable": avg_read_us < 1.0 and avg_write_us < 1.0
	}

## Warmup function to ensure JIT and cache warmup
func _warmup() -> void:
	var root := _create_flat_hierarchy(10)
	test_harness.setup(root)

	for i in range(100):
		test_harness.process_frame(0.016, test_actor, blackboard)

	test_harness.cleanup()
	test_harness = HFSMTestHarness.new()
	add_child(test_harness)

## Helper: Create flat hierarchy
func _create_flat_hierarchy(count: int) -> RecursiveState:
	var root := RecursiveState.new()
	root.name = "Root"

	for i in range(count):
		var state := RecursiveState.new()
		state.name = "State_%d" % i
		state.is_starting_state = (i == 0)
		root.add_child(state)

	return root

## Helper: Create deep hierarchy
func _create_deep_hierarchy(depth: int) -> RecursiveState:
	var root := RecursiveState.new()
	root.name = "Root"

	var current := root
	for i in range(depth):
		var child := RecursiveState.new()
		child.name = "Level_%d" % i
		child.is_starting_state = true
		current.add_child(child)
		current = child

	return root

## Helper: Create wide hierarchy
func _create_wide_hierarchy(child_count: int) -> RecursiveState:
	var root := RecursiveState.new()
	root.name = "Root"

	for i in range(child_count):
		var child := RecursiveState.new()
		child.name = "Child_%d" % i
		child.is_starting_state = (i == 0)

		# Add condition to select based on input
		var condition := MockCondition.new()
		condition.resource_name = "Select_%d" % i
		child.activation_conditions = [condition]

		root.add_child(child)

	return root

## Helper: Format benchmark result
func _format_benchmark_result(bench_name: String, frames: int, metrics: Dictionary) -> Dictionary:
	var avg_us: float = metrics.avg_process_time_us
	var max_us: float = metrics.max_process_time_us
	var budget_us := 16666.0  # 60 FPS budget in microseconds
	var budget_used: float = avg_us / budget_us * 100.0

	return {
		"benchmark_name": bench_name,
		"frames_processed": frames,
		"avg_time_us": avg_us,
		"max_time_us": max_us,
		"budget_us": budget_us,
		"budget_used_pct": budget_used,
		"acceptable": budget_used < 1.0  # Should use less than 1% of frame budget
	}

## Print summary of all benchmarks
func _print_benchmark_summary() -> void:
	print("\n" + "=".repeat(70))
	print("BENCHMARK SUMMARY")
	print("=".repeat(70))

	var acceptable_count := 0
	var total_count := 0

	for key in benchmark_results.keys():
		var result := benchmark_results[key] as Dictionary
		total_count += 1

		if result.has("acceptable") and result.acceptable:
			acceptable_count += 1

		var bench_name: String = result.get("benchmark_name", key)
		var acceptable: bool = result.get("acceptable", true)
		var status = "✓ PASS" if acceptable else "✗ FAIL"

		if result.has("avg_time_us"):
			print("%s %-30s Avg: %6.2f μs | Budget: %5.2f%%" %
				[status, bench_name, result.avg_time_us, result.budget_used_pct])

	print("-".repeat(70))
	print("Results: %d/%d benchmarks passed (%.1f%%)" %
		[acceptable_count, total_count, float(acceptable_count) / total_count * 100.0])
	print("=".repeat(70) + "\n")

## Setup test environment
func _setup_environment() -> void:
	test_harness = HFSMTestHarness.new()
	test_actor = Node3D.new()
	add_child(test_harness)
	add_child(test_actor)
	blackboard = {}

## Reset environment between benchmarks
func _reset_environment() -> void:
	test_harness.reset()
	blackboard = {}
	# Clear children of test_harness
	for child in test_harness.get_children():
		if child is RecursiveState:
			child.queue_free()

## Cleanup
func _cleanup() -> void:
	if test_harness:
		test_harness.cleanup()
		test_harness.queue_free()

	if test_actor:
		test_actor.queue_free()

## Mock condition for testing
class MockCondition extends StateCondition:
	func _evaluate(_actor: Node, _blackboard: Dictionary) -> bool:
		return false
