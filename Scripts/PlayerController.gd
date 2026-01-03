class_name PlayerController extends Node

## THE DRIVER
## Polls input, updates the Blackboard, and ticks the State Machine.
## Attached to the CharacterBody3D (or an empty node inside it).

## The root state of the HFSM hierarchy.
@export var root_state: RecursiveState
## The physics manager component for handling movement.
@export var physics_manager: PhysicsManager

@export_group("Input Actions")
@export var input_left: String = "ui_left"
@export var input_right: String = "ui_right"
@export var input_up: String = "ui_up"
@export var input_down: String = "ui_down"
@export var input_jump: String = "ui_accept"
@export var input_fire: String = "ui_select"

# The Blackboard: A shared dictionary for the entire hierarchy
## Shared data dictionary passed to all states.
## Contains input data, references to components, and other global state information.
var blackboard: Dictionary = {}

## Initializes the controller, blackboard, and starts the state machine.
func _ready() -> void:
	# Ensure dependencies
	if not root_state:
		# Try to find it
		root_state = get_parent().get_node_or_null("RootState")
	
	if not physics_manager:
		physics_manager = get_parent().get_node_or_null("PhysicsManager")

	# Initialize Blackboard
	blackboard["physics_manager"] = physics_manager
	blackboard["inputs"] = {}
	
	# Start the machine
	if root_state:
		root_state.enter(get_parent(), blackboard)

## Main loop for input polling and state machine updates.
## Logic runs in `_process` (frame-dependent), while physics runs in `_physics_process`.
func _process(delta: float) -> void:
	# 1. POLL INPUT
	_poll_input()
	
	# 2. TICK MACHINE
	# We use _process for logic, but physics_manager uses _physics_process for movement.
	if root_state:
		root_state.process_state(delta, get_parent(), blackboard)

## Polls input from the InputMap and updates the blackboard.
## - `input_dir`: Vector2 (WASD/Joystick)
## - `inputs`: Dictionary of boolean flags (jump, fire, etc.)
func _poll_input() -> void:
	# Get Vector2 input for movement
	var input_dir = Input.get_vector(input_left, input_right, input_up, input_down)
	blackboard["input_dir"] = input_dir
	
	# Get Boolean actions
	var inputs = blackboard.get("inputs")
	inputs["jump"] = Input.is_action_pressed(input_jump)
	inputs["fire"] = Input.is_action_pressed(input_fire)
	
	# Add more inputs as needed...
