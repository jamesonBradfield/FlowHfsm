@tool
class_name BehaviorDebug extends StateBehavior

## A simple diagnostic tool. Prints messages when the State changes.
## Useful for verifying if a specific State is actually running.

enum LogType { PRINT, WARNING, ERROR }

@export_group("Settings")
@export var message: String = "State Active"
@export var type: LogType = LogType.PRINT

@export_group("Triggers")
@export var on_enter: bool = true
@export var on_exit: bool = false
@export var on_update: bool = false

func enter(state: RecursiveState, _actor: Node, _blackboard: Blackboard) -> void:
	if on_enter:
		_log("[%s] ENTER: %s" % [state.name, message])

func exit(state: RecursiveState, _actor: Node, _blackboard: Blackboard) -> void:
	if on_exit:
		_log("[%s] EXIT: %s" % [state.name, message])

func update(state: RecursiveState, _delta: float, _actor: Node, _blackboard: Blackboard) -> void:
	if on_update:
		_log("[%s] UPDATE: %s" % [state.name, message])

func _log(msg: String) -> void:
	match type:
		LogType.PRINT:
			print(msg)
		LogType.WARNING:
			push_warning(msg)
		LogType.ERROR:
			push_error(msg)
