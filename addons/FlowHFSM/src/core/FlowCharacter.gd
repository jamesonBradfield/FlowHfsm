class_name FlowCharacter extends CharacterBody3D

## THE UNIFIED BASE
## Handles Input, Physics, and Animation syncing automatically.
## 
## HOW TO USE:
## 1. Extend this script (e.g., Player.gd extends FlowCharacter).
## 2. Assign your AnimationTree and RootState (or let it auto-find them).
## 3. Override _poll_input() if you need custom controls.

@export_group("References")
@export var root_state: FlowState
@export var animation_tree: AnimationTree
@export var camera: Node3D
@export var model: Node3D

@export_group("Physics Settings")
@export var gravity: float = 20.0
@export var ground_friction: float = 0.1
@export var air_resistance: float = 0.01
@export var terminal_velocity: float = 50.0

@export_group("Animation Settings")
## If true, automatically travels to an AnimationNode matching the active State name.
@export var auto_travel_states: bool = true
## The path to the playback object in the AnimationTree.
@export var animation_state_machine_path: String = "parameters/playback"

# Internal
var _anim_playback: AnimationNodeStateMachinePlayback

# Public State Variables (Read by Logic Island Behaviors)
var move_input: Vector3 = Vector3.ZERO
var is_moving: bool = false
var jump_pressed: bool = false
var jump_just_pressed: bool = false

# -- VIRTUAL: INPUT --
# Override this to define your own inputs.
func _poll_input() -> void:
	# Default Implementation: WASD + Space
	var input_dir := Vector3.ZERO
	var move_vec := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	input_dir.x = move_vec.x
	input_dir.z = move_vec.y
	
	move_input = input_dir
	is_moving = move_input.length_squared() > 0.01
	jump_pressed = Input.is_action_pressed("ui_accept")
	jump_just_pressed = Input.is_action_just_pressed("ui_accept")

# -- LIFECYCLE --

func _ready() -> void:
	# 1. Auto-find Root State
	if not root_state:
		root_state = get_node_or_null("RootState")
	
	if not root_state:
		push_error("FlowCharacter: No RootState found. Please assign one.")
		set_physics_process(false)
		return

	# 2. Setup Animation
	if animation_tree:
		_anim_playback = animation_tree.get(animation_state_machine_path)
		if auto_travel_states:
			_connect_state_signals(root_state)

func _physics_process(delta: float) -> void:
	# 1. Handle Input (User Logic)
	_poll_input()
	
	# 2. Run State Machine (Brain)
	if root_state:
		root_state.process_state(delta, self)
	
	# 3. Apply Default Physics (Gravity/Friction)
	# Note: We do this AFTER the state machine, so States can modify velocity first.
	_apply_physics(delta)
	
	# 4. Sync Animation (Visuals)
	# (Logic Island removed auto-syncing of parameters from blackboard)

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
