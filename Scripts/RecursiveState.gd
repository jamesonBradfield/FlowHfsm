class_name RecursiveState extends Node

## THE CONTAINER
## Acts as a generic host for a Behavior (Logic) and Transitions (Gates).
## Holds the "State" (Memory) for the Behavior to use.

# --- EXPORTS (The Strategy) ---
@export_group("Logic")
## The "Brain" (Resource). Defines what this state does (e.g., Move, Jump).
@export var behavior: StateBehavior 
## The "Triggers" (Resources). A list of conditions that cause this state to activate (Incoming).
## Used by the Parent to auto-select this child (e.g., Jump triggers when Space is pressed).
## This decoupling allows the state to be dropped into any container without knowing its neighbors.
## NOTE: Transitions are checked in order. First one to satisfy conditions wins.
@export var transitions: Array[StateTransition]

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
## 1. Checks for transitions (if not locked).
## 2. Updates the active behavior.
## 3. Recursively updates the active child.
##
## @param delta: Time elapsed since the last frame.
## @param actor: The owner of the state machine (usually a CharacterBody3D/2D).
## @param blackboard: Shared data dictionary for the entire HFSM.
func process_state(delta: float, actor: Node, blackboard: Dictionary) -> void:
	# 1. SELECTOR LOGIC (Check Children Triggers)
	# This implements "Parent Responsibility": The parent checks if any child (state) 
	# should become active based on that child's conditions.
	# "Hierarchical Blocking": We check if the active child OR any of its descendants are locked.
	if not active_child or not active_child.is_hierarchy_locked():
		for child in get_children():
			if child is RecursiveState and child != active_child:
				if child.check_transitions(actor, blackboard):
					change_active_child(child, actor, blackboard)
					break # Found a winner, stop checking others (Priority = Tree Order)

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

## Checks if any of the triggers for this state are met.
func check_transitions(actor: Node, blackboard: Dictionary) -> bool:
	if transitions.is_empty():
		return false
		
	for transition in transitions:
		if transition.is_triggered(actor, blackboard):
			return true
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

