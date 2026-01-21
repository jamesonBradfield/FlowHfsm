@tool
class_name FlowState extends Node

## THE LOGIC ISLAND
## Holds Behaviors and Conditions. 
## Can store 'Custom Code' for rapid prototyping.

@export var behaviors: Array[FlowBehavior] = []

enum ActivationMode { AND, OR }
@export var activation_conditions: Array[FlowCondition] = []
@export_enum("AND", "OR") var activation_mode: int = ActivationMode.AND

@export var is_starting_state: bool = false
@export var is_locked: bool = false 

# --- THE CODE BRIDGE ---
# This code is injected by LogicSmasher into the generated script.
# Use this for one-off logic: "actor.velocity.y = 10"
@export_multiline var custom_code: String = ""

# --- STATE MEMORY ---
var parent: FlowState = null
var active_child: FlowState = null

signal state_entered(state: FlowState)
signal state_exited(state: FlowState)

func _ready() -> void:
	var p = get_parent()
	if p is FlowState:
		parent = p

func process_state(delta: float, actor: Node) -> void:
	# 1. SELECTOR
	var best_child: FlowState = null
	for child in get_children():
		if child is FlowState:
			if child.can_activate(actor):
				best_child = child
	
	if best_child != null and best_child != active_child:
		if not active_child or not active_child.is_hierarchy_locked():
			change_active_child(best_child, actor)
	
	# 2. BEHAVIOR
	for b in behaviors:
		if b: b.update(self, delta, actor)

	# 3. RECURSION
	if active_child:
		active_child.process_state(delta, actor)

func enter(actor: Node) -> void:
	is_locked = false 
	state_entered.emit(self)
	
	if not active_child and get_child_count() > 0:
		active_child = _get_starting_child()

	for b in behaviors:
		if b: b.enter(self, actor)
	
	if active_child:
		active_child.enter(actor)

func exit(actor: Node) -> void:
	if active_child:
		active_child.exit(actor)
		active_child = null
		
	for b in behaviors:
		if b: b.exit(self, actor)
	
	state_exited.emit(self)

func can_activate(actor: Node) -> bool:
	if activation_conditions.is_empty(): return true
	match activation_mode:
		ActivationMode.AND:
			for c in activation_conditions:
				if not c.evaluate(actor): return false
			return true
		ActivationMode.OR:
			for c in activation_conditions:
				if c.evaluate(actor): return true
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
		if child is FlowState: return child
	return null
