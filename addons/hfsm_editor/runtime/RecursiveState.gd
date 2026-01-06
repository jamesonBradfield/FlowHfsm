class_name RecursiveState extends Node

## THE CONTAINER
## Acts as a generic host for a Behavior (Logic) and Atomic Activation Conditions.
## Holds the "State" (Memory) for the Behavior to use.
##
## Child State Priority:
## Child states are evaluated for activation based on their order in the scene tree.
## Children appearing earlier in the tree (higher up in the inspector list) have higher priority.
## If multiple children can activate, the highest priority activatable child will become the active state.

# --- EXPORTS (The Strategy) ---
@export_group("Logic")
## The "Brain" (Resource). Defines what this state does (e.g., Move, Jump).
@export var behavior: StateBehavior 

enum ActivationMode { AND, OR }

## The "Gate" (Conditions). A list of conditions that must be met for this state to be active.
## Used by the Parent to auto-select this child (e.g., Jump activates when Space is pressed).
@export var activation_conditions: Array[StateCondition]
## How to combine the activation conditions.
## AND: All conditions must be true.
## OR: At least one condition must be true.
@export_enum("AND", "OR") var activation_mode: int = ActivationMode.AND

@export_group("Settings")
## If true, this state will be the active child when the parent is entered.
@export var is_starting_state: bool = false
## If true, this state will remember its active child when exited, resuming it on re-entry.
## If false, it resets to the starting child on re-entry.
@export var has_history: bool = false
## If true, Parent cannot transition out of this state. Useful for committed actions like attacks.
## NOTE: This is a LOCAL lock. To check if the branch is locked, use `is_hierarchy_locked()`.
@export var is_locked: bool = false 

# --- STATE VARIABLES (The Memory) ---
## The parent state in the hierarchy. Null if this is the root state.
var parent: RecursiveState = null
## The currently active child state. Null if this is a leaf state.
var active_child: RecursiveState = null

## The "Bucket" for the Behavior to store runtime data (Timer, Counters, etc.)
## Key = String ("charge_time"), Value = Any.
## Cleared when the state is entered.
var memory: Dictionary = {}

# --- LIFECYCLE ---

## Called when the node enters the scene tree for the first time.
## Establishes the parent-child relationship in the HFSM.
func _ready() -> void:
	# 1. Wire up hierarchy
	var p = get_parent()
	if p is RecursiveState:
		parent = p

# --- THE MAIN LOOP ---

## The core update loop for the state.
## 1. Checks for child activation (Priority by Order).
## 2. Updates the active behavior.
## 3. Recursively updates the active child.
##
## @param delta: Time elapsed since the last frame.
## @param actor: The owner of the state machine (usually a CharacterBody3D/2D).
## @param blackboard: Shared data dictionary for the entire HFSM.
func process_state(delta: float, actor: Node, blackboard: Dictionary) -> void:
	# 1. SELECTOR LOGIC (Priority-Based Child Activation)
	# Iterate through children in order. The first one that CAN activate becomes the active child.
	# If the current active child is locked, we SKIP switching until it unlocks.
	
	var best_child: RecursiveState = null
	
	for child in get_children():
		if child is RecursiveState:
			if child.can_activate(actor, blackboard):
				best_child = child
				break # Found the highest priority child that wants to run.
	
	# Try to switch if we found a better candidate AND we are not locked
	if best_child != null and best_child != active_child:
		if not active_child or not active_child.is_hierarchy_locked():
			change_active_child(best_child, actor, blackboard)
	
	# 2. BEHAVIOR UPDATE (The "Brain")
	if behavior:
		behavior.update(self, delta, actor, blackboard)

	# 3. RECURSION (Tick the Child)
	if active_child:
		active_child.process_state(delta, actor, blackboard)

# --- API ---

## Called when the state becomes active.
## Clears memory, resets locks, enters the behavior, and recursively enters the starting child.
##
## @param actor: The owner of the state machine.
## @param blackboard: Shared data dictionary.
func enter(actor: Node, blackboard: Dictionary) -> void:
	# Reset local memory on entry so we don't have stale data (e.g. old timers)
	memory.clear()
	is_locked = false 
	
	# Auto-resolve initial child if none is active
	if not active_child and get_child_count() > 0:
		var start_node = _get_starting_child()
		if start_node:
			active_child = start_node

	if behavior:
		behavior.enter(self, actor, blackboard)
	
	# If we have a default child, enter it too
	if active_child:
		active_child.enter(actor, blackboard)

## Helper to find the default starting child state.
## Returns the child marked as `is_starting_state`, or the first `RecursiveState` child found.
func _get_starting_child() -> RecursiveState:
	for child in get_children():
		if child is RecursiveState and child.is_starting_state:
			return child
	
	# Fallback: First valid child
	for child in get_children():
		if child is RecursiveState:
			return child
	
	return null

## Called when the state becomes inactive.
## Recursively exits the active child and the current behavior.
##
## @param actor: The owner of the state machine.
## @param blackboard: Shared data dictionary.
func exit(actor: Node, blackboard: Dictionary) -> void:
	if active_child:
		active_child.exit(actor, blackboard)
		# Forget the active child if we don't have history enabled
		if not has_history:
			active_child = null
		
	if behavior:
		behavior.exit(self, actor, blackboard)

# --- CHILD MANAGEMENT ---

## Checks if this state or any active descendant is locked.
func is_hierarchy_locked() -> bool:
	if is_locked: 
		return true
	
	if active_child:
		return active_child.is_hierarchy_locked()
		
	return false

## Checks if this state can be active.
## Evaluates activation_conditions based on activation_mode.
func can_activate(actor: Node, blackboard: Dictionary) -> bool:
	# No conditions = Always Active (if reached by priority)
	if activation_conditions.is_empty():
		return true
		
	match activation_mode:
		ActivationMode.AND:
			# ALL conditions must be true
			for condition in activation_conditions:
				if not condition.evaluate(actor, blackboard):
					return false
			return true
			
		ActivationMode.OR:
			# AT LEAST ONE condition must be true
			for condition in activation_conditions:
				if condition.evaluate(actor, blackboard):
					return true
			return false
			
	return false

## Returns the full path of active states (e.g. ["Root", "Grounded", "Run"])
func get_active_hierarchy_path() -> Array[String]:
	var path: Array[String] = [name]
	if active_child:
		path.append_array(active_child.get_active_hierarchy_path())
	return path

## Directly changes the active child to the specified node.
## Handles the full exit/enter lifecycle.
##
## @param new_node: The new child state to make active.
## @param actor: The owner of the state machine.
## @param blackboard: Shared data dictionary.
func change_active_child(new_node: RecursiveState, actor: Node = null, blackboard: Dictionary = {}) -> void:
	if active_child == new_node: return
	
	# Fallback to owner if actor is missing (e.g. signal call)
	if not actor:
		actor = owner
	
	if active_child:
		active_child.exit(actor, blackboard)
	
	active_child = new_node
	
	if active_child:
		active_child.enter(actor, blackboard)

