class_name PlayerController extends Node

## THE DRIVER
## Polls input, updates the Blackboard, and ticks the State Machine.
## Attached to the CharacterBody3D (or an empty node inside it).

@export var root_state: RecursiveState
@export var physics_manager: PhysicsManager

# The Blackboard: A shared dictionary for the entire hierarchy
var blackboard: Dictionary = {}

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

func _process(delta: float) -> void:
	# 1. POLL INPUT
	_poll_input()
	
	# 2. TICK MACHINE
	# We use _process for logic, but physics_manager uses _physics_process for movement.
	if root_state:
		root_state.process_state(delta, get_parent(), blackboard)

func _poll_input() -> void:
	# Get Vector2 input for movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	blackboard["input_dir"] = input_dir
	
	# Get Boolean actions
	var inputs = blackboard.get("inputs")
	inputs["jump"] = Input.is_action_pressed("ui_accept")
	inputs["fire"] = Input.is_action_pressed("ui_select") # Example
	
	# Add more inputs as needed...
