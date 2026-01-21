@tool
class_name ConditionInput extends FlowCondition

## Generic input trigger condition.
## Replaces custom conditions like JumpPressed, AttackPressed, etc.
## Supports PRESSED, JUST_PRESSED, and JUST_RELEASED triggers.

enum Trigger {
	PRESSED,
	JUST_PRESSED,
	JUST_RELEASED
}

@export var action: String = "ui_accept"
@export var trigger: Trigger = Trigger.JUST_PRESSED

func _evaluate(actor: Node, blackboard: FlowBlackboard) -> bool:
	match trigger:
		Trigger.PRESSED:
			return Input.is_action_pressed(action)
		Trigger.JUST_PRESSED:
			return Input.is_action_just_pressed(action)
		Trigger.JUST_RELEASED:
			return Input.is_action_just_released(action)

	return false
