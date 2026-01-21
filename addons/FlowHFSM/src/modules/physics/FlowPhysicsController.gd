class_name FlowPhysicsController extends Node

## Polls input and exposes it as properties.
## Drives the HFSM state machine every frame.

@export_group("References")
## The root state of the HFSM.
@export var root_state: FlowState
## Optional: The physics manager if separate from this controller.
@export var physics_manager: Node

@export_group("Input Action Names")
## Action name for movement (up/down/left/right).
@export var move_action_prefix: String = "ui_"
## Action name for jump.
@export var jump_action: String = "ui_accept"

# -- Public State Properties --
# Accessed directly by Behaviors and Conditions (replacing Blackboard)
var input_direction: Vector3 = Vector3.ZERO
var is_moving: bool = false
var jump_pressed: bool = false
var jump_just_pressed: bool = false

## The CharacterBody3D being controlled.
var _body: CharacterBody3D

func _ready() -> void:
	# Get the character body
	_body = owner as CharacterBody3D
	if not _body:
		_body = get_parent() as CharacterBody3D
	
	if not _body:
		push_error("PlayerController: Cannot find CharacterBody3D to control")
		return

	# Auto-find root state if not set
	if not root_state:
		root_state = _body.get_node_or_null("RootState")

	if not root_state:
		push_error("PlayerController: Cannot find RootState")
		return
		
	# Initialize Blackboard
	# We use the RootState's blackboard to ensure we share data (Variables, etc.)
	if root_state.has_method("get_blackboard"):
		_blackboard = root_state.get_blackboard()
	else:
		push_warning("FlowPhysicsController: RootState missing get_blackboard(). Creating local fallback.")
		_blackboard = FlowBlackboard.new()

func _process(delta: float) -> void:
	# 1. Poll Input & Update Blackboard
	_poll_input()
	
	# 2. Tick the HFSM
	if root_state:
		# Pass the populated blackboard to the state machine
		root_state.process_state(delta, _body, _blackboard)

# NOTE: Physics movement (move_and_slide) is handled by PhysicsManager.gd
# We do not call it here to avoid double-movement.

func _poll_input() -> void:
	# Reset input flags
	jump_just_pressed = false
	
	# Poll movement input
	var move_vec := Vector2.ZERO
	move_vec.x = Input.get_axis(move_action_prefix + "left", move_action_prefix + "right")
	move_vec.y = Input.get_axis(move_action_prefix + "up", move_action_prefix + "down")
	
	# Convert 2D input to 3D direction (XZ plane)
	input_direction = Vector3.ZERO
	input_direction.x = move_vec.x
	input_direction.z = move_vec.y
	
	is_moving = input_direction.length_squared() > 0.01

	# Poll jump input

	# Poll jump input
	jump_pressed = Input.is_action_pressed(jump_action)
	if Input.is_action_just_pressed(jump_action):
		jump_just_pressed = true
		
	# Sync to Blackboard
	_blackboard.set_value("input_direction", input_direction)
	_blackboard.set_value("is_moving", is_moving)
	_blackboard.set_value("jump_pressed", jump_pressed)
	_blackboard.set_value("jump_just_pressed", jump_just_pressed)

var _blackboard: FlowBlackboard
