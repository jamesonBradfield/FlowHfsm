extends Node

## Main Test Runner for HFSM Stress Testing
##
## Coordinates execution of all stress tests and benchmarks.
## Run this scene to execute the full test suite.

## Test configuration
@export var run_hierarchy_tests: bool = true
@export var run_atomic_tests: bool = true
@export var run_animation_tests: bool = true
@export var run_benchmarks: bool = true
@export var stop_on_failure: bool = false

## Test results
var all_results: Dictionary = {}
var test_start_time: int = 0
var total_test_time: int = 0

## Signals
signal all_tests_complete(results: Dictionary)
signal test_suite_finished(suite_name: String, results: Dictionary)

func _ready() -> void:
	print("\n" + "█".repeat(70))
	print("█" + " ".repeat(68) + "█")
	print("█" + _center_string("HFSM STRESS TEST & BENCHMARK SUITE", 68) + "█")
	print("█" + " ".repeat(68) + "█")
	print("█".repeat(70) + "\n")

	print("Configuration:")
	print("  Hierarchy Tests:    %s" % ("✓ Enabled" if run_hierarchy_tests else "✗ Disabled"))
	print("  Atomic Tests:       %s" % ("✓ Enabled" if run_atomic_tests else "✗ Disabled"))
	print("  Animation Tests:    %s" % ("✓ Enabled" if run_animation_tests else "✗ Disabled"))
	print("  Benchmarks:         %s" % ("✓ Enabled" if run_benchmarks else "✗ Disabled"))
	print("  Stop on Failure:    %s" % ("✓ Yes" if stop_on_failure else "✗ No"))
	print()

	test_start_time = Time.get_ticks_msec()

	# Run test suites
	await _run_all_tests()

	# Generate final report
	_generate_final_report()

func _run_all_tests() -> void:
	if run_hierarchy_tests:
		await _run_hierarchy_tests()

	if run_atomic_tests:
		await _run_atomic_tests()

	if run_animation_tests:
		await _run_animation_tests()

	if run_benchmarks:
		await _run_benchmarks()

## Hierarchy Blocking Tests
func _run_hierarchy_tests() -> void:
	print("\n" + "=".repeat(70))
	print("RUNNING HIERARCHY BLOCKING TESTS")
	print("=".repeat(70))

	var test_suite: HierarchyBlockingStressTest = HierarchyBlockingStressTest.new()
	add_child(test_suite)

	var results: Dictionary = test_suite.run_all_tests()
	all_results["hierarchy_tests"] = results

	test_suite.queue_free()
	test_suite_finished.emit("Hierarchy Blocking Tests", results)

	await get_tree().process_frame

	var passed := _count_passed_tests(results)
	var total := results.size()

	print("\nHierarchy Tests Summary: %d/%d passed (%.1f%%)" %
		[passed, total, float(passed) / max(1, total) * 100.0])

	if stop_on_failure and passed < total:
		push_error("Hierarchy tests failed. Stopping.")
		get_tree().quit()

## Atomic Transition Tests
func _run_atomic_tests() -> void:
	print("\n" + "=".repeat(70))
	print("RUNNING ATOMIC TRANSITION TESTS")
	print("=".repeat(70))

	var test_suite: AtomicTransitionStressTest = AtomicTransitionStressTest.new()
	add_child(test_suite)

	var results: Dictionary = test_suite.run_all_tests()
	all_results["atomic_tests"] = results

	test_suite.queue_free()
	test_suite_finished.emit("Atomic Transition Tests", results)

	await get_tree().process_frame

	var passed := _count_passed_tests(results)
	var total := results.size()

	print("\nAtomic Tests Summary: %d/%d passed (%.1f%%)" %
		[passed, total, float(passed) / max(1, total) * 100.0])

	if stop_on_failure and passed < total:
		push_error("Atomic tests failed. Stopping.")
		get_tree().quit()

## Animation Integration Tests
func _run_animation_tests() -> void:
	print("\n" + "=".repeat(70))
	print("RUNNING ANIMATION INTEGRATION TESTS")
	print("=".repeat(70))

	var test_suite = load("res://Scripts/Tests/AnimationIntegrationTest.gd").new()
	add_child(test_suite)

	var results: Dictionary = test_suite.run_all_tests()
	all_results["animation_tests"] = results

	test_suite.queue_free()
	test_suite_finished.emit("Animation Integration Tests", results)

	await get_tree().process_frame

	var passed := _count_passed_tests(results)
	var total := results.size()

	print("\nAnimation Tests Summary: %d/%d passed (%.1f%%)" %
		[passed, total, float(passed) / max(1, total) * 100.0])

	if stop_on_failure and passed < total:
		push_error("Animation tests failed. Stopping.")
		get_tree().quit()

## Performance Benchmarks
func _run_benchmarks() -> void:
	print("\n" + "=".repeat(70))
	print("RUNNING PERFORMANCE BENCHMARKS")
	print("=".repeat(70))

	var benchmark_suite: PerformanceBenchmarkSuite = PerformanceBenchmarkSuite.new()
	add_child(benchmark_suite)

	var results: Dictionary = benchmark_suite.run_all_benchmarks()
	all_results["benchmarks"] = results

	benchmark_suite.queue_free()
	test_suite_finished.emit("Performance Benchmarks", results)

	await get_tree().process_frame

## Count passed tests in a results dictionary
func _count_passed_tests(results: Dictionary) -> int:
	var passed := 0
	for key in results.keys():
		var test_result: Dictionary = results[key] as Dictionary
		if test_result.get("passed", false):
			passed += 1
	return passed

## Helper for string centering (Godot 4 String doesn't have center())
func _center_string(s: String, width: int, pad: String = " ") -> String:
	if s.length() >= width:
		return s
	var left_pad := int((width - s.length()) / 2.0)
	var right_pad := width - s.length() - left_pad
	return pad.repeat(left_pad) + s + pad.repeat(right_pad)

## Generate final comprehensive report
func _generate_final_report() -> void:
	total_test_time = Time.get_ticks_msec() - test_start_time

	print("\n" + "█".repeat(70))
	print("█" + " ".repeat(68) + "█")
	print("█" + _center_string("FINAL TEST REPORT", 68) + "█")
	print("█" + " ".repeat(68) + "█")
	print("█".repeat(70) + "\n")

	# Overall summary
	var total_tests := 0
	var total_passed := 0
	var total_benchmarks := 0
	var acceptable_benchmarks := 0

	# Hierarchy tests
	if all_results.has("hierarchy_tests"):
		var h_results: Dictionary = all_results["hierarchy_tests"] as Dictionary
		total_tests += h_results.size()
		total_passed += _count_passed_tests(h_results)

	# Atomic tests
	if all_results.has("atomic_tests"):
		var a_results: Dictionary = all_results["atomic_tests"] as Dictionary
		total_tests += a_results.size()
		total_passed += _count_passed_tests(a_results)

	# Animation tests
	if all_results.has("animation_tests"):
		var a_results: Dictionary = all_results["animation_tests"] as Dictionary
		total_tests += a_results.size()
		total_passed += _count_passed_tests(a_results)

	# Benchmarks
	if all_results.has("benchmarks"):
		var b_results: Dictionary = all_results["benchmarks"] as Dictionary
		for key in b_results.keys():
			total_benchmarks += 1
			var result: Dictionary = b_results[key] as Dictionary
			if result.get("acceptable", true):
				acceptable_benchmarks += 1

	print("Test Execution Time: %.2f seconds" % (total_test_time / 1000.0))
	print("\nTest Results:")
	print("  Total Tests:      %d" % total_tests)
	print("  Tests Passed:     %d" % total_passed)
	print("  Tests Failed:     %d" % (total_tests - total_passed))
	print("  Pass Rate:        %.1f%%" % (float(total_passed) / max(1, total_tests) * 100.0))

	print("\nBenchmark Results:")
	print("  Total Benchmarks: %d" % total_benchmarks)
	print("  Acceptable:       %d" % acceptable_benchmarks)
	print("  Needs Attention: %d" % (total_benchmarks - acceptable_benchmarks))

	# Detailed breakdown
	print("\n" + "-".repeat(70))
	print("DETAILED BREAKDOWN")
	print("-".repeat(70))

	if all_results.has("hierarchy_tests"):
		print("\n[Hierarchy Blocking Tests]")
		_print_test_details(all_results["hierarchy_tests"])

	if all_results.has("atomic_tests"):
		print("\n[Atomic Transition Tests]")
		_print_test_details(all_results["atomic_tests"])

	if all_results.has("animation_tests"):
		print("\n[Animation Integration Tests]")
		_print_test_details(all_results["animation_tests"])

	if all_results.has("benchmarks"):
		print("\n[Performance Benchmarks]")
		_print_benchmark_details(all_results["benchmarks"])

	# Final verdict
	print("\n" + "█".repeat(70))
	var all_passed := (total_passed == total_tests) and (acceptable_benchmarks == total_benchmarks)
	var verdict = "✓ ALL TESTS PASSED" if all_passed else "✗ SOME TESTS FAILED"
	print("█" + " ".repeat(68) + "█")
	print("█" + _center_string(verdict, 68) + "█")
	print("█" + " ".repeat(68) + "█")
	print("█".repeat(70) + "\n")

	all_tests_complete.emit(all_results)

## Print test details
func _print_test_details(results: Dictionary) -> void:
	for key in results.keys():
		var result: Dictionary = results[key] as Dictionary
		var test_name = result.get("test_name", key)
		var passed = result.get("passed", false)
		var status = "✓ PASS" if passed else "✗ FAIL"
		print("  %s %s" % [status, test_name])

## Print benchmark details
func _print_benchmark_details(results: Dictionary) -> void:
	for key in results.keys():
		var result: Dictionary = results[key] as Dictionary
		var bench_name = result.get("benchmark_name", key)
		var acceptable = result.get("acceptable", true)
		var status = "✓ PASS" if acceptable else "✗ FAIL"

		if result.has("avg_time_us"):
			print("  %s %-30s Avg: %6.2f μs | Budget: %5.2f%%" %
				[status, bench_name, result.avg_time_us, result.budget_used_pct])
		elif result.has("avg_load_us"):
			print("  %s %-30s Load: %6.2f μs | Access: %6.2f μs" %
				[status, bench_name, result.avg_load_us, result.avg_access_us])

## Save results to JSON file
func save_results_to_json(filepath: String) -> void:
	var file := FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(all_results, "\t"))
		file.close()
		print("Results saved to: %s" % filepath)
	else:
		push_error("Failed to save results to: %s" % filepath)

## Quit after tests
func quit() -> void:
	get_tree().quit()
	# Fallback: Force kill if engine hangs (common in CI/headless)
	await get_tree().create_timer(0.5).timeout
	OS.kill(OS.get_process_id())

## Auto-quit immediately after tests
func _on_all_tests_complete(_results: Dictionary) -> void:
	print("Tests complete. Exiting...")
	# Force a frame process to ensure print buffer flushes
	await get_tree().process_frame
	quit()
