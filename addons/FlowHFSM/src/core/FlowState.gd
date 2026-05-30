@tool
class_name FlowState extends Node

## Conditions that must all pass for this state to be selected.
@export var conditions: Array[FlowCondition] = []

## Behaviors that run while this state is active.
@export var behaviors: Array[FlowBehavior] = []

var host: Node
var active_child: FlowState = null

func _walk(data: Dictionary, delta: float) -> void:
	# 1. Run my behaviors (write to data before children read)
	for b in behaviors:
		if b:
			b.update(host, data, delta)

	# 2. Pick a child (first match wins — sibling order is priority)
	var next: FlowState = null
	for child in get_children():
		if child is FlowState and child._evaluate(host, data):
			next = child
			break

	# 3. Transition if changed
	if next != active_child:
		if active_child:
			active_child._exit(data)
		active_child = next
		if active_child:
			active_child._enter(data)

	# 4. Recurse
	if active_child:
		active_child._walk(data, delta)

func _evaluate(_host: Node, data: Dictionary) -> bool:
	for c in conditions:
		if not c.evaluate(_host, data):
			return false
	return true

func _enter(data: Dictionary) -> void:
	for b in behaviors:
		if b:
			b.enter(host, data)

func _exit(data: Dictionary) -> void:
	for b in behaviors:
		if b:
			b.exit(host, data)
