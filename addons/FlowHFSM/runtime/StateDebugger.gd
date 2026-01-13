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
		var bb = null
		if player_controller.has_method("get_blackboard"):
			bb = player_controller.get_blackboard()
		elif "blackboard" in player_controller:
			bb = player_controller.blackboard
		elif "_blackboard" in player_controller: # Fallback for older versions
			bb = player_controller._blackboard
			
		if bb:
			bb_data = str(bb.get_data())
	
	# Update the 3D Label text
	text = "State: %s\nMemory: %s\nBlackboard: %s" % [active_path, leaf_data, bb_data]

## Recursive helper to build the string "Grounded > Run".
## Traverses down the `active_child` chain to build a breadcrumb path.
func _get_active_path(node: RecursiveState) -> String:
	var state_name = node.name
	
	# If we have behaviors, maybe append their names too for clarity
	if not node.behaviors.is_empty():
		var b_names = []
		for b in node.behaviors:
			if not b: continue
			# Extract behavior name, fallback to "Embedded" if resource_path is empty
			var b_name = "Embedded"
			if b.resource_path != "":
				b_name = b.resource_path.get_file().get_basename()
			b_names.append(b_name)
		
		if not b_names.is_empty():
			state_name += "(%s)" % ", ".join(b_names)
		
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
