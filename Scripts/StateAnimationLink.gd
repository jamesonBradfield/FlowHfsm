class_name StateAnimationLink extends Node

## Links the Flux HFSM to a Godot AnimationTree.
## Automatically connects to all RecursiveState nodes and triggers playback
## in the AnimationNodeStateMachine based on the state name.

## The AnimationTree to control.
@export var animation_tree: AnimationTree
## The root of the HFSM. If null, tries to find "RootState" in parent.
@export var root_state: RecursiveState
## The property path to the AnimationNodeStateMachine playback.
## Default is "parameters/playback", but could be "parameters/StateMachine/playback".
@export var state_machine_path: String = "parameters/playback"

func _ready() -> void:
	if not root_state:
		# Try to find it on parent
		var parent = get_parent()
		if parent:
			root_state = parent.get_node_or_null("RootState")
			
	if root_state:
		_connect_states_recursive(root_state)
	else:
		push_warning("StateAnimationLink: Could not find RootState.")

## Recursively connects signals for all state nodes.
func _connect_states_recursive(node: Node) -> void:
	if node is RecursiveState:
		node.state_entered.connect(_on_state_entered)
		
		for child in node.get_children():
			_connect_states_recursive(child)

## Signal handler.
func _on_state_entered(state: RecursiveState) -> void:
	if not animation_tree:
		return
	
	if not animation_tree.active:
		return
		
	# Get the state machine playback object
	var playback = animation_tree.get(state_machine_path)
	if playback:
		# Try to travel to a state with the same name.
		# Note: AnimationNodeStateMachine node names must match RecursiveState names!
		# e.g. State "Run" -> Animation State "Run"
		playback.travel(state.name)
