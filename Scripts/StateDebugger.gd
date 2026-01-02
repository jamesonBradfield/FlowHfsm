class_name StateDebugger extends Label3D

## A simple debug tool. Attach this as a child of your Character.
## Position it above the player's head.

@export var root_state: RecursiveState

func _process(delta: float) -> void:
	if not root_state:
		text = "StateDebugger: No Root Linked"
		return
		
	var active_path = _get_active_path(root_state)
	var leaf_data = _get_leaf_data(root_state)
	
	# Update the 3D Label text
	text = "State: %s\nData: %s" % [active_path, leaf_data]

# Recursive helper to build the string "Grounded > Run"
func _get_active_path(node: RecursiveState) -> String:
	var state_name = node.name
	
	# If we have a behavior, maybe append its name too for clarity
	if node.behavior:
		var b_name = node.behavior.resource_path.get_file().replace(".gd", "").replace(".tres", "")
		state_name += "(%s)" % b_name
		
	if node.active_child:
		return state_name + " > " + _get_active_path(node.active_child)
	
	return state_name

# Helper to show what's inside the memory of the bottom-most state
func _get_leaf_data(node: RecursiveState) -> String:
	if node.active_child:
		return _get_leaf_data(node.active_child)
	
	# We are at the leaf
	if node.memory.is_empty():
		return "Empty"
	return str(node.memory)
