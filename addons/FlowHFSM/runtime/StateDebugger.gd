class_name StateDebugger extends Label3D

## A simple debug tool. Attach this as a child of your Character.
## Position it above the player's head.

## The root state to monitor.
@export var root_state: RecursiveState
## Optional: Link to the PlayerController to view the global Blackboard.
@export var player_controller: PlayerController

## Updates the debug label with the current state path and memory.
func _process(_delta: float) -> void:
	if not root_state:
		text = "StateDebugger: No Root Linked"
		return
		
	var active_path = _get_active_path(root_state)
	var leaf_data = _get_leaf_data(root_state)
	
	var bb_data = "N/A"
	if player_controller:
		bb_data = str(player_controller.blackboard)
	
	# Update the 3D Label text
	text = "State: %s\nMemory: %s\nBlackboard: %s" % [active_path, leaf_data, bb_data]

## Recursive helper to build the string "Grounded > Run".
## Traverses down the `active_child` chain to build a breadcrumb path.
func _get_active_path(node: RecursiveState) -> String:
	var state_name = node.name
	
	# If we have a behavior, maybe append its name too for clarity
	if node.behavior:
		# Extract behavior name, fallback to "Behavior" if resource_path is empty (e.g. embedded sub-resource)
		var b_name = "Embedded"
		if node.behavior.resource_path != "":
			b_name = node.behavior.resource_path.get_file().get_basename()
		
		state_name += "(%s)" % b_name
		
	if node.active_child:
		return state_name + " > " + _get_active_path(node.active_child)
	
	return state_name

## Helper to show what's inside the memory of the bottom-most state (leaf).
## Recurses down to the currently active leaf state and dumps its memory dictionary.
func _get_leaf_data(node: RecursiveState) -> String:
	if node.active_child:
		return _get_leaf_data(node.active_child)
	
	# We are at the leaf
	if node.memory.is_empty():
		return "Empty"
	return str(node.memory)

func _ready() -> void:
	if not player_controller:
		# Try to find a sibling PlayerController
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child is PlayerController:
					player_controller = child
					break
