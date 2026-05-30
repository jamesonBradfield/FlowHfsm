@tool
class_name BehaviorDebug extends FlowBehavior

## Prints a message when the state activates.

@export var message: String = "State Active"
@export var on_enter: bool = true
@export var on_exit: bool = false
@export var on_update: bool = false

func enter(host: Node, _data: Dictionary) -> void:
	if on_enter:
		print("[%s] ENTER: %s" % [host.name, message])

func exit(host: Node, _data: Dictionary) -> void:
	if on_exit:
		print("[%s] EXIT: %s" % [host.name, message])

func update(host: Node, _data: Dictionary, _delta: float) -> void:
	if on_update:
		print("[%s] UPDATE: %s" % [host.name, message])
