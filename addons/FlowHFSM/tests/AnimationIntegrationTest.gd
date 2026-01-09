class_name AnimationIntegrationTest
extends Node

## Integration tests for HFSM <-> AnimationTree
##
## Verifies that HFSM state changes correctly drive AnimationNodeStateMachine
## via the HFSMAnimationController.

var test_harness: HFSMTestHarness
var test_actor: MockActor
var animation_controller
var mock_anim_tree

var root_state: RecursiveState

## Mock Actor with dynamic properties
class MockActor extends Node3D:
	var properties: Dictionary = {}
	
	func get(property: StringName) -> Variant:
		if properties.has(property):
			return properties[property]
		return null
		
	func set(property: StringName, value: Variant) -> bool:
		properties[property] = value
		return true

## Run all animation integration tests
func run_all_tests() -> Dictionary:
	var results := {}

	print("\n" + "#".repeat(70))
	print("ANIMATION INTEGRATION TESTS")
	print("#".repeat(70) + "\n")

	_setup_environment()

	results["test_direct_mapping_travel"] = test_direct_mapping_travel()
	_reset_environment()
	
	results["test_blackboard_trigger_animation"] = test_blackboard_trigger_animation()
	_reset_environment()

	results["test_parameter_sync"] = test_parameter_sync()
	_reset_environment()
	
	_cleanup()

	return results

## Test 3: Verify parameter syncing (Source -> AnimationTree)
func test_parameter_sync() -> Dictionary:
	print("\n[TEST] Parameter Sync")
	print("-".repeat(40))

	var test_name := "parameter_sync"
	var test_passed := true
	
	# Setup: Define a mapping "speed" -> "parameters/Run/blend_position"
	if animation_controller:
		animation_controller.property_mapping = {
			"speed": "parameters/Run/blend_position"
		}
	
	# Mock source
	var mock_source = MockActor.new()
	add_child(mock_source)
	if animation_controller:
		animation_controller.property_source = mock_source
	
	# Act: Set value in source
	var test_val = 0.5
	mock_source.set("speed", test_val)
	
	# Process frame
	animation_controller._process(0.016)
	
	# Assert: AnimationTree received the value
	var actual_val = mock_anim_tree.get("parameters/Run/blend_position")
	
	if actual_val != test_val:
		push_error("Expected blend_position %s, got %s" % [test_val, actual_val])
		test_passed = false
		
	print("✓ Property 'speed': %s -> AnimationTree: %s" % [test_val, actual_val])

	return _generate_test_result(test_name, test_passed)

## Test 1: Verify entering HFSM state triggers correct Animation travel
func test_direct_mapping_travel() -> Dictionary:
	print("\n[TEST] Direct Mapping Travel")
	print("-".repeat(40))

	var test_name := "direct_mapping_travel"
	var test_passed := true
	
	# Setup hierarchy: Root -> Idle (start), Run
	var run_state := RecursiveState.new()
	run_state.name = "Run"
	root_state.add_child(run_state)
	
	# Manually connect the new state to the controller since it was added after controller _ready
	if animation_controller.has_method("_connect_signals_recursive"):
		animation_controller._connect_signals_recursive(run_state)
	
	# Re-init harness with new structure
	test_harness.setup(root_state)
	
	# Act: Manually switch HFSM state to Run
	root_state.change_active_child(run_state, test_actor)
	
	# Process frame to ensure signals propagate
	test_harness.process_frame(0.016, test_actor)
	
	# Assert: AnimationTree should have traveled to "Run"
	var current_anim = mock_anim_tree.mock_playback.get_current_node()
	var expected_anim = "Run"
	
	if current_anim != expected_anim:
		push_error("Expected animation '%s', got '%s'" % [expected_anim, current_anim])
		test_passed = false
		
	print("✓ HFSM State 'Run' -> Animation 'Run': %s" % test_passed)
	
	return _generate_test_result(test_name, test_passed)

## Test 2: Verify actor variable triggers HFSM transition -> Animation change
func test_blackboard_trigger_animation() -> Dictionary:
	print("\n[TEST] Actor Property Trigger -> Animation Change")
	print("-".repeat(40))

	var test_name := "blackboard_trigger_animation"
	var test_passed := true

	# Setup hierarchy: Root -> Idle (start), Jump
	var jump_state := RecursiveState.new()
	jump_state.name = "Jump"
	# Add condition: is_jumping == true
	jump_state.activation_conditions = [_create_condition("is_jumping", false)]
	root_state.add_child(jump_state)
	
	# Manually connect new state
	if animation_controller.has_method("_connect_signals_recursive"):
		animation_controller._connect_signals_recursive(jump_state)
	
	# Re-init harness
	test_harness.setup(root_state)
	
	# Act: Set actor variable
	test_actor.set("is_jumping", true)
	
	# Process frame to trigger HFSM transition logic
	test_harness.process_frame(0.016, test_actor)
	
	# Assert 1: HFSM entered Jump
	var hfsm_in_jump = test_harness.assert_state("Jump")
	test_passed = test_passed and hfsm_in_jump
	
	# Assert 2: Animation traveled to Jump
	var current_anim = mock_anim_tree.mock_playback.get_current_node()
	var expected_anim = "Jump"
	
	var anim_correct = (current_anim == expected_anim)
	if not anim_correct:
		push_error("Expected animation '%s', got '%s'" % [expected_anim, current_anim])
		test_passed = false
	
	print("✓ Actor 'is_jumping' -> HFSM Jump: %s" % hfsm_in_jump)
	print("✓ HFSM Jump -> Animation Jump: %s" % anim_correct)

	return _generate_test_result(test_name, test_passed)

## Helper: Create test condition
func _create_condition(cond_name: String, return_value: bool) -> StateCondition:
	var condition := MockCondition.new()
	condition.resource_name = cond_name
	condition.fixed_value = return_value
	return condition

## Mock condition for testing
class MockCondition extends StateCondition:
	var fixed_value: bool = false
	
	func _evaluate(actor: Node) -> bool:
		var val = actor.get(resource_name)
		if val != null and val is bool:
			return val
		return fixed_value

## Helper: Generate test result
func _generate_test_result(test_name: String, passed: bool) -> Dictionary:
	return {
		"test_name": test_name,
		"passed": passed,
		"timestamp": Time.get_ticks_msec()
	}

## Setup test environment
func _setup_environment() -> void:
	# 1. Actors
	test_actor = MockActor.new()
	add_child(test_actor)
	
	# 2. HFSM Root
	root_state = RecursiveState.new()
	root_state.name = "Root"
	
	var idle_state = RecursiveState.new()
	idle_state.name = "Idle"
	idle_state.is_starting_state = true
	root_state.add_child(idle_state)
	
	# 3. Mocks
	mock_anim_tree = load("res://addons/FlowHFSM/tests/Mocks/MockAnimationTree.gd").new()
	add_child(mock_anim_tree)
	
	# 4. Controller
	animation_controller = load("res://addons/FlowHFSM/runtime/components/HFSMAnimationController.gd").new()
	animation_controller.root_state = root_state
	animation_controller.animation_tree = mock_anim_tree
	animation_controller.property_source = test_actor # Bind to our mock actor
	add_child(animation_controller)
	
	# 5. Harness
	test_harness = HFSMTestHarness.new()
	add_child(test_harness)

## Reset environment
func _reset_environment() -> void:
	# Full tear down and rebuild safer for complex state interactions
	_cleanup()
	_setup_environment()

## Cleanup
func _cleanup() -> void:
	if is_instance_valid(test_harness):
		test_harness.queue_free()
	if is_instance_valid(animation_controller):
		animation_controller.queue_free()
	if is_instance_valid(mock_anim_tree):
		mock_anim_tree.queue_free()
	if is_instance_valid(root_state):
		root_state.free() # Manually free as it might not be in tree if not setup
	if is_instance_valid(test_actor):
		test_actor.queue_free()
