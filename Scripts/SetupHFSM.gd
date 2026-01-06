extends SceneTree

## Automation script to setup the initial HFSM structure for the player.
## Run this using: `godot --headless -s Scripts/SetupHFSM.gd`

func _init():
	print("Starting HFSM Setup...")
	do_setup()
	quit()

## Constructs the HFSM hierarchy (Grounded, Airborne) and saves it to a scene file.
func do_setup():
	var main_scene = load("res://playable_scene.tscn").instantiate()
	var character = main_scene.get_node("CharacterBody3D")
	var root_state = character.get_node("RootState")
	
	# Clear existing children of RootState if any (for idempotency)
	for child in root_state.get_children():
		child.free()
	
	# Load Resources
	var beh_run = load("res://Resources/behaviors/run.tres")
	var beh_jump = load("res://Resources/behaviors/jump.tres")
	
	# Load Scripts for Conditions (we instantiate them to ensure unique configuration)
	var ScriptIsGrounded = load("res://Scripts/ConditionIsGrounded.gd")
	var ScriptMovement = load("res://Scripts/ConditionMovement.gd")
	var ScriptInput = load("res://Scripts/ConditionInput.gd")
	
	# --- Create States ---
	
	# 1. Grounded State
	var state_grounded = RecursiveState.new()
	state_grounded.name = "Grounded"
	
	var cond_grounded = ScriptIsGrounded.new()
	set_conditions(state_grounded, [cond_grounded])
	
	# 2. Airborne State
	var state_airborne = RecursiveState.new()
	state_airborne.name = "Airborne"
	
	var cond_airborne = ScriptIsGrounded.new()
	cond_airborne.reverse_result = true
	set_conditions(state_airborne, [cond_airborne])
	
	# --- Grounded Sub-States ---
	
	# Grounded -> Idle
	var state_g_idle = RecursiveState.new()
	state_g_idle.name = "Idle"
	state_g_idle.is_starting_state = true
	
	var cond_not_moving = ScriptMovement.new()
	cond_not_moving.reverse_result = true
	set_conditions(state_g_idle, [cond_not_moving])
	
	# Grounded -> Run
	var state_g_run = RecursiveState.new()
	state_g_run.name = "Run"
	state_g_run.behavior = beh_run
	
	var cond_moving = ScriptMovement.new()
	set_conditions(state_g_run, [cond_moving])
	
	# Grounded -> Jump
	var state_g_jump = RecursiveState.new()
	state_g_jump.name = "Jump"
	state_g_jump.behavior = beh_jump
	
	var cond_jump_input = ScriptInput.new()
	cond_jump_input.action_name = "jump"
	set_conditions(state_g_jump, [cond_jump_input])
	
	# --- Airborne Sub-States ---
	
	# Airborne -> Idle
	var state_a_idle = RecursiveState.new()
	state_a_idle.name = "Idle"
	state_a_idle.is_starting_state = true
	
	var cond_a_not_moving = ScriptMovement.new()
	cond_a_not_moving.reverse_result = true
	set_conditions(state_a_idle, [cond_a_not_moving])
	
	# Airborne -> Run
	var state_a_run = RecursiveState.new()
	state_a_run.name = "Run"
	state_a_run.behavior = beh_run
	
	var cond_a_moving = ScriptMovement.new()
	set_conditions(state_a_run, [cond_a_moving])
	
	# --- Assemble Hierarchy ---
	
	# Add Grounded and its children
	root_state.add_child(state_grounded)
	state_grounded.owner = main_scene
	
	state_grounded.add_child(state_g_idle)
	state_g_idle.owner = main_scene
	
	state_grounded.add_child(state_g_run)
	state_g_run.owner = main_scene
	
	state_grounded.add_child(state_g_jump)
	state_g_jump.owner = main_scene
	
	# Add Airborne and its children
	root_state.add_child(state_airborne)
	state_airborne.owner = main_scene
	
	state_airborne.add_child(state_a_idle)
	state_a_idle.owner = main_scene
	
	state_airborne.add_child(state_a_run)
	state_a_run.owner = main_scene
	
	# --- Camera Setup (Phantom Camera) ---
	# Preserving existing camera setup logic as it handles the camera rig
	var camera = main_scene.get_node_or_null("MainCamera")
	if not camera:
		camera = Camera3D.new()
		camera.name = "MainCamera"
		camera.position = Vector3(0, 5, 10)
		main_scene.add_child(camera)
		camera.owner = main_scene
	
	var pcam_host = camera.get_node_or_null("PhantomCameraHost")
	if not pcam_host:
		pcam_host = PhantomCameraHost.new()
		pcam_host.name = "PhantomCameraHost"
		camera.add_child(pcam_host)
		pcam_host.owner = main_scene
		
	var pcam = main_scene.get_node_or_null("PlayerCamera")
	if not pcam:
		pcam = PhantomCamera3D.new()
		pcam.name = "PlayerCamera"
		main_scene.add_child(pcam)
		pcam.owner = main_scene
	
	# Configure PCam
	pcam.priority = 20
	pcam.follow_mode = 6 # PhantomCamera3D.FollowMode.THIRD_PERSON
	pcam.follow_target = character
	pcam.follow_distance = 5.0
	
	# --- Save ---
	var packed = PackedScene.new()
	packed.pack(main_scene)
	ResourceSaver.save(packed, "res://playable_scene.tscn")
	print("Saved res://playable_scene.tscn")

func set_conditions(state: RecursiveState, conditions: Array):
	var typed_conditions: Array[StateCondition] = []
	for c in conditions:
		if c is StateCondition:
			typed_conditions.append(c)
	state.activation_conditions = typed_conditions
