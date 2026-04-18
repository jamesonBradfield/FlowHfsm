@tool
class_name FlowState extends Node

## THE LOGIC ISLAND
## Holds Behaviors and Conditions. 
## Can store 'Custom Code' for rapid prototyping.
##
## Data flows DOWN: the actor resolves a FlowDataMap into a context dict,
## which gets passed through process_state() to all children and behaviors.

@export var is_concurrent: bool = false

@export var behaviors: Array[FlowBehavior] = []

enum ActivationMode { AND, OR }
@export var activation_conditions: Array[FlowCondition] = []
@export_enum("AND", "OR") var activation_mode: int = ActivationMode.AND

@export var is_starting_state: bool = false
@export var is_locked: bool = false 

## Keys this state needs from the context.
## If non-empty, only these keys are passed to children (filtering).
## If empty, the full context passes through.
@export var required_keys: Array[StringName] = []

# --- THE CODE BRIDGE ---
@export_multiline var custom_code: String = ""

# --- STATE MEMORY ---
var parent: FlowState = null
var active_child: FlowState = null
var is_active: bool = false

signal state_entered(state: FlowState)
signal state_exited(state: FlowState)

func _ready() -> void:
	var p = get_parent()
	if p is FlowState:
		parent = p

func process_state(delta: float, actor: Node, context: Dictionary[StringName, Variant]) -> void:
	# Filter context for children if this state declares required keys
	var child_context := context
	if not required_keys.is_empty():
		child_context = _filter_context(context)
	
	# 1. HANDLE CONCURRENT STATES (Parallel Machines)
	for child in get_children():
		if child is FlowState and child.is_concurrent:
			if child.can_activate(actor, child_context):
				if not child.is_active: 
					child.enter(actor)
				child.process_state(delta, actor, child_context)
			elif child.is_active:
				child.exit(actor)

	# 2. SELECTOR (Exclusive Machine)
	var best_child: FlowState = null
	for child in get_children():
		if child is FlowState and not child.is_concurrent:
			if child.can_activate(actor, child_context):
				best_child = child
	
	if best_child != null and best_child != active_child:
		if not active_child or not active_child.is_hierarchy_locked():
			change_active_child(best_child, actor)

	# 3. BEHAVIOR
	for b in behaviors:
		if b: b.update(self, delta, actor, context)

	# 4. RECURSION
	if active_child:
		active_child.process_state(delta, actor, child_context)

func enter(actor: Node) -> void:
	is_active = true
	is_locked = false 
	state_entered.emit(self)
	
	if not active_child and get_child_count() > 0:
		active_child = _get_starting_child()

	for b in behaviors:
		if b: b.enter(self, actor)
	
	if active_child:
		active_child.enter(actor)

func exit(actor: Node) -> void:
	is_active = false
	if active_child:
		active_child.exit(actor)
		active_child = null
		
	for b in behaviors:
		if b: b.exit(self, actor)
	
	state_exited.emit(self)

func can_activate(actor: Node, context: Dictionary[StringName, Variant] = {}) -> bool:
	if activation_conditions.is_empty(): return true
	match activation_mode:
		ActivationMode.AND:
			for c in activation_conditions:
				if not c.evaluate(actor, context): return false
			return true
		ActivationMode.OR:
			for c in activation_conditions:
				if c.evaluate(actor, context): return true
			return false
	return false

func change_active_child(new_node: FlowState, actor: Node) -> void:
	if active_child == new_node: return
	if active_child: active_child.exit(actor)
	active_child = new_node
	if active_child: active_child.enter(actor)

func is_hierarchy_locked() -> bool:
	if is_locked: return true
	if active_child: return active_child.is_hierarchy_locked()
	return false

func _get_starting_child() -> FlowState:
	for child in get_children():
		if child is FlowState and child.is_starting_state: return child
	for child in get_children():
		if child is FlowState and not child.is_concurrent: return child
	return null

func _filter_context(context: Dictionary[StringName, Variant]) -> Dictionary[StringName, Variant]:
	var filtered: Dictionary[StringName, Variant] = {}
	for key in required_keys:
		if context.has(key):
			filtered[key] = context[key]
	return filtered
