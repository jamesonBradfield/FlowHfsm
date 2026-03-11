@tool
class_name ConditionInput extends FlowCondition

## "The Gatekeeper"
## Checks Global Input for State Transitions.

enum Check { IS_PRESSED, JUST_PRESSED, JUST_RELEASED }
@export var actions: Array[String] = ["ui_accept"]
@export var check: Check = Check.JUST_PRESSED

func _evaluate(_actor: Node) -> bool:
	for action in actions:
		match check:
			Check.IS_PRESSED:
				if Input.is_action_pressed(action): return true
			Check.JUST_PRESSED:
				if Input.is_action_just_pressed(action): return true
			Check.JUST_RELEASED:
				if Input.is_action_just_released(action): return true
	return false
