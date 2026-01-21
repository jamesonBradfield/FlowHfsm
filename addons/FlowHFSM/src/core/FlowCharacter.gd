class_name FlowCharacter extends CharacterBody3D

## THE UNIFIED BASE
## Handles Input, Physics, and Animation syncing automatically.
## 
## HOW TO USE:
## 1. Extend this script (e.g., Player.gd extends FlowCharacter).
## 2. Assign your AnimationTree and RootState (or let it auto-find them).
## 3. Override _poll_input() if you need custom controls.
## 4. Name your AnimationTree parameters the SAME as your Blackboard variables.

@export_group("References")
@export var root_state: FlowState
@export var animation_tree: AnimationTree

@export_group("Physics Settings")
@export var gravity: float = 20.0
@export var ground_friction: float = 0.1
@export var air_resistance: float = 0.01
@export var terminal_velocity: float = 50.0

@export_group("Animation Settings")
## If true, automatically sets AnimationTree parameters that match Blackboard keys.
@export var auto_sync_parameters: bool = true
## If true, automatically travels to an AnimationNode matching the active State name.
@export var auto_travel_states: bool = true
## The path to the playback object in the AnimationTree.
@export var animation_state_machine_path: String = "parameters/playback"

# Internal
var _blackboard: FlowBlackboard
var _anim_playback: AnimationNodeStateMachinePlayback

# -- VIRTUAL: INPUT --
# Override this to define your own inputs.
# Returns true if the character is "trying to move".
func _poll_input() -> void:
	# Default Implementation: WASD + Space
	var input_dir := Vector3.ZERO
	var move_vec := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	input_dir.x = move_vec.x
	input_dir.z = move_vec.y
	
	var is_moving := input_dir.length_squared() > 0.01
	var jump_pressed := Input.is_action_pressed("ui_accept")
	var jump_just_pressed := Input.is_action_just_pressed("ui_accept")

	# Write to Blackboard
	if _blackboard:
		_blackboard.set_value("input_direction", input_dir)
		_blackboard.set_value("is_moving", is_moving)
		_blackboard.set_value("jump_pressed", jump_pressed)
		_blackboard.set_value("jump_just_pressed", jump_just_pressed)

# -- LIFECYCLE --

func _ready() -> void:
	# 1. Auto-find Root State
	if not root_state:
		root_state = get_node_or_null("RootState")
	
	if not root_state:
		push_error("FlowCharacter: No RootState found. Please assign one.")
		set_physics_process(false)
		return

	# 2. Initialize Blackboard
	if root_state.has_method("get_blackboard"):
		_blackboard = root_state.get_blackboard()
	else:
		_blackboard = FlowBlackboard.new()

	# 3. Setup Animation
	if animation_tree:
		_anim_playback = animation_tree.get(animation_state_machine_path)
		if auto_travel_states:
			_connect_state_signals(root_state)

func _physics_process(delta: float) -> void:
	# 1. Handle Input (User Logic)
	_poll_input()
	
	# 2. Run State Machine (Brain)
	if root_state:
		root_state.process_state(delta, self, _blackboard)
	
	# 3. Apply Default Physics (Gravity/Friction)
	# Note: We do this AFTER the state machine, so States can modify velocity first.
	_apply_physics(delta)
	
	# 4. Sync Animation (Visuals)
	if animation_tree and auto_sync_parameters:
		_sync_animation_parameters()

# -- PHYSICS LOGIC --

func _apply_physics(delta: float) -> void:
	# Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		if velocity.y < -terminal_velocity:
			velocity.y = -terminal_velocity
	
	# Apply Friction
	var friction = ground_friction if is_on_floor() else air_resistance
	velocity.x = move_toward(velocity.x, 0, abs(velocity.x) * friction)
	velocity.z = move_toward(velocity.z, 0, abs(velocity.z) * friction)
	
	move_and_slide()

# -- ANIMATION LOGIC --

func _sync_animation_parameters() -> void:
	# Iterate over all data currently in the Blackboard
	# If the AnimationTree has a matching parameter, set it.
	# Example: Blackboard has "speed" -> sets "parameters/speed"
	
	# Note: This requires FlowBlackboard to expose a way to iterate keys, 
	# or we can iterate the variables defined in RootState. 
	# For now, we assume we can get data. 
	# Optimization: You might want to cache these paths later.
	
	# HACK: Accessing internal dictionary for direct iteration if available, 
	# otherwise we rely on user naming convention.
	var data = _blackboard._data # Assuming _data is the dictionary in FlowBlackboard
	
	for key in data:
		var param_path = "parameters/" + key
		# Check if the property exists on the tree (to avoid errors)
		# get(path) returns null if invalid, but we want to avoid spamming the error log.
		var val = data[key]
		
		# We assume if the user named it the same, they want it synced.
		# We use duck-typing: just try to set it.
		animation_tree.set(param_path, val)

func _connect_state_signals(state: Node) -> void:
	if state.has_signal("state_entered"):
		if not state.state_entered.is_connected(_on_state_entered):
			state.state_entered.connect(_on_state_entered)
	
	for child in state.get_children():
		_connect_state_signals(child)

func _on_state_entered(state: Node) -> void:
	if _anim_playback:
		# Try to travel to a node with the same name as the state
		_anim_playback.travel(state.name)
