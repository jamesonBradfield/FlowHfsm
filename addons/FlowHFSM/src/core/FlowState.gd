@tool
class_name FlowState extends Node

## THE CONTAINER
## Acts as a generic host for a Behavior (Logic) and Atomic Activation Conditions.
## Holds the "State" (Memory) for the Behavior to use.
##
## Child State Priority:
## Child states are evaluated for activation based on their order in the scene tree.
## All children are evaluated. If multiple children can activate, the one appearing LATEST in the list
## (lowest in the inspector) becomes the active state.

# --- EXPORTS (The Strategy) ---
## Define variables here to auto-create them in the Blackboard.
@export var declared_variables: Array[FlowVariable] = []

## The "Brain" (Resource). Defines what this state does (e.g., Move, Jump).
@export var behaviors: Array[FlowBehavior] = []

## LEGACY: Singular behavior support for backward compatibility.
## Migrates to the behaviors array on set.
var behavior: FlowBehavior:
	set(v):
		if v and behaviors.is_empty():
			behaviors.append(v)

enum ActivationMode { AND, OR }

## The "Gate" (Conditions). A list of conditions that must be met for this state to be active.
## Used by the Parent to auto-select this child (e.g., Jump activates when Space is pressed).
@export var activation_conditions: Array[FlowCondition] = []

## How to combine the activation conditions.
## AND: All conditions must be true.
## OR: At least one condition must be true.
@export_enum("AND", "OR") var activation_mode: int = ActivationMode.AND

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
var parent: FlowState = null

## The currently active child state. Null if this is a leaf state.
var active_child: FlowState = null

## The "Bucket" for the Behavior to store runtime data (Timer, Counters, etc.)
## Key = String ("charge_time"), Value = Any.
## Cleared when the state is entered.
var memory: Dictionary = {}

## Structured memory object (Optional, for Type-Safe refactor).
## If set, this will be used instead of the dictionary.
var memory_obj: RefCounted = null

## The Blackboard instance. 
## If this is the Root State, it creates and owns this.
## If this is a Child State, this is usually null (passed via arguments).
var _owned_blackboard: FlowBlackboard

# --- SIGNALS ---
signal state_entered(state: FlowState)
signal state_exited(state: FlowState)

# --- CONFIGURATION WARNINGS ---
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	# Check Smasher Integrity
	var smash_error: String = validate_smashed_logic()
	if not smash_error.is_empty():
		warnings.append(smash_error)
	
	# Check for null behaviors
	for i in range(behaviors.size()):
		if behaviors[i] == null:
			warnings.append("Behavior Slot #%d is empty. Please assign a StateBehavior or remove the slot." % i)
			
	# Check for null conditions
	for i in range(activation_conditions.size()):
		if activation_conditions[i] == null:
			warnings.append("Condition Slot is empty.")
			
	# Check for multiple starting states
	var starting_states_count: int = 0
	for child in get_children():
		if child is FlowState and child.is_starting_state:
			starting_states_count += 1
			
	if starting_states_count > 1:
		warnings.append("Multiple children are marked as 'Is Starting State'. Only the first one will be used.")
		
	return warnings

# --- VALIDATION ---
func validate_smashed_logic() -> String:
	var scr: Script = get_script()
	if not scr: return ""
	
	# Check if this is a Smashed Script
	# We rely on the constant we injected: SMASHED_CHILD_COUNT
	var smashed_count: Variant = scr.get_script_constant_map().get("SMASHED_CHILD_COUNT")
	
	if smashed_count == null:
		return "" # Not a smashed script, normal operation
		
	# Count actual state children
	var current_count: int = 0
	for c in get_children():
		if c is FlowState:
			current_count += 1
			
	if current_count != int(smashed_count):
		return "LOGIC MISMATCH: Smashed script expects %d children, found %d. Please Re-Smash!" % [smashed_count, current_count]
		
	return ""

# --- LIFECYCLE ---

## Called when the node enters the scene tree for the first time.
## Establishes the parent-child relationship in the HFSM.
func _ready() -> void:
	# 1. Wire up hierarchy
	var p: Node = get_parent()
	if p is FlowState:
		parent = p
	else:
		# I AM ROOT.
		if not _owned_blackboard: 
			_owned_blackboard = FlowBlackboard.new()

		# THE HARVEST: Scan tree and populate blackboard
		_initialize_hierarchy_data(self, _owned_blackboard)

## Recursively harvests variables from the tree and registers them.
func _initialize_hierarchy_data(node: FlowState, root_blackboard: FlowBlackboard) -> void:
	# 1. Register THIS node's variables
	for var_def: FlowVariable in node.declared_variables:
		if not var_def: continue # Skip empty slots
		
		if var_def.variable_name.is_empty(): 
			push_warning("StateVariable in %s has no name!" % node.name)
			continue
			
		if var_def.is_global:
			# Only set if not already set to avoid overwriting (or remove check to allow overwrites)
			if not root_blackboard.has_value(var_def.variable_name):
				root_blackboard.set_value(var_def.variable_name, var_def.initial_value)
				# print_verbose("FlowHFSM: Registered global variable '%s' from state '%s'" % [var_def.variable_name, node.name])
			else:
				# Check if we should warn about duplicates or just ignore
				pass
	
	# 2. Recursively check children
	for child in node.get_children():
		if child is FlowState:
			_initialize_hierarchy_data(child, root_blackboard)

# --- THE MAIN LOOP ---

## The core update loop for the state.
## 1. Checks for child activation (Priority by Order).
## 2. Updates the active behavior.
## 3. Recursively updates the active child.
##
## @param delta: Time elapsed since the last frame.
## @param actor: The owner of the state machine (usually a CharacterBody3D/2D).
## @param blackboard: The shared data container.
func process_state(delta: float, actor: Node, blackboard: FlowBlackboard = null) -> void:
	# 0. BLACKBOARD RESOLUTION
	if not blackboard:
		if not parent:
			# I am Root, use/create my own
			if not _owned_blackboard: _owned_blackboard = FlowBlackboard.new()
			blackboard = _owned_blackboard
		else:
			push_warning("RecursiveState: process_state called without blackboard on child node.")
			# Fallback, but dangerous
			return

	# 1. SELECTOR LOGIC (Priority-Based Child Activation)
	# Iterate through children in order. The LAST one that CAN activate becomes the active child.
	# Priority: Lower nodes in the scene tree override higher nodes.
	# If the current active child is locked, we SKIP switching until it unlocks.
	
	var best_child: FlowState = null
	
	for child in get_children():
		if child is FlowState:
			if child.can_activate(actor, blackboard):
				best_child = child
	
	# Try to switch if we found a better candidate AND we are not locked
	if best_child != null and best_child != active_child:
		if not active_child or not active_child.is_hierarchy_locked():
			change_active_child(best_child, actor, blackboard)
	
	# 2. BEHAVIOR UPDATE (The "Brain")
	for b: FlowBehavior in behaviors:
		if b:
			b.update(self, delta, actor, blackboard)

	# 3. RECURSION (Tick the Child)
	if active_child:
		active_child.process_state(delta, actor, blackboard)

# --- API ---

## Called when the state becomes active.
## Clears memory, resets locks, enters the behavior, and recursively enters the starting child.
##
## @param actor: The owner of the state machine.
## @param blackboard: The shared data container.
func enter(actor: Node, blackboard: FlowBlackboard = null) -> void:
	# Blackboard fallback for entry (if called manually)
	if not blackboard and not parent:
		if not _owned_blackboard: _owned_blackboard = FlowBlackboard.new()
		blackboard = _owned_blackboard

	# Reset local memory on entry so we don't have stale data (e.g. old timers)
	memory.clear()
	if memory_obj and memory_obj.has_method("clear"):
		memory_obj.call("clear")
		
	is_locked = false 
	
	state_entered.emit(self)
	
	# Auto-resolve initial child if none is active
	if not active_child and get_child_count() > 0:
		var start_node: FlowState = _get_starting_child()
		if start_node:
			active_child = start_node

	for b: FlowBehavior in behaviors:
		if b:
			b.enter(self, actor, blackboard)
	
	# If we have a default child, enter it too
	if active_child:
		active_child.enter(actor, blackboard)

## Helper to find the default starting child state.
## Returns the child marked as `is_starting_state`, or the first `RecursiveState` child found.
func _get_starting_child() -> FlowState:
	for child in get_children():
		if child is FlowState and child.is_starting_state:
			return child
	
	# Fallback: First valid child
	for child in get_children():
		if child is FlowState:
			return child
	
	return null

## Called when the state becomes inactive.
## Recursively exits the active child and the current behavior.
##
## @param actor: The owner of the state machine.
## @param blackboard: The shared data container.
func exit(actor: Node, blackboard: FlowBlackboard = null) -> void:
	# Blackboard fallback
	if not blackboard and not parent:
		blackboard = _owned_blackboard

	if active_child:
		active_child.exit(actor, blackboard)
		# Forget the active child if we don't have history enabled
		if not has_history:
			active_child = null
		
	for b: FlowBehavior in behaviors:
		if b:
			b.exit(self, actor, blackboard)
	
	state_exited.emit(self)

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
func can_activate(actor: Node, blackboard: FlowBlackboard = null) -> bool:
	# No conditions = Always Active (if reached by priority)
	if activation_conditions.is_empty():
		return true
		
	match activation_mode:
		ActivationMode.AND:
			# ALL conditions must be true
			for condition: FlowCondition in activation_conditions:
				if not condition.evaluate(actor, blackboard):
					return false
			return true
			
		ActivationMode.OR:
			# AT LEAST ONE condition must be true
			for condition: FlowCondition in activation_conditions:
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
## @param blackboard: The shared data container.
func change_active_child(new_node: FlowState, actor: Node = null, blackboard: FlowBlackboard = null) -> void:
	if active_child == new_node: return
	
	# Fallback to owner if actor is missing (e.g. signal call)
	if not actor:
		actor = owner
	
	if active_child:
		active_child.exit(actor, blackboard)
	
	active_child = new_node
	
	if active_child:
		active_child.enter(actor, blackboard)

## Returns the blackboard used by this state.
## If Root, returns the owned blackboard (creating it if necessary).
## If Child, recursively asks parent.
func get_blackboard() -> FlowBlackboard:
	if parent:
		return parent.get_blackboard()
	
	# I am Root
	if not _owned_blackboard: 
		_owned_blackboard = FlowBlackboard.new()
		# We must ensure variables are initialized if we lazily created it
		_initialize_hierarchy_data(self, _owned_blackboard)
			
	return _owned_blackboard
