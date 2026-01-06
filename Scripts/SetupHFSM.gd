extends SceneTree

## Automation script to setup the initial HFSM structure for the player.
## Run this using: `godot --headless -s Scripts/SetupHFSM.gd`

func _init():
	print("Starting HFSM Setup...")
	do_setup()
	quit()

## Constructs the HFSM hierarchy (Idle, Run, Jump) and saves it to a scene file.
func do_setup():
	var main_scene = load("res://main.tscn").instantiate()
	var character = main_scene.get_node("CharacterBody3D")
	var root_state = character.get_node("RootState")
	
	# Clear existing children of RootState if any (for idempotency)
	for child in root_state.get_children():
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
	state_idle.is_starting_state = true 
	
	# Idle Activation: "Active if not moving and grounded"
	state_idle.activation_conditions = [cond_not_moving, cond_is_grounded]
	state_idle.activation_mode = RecursiveState.ActivationMode.AND
	
	# 2. Run
	var state_run = RecursiveState.new()
	state_run.name = "Run"
	state_run.behavior = beh_run
	
	# Run Activation: "Active if moving and grounded"
	state_run.activation_conditions = [cond_is_moving, cond_is_grounded]
	state_run.activation_mode = RecursiveState.ActivationMode.AND
	
	# 3. Jump
	var state_jump = RecursiveState.new()
	state_jump.name = "Jump"
	state_jump.behavior = beh_jump
	
	# Jump Activation: "Active if Jump Pressed and Grounded"
	# Note: Once in Jump, we might be airborne, so we don't want to switch out immediately 
	# just because "moving" or "not moving" conditions match for other states?
	# Wait. If Jump is active (Airborne), "Run" trigger checks "Grounded". "Idle" trigger checks "Grounded".
	# If we are Airborne, neither matches. So Jump stays active.
	# But Jump trigger itself? "Input Jump" + "Grounded".
	# If we are in Jump, and frame 2 comes. Grounded is false (hopefully).
	# So we stay in Jump.
	
	state_jump.activation_conditions = [cond_input_jump, cond_is_grounded]
	state_jump.activation_mode = RecursiveState.ActivationMode.AND
	
	# --- Add to Root ---
	root_state.add_child(state_idle)
	state_idle.owner = main_scene # Important for packing
	
	root_state.add_child(state_run)
	state_run.owner = main_scene
	
	root_state.add_child(state_jump)
	state_jump.owner = main_scene
	
	# --- Camera Setup (Phantom Camera) ---
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
