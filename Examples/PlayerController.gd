class_name PlayerController extends Node

## Polls input and feeds it into the blackboard.
## Drives the HFSM state machine every frame.

@export_group("References")
## The root state of the HFSM.
@export var root_state: RecursiveState
## Optional: The physics manager if separate from this controller.
@export var physics_manager: Node

@export_group("Input Action Names")
## Action name for movement (up/down/left/right).
@export var move_action_prefix: String = "ui_"
## Action name for jump.
@export var jump_action: String = "ui_accept"

## The blackboard shared with the HFSM.
var blackboard: Dictionary = {}

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

	# Initialize blackboard
	_init_blackboard()

func _process(delta: float) -> void:
	# 1. Poll Input
	_poll_input()

	# 2. Tick the HFSM
	if root_state:
		root_state.process_state(delta, _body, blackboard)

func _physics_process(delta: float) -> void:
	# 3. Apply physics (move_and_slide)
	if _body:
		_body.move_and_slide()

func _init_blackboard() -> void:
	# Initialize all blackboard values
	blackboard["input_direction"] = Vector3.ZERO
	blackboard["is_moving"] = false
	blackboard["jump_pressed"] = false
	blackboard["jump_just_pressed"] = false

func _poll_input() -> void:
	# Reset input flags
	blackboard["jump_just_pressed"] = false

	# Poll movement input
	var move_vec := Vector2.ZERO
	move_vec.x = Input.get_axis(move_action_prefix + "left", move_action_prefix + "right")
	move_vec.y = Input.get_axis(move_action_prefix + "up", move_action_prefix + "down")

	# Convert 2D input to 3D direction (XZ plane)
	var input_dir := Vector3.ZERO
	input_dir.x = move_vec.x
	input_dir.z = move_vec.y

	blackboard["input_direction"] = input_dir

	# Poll jump input
	var is_jump_pressed := Input.is_action_pressed(jump_action)
	var is_jump_just_pressed := Input.is_action_just_pressed(jump_action)

	blackboard["jump_pressed"] = is_jump_pressed
	if is_jump_just_pressed:
		blackboard["jump_just_pressed"] = true
