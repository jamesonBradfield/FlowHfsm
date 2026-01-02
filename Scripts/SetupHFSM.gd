extends SceneTree

func _init():
	print("Starting HFSM Setup...")
	do_setup()
	quit()

func do_setup():
	var main_scene = load("res://main.tscn").instantiate()
	var character = main_scene.get_node("CharacterBody3D")
	var root = character.get_node("RootState")
	
	# Clear existing children of RootState if any (for idempotency)
	for child in root.get_children():
		child.free()
	
	# Load Resources
	var beh_run = load("res://Resources/behaviors/run.tres")
	var beh_jump = load("res://Resources/behaviors/jump.tres")
	
	var cond_input_jump = load("res://Resources/conditions/input_jump.tres")
	var cond_is_grounded = load("res://Resources/conditions/is_grounded.tres")
	var cond_is_moving = load("res://Resources/conditions/is_moving.tres")
	var cond_not_moving = load("res://Resources/conditions/not_moving.tres")
	
	# --- Create States ---
	
	# 1. Idle
	var state_idle = RecursiveState.new()
	state_idle.name = "Idle"
	state_idle.is_starting_state = true # Set Idle as start
	
	# Idle Transitions
	var t_idle_to_jump = StateTransition.new()
	t_idle_to_jump.target_state = "Jump"
	# Explicitly cast to the correct array type
	var conds_idle_jump: Array[StateCondition] = [cond_input_jump]
	t_idle_to_jump.conditions = conds_idle_jump
	
	var t_idle_to_run = StateTransition.new()
	t_idle_to_run.target_state = "Run"
	var conds_idle_run: Array[StateCondition] = [cond_is_moving]
	t_idle_to_run.conditions = conds_idle_run
	
	var trans_idle: Array[StateTransition] = [t_idle_to_jump, t_idle_to_run]
	state_idle.transitions = trans_idle
	
	# 2. Run
	var state_run = RecursiveState.new()
	state_run.name = "Run"
	state_run.behavior = beh_run
	
	# Run Transitions
	var t_run_to_jump = StateTransition.new()
	t_run_to_jump.target_state = "Jump"
	var conds_run_jump: Array[StateCondition] = [cond_input_jump]
	t_run_to_jump.conditions = conds_run_jump
	
	var t_run_to_idle = StateTransition.new()
	t_run_to_idle.target_state = "Idle"
	var conds_run_idle: Array[StateCondition] = [cond_not_moving]
	t_run_to_idle.conditions = conds_run_idle
	
	var trans_run: Array[StateTransition] = [t_run_to_jump, t_run_to_idle]
	state_run.transitions = trans_run
	
	# 3. Jump
	var state_jump = RecursiveState.new()
	state_jump.name = "Jump"
	state_jump.behavior = beh_jump
	
	# Jump Transitions
	# Use a trick: only transition to Idle if grounded AND we aren't moving upwards?
	# Or rely on the fact that is_on_floor updates in physics.
	var t_jump_to_idle = StateTransition.new()
	t_jump_to_idle.target_state = "Idle"
	var conds_jump_idle: Array[StateCondition] = [cond_is_grounded]
	t_jump_to_idle.conditions = conds_jump_idle
	
	# Also allow moving while in air?
	# The current system structure implies "Run" checks "is_moving".
	# If we are in "Jump" state, we might not have movement control unless "Jump" state also has movement behavior?
	# "BehaviorJump" only applies impulse. It doesn't handle air movement.
	# If we want air control, we might need a composite behavior or "Air" state with "Move" behavior.
	# But user said "use premade". "BehaviorMove" handles input.
	# So maybe "Jump" state should ALSO have "BehaviorMove" logic?
	# But RecursiveState only holds ONE behavior.
	
	# Setup: Jump -> (Transition on Grounded) -> Idle
	# To have air control, we usually use a separate system or "Air" state that uses "BehaviorMove" but with different friction.
	# But let's stick to the basics.
	
	var trans_jump: Array[StateTransition] = [t_jump_to_idle]
	state_jump.transitions = trans_jump
	
	# --- Add to Root ---
	root.add_child(state_idle)
	state_idle.owner = main_scene # Important for packing
	
	root.add_child(state_run)
	state_run.owner = main_scene
	
	root.add_child(state_jump)
	state_jump.owner = main_scene
	
	# --- Save ---
	var packed = PackedScene.new()
	packed.pack(main_scene)
	ResourceSaver.save(packed, "res://playable_scene.tscn")
	print("Saved res://playable_scene.tscn")
